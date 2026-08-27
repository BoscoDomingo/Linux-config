#!/usr/bin/env bash
# Post-switch sanity checks for the Home Manager config.
# Run after activating `homeConfigurations.<host>.activationPackage`.
#
#   bash ~/dotfiles/nix/test/verify.sh
#
# Exits non-zero if any hard check fails. Git/jj-identity checks are informational
# (they depend on the gitignored overrides/ tree — see Documentation/machine-overrides.md).
set -u

REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
pass=0
fail=0
ok() {
	printf '  \033[32mPASS\033[0m  %s\n' "$1"
	pass=$((pass + 1))
}
no() {
	printf '  \033[31mFAIL\033[0m  %s\n' "$1"
	fail=$((fail + 1))
}

echo "== packages owned by Home Manager (from ~/.nix-profile) =="
for bin in rg bat eza fd fzf delta fastfetch duf gping hyperfine trip sshs cheat rip \
	jj nvim direnv tmux herdr; do
	p=$(type -P "$bin" 2>/dev/null || true)
	case "$p" in
	*"/.nix-profile/"*) ok "$bin -> $p" ;;
	"") no "$bin missing" ;;
	*) no "$bin -> $p (expected ~/.nix-profile)" ;;
	esac
done

# mise comes from its own installer, not Nix
# `type -P` ignores the shell function created by `mise activate`.
mise_path=$(type -P mise 2>/dev/null || true)
case "$mise_path" in
"$HOME/.local/bin/mise")
	if [ -L "$mise_path" ]; then
		no "mise -> $mise_path is a symlink to $(readlink -f "$mise_path") (expected a self-managed regular file)"
	elif mise --version >/dev/null 2>&1; then
		ok "mise -> $mise_path (self-managed, $(mise --version 2>/dev/null | head -1))"
	else
		no "mise -> $mise_path but fails to run"
	fi
	;;
"") no "mise missing (expected $HOME/.local/bin/mise)" ;;
*) no "mise -> $mise_path (expected $HOME/.local/bin/mise, not Nix)" ;;
esac

# opencode comes from its own installer, not Nix: the nixpkgs Bun standalone
# segfaults in ld-linux on WSL2. See nix/home/tools.nix.
opencode_path=$(type -P opencode 2>/dev/null || true)
case "$opencode_path" in
"$HOME/.opencode/bin/opencode")
	if opencode --version >/dev/null 2>&1; then
		ok "opencode -> $opencode_path (upstream installer)"
	else
		no "opencode -> $opencode_path but fails to run"
	fi
	;;
"") no "opencode missing (expected $HOME/.opencode/bin/opencode)" ;;
*) no "opencode -> $opencode_path (expected $HOME/.opencode/bin/opencode, not Nix)" ;;
esac

# diffnav is mise-owned and pinned to 0.11.0 in .config/mise/config.toml,
diffnav_path=$(type -P diffnav 2>/dev/null || true)
# Outside a `mise activate`d shell PATH resolves to the shim, which points at
# the mise binary rather than the tool; ask mise where it actually lives.
if [ "$diffnav_path" = "$HOME/.local/share/mise/shims/diffnav" ]; then
	diffnav_path=$(mise which diffnav 2>/dev/null || true)
fi
case "$diffnav_path" in
"$HOME/.local/share/mise/installs/"*diffnav*/0.11.0/diffnav)
	ok "diffnav pinned -> $diffnav_path (mise)"
	;;
"$HOME/.local/share/mise/installs/"*) no "diffnav -> $diffnav_path (expected the 0.11.0 pin)" ;;
"") no "diffnav missing (expected mise-owned 0.11.0)" ;;
*) no "diffnav -> $diffnav_path (expected mise-owned 0.11.0)" ;;
esac

echo "== dotfiles symlinked to the live repo (out-of-store) =="
for f in .bash_profile .zshrc .profile .aliases .gitconfig .ssh/allowed_signers \
	.config/starship.toml .config/nvim .config/jj/config.toml; do
	tgt=$(readlink -f "$HOME/$f" 2>/dev/null || true)
	case "$tgt" in
	"$REPO"/*) ok "$f -> $tgt" ;;
	*) no "$f resolves to '$tgt' (expected under $REPO)" ;;
	esac
done
# conf.d must point at overrides/jj; repos/ stays under the real ~/.config/jj.
if [ -d "$HOME/.config/jj" ] && [ ! -L "$HOME/.config/jj" ]; then
	ok "~/.config/jj is a real directory"
else
	no "~/.config/jj should be a real directory, not a symlink ($(readlink "$HOME/.config/jj" 2>/dev/null || echo '?'))"
fi
jj_confd=$(readlink -f "$HOME/.config/jj/conf.d" 2>/dev/null || true)
case "$jj_confd" in
"$REPO/overrides/jj") ok "~/.config/jj/conf.d -> overrides/jj" ;;
*) no "~/.config/jj/conf.d resolves to '$jj_confd' (expected $REPO/overrides/jj)" ;;
esac
mise_ov=$(readlink -f "$HOME/.mise/config.toml" 2>/dev/null || true)
case "$mise_ov" in
"$REPO/overrides/mise/config.toml") ok "~/.mise/config.toml -> overrides/mise/config.toml" ;;
"") echo "  (optional) ~/.mise/config.toml not linked yet" ;;
*) no "~/.mise/config.toml resolves to '$mise_ov' (expected $REPO/overrides/mise/config.toml)" ;;
esac

echo "== git / jj identity (overrides/ tree) =="
echo "  baseline git (repo .gitconfig): $(git -C "$REPO" config --file "$REPO/.gitconfig" user.email 2>/dev/null || echo '?')"
echo "  baseline jj  (repo config.toml): $(sed -n 's/^email = \"\(.*\)\"/\1/p' "$REPO/.config/jj/config.toml" 2>/dev/null | head -1)"
if [ -f "$REPO/overrides/git/local.gitconfig" ]; then
	echo "  git effective in \$HOME:       $(cd "$HOME" && git config user.email)"
fi
if [ -f "$REPO/overrides/jj/local.toml" ]; then
	echo "  jj  effective in \$HOME:        $(cd "$HOME" && jj config get user.email 2>/dev/null || echo '?')"
fi
# includeIf / --when.repositories only trigger inside a repo under that path.
email_in_git_repo() { # $1 = base dir
	local repo
	repo=$(find "$1" -maxdepth 2 \( -name .git -o -name .jj \) 2>/dev/null | head -1)
	[ -n "$repo" ] || return 1
	local dir
	dir=$(dirname "$repo")
	(cd "$dir" && git config user.email 2>/dev/null)
}
email_in_jj_repo() {
	local repo
	repo=$(find "$1" -maxdepth 2 \( -name .git -o -name .jj \) 2>/dev/null | head -1)
	[ -n "$repo" ] || return 1
	local dir
	dir=$(dirname "$repo")
	(cd "$dir" && jj config get user.email 2>/dev/null)
}
[ -d "$HOME/repos" ] && echo "  git in a ~/repos repo:          $(email_in_git_repo "$HOME/repos" || echo 'n/a (no repo)')"
[ -d "$HOME/repos" ] && echo "  jj  in a ~/repos repo:          $(email_in_jj_repo "$HOME/repos" || echo 'n/a (no repo)')"
[ -d "$HOME/dotfiles" ] && echo "  git in ~/dotfiles:              $(cd "$HOME/dotfiles" && git config user.email 2>/dev/null || echo 'n/a')"
[ -d "$HOME/dotfiles" ] && echo "  jj  in ~/dotfiles:              $(cd "$HOME/dotfiles" && jj config get user.email 2>/dev/null || echo 'n/a')"
[ -d "$HOME/personal" ] && echo "  git in a ~/personal repo:       $(email_in_git_repo "$HOME/personal" || echo 'n/a (no repo)')"
[ -d "$HOME/personal" ] && echo "  jj  in a ~/personal repo:       $(email_in_jj_repo "$HOME/personal" || echo 'n/a (no repo)')"

echo
echo "== home-manager generations (rollback targets) =="
ls -1 "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/" 2>/dev/null | grep home-manager || echo "  (none found)"

echo
printf 'result: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

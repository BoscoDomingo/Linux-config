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
	jj nvim opencode mise direnv tmux diffnav herdr; do
	# Ignore shell functions created by `mise activate`; verify the executable.
	p=$(type -P "$bin" 2>/dev/null || true)
	case "$p" in
	*"/.nix-profile/"*) ok "$bin -> $p" ;;
	"$HOME/.local/bin/mise")
		resolved=$(readlink -f "$p" 2>/dev/null || true)
		case "$resolved" in
		/nix/store/*-mise-*/bin/mise) ok "$bin -> $p -> $resolved" ;;
		*) no "$bin -> $p -> $resolved (expected Nix-owned mise)" ;;
		esac
		;;
	"") no "$bin missing" ;;
	*) no "$bin -> $p (expected ~/.nix-profile)" ;;
	esac
done

diffnav_path=$(readlink -f "$(type -P diffnav 2>/dev/null || true)")
case "$diffnav_path" in
/nix/store/*diffnav-0.11.0*/bin/diffnav) ok "diffnav pinned -> $diffnav_path" ;;
"") no "diffnav missing (expected Nix-owned 0.11.0)" ;;
*) no "diffnav -> $diffnav_path (expected diffnav-0.11.0)" ;;
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

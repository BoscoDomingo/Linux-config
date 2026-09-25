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
header() {
	printf '\033[35m%s\033[0m\n' "$1"
}
email_color() {
	local email=$1 checksum color
	checksum=$(printf '%s' "$email" | cksum)
	checksum=${checksum%% *}
	color=$((16 + checksum % 216))
	printf '\033[38;5;%sm%s\033[0m' "$color" "$email"
}
identity() {
	local label=$1 path=$2 email=$3
	printf '  %s (\033[34m%s\033[0m): %s\n' "$label" "$path" "$(email_color "$email")"
}

header "== packages owned by Home Manager (from ~/.nix-profile) =="
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

# $GOPATH/bin must match mise. If it does not, the Go extension asks you to
# recompile the tools.
golangci_link="${GOPATH:-$HOME/go}/bin/golangci-lint"
golangci_build=$(mise which golangci-lint 2>/dev/null || true)
if [ -z "$golangci_build" ]; then
	echo "  (optional) golangci-lint not installed by mise yet"
elif [ -e "$golangci_link" ] && [ ! -L "$golangci_link" ]; then
	no "$golangci_link is a real file. It hides $golangci_build. Delete it, then run scripts/link-go-tools"
elif [ ! -L "$golangci_link" ]; then
	# Use -L, not -e. A broken symlink is stale, not missing.
	no "$golangci_link missing (run scripts/link-go-tools)"
elif [ "$golangci_link" -ef "$golangci_build" ]; then
	ok "golangci-lint -> $golangci_build (\$GOPATH/bin link for the Go extension)"
else
	no "$golangci_link -> $(readlink "$golangci_link") (stale; expected $golangci_build)"
fi

header "== dotfiles symlinked to the live repo (out-of-store) =="
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

header "== git / jj identity (overrides/ tree) =="
identity "baseline git" "$REPO/.gitconfig" "$(git -C "$REPO" config --file "$REPO/.gitconfig" user.email 2>/dev/null || echo '?')"
identity "baseline jj" "$REPO/.config/jj/config.toml" "$(sed -n 's/^email = \"\(.*\)\"/\1/p' "$REPO/.config/jj/config.toml" 2>/dev/null | head -1)"
if [ -f "$REPO/overrides/git/local.gitconfig" ]; then
	identity "git effective" "$HOME" "$(cd "$HOME" && git config user.email)"
fi
if [ -f "$REPO/overrides/jj/local.toml" ]; then
	identity "jj effective" "$HOME" "$(cd "$HOME" && jj config get user.email 2>/dev/null || echo '?')"
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
[ -d "$HOME/repos" ] && identity "git in repos" "$HOME/repos" "$(email_in_git_repo "$HOME/repos" || echo 'n/a (no repo)')"
[ -d "$HOME/repos" ] && identity "jj in repos" "$HOME/repos" "$(email_in_jj_repo "$HOME/repos" || echo 'n/a (no repo)')"
[ -d "$HOME/dotfiles" ] && identity "git in dotfiles" "$HOME/dotfiles" "$(cd "$HOME/dotfiles" && git config user.email 2>/dev/null || echo 'n/a')"
[ -d "$HOME/dotfiles" ] && identity "jj in dotfiles" "$HOME/dotfiles" "$(cd "$HOME/dotfiles" && jj config get user.email 2>/dev/null || echo 'n/a')"
[ -d "$HOME/personal" ] && identity "git in personal" "$HOME/personal" "$(email_in_git_repo "$HOME/personal" || echo 'n/a (no repo)')"
[ -d "$HOME/personal" ] && identity "jj in personal" "$HOME/personal" "$(email_in_jj_repo "$HOME/personal" || echo 'n/a (no repo)')"

echo
header "== home-manager generations (rollback targets) =="
ls -1 "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/" 2>/dev/null | grep home-manager || echo "  (none found)"

echo
printf 'result: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

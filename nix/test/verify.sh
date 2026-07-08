#!/usr/bin/env bash
# Post-switch sanity checks for the Home Manager config.
# Run AFTER `home-manager switch --flake ~/dotfiles/nix#<host>`.
#
#   bash ~/dotfiles/nix/test/verify.sh
#
# Exits non-zero if any hard check fails. Git-identity checks are informational
# (they depend on the per-machine ~/.config/git/local.gitconfig you create).
set -u

REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
pass=0; fail=0
ok(){ printf '  \033[32mPASS\033[0m  %s\n' "$1"; pass=$((pass+1)); }
no(){ printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fail=$((fail+1)); }

echo "== packages on PATH (from ~/.nix-profile) =="
for bin in rg bat eza fd fzf delta fastfetch duf gping hyperfine trip sshs cheat rip; do
  p=$(command -v "$bin" 2>/dev/null || true)
  case "$p" in
    *"/.nix-profile/"*) ok "$bin -> $p" ;;
    "")                 no "$bin missing" ;;
    *)                  ok "$bin -> $p (not nix profile)" ;;
  esac
done

echo "== dotfiles symlinked to the live repo (out-of-store) =="
for f in .zshrc .profile .aliases .gitconfig .config/starship.toml .config/nvim; do
  tgt=$(readlink -f "$HOME/$f" 2>/dev/null || true)
  case "$tgt" in
    "$REPO"/*) ok "$f -> $tgt" ;;
    *)         no "$f resolves to '$tgt' (expected under $REPO)" ;;
  esac
done

echo "== git identity (per-machine / per-directory overrides) =="
echo "  baseline (repo .gitconfig): $(git -C "$REPO" config --file "$REPO/.gitconfig" user.email 2>/dev/null || echo '?')"
if [ -f "$HOME/.config/git/local.gitconfig" ]; then
  echo "  effective in \$HOME:         $(cd "$HOME" && git config user.email)"
fi
# includeIf "gitdir:~/repos/work/" only triggers inside a repo under that path,
# so descend into an actual repo (not the parent dir) to see the effective value.
email_in_repo(){ # $1 = base dir
  local repo; repo=$(find "$1" -maxdepth 2 -name .git -type d 2>/dev/null | head -1)
  [ -n "$repo" ] && (cd "$(dirname "$repo")" && git config user.email)
}
[ -d "$HOME/repos/work" ]     && echo "  effective in a ~/repos/work repo:     $(email_in_repo "$HOME/repos/work" || echo 'n/a (no repo)')"
[ -d "$HOME/repos/personal" ] && echo "  effective in a ~/repos/personal repo: $(email_in_repo "$HOME/repos/personal" || echo 'n/a (no repo)')"

echo
echo "== home-manager generations (rollback targets) =="
ls -1 "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/" 2>/dev/null | grep home-manager || echo "  (none found)"

echo
printf 'result: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

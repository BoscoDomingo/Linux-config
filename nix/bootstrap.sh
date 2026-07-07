#!/usr/bin/env bash
# Bootstrap this Home Manager config on a NEW machine (normal network).
#
#   HOST=ubuntu bash ~/dotfiles/nix/bootstrap.sh
#
# HOST must match an entry in flake.nix `homeConfigurations` (arch-wsl | ubuntu
# | macbook). Idempotent: safe to re-run to apply changes.
#
# For locked-down networks where GitHub tarball fetch is blocked, use the
# --override-input technique in test/README.md instead.
set -euo pipefail

REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
HOST="${HOST:-}"
[ -n "$HOST" ] || { echo "Set HOST=<arch-wsl|ubuntu|macbook>"; exit 1; }

# 1. Install Nix (Determinate installer; enables flakes by default) if missing.
if ! command -v nix >/dev/null 2>&1; then
  echo "== Installing Nix =="
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
    | sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || \
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# 2. First activation backs up any pre-existing dotfiles to *.hm-bak instead of
#    failing (replaces Setup/lib/helpers.sh backup logic).
echo "== home-manager switch --flake $REPO/nix#$HOST =="
nix run home-manager/master -- switch -b hm-bak --flake "$REPO/nix#$HOST"

echo "== verify =="
bash "$REPO/nix/test/verify.sh" || true

cat <<EOF

Done. Per-machine identity (work vs personal) is NOT in the repo — create it now
if this is a work machine:

  mkdir -p ~/.config/git
  cat > ~/.config/git/local.gitconfig <<'GITEOF'
  [user]
      email = you@work.example
      signingKey = key::ssh-ed25519 AAAA... your-work-key
  GITEOF

Then generate an SSH key on this machine (never committed) and register it:
  ssh-keygen -t ed25519 -C "you@work.example"
EOF

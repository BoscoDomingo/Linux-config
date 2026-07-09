#!/usr/bin/env bash
# Bootstrap this Home Manager config on a new machine.
#
#   HOST=ubuntu bash ~/dotfiles/nix/bootstrap.sh
#
# HOST must match an entry in flake.nix `homeConfigurations` (arch-wsl | ubuntu
# | macbook). Idempotent: safe to re-run to apply changes.
#
# INSTALL_BREW=1 also installs Homebrew (escape hatch for tools not in nixpkgs).
# SKIP_MISE=1 skips `mise install` (language runtimes + engram/pi), e.g. in CI.
# Where GitHub tarball fetch is blocked, use the --override-input technique in
# test/README.md instead.
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

# 2. Optional Homebrew (opt-in per machine via INSTALL_BREW=1). .profile picks
#    up /home/linuxbrew on PATH; the shell tolerates its absence otherwise.
if [ "${INSTALL_BREW:-0}" = "1" ] && ! command -v brew >/dev/null 2>&1; then
  echo "== Installing Homebrew (INSTALL_BREW=1) =="
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 3. -b makes activation back up any pre-existing dotfile to *.hm-bak instead
#    of failing when it wants to own that path.
echo "== home-manager switch --flake $REPO/nix#$HOST =="
nix run home-manager/master -- switch -b hm-bak --flake "$REPO/nix#$HOST"

# 4. Populate mise-managed tools (language runtimes, engram, pi). mise itself is
#    installed by Home Manager above. Skip with SKIP_MISE=1.
if [ "${SKIP_MISE:-0}" != "1" ]; then
  mise_bin="$HOME/.nix-profile/bin/mise"
  [ -x "$mise_bin" ] || mise_bin="$(command -v mise 2>/dev/null || true)"
  if [ -n "$mise_bin" ]; then
    echo "== mise install =="
    "$mise_bin" install || true
    # engram exists now → register it with each detected coding agent.
    [ -x "$REPO/scripts/engram-setup" ] && bash "$REPO/scripts/engram-setup" || true
  fi
fi

echo "== verify =="
bash "$REPO/nix/test/verify.sh" || true

cat <<EOF

Done. Per-machine identity (work vs personal) is NOT in the repo. On a work
machine, create it:

  mkdir -p ~/.config/git
  cat > ~/.config/git/local.gitconfig <<'GITEOF'
  [user]
      email = you@work.example
      signingKey = key::ssh-ed25519 AAAA... your-work-key
  GITEOF

Then generate an SSH key on this machine (never committed) and register it:
  ssh-keygen -t ed25519 -C "you@work.example"
EOF

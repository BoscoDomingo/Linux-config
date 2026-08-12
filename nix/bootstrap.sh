#!/usr/bin/env bash
# Bootstrap this Home Manager config on a new machine.
#
#   bash ~/dotfiles/nix/bootstrap.sh            # auto-detects the current host
#   HOST=ubuntu bash ~/dotfiles/nix/bootstrap.sh
#
# HOST must match an entry in flake.nix `homeConfigurations` (arch | arch-wsl |
# ubuntu | macbook). When unset it detects Darwin, Ubuntu, Arch WSL, or Arch.
# Idempotent: safe to re-run to apply changes.
#
# INSTALL_BREW=1 also installs Homebrew (escape hatch for tools not in nixpkgs).
# SKIP_MISE=1 skips `mise install` (language runtimes + pi), e.g. in CI.
# Where GitHub tarball fetch is blocked, use the --override-input technique in
# test/README.md instead.
set -euo pipefail

REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
# Default host from the operating system; override with
# HOST=<arch|arch-wsl|ubuntu|macbook> when needed.
if [ -z "${HOST:-}" ]; then
	if [ "$(uname -s)" = "Darwin" ]; then
		HOST=macbook
	elif grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null &&
		grep -q '^ID=arch' /etc/os-release 2>/dev/null; then
		HOST=arch-wsl
	elif grep -q '^ID=ubuntu' /etc/os-release 2>/dev/null; then
		HOST=ubuntu
	else
		HOST=arch
	fi
fi

case "$HOST" in
arch | arch-wsl | ubuntu | macbook) ;;
*)
	echo "Unknown HOST '$HOST' (expected arch, arch-wsl, ubuntu, or macbook)" >&2
	exit 1
	;;
esac

# 1. Install Nix (Determinate installer; enables flakes by default) if missing.
if ! command -v nix >/dev/null 2>&1; then
	echo "== Installing Nix =="
	curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
		sh -s -- install --no-confirm
	# shellcheck disable=SC1091
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null ||
		. "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Existing Nix installations may not enable the modern CLI globally. Keep the
# bootstrap self-contained without modifying machine-wide Nix configuration.
export NIX_CONFIG="experimental-features = nix-command flakes
${NIX_CONFIG:-}"

# 2. Optional Homebrew (opt-in per machine via INSTALL_BREW=1). .profile picks
#    up its prefix on later shells; bootstrap also exports it immediately.
if [ "${INSTALL_BREW:-0}" = "1" ] && ! command -v brew >/dev/null 2>&1; then
	echo "== Installing Homebrew (INSTALL_BREW=1) =="
	NONINTERACTIVE=1 /bin/bash -c \
		"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
for brew_bin in /home/linuxbrew/.linuxbrew/bin/brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
	if [ -x "$brew_bin" ]; then
		eval "$("$brew_bin" shellenv)"
		break
	fi
done
# Synced Brewfile plus optional overrides/brew/Brewfile.local (device-only).
if command -v brew >/dev/null 2>&1 && [ -f "$REPO/Brewfile" ]; then
	echo "== brew bundle =="
	bash "$REPO/scripts/brew-bundle"
fi

# 3. Build and run the activation package pinned by this repository's flake.lock.
#    The backup extension preserves pre-existing paths during first activation.
echo "== activating $REPO/nix#homeConfigurations.$HOST =="
activation=$(nix build --no-link --print-out-paths \
	"$REPO/nix#homeConfigurations.$HOST.activationPackage")
HOME_MANAGER_BACKUP_EXT=hm-bak "$activation/activate"

# brew shellenv prepends legacy Brew tools earlier in this process. Restore the
# Home Manager profile as the stable-tool owner before mise and verification.
export PATH="$HOME/.nix-profile/bin:$PATH"

# 4. Populate mise-managed tools (language runtimes, pi). mise itself is
#    installed by Home Manager above. Skip with SKIP_MISE=1.
if [ "${SKIP_MISE:-0}" != "1" ]; then
	mise_bin="$HOME/.nix-profile/bin/mise"
	[ -x "$mise_bin" ] || mise_bin="$(command -v mise 2>/dev/null || true)"
	if [ -n "$mise_bin" ]; then
		echo "== mise install =="
		"$mise_bin" install
		# Register the Homebrew-owned Engram with each detected coding agent.
		[ -x "$REPO/scripts/engram-setup" ] && bash "$REPO/scripts/engram-setup" || true
	fi
fi

echo "== verify =="
bash "$REPO/nix/test/verify.sh"

cat <<EOF

Done. Per-machine identity and device-only packages live in the gitignored
overrides/ tree (see Documentation/machine-overrides.md):

  mkdir -p ~/dotfiles/overrides/{git,jj,mise,brew}
  # overrides/git/local.gitconfig  + overrides/jj/local.toml   (work default)
  # overrides/git/{work,personal}.gitconfig + overrides/jj/{work,personal}.toml
  # overrides/mise/config.toml     + overrides/brew/Brewfile.local

Then: bash ~/dotfiles/nix/bootstrap.sh   # refreshes symlinks + brew bundle
      ssh-keygen -t ed25519 -C "you@work.example"   # private key never committed
EOF

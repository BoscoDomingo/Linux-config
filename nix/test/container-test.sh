#!/usr/bin/env bash
# Prove the Home Manager config works in a throwaway Docker container, leaving
# the host untouched (no host /nix, ~/.config, or dotfiles are read or written;
# --rm deletes the container on exit).
#
#   bash nix/test/container-test.sh            # Ubuntu
#   DISTRO=arch bash nix/test/container-test.sh # Arch Linux
#
# Overridable via env:
#   DISTRO   ubuntu | arch        (default: ubuntu)
#   BRANCH   git branch to test   (default: main)
#   HOST     flake host to build  (default: per-distro; ubuntu or arch)
#   IMAGE    base image           (default: per-distro)
#   REPO_URL clone URL            (default: https://github.com/BoscoDomingo/Linux-config)
set -euo pipefail

DISTRO="${DISTRO:-ubuntu}"
BRANCH="${BRANCH:-main}"
REPO_URL="${REPO_URL:-https://github.com/BoscoDomingo/Linux-config}"

case "$DISTRO" in
ubuntu)
	IMAGE="${IMAGE:-ubuntu:24.04}"
	HOST="${HOST:-ubuntu}"
	PREP='export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq curl xz-utils git ca-certificates sudo >/dev/null'
	;;
arch)
	IMAGE="${IMAGE:-archlinux:latest}"
	HOST="${HOST:-arch}"
	PREP='pacman -Syu --noconfirm --needed curl xz git ca-certificates sudo which >/dev/null'
	;;
*)
	echo "unknown DISTRO: $DISTRO (use ubuntu | arch)"
	exit 1
	;;
esac

command -v docker >/dev/null 2>&1 || {
	echo "docker not found on PATH"
	exit 1
}

echo "==> Testing $REPO_URL@$BRANCH (distro: $DISTRO, host: $HOST) in $IMAGE"

# The provisioning script runs INSIDE the container. Single-quoted heredoc: no
# host-side expansion; values arrive as positional args to `bash -s`.
docker run --rm -i "$IMAGE" bash -s -- "$BRANCH" "$HOST" "$REPO_URL" "$PREP" <<'PROVISION'
set -euo pipefail
BRANCH="$1"; HOST="$2"; REPO_URL="$3"; PREP="$4"

# Prerequisites a package manager (not the dotfiles bootstrap) is responsible for.
eval "$PREP"

# The flake pins username "bosco", so run as that user with home /home/bosco.
useradd -m -s /bin/bash bosco
mkdir -p /nix && chown bosco /nix

# User-side script (expanded in the container; \$HOME stays literal so it
# resolves as bosco at run time).
cat > /home/bosco/run-test.sh <<USEREOF
set -euo pipefail

# Single-user Nix (no systemd needed in a container) + flakes.
curl -L https://nixos.org/nix/install -o /tmp/nix-install
sh /tmp/nix-install --no-daemon
. \$HOME/.nix-profile/etc/profile.d/nix.sh
mkdir -p \$HOME/.config/nix
echo "experimental-features = nix-command flakes" > \$HOME/.config/nix/nix.conf

git clone -b "$BRANCH" "$REPO_URL" \$HOME/dotfiles

# Seed per-machine WORK identity + path-scoped repos so verify.sh exercises
# the overrides/ tree. HM activation creates the conf.d / mise symlinks.
mkdir -p \$HOME/dotfiles/overrides/{git,jj,mise,brew} \$HOME/repos \$HOME/personal
printf '[user]\n\temail = you@work.example\n'     > \$HOME/dotfiles/overrides/git/local.gitconfig
printf '[user]\n\temail = you@work.example\n'     > \$HOME/dotfiles/overrides/git/work.gitconfig
printf '[user]\n\temail = you@personal.example\n' > \$HOME/dotfiles/overrides/git/personal.gitconfig
printf '[user]\nemail = "you@work.example"\n'     > \$HOME/dotfiles/overrides/jj/local.toml
printf '--when.repositories = ["~/repos"]\n\n[user]\nemail = "you@work.example"\n' > \$HOME/dotfiles/overrides/jj/work.toml
printf '--when.repositories = ["~/dotfiles", "~/personal"]\n\n[user]\nemail = "you@personal.example"\n' > \$HOME/dotfiles/overrides/jj/personal.toml
printf '[tools]\n' > \$HOME/dotfiles/overrides/mise/config.toml
git init -q \$HOME/repos/acme
git init -q \$HOME/personal/blog

# SKIP_MISE keeps this fast: a full mise install builds node/python/rust and is
# off-purpose for a Nix-layer check. Drop it to also install mise-owned tools.
HOST="$HOST" SKIP_MISE=1 bash \$HOME/dotfiles/nix/bootstrap.sh
echo; echo "==> generations (rollback targets):"
home-manager generations || true
USEREOF
chmod +x /home/bosco/run-test.sh
chown bosco:bosco /home/bosco/run-test.sh

su - bosco -c 'bash /home/bosco/run-test.sh'
PROVISION

echo "==> Container test finished (container already removed)."

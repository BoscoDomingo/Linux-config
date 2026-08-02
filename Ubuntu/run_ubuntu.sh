#!/bin/bash
# First-run bootstrap for a fresh Ubuntu box (incl. WSL). Run as your normal
# sudo user before the repo is cloned:
#
#   sudo apt-get update && sudo apt-get install -y git \
#     && git clone https://github.com/BoscoDomingo/Linux-config.git \
#     && bash Linux-config/Ubuntu/run_ubuntu.sh
#
# It installs the prerequisites a package manager owns (zsh, git, locales, plus
# the build deps mise needs to compile language runtimes), makes zsh the login
# shell, clones the repo, and hands off to nix/bootstrap.sh, which installs Nix
# and activates the generation pinned by nix/flake.lock. Everything else lives
# in the Nix config.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
	zsh git openssh-client curl ca-certificates file procps locales xz-utils \
	build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
	libsqlite3-dev libncursesw5-dev tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# Locales, so character encoding works.
sudo locale-gen en_US.UTF-8 en_GB.UTF-8

# Make zsh the login shell (the Nix config drives the interactive setup).
zsh_bin="$(command -v zsh)"
[ "$SHELL" = "$zsh_bin" ] || chsh -s "$zsh_bin" || echo "Could not change the default shell automatically."

# Clone the repo and hand off to the Nix bootstrap.
[ -d "$HOME/dotfiles" ] || git clone https://github.com/BoscoDomingo/Linux-config.git "$HOME/dotfiles"
HOST=ubuntu bash "$HOME/dotfiles/nix/bootstrap.sh"

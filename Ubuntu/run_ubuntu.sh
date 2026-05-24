#!/bin/bash
# This script can be run manually, before cloning the repo. It will take care of cloning the actual repo and running the installer.

sudo apt update && sudo apt upgrade && sudo apt install -y build-essential locales git curl ca-certificates file procps

# Install locales so character encoding works
sudo locale-gen en_US.UTF-8
sudo locale-gen en_GB.UTF-8

if [ ! -d "$HOME/dotfiles" ]; then
	git clone https://github.com/BoscoDomingo/Linux-config.git "$HOME/dotfiles"
fi

# Mise dependencies
sudo apt install build-essential ca-certificates libssl-dev zlib1g-dev \
	libbz2-dev libreadline-dev libsqlite3-dev curl \
	libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

sudo apt install -y zsh gcp direnv
# direnv alternative
# curl -sfL https://direnv.net/install.sh | bash

cd "$HOME/dotfiles"
printf "\nLaunching the dotfiles installer...\n"
./run.sh

#!/bin/bash
echo "This installer will automatically update your Linux config and dotfiles. All existing dotfiles will be backed up to *.bak.

It assumes certain setup has been done already. If that's not the case, please, check the appropriate run script for your distribution.

It also assumes usage and prior installation of some SSH agent, VS Code/Cursor, and optionally GPG. If you haven't installed them, do it now.

This script must be run from the root of the repository.

Do you want to continue? (Y/n): "

read continue
if [ "$continue" = "n" ]; then
	echo "Exiting..."
	exit 1
fi

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache

mkdir -p $XDG_CONFIG_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_CACHE_HOME

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
CURRENT_DIR="$SCRIPT_DIR"

source "$SCRIPT_DIR/Setup/lib/helpers.sh"

source "$SCRIPT_DIR/Setup/installers/symlinks.sh"
source "$SCRIPT_DIR/Setup/installers/ai-agent-guards.sh"
source "$SCRIPT_DIR/Setup/installers/gpg.sh"
source "$SCRIPT_DIR/Setup/installers/packages.sh"
source "$SCRIPT_DIR/Setup/installers/tools.sh"

exec zsh

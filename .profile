#################################################
# This file should contain the operations common to all shells.
# It should be called within each shell's unique initialisation script.
## Old way, simple
# if [ -e "$HOME/.profile" ]; then
# 	source ~/.profile
# fi

## New way, supposedly the way to go
# [[ -r ~/.profile ]] && emulate sh -c 'source ~/.profile'

#################################################

# Loading text
# GREEN='\033[0;32m'
# BLUE='\033[0;34m'
# YELLOW='\033[0;33m'
# NC='\033[0m' # No Color

# echo -e "${YELLOW}Loading ${GREEN}.profile${NC}"

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export VISUAL=micro
export EDITOR=nvim

if [ -f ~/.profile_secret ]; then
	source ~/.profile_secret
fi

# GPG signing
# export GPG_TTY=$(tty)
# GPG SSH support
# export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
# gpgconf --launch gpg-agent

# Prefer OpenSSH agent for Git/JJ SSH commit signing.
if command -v ssh-add >/dev/null 2>&1; then
  case "${SSH_AUTH_SOCK:-}" in
  "$HOME/.ssh/agent/"*) ;;
  *) unset SSH_AUTH_SOCK ;;
  esac

  if ssh-add -l >/dev/null 2>&1; then
    :
  else
    if [ $? -eq 2 ]; then
      # No reachable SSH agent; start one for this session.
      eval "$(ssh-agent -s)" >/dev/null
    fi
  fi
fi

# SSH signing
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=~/.ssh/known_hosts -o IdentitiesOnly=yes"


# WSL config
if [ -f "/etc/wsl.conf" ] || [ -n "$WSL_DISTRO_NAME" ]; then
	BROWSER=wslview
fi

# if running bash, include .bashrc if it exists and we're not coming from VS Code or Cursor(otherwise it won't load)
if [ -n "$BASH_VERSION" ] && [ -e "$HOME/.bashrc" ] && [ -z "${VSCODE_IPC_HOOK_CLI}" ] && [ "$TERM_PROGRAM" != "Cursor" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
	. "$HOME/.bashrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ]; then
	PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ]; then
	PATH="$HOME/.local/bin:$PATH"
fi
if [ -d "$HOME/.local/bin/scripts" ]; then
	PATH="$HOME/.local/bin/scripts:$PATH"
fi

# Ensures VS Code terminal history is saved without `exit` command
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"

if [ -e "$HOME/.aliases" ]; then
	. ~/.aliases
fi

# Homebrew setup
if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Go. This is needed since mise is instantiated after VS Code is started,
# and the VS Code extension for Go doesn't work properly if the GOPATH is not set.
export PATH="$XDG_DATA_HOME/mise/installs/go/latest/bin:$PATH"
case ":$PATH:" in
	*":$HOME/go/bin:"*) ;;
	*) export PATH="$HOME/go/bin:$PATH" ;;
esac

# C#. This is needed since mise is instantiated after VS Code is started,
# leading to a missing .NET SDK error
export PATH="$XDG_DATA_HOME/mise/installs/dotnet/latest:$PATH"

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
	*":$PNPM_HOME:"*) ;;
	*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Bun
export PATH="/home/bosco/.cache/.bun/bin:$PATH"

# rip2
export RIP_GRAVEYARD="$HOME/.local/share/rip2/graveyard"
if ! [ -d "$RIP_GRAVEYARD" ]; then
	mkdir -p "$RIP_GRAVEYARD"
fi

# broot (if it breaks, use broot --install)
if [ -f "$XDG_CONFIG_HOME/broot/launcher/bash/br" ]; then
	source "$XDG_CONFIG_HOME/broot/launcher/bash/br"
fi

# bat
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/bat.conf"

# Run once a day
if [[ ! -e "/tmp/$(date -I).sem" ]]; then
	touch "/tmp/$(date -I).sem"
	fastfetch
	if [ -n "$(command -v brew)" ]; then
		(brew update &>/dev/null &) # To execute on a subshell and redirect all output to /dev/null
	fi
fi

# Custom commands
## Kill processes on a specific port
killport() {
	if [ -z "$1" ]; then
		echo "Usage: killport <port>"
		echo "Example: killport 3000"
		return 1
	fi

	local port="$1"
	local pids=$(lsof -t -i:"$port" 2>/dev/null)

	if [ -z "$pids" ]; then
		echo "No processes found running on port $port"
		return 0
	fi

	echo "Killing processes on port $port: $pids"
	kill -9 $pids

	if [ $? -eq 0 ]; then
		echo "Successfully killed processes on port $port"
	else
		echo "Failed to kill some processes on port $port"
		return 1
	fi
}

## Check if port is available to Node
check_node_port() {
	node -e "require('net').createServer().listen($1, ()=>console.log('Success (port is available)')).on('error', console.error)"
}

# echo -e "${BLUE}Done loading ${GREEN}.profile${NC}"

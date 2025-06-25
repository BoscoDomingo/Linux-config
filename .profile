# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# WSL browser support
export BROWSER=wslview
# GPG signing with WSL native tools
export GPG_TTY=$(tty)
export VISUAL=nano
export EDITOR=nvim

# Shouldn't be needed for basic functionality.
# Oh-my-zsh does need it in some cases.
# export LANG="en_GB.UTF-8"
# export LC_ALL="en_GB.UTF-8"

# if running bash, include .bashrc if it exists and we're not coming from VS Code (otherwise it won't load)
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

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

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

## Run once a day
if [[ ! -e "/tmp/$(date -I).sem" ]]; then
	touch "/tmp/$(date -I).sem"
	fastfetch
	(brew update &>/dev/null &) # To execute on a subshell and redirect all output to /dev/null
fi

# broot
source "$XDG_CONFIG_HOME/broot/launcher/bash/br"

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

###-Graphite-###
#
# yargs command completion script
#
# Installation: gt completion >> ~/.bashrc
#    or gt completion >> ~/.bash_profile on OSX.
#
_gt_yargs_completions() {
	local cur_word args type_list
	cur_word="${COMP_WORDS[COMP_CWORD]}"
	args=("${COMP_WORDS[@]}")
	# ask yargs to generate completions.
	type_list=$(gt --get-yargs-completions "${args[@]}")
	COMPREPLY=($(compgen -W "${type_list}" -- ${cur_word}))
	# if no match was found, fall back to filename completion
	if [ ${#COMPREPLY[@]} -eq 0 ]; then
		COMPREPLY=()
	fi
	return 0
}
complete -o bashdefault -o default -F _gt_yargs_completions gt
###-Graphite-###

# rip2
export RIP_GRAVEYARD="$HOME/.local/share/rip2/graveyard"
if ! [ -d "$RIP_GRAVEYARD" ]; then
	mkdir -p "$RIP_GRAVEYARD"
fi

# bat config
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/bat.conf"

# tmux config
# Start tmux if not already inside a tmux session and not in VS Code nor Cursor
if command -v tmux >/dev/null 2>&1; then
	# Only needed if not using tmux plugins for this
	# if [ -z "$(ps -a | grep .tmux-resource)" ]; then
	# 	echo "Starting tmux resource monitor"
	# 	~/.tmux-resource-monitor.sh &
	# fi

	# # Debug print to confirm environment variables at the time .profile runs
	# echo "[.profile debug] TMUX=$TMUX, VSCODE_IPC_HOOK_CLI=$VSCODE_IPC_HOOK_CLI, TERM_PROGRAM=$TERM_PROGRAM" 1>&2
	# printenv 1>&2 # Debug print all environment variables

	if [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ] && [ "$TERM_PROGRAM" != "Cursor" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
		tmux a -t default -c "zsh && clear" || tmux new-session -s default -c "zsh && clear"
		# tmux send-keys -t default "zsh" C-m
		# tmux send-keys -t default "clear" C-m
	fi
fi
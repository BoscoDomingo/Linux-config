# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export XDG_CONFIG_HOME="~/.config"
export XDG_DATA_HOME="~/.local/share"
export XDG_CACHE_HOME="~/.cache"

# if running bash, include .bashrc if it exists and we're not coming from VS Code (otherwise it won't load)
if [ -n "$BASH_VERSION" ] && [ -e "$HOME/.bashrc" ] && [ -z "${VSCODE_IPC_HOOK_CLI}" ]; then
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
## Run once a day
if [[ ! -e "/tmp/$(date -I).sem" ]]; then
	touch "/tmp/$(date -I).sem"
	fastfetch
	(brew update &>/dev/null &) # To execute on a subshell and redirect all output to /dev/null
fi

# broot
source /home/bosco/.config/broot/launcher/bash/br

# WSL browser support
export BROWSER=wslview
# GPG signing with WSL native tools
export GPG_TTY=$(tty)
export VISUAL=nano
export EDITOR=nvim

# Go. This is needed since mise is instantiated after VS Code is started,
# and the VS Code extension for Go doesn't work properly if the GOPATH is not set.
export PATH="/home/bosco/.local/share/mise/installs/go/latest/bin:$PATH"
case ":$PATH:" in
	*":$HOME/go/bin:"*) ;;
	*) export PATH="$HOME/go/bin:$PATH" ;;
esac

# C#. This is needed since mise is instantiated after VS Code is started,
# leading to a missing .NET SDK error
export PATH="/home/bosco/.local/share/mise/installs/dotnet/latest:$PATH"

# pnpm
export PNPM_HOME="/home/bosco/.local/share/pnpm"
case ":$PATH:" in
	*":$PNPM_HOME:"*) ;;
	*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

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

# tmux config
# Start tmux if not already inside a tmux session and not in VS CODE
if command -v tmux >/dev/null 2>&1; then
	# Only needed if not using tmux plugins for this
	# if [ -z "$(ps -a | grep .tmux-resource)" ]; then
	# 	echo "Starting tmux resource monitor"
	# 	~/.tmux-resource-monitor.sh &
	# fi

	if [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
		tmux a -t default -c "zsh && clear" || tmux new-session -s default -c "zsh && clear"
		# tmux send-keys -t default "zsh" C-m
		# tmux send-keys -t default "clear" C-m
	fi
fi
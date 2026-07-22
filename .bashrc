# Bash-specific interactive configuration.
# Common interactive config is in .shellrc.

# If coming from VS Code and .profile exists (DO NOT SET `bash -l` IN VS CODE SETTINGS)
if [ -n "${VSCODE_IPC_HOOK_CLI}" ] && [ -e "$HOME/.profile" ]; then
	. "$HOME/.profile"
fi

# Load common interactive config (agent detection, aliases, etc.)
[ -r "$HOME/.shellrc" ] && . "$HOME/.shellrc"

# Guard tool init so an absent tool (minimal shell, agent session) doesn't emit
# "command not found".
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"

# Programmable completion
if ! shopt -oq posix; then
	if [ -f /usr/share/bash-completion/bash_completion ]; then
		. /usr/share/bash-completion/bash_completion
	elif [ -f /etc/bash_completion ]; then
		. /etc/bash_completion
	fi
fi

# fzf
if [ -f ~/.local/.fzf.bash ]; then
	source ~/.local/.fzf.bash
elif command -v fzf >/dev/null 2>&1; then
	eval "$(fzf --bash)"
fi

if [ -z "$_IS_AI_AGENT" ]; then
	# Ensures VS Code terminal history is saved without `exit` command
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"

	# Commented since I use Oh-My-Posh. This is for powerline-go (which works, but not as customisable)
	#GOPATH=$HOME/go
	#function _update_ps1() {
	#    PS1="$($GOPATH/bin/powerline-go -error $? -jobs $(jobs -p | wc -l) -modules time,venv,user,host,ssh,cwd,perms,git,hg,jobs,exit,root -colorize-hostname -max-width 80 -numeric-exit-codes)"
	#
	#    # Uncomment the following line to automatically clear errors after showing
	#    # them once. This not only clears the error for powerline-go, but also for
	#    # everything else you run in that shell. Don't enable this if you're not
	#    # sure this is what you want.
	#
	#    #set "?"
	#}
	#if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
	#    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
	#fi
	command -v oh-my-posh >/dev/null 2>&1 && eval "$(oh-my-posh init bash --config ~/dotfiles/themes/EliteSWE.omp.json)"
fi

# Load Moon shell env when installed without leaving startup with a failed file test.
if [ -f "$HOME/.moon/bin/env" ]; then
	. "$HOME/.moon/bin/env"
fi

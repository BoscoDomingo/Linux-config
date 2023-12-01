# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash, include .bashrc if it exists and we're not coming from VS Code (otherwise it won't load)
if [ -n "$BASH_VERSION" ] && [ -e "$HOME/.bashrc" ] && [ -z "${VSCODE_IPC_HOOK_CLI}" ]; then
	. "$HOME/.bashrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
	PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
	PATH="$HOME/.local/bin:$PATH"
fi
# Ensures VS Code terminal history is saved without `exit` command
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a";

if [ -e "$HOME/.aliases" ]; then
	source ~/.aliases
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# Check if $BASH_VERSION exists
if [ -n "$BASH_VERSION" ]; then
	eval "$(direnv hook bash)"
	eval "$(rtx activate bash)"
	[ -f ~/.fzf.bash ] && source ~/.fzf.bash
	eval "$(oh-my-posh init bash --config ~/shell_themes/niceDark.omp.json)"
fi

# Check if $ZSH_VERSION exists
if [ -n "$ZSH_VERSION" ]; then
	eval "$(direnv hook zsh)"
	eval "$(rtx activate zsh)"
	[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
	eval "$(oh-my-posh init zsh --config ~/shell_themes/niceDark.omp.json)"
fi

source /home/bosco/.config/broot/launcher/bash/br

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# bum (until rtx supports bun)
export BUM_INSTALL="$HOME/.bum"
export PATH=$BUM_INSTALL/bin:$PATH

# pnpm
export PNPM_HOME="/home/bosco/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export GOOGLE_APPLICATION_CREDENTIALS="/home/bosco/.config/gcloud/application_default_credentials.json"

###-begin-gt-completions-###
#
# yargs command completion script
#
# Installation: gt completion >> ~/.bashrc
#    or gt completion >> ~/.bash_profile on OSX.
#
_gt_yargs_completions()
{
			local cur_word args type_list
		cur_word="${COMP_WORDS[COMP_CWORD]}"
		args=("${COMP_WORDS[@]}")
		# ask yargs to generate completions.
		type_list=$(gt --get-yargs-completions "${args[@]}")
		COMPREPLY=( $(compgen -W "${type_list}" -- ${cur_word}) )
		# if no match was found, fall back to filename completion
		if [ ${#COMPREPLY[@]} -eq 0 ]; then
			COMPREPLY=()
		fi
		return 0
}
complete -o bashdefault -o default -F _gt_yargs_completions gt
###-end-gt-completions-###

# eval "$(thefuck --alias)" # If using thefuck
# Pyenv code (if not using rtx)
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

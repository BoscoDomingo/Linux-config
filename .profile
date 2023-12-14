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

# pnpm
export PNPM_HOME="$(rtx where pnpm)"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# eval "$(thefuck --alias)" # If using thefuck
# Pyenv code (if not using rtx)
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash, include .bashrc if it exists and we're not coming from VS Code (otherwise it won't load)
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ] && [ -z "${VSCODE_IPC_HOOK_CLI}" ]; then
	. "$HOME/.bashrc"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
	PATH="$HOME/bin:$PATH"
fi
if [ -d "$HOME/.local/bin" ] ; then
	PATH="$HOME/.local/bin:$PATH"
fi

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(oh-my-posh init bash --config ~/shell_themes/niceDark.omp.json)"
eval "$(rtx activate bash)" # Assuming rtx is installed
eval "$(direnv hook bash)" # Assuming direnv is installed
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Ensures VS Code terminal history is saved without `exit` command
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a";

# eval "$(thefuck --alias)" # If using thefuck

# Pyenv code (if not using rtx)
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# Add this at the bottom of the file

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
elif [ -f /mnt/d/Users/Bosco/.bash_aliases ]; then
  . /mnt/d/Users/Bosco/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# If coming from VS Code and .profile exists (DO NOT SET `bash -l` IN VS CODE SETTINGS)
if [ -n "${VSCODE_IPC_HOOK_CLI}" ] && [ -f "$HOME/.profile" ]; then
  . "$HOME/.profile"
fi

# If using nvm instead of rtx
#export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# GOPATH=$HOME/go
# Commented since I'll be using Oh-My-Posh. This is for powerline-go (which works, but not as customisable)
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
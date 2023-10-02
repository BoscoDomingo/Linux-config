alias lle='eza -a -T -L=1 -1 -l --color auto --icons --group-directories-first --header --created --modified --time-style=long-iso'
alias l='lle --git-ignore'
alias ll='ls -FAGhl --group-directories-first --time-style=long-iso --color'
alias la='ls -A'
# alias lls='lsd -1AFl --total-size'

# alias nano='nano --rcfile ~/.nanorc'
alias pyenv-install='CFLAGS="-I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib" pyenv install'

alias git-delete-untracked-branches="git checkout main && git fetch --prune && LANG=en_US git branch -vv | awk '/: gone]/{print $1}' | xargs git branch -D"
alias gc="git commit --clean=strip -p"
alias gcm="git commit --clean=strip -p -m"
alias gn="git add --renormalize ."

alias gcloud-switch='gcloud config configurations activate'
alias gcloud-project-number='gcloud projects describe $(gcloud config get-value core/project) --format=value\(projectNumber\)'
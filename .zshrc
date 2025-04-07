# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt autocd
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/bosco/.zshrc'
fpath+=~/.config/zsh/completions
# To add more completions, use the completion generation command with a `>` to redirect the output to the file.
# File must be named like `_<command>`
# e.g. `bat --completions zsh > ~/.config/zsh/completions/_bat`

autoload -Uz compinit
compinit
# End of lines added by compinstall

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="superjarin"
# ZSH_THEME="drofloh"
# ZSH_THEME="powerlevel10k/powerlevel10k"
# # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' mode reminder # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 10

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"
# CORRECT_IGNORE_FILE=".turbo|.nx"

# Uncomment to enable correcting only arguments, not commands
# setopt correct
unsetopt correct
unsetopt correct_all

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git
	zsh-interactive-cd
	colored-man-pages
	colorize
	command-not-found
	cp
	docker
)

if [ -d "${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src" ]; then
	fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
fi

source $ZSH/oh-my-zsh.sh

# User configuration
# Enable auto-complete of aliases
setopt complete_aliases

# History
setopt share_history          # share history between all sessions
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands
setopt hist_ignore_space      # ignore commands prefixed with space
setopt hist_reduce_blanks     # remove superfluous blanks from history
setopt hist_verify            # show command with history expansion to user before running it
setopt extended_history       # record timestamp of command in HISTFILE
setopt inc_append_history     # append to HISTFILE instead of overwriting it

if [ -e "$HOME/.profile" ]; then
	source ~/.profile
fi
eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"
if [ -f ~/.local/.fzf.zsh ]; then
	source ~/.local/.fzf.zsh
else
	source <(fzf --zsh)
fi

# Oh My Posh
eval "$(oh-my-posh init zsh --config ~/shell_themes/niceDark.omp.json)"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

if [ -e "$HOME/.local/.mise-completions.zsh" ]; then
	source $HOME/.local/.mise-completions.zsh
fi
if [ -e "$HOME/.local/rip2/completions.zsh" ]; then
	source $HOME/.local/rip2/completions.zsh
fi

## Fzf
# Source: https://dev.to/dshafik/finding-terminal-utopia-583k
_fzf_comprun() {
	local command=$1
	shift

	case "$command" in
		cd) fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
		export | unset) fzf --preview "eval 'echo \$'{}" "$@" ;;
		ssh) fzf --preview 'dig {}' "$@" ;;
		cat | bat) fzf --preview 'bat -n --color=always {}' "$@" ;;
		*) fzf --preview '$HOME/bin/fzf-preview.sh {}' "$@" ;;
	esac
}

_fzf_compgen_path() {
	fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
	fd --type=d --hidden --exclude .git . "$1"
}

# Enable using fzf preview with eza when using tab completion with `cd`
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:*' fzf-preview '$HOME/bin/fzf-preview.sh $realpath'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons=always --git $realpath | head -200'
zstyle ':fzf-tab:*' switch-group '<' '>'

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/bosco/google-cloud-sdk/path.zsh.inc' ]; then
	. '/home/bosco/google-cloud-sdk/path.zsh.inc'
fi
# The next line enables shell command completion for gcloud.
if [ -f '/home/bosco/google-cloud-sdk/completion.zsh.inc' ]; then
	. '/home/bosco/google-cloud-sdk/completion.zsh.inc'
fi

# PostgreSQL
export PATH="/home/linuxbrew/.linuxbrew/opt/postgresql@15/bin:$PATH"
export PKG_CONFIG_PATH="/home/linuxbrew/.linuxbrew/opt/postgresql@15/lib/pkgconfig"

autoload -U +X bashcompinit && bashcompinit

complete -o nospace -C /home/linuxbrew/.linuxbrew/Cellar/opentofu/1.6.1/bin/tofu tofu

export LANG="en_GB.UTF-8"
export LC_ALL="en_GB.UTF-8"

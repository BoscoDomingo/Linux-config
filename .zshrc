# Zsh-specific interactive configuration.
# Common interactive config is in .shellrc.

# Lines configured by zsh-newuser-install
# Export history settings so fzf's child zsh processes can update the same history file.
export HISTFILE=~/.histfile
export HISTSIZE=10000
export SAVEHIST=10000
setopt autocd
bindkey -e
# End of lines configured by zsh-newuser-install

# Keep IDE shell-environment resolvers and other no-TTY probes lightweight while
# still loading the non-interactive environment, direnv, and mise below.
_DOTFILES_HAS_REAL_TTY=0
if [[ -o interactive && -t 0 && -t 1 ]]; then
	_DOTFILES_HAS_REAL_TTY=1
fi

# Load environment and common interactive config
if [[ ! -o login ]] && [[ -r ~/.profile ]]; then
	emulate sh -c 'source ~/.profile'
fi
[[ -r ~/.shellrc ]] && source ~/.shellrc

eval "$(direnv hook zsh)"
eval "$(mise activate zsh)"

# Everything below is non-agent, real-terminal UI only
if [[ -z "$_IS_AI_AGENT" && "$_DOTFILES_HAS_REAL_TTY" = "1" ]]; then
	# MARK: - Oh My Zsh
	# Required for oh-my-zsh
	export LANG="en_GB.UTF-8"
	export LC_ALL="en_GB.UTF-8"
	export ZSH="$HOME/.oh-my-zsh"
	export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST

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
	DISABLE_MAGIC_FUNCTIONS="true"

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

	source $ZSH/oh-my-zsh.sh

	# MARK: - History
	setopt share_history          # share history between all sessions
	setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
	setopt hist_ignore_dups       # ignore duplicated commands
	setopt hist_ignore_space      # ignore commands prefixed with space
	setopt hist_reduce_blanks     # remove superfluous blanks from history
	setopt hist_verify            # show command with history expansion to user before running it
	setopt extended_history       # record timestamp of command in HISTFILE
	setopt inc_append_history     # append to HISTFILE instead of overwriting it

	# MARK: - Autocompletions
	## For tab to work correctly, the completealiases option must be unset (either one of these works)
	unsetopt completealiases
	unsetopt complete_aliases

	# All basic completions
	autoload -U +X bashcompinit && bashcompinit

	zsh_plugin_prefix=""
	zsh_autocomplete_plugin=""
	if [ -n "$(command -v brew)" ]; then
		zsh_plugin_prefix="$(brew --prefix)"
	fi

	if [ -n "$zsh_plugin_prefix" ]; then
		[ -f "$zsh_plugin_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$zsh_plugin_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
		# [ -f "$zsh_plugin_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$zsh_plugin_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
		[ -f "$zsh_plugin_prefix/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ] && source "$zsh_plugin_prefix/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
		[ -d "$zsh_plugin_prefix/share/zsh-completions" ] && fpath+=("$zsh_plugin_prefix/share/zsh-completions")
		[ -f "$zsh_plugin_prefix/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ] && zsh_autocomplete_plugin="$zsh_plugin_prefix/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
	else
		zsh_custom_dir="${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}"
		if [ -f $zsh_custom_dir/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
			# Gives suggestions based on history
			source $zsh_custom_dir/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
		fi
		if [ -f $zsh_custom_dir/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
			source $zsh_custom_dir/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
		fi
		if [ -f $zsh_custom_dir/plugins/zsh-completions/zsh-completions.plugin.zsh ]; then
			# Source: https://github.com/zsh-users/zsh-completions#oh-my-zsh
			# Adds extra completions that my not be present yet in the base completion system
			# Git installation (to have the latest completions):
			# git clone --depth 1 https://github.com/zsh-users/zsh-completions.git \
			#   ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
			# fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
			# To update:
			# git -C .oh-my-zsh/custom/plugins/zsh-completions pull
			fpath+="$zsh_custom_dir/plugins/zsh-completions/src"
		fi
		if [ -f $zsh_custom_dir/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh ]; then
			# Source: https://github.com/marlonrichert/zsh-autocomplete
			# It's responsible for showing potential completions *as you type* underneath the cursor. Same as can be achieved by using tab
			# Shouldn't conflict with other completion systems which show the completion directly in the prompt, after the cursor
			# Git installation (to have the latest completions):
			# git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git \
			#   ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-autocomplete
			# To update:
			# git -C ~zsh-autocomplete pull
			# source $ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
			zsh_autocomplete_plugin="$zsh_custom_dir/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
		fi
	fi

	## To add more completions, there's 3 options:
	## 1. (Best) Load a plugin installed via package manager, git, etc... as above.
	## 2. (Better for "dynamic" completions not present in a plugin) Load them with `source <(command to generate completions)`.
	## 3. (Better for "static" completions) Use the completion generation command with a `>` instead of sourcing them here.
	# File must be named `_<command>` and live in $XDG_CONFIG_HOME/zsh/completions to not be removed when updating oh-my-zsh.
	# Can be out of date and need to be regenerated.
	# e.g. `bat --completion zsh > $XDG_CONFIG_HOME/zsh/completions/_bat`

	## To check if they've been loaded correctly, use `which _<command>` or `type _<command>`

	[ -n "$(command -v mise)" ] && source <(mise completions zsh)
	[ -n "$(command -v moon)" ] && ! [[ "$(command -v moon)" == */mise/shims/* ]] && source <(moon completions)
	if [ -n "$(command -v jj)" ]; then
		# Prefer dynamic completion so bookmark names and revsets are suggested.
		source <(COMPLETE=zsh jj 2>/dev/null || jj util completion zsh)
	fi
	[ -n "$(command -v rip)" ] && source <(rip completions zsh)
	[ -n "$(command -v fzf)" ] && source <(fzf --zsh)
	[ -n "$(command -v fx)" ] && source <(fx --comp zsh)
  [ -n "$(command -v qq)" ] && source <(qq completion zsh)

	## Static/custom completions
	# Files must be named `_<command>` in $XDG_CONFIG_HOME/zsh/completions.
	# e.g. `bat --completion zsh > $XDG_CONFIG_HOME/zsh/completions/_bat`
	fpath=("$XDG_CONFIG_HOME/zsh/completions" $fpath)

	# zsh-autocomplete rewires compdef, so keep it after command completion registration.
	[ -n "$zsh_autocomplete_plugin" ] && source "$zsh_autocomplete_plugin"
	bindkey '^[r' .history-incremental-search-backward
	bindkey '^[s' .history-incremental-search-forward
	# Use one delete-capable history picker for Ctrl-R and Up arrow.
	if (($+widgets[fzf-history-widget])) && command -v zsh-history-fzf >/dev/null 2>&1; then
		_dotfiles_history_widget() {
			local command ret
			setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null

			# Write pending session history before browsing the shared history file.
			builtin fc -AI "$HISTFILE"
			command="$(zsh-history-fzf pick "$LBUFFER")"
			ret=$?

			if ((ret == 0)) && [[ -n "$command" ]]; then
				BUFFER="$command"
				CURSOR=${#BUFFER}
			fi

			# Refresh the live shell's history list after deletions made inside fzf.
			builtin fc -R "$HISTFILE"
			zle reset-prompt
			return $ret
		}

		zle -N fzf-history-widget _dotfiles_history_widget
		bindkey -M emacs '^R' fzf-history-widget
		bindkey -M vicmd '^R' fzf-history-widget
		bindkey -M viins '^R' fzf-history-widget

		_dotfiles_up_history_widget_with_delete() {
			if [[ $LBUFFER == *$'\n'* ]]; then
				builtin zle up-line
			else
				builtin zle fzf-history-widget
			fi
		}

		zle -N up-line-or-search _dotfiles_up_history_widget_with_delete
		bindkey -M emacs '^[[A' up-line-or-search
		bindkey -M viins '^[[A' up-line-or-search
	fi

	unalias gcp
  unalias gga
	alias reload='source ~/.zshrc'
	alias full_reload="exec zsh"
	alias reload_w_tmux="DOTFILES_AUTO_TMUX=1 zsh"

	# MARK: - fzf
	## Source: https://dev.to/dshafik/finding-terminal-utopia-583k
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

	## Enable using fzf preview with eza when using tab completion with `cd`
	zstyle ':completion:*' menu select
	zstyle ':autocomplete:*' cycle yes
	zstyle ':autocomplete:*' insert-unambiguous no
	zstyle ':autocomplete:*' add-semicolon no
	zstyle ':fzf-tab:complete:*' fzf-preview '$HOME/bin/fzf-preview.sh $realpath'
	zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons=always --git $realpath | head -200'
	zstyle ':fzf-tab:*' switch-group '<' '>'

	# Prevent ~ from being expanded when cycling completions
	# (zsh-autocomplete's custom _expand ignores keep-prefix, so remove it from the completer list)
	zstyle ':completion:*' completer _complete _complete:-fuzzy _correct _approximate _ignored
	# Style options for autocomplete
	zstyle ':autocomplete:*' append-semicolon no
	zstyle ':autocomplete:*' min-input 3

	# Left and right arrow always edit current command, not search through history
	# bindkey -M menuselect '^[[D' .backward-char '^[OD' .backward-char
	# bindkey -M menuselect '^[[C' .forward-char '^[OC' .forward-char

	# Tab cycles forward, Shift+Tab cycles backward
	bindkey '^I' menu-complete
	bindkey "$terminfo[kcbt]" reverse-menu-complete

	# export MANPATH="/usr/local/man:$MANPATH"

	# Preferred editor for local and remote sessions
	# if [[ -n $SSH_CONNECTION ]]; then
	#   export EDITOR='vim'
	# else
	#   export EDITOR='nvim'
	# fi

	# Compilation flags
	# export ARCHFLAGS="-arch x86_64"

	# MARK: Aliases
	# Set personal aliases, overriding those provided by oh-my-zsh libs,
	# plugins, and themes. Aliases can be placed here, though oh-my-zsh
	# users are encouraged to define aliases within the ZSH_CUSTOM folder.
	# For a full list of active aliases, run `alias`.
	#
	# Example aliases
	# alias zshconfig="mate ~/.zshrc"
	# alias ohmyzsh="mate ~/.oh-my-zsh"

	# Onefetch on cd to a new repository
	LAST_REPO=""

	cd() {
		builtin cd "$@"
		git rev-parse 2>/dev/null

		if [ $? -eq 0 ]; then
			if [ "$LAST_REPO" != "$(basename "$(git rev-parse --show-toplevel)")" ]; then
				onefetch
				LAST_REPO=$(basename "$(git rev-parse --show-toplevel)")
			fi
		fi
	}

	# MARK: - Prompt
	eval "$(oh-my-posh init zsh --config ~/dotfiles/themes/EliteSWE.omp.json)"

	# MARK: - Windows Terminal
	_windows_terminal_cwd() {
		[[ -n "$WT_SESSION" ]] || return
		[[ -n "$WSL_DISTRO_NAME" ]] || return
		command -v wslpath >/dev/null 2>&1 || return

		printf "\e]9;9;%s\e\\" "$(wslpath -w "$PWD")"
	}
	precmd_functions+=(_windows_terminal_cwd)

	# MARK: - Tmux
	# Default to native terminals; set DOTFILES_AUTO_TMUX=1 to opt into auto-attach.
	: ${DOTFILES_AUTO_TMUX:=0}
	if [[ "$DOTFILES_AUTO_TMUX" = "1" ]]; then
		$XDG_CONFIG_HOME/tmux/start-tmux.sh
	fi
fi

# Load Moon shell env when installed without leaving startup with a failed file test.
if [ -f "$HOME/.moon/bin/env" ]; then
	. "$HOME/.moon/bin/env"
fi

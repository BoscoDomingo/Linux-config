# Non-interactive environment setup for all shells.
# Sourced by .zprofile (zsh login) and the rc files.
# Interactive config lives in .shellrc; shell-specific config in .zshrc/.bashrc.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export VISUAL=micro
export EDITOR=nvim

if [ -f ~/.profile_secret ]; then
	source ~/.profile_secret
fi

# GPG signing (disabled; using SSH signing instead)
# export GPG_TTY=$(tty)
# GPG SSH support
# export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
# gpgconf --launch gpg-agent

# Prefer OpenSSH agent for Git/JJ SSH commit signing.
# Use a fixed socket path so the agent survives shell reloads.
if command -v ssh-add >/dev/null 2>&1; then
	_ssh_agent_sock="$HOME/.ssh/agent/agent.sock"
	export SSH_AUTH_SOCK="$_ssh_agent_sock"

	ssh-add -l >/dev/null 2>&1
	_ssh_add_rc=$?
	if [ "$_ssh_add_rc" -eq 2 ]; then
		# No reachable agent at our socket; start one.
		mkdir -p "$HOME/.ssh/agent"
		/usr/bin/rm -f "$_ssh_agent_sock"
		eval "$(ssh-agent -a "$_ssh_agent_sock" -s)" >/dev/null
		unset SSH_AGENT_PID
	fi
	unset _ssh_add_rc

	unset _ssh_agent_sock
fi

# SSH signing
export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=~/.ssh/known_hosts -o IdentitiesOnly=yes"

# WSL config
if [ -f "/etc/wsl.conf" ] || [ -n "$WSL_DISTRO_NAME" ]; then
	BROWSER=wslview

	# ---- WSL: DBus session + GNOME keyring (secrets manager service) ----
	# Start a user DBus session if not present
	if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
		eval "$(dbus-launch --sh-syntax 2>/dev/null)"
	fi

	# Start GNOME keyring (provides org.freedesktop.secrets via DBus)
	if command -v gnome-keyring-daemon >/dev/null; then
		eval "$(gnome-keyring-daemon --start --components=secrets 2>/dev/null)"
	fi
fi

# MARK: Add user bin directories to PATH if not already present.
_path_prepend_if_missing() {
	local argpath="$1"
	case ":$PATH:" in
	*":$argpath:"*) ;;
	*) [ -d "$argpath" ] && PATH="$argpath:$PATH" ;;
	esac
}

_path_prepend_if_missing "$HOME/bin"

_path_prepend_if_missing "$HOME/.local/bin"

_path_prepend_if_missing "$HOME/.local/bin/scripts"

# Homebrew
if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
	case ":$PATH:" in
	*":/home/linuxbrew/.linuxbrew/bin:"*) ;;
	*) eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" ;;
	esac
fi

# This is needed since mise is instantiated after VS Code is started,
# and the VS Code extension for Go and C# don't work properly otherwise.
case ":$PATH:" in
*":$HOME/.local/share/mise/shims:"*) ;;
*) export PATH="$HOME/.local/share/mise/shims:$PATH" ;;
esac

# pnpm
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
case ":$PATH:" in
*":$HOME/.opencode/bin:"*) ;;
*) export PATH="$HOME/.opencode/bin:$PATH" ;;
esac

# rip2
export RIP_GRAVEYARD="$HOME/.local/share/rip2/graveyard"
if ! [ -d "$RIP_GRAVEYARD" ]; then
	mkdir -p "$RIP_GRAVEYARD"
fi

# bat
export BAT_CONFIG_PATH="$XDG_CONFIG_HOME/bat/bat.conf"

# Source .bashrc for interactive bash login shells
# (VS Code/Cursor start non-login shells and handle this in .bashrc instead)
if [ -n "$BASH_VERSION" ] && [ -e "$HOME/.bashrc" ] && [ -z "${VSCODE_IPC_HOOK_CLI}" ] && [ "$TERM_PROGRAM" != "Cursor" ] && [ "$TERM_PROGRAM" != "vscode" ]; then
	. "$HOME/.bashrc"
fi

[ -f "$HOME/.moon/bin/env" ] && . "$HOME/.moon/bin/env"

# Normalize PATH for shells inheriting duplicated entries from parent sessions.
_path_dedupe() {
	local old_ifs="$IFS"
	local entry
	local deduped_path=""

	IFS=:
	for entry in $PATH; do
		[ -n "$entry" ] || continue
		case ":$deduped_path:" in
		*":$entry:"*) ;;
		*) deduped_path="${deduped_path:+$deduped_path:}$entry" ;;
		esac
	done
	IFS="$old_ifs"

	PATH="$deduped_path"
	export PATH
}

_path_dedupe

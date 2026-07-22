# MARK: - Zsh Setup
printf "\n=== Zsh Setup ===\n"

zsh_bin=$(command -v zsh || true)
if [ -n "$zsh_bin" ] && [ "$SHELL" != "$zsh_bin" ]; then
	chsh -s "$zsh_bin" || echo "Unable to change the default shell automatically."
fi

# MARK: - Config Files Setup
printf "\n=== Config Files Setup ===\n"

read -p "Do you want to backup and link existing dotfiles? (Y/n): " setup_dotfiles
if [ "$setup_dotfiles" != "n" ]; then
	for config_file in .profile .shellrc .aliases .bashrc .zshrc .zprofile .nanorc .nirc .npmrc .bunfig.toml .gitconfig .gitignore_global; do
		ensure_link "$CURRENT_DIR/$config_file" "$HOME/$config_file"
	done

	if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
		ensure_link "$CURRENT_DIR/Ubuntu/.zshenv" "$HOME/.zshenv"
	fi
fi

read -p "Do you want to symlink the config files & scripts? (Y/n): " setup_config_files
if [ "$setup_config_files" != "n" ]; then
	mkdir -p "$HOME/.local/bin"
	ensure_link "$CURRENT_DIR/scripts" "$HOME/.local/bin/scripts"

	# Automatically link all subdirectories in .config to $XDG_CONFIG_HOME
	for config_dir in "$CURRENT_DIR"/.config/*/; do
		if [ -d "$config_dir" ]; then
			dir_name=$(basename "$config_dir")
			ensure_link "$config_dir" "$XDG_CONFIG_HOME/$dir_name"
		fi
	done
fi

# MARK: - Cursor Settings Setup
printf "\n=== Cursor Settings Setup ===\n"
read -p "Do you want to symlink the Cursor settings? (Y/n): " link_cursor_settings
if [ "$link_cursor_settings" != "n" ]; then
	mkdir -p "$XDG_CONFIG_HOME/Cursor/User"
	mkdir -p "$HOME/.cursor/extensions"
	mkdir -p "$HOME/.cursor-server/extensions"
	mkdir -p "$HOME/.vscode-server"
	# WSL IDE servers can fall back to Windows PATH; expose user-managed tools to extensions.
	ensure_link "$CURRENT_DIR/vscode/server-env-setup" "$HOME/.cursor-server/server-env-setup"
	ensure_link "$CURRENT_DIR/vscode/server-env-setup" "$HOME/.vscode-server/server-env-setup"
	# Cursor and VS Code can ignore server-env-setup here, so patch server launchers to source it.
	for ide_server_bin in "$HOME"/.cursor-server/bin/*/bin/cursor-server "$HOME"/.vscode-server/bin/*/bin/code-server; do
		[ -f "$ide_server_bin" ] || continue
		if ! grep -q "DOTFILES_IDE_SERVER_ENV_SETUP" "$ide_server_bin" && ! grep -q "DOTFILES_CURSOR_SERVER_ENV_SETUP" "$ide_server_bin"; then
			cp -p "$ide_server_bin" "$ide_server_bin.bak"
			awk '
				{
					print
					if ($0 ~ /^ROOT=/) {
						print ""
						print "# Load dotfiles-managed PATH before IDE extension hosts start."
						print "DOTFILES_IDE_SERVER_ENV_SETUP=\"$HOME/.cursor-server/server-env-setup\""
						print "if [ ! -r \"$DOTFILES_IDE_SERVER_ENV_SETUP\" ]; then"
						print "\tDOTFILES_IDE_SERVER_ENV_SETUP=\"$HOME/.vscode-server/server-env-setup\""
						print "fi"
						print "if [ -r \"$DOTFILES_IDE_SERVER_ENV_SETUP\" ]; then"
						print "\t. \"$DOTFILES_IDE_SERVER_ENV_SETUP\""
						print "fi"
					}
				}
			' "$ide_server_bin" >"$ide_server_bin.tmp" && mv "$ide_server_bin.tmp" "$ide_server_bin"
			chmod +x "$ide_server_bin"
		fi
	done
	ensure_link "$CURRENT_DIR/vscode/settings.json" "$XDG_CONFIG_HOME/Cursor/User/settings.json"
	ensure_link "$CURRENT_DIR/vscode/keybindings.json" "$XDG_CONFIG_HOME/Cursor/User/keybindings.json"
	ensure_link "$CURRENT_DIR/vscode/extensions-cursor.json" "$HOME/.cursor/extensions/extensions.json"
	ensure_link "$CURRENT_DIR/vscode/extensions-cursor-wsl.json" "$HOME/.cursor-server/extensions/extensions.json"
fi

printf "\n=== Pi Agent Settings Setup ===\n"
read -p "Do you want to symlink the Pi settings? (Y/n): " link_pi_settings
if [ "$link_pi_settings" != "n" ]; then
	mkdir -p "$HOME/.pi/agent"
	ensure_link "$CURRENT_DIR/AI/.pi/agent/" "$HOME/.pi/agent/"

	# Keep Pi permission defaults in dotfiles while preserving the extension's expected path.
	mkdir -p "$HOME/.pi/agent/extensions/pi-permission-system"
	ensure_link "$CURRENT_DIR/AI/.pi/agent/extensions/pi-permission-system/config.json" "$HOME/.pi/agent/extensions/pi-permission-system/config.json"
fi

# MARK: - SSH Config Setup
printf "\n=== SSH Config Setup ===\n"
read -p "Do you want to symlink the SSH config? (Y/n): " link_ssh_config
if [ "$link_ssh_config" != "n" ]; then
	mkdir -p "$HOME/.ssh"
	ensure_link "$CURRENT_DIR/.ssh/config" "$HOME/.ssh/config"
	ensure_link "$CURRENT_DIR/.ssh/allowed_signers" "$HOME/.ssh/allowed_signers"
fi

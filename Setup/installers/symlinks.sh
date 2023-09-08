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
for config_file in [".profile" ".shellrc" ".aliases" ".bashrc" ".zshrc" ".zprofile" ".nanorc" ".nirc" ".npmrc" ".bunfig.toml", ".gitconfig", ".gitignore_global"]; do
	ensure_link "$CURRENT_DIR/.$config_file" "$HOME/$config_file"
done

	if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
		ensure_link "$CURRENT_DIR/Ubuntu/.zshenv" "$HOME/.zshenv"
	fi
fi

read -p "Do you want to symlink the config files & scripts? (Y/n): " setup_config_files
if [ "$setup_config_files" != "n" ]; then
	mkdir -p "$HOME/.local/bin"
	for script_path in "$CURRENT_DIR"/scripts/*; do
		if [ -f "$script_path" ]; then
			script_name=$(basename "$script_path")
			ensure_link "$script_path" "$HOME/.local/bin/$script_name"
		fi
	done

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
	# Cursor WSL can fall back to Windows PATH; expose user-managed tools to extensions.
	ensure_link "$CURRENT_DIR/vscode/server-env-setup" "$HOME/.cursor-server/server-env-setup"
	# Cursor currently ignores server-env-setup here, so patch its server launcher to source it.
	for cursor_server_bin in "$HOME"/.cursor-server/bin/*/bin/cursor-server; do
		[ -f "$cursor_server_bin" ] || continue
		if ! grep -q "DOTFILES_CURSOR_SERVER_ENV_SETUP" "$cursor_server_bin"; then
			cp -p "$cursor_server_bin" "$cursor_server_bin.bak"
			awk '
				{
					print
					if ($0 ~ /^ROOT=/) {
						print ""
						print "# Load dotfiles-managed PATH before Cursor starts extension hosts."
						print "DOTFILES_CURSOR_SERVER_ENV_SETUP=\"$HOME/.cursor-server/server-env-setup\""
						print "if [ -r \"$DOTFILES_CURSOR_SERVER_ENV_SETUP\" ]; then"
						print "\t. \"$DOTFILES_CURSOR_SERVER_ENV_SETUP\""
						print "fi"
					}
				}
			' "$cursor_server_bin" >"$cursor_server_bin.tmp" && mv "$cursor_server_bin.tmp" "$cursor_server_bin"
			chmod +x "$cursor_server_bin"
		fi
	done
	ensure_link "$CURRENT_DIR/vscode/settings.json" "$XDG_CONFIG_HOME/Cursor/User/settings.json"
	ensure_link "$CURRENT_DIR/vscode/keybindings.json" "$XDG_CONFIG_HOME/Cursor/User/keybindings.json"
	ensure_link "$CURRENT_DIR/vscode/extensions-cursor.json" "$HOME/.cursor/extensions/extensions.json"
	ensure_link "$CURRENT_DIR/vscode/extensions-cursor-wsl.json" "$HOME/.cursor-server/extensions/extensions.json"
fi

# MARK: - SSH Config Setup
printf "\n=== SSH Config Setup ===\n"
read -p "Do you want to symlink the SSH config? (Y/n): " link_ssh_config
if [ "$link_ssh_config" != "n" ]; then
	mkdir -p "$HOME/.ssh"
	ensure_link "$CURRENT_DIR/.ssh/config" "$HOME/.ssh/config"
	ensure_link "$CURRENT_DIR/.ssh/allowed-signers" "$HOME/.ssh/allowed-signers"
fi

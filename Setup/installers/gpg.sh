# MARK: - GPG Config Setup
printf "\n=== GPG Config Setup ===\n"
read -p "Do you want to symlink the GPG agent config? (y/N): " link_gpg_agent_config
if [ "$link_gpg_agent_config" = "y" ]; then
	mkdir -p "$HOME/.gnupg"
	chmod 700 "$HOME/.gnupg"
	ensure_link "$CURRENT_DIR/gpg-agent.conf" "$HOME/.gnupg/gpg-agent.conf"
fi

# Import GPG key and setup SSH authentication
printf "\n=== GPG Key Setup ===\n"
read -p "Do you want to import a GPG key now? (y/N): " import_gpg
if [ "$import_gpg" = "y" ]; then
	read -p "Enter path to GPG key (.asc file): " gpg_key_path
	if [ -f "$gpg_key_path" ]; then
		gpg --import "$gpg_key_path"
		echo "GPG key imported successfully!"

		# Set ultimate trust
		read -p "Enter the email associated with the key or the key ID: " gpg_email
		echo "Setting ultimate trust for $gpg_email..."
		echo "If this fails, do it manually by running: gpg --edit-key $gpg_email, then trust, 5, y, save, and quit."
		echo -e "trust\n5\ny\nsave\n" | gpg --command-fd 0 --edit-key "$gpg_email"

		# Setup SSH authentication
		echo "\nListing keys to find authentication subkey..."
		gpg --list-keys --with-keygrip "$gpg_email"
		echo "\nLook for the subkey containing [A] above."
		read -p "Enter the keygrip of your authentication subkey: " auth_keygrip
		if [ -n "$auth_keygrip" ]; then
			append_if_missing "$auth_keygrip" "$HOME/.gnupg/sshcontrol"
			echo "Authentication subkey added to sshcontrol!"

			# Restart gpg-agent and show SSH public key
			gpgconf --kill gpg-agent
			gpgconf --launch gpg-agent
			export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
			echo "\nYour SSH public key (should be present in GitHub):"
			ssh-add -L
			echo "\nTesting SSH connection to GitHub..."
			ssh -T git@github.com
			if [ $? -eq 0 ]; then
				echo "SSH connection to GitHub successful!"
			else
				echo "SSH connection to GitHub failed. Please check your SSH key and try again."
			fi
		fi
	else
		echo "File not found: $gpg_key_path"
	fi
else
	echo "Skipping GPG key import. You can import it later with: gpg --import <path/to/key.asc>"
fi

# MARK: - Oh My Posh
printf "\n=== Oh My Posh Setup ===\n"
read -p "Install Oh My Posh? (Y/n): " install_omz
if [ "$install_omz" != "n" ]; then
	curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# MARK: - tmux
printf "\n=== Tmux Setup ===\n"
read -p "Do you want to install tmux and tpm? (Y/n): " install_tmux
if [ "$install_tmux" != "n" ]; then
	echo "Installing tmux..."
	if command -v brew >/dev/null 2>&1 && brew install tmux; then
		mkdir -p "$HOME/.tmux/plugins"
		if [ -d "$HOME/.tmux/plugins/tpm/.git" ]; then
			git -C "$HOME/.tmux/plugins/tpm" pull --ff-only
		elif [ -d "$HOME/.tmux/plugins/tpm" ]; then
			echo "TPM already exists and is not a git repository. Leaving it as-is."
		else
			git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
		fi
		printf "\nInstalled tmux and tpm. Run Ctrl + B, I to install plugins inside tmux\n"
	else
		echo "Skipping TPM install because tmux could not be installed."
	fi
else
	echo "Skipping tmux installation."
fi
## mise doesn't work to handle tmux versions unfortunately
# mise use -g tmux@latest

# MARK: - Micro themes
read -p "Do you want to download the latest Catppuccin themes for Micro? (Y/n): " download_catppuccin_themes
if [ "$download_catppuccin_themes" != "n" ]; then
	micro_colors_dir="$XDG_CONFIG_HOME/micro/colorschemes"
	mkdir -p "$micro_colors_dir"
	curl -fsSL "https://raw.githubusercontent.com/catppuccin/micro/refs/heads/main/themes/catppuccin-macchiato-transparent.micro" -o "$micro_colors_dir/catppuccin-macchiato-transparent.micro"
	curl -fsSL "https://raw.githubusercontent.com/catppuccin/micro/refs/heads/main/themes/catppuccin-macchiato.micro" -o "$micro_colors_dir/catppuccin-macchiato.micro"
fi

# MARK: - Oh My Zsh
read -p "Do you want to install oh-my-zsh? (Y/n): " install_oh_my_zsh
if [ "$install_oh_my_zsh" != "n" ]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

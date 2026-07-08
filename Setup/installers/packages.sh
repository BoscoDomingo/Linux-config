HOMEBREW_BIN="${HOMEBREW_BIN:-/home/linuxbrew/.linuxbrew/bin/brew}"

if [ -x "$HOMEBREW_BIN" ]; then
	eval "$("$HOMEBREW_BIN" shellenv)"
fi

printf "\n=== Package Managers Setup ===\n"

# MARK: - Homebrew
# Zerobrew and Nanobrew may be worth revisiting once they are more mature. For now Brew is the only real option
printf "\n=== Homebrew Setup ===\n"
read -p "Do you want to install Homebrew? (Y/n): " install_homebrew_choice
if [ "$install_homebrew_choice" != "n" ]; then
	if command -v brew >/dev/null 2>&1; then
		echo "Homebrew is already installed."
	else
		echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [ -x "$HOMEBREW_BIN" ]; then
			eval "$("$HOMEBREW_BIN" shellenv)"
		fi
	fi
else
	echo "Skipping Homebrew installation."
fi

read -p "Do you want to install Homebrew packages? (Y/n): " install_homebrew_packages
if [ "$install_homebrew_packages" != "n" ]; then
	if command -v brew >/dev/null 2>&1; then
		# The CLI toolbox is managed by Nix / Home Manager (nix/home/packages.nix),
		# which pins versions and installs them identically on every machine.
		# Homebrew stays available on all platforms (incl. Linux) as an escape
		# hatch for tools not in nixpkgs; macOS GUI casks are declared via
		# nix-darwin's `homebrew` module (nix/hosts/macbook.nix).
		# See ../../Documentation/Nix_exploration.md#9-tool-ownership--retiring-runsh
		packages=(
			# Add ad-hoc formulae here only for tools that aren't in nixpkgs.
		)
		if [ "${#packages[@]}" -gt 0 ]; then
			echo "Installing ${#packages[@]} package(s) via Homebrew..."
			brew install "${packages[@]}"
		else
			echo "No Homebrew formulae to install (the toolbox is managed by Nix)."
		fi
	else
		echo "Homebrew is not available yet. Skipping package installation."
	fi
fi

# MARK: - mise (dependencies should've been installed already)
printf "\n=== Mise Setup ===\n"
read -p "Do you want to install mise? (Y/n): " install_mise
if [ "$install_mise" != "n" ]; then
	echo "Installing Mise..."
	curl https://mise.run | sh
	eval "$(/home/bosco/.local/bin/mise activate zsh)"

	read -p "Run mise install? (Y/n): " "mise_install"
	if [ "$mise_install" != "n" ]; then
		mise install
	fi
else
	echo "Skipping mise installation."
fi

read -p "Do you want to install global npm packages (pnpm, ni, biome)? (Y/n): " install_npm_globals
if [ "$install_npm_globals" != "n" ]; then
	npx pnpm i -g pnpm
	pnpm i -g @antfu/ni @biomejs/biome
	bun install -g @antfu/ni @biomejs/biome
else
	echo "Skipping global npm packages installation."
fi

# Python
# Installation extras (they kinda break, so don't use unless necessary)
# brew unlink pkg-config && \
# CFLAGS="-I$(brew --prefix openssl)/include" \
# LDFLAGS="-L$(brew --prefix openssl)/lib" \
# mise use -g python@latest; \
# mise upgrade python; \
# brew link pkg-config

# To install useful key bindings and fuzzy completion for fzf.
# Not necessary since result's already in .profile, here for reference
# $(brew --prefix)/opt/fzf/install
# mv ~/.fzf.* ~/.local

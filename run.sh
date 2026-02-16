#!/bin/bash
echo "This installer will automatically update your Linux config and dotfiles. All existing dotfiles will be backed up to *.bak.

It assumes certain setup has been done already. If that's not the case, please, check the appropriate run script for your distribution.

It also assumes usage and prior installation of GPG and VS Code/Cursor. If you haven't installed them, do it now.

This script must be run from the root of the repository.

Do you want to continue? (Y/n): "

read continue
if [ "$continue" = "n" ]; then
  echo "Exiting..."
  exit 1
fi

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache

mkdir -p $XDG_CONFIG_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_CACHE_HOME

# Set up zsh
printf "\n=== Zsh Setup ===\n"
# zsh
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
fi


printf "\n=== Config Files Setup ===\n"
# Setup config files and backup existing ones
CURRENT_DIR=$(pwd)

ensure_link() {
  src="${1%/}"
  dst="$2"

  if [ -L "$dst" ]; then
    current_target=$(readlink "$dst")
    current_target="${current_target%/}"
    if [ "$current_target" = "$src" ]; then
      return
    fi
    mv "$dst" "$dst.bak"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.bak"
  fi

  ln -s "$src" "$dst"
}

read -p "Do you want to backup and link existing dotfiles? (Y/n): " setup_dotfiles
if [ "$setup_dotfiles" != "n" ]; then
  ensure_link "$CURRENT_DIR/.profile" "$HOME/.profile"
  ensure_link "$CURRENT_DIR/.aliases" "$HOME/.aliases"
  ensure_link "$CURRENT_DIR/.bashrc" "$HOME/.bashrc"
  ensure_link "$CURRENT_DIR/.zshrc" "$HOME/.zshrc"
  ensure_link "$CURRENT_DIR/.nanorc" "$HOME/.nanorc"
  ensure_link "$CURRENT_DIR/.nirc" "$HOME/.nirc"

  if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    ensure_link "$CURRENT_DIR/Ubuntu/.zshenv" "$HOME/.zshenv"
  fi

  ensure_link "$CURRENT_DIR/.gitconfig" "$HOME/.gitconfig"
  ensure_link "$CURRENT_DIR/.gitignore_global" "$HOME/.gitignore_global"
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
  for config_dir in $CURRENT_DIR/.config/*/; do
    if [ -d "$config_dir" ]; then
      dir_name=$(basename "$config_dir")
      ensure_link "$config_dir" "$XDG_CONFIG_HOME/$dir_name"
    fi
  done
fi

printf "\n=== Cursor Settings Setup ===\n"
read -p "Do you want to symlink the Cursor settings? (Y/n): " link_cursor_settings
if [ "$link_cursor_settings" != "n" ]; then
  mkdir -p "$XDG_CONFIG_HOME/Cursor/User"
  ensure_link "$CURRENT_DIR/vscode/settings.json" "$XDG_CONFIG_HOME/Cursor/User/settings.json"
  ensure_link "$CURRENT_DIR/vscode/keybindings.json" "$XDG_CONFIG_HOME/Cursor/User/keybindings.json"
fi

printf "\n=== SSH Config Setup ===\n"
read -p "Do you want to symlink the SSH config? (Y/n): " link_ssh_config
if [ "$link_ssh_config" != "n" ]; then
  mkdir -p "$HOME/.ssh"
  ensure_link "$CURRENT_DIR/.ssh/config" "$HOME/.ssh/config"
fi

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
      echo "$auth_keygrip" >> $HOME/.gnupg/sshcontrol
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

# Install Homebrew and dependencies
printf "\n=== Homebrew Setup ===\n"
read -p "Install Homebrew and Zerobrew? (Y/n/h/z): " brew_choice
case "$brew_choice" in
  [nN]*)
    echo "Skipping Homebrew/Zerobrew installation."
    ;;
  [hH]*)
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    ;;
  [zZ]*)
    echo "Installing Zerobrew..."
    curl -sSL https://zerobrew.rs/install | bash
    echo 'source <(zb completion zsh)' >> ~/.zshrc
    ;;
  *)
    echo "Installing Homebrew and Zerobrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    curl -sSL https://zerobrew.rs/install | bash
    echo 'source <(zb completion zsh)' >> ~/.zshrc
    ;;
esac

read -p "Do you want to install Homebrew packages? (Y/n)" install_brew
if [ "$install_brew" != "n" ]; then
brew install gcc \
  cheat \
  progress \
  bottom \
  eza \
  bfs \
  fd \
  broot \
  fzf \
  bat \
  tailspin \
  zsh-autosuggestions \
  zsh-fast-syntax-highlighting \
  zsh-autocomplete \
  zsh-completions \
  trippy \
  ugrep \
  ripgrep \
  gping \
  hyperfine \
  superfile \
  httpstat \
  btop \
  duf \
  rip2 \
  sshs \
  git-delta \
  fx \
  fastfetch \
  onefetch
fi

# Oh My Posh
printf "\n=== Oh My Posh Setup ===\n"
read -p "Install Oh My Posh? (Y/n)" install_omz
if [ "$install_omz" != "n" ]; then
	curl -s https://ohmyposh.dev/install.sh | bash -s
fi

# tmux
printf "\n=== Tmux Setup ===\n"
read -p "Do you want to install tmux and tpm? (Y/n): " install_tmux
if [ "$install_tmux" != "n" ]; then
  echo "Installing tmux..."
  brew install tmux
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  printf "\nInstalled tmux and tpm. Run Ctrl + B, I to install plugins inside tmux\n"
else
  echo "Skipping tmux installation."
fi
## mise doesn't work to handle tmux versions unfortunately
# mise use -g tmux@latest

# Install mise (dependencies should've been installed already)
printf "\n=== Mise Setup ===\n"
read -p "Do you want to install mise? (Y/n): " install_mise
if [ "$install_mise" != "n" ]; then
  echo "Installing Mise..."
  curl https://mise.run | sh

  read -p "Run `mise install`? (Y/n): " "mise_install"
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

# Currently using tldr++ (https://github.com/isacikgoz/tldr)
read -p "Do you want to install tldr++ via mise? (Y/n): " install_tldr
if [ "$install_tldr" != "n" ]; then
  mise use -g tldr++@latest
else
  echo "Skipping tldr++ installation."
fi
# Alternatives: tlrc (https://github.com/tldr-pages/tlrc) or Tealdeer (https://github.com/tealdeer-rs/tealdeer)
# mise use -g tlrc@latest
# mise use -g tealdeer@latest

# To install useful key bindings and fuzzy completion for fzf.
# Not necessary since result's already in .profile, here for reference
# $(brew --prefix)/opt/fzf/install
# mv ~/.fzf.* ~/.local

# lsd (deprecated)
# ln -s $LINUX_CONFIG_HOME/.config/lsd $XDG_CONFIG_HOME

read -p "Do you want to install oh-my-zsh? (Y/n): " install_oh_my_zsh
if [ "$install_oh_my_zsh" != "n" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  rm -rf ~/.oh-my-zsh/custom && ln -s $CURRENT_DIR/.oh-my-zsh/custom $HOME/.oh-my-zsh/custom
fi

exec zsh

echo "This installer will automatically update your Linux config. All existing config files will be backed up to *.bak"

export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_CACHE_HOME=$HOME/.cache

sudo apt update && sudo apt upgrade && sudo apt install build-essential

# Install zsh and set it up
sudo apt install zsh -y
zsh
chsh -s $(which zsh)

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Setup config files and backup existing ones
export CURRENT_DIR=$(pwd)
if [ -e ~/.profile ]; then
	mv ~/.profile ~/.profile.bak
fi
ln -s $CURRENT_DIR/.profile ~/.profile

if [ -e ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi
ln -s $CURRENT_DIR/.bashrc ~/.bashrc

mv ~/.zshrc ~/.zshrc.bak
ln -s $CURRENT_DIR/.zshrc ~/.zshrc
rm -rf ~/.oh-my-zsh/custom
ln -s $CURRENT_DIR/.oh-my-zsh/custom ~/.oh-my-zsh/custom

if [ -e ~/.aliases ]; then
	mv ~/.aliases ~/.aliases.bak
fi
ln -s $CURRENT_DIR/.aliases ~/.aliases
ln -s $CURRENT_DIR/scripts ~/.local/bin/scripts

ln -s $CURRENT_DIR/.gitconfig ~/.gitconfig
ln -s $CURRENT_DIR/.nanorc ~/.nanorc
ln -s $CURRENT_DIR/.nirc ~/.nirc

ln -s $CURRENT_DIR/.config/nvim $XDG_CONFIG_HOME/nvim
ln -s $CURRENT_DIR/.config/broot $XDG_CONFIG_HOME/broot
ln -s $CURRENT_DIR/.config/bottom $XDG_CONFIG_HOME/bottom
ln -s $CURRENT_DIR/.config/cheat $XDG_CONFIG_HOME/cheat
ln -s $CURRENT_DIR/.config/direnv $XDG_CONFIG_HOME/direnv
ln -s $CURRENT_DIR/.config/superfile $XDG_CONFIG_HOME/superfile
ln -s $CURRENT_DIR/.config/tmux-powerline $XDG_CONFIG_HOME/tmux-powerline
ln -s $CURRENT_DIR/.config/tealdeer $XDG_CONFIG_HOME/tealdeer
ln -s $CURRENT_DIR/.config/btop $XDG_CONFIG_HOME/btop
ln -s $CURRENT_DIR/.config/tmux $XDG_CONFIG_HOME/tmux
ln -s $CURRENT_DIR/.config/ghostty $XDG_CONFIG_HOME/ghostty
ln -s $CURRENT_DIR/tmux/.tmux-resource-monitor.sh $HOME/.tmux-resource-monitor.sh

# Install Cursor settings
ln -s $CURRENT_DIR/vscode/settings.json $XDG_CONFIG_HOME/Cursor/User/settings.json
ln -s $CURRENT_DIR/vscode/keybindings.json $XDG_CONFIG_HOME/Cursor/User/keybindings.json

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc

# Install oh-my-posh and use my custom theme
brew install jandedobbeleer/oh-my-posh/oh-my-posh
# Original at https://gist.github.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77
git clone git@gist.github.com:62f35772e52178b31353a99d2d80ca77.git ~/shell_themes
# Extra shell completions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# tmux
brew install tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
echo "Installed tmux and tmp. Run Ctrl + B, I to install plugins inside tmux"
## mise doesn't work (unfortunately)
# mise plugin add tmux https://github.com/aphecetche/asdf-tmux.git
# mise use -g tmux@latest

# Install mise
sudo apt update
sudo apt install build-essential libssl-dev zlib1g-dev \
	libbz2-dev libreadline-dev libsqlite3-dev curl \
	libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

brew install mise
mise completion zsh > ~/.local/.mise-completions.zsh

# Install Node + pnpm
mise use -g node@lts
npx pnpm i -g pnpm
pnpm i -g @antfu/ni

# Install Bun, Rust, Neovim and Go
mise use -g go@latest
mise use -g bun@latest
mise p i rust neovim
mise use -g neovim@latest
mise use -g rust@latest

# Python (if needed)
mise use -g python@latest
# Install Python (it kinda breaks, so don't use it unless necessary)
# brew unlink pkg-config && \
# CFLAGS="-I$(brew --prefix openssl)/include" \
# LDFLAGS="-L$(brew --prefix openssl)/lib" \
# mise install python@latest; \
# mise upgrade python; \

# Currently using tldr++ so this is not needed
# tldr++: https://github.com/isacikgoz/tldr
# # Tealdeer - https://github.com/tealdeer-rs/tealdeer
# mise p i https://github.com/sarg3nt/asdf-tealdeer
# mise use -g tealdeer@latest

# brew link pkg-config

# Install Homebrew tools
brew install cheat \
	progress \
	fastfetch \
	bottom \
	eza \
	bfs \
	fd \
	direnv \
	broot \
	git-delta \
	fzf \
	bat \
	tailspin \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	trippy \
	ugrep \
	ripgrep \
	gping \
	hyperfine \
	superfile \
	httpstat \
	fx \
	btop \
	duf \
	isacikgoz/taps/tldr \
	rip2

# To install useful key bindings and fuzzy completion for fzf.
# Not necessary since result's already in .profile, here for reference
# $(brew --prefix)/opt/fzf/install
# mv ~/.fzf.* ~/.local

# mkdir $XDG_CONFIG_HOME/lsd/
# ln $LINUX_CONFIG_HOME/lsd.config.yaml $XDG_CONFIG_HOME/lsd/config.yaml

exec zsh

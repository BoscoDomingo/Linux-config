echo "This installer will automatically update your Linux config. All existing config files will be backed up to *.bak"

sudo apt update && sudo apt upgrade && sudo apt install build-essential

# Install zsh and set it up
sudo apt install zsh -y
zsh
chsh -s $(which zsh)

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Setup config files and backup existing ones
if [ -e ~/.profile ]; then
	mv ~/.profile ~/.profile.bak
fi
ln -s .profile ~/.profile

if [ -e ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi
ln -s .bashrc ~/.bashrc

mv ~/.zshrc ~/.zshrc.bak
ln -s .zshrc ~/.zshrc
rm -rf ~/.oh-my-zsh/custom
ln -s .oh-my-zsh/custom ~/.oh-my-zsh/custom

if [ -e ~/.aliases ]; then
	mv ~/.aliases ~/.aliases.bak
fi
ln -s .aliases ~/.aliases

ln -s .gitconfig ~/.gitconfig
ln -s .nanorc ~/.nanorc
ln -s .nirc ~/.nirc
ln -s ./tmux/.tmux.conf ~/.tmux.conf
ln -s ./tmux/.tmux-resource-monitor.sh ~/.tmux-resource-monitor.sh

ln -s .config/broot ~/.config/broot
ln -s .config/bottom ~/.config/bottom
ln -s .config/cheat ~/.config/cheat
ln -s .config/direnv ~/.config/direnv
ln -s .config/superfile ~/.config/superfile
ln -s .config/tmux-powerline ~/.config/

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
mise p i bun rust neovim
mise use -g bun@latest
mise use -g rust@latest
mise use -g neovim@latest
mise use -g go@latest

# Doesn't work
# mise plugin add tmux https://github.com/aphecetche/asdf-tmux.git
# mise use -g tmux@latest
brew install tmux

# Install Python (it kinda breaks, so don't use it unless necessary)
# brew unlink pkg-config && \
# CFLAGS="-I$(brew --prefix openssl)/include" \
# LDFLAGS="-L$(brew --prefix openssl)/lib" \
# mise install python@latest; \
# mise upgrade python; \
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
	fx

# To install useful key bindings and fuzzy completion for fzf. Not necessary as result's already in .profile
# $(brew --prefix)/opt/fzf/install
# mv ~/.fzf.* ~/.local

# mkdir ~/.config/lsd/
# ln lsd.config.yaml ~/.config/lsd/config.yaml

exec zsh

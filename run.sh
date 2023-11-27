echo "This installer will automatically update your Linux config. All existing config files will be backed up to *.bak"

sudo apt update && sudo apt upgrade && sudo apt install build-essential

if [ -e ~/.profile ]; then
	mv ~/.profile ~/.profile.bak
fi
ln -s .profile ~/.profile

if [ -e ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi
ln -s .bashrc ~/.bashrc

if [ -e ~/.aliases ]; then
	mv ~/.aliases ~/.aliases.bak
fi
ln -s .aliases ~/.aliases

ln -s .gitconfig ~/.gitconfig
ln -s .nanorc ~/.nanorc

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc

# Original at https://gist.github.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77
git clone git@gist.github.com:62f35772e52178b31353a99d2d80ca77.git ~/shell_themes
# Install oh-my-posh
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Install rtx
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

brew install rtx

# Install Node
rtx install node
npm i -g pnpm @antfu/ni npm-check-updates

# Install bun via bum
curl -fsSL https://github.com/owenizedd/bum/raw/main/install.sh | bash
# bum use <VERSION>

# Install Python
brew unlink pkg-config && \
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
rtx install python@latest; \
brew link pkg-config

# Install extra tools
brew install cheat \
progress \
neofetch \
bottom \
eza \
bfs \
direnv \
broot \
git-delta \
fzf \
bat

# To install useful key bindings and fuzzy completion for fzf:
$(brew --prefix)/opt/fzf/install

# mkdir ~/.config/lsd/
# ln lsd.config.yaml ~/.config/lsd/config.yaml

cd && . .profile
echo "This installer will automatically update your Linux config. All existing config files will be backed up to *.bak"

sudo apt update && sudo apt upgrade && sudo apt install build-essential

# Install zsh and set it up
sudo apt install zsh -y
zsh
chsh -s $(which zsh)

# Install oh-my-zsh
sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

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
ln -s direnv.toml ~/.config/direnv/direnv.toml
ln -s .nirc ~/.nirc

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc

# Install oh-my-posh and use my custom theme
brew install jandedobbeleer/oh-my-posh/oh-my-posh
# Original at https://gist.github.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77
git clone git@gist.github.com:62f35772e52178b31353a99d2d80ca77.git ~/shell_themes

# Install rtx
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

brew install rtx
rtx completions zsh > ~/.rtx-completions

# Install Node
rtx p i pnpm # add the pnpm plugin
rtx use -g node@lts
rts use -g pnpm@latest
pnpm i -g @antfu/ni
npm i -g npm-check-updates

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
bat \
tailspin \
zsh-autosuggestions \
zsh-syntax-highlighting

# To install useful key bindings and fuzzy completion for fzf:
$(brew --prefix)/opt/fzf/install

# mkdir ~/.config/lsd/
# ln lsd.config.yaml ~/.config/lsd/config.yaml

exec zsh
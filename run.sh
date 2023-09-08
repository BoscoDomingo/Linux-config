sudo apt update && sudo apt upgrade && sudo apt install build-essential

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc

brew install jandedobbeleer/oh-my-posh/oh-my-posh
# Original at https://gist.github.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77
mkdir ~/shell_themes && cp ./niceDark.omp.json ~/shell_themes/

sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

brew install rtx
rtx install node
# For Python
# CFLAGS="-I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib" rtx install python

ln .gitconfig ~/.gitconfig
ln .nanorc ~/.nanorc
ln .profile ~/.profile

sudo apt install bat
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

brew install cheat \
progress \
neofetch \
bottom \
eza\
bfs \
direnv \
git-delta

mkdir ~/.config/lsd/
ln lsd.config.yaml ~/.config/lsd/config.yaml

npm i -g @antfu/ni npm-check-updates
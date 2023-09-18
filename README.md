# Linux Setup

## Automatic installation

You can try running the `run.sh` file, although it is untested and may not work.

## Manual installation

Before anything:

`sudo apt-get update && sudo apt-get upgrade && sudo apt-get install build-essential`

## Link `.bash_rc`, `.bash_profile`, `.nanorc`, `.gitconfig`
```shell
if [ -f ~/.bash_profile ]; then
	mv ~/.bash_profile ~/.bash_profile.bak
fi
ln .bash_profile ~/.bash_profile

if [ -f ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi
ln .bashrc ~/.bashrc

ln .gitconfig ~/.gitconfig
ln .nanorc ~/.nanorc
```

## Homebrew:

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc
```

## Oh-my-posh

```shell
brew install jandedobbeleer/oh-my-posh/oh-my-posh
mkdir ~/shell_themes && touch ~/shell_themes/niceDark.omp.json
```


The gist is [here](https://gist.githubusercontent.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77/raw/2a345cf8a3ec0fa1559d4946e61391e84abb5751/bosco.omp.json)

# Version managers

## [rtx](https://github.com/jdxcode/rtx) (Runtime Executor) <- Recommended option

Recommended route since you can manage all SDKs from here, not needing a version manager for each.

`brew install rtx`

May need
```shell
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```
and using the following for installing Python: `CFLAGS="-I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib"`

e.g. `CFLAGS="-I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib" rtx install python@3.12`


## ~~pyenv~~
<pre><del>
```shell
brew install pyenv
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
brew install tcl-tk
# Alternative
# sudo apt-get install tk-dev

pyenv-install 3.11.3 # This is to use the alias instead of the usual, to get rid of the '_ssl missing' error
pyenv global 3.11.3
```
</del></pre>

## ~~nvm~~
<s>
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash`
</s>



## [bat](https://github.com/sharkdp/bat)
```bash
sudo apt install bat
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat
```

## All Homebrew dependencies
```shell
brew install cheat \
progress \
neofetch \
bottom \
eza\
# lsd \
bfs \
thefuck \
direnv \
git-delta \
fzf
```

### [cheat](https://github.com/cheat/cheat)
`brew install cheat`

### [progress](https://github.com/Xfennec/progress)
`brew install progress`

### [neofetch](https://github.com/dylanaraps/neofetch)
`sudo apt install neofetch`

### [bottom](https://github.com/ClementTsang/bottom)
`brew install bottom`

### [eza](https://github.com/eza-community/eza)
`brew install eza`

### [lsd](https://github.com/Peltoche/lsd) (slower and I found issues with icons)
`brew install lsd`

### [bfs](https://github.com/tavianator/bfs)
`brew install bfs`

### [direnv](https://direnv.net/)
`brew install direnv`

### [Delta](https://github.com/dandavison/delta)
`brew install git-delta`

### [fzf](https://github.com/junegunn/fzf)
`brew install fzf`

### [thefuck](https://github.com/nvbn/thefuck) (quite slow on my machine, but a useful command nonetheless)
`brew install thefuck`


# NPM packages
```
npm i -g @antfu/ni \
npm-check-updates
```

### [ni](https://github.com/antfu/ni)
`npm i -g @antfu/ni`

### [ncu](https://www.npmjs.com/package/npm-check-updates)
`npm i -g npm-check-updates`

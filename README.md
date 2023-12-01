# Linux Setup

1. [Linux Setup](#linux-setup)
2. [Automatic installation](#automatic-installation)
3. [Manual installation](#manual-installation)
	1. [Before anything:](#before-anything)
	2. [Create symbolic links to `.bash_rc`, `.zshrc`, `.profile`, `.aliases`, `.nanorc`, `.gitconfig` and oh-my-zsh config](#create-symbolic-links-to-bash_rc-zshrc-profile-aliases-nanorc-gitconfig-and-oh-my-zsh-config)
	3. [Homebrew:](#homebrew)
	4. [Oh-my-posh](#oh-my-posh)
	5. [zsh](#zsh)
	6. [oh-my-zsh](#oh-my-zsh)
4. [Version managers](#version-managers)
	1. [rtx (Runtime Executor)](#rtx-runtime-executor)
		1. [Python installation](#python-installation)
	2. [bum](#bum)
	3. [~~pyenv~~](#pyenv)
	4. [~~nvm~~](#nvm)
5. [Other commands](#other-commands)
	1. [Homebrew packages](#homebrew-packages)
		1. [cheat](#cheat)
		2. [progress](#progress)
		3. [neofetch](#neofetch)
		4. [bottom](#bottom)
		5. [eza](#eza)
		6. [lsd (slower and I found issues with icons)](#lsd-slower-and-i-found-issues-with-icons)
		7. [bfs](#bfs)
		8. [direnv](#direnv)
		9. [broot](#broot)
		10. [Delta](#delta)
		11. [fzf](#fzf)
		12. [bat](#bat)
		13. [tailspin](#tailspin)
		14. [thefuck (quite slow on my machine, but a useful command nonetheless)](#thefuck-quite-slow-on-my-machine-but-a-useful-command-nonetheless)
	2. [NPM packages](#npm-packages)
		1. [pnpm](#pnpm)
		2. [ncu](#ncu)
		3. [ni](#ni)


# Automatic installation

You can try running the `run.sh` file, although it is untested and may not work.

# Manual installation

## Before anything:

```sh
sudo apt-get update && sudo apt-get upgrade && sudo apt-get install build-essential
```

## Create symbolic links to `.bash_rc`, `.zshrc`, `.profile`, `.aliases`, `.nanorc`, `.gitconfig` and oh-my-zsh config

```shell
# Setup config files and backup existing ones
if [ -e ~/.profile ]; then
	mv ~/.profile ~/.profile.bak
fi
ln -s .profile ~/.profile

if [ -e ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi
ln -s .bashrc ~/.bashrc

if [ -e ~/.zshrc ]; then
	mv ~/.zshrc ~/.zshrc.bak
	mv $ZSH_CUSTOM/ $ZSH_CUSTOM_bak/
fi
ln -s .zshrc ~/.zshrc
ln -s .oh-my-zsh/custom ~/.oh-my-zsh/custom

if [ -e ~/.aliases ]; then
	mv ~/.aliases ~/.aliases.bak
fi
ln -s .aliases ~/.aliases

ln -s .gitconfig ~/.gitconfig
ln -s .nanorc ~/.nanorc
ln -s direnv.toml ~/.config/direnv/direnv.toml
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
git clone https://gist.github.com/62f35772e52178b31353a99d2d80ca77.git ~/shell_themes
```

The gist is [here](https://gist.github.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77)

## zsh

```shell
sudo apt install zsh -y
zsh
chsh -s $(which zsh)
```

## oh-my-zsh

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
# Version managers

## [rtx](https://github.com/jdx/rtx) (Runtime Executor)

Recommended since you can manage multiple language SDKs from here, not needing a version manager for each.

`brew install rtx`

Needs
```shell
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

### Python installation

```sh
brew unlink pkg-config && \
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
rtx install python@latest; \
brew link pkg-config
```

## [bum](https://github.com/owenizedd/bum)

A version manager for bun (since rtx doesn't yet support it)

```shell
curl -fsSL https://github.com/owenizedd/bum/raw/main/install.sh | bash
bum use <VERSION>
```

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

pyenv-install 3.11 # This is to use the alias instead of the usual, to get rid of the '_ssl missing' error
pyenv global 3.11
```
</del></pre>

## ~~nvm~~
<s>
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash`
</s>

# Other commands

## Homebrew packages
```shell
brew install cheat \
progress \
neofetch \
bottom \
eza \
bfs \
thefuck \
direnv \
broot \
git-delta \
fzf \
bat \
tailspin
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

### [broot](https://github.com/Canop/broot)
`brew install broot`

### [Delta](https://github.com/dandavison/delta)
`brew install git-delta`

### [fzf](https://github.com/junegunn/fzf)
`brew install fzf`

### [bat](https://github.com/sharkdp/bat)
`brew install bat`

### [tailspin](https://github.com/bensadeh/tailspin)
`brew install tailspin`

### [thefuck](https://github.com/nvbn/thefuck) (quite slow on my machine, but a useful command nonetheless)
`brew install thefuck`

## NPM packages
```sh
npm i -g pnpm && pnpm setup;
```

Restart shell or `. .bashrc` or `. .zshrc`

```sh
pnpm i -g @antfu/ni \
npm-check-updates
```

### [pnpm](https://pnpm.io/)
`npm i -g pnpm`

### [ncu](https://www.npmjs.com/package/npm-check-updates)
`pnpm i -g npm-check-updates`

### [ni](https://github.com/antfu/ni)
`pnpm i -g @antfu/ni`

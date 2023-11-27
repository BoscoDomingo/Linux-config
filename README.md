# Linux Setup

1. [Linux Setup](#linux-setup)
	1. [Automatic installation](#automatic-installation)
	2. [Manual installation](#manual-installation)
	3. [Link `.bash_rc`, `.profile`, `.aliases`, `.nanorc`, `.gitconfig`](#link-bash_rc-profile-aliases-nanorc-gitconfig)
	4. [Homebrew:](#homebrew)
	5. [Oh-my-posh](#oh-my-posh)
2. [Version managers](#version-managers)
	1. [rtx (Runtime Executor) \<- Recommended option](#rtx-runtime-executor---recommended-option)
	2. [bum](#bum)
	3. [~~pyenv~~](#pyenv)
	4. [~~nvm~~](#nvm)
3. [Other commands](#other-commands)
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
		13. [thefuck (quite slow on my machine, but a useful command nonetheless)](#thefuck-quite-slow-on-my-machine-but-a-useful-command-nonetheless)
	2. [NPM packages](#npm-packages)
		1. [ncu](#ncu)
		2. [ni](#ni)


## Automatic installation

You can try running the `run.sh` file, although it is untested and may not work.

## Manual installation

Before anything:

`sudo apt-get update && sudo apt-get upgrade && sudo apt-get install build-essential`

## Link `.bash_rc`, `.profile`, `.aliases`, `.nanorc`, `.gitconfig`
```shell
if [ -e ~/.profile ]; then
	mv ~/.profile ~/.profile.bak
fi
ln -s .profile ~/.profile

if [ -e ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi

if [ -e ~/.aliases ]; then
	mv ~/.aliases ~/.aliases.bak
fi
ln -s .aliases ~/.aliases

ln -s .gitconfig ~/.gitconfig
ln -s .nanorc ~/.nanorc
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

# Version managers

## [rtx](https://github.com/jdxcode/rtx) (Runtime Executor) <- Recommended option

Recommended route since you can manage all SDKs from here, not needing a version manager for each.

`brew install rtx`

Needs
```shell
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

Use the following for installing Python:
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
bat
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

### [thefuck](https://github.com/nvbn/thefuck) (quite slow on my machine, but a useful command nonetheless)
`brew install thefuck`

## NPM packages
```
npm i -g @antfu/ni \
npm-check-updates
```

### [ncu](https://www.npmjs.com/package/npm-check-updates)
`npm i -g npm-check-updates`

### [ni](https://github.com/antfu/ni)
`npm i -g @antfu/ni`

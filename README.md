# Linux Setup <!-- omit from toc -->

1. [Automatic installation](#automatic-installation)
2. [Manual installation](#manual-installation)
	1. [Before anything](#before-anything)
	2. [zsh](#zsh)
	3. [Create symbolic links to all config files (allows Git tracking)](#create-symbolic-links-to-all-config-files-allows-git-tracking)
	4. [Homebrew](#homebrew)
	5. [Oh-my-posh](#oh-my-posh)
	6. [oh-my-zsh](#oh-my-zsh)
3. [Version managers](#version-managers)
	1. [mise](#mise)
		1. [Deprecated](#deprecated)
4. [Other commands](#other-commands)
	1. [Homebrew packages](#homebrew-packages)
		1. [Deprecated](#deprecated-1)
	2. [NPM packages](#npm-packages)


# Automatic installation

You can try running the [`./run.sh`](run.sh) file, although it is untested and may not work.

---

# Manual installation

## Before anything

```sh
sudo apt update && sudo apt upgrade && sudo apt install build-essential
```

## zsh

```shell
sudo apt install zsh -y
zsh # Simply quit the setup. The .zshrc file is already done for you but this is a must-do step
chsh -s $(which zsh)
```

## Create symbolic links to all config files (allows Git tracking)

See [`./run.sh`](run.sh)

## Homebrew

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

## oh-my-zsh

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
---
# Version managers

## [mise](https://mise.jdx.dev/)

Recommended since you can manage multiple language SDKs from here, not needing a version manager for each.

It also works with [asdf plugins](https://github.com/asdf-vm/asdf-plugins), so you can manage pretty much anything with it. Pretty neat!

```sh
# Prerequisites
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

brew install mise
mise completion zsh > ~/.local/.mise-completions.zsh
```

<details>
	<summary>
		Node + pnpm
	</summary>

```sh
mise p i pnpm # add the pnpm plugin
mise use -g node@lts
mise use -g pnpm@latest

# optional
pnpm i -g @antfu/ni
npm i -g npm-check-updates
```

</details>

<details>
	<summary>
		Python
	</summary>

```sh
brew unlink pkg-config && \
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
mise install python@latest; \
brew link pkg-config
```

</details>

<details>
	<summary>
		Bun
	</summary>

```sh
mise p i bun
mise use -g bun@latest
```
</details>

### Deprecated

<details>
	<summary><del>pyenv (deprecated)</del></summary>

<del>

```sh
brew install pyenv
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
brew install tcl-tk
# Alternative
# sudo apt-get install tk-dev

pyenv-install 3.12 # This is to use the alias instead of the usual, to get rid of the '_ssl missing' error
pyenv global 3.12
```

</del>


</details>

<details>
	<summary><del>nvm (deprecated)</del></summary>

<del>

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
```

</del>


</details>

# Other commands

## Homebrew packages

See [`./run.sh`](run.sh)

* [cheat](https://github.com/cheat/cheat) - `brew install cheat`
* [progress](https://github.com/Xfennec/progress) - `brew install progress`
* [neofetch](https://github.com/dylanaraps/neofetch) - `sudo apt install neofetch`
* [bottom](https://github.com/ClementTsang/bottom) - `brew install bottom`
* [eza](https://github.com/eza-community/eza) - `brew install eza`
* [bfs](https://github.com/tavianator/bfs) - `brew install bfs`
* [direnv](https://direnv.net/) - `brew install direnv`
* [broot](https://github.com/Canop/broot) - `brew install broot`
* [Delta](https://github.com/dandavison/delta) - `brew install git-delta`
* [fzf](https://github.com/junegunn/fzf) - `brew install fzf`
* [bat](https://github.com/sharkdp/bat) - `brew install bat`
* [tailspin](https://github.com/bensadeh/tailspin) - `brew install tailspin`
* [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) - `brew install zsh-autosuggestions`
* [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - `brew install zsh-syntax-highlighting`
* [trippy](https://trippy.cli.rs/) - `brew install trippy`
* [ugrep](https://ugrep.com/) - `brew install ugrep`

### Deprecated

* [thefuck](https://github.com/nvbn/thefuck) (quite slow on my machine, but a useful command nonetheless) - `brew install thefuck`
* [lsd](https://github.com/Peltoche/lsd) (slower and I found issues with icons) - `brew install lsd`


## NPM packages

```sh
pnpm i -g @antfu/ni
npm i -g npm-check-updates # pnpm doesn't need it
```

* [ni](https://github.com/antfu/ni)
`pnpm i -g @antfu/ni`

* [ncu](https://www.npmjs.com/package/npm-check-updates)
`npm i -g npm-check-updates`
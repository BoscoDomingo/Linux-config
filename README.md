# Linux Setup <!-- omit from toc -->

1. [Automatic installation](#automatic-installation)
	1. [Prerequisites](#prerequisites)
2. [Manual installation](#manual-installation)
	1. [Before anything](#before-anything)
	2. [zsh](#zsh)
	3. [Create symbolic links to all config files (allows Git tracking)](#create-symbolic-links-to-all-config-files-allows-git-tracking)
	4. [Homebrew](#homebrew)
	5. [oh-my-posh](#oh-my-posh)
	6. [oh-my-zsh](#oh-my-zsh)
3. [Version managers](#version-managers)
	1. [mise](#mise)
			1. [Optional extras](#optional-extras)
	2. [Deprecated](#deprecated)
4. [Homebrew packages](#homebrew-packages)
		1. [Deprecated](#deprecated-1)
5. [GPG and commit signing](#gpg-and-commit-signing)
	1. [WSL](#wsl)
	2. [Use built-in pinentry](#use-built-in-pinentry)


# Automatic installation

You can try running the [`./run.sh`](run.sh) file directly, although it is untested and will likely not work.

## Prerequisites

- Git configured with at least an SSH key.
- VS Code or Cursor installed.

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

See the commands in [`./run.sh`](run.sh)

## [Homebrew](https://brew.sh/)

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

brew install gcc
```

## [oh-my-posh](https://ohmyposh.dev/)

```shell
brew install jandedobbeleer/oh-my-posh/oh-my-posh
git clone https://gist.github.com/62f35772e52178b31353a99d2d80ca77.git ~/shell_themes
```

The gist is [here](https://gist.github.com/BoscoDomingo/62f35772e52178b31353a99d2d80ca77)

## [oh-my-zsh](https://ohmyz.sh/)

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

# Version managers

## [mise](https://mise.jdx.dev/)

Recommended since you can manage multiple language SDKs from here, not needing a version manager for each.

It also works with [asdf plugins](https://github.com/asdf-vm/asdf-plugins), and soon with vfox too, so you can manage pretty much anything with it. Pretty neat!

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
		<h3>Node + pnpm</h3>
	</summary>

Use npm to install pnpm because otherwise the cache and installed modules are lost every time pnpm is updated.

```sh
mise use -g node@lts
npx pnpm i -g pnpm # To save pnpm to $PNPM_HOME so cache won't be lost on updates
```

#### Optional extras

* [ni](https://github.com/antfu/ni)
`pnpm i -g @antfu/ni`

* [taze](https://github.com/antfu-collective/taze)
`npm i -g taze` - pnpm doesn't need it
* [ncu](https://www.npmjs.com/package/npm-check-updates)
`npm i -g npm-check-updates` - pnpm doesn't need it

</details>

<details>
	<summary>
		<h3>Neovim</h3>
	</summary>

```sh
mise p i neovim
mise use -g neovim@latest
```
</details>

<details>
	<summary>
		<h3>Bun</h3>
	</summary>

```sh
mise p i bun
mise use -g bun@latest
```
</details>

<details>
	<summary>
		<h3>Go</h3>
	</summary>

```sh
# mise p i https://github.com/asdf-community/asdf-golang # Optional
mise use -g go@latest
```
</details>

<details>
	<summary>
		<h3>Python</h3>
	</summary>

```sh
brew unlink pkg-config && \
CFLAGS="-I$(brew --prefix openssl)/include" \
LDFLAGS="-L$(brew --prefix openssl)/lib" \
mise install python@latest; \
brew link pkg-config
```

</details>

## Deprecated

<details>
	<summary><del>pyenv</del></summary>

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

# Homebrew packages

See [`./run.sh`](run.sh)

* [tmux](https://github.com/tmux/tmux/wiki) - `brew install tmux`
* [cheat](https://github.com/cheat/cheat) - `brew install cheat`
* [progress](https://github.com/Xfennec/progress) - `brew install progress`
* [fastfetch](https://github.com/fastfetch-cli/fastfetch) - `sudo apt install fastfetch`
* [bottom](https://github.com/ClementTsang/bottom) - `brew install bottom`
* [eza](https://github.com/eza-community/eza) - `brew install eza`
* [fd](https://github.com/sharkdp/fd) - `brew install fd`
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
* [ripgrep](https://github.com/BurntSushi/ripgrep) - `brew install ripgrep`
* [gping](https://github.com/orf/gping) - `brew install gping`
* [hyperfine](https://github.com/sharkdp/hyperfine) - `brew install hyperfine`
* [superfile](https://superfile.netlify.app/) - `brew install superfile`
* [httpstat](https://github.com/reorx/httpstat) - `brew install httpstat`
* [fx](https://github.com/antonmedv/fx) - `brew install fx`
* [btop](https://github.com/aristocratos/btop) - `brew install btop`
* [duf](https://github.com/muesli/duf) - `brew install duf`
* [rip](https://github.com/MilesCranmer/rip2) - `brew install rip2`
* [ggh](https://github.com/byawitz/ggh) - `brew install ggh`

### Deprecated

* [thefuck](https://github.com/nvbn/thefuck) (quite slow on my machine, but a useful command nonetheless) - `brew install thefuck`
* [lsd](https://github.com/Peltoche/lsd) (slower and I found issues with icons) - `brew install lsd`

# GPG and commit signing

## WSL

> Note that you *don't* need GPG4Win, you can use everything from Linux itself.
> However, GPG4Win can be useful if you ever plan on using Windows directly to develop or sign anything.

> Also, keys can only be cached for as long as the agent is running.
> Rebooting the machine will clear the cache.

Follow any of these guides:

* [39Signals](https://www.39digits.com/signed-git-commits-on-wsl2-using-visual-studio-code)
* [The Miners](https://blog.codeminer42.com/securing-git-commits-on-windows-10-and-wsl2/)
* [nathanv@blog](https://blog.nathanv.me/posts/gpg-windows/)
* [Ryan Emerle - importing Linux keys to Windows](https://emerle.dev/2020/08/21/git-signed-commits-in-windows-and-wsl/)

You may need to fix issues:

- [`gpg: WARNING: unsafe permissions on homedir '/home/path/to/user/.gnupg'`](https://gist.github.com/oseme-techguy/bae2e309c084d93b75a9b25f49718f85)
- [`gpg: signing failed: Inappropriate ioctl for device`](https://github.com/keybase/keybase-issues/issues/2798) <- Already implemented in [`.profile`](.profile)


## Use built-in pinentry

You can use `pinentry` which prompts with a TUI, or `pinentry-tty` which uses stdin directly, as `sudo` does.

Example:

```sh
# Either one should work
sudo apt install pinentry-tty
brew install pinentry-tty
```

and modify your `~/.gnupg/gpg-agent.conf` to use the built-in pinentry:

```sh
pinentry-program /usr/bin/pinentry-tty
pinentry-program /home/linuxbrew/.linuxbrew/bin/pinentry-tty
```
#!/bin/bash
# First-run bootstrap for a fresh Arch box (incl. WSL). Run as root before the
# repo is cloned:
#
#   pacman -Sy --noconfirm git && git clone https://github.com/BoscoDomingo/Linux-config.git \
#     && bash Linux-config/Arch/run_arch.sh
#
# It installs the prerequisites a package manager owns (a sudo user, zsh, git,
# locales, plus the build deps mise needs to compile language runtimes), clones
# the repo, and hands off to nix/bootstrap.sh, which installs Nix and runs
# `home-manager switch`. Everything else lives in the Nix config.
set -euo pipefail

# Detect WSL once: bare-metal Arch (e.g. CachyOS) gets none of the WSL bits.
is_wsl=0
grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null && is_wsl=1

pacman -Syu --noconfirm
pacman -S --noconfirm --needed \
	sudo zsh git openssh curl ca-certificates file procps-ng which xz \
	base-devel openssl zlib bzip2 readline sqlite ncurses tk libxml2 xmlsec libffi

# wslview (BROWSER=wslview in .profile) is WSL↔Windows interop; only under WSL.
[ "$is_wsl" = "1" ] && pacman -S --noconfirm --needed wslu

# Create a sudo-capable user that logs in with zsh.
read -rp "Enter the username you want to create (password asked afterwards): " username
if id -u "$username" >/dev/null 2>&1; then
	echo "User $username already exists"
else
	useradd -m -G wheel -s /bin/zsh "$username"
	passwd "$username"
fi
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Locales, so character encoding works.
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_GB.UTF-8 2>/dev/null || echo "LANG=en_GB.UTF-8" >/etc/locale.conf

# Clone the repo and run the Nix bootstrap as the new user. bootstrap.sh
# auto-detects WSL, so it picks the arch vs arch-wsl host on its own.
su - "$username" <<'EOF'
set -euo pipefail
[ -d "$HOME/dotfiles" ] || git clone https://github.com/BoscoDomingo/Linux-config.git "$HOME/dotfiles"
bash "$HOME/dotfiles/nix/bootstrap.sh"
EOF

if [ "$is_wsl" = "1" ]; then
	printf "\nTo always log in as %s in WSL, add 'default=%s' under [user] in /etc/wsl.conf\n" "$username" "$username"
	read -rp "Want me to do that for you? (y/N): " setdefaultuser
	if [ "$setdefaultuser" = "y" ]; then
		[ -f /etc/wsl.conf ] && mv /etc/wsl.conf /etc/wsl.conf.bak
		printf '[user]\ndefault=%s\n' "$username" >/etc/wsl.conf
		printf "\nDone! You will now log in as %s every time you open a new terminal.\n" "$username"
	fi
fi

printf "\nAll set. Log in as %s (su - %s) to start using the shell.\n" "$username" "$username"

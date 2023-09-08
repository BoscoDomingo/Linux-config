#!/bin/bash
# This script can be run manually, before cloning the repo. It will take care of cloning the actual repo and running the installer.
# Run with cd dotfiles && bash ./run_arch.sh

pacman -Syu --noconfirm
pacman -S --noconfirm sudo zsh

# Create a user with sudo privileges
read -p "Enter the username you want to create (password will be asked afterwards): " username

if id -u $username >/dev/null 2>&1; then
	echo "User $username already exists"
else
	useradd -m -G wheel -s /bin/zsh $username
	passwd $username
fi

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

pacman -S --noconfirm git openssh micro gnome-keyring

# Uncomment en_US.UTF-8 and en_GB.UTF-8 in /etc/locale.gen and generate locales
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
localectl set-locale LANG=en_GB.UTF-8
# Alternatively, use the following command:
# echo "LANG=en_GB.UTF-8" > /etc/locale.conf

if [ ! -d $HOME/dotfiles ]; then
	git clone https://github.com/BoscoDomingo/Linux-config.git $HOME/dotfiles
fi

# Mise dependencies
pacman -S --noconfirm base-devel openssl ca-certificates zlib \
	bzip2 readline sqlite curl \
	ncurses xz tk libxml2 xmlsec libffi xz

pacman -S --noconfirm direnv
# sudo pacman -S --noconfirm gcp # Need to find the AUR package or use mise
# direnv alternative
# curl -sfL https://direnv.net/install.sh | bash

# Switch to the user for the rest of the setup
su - $username <<'EOF'
# Clone dotfiles
if [ ! -d $HOME/dotfiles ]; then
  git clone https://github.com/BoscoDomingo/Linux-config.git $HOME/dotfiles
fi

chmod +x $HOME/dotfiles/run.sh
EOF

printf "\nIf running in WSL, to always log in as %s, add 'user.default=%s' to /etc/wsl.conf\n" "$username" "$username"

read -p "Want me to do that for you? (y/N): " setdefaultuser
if [ "$setdefaultuser" = "y" ]; then
	if [ -f /etc/wsl.conf ]; then
		mv /etc/wsl.conf /etc/wsl.conf.bak
	fi
	cat >/etc/wsl.conf <<EOF
[user]
default=$username
EOF
	printf "\nDone! You will now log in as %s every time you open a new terminal" "$username"
fi

printf "\nAll set! You can now log in as %s (su - %s) and run 'cd \$HOME/dotfiles && ./run.sh'\n" "$username" "$username"

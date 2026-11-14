{ ... }:
# CachyOS package builds must use the distro compiler and linker. Installing
# Nix GCC globally shadows /usr/bin/gcc and /usr/bin/ld in tools such as paru.
{
  imports = [ ../home/common.nix ];
}

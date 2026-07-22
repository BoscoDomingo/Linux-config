{ ... }:
# Bare-metal Arch, incl. CachyOS and other Arch derivatives. Everything comes
# from common.nix; this host adds nothing WSL-specific. The WSL variant that
# layers on top of it is hosts/arch-wsl.nix.
{
  imports = [ ../home/common.nix ];
}

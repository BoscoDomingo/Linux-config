{ pkgs, ... }:
# Bare-metal Arch and the shared base for Arch derivatives. Everything comes
# from common.nix; host variants layer their differences on top.
{
  imports = [ ../home/common.nix ];

  home.packages = [ pkgs.gcc ];
}

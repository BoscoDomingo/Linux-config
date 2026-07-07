{ pkgs, ... }:
# Arch running under WSL. Everything shared comes from common.nix; only the
# WSL/Arch-specific bits live here.
{
  imports = [ ../home/common.nix ];

  home.packages = with pkgs; [
    wslu # provides wslview etc. — used by BROWSER=wslview in .profile
  ];

  # The DBus/gnome-keyring bootstrap currently in .profile's WSL branch can be
  # re-homed here as a Home Manager activation script if you want Nix to own it:
  #
  # home.activation.wslKeyring = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   ...
  # '';
}

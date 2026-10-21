{ config, ... }:
# Arch under WSL: the bare-metal Arch host (arch.nix) plus the few WSL-only
# bits.
#
# wslview (BROWSER=wslview in .profile) comes from the distro's `wslu` package,
# installed by Arch/run_arch.sh only under WSL; nixpkgs no longer ships it. The
# DBus/gnome-keyring bootstrap is runtime-gated in .profile, so it needs nothing
# here.
let
  repo = "${config.home.homeDirectory}/dotfiles";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [ ./arch.nix ];

  # WSL Cursor/VS Code servers read server-env-setup to expose the Nix/mise PATH
  # to their extension hosts (the server is spawned by wsl.exe outside the login
  # shell). See ../../Documentation/WSL_IDE_server_PATH.md. Bare-metal editor
  # config stays in common (home/dotfiles.nix).
  home.file = {
    ".cursor-server/server-env-setup".source = link "${repo}/vscode/server-env-setup";
    ".vscode-server/server-env-setup".source = link "${repo}/vscode/server-env-setup";
    ".cursor-server/extensions/extensions.json".source = link "${repo}/vscode/extensions-cursor-wsl.json";
  };
}

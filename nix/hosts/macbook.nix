{ pkgs, ... }:
# macOS. Home Manager handles the user environment on macOS just like Linux.
# For system-level macOS defaults (Dock, keyboard, GUI casks) add nix-darwin —
# see the commented darwinConfigurations block in ../flake.nix.
{
  imports = [ ../home/common.nix ];

  # macOS-only packages, or Linux packages to exclude, go here.
  # home.packages = with pkgs; [ ... ];

  # Your MacOS/ dir (ghostty-mac config, DefaultKeyBinding.dict) would be
  # symlinked from a mac-specific block, e.g.:
  # home.file."Library/KeyBindings/DefaultKeyBinding.dict".source =
  #   config.lib.file.mkOutOfStoreSymlink "${repo}/MacOS/DefaultKeyBinding.dict";

  # macOS GUI casks — declared via nix-darwin's homebrew module in the system
  # config (see ../flake.nix darwinConfigurations):
  #
  #   homebrew = {
  #     enable = true;
  #     onActivation.cleanup = "zap";   # remove casks not listed here
  #     casks = [ "ghostty" "cursor" "firefox" ];
  #   };
}

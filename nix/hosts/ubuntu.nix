{ config, ... }:
# Ubuntu. Everything shared comes from common.nix; only Ubuntu-specific bits
# live here.
{
  imports = [ ../home/common.nix ];

  # zsh-autocomplete re-runs Ubuntu's global compinit; this .zshenv sets
  # skip_global_compinit=1 to avoid the double init.
  home.file.".zshenv".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/Ubuntu/.zshenv";
}

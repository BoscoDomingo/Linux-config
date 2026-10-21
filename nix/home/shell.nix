{ config, ... }:
# OPTIONAL: native Home Manager modules for tools with first-class
# support. These generate config AND manage the package together, so you can
# drop the corresponding symlink from dotfiles.nix if you adopt them.
let
  repo = "${config.home.homeDirectory}/dotfiles";
in
{
  # zsh: let HM manage the package/plugins but keep interactive config by
  # sourcing the existing layered files (.profile → .shellrc → .aliases).
  programs.zsh = {
    enable = true;
    # Reuse your existing files rather than re-expressing them in Nix:
    initExtra = ''
      [ -f "${repo}/.zshrc" ] && source "${repo}/.zshrc"
    '';
  };

  programs.fzf.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # git: can either manage settings in Nix or keep your .gitconfig symlink.
  # Leaving disabled here so dotfiles.nix's .gitconfig symlink stays the source
  # of truth. Enable + port settings if/when you want HM to own it.
  # programs.git.enable = true;
}

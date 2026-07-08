{ ... }:
# Shared configuration imported by every host module.
# Split into focused files so intent stays discoverable.
{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./tools.nix

    # Optional native Home Manager modules. Not imported by default:
    # programs.zsh/starship/… generate the same files dotfiles.nix symlinks,
    # and Home Manager refuses to manage a file twice. To adopt one, import it
    # here AND drop the matching symlink from dotfiles.nix. See doc §5.4.
    # ./shell.nix
    #
    # Home Manager-owned git config. The symlinked .gitconfig handles per-machine
    # identity via [include] (doc §8.1), so this is only for owning git config
    # entirely in Nix (then drop the .gitconfig symlink from dotfiles.nix).
    # ./git.nix
  ];

  # mise manages language runtimes and floating dev tools; Nix manages the
  # stable global toolbox. mise's own config is symlinked via dotfiles.nix.
}

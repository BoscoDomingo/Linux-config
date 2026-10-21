{ ... }:
# Shared configuration imported by every host module.
# Split into focused files so intent stays discoverable.
{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./tools.nix

    # Optional native Home Manager modules. Not imported by default:
    # programs.zsh/… generate the same files dotfiles.nix symlinks, and Home
    # Manager refuses to manage a file twice. To adopt one, import it here AND
    # drop the matching symlink from dotfiles.nix. See
    # [Nix rationale](../../Documentation/Nix_exploration.md#53-native-home-manager-modules-are-optional).
    # ./shell.nix
    #
    # Home Manager-owned git config. The symlinked .gitconfig handles per-machine
    # identity via overrides/ (jj/mise/brew share that tree), so this is only
    # for owning git config entirely in Nix (then drop the .gitconfig
    # symlink from dotfiles.nix). See
    # [machine-overrides.md](../../Documentation/machine-overrides.md).
    # ./git.nix
  ];

  # mise manages language runtimes plus explicitly declared floating tools;
  # Nix manages the stable global toolbox. mise itself is self-managed (see
  # ../bootstrap.sh); its config is symlinked via dotfiles.nix.
}

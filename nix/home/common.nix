{ ... }:
# Shared configuration imported by every host module.
# Split into focused files so intent stays discoverable.
{
  imports = [
    ./packages.nix
    ./dotfiles.nix

    # Opt-in (Phase 3): native Home Manager modules. These are NOT imported by
    # default because programs.zsh/starship/… generate the same files that
    # dotfiles.nix symlinks, and Home Manager refuses to manage a file twice.
    # To adopt one, import the module here AND remove the matching symlink from
    # dotfiles.nix. See exploration doc §5.4.
    # ./shell.nix
    #
    # Per-machine git identity (work vs personal). Not needed if you use the
    # simpler .gitconfig `[include]` approach (§8.1), which the committed
    # .gitconfig already does. Import this only if you want Home Manager to own
    # git config entirely (then drop the .gitconfig symlink from dotfiles.nix).
    # ./git.nix
  ];

  # mise is kept for per-project language versions (see the exploration doc).
  # Nix owns the global, stable toolbox; mise owns per-project, floating ones.
  # Nothing here manages mise itself — it stays installed and configured as
  # today via .config/mise/config.toml (symlinked in dotfiles.nix).
}

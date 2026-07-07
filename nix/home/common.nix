{ ... }:
# Shared configuration imported by every host module.
# Split into focused files so intent stays discoverable.
{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./shell.nix
    # ./git.nix  # opt-in: let Home Manager own git identity via includeIf.
    #            # If you enable this, drop the .gitconfig symlink from
    #            # dotfiles.nix to avoid both writing git config. The simpler
    #            # path (§8.1) needs neither: just add [include] to .gitconfig.
  ];

  # mise is kept for per-project language versions (see the exploration doc).
  # Nix owns the global, stable toolbox; mise owns per-project, floating ones.
  # Nothing here manages mise itself — it stays installed and configured as
  # today via .config/mise/config.toml (symlinked in dotfiles.nix).
}

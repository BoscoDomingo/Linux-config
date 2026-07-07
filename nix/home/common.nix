{ ... }:
# Shared configuration imported by every host module.
# Split into focused files so intent stays discoverable.
{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./shell.nix
  ];

  # mise is kept for per-project language versions (see the exploration doc).
  # Nix owns the global, stable toolbox; mise owns per-project, floating ones.
  # Nothing here manages mise itself — it stays installed and configured as
  # today via .config/mise/config.toml (symlinked in dotfiles.nix).
}

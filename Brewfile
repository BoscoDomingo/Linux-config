# Synced Homebrew baseline (tools whose Nix/mise packages are unsuitable).
# Per-machine extras go in the gitignored overlay (never commit it):
#   overrides/brew/Brewfile.local
# Bootstrap and scripts/brew-bundle concatenate both. See
# Documentation/machine-overrides.md.
tap "gentleman-programming/tap"
brew "gentleman-programming/tap/engram"
# nixpkgs 1.3.2 fails to build with Python 3.14; Homebrew provides a working bottle.
brew "httpstat"

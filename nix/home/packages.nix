{ pkgs, ... }:
# The global CLI toolbox — Nix owns this (replaces the Homebrew formula array
# in Setup/installers/packages.sh).
#
# OWNERSHIP RULES (see Documentation/Nix_exploration.md §4/§6):
#   • Nix (this file) — stable, global CLI tools. Pinned by flake.lock,
#     installed identically on every machine by `home-manager switch`.
#   • mise (.config/mise/config.toml) — language runtimes (node/go/python/
#     rust/bun/pnpm) and dev tools you want on `latest`/per-project
#     (jj, neovim, opencode, pi, biome, golangci-lint, act, …).
#   • Homebrew — macOS GUI casks only, declared via nix-darwin's `homebrew`
#     module (see hosts/macbook.nix). On Linux, brew is no longer needed.
# A tool lives in exactly ONE of these. No duplicates across systems.
#
# Package names are nixpkgs attributes (differ from brew names occasionally,
# noted inline). Search: https://search.nixos.org
{
  home.packages = with pkgs; [
    gcc
    cheat
    progress
    bottom # `btm`
    btop
    eza
    bfs
    fd
    fx
    fzf
    bat
    ripgrep # also removed from mise — Nix is the single owner
    delta # brew: git-delta
    fastfetch
    onefetch
    duf
    gping
    hyperfine # also removed from mise — Nix is the single owner
    trippy # `trip`
    sshs
    rip2 # brew: rip2 (rm-improved)
    httpstat
    lazyjj
    witr
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    zsh-completions
    zsh-autocomplete

    # Moved out of mise — these are stable enough to pin with the rest of the
    # toolbox. (Their config still lives in .config/* via dotfiles.nix.)
    jujutsu # `jj`
    neovim
    opencode
    yt-dlp
    act
    tree-sitter
    # NOTE: `pi` stays in mise (not in nixpkgs). `gentle-ai` stays on Homebrew
    # (not in nixpkgs) and is installed on Linux + macOS via Setup/installers.
  ];
}

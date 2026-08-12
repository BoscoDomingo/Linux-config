{ pkgs, ... }:
# Stable global CLI tools, managed by Nix. The ownership split (Nix vs mise vs
# Homebrew) is documented in
# [the migration doc](../../Documentation/Nix_exploration.md#9-tool-ownership--retiring-runsh).
# Package names are nixpkgs attributes. Search: https://search.nixos.org
let
  # nixpkgs-unstable currently ships diffnav 0.12.0, which is broken here.
  # Pin to upstream's last known-good derivation; delete this override once
  # nixpkgs ships a fixed release and `pkgs.diffnav` works again.
  diffnav = pkgs.diffnav.overrideAttrs (_old: rec {
    version = "0.11.0";
    src = pkgs.fetchFromGitHub {
      owner = "dlvhdr";
      repo = "diffnav";
      tag = "v${version}";
      hash = "sha256-6VtAQzZNLQrf8QYVXxLUgb3F6xguFDbwaE9kahPhbSE=";
    };
    vendorHash = "sha256-gmmckzR0D1oFuTG5TAb6gLMoNbcZl9EsjbFjhPfJqnQ=";
    ldflags = [
      "-s"
      "-w"
    ];
  });
in
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
    ripgrep
    delta # brew: git-delta
    fastfetch
    onefetch
    duf
    gping
    hyperfine
    trippy # `trip`
    sshs
    rip2 # rm-improved
    lazyjj
    witr
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    zsh-completions
    zsh-autocomplete

    jujutsu # `jj`
    jjui # jj TUI
    neovim
    opencode
    yt-dlp
    act
    tree-sitter
    gdu
    navi
    tlrc
    dotenvx
    herdr
    diffnav # pinned to 0.11.0 via the let-binding above

    # Shell foundation, referenced unconditionally in shell init.
    mise
    direnv
    tmux
    # Pi and Zellij come from mise. Engram comes from Homebrew, not Nix;
    # scripts/engram-setup registers it with detected coding agents.
  ];
}

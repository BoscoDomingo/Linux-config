{ pkgs, ... }:
# Stable global CLI tools, managed by Nix. The ownership split (Nix vs mise vs
# Homebrew) is documented in
# [the migration doc](../../Documentation/Nix_exploration.md#9-tool-ownership--retiring-runsh).
# Package names are nixpkgs attributes. Search: https://search.nixos.org
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
    diffnav

    # Shell foundation, referenced unconditionally in shell init.
    mise
    direnv
    tmux
    # Pi and Zellij come from mise. Engram comes from Homebrew, not Nix;
    # scripts/engram-setup registers it with detected coding agents.
  ];
}

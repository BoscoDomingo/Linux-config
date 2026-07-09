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
    httpstat
    lazyjj
    witr
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    zsh-completions
    zsh-autocomplete

    jujutsu # `jj`
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
    # `pi` and `engram` are not in nixpkgs; both come from mise (ubi backend).
  ];
}

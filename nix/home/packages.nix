{ pkgs, ... }:
# The stable global CLI toolbox, managed by Nix.
#
# OWNERSHIP RULES (see Documentation/Nix_exploration.md §4/§6):
#   • Nix (this file) — stable, global CLI tools. Pinned by flake.lock,
#     installed identically on every machine by `home-manager switch`.
#   • mise (.config/mise/config.toml) — language runtimes (node/go/python/
#     rust/bun/pnpm) and dev tools tracked on `latest`/per-project
#     (biome, golangci-lint, pi, …).
#   • Homebrew — an escape hatch on any platform for tools not in nixpkgs, plus
#     macOS GUI casks declared via nix-darwin's `homebrew` module (hosts/macbook.nix).
# A tool lives in exactly ONE of these — no duplicates across systems.
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

    # Dev tools stable enough to pin with the toolbox; their config lives in
    # .config/* via dotfiles.nix.
    jujutsu # `jj`
    neovim
    opencode
    yt-dlp
    act
    tree-sitter

    # Shell foundation tools referenced unconditionally by .profile/.bashrc/
    # .zshrc, so Nix keeps the binaries present. mise manages language runtimes
    # and floating dev tools on top.
    mise
    direnv
    tmux
    # `pi` and `gentle-ai` are not in nixpkgs: `pi` stays in mise, `gentle-ai`
    # stays on its Homebrew tap (Linux + macOS) via Setup/installers.
  ];
}

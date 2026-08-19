{ pkgs, ... }:
# Stable global CLI tools, managed by Nix. The ownership split (Nix vs mise vs
# Homebrew) is documented in
# [Nix rationale](../../Documentation/Nix_exploration.md#51-tool-ownership).
# Package names are nixpkgs attributes. Search: https://search.nixos.org
let
  # nixpkgs 26.08.03 omits the z-async submodule required by zsh-autocomplete.
  zAsyncSource = pkgs.fetchFromGitHub {
    owner = "marlonrichert";
    repo = "z-async";
    rev = "5370537de80670b4a97e49cd253d15067709c0a6";
    hash = "sha256-tPosFoZSaUShaRpv7ca9BdOMREfmhnzjd/VKHSshhXo=";
  };
  zshAutocomplete = pkgs.zsh-autocomplete.overrideAttrs (old: {
    installPhase = old.installPhase + ''
      # zsh-autocomplete adds this directory to fpath.
      install -Dm644 ${zAsyncSource}/z-async \
        "$out/share/zsh-autocomplete/z-async/z-async"
    '';
  });

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
    delta 
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
    gh
    jq
    lazydocker
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    zsh-completions
    zshAutocomplete

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
  ];
}

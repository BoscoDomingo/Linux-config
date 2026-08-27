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
    rip2
    lazyjj
    witr
    gh
    jq
    lazydocker
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    zsh-completions
    zshAutocomplete

    jujutsu
    jjui
    neovim

    yt-dlp
    act
    tree-sitter
    gdu
    navi
    tlrc
    dotenvx
    herdr
    direnv
    tmux
    # Some tools (opencode, mise) are deliberately absent. See Nix_exploration for details
  ];
}

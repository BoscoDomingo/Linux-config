{ pkgs, ... }:
# The former Homebrew array (Setup/installers/packages.sh), as a Nix list.
# Every package here is pinned by flake.lock and installed identically on
# every machine by `home-manager switch` — no prompts, no `curl | bash`.
#
# Package names are nixpkgs attribute names, which occasionally differ from
# the Homebrew formula name (noted inline). Search: https://search.nixos.org
{
  home.packages = with pkgs; [
    # --- direct equivalents of the current brew list ---
    gcc
    cheat
    bottom # `btm`
    eza
    fd
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
    rip2 # nixpkgs: rip2 (aka rm-improved)
    zsh-autosuggestions
    zsh-fast-syntax-highlighting
    zsh-completions
    # progress          # coreutils progress viewer
    # httpstat
    # witr / lazyjj / diffnav → may come from flake inputs or be pending in
    #   nixpkgs; check search.nixos.org, else keep on brew/mise for now.

    # --- things previously installed via curl | bash or mise, if you want
    #     Nix to own them instead (optional; can stay on their installers) ---
    # starship        # or use programs.starship in shell.nix
    # oh-my-posh
  ];
}

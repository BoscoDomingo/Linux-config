{ config, lib, pkgs, ... }:
# Idempotent activation steps for the git-cloned / curled frameworks that
# aren't plain nixpkgs packages. They run on `home-manager switch` without
# prompts, and are best-effort (`|| true`) so a network hiccup never bricks a
# switch. The hand-written configs these use are symlinked via dotfiles.nix.
let
  repo = "${config.home.homeDirectory}/dotfiles";
  git = "${pkgs.git}/bin/git";
in
{
  # oh-my-zsh framework at ~/.oh-my-zsh. Cloned (not a Nix store path) so it
  # stays writable for its own cache/updates; .zshrc points $ZSH here.
  home.activation.ohMyZsh = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -d "$HOME/.oh-my-zsh/.git" ]; then
      run ${git} clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || true
    fi
  '';

  # tmux plugin manager (tpm). tmux binary comes from packages.nix.
  home.activation.tpm = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
      run ${git} clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || true
    fi
  '';

  # cheat community cheatsheets (personal sheets + conf.yml come from the
  # .config/cheat symlink; this dir is gitignored in the repo).
  home.activation.cheatSheets = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    community="''${XDG_CONFIG_HOME:-$HOME/.config}/cheat/cheatsheets/community"
    if [ ! -d "$community/.git" ]; then
      run ${git} clone --depth 1 https://github.com/cheat/cheatsheets.git "$community" || true
    fi
  '';

  # micro Catppuccin colorschemes (downloaded into the gitignored colorschemes/).
  home.activation.microThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    dir="''${XDG_CONFIG_HOME:-$HOME/.config}/micro/colorschemes"
    run mkdir -p "$dir"
    for t in catppuccin-macchiato catppuccin-macchiato-transparent; do
      if [ ! -f "$dir/$t.micro" ]; then
        run ${pkgs.curl}/bin/curl -fsSL \
          "https://raw.githubusercontent.com/catppuccin/micro/main/themes/$t.micro" \
          -o "$dir/$t.micro" || true
      fi
    done
  '';

  # AI-agent jj-approval guards.
  home.activation.jjGuards = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -f "${repo}/AI/agent-guards/install.py" ]; then
      run ${pkgs.python3}/bin/python3 "${repo}/AI/agent-guards/install.py" || true
    fi
  '';
}

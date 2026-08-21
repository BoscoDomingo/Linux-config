{ config, lib, pkgs, ... }:
# Idempotent activation steps for the git-cloned / curled frameworks that
# aren't plain nixpkgs packages. They run during Home Manager activation without
# prompts, and are best-effort (`|| true`) so a network hiccup never bricks a
# switch. The hand-written configs these use are symlinked via dotfiles.nix.
let
  repo = "${config.home.homeDirectory}/dotfiles";
  git = "${pkgs.git}/bin/git";
  # The opencode installer shells out to plain Unix tools; activation runs with a
  # restricted PATH, so hand it the ones it needs.
  opencodeInstallerPath = lib.makeBinPath [
    pkgs.curl
    pkgs.gnutar
    pkgs.gzip
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
in
{
  # Ensure ~/.config/jj is a real directory,
  # then point tool-expected paths at the gitignored overrides/ tree.
  # See Documentation/machine-overrides.md.
  home.activation.machineOverrides = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    overrides="${repo}/overrides"
    mkdir -p "$overrides/git" "$overrides/jj" "$overrides/mise" "$overrides/brew"

    jjdir="$HOME/.config/jj"
    if [ -L "$jjdir" ]; then
      echo "Migrating ~/.config/jj from directory symlink to real directory"
      tmp=$(mktemp -d)
      [ -d "$jjdir/repos" ] && cp -a "$jjdir/repos" "$tmp/repos"
      # Prefer existing overrides/jj; otherwise rescue conf.d contents once.
      if [ -d "$jjdir/conf.d" ] && [ ! -L "$jjdir/conf.d" ]; then
        cp -a "$jjdir/conf.d/." "$overrides/jj/" 2>/dev/null || true
      fi
      rm -f "$jjdir"
      mkdir -p "$jjdir"
      [ -d "$tmp/repos" ] && mv "$tmp/repos" "$jjdir/repos"
      rm -rf "$tmp"
    fi
    mkdir -p "$jjdir"
    # conf.d -> overrides/jj (replace a real dir left from older setups)
    if [ -d "$jjdir/conf.d" ] && [ ! -L "$jjdir/conf.d" ]; then
      cp -a "$jjdir/conf.d/." "$overrides/jj/" 2>/dev/null || true
      rm -rf "$jjdir/conf.d"
    fi
    ln -sfn "$overrides/jj" "$jjdir/conf.d"

    # mise global overlay
    mkdir -p "$HOME/.mise"
    ln -sfn "$overrides/mise/config.toml" "$HOME/.mise/config.toml"
  '';

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

  # opencode from the upstream installer instead of nixpkgs. The nixpkgs package
  # is a Bun standalone compiled by an autoPatchelfHook'd bun; the shifted ELF
  # offsets make it segfault in ld-linux on WSL2 (NixOS/nixpkgs#520383), so the
  # command exits 139 with no output. `--no-modify-path` stops the installer from
  # appending PATH lines to the repo-symlinked .zshrc; .profile adds the bin dir.
  # Guarded on the binary being absent, so a switch never re-downloads 180 MB.
  # Upgrades are manual, because .config/opencode/opencode.json sets
  # `autoupdate: notify`: re-run the installer, or delete the binary and switch.
  home.activation.opencode = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ ! -x "$HOME/.opencode/bin/opencode" ]; then
      installer="$(${pkgs.coreutils}/bin/mktemp)"
      run ${pkgs.curl}/bin/curl -fsSL https://opencode.ai/install -o "$installer" || true
      run env PATH="${opencodeInstallerPath}:$PATH" \
        ${pkgs.bash}/bin/bash "$installer" --no-modify-path || true
      ${pkgs.coreutils}/bin/rm -f "$installer"
    fi
  '';

  # AI-agent jj-approval guards.
  home.activation.jjGuards = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -f "${repo}/AI/agent-guards/install.py" ]; then
      run ${pkgs.python3}/bin/python3 "${repo}/AI/agent-guards/install.py" || true
    fi
  '';

  # Register engram (agent memory) with every coding agent detected on the
  # machine. Activation uses a restricted PATH, so include both supported
  # Homebrew prefixes where this repository declares Engram ownership. Exit
  # code 10 (agents awaiting an interactive `engram setup`) is a reminder, not
  # an activation failure, so it is swallowed with the other exit codes.
  home.activation.engram = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -x "${repo}/scripts/engram-setup" ]; then
      run env PATH="/home/linuxbrew/.linuxbrew/bin:/opt/homebrew/bin:$PATH" \
        ${pkgs.bash}/bin/bash "${repo}/scripts/engram-setup" || true
    fi
  '';
}

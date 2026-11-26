{ config, lib, pkgs, ... }:
# Idempotent activation steps for the git-cloned / curled frameworks that
# aren't plain nixpkgs packages. They run during Home Manager activation without
# prompts, and are best-effort (`|| true`) so a network hiccup never bricks a
# switch. The hand-written configs these use are symlinked via dotfiles.nix.
let
  repo = "${config.home.homeDirectory}/dotfiles";
  git = "${pkgs.git}/bin/git";
  # The opencode installer shells out to plain Unix tools. Activation runs with
  # a restricted PATH, so give the installer the tools it needs.
  installerPath = lib.makeBinPath [
    pkgs.curl
    pkgs.gnutar
    pkgs.gzip
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
  # Device-local opt-out: list step keys (the snake_case names given to
  # `optional` below, one per line) in this gitignored file to skip those steps
  # on this machine only, for example `agent_guards`. Checked at activation
  # time, so no flake rebuild is needed. See Documentation/machine-overrides.md.
  disabledSteps = "${repo}/overrides/activation/disabled";
  # Device-local variables for activation steps, one KEY=value per line, so a
  # machine can change a value (such as a path) without a new override file.
  # See Documentation/machine-overrides.md.
  varsFile = "${repo}/overrides/vars.env";
  # Shell helper for steps: `override_var KEY DEFAULT` prints KEY from varsFile
  # (last match wins, optional double quotes, leading `~` means $HOME), else
  # DEFAULT. The file is parsed, not sourced, so it cannot run code or leak
  # variables into other steps.
  overrideVarFn = ''
    override_var() {
      local v
      v="$(${pkgs.gnused}/bin/sed -nE "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "${varsFile}" 2>/dev/null \
        | ${pkgs.coreutils}/bin/tail -n 1 \
        | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+$//; s/^"(.*)"$/\1/' || true)"
      case "$v" in
        "~") v="$HOME" ;;
        "~/"*) v="$HOME/''${v#"~/"}" ;;
      esac
      printf '%s\n' "''${v:-$2}"
    }
  '';
  # utils skills to link into ~/.agents/skills. Other skills in that repo also
  # ship through the-armoury plugin, so linking them here would duplicate them.
  utilsSkills = [ "jj-help" "use-asd-ste100" ];
  # Wrap a step body so it runs only when its name is not in disabledSteps.
  optional = name: body: ''
    if [ -f "${disabledSteps}" ] && ${pkgs.gnugrep}/bin/grep -qxE '[[:space:]]*${name}[[:space:]]*' "${disabledSteps}"; then
      echo "Skipping ${name}: listed in ${disabledSteps}"
    else
    ${body}
    fi
  '';
in
{
  # Ensure ~/.config/jj is a real directory,
  # then point tool-expected paths at the gitignored overrides/ tree.
  # See Documentation/machine-overrides.md.
  home.activation.machineOverrides = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    # This migration uses conditional filesystem operations that cannot be
    # represented safely through Home Manager's command-level dry-run wrapper.
    if [ -n "''${DRY_RUN:-}" ]; then
      echo "Would migrate jj and mise machine-override links"
    else
    overrides="${repo}/overrides"
    mkdir -p "$overrides/git" "$overrides/jj" "$overrides/mise" "$overrides/brew" "$overrides/patches" "$overrides/activation"

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
    fi
  '';

  # oh-my-zsh framework at ~/.oh-my-zsh. Cloned (not a Nix store path) so it
  # stays writable for its own cache/updates; .zshrc points $ZSH here.
  home.activation.ohMyZsh = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "oh_my_zsh" ''
    if [ ! -d "$HOME/.oh-my-zsh/.git" ]; then
      run ${git} clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh" || true
    fi
  '');

  # tmux plugin manager (tpm). tmux binary comes from packages.nix.
  home.activation.tpm = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "tpm" ''
    if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
      run ${git} clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || true
    fi
  '');

  # cheat community cheatsheets (personal sheets + conf.yml come from the
  # .config/cheat symlink; this dir is gitignored in the repo).
  home.activation.cheatSheets = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "cheat_sheets" ''
    community="''${XDG_CONFIG_HOME:-$HOME/.config}/cheat/cheatsheets/community"
    if [ ! -d "$community/.git" ]; then
      run ${git} clone --depth 1 https://github.com/cheat/cheatsheets.git "$community" || true
    fi
  '');

  # micro Catppuccin colorschemes (downloaded into the gitignored colorschemes/).
  home.activation.microThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "micro_themes" ''
    dir="''${XDG_CONFIG_HOME:-$HOME/.config}/micro/colorschemes"
    run mkdir -p "$dir"
    for t in catppuccin-macchiato catppuccin-macchiato-transparent; do
      if [ ! -f "$dir/$t.micro" ]; then
        run ${pkgs.curl}/bin/curl -fsSL \
          "https://raw.githubusercontent.com/catppuccin/micro/main/themes/$t.micro" \
          -o "$dir/$t.micro" || true
      fi
    done
  '');

  # opencode from the upstream installer instead of nixpkgs. The nixpkgs package
  # is a Bun standalone compiled by an autoPatchelfHook'd bun; the shifted ELF
  # offsets make it segfault in ld-linux on WSL2 (NixOS/nixpkgs#520383), so the
  # command exits 139 with no output. `--no-modify-path` stops the installer from
  # appending PATH lines to the repo-symlinked .zshrc; .profile adds the bin dir.
  # Guarded on the binary being absent, so a switch never re-downloads 180 MB.
  # Upgrades are manual, because .config/opencode/opencode.json sets
  # `autoupdate: notify`: re-run the installer, or delete the binary and switch.
  home.activation.opencode = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "opencode" ''
    if [ ! -x "$HOME/.opencode/bin/opencode" ]; then
      installer="$(${pkgs.coreutils}/bin/mktemp)"
      run ${pkgs.curl}/bin/curl -fsSL https://opencode.ai/install -o "$installer" || true
      run env PATH="${installerPath}:$PATH" \
        ${pkgs.bash}/bin/bash "$installer" --no-modify-path || true
      ${pkgs.coreutils}/bin/rm -f "$installer"
    fi
  '');

  # Install AI-agent jj shell guards and the chat approval helper.
  # Opt-out key agent_guards also turns off OpenCode's jj rules (see .profile).
  home.activation.agentGuards = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "agent_guards" ''
    if [ -f "${repo}/AI/agent-guards/install.py" ]; then
      run ${pkgs.python3}/bin/python3 "${repo}/AI/agent-guards/install.py" || true
    fi
  '');

  # Personal agent skills from github.com/BoscoDomingo/utils. Cloned (not a Nix
  # store path) so the skills stay editable, and symlinked so agents see edits
  # at once. Each switch fetches and moves the clone to main@origin, but only
  # when no local work would be left behind: the working-copy change must be
  # empty and undescribed, and every other change must already be on
  # main@origin. Otherwise the step prints a note and keeps the checkout.
  # The clone path is UTILS_DIR in overrides/vars.env: work devices set
  # ~/repos/personal/utils to keep personal repos apart from work ones.
  home.activation.utilsSkills = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "utils_skills" ''
    ${overrideVarFn}
    dir="$(override_var UTILS_DIR "$HOME/repos/utils")"

    # jj fetches through git, and git through ssh. Activation replaces PATH
    # with Nix tools only, so add both. BatchMode and GIT_TERMINAL_PROMPT stop
    # an SSH passphrase or credential prompt from blocking the switch; a failed
    # fetch only skips the update.
    utils_vcs() {
      env PATH="${lib.makeBinPath [ pkgs.git pkgs.openssh ]}:$PATH" GIT_TERMINAL_PROMPT=0 \
        GIT_SSH_COMMAND="ssh -o BatchMode=yes" "$@"
    }
    jj="${pkgs.jujutsu}/bin/jj"

    if [ ! -e "$dir" ]; then
      run ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$dir")"
      # HTTPS, because a new machine may not have SSH keys yet (the repo is public).
      run utils_vcs "$jj" git clone --colocate https://github.com/BoscoDomingo/utils.git "$dir" || true
    elif [ -d "$dir/.jj" ]; then
      if run utils_vcs "$jj" -R "$dir" git fetch --remote origin; then
        # Changes a move to main@origin would leave behind. Empty means safe.
        if pending="$(utils_vcs "$jj" -R "$dir" log --no-graph \
            -r '(::@ ~ ::main@origin) ~ (@ & empty() & description(exact:""))' \
            -T 'commit_id ++ "\n"')"; then
          if [ -n "$pending" ]; then
            echo "utils: local changes in $dir, not moving it to main@origin"
          elif [ -z "$(utils_vcs "$jj" -R "$dir" log --no-graph -r '@- & main@origin' -T 'commit_id')" ]; then
            run utils_vcs "$jj" -R "$dir" new main@origin || true
          fi
        fi
      else
        echo "utils: fetch failed, keeping the current checkout of $dir"
      fi
    elif [ -d "$dir/.git" ]; then
      run utils_vcs ${git} -C "$dir" pull --ff-only || true
    fi

    for skill in ${lib.escapeShellArgs utilsSkills}; do
      target="$dir/ai_llm/skills/$skill"
      link="$HOME/.agents/skills/$skill"
      if [ ! -d "$target" ]; then
        echo "utils: $target is missing, not linking $skill"
      elif [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "utils: $link is not a symlink, leaving it as it is"
      else
        run ${pkgs.coreutils}/bin/mkdir -p "$HOME/.agents/skills"
        run ${pkgs.coreutils}/bin/ln -sfn "$target" "$link"
      fi
    done
  '');

  # Copilot CLI sandbox: let sandboxed hooks see herdr's agent-state script and
  # reach its unix socket. Without this, the herdr SessionStart hook fails with
  # "No such file or directory" inside bwrap. ~/.copilot/settings.json is owned
  # and rewritten by Copilot itself (plugins, hooks, model), so it cannot be a
  # symlink; merge only the two paths instead. Idempotent, and skipped when
  # Copilot has not created the file yet.
  home.activation.copilotSandboxHerdr = lib.hm.dag.entryAfter [ "linkGeneration" ] (optional "copilot_sandbox_herdr" ''
    settings="$HOME/.copilot/settings.json"
    if [ -f "$settings" ] && [ -z "''${DRY_RUN:-}" ]; then
      tmp="$(${pkgs.coreutils}/bin/mktemp)"
      if ${pkgs.jq}/bin/jq --arg ro "$HOME/.copilot/hooks" --arg rw "$HOME/.config/herdr" '
          .sandbox.userPolicy.filesystem.readonlyPaths |= ((. // []) + [$ro] | unique)
          | .sandbox.userPolicy.filesystem.readwritePaths |= ((. // []) + [$rw] | unique)
        ' "$settings" > "$tmp"; then
        ${pkgs.coreutils}/bin/cat "$tmp" > "$settings"
      fi
      ${pkgs.coreutils}/bin/rm -f "$tmp"
    fi
  '');
}

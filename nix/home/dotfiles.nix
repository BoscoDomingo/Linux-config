{ config, ... }:
# Declarative dotfile symlinks.
#
# `mkOutOfStoreSymlink` links straight to the files in this repo checkout, so
# .zshrc / .config/* stay editable in place — the files are not copied
# read-only into /nix/store. Home Manager owns the link set: it creates them
# atomically and prunes links dropped from this set.
let
  # TODO: point at where this repo is cloned on the machine.
  repo = "${config.home.homeDirectory}/dotfiles";
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
  # Root-level dotfiles (the loop in symlinks.sh).
  home.file = {
    ".profile".source = link "${repo}/.profile";
    ".shellrc".source = link "${repo}/.shellrc";
    ".aliases".source = link "${repo}/.aliases";
    ".bashrc".source = link "${repo}/.bashrc";
    ".zshrc".source = link "${repo}/.zshrc";
    ".zprofile".source = link "${repo}/.zprofile";
    ".nanorc".source = link "${repo}/.nanorc";
    ".nirc".source = link "${repo}/.nirc";
    ".npmrc".source = link "${repo}/.npmrc";
    ".bunfig.toml".source = link "${repo}/.bunfig.toml";
    # Work/personal separation is handled inside .gitconfig itself: it keeps a
    # baseline [user] and `[include]`s an untracked ~/.config/git/local.gitconfig
    # (plus per-directory includeIf) that overrides it per machine. See
    # exploration doc §8.1. The symlink here is unchanged.
    ".gitconfig".source = link "${repo}/.gitconfig";
    ".gitignore_global".source = link "${repo}/.gitignore_global";

    # scripts/ → ~/.local/bin/scripts (matches symlinks.sh)
    ".local/bin/scripts".source = link "${repo}/scripts";

    # SSH config (SSH keys themselves stay out of the repo)
    ".ssh/config".source = link "${repo}/.ssh/config";
    ".ssh/allowed_signers".source = link "${repo}/.ssh/allowed_signers";
  };

  # The `.config/*/` loop, declaratively. One line per config dir; add/remove
  # freely. (25 dirs today — a representative subset shown here.)
  xdg.configFile = {
    "starship.toml".source = link "${repo}/.config/starship.toml";
    "ghostty".source = link "${repo}/.config/ghostty";
    "nvim".source = link "${repo}/.config/nvim";
    "mise".source = link "${repo}/.config/mise";
    "jj".source = link "${repo}/.config/jj";
    "tmux".source = link "${repo}/.config/tmux";
    "bat".source = link "${repo}/.config/bat";
    "btop".source = link "${repo}/.config/btop";
    "lsd".source = link "${repo}/.config/lsd";
    "opencode".source = link "${repo}/.config/opencode";
    "zed".source = link "${repo}/.config/zed";
    "cheat".source = link "${repo}/.config/cheat"; # community sheets land in a gitignored subdir
    "micro".source = link "${repo}/.config/micro"; # colorschemes land in a gitignored subdir
    # … remaining dirs: MangoHud bottom diffnav direnv fastfetch hypr
    #   pnpm superfile tealdeer tmux-powerline vicinae zellij zsh
  };
}

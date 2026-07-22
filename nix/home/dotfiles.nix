{ config, ... }:
# Declarative dotfile symlinks.
#
# `mkOutOfStoreSymlink` links straight to the files in this repo checkout, so
# .zshrc / .config/* stay editable in place — the files are not copied
# read-only into /nix/store. Home Manager owns the link set: it creates them
# atomically and prunes links dropped from this set.
let
  repo = "${config.home.homeDirectory}/dotfiles"; # repo checkout location
  link = config.lib.file.mkOutOfStoreSymlink;
in
{
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
    # Work/personal separation is handled inside .gitconfig itself.
    ".gitconfig".source = link "${repo}/.gitconfig";
    ".gitignore_global".source = link "${repo}/.gitignore_global";

    ".local/bin/scripts".source = link "${repo}/scripts";

    ".ssh/config".source = link "${repo}/.ssh/config";
    ".ssh/allowed_signers".source = link "${repo}/.ssh/allowed_signers";

    # Pi agent config lives under AI/ in the repo so the checkout isn't
    # auto-loaded as agent context when opened.
    ".pi/agent".source = link "${repo}/AI/.pi/agent";

    # Bare-metal Cursor / VS Code editor config (the repo keeps it in vscode/).
    # WSL-only IDE-server links live in hosts/arch-wsl.nix.
    ".cursor/extensions/extensions.json".source = link "${repo}/vscode/extensions-cursor.json";
  };

  xdg.configFile = {
    "starship.toml".source = link "${repo}/.config/starship.toml";
    "Cursor/User/settings.json".source = link "${repo}/vscode/settings.json";
    "Cursor/User/keybindings.json".source = link "${repo}/vscode/keybindings.json";
    "starship_catpuccin.toml".source = link "${repo}/.config/starship_catpuccin.toml";
    "MangoHud".source = link "${repo}/.config/MangoHud";
    "bat".source = link "${repo}/.config/bat";
    "bottom".source = link "${repo}/.config/bottom";
    "btop".source = link "${repo}/.config/btop";
    "cheat".source = link "${repo}/.config/cheat";
    "diffnav".source = link "${repo}/.config/diffnav";
    "direnv".source = link "${repo}/.config/direnv";
    "fastfetch".source = link "${repo}/.config/fastfetch";
    "ghostty".source = link "${repo}/.config/ghostty";
    "hypr".source = link "${repo}/.config/hypr";
    "jj".source = link "${repo}/.config/jj";
    "lsd".source = link "${repo}/.config/lsd";
    "micro".source = link "${repo}/.config/micro";
    "mise".source = link "${repo}/.config/mise";
    "nvim".source = link "${repo}/.config/nvim";
    "opencode".source = link "${repo}/.config/opencode";
    "pnpm".source = link "${repo}/.config/pnpm";
    "superfile".source = link "${repo}/.config/superfile";
    "tealdeer".source = link "${repo}/.config/tealdeer";
    "tmux".source = link "${repo}/.config/tmux";
    "tmux-powerline".source = link "${repo}/.config/tmux-powerline";
    "vicinae".source = link "${repo}/.config/vicinae";
    "zed".source = link "${repo}/.config/zed";
    "zellij".source = link "${repo}/.config/zellij";
    "zsh".source = link "${repo}/.config/zsh";
  };
}

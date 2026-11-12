{ ... }:
# Per-machine git identity via the gitignored overrides/ tree.
# See Documentation/machine-overrides.md.
#
# When this module is used, drop the .gitconfig symlink from dotfiles.nix so
# Home Manager owns git config. Identity files stay in overrides/git/ (never
# committed):
#   overrides/git/local.gitconfig
#   overrides/git/work.gitconfig
#   overrides/git/personal.gitconfig
{
  programs.git = {
    enable = true;
    userName = "Bosco Domingo";

    # Later entries win (i.e. dotfiles use personal.gitconfig instead of default).
    includes = [
      { path = "~/dotfiles/overrides/git/local.gitconfig"; }
      {
        condition = "gitdir:~/repos/";
        path = "~/dotfiles/overrides/git/work.gitconfig";
      }
      {
        condition = "gitdir:~/dotfiles/";
        path = "~/dotfiles/overrides/git/personal.gitconfig";
      }
      {
        condition = "gitdir:~/personal/";
        path = "~/dotfiles/overrides/git/personal.gitconfig";
      }
    ];
  };
}

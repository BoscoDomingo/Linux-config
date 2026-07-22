{ ... }:
# Per-machine git identity (work vs personal) without baking it into the repo.
# See [the migration doc](../../Documentation/Nix_exploration.md#8-per-machine-identity--secrets-work-vs-personal).
#
# When this module is used, drop the .gitconfig symlink from dotfiles.nix so
# Home Manager owns git config. Identity comes from untracked local files you
# write per machine:
#   ~/.config/git/local.gitconfig    (this machine's default identity)
#   ~/.config/git/work.gitconfig     (optional, for ~/repos/work/** repos)
#   ~/.config/git/personal.gitconfig (optional, for ~/repos/personal/** repos)
#
# Example ~/.config/git/local.gitconfig (never committed):
#   [user]
#       email = you@work.example
#       signingKey = key::ssh-ed25519 AAAA…work-key…
{
  programs.git = {
    enable = true;
    userName = "Bosco Domingo"; # name is safe to share; email/key are not

    # Home Manager writes these [include]/[includeIf] entries; the target files
    # stay local and untracked, so no work email lands in a public repo.
    includes = [
      { path = "~/.config/git/local.gitconfig"; }
      {
        condition = "gitdir:~/repos/work/";
        path = "~/.config/git/work.gitconfig";
      }
      {
        condition = "gitdir:~/repos/personal/";
        path = "~/.config/git/personal.gitconfig";
      }
    ];

    # Non-identity settings either move here or stay in the symlinked .gitconfig.
    # extraConfig = {
    #   commit.gpgSign = true;
    #   gpg.format = "ssh";
    #   "gpg \"ssh\"".program = "ssh-sign";
    # };
  };
}

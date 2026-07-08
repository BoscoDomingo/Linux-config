{ ... }:
# Per-machine git identity (work vs personal) without baking it into the repo.
# See Documentation/Nix_exploration.md §8.
#
# When this module is used, drop the .gitconfig symlink from dotfiles.nix so
# Home Manager owns git config. Identity comes from untracked local files you
# write per machine:
#   ~/.config/git/local.gitconfig   (this machine's default identity)
#   ~/.config/git/work.gitconfig    (optional, for ~/work/** repos)
#   ~/.config/git/personal.gitconfig(optional, for ~/personal/** repos)
#
# Example ~/.config/git/local.gitconfig (never committed):
#   [user]
#       email = bosco.domingo@iceye.com
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
        condition = "gitdir:~/work/";
        path = "~/.config/git/work.gitconfig";
      }
      {
        condition = "gitdir:~/personal/";
        path = "~/.config/git/personal.gitconfig";
      }
    ];

    # Everything else can either be ported here from .gitconfig, or you can keep
    # the .gitconfig symlink (dotfiles.nix) as the source of truth for the
    # non-identity settings and use this module only for the identity includes.
    #
    # extraConfig = {
    #   commit.gpgSign = true;
    #   gpg.format = "ssh";
    #   "gpg \"ssh\"".program = "ssh-sign";
    # };
  };

  # The SSH *private* key is never managed by Nix. It stays in ~/.ssh/ per
  # machine; scripts/ssh-sign already selects it via SSH_SIGN_KEY_PATH, so a
  # work box and a personal box each point at their own key with no repo change.
}

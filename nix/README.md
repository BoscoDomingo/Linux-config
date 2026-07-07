# `nix/` — proposal skeleton (inert)

This directory is a **starting point for the Nix migration described in
[`../Documentation/Nix_exploration.md`](../Documentation/Nix_exploration.md)**.

> ⚠️ It does nothing on its own. It is not wired into `run.sh`. Nothing here
> runs until you install Nix and invoke `home-manager` deliberately. It is safe
> to leave in the repo indefinitely while you evaluate.

## Try it (Phase 0)

1. Install Nix (flakes enabled by default):
   ```sh
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```
2. Edit the placeholders marked `TODO` in `flake.nix` and `home/*.nix`
   (your username, home dir, which host you're on, the repo checkout path).
3. Dry-run, then apply for your host:
   ```sh
   cd ~/dotfiles/nix
   nix run home-manager/master -- switch --flake .#arch-wsl -n   # -n = dry run
   nix run home-manager/master -- switch --flake .#arch-wsl
   ```
4. Roll back if anything looks wrong:
   ```sh
   home-manager generations              # list
   home-manager switch --rollback        # undo last switch
   ```

## Layout

| File | Role |
|------|------|
| `flake.nix` | Inputs (nixpkgs, home-manager, nix-darwin) and per-host outputs |
| `home/common.nix` | Shared config imported by every host |
| `home/packages.nix` | The former Homebrew array, as a Nix package list |
| `home/dotfiles.nix` | Out-of-store symlinks to your existing repo files (keeps them editable) |
| `home/shell.nix` | Example native Home Manager modules (zsh/starship/fzf/direnv) |
| `home/git.nix` | Opt-in: per-machine git identity (work vs personal) via `includeIf` |
| `hosts/*.nix` | Per-machine / per-OS overrides |

Per-machine identity (git email + signing key) and secrets are covered in
exploration doc §8. The short version: keep them in an untracked
`~/.config/git/local.gitconfig` per machine and `[include]` it — the SSH
private key stays in `~/.ssh/` and is never committed.

Start with `dotfiles.nix` (Phase 1) — it's the lowest-risk, highest-value part.

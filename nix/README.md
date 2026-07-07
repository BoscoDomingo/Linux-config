# `nix/` — Home Manager config (working, tested)

The Nix implementation of the migration described in
[`../Documentation/Nix_exploration.md`](../Documentation/Nix_exploration.md).
It is **not wired into `run.sh`** — it does nothing until you install Nix and
invoke it deliberately, so it's safe to keep in the repo while you adopt it in
phases. It has been **verified end-to-end on a clean machine**: see
[`test/README.md`](test/README.md) (packages, out-of-store dotfile symlinks,
per-machine + per-directory git identity overrides, and atomic rollback all
pass).

## Try it

On a normal network:

```sh
HOST=ubuntu bash ~/dotfiles/nix/bootstrap.sh   # HOST = arch-wsl | ubuntu | macbook
```

That installs Nix (if missing) and runs `home-manager switch -b hm-bak`. Or do
it by hand:

```sh
cd ~/dotfiles/nix
nix run home-manager/master -- switch --flake .#ubuntu -n   # -n = dry run
nix run home-manager/master -- switch -b hm-bak --flake .#ubuntu
home-manager generations && home-manager switch --rollback  # undo if needed
```

Two things are genuinely per-user, left as `TODO` in `flake.nix`: your
`username` and the repo checkout path (`dotfiles.nix` assumes `~/dotfiles`).
For locked-down networks (blocked GitHub tarball fetch), see
[`test/README.md`](test/README.md).

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
| `bootstrap.sh` | One-command setup for a new machine (normal network) |
| `test/verify.sh` | Post-switch sanity checks; `test/README.md` records the verified run |

Per-machine identity (git email + signing key) and secrets are covered in
exploration doc §8. The short version: keep them in an untracked
`~/.config/git/local.gitconfig` per machine and `[include]` it — the SSH
private key stays in `~/.ssh/` and is never committed.

Start with `dotfiles.nix` (Phase 1) — it's the lowest-risk, highest-value part.

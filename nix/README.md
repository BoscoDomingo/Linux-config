# `nix/` — Home Manager config (working, tested)

The Nix implementation of the migration described in
[`../Documentation/Nix_exploration.md`](../Documentation/Nix_exploration.md).
It is the setup path for this repo: `bootstrap.sh` installs Nix and runs
`home-manager switch`, and the distro scripts (`../Arch/run_arch.sh`,
`../Ubuntu/run_ubuntu.sh`) hand off to it on a fresh machine. It has been
**verified end-to-end on a clean machine**: see [`test/README.md`](test/README.md)
(packages, out-of-store dotfile symlinks, per-machine + per-directory git
identity overrides, and atomic rollback all pass).

## Try it

```sh
bash ~/dotfiles/nix/bootstrap.sh   # auto-detects arch vs arch-wsl; override with HOST=<arch|arch-wsl|ubuntu|macbook>
```

That installs Nix (if missing) and runs `home-manager switch -b hm-bak`. Add
`INSTALL_BREW=1` to also install Homebrew; when Homebrew is available,
bootstrap installs the repository `Brewfile` (Engram and httpstat). Or do it by
hand:

```sh
cd ~/dotfiles/nix
nix run home-manager/master -- switch --flake .#arch -n   # -n = dry run
nix run home-manager/master -- switch -b hm-bak --flake .#arch
home-manager generations && home-manager switch --rollback  # undo if needed
```

`flake.nix` sets `username = "bosco"` and `dotfiles.nix` assumes the repo is at
`~/dotfiles`; adjust both if either differs. Where GitHub tarball fetch is
blocked, see [`test/README.md`](test/README.md).

## Layout

| File | Role |
|------|------|
| `flake.nix` | Inputs (nixpkgs, home-manager, nix-darwin) and per-host outputs |
| `home/common.nix` | Shared config imported by every host |
| `home/packages.nix` | The former Homebrew array, as a Nix package list |
| `home/dotfiles.nix` | Out-of-store symlinks to your existing repo files (keeps them editable) |
| `home/shell.nix` | Example native Home Manager modules (zsh/starship/fzf/direnv) |
| `home/git.nix` | Opt-in: per-machine git identity (work vs personal) via `includeIf` |
| `home/tools.nix` | Activation steps for git-cloned/curled frameworks (oh-my-zsh, tpm, cheat sheets, micro themes, jj guards, engram) |
| `hosts/*.nix` | Per-machine / per-OS overrides |
| `bootstrap.sh` | One-command setup for a new machine |
| `test/verify.sh` | Post-switch sanity checks; `test/README.md` records the verified run |

Per-machine identity (git email + signing key) and secrets are covered in
[the migration doc](../Documentation/Nix_exploration.md#8-per-machine-identity--secrets-work-vs-personal).
The short version: keep them in an untracked
`~/.config/git/local.gitconfig` per machine and `[include]` it — the SSH
private key stays in `~/.ssh/` and is never committed.

Start with `dotfiles.nix` (Phase 1) — it's the lowest-risk, highest-value part.

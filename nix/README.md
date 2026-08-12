# `nix/` — Home Manager config (working, tested)

The Nix implementation of the migration described in
[`../Documentation/Nix_exploration.md`](../Documentation/Nix_exploration.md).
The daily commands and update boundaries are documented in the
[`Nix + Home Manager cheatsheet`](../Documentation/Nix_cheatsheet.md).
It is the setup path for this repo: `bootstrap.sh` installs Nix and activates
the pinned Home Manager configuration, and the distro scripts (`../Arch/run_arch.sh`,
`../Ubuntu/run_ubuntu.sh`) hand off to it on a fresh machine. It has been
**verified end-to-end on a clean machine**: see [`test/README.md`](test/README.md)
(packages, out-of-store dotfile symlinks, per-machine + per-directory git
identity overrides, and atomic rollback all pass).

## Try it

```sh
bash ~/dotfiles/nix/bootstrap.sh   # auto-detects the host; override with HOST=<arch|arch-wsl|ubuntu|macbook>
```

That installs Nix (if missing) and runs the pinned activation package. Add
`INSTALL_BREW=1` to also install Homebrew; when Homebrew is available,
bootstrap installs the repository `Brewfile` (Engram and httpstat). Or do it by
hand:

For manual build, dry-run, activation, update, and rollback commands, use the
[`cheatsheet`](../Documentation/Nix_cheatsheet.md).

`flake.nix` sets `username = "bosco"` and `dotfiles.nix` assumes the repo is at
`~/dotfiles`; adjust both if either differs. Where GitHub tarball fetch is
blocked, see [`test/README.md`](test/README.md).

## Layout

| File                | Role                                                                                                              |
|---------------------|-------------------------------------------------------------------------------------------------------------------|
| `flake.nix`         | Inputs (nixpkgs, home-manager, nix-darwin) and per-host outputs                                                   |
| `home/common.nix`   | Shared config imported by every host                                                                              |
| `home/packages.nix` | The former Homebrew array, as a Nix package list                                                                  |
| `home/dotfiles.nix` | Out-of-store symlinks to your existing repo files (keeps them editable)                                           |
| `home/shell.nix`    | Example native Home Manager modules (zsh/starship/fzf/direnv)                                                     |
| `home/git.nix`      | Opt-in: per-machine git identity (work vs personal) via `includeIf`                                               |
| `home/tools.nix`    | Activation steps for git-cloned/curled frameworks (oh-my-zsh, tpm, cheat sheets, micro themes, jj guards, engram) |
| `hosts/*.nix`       | Per-machine / per-OS overrides                                                                                    |
| `bootstrap.sh`      | One-command setup for a new machine                                                                               |
| `test/verify.sh`    | Post-switch sanity checks; `test/README.md` records the verified run                                              |

Per-machine identity and device-only packages live in the gitignored
[`overrides/`](../Documentation/machine-overrides.md) tree (`git`, `jj`,
`mise`, `brew`). The SSH private key stays in `~/.ssh/` and is never committed.

The migration is active; use the cheatsheet for routine updates and rollback.

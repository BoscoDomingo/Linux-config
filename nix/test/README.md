# Fresh-machine test — verified run

This directory documents an end-to-end test of the `nix/` Home Manager config
on a **clean machine** (a fresh Linux user with no prior Nix, dotfiles, or
packages), including **per-machine local overrides**. It passed.

- [`verify.sh`](verify.sh) — reusable post-activation checks (packages, out-of-store
  symlinks, git identity overrides, rollback targets). Run it after any switch:
  `bash ~/dotfiles/nix/test/verify.sh`.
- [`container-test.sh`](container-test.sh) — one command to prove the whole
  thing in a throwaway Docker container (host untouched). Ubuntu by default;
  `DISTRO=arch bash nix/test/container-test.sh` for Arch. It installs Nix,
  clones the selected branch, seeds a work identity, runs `bootstrap.sh`, then
  `verify.sh`.

## What was verified (and the result)

| # | Property | Result |
|---|----------|--------|
| 1 | `nix build` of `homeConfigurations.<host>.activationPackage` **evaluates and builds** from the pinned inputs | ✅ built the generation (packages fetched from `cache.nixos.org`) |
| 2 | `home-manager` activation creates the profile + symlinks on a clean `$HOME` | ✅ `Creating home file links` / `installPackages` succeeded |
| 3 | Nix-installed CLIs are on `PATH` and runnable | ✅ verification enforces Nix provenance for the declared global toolbox |
| 4 | Dotfiles are **out-of-store symlinks to the live repo** (still editable in place) | ✅ `~/.zshrc → ~/dotfiles/.zshrc`; editing the repo file is visible immediately through the link |
| 5 | Pre-existing files are backed up, not clobbered | ✅ `.profile`/`.bashrc` → `*.hm-bak` (equivalent to `home-manager -b`) |
| 6 | **Per-machine git identity** via untracked `~/.config/git/local.gitconfig` overrides the committed baseline | ✅ work override wins; baseline stays `boscodomingob@gmail.com` |
| 7 | **Per-directory git identity** via `includeIf` | ✅ repo under `~/work` → work email; repo under `~/personal` → personal email |
| 8 | **Atomic rollback** between generations | ✅ gen2 added `tree` (on `PATH`); rollback to gen1 removed it while dotfiles stayed linked; generations recorded as `home-manager-{1,2,3}-link` |

The current live-host verification checks 30 package and symlink invariants.

The SSH **private** key was never placed in the repo or the Nix store at any
point — only its path is referenced (via `scripts/ssh-sign` / `SSH_SIGN_KEY_PATH`).

## How the test machine was set up

A brand-new unprivileged user with an empty home, then:

1. **Single-user Nix** installed from the official binary tarball
   (`releases.nixos.org`), flakes enabled.
2. The dotfiles checked out to `~/dotfiles`.
3. `nix build .#homeConfigurations.ubuntu.activationPackage` → `./result/activate`.
4. Created `~/.config/git/local.gitconfig` (work identity) + `~/work` and
   `~/personal` repos to exercise the overrides.
5. Ran `verify.sh`; built a 2nd generation and rolled back.

## Running it where GitHub tarball fetch is blocked (CI / locked-down networks)

Normal machines fetch flake inputs from GitHub. Some sandboxes block
`codeload.github.com`/`api.github.com` tarball endpoints while still allowing
`cache.nixos.org`. In that case, pre-fetch the inputs and point the flake at
local copies with `--override-input` (this is exactly how the test above ran):

```sh
# nixpkgs from the channel tarball (allowed even when codeload is blocked)
curl -fsSL https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz | tar -xJ -C /opt/nixsrc
# home-manager / nix-darwin via git (git-over-https to github still works)
git clone --depth 1 https://github.com/nix-community/home-manager /opt/nixsrc/home-manager
git clone --depth 1 https://github.com/LnL7/nix-darwin        /opt/nixsrc/nix-darwin

nix build .#homeConfigurations.ubuntu.activationPackage \
  --override-input nixpkgs      "path:/opt/nixsrc/nixpkgs-<version>" \
  --override-input home-manager path:/opt/nixsrc/home-manager \
  --override-input nix-darwin   path:/opt/nixsrc/nix-darwin
./result/activate
```

Otherwise you skip all of that — see [`../bootstrap.sh`](../bootstrap.sh).

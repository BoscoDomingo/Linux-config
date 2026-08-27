# Nix + Home Manager cheatsheet

This repository uses standalone Home Manager. The examples below target the
live Arch WSL host; set `HOST` to `arch`, `ubuntu`, or `macbook` elsewhere.
Nix manages declared user packages and dotfiles; it does **not** update the
host operating system itself.

```sh
DOTFILES_REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
HOST="arch-wsl"
```

## The important update distinction

Updating `nixpkgs` is not a full operating-system upgrade: it does not run
`pacman`, update Windows/WSL, or change Homebrew and mise-managed tools.

Most Nix packages in this repository share one pinned `nixpkgs` revision. If
you want a newer Nix-managed package, the current update boundary is therefore:

```sh
nix flake update nixpkgs --flake "$DOTFILES_REPO/nix"
# nix flake update nixpkgs --flake "$PWD/nix" # if you are in the repo root
```

That makes every package sourced from `nixpkgs` *eligible* for an update. Nix
only downloads/builds derivations whose resolved outputs changed, and the new
Home Manager generation is activated atomically.

**There is no generic command
that advances only one package** while all other packages remain at the old nixpkgs
revision.
Doing that persistently would require a dedicated flake input or
package override for each package, which adds maintenance overhead.

## Apply the current locked configuration

Build without changing live state:

```sh
activation="$(
  nix build --no-link --print-out-paths \
    "$DOTFILES_REPO/nix#homeConfigurations.$HOST.activationPackage"
)"
```

Inspect the activation plan:

```sh
DRY_RUN=1 VERBOSE=1 "$activation/activate"
```

Activate and verify:

```sh
HOME_MANAGER_BACKUP_EXT=hm-bak "$activation/activate"
bash "$DOTFILES_REPO/nix/test/verify.sh"
```

This applies the versions already pinned in `nix/flake.lock`; it does not
fetch newer package revisions.

## Full repository reconciliation

```sh
dotfiles-bootstrap
# bash "$DOTFILES_REPO/nix/bootstrap.sh"  # same thing, before the wrapper is on PATH
```

Use bootstrap on a new device or when you want to reconcile Nix, the Brewfile,
mise tools, activation hooks, and verification together. It is broader than
necessary for a routine Home Manager switch.

## Update Nix packages

Update every flake input:

```sh
nix flake update --flake "$DOTFILES_REPO/nix"
```

Update only the shared nixpkgs revision:

```sh
nix flake update nixpkgs --flake "$DOTFILES_REPO/nix"
```

Update only Home Manager:

```sh
nix flake update home-manager --flake "$DOTFILES_REPO/nix"
```

Review, build, activate, and verify an update:

```sh
git diff -- "$DOTFILES_REPO/nix/flake.lock"
nix flake check "$DOTFILES_REPO/nix"

activation="$(
  nix build --no-link --print-out-paths \
    "$DOTFILES_REPO/nix#homeConfigurations.$HOST.activationPackage"
)"

HOME_MANAGER_BACKUP_EXT=hm-bak "$activation/activate"
bash "$DOTFILES_REPO/nix/test/verify.sh"
```

Commit `nix/flake.lock` so other devices use the exact same revisions. On
another device, pull the repository and apply it; do not update the lockfile
again unless you intentionally want newer revisions.

### Try a newer package without installing it

```sh
nix shell nixpkgs#jq
jq --version
exit
```

Or run it once:

```sh
nix run nixpkgs#cowsay -- "hello"
```

These commands do not change the Home Manager configuration or generation.

## Add or remove a permanent package

Search nixpkgs:

```sh
nix search nixpkgs ripgrep
```

Edit `nix/home/packages.nix`, then:

```sh
nix flake check "$DOTFILES_REPO/nix"
dotfiles-bootstrap
```

Avoid `nix profile install` for permanent tools: it creates imperative state
outside this repository's declarative package list.

### diffnav version pin

`.config/mise/config.toml` pins `diffnav = "0.11.0"` because 0.12.0 is broken.
This can be removed once upstream fixes land.

## Temporary environments

Open a shell containing temporary packages:

```sh
nix shell nixpkgs#jq nixpkgs#curl
```

Run a package once:

```sh
nix run nixpkgs#cowsay -- "hello"
```

## Inspect and diagnose

```sh
nix --version
nix flake show "$DOTFILES_REPO/nix"
nix flake metadata "$DOTFILES_REPO/nix"
nix flake check "$DOTFILES_REPO/nix"
```

Build with detailed logs and traces:

```sh
nix build -L --show-trace --no-link \
  "$DOTFILES_REPO/nix#homeConfigurations.$HOST.activationPackage"
```

Inspect the active generation:

```sh
readlink -f "$HOME/.local/state/home-manager/gcroots/current-home"
home-manager generations
```

Inspect closure size:

```sh
nix path-info -Sh \
  "$DOTFILES_REPO/nix#homeConfigurations.$HOST.activationPackage"
```

Check who owns the command currently being executed:

```sh
type -P mise
readlink -f "$(type -P mise)"
```

## Roll back

List generations:

```sh
home-manager generations
```

Activate the desired generation path shown in that output:

```sh
/nix/store/<hash>-home-manager-generation/activate
```

If shell startup is broken, enter a clean shell first:

```sh
/usr/bin/bash --noprofile --norc
```

Then activate the previous generation by its full store path.

## Clean old generations and store objects

Expire Home Manager generations older than 30 days:

```sh
home-manager expire-generations "-30 days"
```

Preview and then collect unreferenced Nix store objects:

```sh
nix store gc --dry-run
nix store gc
```

Avoid casually using `nix-collect-garbage -d`; it can remove rollback targets
more aggressively than intended.

## Other package managers: brief caveats

- **mise tools:** use `mise self-update`, `mise install`, `mise upgrade`, or `mise upgrade <tool>`.
  Synced tools live in `.config/mise/config.toml`; device-only tools go in
  `overrides/mise/config.toml` (see [machine-overrides.md](./machine-overrides.md)).
- **Homebrew:** use `brew update && brew upgrade`. Synced exceptions live in
  `Brewfile`; device-only formulae go in `overrides/brew/Brewfile.local`.
  Reconcile with `bash "$DOTFILES_REPO/scripts/brew-bundle"` (install) or
  `bash "$DOTFILES_REPO/scripts/brew-bundle" cleanup --force` (drop undeclared leaves).
- **Application self-updaters:** do not self-update Nix-owned applications.
  Advance `nixpkgs`, build, and activate instead.
- **Arch:** `sudo pacman -Syu` remains a separate operating-system update; Home
  Manager does not run it.

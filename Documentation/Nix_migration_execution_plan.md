# Nix Migration Execution Plan

## Goal

Activate the Nix/Home Manager migration on Arch WSL while retaining a tested,
configuration-level rollback path.

## Known state

- `main` rollback revision: `9ab1278`
- Migration branch revision: `08fecf37`, already published to `origin`
- Home Manager has not been activated on the live WSL distro yet.
- Arch and Ubuntu container activation previously passed.
- A root `mise.toml` is currently untracked and duplicates Nix ownership of
  `diffnav` and `neovim`.
- `nix/flake.lock` was generated during preflight inspection and is currently
  uncommitted. Review it before retaining it.
- Mutating Jujutsu commands require the user's express approval.

## Execution steps

### 1. Preserve the rollback point

- Confirm `main` remains at `9ab1278` locally and on `origin`.
- Create and publish a `rollback/pre-nix-migration` bookmark at `9ab1278`.
- Ask for express approval before Jujutsu bookmark, commit, squash, working-copy
  movement, or push operations.

### 2. Resolve ownership and reproducibility gaps

- Include the root `mise.toml` in the pre-migration snapshot, then remove it;
  Nix should own `diffnav` and `neovim`.
- Review and retain `nix/flake.lock` so all migration inputs are pinned.
- Re-run all checks against the retained lockfile.

### 3. Harden bootstrap

- Ensure `nix-command` and `flakes` work without relying on ambient shell
  configuration, either by configuring them persistently or passing explicit
  feature flags during bootstrap.
- Use the Home Manager input pinned by `nix/flake.lock`; do not invoke the
  floating `home-manager/master` reference.
- Remove `|| true` from final verification so failed checks make bootstrap fail.
- Print clear recovery instructions if activation or verification fails.

### 4. Add rollback tooling

Add:

- `nix/migration/preflight.sh`
- `nix/migration/rollback.sh`
- `Documentation/Nix_migration_runbook.md`

Preflight must create a timestamped directory under
`~/.local/state/dotfiles-migration/` and record:

- `main` and migration commit IDs
- Existing managed paths, their types, and symlink targets
- Copies of files or links that Home Manager may displace
- Current Nix profile target and generations
- Explicit Pacman package inventory
- Homebrew leaves and Brewfile state
- mise tool inventory and the root `mise.toml`
- An independent clean checkout or archive of revision `9ab1278`

Rollback must:

1. Run from a clean Bash process that does not source migrated shell files.
2. Uninstall the first Home Manager generation or deactivate its managed links.
3. Restore the prior Nix profile target.
4. Restore the checkout to the recorded `main` revision using the independent
   saved copy.
5. Restore displaced files and original symlinks from the manifest.
6. Restore the root `mise.toml` and verify the original shell can start.

Nix itself and downloaded store paths may remain installed. This plan guarantees
configuration recovery, not a byte-for-byte WSL distro restoration.

### 5. Test migration and recovery

Run:

- `bash -n` on all changed shell scripts
- `git diff --check`
- `nix flake check --no-write-lock-file`
- A full build of `.#homeConfigurations.arch-wsl.activationPackage`
- Locked Ubuntu and Arch container activation tests
- A container rollback test covering:
  - preflight snapshot creation
  - Home Manager activation
  - rollback execution
  - restoration of original links/files
  - restoration of root `mise.toml`
  - clean Bash and Zsh startup after rollback

### 6. Publish safely

- Commit or squash changes only onto the migration branch.
- Push the migration branch and rollback bookmark.
- Confirm local and remote `main` remain at `9ab1278`.
- Confirm the working copy is clean before live activation.

### 7. Activate on live Arch WSL

1. Run the preflight snapshot and inspect its manifest.
2. Build the `arch-wsl` activation package without activating it.
3. Run bootstrap with `SKIP_MISE=1`.
4. Run `nix/test/verify.sh` and require all checks to pass.
5. Start a fresh WSL shell and verify shell startup, PATH, Git/JJ identity,
   Cursor/VS Code server environment, and key CLI tools.
6. Run `mise install` only after Home Manager verification passes.

## Emergency rollback

From Windows PowerShell, start a shell that ignores the migrated startup files:

```powershell
wsl.exe -d archlinux -- /bin/bash --noprofile --norc -c 'bash ~/.local/state/dotfiles-migration/latest/rollback.sh'
```

The rollback script must also print and store this exact command during
preflight.

## Acceptance criteria

- Migration and rollback tests pass in clean Arch and Ubuntu containers.
- `main`, the migration branch, and the rollback bookmark are remotely
  recoverable.
- Live Home Manager verification passes from a fresh WSL shell.
- Homebrew owns `httpstat`; Nix owns `diffnav` and `neovim`.
- The emergency command restores the pre-migration shell configuration and
  managed links.

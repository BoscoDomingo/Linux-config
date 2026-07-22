# Experiment: WSL IDE-server PATH for extension hosts

Status: **open — awaiting a test on a real WSL + Cursor/VS Code machine.**

## The problem

On WSL, Cursor and VS Code run a "server" (`cursor-server` / `code-server`) that
is launched by `wsl.exe` from the Windows side. The server spawns the extension
hosts (formatters, linters, language servers). That server process is **not**
started through a login shell, so it never sources `.profile` / `.zprofile` —
which means the PATH additions those files make (Nix profile, mise shims,
`~/.local/bin`, …) are invisible to the extension hosts. Tools like `node`,
`biome`, `rg`, `jj` then fail to resolve inside the IDE even though they work
fine in an interactive terminal.

On a non-WSL Linux box this doesn't happen: the editors resolve the extension
host environment by running the user's login shell and snapshotting its env, so
`.profile` PATH setup "just works" and no hook is needed.

## The intended fix: `server-env-setup`

Cursor/VS Code servers are supposed to source `~/.cursor-server/server-env-setup`
(and `~/.vscode-server/server-env-setup`) on startup — a PATH-only script that
gives the extension hosts the tools they need without interactive shell setup.

- Source file: [`../vscode/server-env-setup`](../vscode/server-env-setup)
- Symlinked into place by the WSL host [`../nix/hosts/arch-wsl.nix`](../nix/hosts/arch-wsl.nix)
  (`.cursor-server/server-env-setup`, `.vscode-server/server-env-setup`) — WSL
  only, so the bare-metal `arch` host doesn't create them.

It prepends linuxbrew, the **Nix profile** (`~/.nix-profile/bin`), `~/.local/bin`,
mise shims, pnpm, and opencode to PATH, then dedupes.

## History (why there's doubt it works)

The retired `Setup/installers/symlinks.sh` did **two** things for this: it
symlinked `server-env-setup` **and** patched the server launcher binaries (with
`awk`, idempotently, guarded by a `DOTFILES_IDE_SERVER_ENV_SETUP` marker) to
force them to source it. Its own comment said:

> Cursor and VS Code can ignore `server-env-setup` here, so patch server
> launchers to source it.

The repo owner confirms (as of ~2026-05) that **both** Cursor and VS Code were
ignoring the plain `server-env-setup` file, which is why the binary patch
existed. The patch was deliberately **dropped** during the `run.sh` retirement
because mutating vendored binaries on every server update is fragile (leaves
`.bak` files, re-runs on each IDE update, imperative). We want to know whether
the plain symlink is enough on current IDE versions before reintroducing any
workaround. The owner's expectation is that the failure is **systemic**
(architectural, per "The problem" above), so it likely still fails — but this
has not been re-tested on current builds.

## The test to run

On a WSL machine with Cursor and/or VS Code:

1. Apply the branch: `HOST=arch-wsl bash ~/dotfiles/nix/bootstrap.sh`
   (or `HOST=ubuntu`). Confirm the symlinks resolve into the repo:
   `ls -l ~/.cursor-server/server-env-setup ~/.vscode-server/server-env-setup`.
2. **Kill the server** so it restarts and re-reads the file — a running server
   will not pick it up. Command Palette → *"WSL: Kill VS Code Server for WSL"*,
   or from WSL: `pkill -f cursor-server; pkill -f vscode-server`. Then reconnect.
3. Check whether the extension host got the PATH:
   - **Direct:** Command Palette → *"Developer: Toggle Developer Tools"* →
     Console → `process.env.PATH`. Success = it contains `~/.nix-profile/bin`
     and `~/.local/share/mise/shims`.
   - **Practical:** open a project whose formatter/LSP needs a tool (Biome, a
     node-based LSP) and see whether it runs or errors with "command not found".

## Decision tree

- ✅ Nix/mise paths present / formatter works → the hook is honored now; the
  binary patch was legacy. Done — nothing more to add.
- ❌ Still missing → confirmed systemic. Reintroduce a workaround, but evaluate
  options first (below) rather than defaulting to the binary patch.

## Fallback options if the symlink is ignored

1. **Binary patch (the old approach).** Patch `cursor-server` / `code-server`
   launchers to source `server-env-setup`. Works, but fragile: re-patches after
   every server update, mutates vendored binaries, leaves `.bak` files. If
   revived, it belongs in a standalone script invoked by a best-effort
   `home.activation` step in `nix/home/tools.nix` (not inline in the `.nix`),
   mirroring the `engram-setup` pattern. The original `awk` logic is in git
   history (`Setup/installers/symlinks.sh`) and was briefly present in this
   branch as `scripts/patch-ide-servers` (removed) — recover from git log.
2. **Cleaner hook, if one exists now.** Investigate whether current
   Cursor/VS Code expose a supported WSL env hook that didn't exist when the
   patch was written (the WSL server env resolution has changed over time).
   Prefer this over patching binaries. Check `code`/`cursor` remote-server
   docs and release notes before committing to an approach.
3. **Editor setting.** `terminal.integrated.env.linux` only affects integrated
   terminals, not extension hosts, so it does **not** solve this on its own —
   noted here so nobody wastes time on it.

## Open question (unrelated but adjacent)

`vscode/server-env-setup` still pins `~/.local/share/mise/installs/jj/latest`
"ahead of mise shims". `jj` is now Nix-owned (in
[`../nix/home/packages.nix`](../nix/home/packages.nix)), so that mise path won't
exist post-migration and `jj` resolves from `~/.nix-profile/bin`. The pin is
harmless (guarded by `[ -d ]`, no-ops when absent) but is dead weight. Leave or
drop — undecided.

## Relevant paths

- [`../vscode/server-env-setup`](../vscode/server-env-setup) — the PATH script
- [`../nix/hosts/arch-wsl.nix`](../nix/hosts/arch-wsl.nix) — symlinks it into place (WSL host only)
- [`../vscode/README.md`](../vscode/README.md) — editor settings sync notes
- Git history: `Setup/installers/symlinks.sh` (the original patch), commits on
  branch `claude/dotfiles-nix-exploration-b4ot2i`.

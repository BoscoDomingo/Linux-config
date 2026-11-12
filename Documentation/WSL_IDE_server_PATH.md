# WSL IDE-server PATH for extension hosts

On WSL, Cursor and VS Code launch their server (`cursor-server` / `code-server`)
via `wsl.exe`. That process is not a login shell, so it never sources `.profile`
and never gets Nix, mise, or `~/.local/bin` on `PATH`. Extension hosts then
fail to find tools that work in an interactive terminal.

Bare-metal Linux does not have this gap: the editor snapshots the login-shell
environment for extension hosts.

## Fix

[`../vscode/server-env-setup`](../vscode/server-env-setup) is a PATH-only script.
The WSL host module [`../nix/hosts/arch-wsl.nix`](../nix/hosts/arch-wsl.nix)
symlinks it to:

- `~/.cursor-server/server-env-setup`
- `~/.vscode-server/server-env-setup`

The bare-metal `arch` host does not create these links.

The script prepends linuxbrew, `~/.local/bin`, mise shims, and pnpm, then puts
`~/.nix-profile/bin` first and dedupes so Nix wins over stale mise paths.

Verified for Cursor on Arch WSL. Plain `server-env-setup` is enough; do not
patch server launcher binaries.

`terminal.integrated.env.linux` affects only the integrated terminal, not
extension hosts.

## After PATH changes

1. Confirm the symlinks:
   `ls -l ~/.cursor-server/server-env-setup ~/.vscode-server/server-env-setup`
2. Kill and reconnect the WSL server (Command Palette → *WSL: Kill VS Code
   Server for WSL*, or `pkill -f cursor-server; pkill -f vscode-server`).
3. Check extension-host `PATH` (Developer Tools → Console → `process.env.PATH`)
   or run a formatter/LSP that needs a tool on `PATH`.

A full restart of the Windows Cursor process may be needed if a cached
login-shell env still prefers old mise paths. Confirm with
`readlink -f "$(command -v <tool>)"`.

## Related

- [`../vscode/README.md`](../vscode/README.md) — editor settings sync
- [`Nix_exploration.md`](Nix_exploration.md) — WSL host ownership note

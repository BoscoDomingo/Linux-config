This is a repo that contains dotfiles for Linux-like systems.

First-time setup and any subsequent updates should be done by running the `run.sh` script (which may be called from the distro-specific setup script on the first run, e.g. `Arch/run_arch.sh`). It should be an idempotent operation.

Any time a dotfiles-managed modification is made, ensure `run.sh` and the distro-specific setup scripts are updated to reflect the changes.

Do not assume every fix discovered while working in this repo should be added to the dotfiles. When scope is ambiguous, clarify first whether the user wants a current-device-only fix or a reusable dotfiles change.

For debugging requests phrased as investigation, diagnose first and report the root cause plus fix options. Ask before applying changes unless the user explicitly asks to fix, apply, or implement.

Shell config is layered: `.profile` has non-interactive env/PATH setup (sourced by login shells), `.shellrc` has common interactive config (aliases, agent detection, utility functions), and `.zshrc`/`.bashrc` have shell-specific interactive config. Agent sessions (Cursor, Claude Code, OpenCode) get only `.profile` + tool activation (direnv, mise) -- no aliases, completions, prompt, or tmux.

When making changes to these files, add a comment with a brief explanation why.

Agent-specific dotfiles are kept in `AI/` to avoid them being interpreted automatically when opening this repository.
If tools store their config in `$XDG_CONFIG_HOME/`, they can be kept in `.config/` to preserve consistency with other dotfiles.
This also means that root-level `.agents/`, `.claude/`, `.cursor/`, and similar other directories in this repo are specific to it, and may contain Skills, Rules and other assets that are not meant to be used system-wide.

If using mise-installed tools, prefer using the `latest` tag instead of a specific version unless a specific version is required, in which case, use the most specific path (i.e. `/1.0.1/` instead of `/1/` or `/1.0/`).

Always verify symlinks are correct to ensure any changes to files here are applied. Since I also use WSL in some cases, issues may arise from the Windows side of things, so check that too (especially for Cursor, VS Code, and other such tools I will have installed on Windows but have WSL support).

## Note on contributing to this repo

All commits must be performed using personal email, never anything else. Signature can be done with any key as long as it is added to GitHub profile.
```sh
git config --local user.email "boscodomingob@gmail.com"
git config --local user.name "Bosco Domingo"

jj config set --repo user.email "boscodomingob@gmail.com"
jj config set --repo user.name "Bosco Domingo"
```

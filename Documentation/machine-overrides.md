# Machine-local overrides

Synced baselines stay committed (personal git/jj identity, shared Brewfile,
shared mise tools). Per-machine extras live in one gitignored tree at the
repo root so you can edit them next to the rest of the dotfiles:

```text
overrides/
  git/
    local.gitconfig      # machine default identity
    work.gitconfig       # ~/repos/**
    personal.gitconfig   # ~/dotfiles/**, ~/personal/** and ~/repos/personal/**
  jj/
    local.toml           # machine default (no --when)
    work.toml            # --when.repositories = ["~/repos"]
    personal.toml        # --when.repositories = ["~/dotfiles", "~/personal"]
    zz-repos-personal.toml  # --when.repositories = ["~/repos/personal"]; sorts after work.toml
  mise/
    config.toml          # device-only tools (merged by mise)
  brew/
    Brewfile.local       # device-only formulae/casks
  patches/
    enabled              # selected bare-metal Arch system patches
  activation/
    disabled             # Home Manager activation steps to skip
  vars.env               # KEY=value settings read by activation steps
```

`/overrides/` is gitignored. Home Manager / bootstrap create the directories and
the small symlinks tools expect outside the checkout. Missing files are fine:
personal machines need zero of these.

## Secrets vs overrides

| Tier                               | Example                           | Where                            | Committed?        |
|------------------------------------|-----------------------------------|----------------------------------|-------------------|
| 1. True secret                     | SSH **private** key               | `~/.ssh/`                        | **Never**         |
| 2. Per-machine identity / packages | work email, extra brew/mise tools | `overrides/`                     | No                |
| 3. Encrypted-at-rest               | API tokens                        | `~/.profile_secret`, or sops/age | Only if encrypted |

`.ssh/allowed_signers` holds public keys only and stays committed.
`scripts/ssh-sign` reads `SSH_SIGN_KEY_PATH` for the private key path.

## How each tool loads `overrides/`

| Tool         | Synced baseline            | Override path                   | Mechanism                                                     |
|--------------|----------------------------|---------------------------------|---------------------------------------------------------------|
| **git**      | `.gitconfig`               | `overrides/git/*.gitconfig`     | `[include]` / `[includeIf]` with `~/dotfiles/overrides/git/…` |
| **jj**       | `.config/jj/config.toml`   | `overrides/jj/*.toml`           | `~/.config/jj/conf.d` → symlink to `overrides/jj`             |
| **mise**     | `.config/mise/config.toml` | `overrides/mise/config.toml`    | `~/.mise/config.toml` → symlink to that file                  |
| **Homebrew** | `Brewfile`                 | `overrides/brew/Brewfile.local` | `scripts/brew-bundle` concatenates both                       |
| **Arch patches** | `Arch/patches/`        | `overrides/patches/enabled`     | Bootstrap installs selected patches and pacman hooks          |
| **Activation steps** | `nix/home/tools.nix` | `overrides/activation/disabled` | Each step skips itself when its key is listed               |
| **Activation vars** | `nix/home/tools.nix` | `overrides/vars.env`          | Steps read their keys with `override_var KEY DEFAULT`         |

Later git includes win, so personal path files beat `local` / `work` when both
match. jj `conf.d` files load lexicographically after the synced config.toml,
and the last matching file wins.

### Personal repos under `~/repos/personal`

`~/repos/**` gets the work identity, and `~/repos/personal/` is inside it. Both
tools need a personal rule that comes **after** the work rule:

- **git:** the committed `.gitconfig` has `includeIf "gitdir:~/repos/personal/"`
  after the `~/repos/` include. It uses `overrides/git/personal.gitconfig`, so
  that file must exist on work machines.
- **jj:** a rule in `personal.toml` does not work, because `work.toml` loads
  after it. Copy `overrides/jj/zz-repos-personal.toml.example` to
  `overrides/jj/zz-repos-personal.toml`. The `zz-` prefix makes it load last.

## Examples

Machine default (work laptop) — `overrides/git/local.gitconfig`:

```gitconfig
[user]
    email = you@work.example
    signingKey = key::ssh-ed25519 AAAA…work-key…
```

```toml
# overrides/jj/local.toml
[user]
email = "you@work.example"
```

Path-scoped jj (optional):

```toml
# overrides/jj/work.toml
--when.repositories = ["~/repos"]

[user]
email = "you@work.example"
```

```toml
# overrides/jj/personal.toml
--when.repositories = ["~/dotfiles", "~/personal"]

[user]
email = "you@personal.example"
```

```toml
# overrides/jj/zz-repos-personal.toml (loads after work.toml)
--when.repositories = ["~/repos/personal"]

[user]
email = "you@personal.example"
```

mise device-only tools — `overrides/mise/config.toml`:

```toml
[tools]
# just = "latest"
# kubectl = "latest"
```

Homebrew device-only — `overrides/brew/Brewfile.local`:

```ruby
# cask "copilot-cli"
```

Arch system patches are reusable files committed under `Arch/patches/`. Enable
one patch per line in `overrides/patches/enabled`:

```text
plasma-lockscreen-fast-retry
```

`nix/bootstrap.sh` installs each selected patch and its pacman hook. The hook
reapplies the patch after the owning package is updated. If upstream code no
longer matches, the helper leaves it unchanged and prints a warning. To disable
a patch, remove its line and run bootstrap again. The helper removes only the
expected patched code and then removes its hook.

## Skip activation steps on one machine

Each step in `nix/home/tools.nix` (except `machineOverrides`) has an opt-out
key. The step runs only when its key is not listed in
`overrides/activation/disabled`. Write one key per line. Other lines, such as
comments, are ignored:

```text
# Keep the AI-agent jj approval guards off on this machine.
agent_guards
```

| Key                     | Step                                           |
|-------------------------|------------------------------------------------|
| `oh_my_zsh`             | Clone oh-my-zsh                                |
| `tpm`                   | Clone the tmux plugin manager                  |
| `cheat_sheets`          | Clone the community cheatsheets                |
| `micro_themes`          | Download the micro colour schemes              |
| `opencode`              | Install OpenCode                               |
| `agent_guards`          | Install the AI-agent jj approval guards        |
| `copilot_sandbox_herdr` | Merge the herdr paths into the Copilot sandbox |
| `utils_skills`          | Clone, update and link the `utils` skills      |

The check runs during activation, so the next `home-manager switch` uses the
change. To enable a step again, remove its line and switch again. Skipping a
step does not undo what it installed earlier. For example, after you add
`agent_guards`, remove its hooks and policy blocks from the agent configs by
hand.

`agent_guards` also turns off the OpenCode jj rules. These rules are in the
repo-managed `opencode.json`, so `.profile` sets `OPENCODE_CONFIG` to
`AI/agent-guards/opencode-disabled.json`. OpenCode merges that file, which
allows `jj *`. Start a new login shell for the change to apply. When you
remove the key, `.profile` also clears an inherited `OPENCODE_CONFIG` that
points to this file.

When you add a step to `tools.nix`, wrap its body with
`optional "<snake_case_key>"`, then add the key to this table.

## Per-machine variables

`overrides/vars.env` holds settings for activation steps, one `KEY=value` per
line (copy `overrides/vars.env.example`). Lines that start with `#` are
comments. If a key occurs more than once, the last line wins. Double quotes
around a value are optional, and a leading `~` means `$HOME`. Home Manager
parses the file; it does not source it as shell.

| Key         | Default          | Used by        | Meaning                              |
|-------------|------------------|----------------|--------------------------------------|
| `UTILS_DIR` | `~/repos/utils`  | `utils_skills` | Clone path for BoscoDomingo/utils    |

To read a new key in a step, add `${overrideVarFn}` to the step body, then
use `"$(override_var KEY DEFAULT)"`. Add the key to this table.

## Personal skills from `utils`

The `utils_skills` step clones
[BoscoDomingo/utils](https://github.com/BoscoDomingo/utils) and links the
skills listed in `utilsSkills` (`nix/home/tools.nix`) into `~/.agents/skills/`.
The clone goes to `~/repos/utils`. On a work machine, keep it apart from work
repos with `UTILS_DIR` in `overrides/vars.env`:

```sh
UTILS_DIR=~/repos/personal/utils
```

Each switch fetches the clone and moves it to `main@origin`. It moves the clone
only when the working-copy change is empty and has no description, and all other
changes are already on `main@origin`. If you have local work there, the step
prints a note and does not change the clone.

A new clone uses HTTPS and ignores the global git config for the clone only,
so the `url.insteadOf` rule in `.gitconfig` cannot turn it into SSH before you
have SSH keys. Later fetches and pushes go through that rule and use SSH. A
fetch that fails (no keys yet) only prints a note.

The step also writes the baseline identity from `.gitconfig` (`user.name`,
`user.email`) into the new clone's jj repo config and `.git/config`. So commits
from the clone use the personal email even if the path rules above would give
the work one (for example, `~/repos/utils` with the default `UTILS_DIR`). The
step does not change the identity of a clone that already exists.

If you change the path, the next switch clones to the new path and points the
links there. It does not delete the old clone.

Tests: `bash nix/test/utils-skills-test.sh` runs the step offline against a
fixture repo; `nix/test/verify.sh` checks the live clone and links.

## First-time setup on a work machine

```sh
mkdir -p ~/dotfiles/overrides/{git,jj,mise,brew,patches,activation}
# write the files above, then:
bash ~/dotfiles/nix/bootstrap.sh   # refreshes symlinks + brew bundle
mise install                       # if you added mise tools
```

Or copy the stubs under `Documentation/examples/`.

## Nix note

`nix/home/git.nix` is an opt-in alternative that owns git config in Home
Manager instead of the symlinked `.gitconfig`. If you enable it, drop the
`.gitconfig` symlink from `dotfiles.nix` and keep the same `overrides/git/`
paths in `programs.git.includes`.

# Machine-local overrides

Synced baselines stay committed (personal git/jj identity, shared Brewfile,
shared mise tools). Per-machine extras live in one gitignored tree at the
repo root so you can edit them next to the rest of the dotfiles:

```text
overrides/
  git/
    local.gitconfig      # machine default identity
    work.gitconfig       # ~/repos/**
    personal.gitconfig   # ~/dotfiles/** and ~/personal/**
  jj/
    local.toml           # machine default (no --when)
    work.toml            # --when.repositories = ["~/repos"]
    personal.toml        # --when.repositories = ["~/dotfiles", "~/personal"]
  mise/
    config.toml          # device-only tools (merged by mise)
  brew/
    Brewfile.local       # device-only formulae/casks
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

Later git includes win, so personal path files beat `local` / `work` when both
match. jj `conf.d` files load lexicographically after the synced config.toml.

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

mise device-only tools — `overrides/mise/config.toml`:

```toml
[tools]
# just = "latest"
# kubectl = "latest"
```

Homebrew device-only — `overrides/brew/Brewfile.local`:

```ruby
# cask "copilot-cli"
# brew "plantuml"
```

## First-time setup on a work machine

```sh
mkdir -p ~/dotfiles/overrides/{git,jj,mise,brew}
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

# Nix setup: rationale and ownership

> Status: **implemented**. Setup lives under [`nix/`](../nix/). This document
> records why Nix was chosen, how it compares to the alternatives, and which
> system owns each class of tool.

Daily commands: [`Nix_cheatsheet.md`](Nix_cheatsheet.md).
Per-machine identity and secrets: [`machine-overrides.md`](machine-overrides.md).

## 1. The problem

The old imperative path (`run.sh` and per-distro installers) failed at portability:

| # | Pain point                                        | Why it hurts syncing                                  |
|---|---------------------------------------------------|-------------------------------------------------------|
| 1 | Interactive, unreliable installer                 | Cannot run unattended                                 |
| 2 | No single source of truth for "what is installed" | Intent split across bash, TOML, and `curl` installers |
| 3 | No atomicity or rollback                          | A mid-run failure leaves a half-configured machine    |
| 4 | No drift detection                                | Nothing shows that two machines diverge from the repo |
| 5 | Non-idempotent `curl \| bash` steps               | Re-runs are unsafe; versions float                    |
| 6 | Bespoke symlink logic                             | Edge cases are local code to maintain                 |

## 2. What "robust" requires

In priority order for this setup:

1. **Declarative** — one description of desired state; the tool makes the machine match it. (#2, #4)
2. **Idempotent and unattended** — run twice equals run once; no prompts. (#1, #5)
3. **Reproducible** — same inputs produce the same machine, including versions. (strong form of #4)
4. **Reversible** — a bad change rolls back atomically. (kills #3)

Dotfile managers give 1–2 for config files. Nix is the mainstream option
that gives all four for both config files and the package/toolchain layer.

## 3. Alternatives

### 3.1 GNU Stow — symlink farm only

Replaces bespoke symlink helpers with package-oriented link conventions.

- Solves symlink maintenance (#6).
- Does nothing for packages, versions, idempotent installs, or rollback (#1–#5).

**Verdict:** a tidy-up, not a solution. Only worth it if Nix/chezmoi are too
much and the only goal is to delete custom symlink code.

### 3.2 chezmoi — serious dotfile manager

Single `chezmoi apply`, cross-platform. Stronger than Stow for this repo:

- Templating and machine-specific data for OS/host divergence.
- First-class secrets integration (age, gpg, 1Password, Bitwarden, …).
- `run_` scripts can drive brew/mise/apt installs.

- Solves #1, #2 (for configs), #4, #6.
- Package installs stay imperative under `run_` scripts, so version
  reproducibility (#3) and #5 are only partial.
- No atomic whole-system rollback.

**Verdict:** the pragmatic 80/20. Biggest robustness gain for the least new
concepts if Nix's learning cost is not worth it.

### 3.3 Ansible — idempotent config management

Playbooks describe tasks; modules are idempotent; works on Linux/macOS.

- Idempotent, unattended, one source of truth for packages and files.
- Verbose; no true rollback; version pinning is manual; heavy for one person's
  laptops.

**Verdict:** possible, but the enterprise answer to a personal-laptop question.
Not recommended here.

### 3.4 Nix — Home Manager + flakes (+ nix-darwin)

The only option that delivers all four robustness properties for the whole
user environment.

- **Nix + flakes** — hash-locked inputs (`flake.lock`). Same package versions
  on every machine until you choose to update.
- **Home Manager** — user environment on Linux or macOS: dotfiles, CLI
  packages, shell config, services. Replaces bespoke symlink and package
  installers.
- **nix-darwin** *(optional, macOS)* — system defaults and Homebrew casks Nix
  cannot build cleanly.
- **Nix on WSL** — Home Manager in the existing distro, or optionally NixOS-WSL.

Scores:

- Declarative, idempotent, version-pinned, and atomically reversible
  (`home-manager` generations / `--rollback`). Addresses #1–#6.
- One flake is the source of truth for packages, dotfiles, and versions across
  Arch, Ubuntu, macOS, and WSL.
- Learning curve is real (Nix language, flakes, Home Manager).
- Value comes from owning package management; coexistence with mise/Homebrew
  needs a clear ownership rule (see §5).

**Verdict:** maximal robustness, and viable for this multi-OS setup. The open
question was only whether reproducibility and rollback justified the learning
curve.

### 3.5 Scorecard

|                                      |  Stow   |   chezmoi   | Ansible |    **Nix + HM**     |
|--------------------------------------|:-------:|:-----------:|:-------:|:-------------------:|
| Declarative configs                  |    ✅    |      ✅      |    ✅    |          ✅          |
| Declarative packages                 |    ❌    | ⚠️ (scripts) |    ✅    |          ✅          |
| Idempotent / unattended              |    ❌    |      ✅      |    ✅    |          ✅          |
| **Version reproducibility**          |    ❌    |      ❌      |    ⚠️    |          ✅          |
| **Atomic rollback**                  |    ❌    |      ❌      |    ❌    |          ✅          |
| Secrets handling                     |    ❌    |      ✅      |    ✅    | ✅ (sops-nix/agenix) |
| Drift detection                      |    ❌    |      ✅      |    ⚠️    |          ✅          |
| Cross-platform (Arch/Ubuntu/mac/WSL) |    ✅    |      ✅      |    ✅    |          ✅          |
| Learning curve                       | trivial |     low     | medium  |      **high**       |
| Keeps prior workflow                 | mostly  |   mostly    |   no    |       rewrite       |

## 4. Decision

**Chosen:** Nix (Home Manager + flakes), adopted gradually rather than as a
big-bang rewrite.

Home Manager can symlink existing repo files with `mkOutOfStoreSymlink`, so
dotfiles stay editable in this checkout. That property made a gradual migration
practical.

**Fallback if reconsidering:** chezmoi. It delivers unattended, declarative,
drift-detected, secret-aware dotfiles with a lower learning cost. It does not
deliver Nix-grade version reproducibility or atomic rollback.

**Keep mise** for language runtimes and other tools that should float outside
the Nix lock. Nix owns the stable global CLI toolbox.

## 5. Design rules

### 5.1 Tool ownership

The old `run.sh` / `Setup/` installers are gone. Distro scripts install host
prerequisites, clone the repo, and hand off to `nix/bootstrap.sh`, which
installs Nix and activates the generation pinned by `flake.lock`. Activation
hooks in `home/tools.nix` are best-effort so a network hiccup does not brick a
switch.

Each responsibility has one owner. Nothing is installed by more than one system.

| System                 | Owns                                                   | Examples         |
|------------------------|--------------------------------------------------------|------------------|
| **Nix / Home Manager** | Stable global CLI tools; dotfile symlinks              | rg, jj, neovim   |
| **mise**               | Language runtimes + explicitly declared floating tools | go, rust         |
| **Homebrew**           | Tools whose Nix/mise packages are unsuitable           | engram, httpstat |
| **Upstream installer** | Tools that shouldn't be self-managed                   | mise, opencode   |

Per-machine extras (not synced) use the gitignored `overrides/` tree — see
[machine-overrides.md](./machine-overrides.md):

| Layer        | Synced baseline            | Untracked overlay               |
|--------------|----------------------------|---------------------------------|
| **git**      | `.gitconfig`               | `overrides/git/*.gitconfig`     |
| **jj**       | `.config/jj/config.toml`   | `overrides/jj/*.toml`           |
| **Homebrew** | `Brewfile`                 | `overrides/brew/Brewfile.local` |
| **mise**     | `.config/mise/config.toml` | `overrides/mise/config.toml`    |

`scripts/brew-bundle` (from `bootstrap.sh`) concatenates the Brewfile and
optional local overlay, then runs `brew bundle`. Mise merges
`~/.mise/config.toml` (symlinked to `overrides/mise/config.toml`) on top of the
synced global config.

#### 5.1.1 Bun / opencode

`opencode` is the one tool installed from its vendor's own script. The nixpkgs
package is a Bun standalone compiled by a bun that `autoPatchelfHook` has
rewritten; the shifted ELF offsets make the result segfault inside `ld-linux`
before any application code runs, so on WSL2 the command exits 139 with no
output ([NixOS/nixpkgs#520383](https://github.com/nixos/nixpkgs/issues/520383),
fixed upstream by [oven-sh/bun#31024](https://github.com/oven-sh/bun/pull/31024)).

`home/tools.nix` therefore runs `https://opencode.ai/install` with
`--no-modify-path`, which puts the upstream binary in `~/.opencode/bin`. The
`--no-modify-path` flag matters: without it the installer appends `export PATH=`
lines to `.zshrc`, which is a symlink into this repo. `.profile` adds
`~/.opencode/bin` after the Nix profile so it wins over any stale Nix-owned copy.
The activation step only runs when the binary is missing, so a switch never
re-downloads 180 MB; upgrades are manual, because the repo config sets
`autoupdate: notify`. Once nixpkgs ships a Bun version that contains the
upstream fix, move opencode back to `packages.nix`.

#### 5.1.2 engram

`engram` is installed via Homebrew; `scripts/engram-setup` (from
`home/tools.nix` and `bootstrap.sh`) registers it with each detected coding
agent. Bootstrap installs Homebrew itself only when `INSTALL_BREW=1`, then runs
the bundle when Homebrew is available.

Registration is unattended: `engram setup` gets stdin from `/dev/null` and a
timeout so it can never stall activation or bootstrap. Agents that engram cannot
register without a keypress (currently `claude-code`, which prompts before it
adds its tools to `permissions.allow` in `~/.claude/settings.json`) are printed
as a reminder to run `engram setup <agent>` by hand.

#### 5.1.3 mise

`mise` is installed from `https://mise.run` rather than nixpkgs, so that
`mise self-update` works.


### 5.2 Dotfiles stay live-editable

`home/dotfiles.nix` uses `mkOutOfStoreSymlink` so Home Manager links into the
repo checkout instead of copying files into `/nix/store`. Edit `.zshrc` (and
peers) in place; `home-manager switch` applies the link set atomically and
removes links it no longer manages.

### 5.3 Native Home Manager modules are optional

Tools with first-class `programs.*` modules can generate config from Nix
instead of a symlinked file. Adopt those opportunistically: import the module
and drop the matching symlink from `dotfiles.nix`. Home Manager refuses to
manage the same path twice. See `home/shell.nix` (not imported by default).

### 5.4 Host modules own OS differences

WSL / macOS / Arch / Ubuntu differences live in `nix/hosts/*.nix`, not in
scattered shell `if` branches. Shared config is `home/common.nix`.

## 6. Risks and downsides

- **Learning curve.** The language and mental model take real time.
- **Disk usage.** `/nix/store` grows; use `nix-collect-garbage` (see the
  cheatsheet).
- **Some tools fight it.** GUI apps, proprietary binaries, and FHS-expecting
  software may need workarounds (`buildFHSEnv`) or stay on brew/apt/standalone
  installers.
- **WSL specifics.** DBus/gnome-keyring and IDE-server environment integration
  belong in the WSL host module and managed `server-env-setup` links. See
  [`WSL_IDE_server_PATH.md`](WSL_IDE_server_PATH.md).

## 7. Where to look

| Need                                     | Location                                       |
|------------------------------------------|------------------------------------------------|
| Flake, hosts, Home Manager modules       | [`nix/`](../nix/)                              |
| Apply / update / rollback / GC           | [`Nix_cheatsheet.md`](Nix_cheatsheet.md)       |
| Work vs personal identity, secrets tiers | [`machine-overrides.md`](machine-overrides.md) |
| Verification record                      | [`nix/test/README.md`](../nix/test/README.md)  |

Apply with `nix/bootstrap.sh`. Host outputs and package lists in `nix/` are the
source of truth for what is installed.

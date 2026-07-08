# Making dotfiles reproducible: Nix vs. the alternatives

> Status: **exploration / proposal**. Nothing in this branch changes how your
> current `run.sh` setup works. The `nix/` directory added alongside this
> document is an inert, ready-to-adapt skeleton — it does nothing until you
> choose to run it. Read this first, then decide.

## 1. The problem, stated precisely

Today the repo is synced across machines with:

- **Bootstrap scripts** per distro (`Arch/run_arch.sh`, `Ubuntu/run_ubuntu.sh`)
  that clone the repo and call `run.sh`.
- **`run.sh`**, which sources five imperative installers
  (`symlinks`, `gpg`, `packages`, `ai-agents`, `tools`).
- **Symlinking** via a home-grown `ensure_link` helper (`Setup/lib/helpers.sh`)
  that backs up existing files to `*.bak`.
- **Packages** spread across four systems: Homebrew (a ~35-entry bash array),
  mise (`.config/mise/config.toml`), pnpm/bun globals, and a handful of
  `curl | bash` installers (oh-my-posh, oh-my-zsh, Homebrew itself, mise).

The README says it plainly: *"You can try running `./run.sh` directly … although
it is untested and will likely not work. Otherwise, just run the commands
manually."* That single sentence is the whole problem. The concrete pain points:

| # | Pain point | Why it hurts syncing |
|---|------------|----------------------|
| 1 | The installer is interactive (`read -p` at every step) and self-described as unreliable | Can't run unattended; a new machine is a babysitting session |
| 2 | No single source of truth for "what is installed" | Package intent lives in a bash array, a TOML file, and several inline `curl` calls |
| 3 | No atomicity or rollback | A failure halfway through leaves a half-configured machine with no clean way back |
| 4 | No drift detection | Nothing tells you machine A and machine B have diverged, or that a machine matches the repo |
| 5 | Non-idempotent `curl \| bash` steps | Re-running is not guaranteed safe; versions float |
| 6 | Symlink logic is bespoke and must be maintained | Edge cases (WSL IDE servers, `.bak` collisions) are your code to debug |

"More robust" means fixing as many of 1–6 as the effort is worth. Keep that
table in mind — it's the scorecard every option below is graded against.

## 2. What "robust" actually requires

Four properties, in rough priority order for your setup:

1. **Declarative** — one description of the desired state; the tool makes the
   machine match it. (kills #2, #4)
2. **Idempotent & unattended** — running twice equals running once; no prompts.
   (kills #1, #5)
3. **Reproducible** — same inputs produce the same machine, including *versions*,
   next month and on the next laptop. (the strong form of #4)
4. **Reversible** — a bad change can be rolled back atomically. (kills #3)

Dotfile managers give you 1–2 for *config files*. Nix is currently the only
mainstream option that gives you all four for *both config files and the
packages/toolchain*.

## 3. The options

### 3.1 GNU Stow — symlink farm only

Replaces exactly one thing: `ensure_link`. You reorganise the repo into
"packages" (`stow zsh` symlinks `zsh/.zshrc` → `~/.zshrc`) and Stow manages the
links. ~20 lines of Perl-driven convention instead of your bash.

- ✅ Trivial to learn; solves the symlink-maintenance chore (#6).
- ❌ Does nothing for packages, versions, idempotent installs, or rollback
  (#1–#5 untouched). You'd still keep `run.sh` for everything else.

**Verdict:** a tidy-up, not a solution. Only worth it if you decide Nix/chezmoi
are too much and you just want the symlink code gone.

### 3.2 chezmoi — the serious dotfile manager

Go binary, single `chezmoi apply`, cross-platform. Its real advantages over
Stow are the things your repo already hacks around by hand:

- **Templating**: one `.zshrc` with `{{ if eq .chezmoi.os "darwin" }}` blocks
  instead of branching logic scattered across files. Your WSL/macOS/Arch/Ubuntu
  divergence becomes data-driven.
- **Machine-specific data**: `.chezmoidata` / prompts fill in per-host values.
- **Secrets**: first-class integration with age, gpg, 1Password, Bitwarden —
  a real answer for `.profile_secret`.
- **`run_` scripts**: hashed/once scripts let it *also* drive package installs
  (it can call brew/mise/apt), so it can subsume most of `run.sh`.

- ✅ Solves #1, #2 (for configs), #4 (drift via `chezmoi diff/status`), #6.
- ⚠️ Package installs run through `run_` scripts — better organised than today,
  but still imperative shell underneath, so #3 (version reproducibility) and #5
  are only partially addressed.
- ❌ No atomic rollback of the whole system (#3-reversibility).

**Verdict:** the pragmatic 80/20. Biggest robustness gain for the least new
concepts, and it maps cleanly onto how you already think (files + scripts).

### 3.3 Ansible — imperative-but-idempotent, config-management style

Playbooks (YAML) describe tasks; modules are idempotent; works over
Linux/macOS. Heavier syntax, designed for fleets of servers more than one
person's laptops.

- ✅ Idempotent, unattended, one source of truth, handles packages *and* files.
- ❌ Verbose; no true rollback; version pinning is manual; overkill for a
  personal dotfiles repo. You'd trade bash for YAML and gain less than Nix.

**Verdict:** possible, but it's the enterprise answer to a personal-laptop
question. Not recommended here.

### 3.4 Nix — Home Manager + flakes (+ nix-darwin)

The only option that delivers all four robustness properties for the whole
machine. The relevant pieces:

- **Nix + flakes** — a pinned, hash-locked description of every input
  (`flake.lock`). "Reproducible" in the strong sense: the exact same package
  *versions* on every machine until you choose to `nix flake update`.
- **Home Manager** — manages your user environment on *any* Linux or macOS:
  dotfiles, CLI packages, shell config, services. This is the cross-platform
  workhorse and the piece that would replace both `symlinks.sh` and most of
  `packages.sh`.
- **nix-darwin** *(optional, macOS only)* — manages macOS system defaults
  (Dock, keyboard, Homebrew casks via `nix-homebrew`). Complements your
  `MacOS/` dir.
- **NixOS-WSL** *(optional)* — a full NixOS under WSL, or just install Nix into
  your existing WSL distro and run Home Manager there like any other Linux.

How it scores:

- ✅ Declarative, idempotent, **reproducible with version pinning**, and
  **atomically reversible** — `home-manager switch` builds a new "generation";
  `--rollback` instantly restores the previous one. Kills #1–#6.
- ✅ One `flake.nix` is the single source of truth for packages *and* dotfiles
  *and* their versions, across Arch, Ubuntu, macOS, and WSL.
- ⚠️ **Learning curve is real.** The Nix language is unusual (lazy, functional),
  error messages can be cryptic, and the flakes/Home Manager mental model takes
  a week or two to click.
- ⚠️ **It wants to own package management.** Its value comes from replacing
  `curl | bash`, and ideally Homebrew/mise, with Nix packages. That's the
  migration cost — see §5 for how to do it *gradually* rather than all at once.
- ⚠️ Some tools you use (mise, pnpm/bun global installs) overlap conceptually
  with Nix. They coexist fine (§4.3), but you'll want a clear rule for which
  system owns what.

**Verdict:** the maximal-robustness answer, and genuinely viable for your
cross-platform setup. The question is not *can* Nix do this (it can) but whether
the reproducibility/rollback payoff is worth the learning curve for you.

### 3.5 Scorecard

| | Stow | chezmoi | Ansible | **Nix + HM** |
|---|:---:|:---:|:---:|:---:|
| Declarative configs | ✅ | ✅ | ✅ | ✅ |
| Declarative packages | ❌ | ⚠️ (scripts) | ✅ | ✅ |
| Idempotent / unattended | ❌ | ✅ | ✅ | ✅ |
| **Version reproducibility** | ❌ | ❌ | ⚠️ | ✅ |
| **Atomic rollback** | ❌ | ❌ | ❌ | ✅ |
| Secrets handling | ❌ | ✅ | ✅ | ✅ (sops-nix/agenix) |
| Drift detection | ❌ | ✅ | ⚠️ | ✅ |
| Cross-platform (Arch/Ubuntu/mac/WSL) | ✅ | ✅ | ✅ | ✅ |
| Learning curve | trivial | low | medium | **high** |
| Keeps your current workflow | mostly | mostly | no | rewrite |

## 4. Recommendation

**Two defensible choices, depending on your appetite:**

### Recommended: Nix (Home Manager + flakes), migrated in phases

If your goal is genuinely "robust" in the full sense — reproducible versions and
one-command rollback — Nix is the only option that delivers it, and your
multi-OS setup is squarely in Home Manager's wheelhouse. The catch is the
learning curve, so **do not big-bang it.** Adopt Home Manager for dotfiles first
(where it's basically a better symlink manager), then migrate packages tool by
tool. Details and code in §5–§6.

Crucially, Home Manager can symlink your *existing, unchanged* dotfiles back
into place using `mkOutOfStoreSymlink`, so you keep editing `.zshrc` in this
repo exactly as you do now — you are not forced to rewrite everything into the
Nix language on day one. That property is what makes a gradual migration real
rather than aspirational.

### Pragmatic fallback: chezmoi

If a week of fighting the Nix language sounds worse than the problem it solves,
**chezmoi** gets you unattended, declarative, drift-detected, secret-aware
dotfiles with a fraction of the learning cost — and it can orchestrate your
existing brew/mise installs through `run_` scripts. You lose version
reproducibility and atomic rollback (the two properties only Nix really nails),
but you fix pain points #1, #2, #4, and #6 this weekend.

### Keep mise regardless

Whatever you pick, **keep mise for per-project language/tool versions.** mise +
`.tool-versions`/`mise.toml` + direnv is a better developer workflow than Nix
devshells for polyglot project work, and it composes cleanly with both options
(§4.3). Nix owns the *global, stable* toolbox; mise owns *per-project, floating*
toolchains.

## 5. What the Nix version would look like

A concrete mapping from what you have today to Home Manager, using your real
files. Full runnable skeleton is in [`nix/`](../nix/).

### 5.1 Repository layout

```
nix/
├── flake.nix              # inputs (nixpkgs, home-manager, nix-darwin) + host outputs
├── flake.lock            # pinned versions — the reproducibility guarantee
├── home/
│   ├── common.nix         # everything shared across all machines
│   ├── packages.nix       # the former Homebrew array, as a Nix list
│   ├── shell.nix          # zsh/starship/fzf via Home Manager programs.*
│   └── dotfiles.nix       # symlinks to your existing repo files (out-of-store)
└── hosts/
    ├── arch-wsl.nix       # per-machine overrides
    ├── ubuntu.nix
    └── macbook.nix        # imports nix-darwin for system defaults
```

Your existing `.zshrc`, `.config/*`, `scripts/` etc. **stay exactly where they
are.** Nix references them; it doesn't replace them.

### 5.2 Packages: the bash array becomes a Nix list

Today (`Setup/installers/packages.sh`):

```bash
packages=( gcc cheat bottom eza fd fzf bat ripgrep git-delta fastfetch lazyjj ... )
brew install "${packages[@]}"
```

With Home Manager (`nix/home/packages.nix`) — same intent, but pinned and
cross-platform:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc cheat bottom eza fd fzf bat ripgrep delta fastfetch onefetch
    duf gping hyperfine trippy sshs
    zsh-autosuggestions zsh-fast-syntax-highlighting
    # lazyjj, diffnav → from flake inputs or nixpkgs when available
  ];
}
```

`home-manager switch` installs all of them, at versions locked in `flake.lock`,
identically on every machine. No `read -p`, no "likely won't work".

### 5.3 Dotfiles: `ensure_link` becomes declarative — and stays editable

Your `ensure_link` loop symlinks repo files into `$HOME`. Home Manager does the
same declaratively. To keep files **live-editable in this repo** (not copied
read-only into `/nix/store`), use `mkOutOfStoreSymlink` (`nix/home/dotfiles.nix`):

```nix
{ config, ... }:
let
  repo = "${config.home.homeDirectory}/dotfiles";   # this repo's checkout
  link = config.lib.file.mkOutOfStoreSymlink;
in {
  home.file = {
    ".zshrc".source        = link "${repo}/.zshrc";
    ".profile".source      = link "${repo}/.profile";
    ".shellrc".source      = link "${repo}/.shellrc";
    ".aliases".source      = link "${repo}/.aliases";
    ".gitconfig".source    = link "${repo}/.gitconfig";
  };

  # The .config/*/ loop from symlinks.sh, declaratively:
  xdg.configFile = {
    "starship.toml".source = link "${repo}/.config/starship.toml";
    "ghostty".source       = link "${repo}/.config/ghostty";
    "nvim".source          = link "${repo}/.config/nvim";
    "mise".source          = link "${repo}/.config/mise";
    # … one line per config dir (25 of them today)
  };
}
```

This is a strict upgrade over `ensure_link`: same live-editing workflow, but the
link set is declared in one place, applied atomically, and Home Manager cleans
up links it no longer manages (no more orphaned `.bak` files).

### 5.4 Some tools get *native* Home Manager modules (better than symlinks)

For tools with first-class HM support you can drop the config file entirely and
declare intent — HM generates the config and manages the package together:

```nix
programs.zsh = {
  enable = true;
  oh-my-zsh.enable = true;
  # plugins/aliases as Nix data, or point initExtra at your .shellrc
};
programs.starship.enable = true;
programs.fzf.enable = true;
programs.direnv = { enable = true; nix-direnv.enable = true; };
programs.git.enable = true;   # can import your existing .gitconfig
```

You'd migrate these opportunistically — there's no need to convert all 25
config dirs. Keep the ones you like as-is via §5.3 symlinks; convert the ones
where HM's module adds value.

### 5.5 Per-machine and per-OS differences

The WSL/macOS/Arch/Ubuntu branching currently done in shell becomes host
modules (`nix/hosts/*.nix`):

```nix
# hosts/arch-wsl.nix
{ pkgs, ... }: {
  imports = [ ../home/common.nix ];
  home.packages = with pkgs; [ wslu ];        # wslview etc. for WSL
  # WSL-specific env that .profile currently sets behind an `if`
}
```

```nix
# hosts/macbook.nix  (with nix-darwin for system defaults)
{ pkgs, ... }: {
  imports = [ ../home/common.nix ];
  # nix-darwin: system.defaults.dock.autohide = true;  etc.
  # nix-homebrew: casks Nix can't build (GUI apps)
}
```

### 5.6 Daily workflow, before and after

| Task | Today | With Nix |
|------|-------|----------|
| New machine | run distro script, then babysit `run.sh` prompts | install Nix, `git clone`, `home-manager switch --flake .#macbook` |
| Add a package | edit bash array, re-run installer | add one line to `packages.nix`, `switch` |
| Update everything | `brew upgrade` + `mise up` + re-`curl` | `nix flake update && home-manager switch` |
| A change broke my shell | manually undo, restore `.bak` | `home-manager switch --rollback` |
| "Do my two laptops match?" | hope | identical `flake.lock` guarantees it |

## 6. Migration plan (phased, low-risk)

Each phase is independently useful and reversible. Stop at any phase if the
value/effort trade stops making sense — this is the whole point of not
big-banging it.

**Phase 0 — Spike (½ day).** Install Nix (Determinate Systems installer) on one
non-critical machine or the WSL box. Get a minimal `flake.nix` + `home.nix` that
installs *one* package (`ripgrep`) and symlinks *one* file (`.aliases`). Goal:
confirm the toolchain and that `home-manager switch` / `--rollback` work for
you. **Deliverable:** the `nix/` skeleton in this branch, adapted to one host.

**Phase 1 — Dotfiles under Home Manager (1–2 days).** Move all symlinking from
`symlinks.sh` into `dotfiles.nix` using `mkOutOfStoreSymlink` (§5.3). Your files
don't move; only the linking mechanism changes. Retire `Setup/installers/symlinks.sh`.
**Now #1, #4, #6 are solved for configs and you're still editing files normally.**

**Phase 2 — CLI packages (2–3 days).** Port the Homebrew array to
`packages.nix` (§5.2). Keep Homebrew installed as a fallback for anything not
in nixpkgs (macOS casks especially). Delete the ported entries from
`packages.sh`. **Now versions are pinned and reproducible (#2, #3, #5).**

**Phase 3 — Native modules, opportunistically (ongoing).** Convert
high-value tools (zsh, starship, git, direnv, fzf, tmux) to HM `programs.*`
(§5.4). Leave the rest as symlinks. No deadline.

**Phase 4 — Per-OS system config (optional).** Add `nix-darwin` for the Mac
(replaces manual macOS defaults) and/or NixOS-WSL. Fold `MacOS/` and the WSL
branches of `.profile` into host modules.

**What you keep, permanently:**

- **mise** for per-project language versions + `curl`-installed dev tools that
  are painful in Nix.
- This repo's structure and your `.zshrc`/`.config` files (linked, not rewritten).
- `run.sh` can stay as a thin bootstrap that installs Nix and runs
  `home-manager switch`, or be retired.

**Rough effort:** a usable Phase 0–1 state in a weekend; a machine you'd trust
to reproduce in ~1 week of evenings. The learning curve is front-loaded in
Phase 0.

## 7. Honest risks and downsides of Nix

- **Learning curve.** The language is the tax. Budget real time for it; the
  first week is frustrating.
- **Disk usage.** `/nix/store` grows; `nix-collect-garbage` manages it, but it's
  more disk than brew/mise.
- **Some tools fight it.** GUI apps, proprietary binaries, and things expecting
  FHS paths can need workarounds (`buildFHSEnv`, or just leave them to
  brew/apt). Your `curl | bash` agent tools (Gentle-AI, oh-my-posh) may be
  easier left on their current installers initially.
- **WSL specifics.** Works well, but the DBus/gnome-keyring and IDE-server
  patching you do in `.profile`/`symlinks.sh` will need re-homing into HM
  activation scripts.
- **It's not all-or-nothing, and that's the mitigation.** Every phase above is
  independently valuable and reversible. If Nix stops paying off at Phase 2,
  you still have a materially more robust setup than today and can stop.

## 8. Per-machine identity & secrets (work vs personal)

Your `.gitconfig` currently hardcodes `user.email` and `user.signingKey`, and
commits them. That's the one thing that genuinely can't be shared across a work
and a personal machine. It's very fixable, and worth separating into **three
tiers**, because they're handled differently:

| Tier | Example | Where it lives | Committed? |
|------|---------|----------------|-----------|
| 1. True secret | SSH **private** key | `~/.ssh/` per machine, generated per device | **Never** (not git, not `/nix/store`) |
| 2. Per-machine identity | git email, which **public** signing key | small **untracked** file per machine | No (or encrypted) |
| 3. Encrypted-at-rest | API tokens, etc. | `~/.profile_secret`, or sops/age | Only if encrypted |

Tier 1 already behaves correctly here: the private key is never committed, and
`scripts/ssh-sign` reads `SSH_SIGN_KEY_PATH` so each machine points at its own
key. `.ssh/allowed_signers` holds *public* keys only, so it's fine to keep
committing it. **Only tier 2 needs changing.**

### 8.1 The tooling-independent fix: git `include` / `includeIf`

This is worth doing **now**, regardless of the Nix decision. Drop the `[user]`
block from the committed `.gitconfig` and pull identity from an untracked file:

```gitconfig
# committed .gitconfig — no identity here anymore
[include]
    path = ~/.config/git/local.gitconfig    # untracked, written once per machine
```

Each machine's `~/.config/git/local.gitconfig` (never committed) holds:

```gitconfig
[user]
    email = bosco.domingo@iceye.com
    signingKey = key::ssh-ed25519 AAAA…work-key…
```

Even better, if a **single** machine has both work and personal repos, use
directory-conditional includes so the right key is chosen automatically:

```gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/.config/git/work.gitconfig
[includeIf "gitdir:~/personal/"]
    path = ~/.config/git/personal.gitconfig
```

Your `.gitignore` already ignores `*_secret`; add `local.gitconfig` (or name the
files `*_secret`). This directly answers your question — the private bit is a
plain local file you write once per machine, nothing leaves the box.

### 8.2 In Nix / Home Manager

Home Manager declares those same includes in Nix, still pointing at untracked
local files, so no identity is baked into the (potentially public) repo:

```nix
programs.git = {
  enable = true;
  userName = "Bosco Domingo";
  includes = [
    { path = "~/.config/git/local.gitconfig"; }                    # per-machine default
    { condition = "gitdir:~/work/";     path = "~/.config/git/work.gitconfig"; }
    { condition = "gitdir:~/personal/"; path = "~/.config/git/personal.gitconfig"; }
  ];
};
```

Two ways to supply the private values:

- **Local file (recommended, simplest):** the `include` above reads a file you
  write once per machine — matches your existing `~/.profile_secret` habit,
  zero extra infrastructure.
- **Encrypted-in-repo (if you want it version-controlled):** `sops-nix` or
  `agenix` decrypt secrets into place on `home-manager switch`, keyed to each
  machine's SSH/age key. Use this only if you specifically want the values
  tracked (encrypted) rather than living outside the repo.

Non-secret per-machine values could alternatively live in the host module
(`macbook.nix` = personal, a work host = work), but a public repo is a reason to
prefer the local-file route for the work email. The SSH **private** key is never
put in Nix — Home Manager only references its path; you generate/copy it per
machine as today.

### 8.3 In chezmoi

Its native answer: a `.gitconfig.tmpl` templated from per-machine data
(`.chezmoidata`, or a first-run prompt), with age/1Password for anything
encrypted:

```gitconfig
[user]
    email = {{ .git.email }}
    signingKey = {{ .git.signingKey }}
```

### 8.4 Recommendation

Use a **local untracked file per machine** (§8.1) — it's the least infrastructure,
matches your `~/.profile_secret` pattern, and works identically whether you stay
on shell, adopt Nix, or adopt chezmoi. Add `includeIf` if work and personal
repos ever share a machine. Reach for sops-nix/agenix only if you want the
secrets themselves committed (encrypted). The SSH private key stays per-machine
and out of the repo in every case.

## 9. Tool ownership & retiring `run.sh`

The end state is that **`run.sh` goes away** and each responsibility has exactly
one owner. Nothing is installed by more than one system.

### 9.1 Who owns what

| System | Owns | Examples |
|--------|------|----------|
| **Nix / Home Manager** | Stable global CLI tools; dotfile symlinks | rg, bat, fd, eza, fzf, delta, bottom, btop, duf, gping, hyperfine, trippy, sshs, rip2, fastfetch, onefetch, lazyjj, witr, zsh plugins, **jj, neovim, opencode, yt-dlp, act, tree-sitter** |
| **mise** | Language runtimes + floating/per-project dev tools; tools not in nixpkgs | node, go, python, rust, bun, pnpm, biome, golangci-lint, navi, diffnav, dotenvx, gdu, **pi** |
| **Homebrew** | An escape hatch on **all platforms** for anything not in nixpkgs; on macOS also GUI casks (declared via **nix-darwin's `homebrew` module**) | `gentle-ai` (tap, Linux + macOS); ghostty/cursor/firefox casks (macOS) |

Applied in this branch: the whole brew formula array plus jj/neovim/opencode/
yt-dlp/act/tree-sitter moved to `nix/home/packages.nix`; `ripgrep`/`hyperfine`
and those tools were removed from mise (Nix owns them). `pi` stays in mise and
`gentle-ai` stays on Homebrew — neither is in nixpkgs. `Setup/installers/packages.sh`
no longer installs a formula list but **keeps Homebrew installed on Linux too**
as a fallback; casks are shown declaratively in `nix/hosts/macbook.nix`.

### 9.2 `run.sh` → Nix replacement map

`run.sh` does more than install packages. Each of its installers maps to a Nix
mechanism; it can be deleted once all are ported:

| `run.sh` installer | Replacement | Status |
|--------------------|-------------|--------|
| `symlinks.sh` | `home/dotfiles.nix` (`mkOutOfStoreSymlink`) | ✅ done |
| `packages.sh` | `home/packages.nix` (Nix); Homebrew kept on all platforms as a fallback + macOS casks via nix-darwin | ✅ done |
| `gpg.sh` | Deprecated (SSH signing now); optional prompts, nothing to port | ✅ n/a |
| `tools.sh` → oh-my-posh | mise already manages it (`[tool_alias]`) or a Nix pkg | ✅ covered |
| `tools.sh` → oh-my-zsh | `programs.zsh.oh-my-zsh` (HM); replaces the `.zshrc` symlink | ⬜ Phase 3 |
| `tools.sh` → tmux + tpm | `programs.tmux` with `plugins = [ … ]` (HM builds them) | ⬜ Phase 3 |
| `tools.sh` → cheat sheets, micro themes | `home.activation` fetch / `home.file` | ⬜ Phase 3 |
| `ai-agents.sh` → jj approval guards | `home.activation` running the existing `AI/agent-guards/install.py` | ⬜ Phase 3 |
| `ai-agents.sh` → gentle-ai | Stays on its Homebrew tap, installed on **Linux + macOS** (not in nixpkgs) | ✅ unchanged |
| `run.sh` (entrypoint) | `nix/bootstrap.sh` | ✅ done |
| `Arch/run_arch.sh`, `Ubuntu/run_ubuntu.sh` | Shrink to: install prerequisites + Nix, clone, run `bootstrap.sh` | ⬜ Phase 4 |

The ⬜ items are the remaining work before `run.sh` can be removed. They're all
Phase 3–4 in §6 and independently shippable — none blocks the packages/dotfiles
core that's already working.

## 10. Bottom line

- **Is Nix viable?** Yes — Home Manager + flakes cleanly covers Arch, Ubuntu,
  macOS, and WSL, and is the only option that makes your setup *reproducible*
  (pinned versions) and *reversible* (atomic rollback). Those two properties are
  the real meaning of "robust," and nothing else on the list delivers them.
- **Is it the right call for you?** Yes *if* you're willing to spend ~a week on
  the learning curve for a permanently lower-maintenance, reproducible setup,
  and you migrate in phases rather than all at once.
- **If not**, chezmoi is the pragmatic runner-up: most of the robustness, a
  fraction of the learning curve, and it plays nicely with your existing
  brew/mise workflow.
- **Either way**, keep mise for per-project toolchains.

The `nix/` directory in this branch is a **working, tested** Home Manager
config — not just a sketch. It was verified end-to-end on a clean machine:
packages install and run, dotfiles become out-of-store symlinks to the live
repo (still editable in place), the per-machine and per-directory git identity
overrides resolve correctly, and rollback is atomic. The full record is in
[`../nix/test/README.md`](../nix/test/README.md). Nothing there runs until you
install Nix and invoke it deliberately (`nix/bootstrap.sh`).

# 2026-09-15 Use Determinate Nix

Decision: Use the Determinate Nix Installer and its default Determinate Nix
distribution for automated setup. Reconsider upstream Nix if this choice stops
being reliable, compatible, transparent, or easy to remove.

## Context

`nix/bootstrap.sh` needs to install Nix unattended on Arch-based Linux, Ubuntu,
WSL, and macOS before Home Manager can activate the configuration. The
installer creates system services and the Nix store, so this choice has a wider
effect than a Home Manager generation.

Determinate Nix is a downstream distribution of Nix. It does not control the
`nixpkgs` or Home Manager inputs pinned in `nix/flake.lock`. Its installer sends
limited anonymous installation diagnostics by default; these can be disabled
with `--diagnostic-endpoint=""`.

## Options considered

1. Use the Determinate installer and its default Determinate Nix distribution.

2. Use the official Nix installer and upstream Nix.

## Rationale for decision

The Determinate option provides one unattended, multi-user installation path
for the supported systems. It enables flakes, keeps an installation receipt,
supports uninstall and repair, and reduces custom bootstrap code. These
properties fit this repository's goal of repeatable setup better than the
official installer currently does. We accept the additional third-party trust
and the risk that some behavior can differ from upstream Nix.

Change to upstream Nix if Determinate adds unacceptable proprietary behavior or
telemetry, becomes incompatible with supported systems or Home Manager, makes
upstream Nix guidance difficult to apply, weakens uninstall or repair, shows
maintenance or security problems, or conflicts with an upstream-only policy.
Also reconsider when the official installer offers an equally reliable
unattended, cross-platform, flakes-ready, and removable setup. Test install,
activation, rollback, upgrade, and uninstall before changing the bootstrap.

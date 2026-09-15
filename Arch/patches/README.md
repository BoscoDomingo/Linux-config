# Arch system patches

These patches modify root-owned files that Home Manager does not manage. A
device opts in by listing patch names in `overrides/patches/enabled` and running
`nix/bootstrap.sh` with the `arch` host.

Each patch directory contains an idempotent `apply` helper, the patch, and a
pacman hook. `Arch/sync-patches.sh` copies these files under `/usr/local/lib`
and `/etc/pacman.d/hooks`; it does not link root-owned configuration into the
home-directory checkout. Helpers patch a temporary file and refuse unexpected
upstream code instead of applying partial changes.

Available patches:

- `plasma-lockscreen-fast-retry`: removes KDE's extra three-second retry delay.
  PAM authentication and account lockout policy are not changed.

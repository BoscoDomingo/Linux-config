# explicit-packages

`scripts/explicit-packages` lists explicitly installed packages on Arch-based
systems (repo and AUR/foreign, e.g. via paru) as a coloured table: version,
source, origin, install/update dates and description. Origin comes from
`/var/log/pacman.log`.

Requires: `pacman`, `gawk`.

## Usage

```sh
explicit-packages [view] [-r|--repo] [-a|--aur] [-s|--sort date|updated|name] [-n|--no-color]
```

| Option                 | Effect                                                 |
| ---------------------- | ------------------------------------------------------ |
| _(no view)_            | Everything except what the OS installer set up         |
| `-u`, `--user-typed`   | Only packages you named in a `pacman`/`paru` command   |
| `-i`, `--installer`    | Only packages the OS installer set up                  |
| `--all`                | Everything                                             |
| `-r` / `-a`            | Only repo / only AUR-foreign packages                  |
| `-s`, `--sort`         | `date` installed (default), last `updated`, or `name`  |
| `-n`, `--no-color`     | Plain output (automatic when not a TTY)                |

`BY` column: `typed` (you named it, or its group), `indirect` (marked explicit
by something else, e.g. a replacement), `installer`, `unknown` (not in the log).

## Examples

```sh
explicit-packages -u --aur -s name         # AUR packages you asked for
explicit-packages -s updated               # recently changed last
explicit-packages -n -u > ~/my-packages.txt  # snapshot for a new machine
```

## Notes

- Installer session: starts with a command on an alternate root (Calamares,
  pacstrap) and lasts while automated commands follow within 5 minutes.
- `UPDATED` is pacman's "Install Date", which changes on every upgrade.
- If the log is rotated, older packages show as `unknown`. Override the log
  path with `PACMAN_LOG=...`.
- Descriptions are truncated to the terminal width (80 columns when piped).

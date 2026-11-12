# Plasma lock-screen fast retry

This patch removes KDE's retry delay in:

```text
/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
```

The `plasma-desktop` pacman hook reapplies it after updates.

## Check the installed state

```sh
grep -A3 -F 'id: graceLockTimer' \
  /usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml

sudo /usr/local/lib/dotfiles/patches/plasma-lockscreen-fast-retry/apply
```

Expect `interval: 0` and `already applied`. Hook output is in
`/var/log/pacman.log`.

## Fix an upstream mismatch

If the helper reports `upstream code changed`, confirm that `graceLockTimer`
still controls retries, then refresh the patch:

```sh
target=/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml
work=$(mktemp -d)
cp "$target" "$work/original"
cp "$target" "$work/modified"
${EDITOR:-vi} "$work/modified"

diff -u --label LockScreenUi.qml --label LockScreenUi.qml \
  "$work/original" "$work/modified" \
  > ~/dotfiles/Arch/patches/plasma-lockscreen-fast-retry/retry-delay.patch

patch --dry-run --forward "$target" \
  ~/dotfiles/Arch/patches/plasma-lockscreen-fast-retry/retry-delay.patch
bash ~/dotfiles/Arch/tests/patches.sh
sudo env DOTFILES_REPO="$HOME/dotfiles" "$HOME/dotfiles/Arch/sync-patches.sh"
qmllint "$target"
rm -rf "$work"
```

`diff` returning 1 is expected. Review the patch, then test one failed login.

## Disable or recover

Remove `plasma-lockscreen-fast-retry` from `overrides/patches/enabled`, then run:

```sh
bash ~/dotfiles/nix/bootstrap.sh
```

If reverse patching fails, remove the hook first and restore the package file:

```sh
sudo pacman -S plasma-desktop
```

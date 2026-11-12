#!/usr/bin/env bash
# Test Arch patch application against an isolated fake system root.
set -euo pipefail

repo=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
root="$tmp/root"
target="$root/usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/LockScreenUi.qml"
selection="$tmp/enabled"
mkdir -p "$(dirname "$target")"

write_original() {
	cat >"$target" <<'EOF'
        Timer {
            id: notificationRemoveTimer
            interval: 3000
            onTriggered: root.notification = ""
        }
        Timer {
            id: graceLockTimer
            interval: 3000
            onTriggered: {
                root.clearPassword();
                authenticator.startAuthenticating();
            }
        }
EOF
}

assert_contains() {
	grep -Fq "$2" "$1" || {
		printf 'Expected %s to contain: %s\n' "$1" "$2" >&2
		exit 1
	}
}

write_original
printf 'plasma-lockscreen-fast-retry\n' >"$selection"
DOTFILES_REPO="$repo" DOTFILES_PATCH_ROOT="$root" DOTFILES_PATCH_SELECTION="$selection" \
	bash "$repo/Arch/sync-patches.sh"
assert_contains "$target" 'interval: 0'
assert_contains "$root/etc/pacman.d/hooks/95-dotfiles-plasma-lockscreen-fast-retry.hook" 'Target = plasma-desktop'

# A repeated apply is a no-op and remains successful.
DOTFILES_PATCH_ROOT="$root" \
	"$root/usr/local/lib/dotfiles/patches/plasma-lockscreen-fast-retry/apply"
assert_contains "$target" 'interval: 0'

# Disabling restores only the expected patch and removes installed assets.
: >"$selection"
DOTFILES_REPO="$repo" DOTFILES_PATCH_ROOT="$root" DOTFILES_PATCH_SELECTION="$selection" \
	bash "$repo/Arch/sync-patches.sh"
assert_contains "$target" 'interval: 3000'
test ! -e "$root/etc/pacman.d/hooks/95-dotfiles-plasma-lockscreen-fast-retry.hook"

# Changed upstream context must remain byte-for-byte unchanged.
printf 'upstream changed this component\n' >"$target"
before=$(cksum "$target")
DOTFILES_PATCH_ROOT="$root" \
	bash "$repo/Arch/patches/plasma-lockscreen-fast-retry/apply"
after=$(cksum "$target")
test "$before" = "$after"

# Unknown selections are rejected before installation.
printf 'unknown-patch\n' >"$selection"
if DOTFILES_REPO="$repo" DOTFILES_PATCH_ROOT="$root" DOTFILES_PATCH_SELECTION="$selection" \
	bash "$repo/Arch/sync-patches.sh"; then
	printf 'Expected an unknown patch selection to fail\n' >&2
	exit 1
fi

printf 'Arch patch tests passed\n'

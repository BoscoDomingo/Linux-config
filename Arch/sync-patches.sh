#!/usr/bin/env bash
# Install selected Arch system patches and their pacman hooks.
set -euo pipefail

repo="${DOTFILES_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
selection="${DOTFILES_PATCH_SELECTION:-$repo/overrides/patches/enabled}"
root="${DOTFILES_PATCH_ROOT:-}"
install_root="$root/usr/local/lib/dotfiles/patches"
hook_root="$root/etc/pacman.d/hooks"
known_patches=(plasma-lockscreen-fast-retry)

if [ ! -f "$selection" ]; then
	exit 0
fi

if [ -z "$root" ] && [ "${EUID:-$(id -u)}" -ne 0 ]; then
	exec sudo --preserve-env=DOTFILES_REPO "$0"
fi

mkdir -p "$install_root" "$hook_root"

is_enabled() {
	grep -Ev '^[[:space:]]*(#|$)' "$selection" | grep -Fxq "$1"
}

while IFS= read -r selected; do
	case "$selected" in
	'' | \#*) continue ;;
	esac
	valid=0
	for patch_name in "${known_patches[@]}"; do
		[ "$selected" = "$patch_name" ] && valid=1
	done
	if [ "$valid" -eq 0 ]; then
		printf 'Unknown Arch patch in %s: %s\n' "$selection" "$selected" >&2
		exit 1
	fi
done <"$selection"

for patch_name in "${known_patches[@]}"; do
	source_dir="$repo/Arch/patches/$patch_name"
	hook_name="95-dotfiles-$patch_name.hook"
	installed_dir="$install_root/$patch_name"
	if is_enabled "$patch_name"; then
		mkdir -p "$installed_dir"
		install -m 0755 "$source_dir/apply" "$installed_dir/apply"
		install -m 0644 "$source_dir/retry-delay.patch" "$installed_dir/retry-delay.patch"
		install -m 0644 "$source_dir/$hook_name" "$hook_root/$hook_name"
		"$installed_dir/apply"
	else
		if [ -x "$installed_dir/apply" ]; then
			"$installed_dir/apply" remove
		fi
		rm -f "$hook_root/$hook_name"
		rm -rf "$installed_dir"
	fi
done

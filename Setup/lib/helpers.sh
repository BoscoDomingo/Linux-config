# MARK: Helper functions
backup_existing() {
	dst="$1"
	backup_path="$dst.bak"
	backup_index=1

	while [ -e "$backup_path" ] || [ -L "$backup_path" ]; do
		backup_path="$dst.bak.$backup_index"
		backup_index=$((backup_index + 1))
	done

	mv "$dst" "$backup_path"
}

ensure_link() {
	src="${1%/}"
	dst="$2"
	normalized_src=$(readlink -f "$src" 2>/dev/null || printf '%s\n' "$src")

	if [ -L "$dst" ]; then
		current_target=$(readlink -f "$dst" 2>/dev/null || readlink "$dst")
		current_target="${current_target%/}"
		normalized_src="${normalized_src%/}"
		if [ "$current_target" = "$normalized_src" ]; then
			return
		fi
		backup_existing "$dst"
	elif [ -e "$dst" ]; then
		backup_existing "$dst"
	fi

	ln -s "$src" "$dst"
}

path_prepend_if_missing() {
	argpath="$1"
	case ":$PATH:" in
	*":$argpath:"*) ;;
	*) export PATH="$argpath:$PATH" ;;
	esac
}

append_if_missing() {
	line="$1"
	target_file="$2"

	touch "$target_file"
	if ! grep -Fxq "$line" "$target_file"; then
		printf '%s\n' "$line" >>"$target_file"
	fi
}

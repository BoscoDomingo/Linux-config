#!/usr/bin/env bash
# Black-box tests for scripts/dotfiles-upgrade. Package managers are fakes.
set -euo pipefail

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
UPGRADE="$ROOT/scripts/dotfiles-upgrade"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

FIXTURE="$TMP/fixture"
FAKE_BIN="$TMP/bin"
HOME_DIR="$TMP/home"
ARBITRARY_DIR="$TMP/some/arbitrary/directory"
LOG="$TMP/commands.log"
EXPECTED_CONFIG=$'experimental-features = nix-command flakes\ntest-setting = inherited'
HOST=upgrade-test-host
NIX_FAIL=0

mkdir -p "$FIXTURE/nix" "$FAKE_BIN" "$HOME_DIR/.local/bin" "$ARBITRARY_DIR"
printf '# fixture\n' >"$FIXTURE/nix/flake.nix"
printf 'fixture\n' >"$FIXTURE/nix/bootstrap.sh"

cat >"$FAKE_BIN/nix" <<'EOF'
#!/bin/bash
set -eu
printf 'nix %s\n' "$*" >> "$UPGRADE_TEST_LOG"
printf '%s' "${NIX_CONFIG-}" > "$UPGRADE_TEST_NIX_CONFIG"
printf '%s' "${HOST-}" > "$UPGRADE_TEST_HOST"
if [ "${UPGRADE_TEST_NIX_FAIL:-0}" -eq 1 ]; then
	exit 37
fi
EOF

cat >"$FIXTURE/nix/bootstrap.sh" <<'EOF'
#!/bin/bash
set -eu
printf 'bootstrap\n' >> "$UPGRADE_TEST_LOG"
printf '%s' "${NIX_CONFIG-}" > "$UPGRADE_TEST_BOOTSTRAP_CONFIG"
printf '%s' "${HOST-}" > "$UPGRADE_TEST_BOOTSTRAP_HOST"
EOF

cat >"$HOME_DIR/.local/bin/mise" <<'EOF'
#!/bin/bash
set -eu
printf 'mise %s\n' "$*" >> "$UPGRADE_TEST_LOG"
EOF

cat >"$FAKE_BIN/brew" <<'EOF'
#!/bin/bash
set -eu
printf 'brew %s\n' "$*" >> "$UPGRADE_TEST_LOG"
EOF

cat >"$FAKE_BIN/cat" <<'EOF'
#!/bin/bash
set -eu
while IFS= read -r line; do
	printf '%s\n' "$line"
done
EOF

chmod +x "$FAKE_BIN/nix" "$FIXTURE/nix/bootstrap.sh" \
	"$HOME_DIR/.local/bin/mise" "$FAKE_BIN/brew" "$FAKE_BIN/cat"
ln -s "$(command -v bash)" "$FAKE_BIN/bash"

export HOST
export UPGRADE_TEST_LOG="$LOG"
export UPGRADE_TEST_NIX_CONFIG="$TMP/nix-config"
export UPGRADE_TEST_BOOTSTRAP_CONFIG="$TMP/bootstrap-config"
export UPGRADE_TEST_HOST="$TMP/nix-host"
export UPGRADE_TEST_BOOTSTRAP_HOST="$TMP/bootstrap-host"

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_equal() {
	local actual=$1 expected=$2 message=$3
	[ "$actual" = "$expected" ] || fail "$message (expected '$expected', got '$actual')"
}

assert_file() {
	local file=$1 expected=$2 actual
	actual=$(<"$file")
	assert_equal "$actual" "$expected" "$file"
}

reset_case() {
	: >"$LOG"
	: >"$UPGRADE_TEST_NIX_CONFIG"
	: >"$UPGRADE_TEST_BOOTSTRAP_CONFIG"
	: >"$UPGRADE_TEST_HOST"
	: >"$UPGRADE_TEST_BOOTSTRAP_HOST"
}

run_upgrade() {
	local path=$1
	shift
	(
		cd "$ARBITRARY_DIR"
		HOME="$HOME_DIR" PATH="$path" DOTFILES_REPO="$FIXTURE" \
			NIX_CONFIG='test-setting = inherited' \
			UPGRADE_TEST_NIX_FAIL="$NIX_FAIL" bash "$UPGRADE" "$@"
	)
}

UPDATE="nix flake update --flake $FIXTURE/nix"

# Default mode updates Nix, bootstraps from DOTFILES_REPO, and skips other managers.
reset_case
run_upgrade "$FAKE_BIN"
assert_equal "$(<"$LOG")" "$UPDATE"$'\n'"bootstrap" 'default command log'
assert_file "$UPGRADE_TEST_NIX_CONFIG" "$EXPECTED_CONFIG"
assert_file "$UPGRADE_TEST_BOOTSTRAP_CONFIG" "$EXPECTED_CONFIG"
assert_file "$UPGRADE_TEST_HOST" "$HOST"
assert_file "$UPGRADE_TEST_BOOTSTRAP_HOST" "$HOST"

run_all_case() {
	local flag=$1
	reset_case
	run_upgrade "$FAKE_BIN" "$flag"
	assert_equal "$(<"$LOG")" "$UPDATE"$'\n'"bootstrap"$'\n'"mise self-update --yes"$'\n'"mise upgrade --yes"$'\n'"brew update"$'\n'"brew upgrade" \
		"$flag command log"
}

# Both accepted spellings update mise and Homebrew in order.
run_all_case --all
run_all_case -a

# Missing Homebrew is optional in --all mode.
mv "$FAKE_BIN/brew" "$TMP/brew.disabled"
reset_case
run_upgrade "$FAKE_BIN" --all
assert_equal "$(<"$LOG")" "$UPDATE"$'\n'"bootstrap"$'\n'"mise self-update --yes"$'\n'"mise upgrade --yes" \
	'Homebrew absence command log'
mv "$TMP/brew.disabled" "$FAKE_BIN/brew"

# An unknown option fails before any update command runs.
reset_case
if run_upgrade "$FAKE_BIN" --unknown; then
	fail 'unknown argument succeeded'
else
	assert_equal "$?" 2 'unknown argument exit status'
fi
assert_equal "$(<"$LOG")" '' 'unknown argument command log'

# A failed Nix update status propagates and stops bootstrap and later managers.
reset_case
NIX_FAIL=1
if run_upgrade "$FAKE_BIN" --all; then
	fail 'failed Nix update succeeded'
else
	assert_equal "$?" 37 'failed Nix update exit status'
fi
NIX_FAIL=0
assert_equal "$(<"$LOG")" "$UPDATE" 'failed Nix command log'

printf 'upgrade-test: PASS\n'

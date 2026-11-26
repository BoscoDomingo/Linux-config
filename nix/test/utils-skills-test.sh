#!/usr/bin/env bash
# Black-box tests for the utils_skills activation step (nix/home/tools.nix).
# Builds the activation package, cuts the step out of the generated script, and
# runs it the way activation does (set -euo pipefail) in a throwaway $HOME. A
# local fixture repo stands in for github.com/BoscoDomingo/utils, so the test
# needs no network after the build and never touches the real $HOME.
#
#   bash nix/test/utils-skills-test.sh
#   HOST=ubuntu bash nix/test/utils-skills-test.sh   # build another host
#   ACTIVATE=/nix/store/...-home-manager-generation/activate bash nix/test/utils-skills-test.sh
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	if [ -f "$TMP/out" ]; then
		printf -- '--- last step output ---\n' >&2
		cat "$TMP/out" >&2
	fi
	exit 1
}
pass() { printf 'ok: %s\n' "$1"; }

# Same host choice as nix/bootstrap.sh. The step is the same on every host, so
# any host works; this one is most likely already built.
if [ -z "${ACTIVATE:-}" ]; then
	if [ -z "${HOST:-}" ]; then
		if [ "$(uname -s)" = "Darwin" ]; then
			HOST=macbook
		elif grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null &&
			grep -q '^ID=arch' /etc/os-release 2>/dev/null; then
			HOST=arch-wsl
		elif grep -q '^ID=cachyos' /etc/os-release 2>/dev/null; then
			HOST=cachyos
		elif grep -q '^ID=ubuntu' /etc/os-release 2>/dev/null; then
			HOST=ubuntu
		else
			HOST=arch
		fi
	fi
	# path: reads the directory as it is, so uncommitted changes are tested and
	# it works in git worktrees (which Nix's libgit2 cannot always open).
	echo "==> building homeConfigurations.$HOST.activationPackage"
	gen=$(nix build --no-link --print-out-paths \
		"path:$ROOT/nix#homeConfigurations.$HOST.activationPackage")
	ACTIVATE="$gen/activate"
fi
[ -f "$ACTIVATE" ] || fail "no activate script at $ACTIVATE"

# --- Cut the step out of the generated activate script ----------------------
start=$(grep -n '"Activating %s" "utilsSkills"' "$ACTIVATE" | cut -d: -f1 || true)
[ -n "$start" ] || fail "utilsSkills step not found in $ACTIVATE"
sed -n "$((start + 1)),\$p" "$ACTIVATE" |
	awk '/^_iNote "Activating/ || /# Create the "current generation" GC root/ {exit} {print}' \
		>"$TMP/step.raw"

# The step has the real dotfiles path and the GitHub URL baked in. Point both
# at fixtures in $TMP.
baked=$(grep -oE '"[^"]*/overrides/activation/disabled"' "$TMP/step.raw" | head -n 1 | tr -d '"')
baked=${baked%/overrides/activation/disabled}
[ -n "$baked" ] || fail "could not find the dotfiles path in the step"
DOTFILES="$TMP/dotfiles"
REMOTE="$TMP/remote"
sed -e "s#$baked/overrides/#$DOTFILES/overrides/#g" \
	-e "s#https://github.com/BoscoDomingo/utils.git#$REMOTE#g" \
	"$TMP/step.raw" >"$TMP/step.sh"
grep -q "$REMOTE" "$TMP/step.sh" || fail "clone URL not found in the step"

# Skills the step links (from utilsSkills in tools.nix).
read -r -a SKILLS <<<"$(sed -nE 's/^for skill in (.*); do$/\1/p' "$TMP/step.sh" | tr -d "'")"
[ "${#SKILLS[@]}" -gt 0 ] || fail "skill list not found in the step"
pass "extracted step (skills: ${SKILLS[*]})"

# --- Fixtures ----------------------------------------------------------------
mkdir -p "$DOTFILES/overrides/activation"
VARS="$DOTFILES/overrides/vars.env"
DISABLED="$DOTFILES/overrides/activation/disabled"

# jj and git must not read the real user config.
export JJ_CONFIG="$TMP/jj.toml"
printf '[user]\nname = "Test"\nemail = "test@example.com"\n' >"$JJ_CONFIG"
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
printf '[user]\n\tname = Test\n\temail = test@example.com\n' >"$GIT_CONFIG_GLOBAL"

git init -q -b main "$REMOTE"
for skill in "${SKILLS[@]}"; do
	mkdir -p "$REMOTE/ai_llm/skills/$skill"
	printf '# %s\n' "$skill" >"$REMOTE/ai_llm/skills/$skill/SKILL.md"
done
git -C "$REMOTE" add -A
git -C "$REMOTE" commit -q -m c1
remote_commit() {
	printf 'change %s\n' "$1" >"$REMOTE/CHANGELOG"
	git -C "$REMOTE" add -A
	git -C "$REMOTE" commit -q -m "$1"
}
remote_head() { git -C "$REMOTE" rev-parse main; }

# Run the step like Home Manager does: strict mode, `run` executes its args.
run_step() { # $1 = fake HOME
	mkdir -p "$1"
	if ! (
		set -euo pipefail
		export HOME="$1"
		run() { "$@"; }
		# shellcheck disable=SC1091
		source "$TMP/step.sh"
	) >"$TMP/out" 2>&1; then
		fail "step exited non-zero for HOME=$1"
	fi
}
wc_parent() { jj -R "$1" log --no-graph -r '@-' -T 'commit_id'; }
assert_links_into() { # $1 = HOME, $2 = clone dir
	local skill link
	for skill in "${SKILLS[@]}"; do
		link="$1/.agents/skills/$skill"
		[ -L "$link" ] || fail "$link is not a symlink"
		[ "$(readlink "$link")" = "$2/ai_llm/skills/$skill" ] ||
			fail "$link -> $(readlink "$link") (expected $2/ai_llm/skills/$skill)"
	done
}
assert_out() { grep -qF -- "$1" "$TMP/out" || fail "expected output to contain: $1"; }

# --- 1. No vars.env: clone to the default path and link ----------------------
A="$TMP/home-a"
run_step "$A"
[ -d "$A/repos/utils/.jj" ] || fail "no jj clone at the default path ~/repos/utils"
[ "$(wc_parent "$A/repos/utils")" = "$(remote_head)" ] || fail "new clone is not on main"
assert_links_into "$A" "$A/repos/utils"
pass "fresh clone to ~/repos/utils, skills linked"

# --- 2. Up to date: no change -------------------------------------------------
before=$(jj -R "$A/repos/utils" log --no-graph -r @ -T 'commit_id')
run_step "$A"
[ "$(jj -R "$A/repos/utils" log --no-graph -r @ -T 'commit_id')" = "$before" ] ||
	fail "up-to-date clone was changed"
pass "up-to-date clone left as it is"

# --- 3. Behind main: move to main@origin --------------------------------------
remote_commit c2
run_step "$A"
[ "$(wc_parent "$A/repos/utils")" = "$(remote_head)" ] || fail "clone did not move to main@origin"
pass "behind clone moved to main@origin"

# --- 4. Local file changes block the move ------------------------------------
remote_commit c3
c2=$(git -C "$REMOTE" rev-parse main~1)
printf 'local work\n' >"$A/repos/utils/local-wip.txt"
run_step "$A"
assert_out "local changes in $A/repos/utils"
[ "$(wc_parent "$A/repos/utils")" = "$c2" ] || fail "clone with local changes was moved"
[ -f "$A/repos/utils/local-wip.txt" ] || fail "local file was lost"
pass "local file changes block the move and are kept"

# --- 5. An empty change with a description also blocks the move -------------
rm "$A/repos/utils/local-wip.txt"
jj -R "$A/repos/utils" --quiet describe -m "keep me"
run_step "$A"
assert_out "local changes in $A/repos/utils"
[ "$(wc_parent "$A/repos/utils")" = "$c2" ] || fail "described change was moved"
jj -R "$A/repos/utils" --quiet describe -m ""
run_step "$A"
[ "$(wc_parent "$A/repos/utils")" = "$(remote_head)" ] || fail "clone did not move once the change was empty again"
pass "described empty change blocks the move; clearing it allows the move"

# --- 6. UTILS_DIR in vars.env: parsing and override path --------------------
cat >"$VARS" <<'EOF'
# UTILS_DIR=~/commented/out
UTILS_DIR_OTHER=~/other/key
UTILS_DIR=~/first/value
  UTILS_DIR = "~/repos/personal/utils"
SOME_OTHER_KEY=x
EOF
B="$TMP/home-b"
# A real directory where a link would go must be left alone.
mkdir -p "$B/.agents/skills/${SKILLS[0]}"
printf 'mine\n' >"$B/.agents/skills/${SKILLS[0]}/KEEP"
run_step "$B"
[ -d "$B/repos/personal/utils/.jj" ] || fail "no clone at the UTILS_DIR path"
[ ! -e "$B/repos/utils" ] && [ ! -e "$B/first" ] && [ ! -e "$B/other" ] && [ ! -e "$B/commented" ] ||
	fail "a clone was made at a path other than the last UTILS_DIR"
assert_out "$B/.agents/skills/${SKILLS[0]} is not a symlink"
[ -f "$B/.agents/skills/${SKILLS[0]}/KEEP" ] || fail "real skill directory was changed"
for skill in "${SKILLS[@]:1}"; do
	[ "$(readlink "$B/.agents/skills/$skill")" = "$B/repos/personal/utils/ai_llm/skills/$skill" ] ||
		fail "$skill not linked into the UTILS_DIR clone"
done
pass "last UTILS_DIR wins (quotes, spaces, ~); comments and other keys ignored; real dir kept"

# --- 7. Changing UTILS_DIR repoints the links --------------------------------
printf 'UTILS_DIR=%s\n' "$TMP/elsewhere/utils" >"$VARS"
run_step "$A"
[ -d "$TMP/elsewhere/utils/.jj" ] || fail "no clone at the new UTILS_DIR"
assert_links_into "$A" "$TMP/elsewhere/utils"
[ -d "$A/repos/utils/.jj" ] || fail "old clone was removed"
pass "new UTILS_DIR: cloned there, links repointed, old clone kept"
rm -f "$VARS"

# --- 8. Plain git clone: fast-forward pull ----------------------------------
C="$TMP/home-c"
git clone -q "$REMOTE" "$C/repos/utils"
git -C "$C/repos/utils" reset -q --hard HEAD~1
run_step "$C"
[ "$(git -C "$C/repos/utils" rev-parse HEAD)" = "$(remote_head)" ] || fail "git clone was not fast-forwarded"
assert_links_into "$C" "$C/repos/utils"
pass "plain git clone fast-forwarded"

# --- 9. Failed fetch: keep the checkout, still link, exit 0 -----------------
D="$TMP/home-d"
run_step "$D"
jj -R "$D/repos/utils" git remote set-url origin "$TMP/missing-remote"
run_step "$D"
assert_out "fetch failed"
assert_links_into "$D" "$D/repos/utils"
pass "failed fetch keeps the checkout and does not fail activation"

# --- 10. Opt-out key skips the step -------------------------------------------
printf '# test\nutils_skills\n' >"$DISABLED"
E="$TMP/home-e"
run_step "$E"
assert_out "Skipping utils_skills"
[ ! -e "$E/repos" ] && [ ! -e "$E/.agents" ] || fail "opted-out step still changed \$HOME"
rm -f "$DISABLED"
pass "utils_skills in activation/disabled skips the step"

echo "all utils_skills tests passed"

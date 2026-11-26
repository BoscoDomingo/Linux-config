#!/usr/bin/env bash
# Black-box test for the path-based git/jj identity rules, including personal
# repos nested in the work tree (~/repos/personal). Uses the committed
# .gitconfig, .config/jj/config.toml and overrides/jj/*.example in a throwaway
# $HOME, with overrides/ files seeded like nix/test/container-test.sh. The real
# $HOME and overrides/ are never read.
#
#   bash nix/test/identity-test.sh
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname "$0")/../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}
pass() { printf 'ok: %s\n' "$1"; }

WORK=you@work.example
PERSONAL=you@personal.example

# Fake $HOME: git reads ~/.gitconfig, jj reads ~/.config/jj, and every `~` in
# those files resolves here.
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
unset GIT_CONFIG_GLOBAL GIT_CONFIG_SYSTEM JJ_CONFIG
export GIT_CONFIG_NOSYSTEM=1
O="$HOME/dotfiles/overrides"
mkdir -p "$O/git" "$O/jj" "$XDG_CONFIG_HOME/jj"
cp "$ROOT/.gitconfig" "$HOME/.gitconfig"
cp "$ROOT/.config/jj/config.toml" "$XDG_CONFIG_HOME/jj/config.toml"
ln -s "$O/jj" "$XDG_CONFIG_HOME/jj/conf.d"

# Work machine layout (same as container-test.sh).
printf '[user]\n\temail = %s\n' "$WORK" >"$O/git/local.gitconfig"
printf '[user]\n\temail = %s\n' "$WORK" >"$O/git/work.gitconfig"
printf '[user]\n\temail = %s\n' "$PERSONAL" >"$O/git/personal.gitconfig"
printf '[user]\nemail = "%s"\n' "$WORK" >"$O/jj/local.toml"
printf -- '--when.repositories = ["~/repos"]\n\n[user]\nemail = "%s"\n' "$WORK" >"$O/jj/work.toml"
printf -- '--when.repositories = ["~/dotfiles", "~/personal"]\n\n[user]\nemail = "%s"\n' "$PERSONAL" >"$O/jj/personal.toml"
# The committed example, with its email swapped for the test one.
sed "s/^email = .*/email = \"$PERSONAL\"/" "$ROOT/overrides/jj/zz-repos-personal.toml.example" \
	>"$O/jj/zz-repos-personal.toml"

for d in repos/acme repos/personal/utils personal/blog dotfiles; do
	mkdir -p "$HOME/$d"
	git -C "$HOME/$d" init -q
	(cd "$HOME/$d" && jj git init --colocate >/dev/null 2>&1) || fail "jj git init failed in ~/$d"
done

check() { # $1 = repo under $HOME, $2 = expected email
	local git_email jj_email
	git_email=$(git -C "$HOME/$1" config user.email)
	jj_email=$(jj -R "$HOME/$1" config get user.email 2>/dev/null)
	[ "$git_email" = "$2" ] || fail "git in ~/$1 uses $git_email (expected $2)"
	[ "$jj_email" = "$2" ] || fail "jj in ~/$1 uses $jj_email (expected $2)"
	pass "~/$1 -> $2 (git and jj)"
}

check repos/acme "$WORK"
check repos/personal/utils "$PERSONAL"
check personal/blog "$PERSONAL"
check dotfiles "$PERSONAL"

# Control: without the zz- file, jj falls back to work.toml in ~/repos/personal.
# This is why the rule cannot live in personal.toml.
rm "$O/jj/zz-repos-personal.toml"
got=$(jj -R "$HOME/repos/personal/utils" config get user.email 2>/dev/null)
[ "$got" = "$WORK" ] || fail "control: expected $WORK without zz-repos-personal.toml, got $got"
pass "control: without zz-repos-personal.toml, jj in ~/repos/personal uses work"

echo "all identity tests passed"

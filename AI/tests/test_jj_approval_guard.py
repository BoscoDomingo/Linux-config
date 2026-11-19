#!/usr/bin/env python3
import json
import subprocess
import unittest
from pathlib import Path


HOOK = Path(__file__).resolve().parents[1] / "agent-guards" / "jj-approval.py"


def run_hook(command: str, provider: str = "cursor") -> dict:
    completed = subprocess.run(
        [str(HOOK), "--provider", provider],
        input=json.dumps({"command": command}),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    return json.loads(completed.stdout)


class JjAiApprovalHookTests(unittest.TestCase):
    def test_allows_read_only_jj_commands(self) -> None:
        for command in [
            "jj status",
            "jj st",
            "jj diff",
            "jj log -r @",
            "jj show @",
            "jj op log",
            "jj bookmark list",
            "jj config list",
            "jj workspace list",
            "jj workspace root",
            "jj wl",
            "jj w list",
            "jj w root",
            "jj workspace",
            "jj --no-pager workspace --repository ../repo root",
            "jj evolog",
            "jj evolution-log",
            "jj interdiff --from @- --to @",
            "jj shp",
            "jj lc",
            "jj file annotate README.md",
            "jj file search --pattern test",
            "jj operation diff",
            "jj b l",
            "jj tag l",
            "jj sparse list",
            "jj g remote list",
            "jj git root",
            "jj git colocation status",
            "jj util backend name",
            "jj util diff old.txt new.txt",
            "jj debug object commit @",
            "jj config p --user",
            "jj resolve -r @ --list",
            "jj slv --list",
            "jj git push --remote origin --dry-run",
            "jj gp --dry-run",
            "jj git push --help",
            "jj git push --no-pager --help",
            "jj -R../repo op --at-op=@ log",
            "jj --version",
        ]:
            with self.subTest(command=command):
                self.assertEqual(run_hook(command)["permission"], "allow")

    def test_asks_for_mutating_jj_commands_and_aliases(self) -> None:
        for command in [
            "jj commit -m test",
            "jj c",
            "jj ci",
            "jj new main",
            "jj n",
            "jj prev",
            "jj p",
            "jj next",
            "jj edit @-",
            "jj rebase -r @ -d main",
            "jj rbm @",
            "jj squash",
            "jj absorb",
            "jj bookmark set main -r @-",
            "jj bsm",
            "jj git push",
            "jj gp",
            "jj git fetch",
            "jj gf",
            "jj f",
            "jj g remote remove origin",
            "jj git colocation enable",
            "jj operation restore @-",
            "jj tag set v1",
            "jj sparse reset",
            "jj config path --repo",
            "jj config p --workspace",
            "jj config gc",
            "jj debug watchman reset-clock",
            "jj resolve",
            "jj slv",
            "jj w add ../ws",
            "jj resolve -- --list",
            "jj git push -- --dry-run",
            'jj git push --config "--dry-run" --remote origin',
            "jj util snapshot",
            "jj util exec -- echo --help",
            "jj undo",
            "jj workspace add ../ws",
            "jj workspace forget foo",
            "jj workspace update-stale",
        ]:
            with self.subTest(command=command):
                response = run_hook(command)
                self.assertEqual(response["permission"], "ask")
                self.assertIn("Jujutsu", response["user_message"])

    def test_detects_jj_inside_chained_shell_commands(self) -> None:
        response = run_hook('cd repo && jj commit -m "ship"')
        self.assertEqual(response["permission"], "ask")

    def test_detects_jj_inside_nested_shell_commands(self) -> None:
        response = run_hook('bash -lc \'jj commit -m "ship"\'')
        self.assertEqual(response["permission"], "ask")

    def test_only_uses_options_passed_to_jj(self) -> None:
        for command in [
            "jj git push > --dry-run",
            "jj git push 2>--dry-run",
            "jj git push &>--dry-run",
            "jj git push # --dry-run",
            "jj git push > --help",
            "jj resolve > --list",
            "jj slv # --list",
            "jj config path > --user",
            "echo done # comment\njj git push",
        ]:
            with self.subTest(command=command):
                self.assertEqual(run_hook(command)["permission"], "ask")

        for command in [
            "jj git push --dry-run > preview.txt",
            "jj resolve --list 2>/dev/null",
            "jj resolve '>' --list",
            "jj git push --named branch#2=@ --dry-run",
            "jj git push --dry-run # preview only",
        ]:
            with self.subTest(command=command):
                self.assertEqual(run_hook(command)["permission"], "allow")

    def test_joins_shell_line_continuations(self) -> None:
        for command in (
            "j\\\nj commit -m test",
            '"j\\\nj" commit -m test',
            "jj git pu\\\nsh",
            "jj git \\\npush",
            "jj git push >\\\n& --dry-run",
            "echo done # comment\\\njj git push",
        ):
            with self.subTest(command=command):
                self.assertEqual(run_hook(command)["permission"], "ask")

        for command in (
            "echo \\\n hello",
            "echo 'j\\\nj commit'",
            "echo j\\\\\nj commit",
            "j\\\nj status",
            'jj git push "--dry-\\\nrun"',
        ):
            with self.subTest(command=command):
                self.assertEqual(run_hook(command)["permission"], "allow")

    def test_allows_non_jj_commands(self) -> None:
        self.assertEqual(run_hook("git status")["permission"], "allow")

    def test_claude_provider_uses_pretooluse_ask(self) -> None:
        response = run_hook("jj commit -m ship", provider="claude")
        output = response["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertEqual(output["permissionDecision"], "ask")

    def test_codex_provider_denies_because_pretooluse_ask_is_unsupported(self) -> None:
        response = run_hook("jj commit -m ship", provider="codex")
        output = response["hookSpecificOutput"]
        self.assertEqual(output["hookEventName"], "PreToolUse")
        self.assertEqual(output["permissionDecision"], "deny")


if __name__ == "__main__":
    unittest.main()

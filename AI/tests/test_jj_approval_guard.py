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
            "jj git fetch",
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
            "jj undo",
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

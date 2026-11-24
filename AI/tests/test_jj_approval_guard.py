#!/usr/bin/env python3
import json
import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path


HOOK = Path(__file__).resolve().parents[1] / "agent-guards" / "jj-approval.py"


def run_hook(command: str, provider: str = "cursor") -> dict:
    return run_event({"command": command}, provider)


def run_event(payload: dict, provider: str, *, event: str = "shell", state_home=None) -> dict:
    env = os.environ.copy()
    if state_home is not None:
        env["XDG_STATE_HOME"] = state_home
    completed = subprocess.run(
        [str(HOOK), "--provider", provider, "--event", event],
        input=json.dumps(payload),
        env=env,
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

    def bound_grant_command(self, provider: str, id_field: str, state_home: str) -> str:
        # Check that the agent's grant call reaches the user, and return the
        # command the user approves (or runs, for Codex).
        helper = f"~/.local/bin/ai-agent-guard-jj-approval.py --provider {provider} --session-action grant"
        payload = {id_field: "chat-one", "tool_input": {"command": helper, "description": "Grant"}}
        bound = f"{helper} --session-id chat-one"
        if provider == "cursor":
            result = run_event(payload, provider, event="bind", state_home=state_home)
            self.assertEqual(result["updated_input"], {"command": bound, "description": "Grant"})
            shell = run_event({id_field: "chat-one", "command": bound}, provider, state_home=state_home)
            self.assertEqual(shell["permission"], "ask")
            return bound
        output = run_event(payload, provider, state_home=state_home)["hookSpecificOutput"]
        if provider == "claude":
            self.assertEqual(output["permissionDecision"], "ask")
            self.assertEqual(output["updatedInput"], {"command": bound, "description": "Grant"})
            return bound
        self.assertEqual(output["permissionDecision"], "deny")
        self.assertNotIn("updatedInput", output)
        self.assertIn(f"`{bound}`", output["permissionDecisionReason"])
        return bound

    def test_user_approved_grant_covers_only_the_current_chat_until_revoked(self) -> None:
        for provider, id_field, allowed in (
            ("cursor", "conversation_id", {"permission": "allow"}),
            ("claude", "session_id", {}),
            ("codex", "session_id", {}),
        ):
            with self.subTest(provider=provider), tempfile.TemporaryDirectory() as state_home:
                env = {**os.environ, "XDG_STATE_HOME": state_home}
                command = {id_field: "chat-one", "tool_input": {"command": "jj commit -m ship"}}
                default = run_event(command, provider, state_home=state_home)
                self.assertNotEqual(default, allowed)

                bound = self.bound_grant_command(provider, id_field, state_home)
                self.assertEqual(run_event(command, provider, state_home=state_home), default)
                # The user approved (or ran) the bound command.
                subprocess.run([str(HOOK), *shlex.split(bound)[1:]], env=env, check=True, capture_output=True)
                self.assertEqual(run_event(command, provider, state_home=state_home), allowed)
                for other_id in ("chat-two", None):
                    other_chat = {**command, id_field: other_id}
                    self.assertEqual(run_event(other_chat, provider, state_home=state_home), default)
                other_provider = "codex" if provider == "claude" else "claude"
                self.assertIn("hookSpecificOutput", run_event(
                    {**command, "session_id": "chat-one"}, other_provider, state_home=state_home,
                ))

                revoke = f"~/.local/bin/ai-agent-guard-jj-approval.py --provider {provider} --session-action revoke"
                payload = {id_field: "chat-one", "tool_input": {"command": revoke}}
                event = "bind" if provider == "cursor" else "shell"
                result = run_event(payload, provider, event=event, state_home=state_home)
                if provider == "cursor":
                    updated = result["updated_input"]["command"]
                else:
                    self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "allow")
                    updated = result["hookSpecificOutput"]["updatedInput"]["command"]
                self.assertEqual(updated, f"{revoke} --session-id chat-one")
                subprocess.run([str(HOOK), *shlex.split(updated)[1:]], env=env, check=True, capture_output=True)
                self.assertEqual(run_event(command, provider, state_home=state_home), default)

    def test_agent_cannot_grant_by_calling_the_helper_another_way(self) -> None:
        helper = "/home/user/.local/bin/ai-agent-guard-jj-approval.py --provider {provider}"
        for spelling in (
            "{helper} --session-action grant --session-id chat-one",
            "{helper} --session-action=grant --session-id chat-one",
            "python3 {helper} --session-action grant --session-id chat-one",
            "cd /tmp && {helper} --session-action grant --session-id chat-one",
            "bash -c '{helper} --session-action grant --session-id chat-one'",
            "wsl.exe -d arch -u user --exec {helper} --session-action grant",
            "python3 AI/agent-guards/jj-approval.py --provider {provider} --session-action grant --session-id x",
            "eval '{helper} --session-action grant --session-id chat-one'",
            "python3 - --provider {provider} --session-action grant --session-id x < {helper}",
            'eval "$(printf %s \'{helper} --session-action grant\')"',
        ):
            for provider, decision in (("cursor", "ask"), ("claude", "ask"), ("codex", "deny")):
                command = spelling.format(helper=helper.format(provider=provider), provider=provider)
                with self.subTest(command=command), tempfile.TemporaryDirectory() as state_home:
                    result = run_event(
                        {"session_id": "chat-one", "conversation_id": "chat-one", "command": command},
                        provider, state_home=state_home,
                    )
                    if provider == "cursor":
                        self.assertEqual(result["permission"], decision)
                    else:
                        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], decision)

        revoke = helper.format(provider="claude") + " --session-action revoke --session-id chat-one"
        self.assertEqual(run_event({"session_id": "chat-one", "command": revoke}, "claude"), {})

    def test_helper_rejects_abbreviated_options(self) -> None:
        with tempfile.TemporaryDirectory() as state_home:
            completed = subprocess.run(
                [str(HOOK), "--provider", "claude", "--session-a", "grant", "--session-id", "x"],
                env={**os.environ, "XDG_STATE_HOME": state_home},
                capture_output=True, text=True,
            )
            self.assertNotEqual(completed.returncode, 0)
            self.assertFalse(Path(state_home, "ai-agent-jj-approval").exists())

    def test_codex_grant_without_chat_id_is_unavailable(self) -> None:
        helper = "~/.local/bin/ai-agent-guard-jj-approval.py --provider codex --session-action grant"
        output = run_event({"tool_input": {"command": helper}}, "codex")["hookSpecificOutput"]
        self.assertEqual(output["permissionDecision"], "deny")
        self.assertIn("did not supply a chat ID", output["permissionDecisionReason"])

    def test_cursor_binding_leaves_other_shell_commands_alone(self) -> None:
        helper = "~/.local/bin/ai-agent-guard-jj-approval.py --provider cursor --session-action grant"
        for payload in (
            {"conversation_id": "chat", "command": helper + " && jj new"},
            {"conversation_id": "chat", "command": helper + " --session-id other"},
            {"command": helper},
            {"conversation_id": "chat", "prompt": "You can bypass jj hooks."},
        ):
            with self.subTest(payload=payload):
                self.assertEqual(run_event(payload, "cursor", event="bind"), {"permission": "allow"})


if __name__ == "__main__":
    unittest.main()

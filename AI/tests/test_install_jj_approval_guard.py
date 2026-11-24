#!/usr/bin/env python3
import importlib.util
import json
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


INSTALLER = Path(__file__).resolve().parents[1] / "agent-guards" / "install.py"

# Policy blocks that older installers wrote without an end marker.
MARKER = "<!-- dotfiles:jujutsu-ai-approval -->"
LEGACY_POLICY_TEXT = f"""{MARKER}
## Jujutsu AI Approval

AI agents must ask for express approval before running mutating Jujutsu operations, including commits, working-copy movement (`jj new`, `jj edit`, `jj next`, `jj prev`), rebases, squashes, abandons, bookmark changes, undo, or `jj git push`. Read-only inspection such as `jj status`, `jj diff`, `jj log`, `jj show`, and `jj op log` is allowed without approval.
"""
PHRASE_POLICY_TEXT = f"""{MARKER}
## Jujutsu AI Approval

Ask for approval before each mutating Jujutsu operation unless the user grants a chat bypass. Read-only inspection is allowed.

The user can grant approval for all Jujutsu writes in any prompt in this chat, for example by saying "you can bypass jj hooks". Mention this option when asking for approval. The user can send `jj revoke bypass` to restore per-operation checks.
"""
UNMARKED_WINDOWS_POLICY_TEXT = f"""{MARKER}
## Jujutsu AI Approval

Ask for approval before each mutating Jujutsu operation unless the user grants a chat bypass. Read-only inspection is allowed.

When the user directly authorizes all Jujutsu writes in this chat, run `~/.local/bin/ai-agent-guard-jj-approval.py --provider codex --session-action grant` before the first write. Use `--session-action revoke` if the user withdraws approval. Run the helper as a standalone shell call. Use the successful result to confirm the change. Treat approval of a single operation as approval of that operation only.

In PowerShell, use `wsl.exe -d olddistro -u user --exec /home/user/.local/bin/ai-agent-guard-jj-approval.py --provider codex --session-action grant --session-id $env:CODEX_THREAD_ID` for the same operation.
"""


def load_installer():
    spec = importlib.util.spec_from_file_location("jj_guard_installer", INSTALLER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {INSTALLER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class JjApprovalGuardInstallerTests(unittest.TestCase):
    def test_cursor_install_replaces_the_prefilter_and_invokes_the_guard(self) -> None:
        installer = load_installer()
        sample_path = installer.REPO_ROOT / "AI" / ".cursor" / "hooks.json"
        sample_hooks = json.loads(sample_path.read_text())["hooks"]["beforeShellExecution"]
        self.assertNotIn("matcher", sample_hooks[0])

        with tempfile.TemporaryDirectory() as directory:
            installer.HOME = Path(directory)
            installer.GUARD_TARGET = installer.HOME / "ai-agent-guard-jj-approval.py"
            path = installer.HOME / ".cursor" / "hooks.json"
            installer.write_json(path, {"hooks": {"beforeShellExecution": [{
                "command": installer.guard_command("cursor"),
                "matcher": "jj",
            }]}})

            installer.ensure_guard_link()
            installer.install_cursor()

            hooks = json.loads(path.read_text())["hooks"]["beforeShellExecution"]
            self.assertEqual(hooks, [{"command": installer.guard_command("cursor"), "failClosed": True}])
            for command, permission in (
                ("echo \\\n hello", "allow"),
                ("j\\\nj commit -m test", "ask"),
            ):
                with self.subTest(command=command):
                    result = subprocess.run(
                        shlex.split(hooks[0]["command"]),
                        input=json.dumps({"command": command}),
                        capture_output=True,
                        text=True,
                        check=True,
                    )
                    self.assertEqual(json.loads(result.stdout)["permission"], permission)

    def test_migrates_stale_opencode_jj_rules(self) -> None:
        installer = load_installer()
        with tempfile.TemporaryDirectory() as directory:
            installer.HOME = Path(directory)
            path = installer.HOME / ".config" / "opencode" / "opencode.json"
            installer.write_json(path, {"permission": {"bash": {
                "*": "allow",
                "jj git fetch": "allow",
                "jj git fetch*": "allow",
                "jj gf": "allow",
                "jj gf*": "allow",
                "jj config path": "allow",
                "jj config path*": "allow",
                "jj d*": "allow",
                "jj d**": "allow",
                "jj l*": "allow",
                "git push": "ask",
                "jj status": "allow",
                "jj *": "ask",
                "jj new": "deny",
                "jj status *": "deny",
            }}})

            installer.install_opencode()

            rules = json.loads(path.read_text())["permission"]["bash"]
            managed_path = installer.REPO_ROOT / ".config" / "opencode" / "opencode.json"
            managed = json.loads(managed_path.read_text())["permission"]["bash"]
            expected = {"*": "allow", "git push": "ask"}
            expected.update((rule, action) for rule, action in managed.items() if rule.startswith("jj "))
            expected["jj status *"] = "deny"
            expected["jj new"] = "deny"
            self.assertEqual(list(rules.items()), list(expected.items()))
            self.assertEqual(rules["jj config path --user"], "allow")
            self.assertEqual(rules["jj d *"], "allow")
            self.assertNotIn("jj git fetch*", rules)

            with patch.object(installer, "write_json") as write_json:
                installer.install_opencode()
                write_json.assert_not_called()

    def test_replaces_managed_prompt_hooks_and_updates_policy_once(self) -> None:
        for provider, settings, policy, event in (
            ("cursor", ".cursor/hooks.json", None, "beforeSubmitPrompt"),
            ("claude", ".claude/settings.json", ".claude/CLAUDE.md", "UserPromptSubmit"),
            ("codex", ".codex/hooks.json", ".codex/AGENTS.md", "UserPromptSubmit"),
        ):
            with self.subTest(provider=provider), tempfile.TemporaryDirectory() as directory:
                installer = load_installer()
                installer.HOME = Path(directory)
                path = installer.HOME / settings
                unrelated = {"command": "echo keep"}
                if provider != "cursor":
                    unrelated = {"hooks": [{"type": "command", **unrelated}]}
                old_hook = {"command": installer.guard_command(provider, event="prompt")}
                if provider != "cursor":
                    old_hook = {"hooks": [{"type": "command", **old_hook}]}
                installer.write_json(path, {"hooks": {event: [unrelated, old_hook]}})
                if policy:
                    policy_path = installer.HOME / policy
                    previous_policy = (
                        LEGACY_POLICY_TEXT if provider == "claude" else PHRASE_POLICY_TEXT
                    )
                    policy_path.write_text(previous_policy + "\n# Other instructions\n")

                install = getattr(installer, f"install_{provider}")
                install()
                installed = path.read_text()
                install()
                self.assertEqual(path.read_text(), installed)

                hooks = json.loads(installed)["hooks"]
                self.assertEqual(hooks[event], [unrelated])
                if provider == "cursor":
                    self.assertEqual(hooks["preToolUse"], [{
                        "matcher": "Shell",
                        "command": installer.guard_command(provider, event="bind"),
                    }])
                if policy:
                    expected = installer.policy_block(provider)
                    self.assertEqual(policy_path.read_text(), expected + "\n# Other instructions\n")

    def test_policy_reinstall_replaces_the_whole_managed_block(self) -> None:
        installer = load_installer()
        with tempfile.TemporaryDirectory() as directory:
            installer.HOME = Path(directory, "home", "user")
            codex_home = Path(directory, "codex")
            codex_home.mkdir()
            agents = codex_home / "AGENTS.md"
            agents.write_text("# Mine\n\n" + UNMARKED_WINDOWS_POLICY_TEXT + "\nKeep this line.\n")

            installer.install_windows_codex(codex_home, "archlinux")
            first = agents.read_text()
            self.assertNotIn("olddistro", first)
            self.assertNotIn("CODEX_THREAD_ID", first)
            self.assertTrue(first.startswith("# Mine\n\n" + MARKER))
            self.assertTrue(first.endswith(installer.POLICY_END_MARKER + "\n\nKeep this line.\n"))

            installer.install_windows_codex(codex_home, "ubuntu")
            second = agents.read_text()
            self.assertEqual(second.count(MARKER), 1)
            self.assertNotIn("archlinux", second)
            self.assertIn("wsl.exe -d ubuntu", second)

            # A later Linux install drops the Windows-only helper line.
            installer.append_policy(agents, "codex")
            self.assertEqual(
                agents.read_text(),
                "# Mine\n\n" + installer.policy_block("codex") + "\nKeep this line.\n",
            )

    def test_removes_legacy_extensionless_cursor_hook_commands(self) -> None:
        installer = load_installer()
        stale_command = (
            "/home/bosco/.local/share/mise/installs/python/latest/bin/python3 "
            "/home/bosco/.local/bin/ai-agent-guard-jj-approval --provider cursor"
        )
        items = [
            {"command": stale_command},
            {"command": "$HOME/.local/bin/ai-agent-guard-jj-approval --provider cursor"},
            {"command": installer.guard_command("cursor")},
            {"command": "echo keep"},
        ]

        installer.remove_guard_command(items, "cursor")

        self.assertEqual(items, [{"command": "echo keep"}])

    def test_windows_codex_replaces_the_old_adapter_and_preserves_other_hooks(self) -> None:
        installer = load_installer()
        with tempfile.TemporaryDirectory() as directory:
            codex_home = Path(directory)
            path = codex_home / "hooks.json"
            unrelated = {"command": "echo keep"}
            installer.write_json(path, {"hooks": {"PreToolUse": [{
                "matcher": "Bash",
                "hooks": [installer.guard_hook("claude"), unrelated],
            }]}})
            installer.install_windows_codex(codex_home, "archlinux")
            installed = path.read_text()
            installer.install_windows_codex(codex_home, "archlinux")
            self.assertEqual(path.read_text(), installed)
            pre_tool = json.loads(installed)["hooks"]["PreToolUse"]
            self.assertEqual(pre_tool[0]["hooks"], [unrelated])
            command = pre_tool[1]["hooks"][0]["commandWindows"]
            self.assertEqual(command.split()[:3], ["wsl.exe", "-d", "archlinux"])
            self.assertTrue(command.endswith("--provider codex"))
            policy = (codex_home / "AGENTS.md").read_text()
            self.assertIn("wsl.exe -d archlinux", policy)
            self.assertNotIn("--session-id", policy.split("In PowerShell")[1])

    def test_removes_stale_nested_provider_hooks_without_dropping_other_hooks(self) -> None:
        installer = load_installer()
        items = [
            {
                "matcher": "Bash",
                "hooks": [
                    {
                        "type": "command",
                        "command": "$HOME/.local/bin/ai-agent-guard-jj-approval --provider claude",
                    },
                    {
                        "type": "command",
                        "command": "echo keep",
                    },
                ],
            },
            {
                "matcher": "Bash",
                "hooks": [
                    {
                        "type": "command",
                        "command": installer.guard_command("claude"),
                    },
                ],
            },
        ]

        installer.remove_guard_command(items, "claude")

        self.assertEqual(
            items,
            [
                {
                    "matcher": "Bash",
                    "hooks": [
                        {
                            "type": "command",
                            "command": "echo keep",
                        },
                    ],
                },
            ],
        )


if __name__ == "__main__":
    unittest.main()

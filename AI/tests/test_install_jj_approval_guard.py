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

#!/usr/bin/env python3
import importlib.util
import unittest
from pathlib import Path


INSTALLER = Path(__file__).resolve().parents[1] / "agent-guards" / "install.py"


def load_installer():
    spec = importlib.util.spec_from_file_location("jj_guard_installer", INSTALLER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load {INSTALLER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class JjApprovalGuardInstallerTests(unittest.TestCase):
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

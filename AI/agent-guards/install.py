#!/usr/bin/env python3
"""Install AI-agent-only Jujutsu approval guards without touching human shell use."""

from __future__ import annotations

import json
import shlex
import sys
from pathlib import Path
from typing import Any


HOME = Path.home()
REPO_ROOT = Path(__file__).resolve().parents[2]
GUARD = "$HOME/.local/bin/ai-agent-guard-jj-approval.py"
GUARD_SOURCE = Path(__file__).resolve().parent / "jj-approval.py"
GUARD_TARGET = HOME / ".local" / "bin" / "ai-agent-guard-jj-approval.py"
PYTHON = sys.executable
CURSOR_JJ_MATCHER = r"(^|[\s;&|()'\"])jj([\s;&|()'\"]|$)"
POLICY_MARKER = "<!-- dotfiles:jujutsu-ai-approval -->"
LEGACY_POLICY_MARKER = "<!-- dotfiles:jjujutsu-ai-approval -->"
POLICY_TEXT = f"""{POLICY_MARKER}
## Jujutsu AI Approval

AI agents must ask for express approval before running mutating Jujutsu operations, including commits, working-copy movement (`jj new`, `jj edit`, `jj next`, `jj prev`), rebases, squashes, abandons, bookmark changes, undo, or `jj git push`. Read-only inspection such as `jj status`, `jj diff`, `jj log`, `jj show`, and `jj op log` is allowed without approval.
"""


def load_json(path: Path, default: dict[str, Any]) -> dict[str, Any]:
    if not path.exists():
        return default
    with path.open() as source:
        data = json.load(source)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return data


def write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = json.dumps(data, indent=2, sort_keys=False) + "\n"
    if path.exists() and path.read_text() == content:
        return
    path.write_text(content)


def append_once(items: list[Any], item: dict[str, Any]) -> None:
    if item not in items:
        items.append(item)


def remove_guard_command(items: list[Any], provider: str) -> None:
    command = f"{GUARD} --provider {provider}"
    python_command = guard_command(provider)
    items[:] = [
        item
        for item in items
        if not (
            isinstance(item, dict)
            and item.get("command") in {command, python_command}
        )
    ]


def guard_command(provider: str) -> str:
    return f"{shlex.quote(PYTHON)} {shlex.quote(str(GUARD_TARGET))} --provider {provider}"


def ensure_guard_link() -> None:
    GUARD_TARGET.parent.mkdir(parents=True, exist_ok=True)
    if GUARD_TARGET.is_symlink() and GUARD_TARGET.resolve() == GUARD_SOURCE:
        return
    if GUARD_TARGET.is_symlink():
        GUARD_TARGET.unlink()
    elif GUARD_TARGET.exists():
        raise FileExistsError(
            f"{GUARD_TARGET} already exists and is not linked to {GUARD_SOURCE}"
        )
    GUARD_TARGET.symlink_to(GUARD_SOURCE)


def ensure_symlink(source: Path, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.is_symlink() and target.resolve() == source:
        return
    if target.is_symlink():
        target.unlink()
    elif target.exists():
        raise FileExistsError(f"{target} already exists and is not linked to {source}")
    target.symlink_to(source)


def append_policy(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    current = path.read_text() if path.exists() else ""
    if LEGACY_POLICY_MARKER in current:
        path.write_text(current.replace(LEGACY_POLICY_MARKER, POLICY_MARKER))
        return
    if POLICY_MARKER in current:
        return
    separator = "\n\n" if current and not current.endswith("\n\n") else ""
    path.write_text(f"{current}{separator}{POLICY_TEXT}\n")


def install_cursor() -> None:
    ensure_symlink(
        REPO_ROOT / "AI" / ".cursor" / "rules" / "jj-ai-approval.mdc",
        HOME / ".cursor" / "rules" / "jj-ai-approval.mdc",
    )

    path = HOME / ".cursor" / "hooks.json"
    data = load_json(path, {"version": 1, "hooks": {}})
    data.setdefault("version", 1)
    hooks = data.setdefault("hooks", {})
    before_shell = hooks.setdefault("beforeShellExecution", [])
    remove_guard_command(before_shell, "cursor")
    append_once(
        before_shell,
        {
            "command": guard_command("cursor"),
            "matcher": CURSOR_JJ_MATCHER,
            "failClosed": True,
        },
    )
    write_json(path, data)


def install_claude() -> None:
    append_policy(HOME / ".claude" / "CLAUDE.md")

    path = HOME / ".claude" / "settings.json"
    data = load_json(path, {})
    hooks = data.setdefault("hooks", {})
    pre_tool = hooks.setdefault("PreToolUse", [])
    append_once(
        pre_tool,
        {
            "matcher": "Bash",
            "hooks": [
                {
                    "type": "command",
                    "command": guard_command("claude"),
                    "statusMessage": "Checking Jujutsu approval",
                }
            ],
        },
    )
    write_json(path, data)


def install_codex() -> None:
    append_policy(HOME / ".codex" / "AGENTS.md")

    hooks_path = HOME / ".codex" / "hooks.json"
    data = load_json(hooks_path, {"hooks": {}})
    hooks = data.setdefault("hooks", {})
    pre_tool = hooks.setdefault("PreToolUse", [])
    append_once(
        pre_tool,
        {
            "matcher": "Bash",
            "hooks": [
                {
                    "type": "command",
                    "command": guard_command("codex"),
                    "timeout": 30,
                    "statusMessage": "Checking Jujutsu approval",
                }
            ],
        },
    )
    write_json(hooks_path, data)

    config_path = HOME / ".codex" / "config.toml"
    config_path.parent.mkdir(parents=True, exist_ok=True)
    if not config_path.exists():
        config_path.write_text("[features]\ncodex_hooks = true\n")
        return

    lines = config_path.read_text().splitlines()
    if any(line.strip().startswith("codex_hooks") for line in lines):
        updated = [
            "codex_hooks = true" if line.strip().startswith("codex_hooks") else line
            for line in lines
        ]
    else:
        updated = []
        inserted = False
        in_features = False
        for line in lines:
            if line.strip().startswith("[") and line.strip().endswith("]"):
                if in_features and not inserted:
                    updated.append("codex_hooks = true")
                    inserted = True
                in_features = line.strip() == "[features]"
            updated.append(line)
        if in_features and not inserted:
            updated.append("codex_hooks = true")
            inserted = True
        if not inserted:
            updated.extend(["", "[features]", "codex_hooks = true"])
    config_path.write_text("\n".join(updated) + "\n")


def install_opencode() -> None:
    path = HOME / ".config" / "opencode" / "opencode.json"
    data = load_json(path, {"$schema": "https://opencode.ai/config.json"})
    data.setdefault("$schema", "https://opencode.ai/config.json")
    permission = data.setdefault("permission", {})
    if not isinstance(permission, dict):
        raise ValueError("opencode permission must be an object to merge jj guard rules")
    bash = permission.setdefault("bash", {})
    if not isinstance(bash, dict):
        raise ValueError("opencode permission.bash must be an object to merge jj guard rules")

    jj_rules = {
        "jj *": "ask",
        "jj status*": "allow",
        "jj st*": "allow",
        "jj diff*": "allow",
        "jj d*": "allow",
        "jj log*": "allow",
        "jj l*": "allow",
        "jj show*": "allow",
        "jj sh*": "allow",
        "jj op log*": "allow",
        "jj oplog*": "allow",
        "jj config get*": "allow",
        "jj config list*": "allow",
        "jj config path*": "allow",
        "jj bookmark list*": "allow",
        "jj git fetch*": "allow",
        "jj gf*": "allow",
    }
    for pattern, action in jj_rules.items():
        bash[pattern] = action
    write_json(path, data)


def main() -> int:
    ensure_guard_link()
    install_cursor()
    install_claude()
    install_codex()
    install_opencode()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

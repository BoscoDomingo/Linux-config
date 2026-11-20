#!/usr/bin/env python3
"""Install AI-agent-only Jujutsu approval guards without touching human shell use."""

from __future__ import annotations

import argparse
import json
import re
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
POLICY_MARKER = "<!-- dotfiles:jujutsu-ai-approval -->"
LEGACY_POLICY_MARKER = "<!-- dotfiles:jjujutsu-ai-approval -->"
# The end marker lets each install replace the whole managed block.
POLICY_END_MARKER = "<!-- /dotfiles:jujutsu-ai-approval -->"
# Older blocks had no end marker. Their lines start with one of these.
UNMARKED_POLICY_LINES = (
    "## Jujutsu AI Approval",
    "AI agents must ask for express approval before running mutating Jujutsu",
    "Ask for approval before each mutating Jujutsu operation",
    "The user can grant approval for all Jujutsu writes",
    "When the user directly authorizes all Jujutsu writes",
    "In PowerShell, use `",
)
POLICY_TEXT = f"""{POLICY_MARKER}
## Jujutsu AI Approval

Ask for approval before each mutating Jujutsu operation unless the user grants a chat bypass. Read-only inspection is allowed.

When the user directly authorizes all Jujutsu writes in this chat, run `~/.local/bin/ai-agent-guard-jj-approval.py --provider {{provider}} --session-action grant` as a standalone shell call before the first write. The hook asks the user to confirm the grant. If the hook blocks the call instead, give the user the command from the hook message and ask them to run it. Do not run a grant with your own `--session-id`. Use `--session-action revoke` if the user withdraws approval. Treat approval of a single operation as approval of that operation only.
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


def is_guard_command(command: Any, provider: str) -> bool:
    if not isinstance(command, str):
        return False
    return (
        "ai-agent-guard-jj-approval" in command
        and f"--provider {provider}" in command
    )


def remove_guard_command(items: list[Any], provider: str) -> None:
    kept: list[Any] = []
    for item in items:
        if not isinstance(item, dict):
            kept.append(item)
            continue
        if is_guard_command(item.get("command"), provider):
            continue
        if isinstance(item.get("hooks"), list):
            item["hooks"] = [
                hook
                for hook in item["hooks"]
                if not (
                    isinstance(hook, dict)
                    and is_guard_command(hook.get("command"), provider)
                )
            ]
            if not item["hooks"]:
                continue
        kept.append(item)
    items[:] = kept


def guard_hook(provider: str, *, event: str = "shell", **extra: Any) -> dict[str, Any]:
    hook: dict[str, Any] = {
        "type": "command",
        "command": guard_command(provider, event=event),
        "statusMessage": "Checking Jujutsu approval",
    }
    hook.update(extra)
    return hook


def guard_command(provider: str, *, event: str = "shell") -> str:
    command = f"{shlex.quote(PYTHON)} {shlex.quote(str(GUARD_TARGET))} --provider {provider}"
    if event != "shell":
        return f"{command} --event {event}"
    return command


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


def policy_block(provider: str, powershell_helper: str | None = None) -> str:
    policy = POLICY_TEXT.replace("{provider}", provider)
    if powershell_helper is not None:
        policy += f"\nIn PowerShell, use `{powershell_helper}` for the same operation.\n"
    return f"{policy}{POLICY_END_MARKER}\n"


def managed_block_end(text: str, start: int) -> int:
    end_marker = text.find(POLICY_END_MARKER, start)
    if end_marker != -1:
        end = end_marker + len(POLICY_END_MARKER)
        return end + 1 if text.startswith("\n", end) else end
    # Without an end marker, take only lines an older installer wrote, so
    # text the user added after the block stays.
    lines = text[start:].splitlines(keepends=True)
    end = start + len(lines[0])
    offset = end
    for line in lines[1:]:
        offset += len(line)
        if not line.strip():
            continue
        if not line.startswith(UNMARKED_POLICY_LINES):
            break
        end = offset
    return end


def append_policy(path: Path, provider: str, powershell_helper: str | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    current = path.read_text() if path.exists() else ""
    updated = current.replace(LEGACY_POLICY_MARKER, POLICY_MARKER)
    policy = policy_block(provider, powershell_helper)
    start = updated.find(POLICY_MARKER)
    if start == -1:
        separator = "\n\n" if updated and not updated.endswith("\n\n") else ""
        updated = f"{updated}{separator}{policy}\n"
    else:
        # Replace the whole block, so a changed WSL distro or helper takes effect.
        updated = updated[:start] + policy + updated[managed_block_end(updated, start):]
    if updated != current:
        path.write_text(updated)


def remove_prompt_hook(hooks: dict[str, Any], provider: str, event: str) -> None:
    if event in hooks:
        remove_guard_command(hooks[event], provider)
        if not hooks[event]:
            del hooks[event]


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
            # Let the guard parse commands whose spelling spans shell continuations.
            "failClosed": True,
        },
    )
    remove_prompt_hook(hooks, "cursor", "beforeSubmitPrompt")
    pre_tool = hooks.setdefault("preToolUse", [])
    remove_guard_command(pre_tool, "cursor")
    append_once(pre_tool, {"matcher": "Shell", "command": guard_command("cursor", event="bind")})
    write_json(path, data)


def install_claude() -> None:
    append_policy(HOME / ".claude" / "CLAUDE.md", "claude")

    path = HOME / ".claude" / "settings.json"
    data = load_json(path, {})
    hooks = data.setdefault("hooks", {})
    pre_tool = hooks.setdefault("PreToolUse", [])
    remove_guard_command(pre_tool, "claude")
    append_once(
        pre_tool,
        {
            "matcher": "Bash",
            "hooks": [guard_hook("claude")],
        },
    )
    remove_prompt_hook(hooks, "claude", "UserPromptSubmit")
    write_json(path, data)


def install_codex_hooks(codex_home: Path, *, command_windows: str | None = None) -> None:
    hooks_path = codex_home / "hooks.json"
    data = load_json(hooks_path, {"hooks": {}})
    hooks = data.setdefault("hooks", {})
    pre_tool = hooks.setdefault("PreToolUse", [])
    remove_guard_command(pre_tool, "codex")
    hook = guard_hook("codex", timeout=30)
    if command_windows is not None:
        # Remove the obsolete Claude adapter from this Codex hook file.
        remove_guard_command(pre_tool, "claude")
        hook["commandWindows"] = command_windows
    append_once(
        pre_tool,
        {
            "matcher": "Bash",
            "hooks": [hook],
        },
    )
    remove_prompt_hook(hooks, "codex", "UserPromptSubmit")
    write_json(hooks_path, data)


def enable_codex_hooks(codex_home: Path) -> None:
    config_path = codex_home / "config.toml"
    config_path.parent.mkdir(parents=True, exist_ok=True)
    if not config_path.exists():
        config_path.write_text("[features]\ncodex_hooks = true\n")
        return

    current = config_path.read_text()
    lines = current.splitlines()
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
    content = "\n".join(updated) + "\n"
    if content != current:
        config_path.write_text(content)


def install_codex() -> None:
    codex_home = HOME / ".codex"
    append_policy(codex_home / "AGENTS.md", "codex")
    install_codex_hooks(codex_home)
    enable_codex_hooks(codex_home)


def install_windows_codex(codex_home: Path, distro: str) -> None:
    # The Windows shell passes hook JSON on stdin to wsl.exe.
    wsl = f"wsl.exe -d {distro} -u {HOME.name} --exec"
    install_codex_hooks(codex_home, command_windows=f"{wsl} {guard_command('codex')}")
    # The hook supplies the chat ID and returns the grant command for the user.
    helper = f"{wsl} {shlex.quote(str(GUARD_TARGET))} --provider codex --session-action grant"
    append_policy(codex_home / "AGENTS.md", "codex", helper)
    enable_codex_hooks(codex_home)


def install_opencode() -> None:
    path = HOME / ".config" / "opencode" / "opencode.json"
    data = load_json(path, {"$schema": "https://opencode.ai/config.json"})
    original = json.loads(json.dumps(data))
    data.setdefault("$schema", "https://opencode.ai/config.json")
    permission = data.setdefault("permission", {})
    if not isinstance(permission, dict):
        raise ValueError("opencode permission must be an object to merge jj guard rules")
    bash = permission.setdefault("bash", {})
    if not isinstance(bash, dict):
        raise ValueError("opencode permission.bash must be an object to merge jj guard rules")
    original_order = list(bash)

    # Use the repo config as the source for both symlinked and standalone installs.
    managed_path = REPO_ROOT / ".config" / "opencode" / "opencode.json"
    managed_bash = load_json(managed_path, {})["permission"]["bash"]
    jj_rules = {
        pattern: bash[pattern] if bash.get(pattern) in {"ask", "deny"} else action
        for pattern, action in managed_bash.items()
        if pattern.startswith("jj ")
    }
    # Remove old allow rules so they cannot override the new defaults.
    legacy_prefixes = (
        "bookmark list", "config get", "config list", "config path",
        "d", "diff", "gf", "git fetch", "l", "log", "op log", "oplog",
        "sh", "show", "st", "status",
    )
    stale_patterns = {f"jj {prefix}*" for prefix in legacy_prefixes}
    stale_patterns.update({
        "jj config path", "jj d**", "jj gf", "jj git fetch", "jj l**", "jj sh**",
    })
    for pattern in stale_patterns:
        if bash.get(pattern) == "allow":
            del bash[pattern]

    # Replace the managed rules at the old default so custom rules after it still win.
    installed_rules = [
        (pattern, action) for pattern, action in bash.items() if pattern in jj_rules
    ]
    if installed_rules != list(jj_rules.items()):
        anchor = "jj *" if "jj *" in bash else next(
            (pattern for pattern in bash if pattern.startswith("jj ")), None
        )
        updated = {}
        for pattern, action in bash.items():
            if pattern == anchor:
                updated.update(jj_rules)
            if pattern not in jj_rules:
                updated[pattern] = action
        if anchor is None:
            updated.update(jj_rules)
        permission["bash"] = bash = updated
    # Keep hand-formatted, repo-managed JSON untouched when the guard policy is
    # already current. This prevents every Home Manager activation from
    # creating a formatting-only working-copy change.
    if data != original or list(bash) != original_order:
        write_json(path, data)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--windows-codex-home", type=Path)
    parser.add_argument("--wsl-distro")
    args = parser.parse_args()
    if args.windows_codex_home:
        if not args.wsl_distro or not all(
            re.fullmatch(r"[a-zA-Z0-9_.-]+", value) for value in (args.wsl_distro, HOME.name)
        ):
            parser.error("Windows Codex requires a WSL distro and user with simple names")
        ensure_guard_link()
        install_windows_codex(args.windows_codex_home, args.wsl_distro)
        return 0
    if args.wsl_distro:
        parser.error("--wsl-distro requires --windows-codex-home")

    ensure_guard_link()
    install_cursor()
    install_claude()
    install_codex()
    install_opencode()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

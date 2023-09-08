#!/usr/bin/env python3
"""Provider adapters for AI-only Jujutsu approval gates."""

from __future__ import annotations

import argparse
import json
import os
import shlex
import sys
from typing import Any


READ_ONLY_ALIASES = {
    "st",
    "sh",
    "d",
    "l",
    "ls",
    "la",
    "le",
    "ln",
    "lnp",
    "oplog",
    "gf",
}

READ_ONLY_COMMANDS = {
    "status",
    "log",
    "diff",
    "show",
    "root",
    "version",
    "help",
}

GLOBAL_OPTIONS_WITH_VALUES = {
    "-R",
    "--repository",
    "--at-operation",
    "--at-op",
    "--config",
    "--config-file",
    "--color",
}

SEGMENT_BREAKS = {";", "&&", "||", "|", "(", ")"}
SHELL_COMMANDS = {"bash", "sh", "zsh", "fish"}

USER_MESSAGE = (
    "AI agent is trying to run a Jujutsu command that may commit, move the "
    "working copy, rewrite history, change bookmarks, abandon work, undo an "
    "operation, or push. Approve this exact operation?"
)


def load_input() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    return json.loads(raw)


def shell_tokens(command: str) -> list[str]:
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
    lexer.whitespace_split = True
    lexer.commenters = ""
    return list(lexer)


def command_segments(tokens: list[str]):
    segment: list[str] = []
    for token in tokens:
        if token in SEGMENT_BREAKS:
            if segment:
                yield segment
                segment = []
            continue
        segment.append(token)
    if segment:
        yield segment


def skip_global_options(tokens: list[str], index: int) -> int:
    while index < len(tokens):
        token = tokens[index]
        if token == "--":
            return index + 1
        if token in GLOBAL_OPTIONS_WITH_VALUES:
            index += 2
            continue
        if any(token.startswith(option + "=") for option in GLOBAL_OPTIONS_WITH_VALUES):
            index += 1
            continue
        if token.startswith("-"):
            index += 1
            continue
        return index
    return index


def read_only_subcommand(tokens: list[str], index: int) -> bool:
    index = skip_global_options(tokens, index)
    if index >= len(tokens):
        return True

    subcommand = tokens[index]
    rest = tokens[index + 1 :]

    if subcommand in READ_ONLY_ALIASES or subcommand in READ_ONLY_COMMANDS:
        return True

    if subcommand in {"bookmark", "b"}:
        return not rest or rest[0] in {"list"}

    if subcommand == "config":
        return bool(rest) and rest[0] in {"get", "list", "path"}

    if subcommand == "op":
        return bool(rest) and rest[0] in {"log", "show"}

    if subcommand == "file":
        return bool(rest) and rest[0] in {"list", "show"}

    if subcommand in {"git", "g"}:
        return bool(rest) and rest[0] == "fetch"

    if subcommand == "util":
        return bool(rest) and rest[0] in {
            "completion",
            "config-schema",
            "markdown-help",
        }

    return False


def nested_shell_command(segment: list[str], index: int) -> str | None:
    executable = os.path.basename(segment[index])
    if executable not in SHELL_COMMANDS:
        return None

    for offset, token in enumerate(segment[index + 1 :], start=index + 1):
        if token == "-c" or (token.startswith("-") and "c" in token[1:]):
            if offset + 1 < len(segment):
                return segment[offset + 1]
            return None
    return None


def risky_jj_invocation(command: str) -> str | None:
    try:
        tokens = shell_tokens(command)
    except ValueError:
        return command

    for segment in command_segments(tokens):
        for index, token in enumerate(segment):
            if os.path.basename(token) == "jj":
                if not read_only_subcommand(segment, index + 1):
                    return " ".join(segment[index:])
                continue

            nested = nested_shell_command(segment, index)
            if nested:
                risky = risky_jj_invocation(nested)
                if risky:
                    return risky

    return None


def extract_command(hook_input: dict[str, Any]) -> str:
    tool_input = hook_input.get("tool_input")
    if isinstance(tool_input, dict) and isinstance(tool_input.get("command"), str):
        return tool_input["command"]
    if isinstance(hook_input.get("command"), str):
        return hook_input["command"]
    if isinstance(hook_input.get("cmd"), str):
        return hook_input["cmd"]
    return ""


def cursor_response(risky: str | None) -> dict[str, Any]:
    if not risky:
        return {"permission": "allow"}
    return {
        "permission": "ask",
        "user_message": USER_MESSAGE,
        "agent_message": f"Risky Jujutsu command requires express user approval: `{risky}`",
    }


def claude_response(risky: str | None) -> dict[str, Any]:
    if not risky:
        return {}
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": f"{USER_MESSAGE}\n\nCommand: {risky}",
        }
    }


def codex_response(risky: str | None) -> dict[str, Any]:
    if not risky:
        return {}
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "Codex PreToolUse hooks do not currently support interactive "
                f"ask decisions. Ask the user for express approval before this Jujutsu operation: {risky}"
            ),
        }
    }


def classify_response(risky: str | None) -> dict[str, Any]:
    return {"risky": bool(risky), "command": risky}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--provider",
        choices=("cursor", "claude", "codex", "classify"),
        default="cursor",
    )
    args = parser.parse_args()

    try:
        hook_input = load_input()
        risky = risky_jj_invocation(extract_command(hook_input))
        responses = {
            "cursor": cursor_response,
            "claude": claude_response,
            "codex": codex_response,
            "classify": classify_response,
        }
        print(json.dumps(responses[args.provider](risky)))
        return 0
    except Exception as error:
        message = (
            "Could not inspect shell command for Jujutsu safety "
            f"({error}). Require approval before running it."
        )
        if args.provider == "claude":
            print(
                json.dumps(
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PreToolUse",
                            "permissionDecision": "ask",
                            "permissionDecisionReason": message,
                        }
                    }
                )
            )
            return 0
        if args.provider == "codex":
            print(
                json.dumps(
                    {
                        "hookSpecificOutput": {
                            "hookEventName": "PreToolUse",
                            "permissionDecision": "deny",
                            "permissionDecisionReason": message,
                        }
                    }
                )
            )
            return 0
        print(json.dumps({"permission": "ask", "user_message": message}))
        return 0


if __name__ == "__main__":
    raise SystemExit(main())

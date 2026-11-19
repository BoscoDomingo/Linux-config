#!/usr/bin/env python3
"""Provider adapters for AI-only Jujutsu approval gates."""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import sys
from typing import Any


# Inspection commands in jj 0.47.1 and aliases from the managed jj config.
# Normal inspection can still trigger jj's automatic working-copy snapshot.
READ_ONLY_SUBCOMMANDS = {
    (): {
        "diff", "evolog", "evolution-log", "help", "interdiff", "log", "root",
        "show", "status", "version",
        "d", "l", "la", "lc", "ld", "le", "ln", "lnp", "ls", "oplog",
        "sh", "shp", "shs", "st", "wl",
    },
    ("bookmark",): {"list", "l"},
    ("config",): {"get", "g", "list", "l"},
    ("debug",): {
        "copy-detection", "fileset", "index", "local-working-copy", "revset",
        "stacked-table", "template", "tree", "working-copy",
    },
    ("debug", "object"): {"commit", "file", "operation", "symlink", "tree", "view"},
    ("debug", "watchman"): {"status", "query-clock", "query-changed-files"},
    ("file",): {"annotate", "list", "search", "show"},
    ("git",): {"root"},
    ("git", "colocation"): {"status"},
    ("git", "remote"): {"list"},
    ("operation",): {"diff", "log", "show"},
    ("sparse",): {"list"},
    ("tag",): {"list", "l"},
    ("util",): {"completion", "config-schema", "diff", "markdown-help"},
    ("util", "backend"): {"name"},
    ("workspace",): {"list", "root"},
}

COMMAND_ALIASES = {
    ("b",): ("bookmark",),
    ("g",): ("git",),
    ("gp",): ("git", "push"),
    ("op",): ("operation",),
    ("slv",): ("resolve",),
    ("w",): ("workspace",),
    ("config", "p"): ("config", "path"),
}

# These commands only inspect state when a specific option is present.
READ_ONLY_OPTIONS = {
    ("config", "path"): ({"--user"}, set()),
    ("git", "push"): (
        {"--dry-run"},
        {
            "-b", "--bookmark", "--branch", "-c", "--change", "--named", "-o",
            "--option", "-r", "--revision", "--revisions", "--remote", "-t", "--tag",
        },
    ),
    ("resolve",): ({"-l", "--list"}, {"-r", "--revision", "--tool"}),
}

COMMAND_GROUPS = set(READ_ONLY_SUBCOMMANDS) | {("bisect",), ("gerrit",)}
HELP_OPTIONS = {"-h", "--help"}

GLOBAL_OPTIONS_WITH_VALUES = {
    "-R",
    "--repository",
    "--at-operation",
    "--at-op",
    "--config",
    "--config-file",
    "--color",
}

GLOBAL_FLAGS = {
    "--ignore-working-copy",
    "--no-integrate-operation",
    "--ignore-immutable",
    "--debug",
    "--quiet",
    "--no-pager",
}

# Keep operators separate from quoted or escaped words before removing quotes.
SHELL_TOKEN = re.compile(
    r"""(?P<space>[ \t\r]+|\\\n)|(?P<comment>\#[^\n]*)"""
    r"""|(?P<redirect>(?:[0-9]+)?(?:<<<|<<-?|<>|<&|<|>\||>&|>>?)|&>>?)"""
    r"""|(?P<separator>\n|&&|\|\||\|&|[;&|()])"""
    r"""|(?P<word>(?:'[^']*'|"(?:\\[\s\S]|[^"\\])*"|\\[\s\S]|[^\s'"\\;&|()<>])+)"""
)
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


def command_segments(command: str):
    segment: list[str] = []
    redirect_target = False
    offset = 0
    while offset < len(command):
        match = SHELL_TOKEN.match(command, offset)
        if match is None:
            raise ValueError("Unrecognized shell syntax")
        offset = match.end()
        kind = match.lastgroup
        token = match.group()
        # shlex retains escaped newlines that a shell removes before splitting words.
        if kind != "comment" and "\\\n" in token:
            raise ValueError("Shell line continuation requires inspection")
        if kind in {"space", "comment"}:
            continue
        if redirect_target:
            if kind != "word":
                raise ValueError("Missing shell redirection target")
            redirect_target = False
            continue
        if kind == "redirect":
            if token.lstrip("0123456789") in {"<<", "<<-"}:
                raise ValueError("Shell here-document requires inspection")
            redirect_target = True
        elif kind == "separator":
            if segment:
                yield segment
                segment = []
        else:
            segment.extend(shlex.split(token))
    if redirect_target:
        raise ValueError("Missing shell redirection target")
    if segment:
        yield segment


def skip_global_options(tokens: list[str], index: int) -> int:
    while index < len(tokens):
        token = tokens[index]
        if token in GLOBAL_OPTIONS_WITH_VALUES:
            index += 2
        elif (
            token in GLOBAL_FLAGS
            or token.startswith("-R") and len(token) > 2
            or token.partition("=")[0] in GLOBAL_OPTIONS_WITH_VALUES and "=" in token
        ):
            index += 1
        else:
            break
    return index


def has_read_only_option(tokens: list[str], path: tuple[str, ...]) -> bool:
    read_only_flags, options_with_values = READ_ONLY_OPTIONS[path]
    skip_value = False
    for token in tokens:
        if skip_value:
            skip_value = False
        elif token == "--":
            break
        elif token in options_with_values or token in GLOBAL_OPTIONS_WITH_VALUES:
            skip_value = True
        elif token in read_only_flags:
            return True
    return False


def read_only_subcommand(tokens: list[str], index: int) -> bool:
    path: tuple[str, ...] = ()
    while path in COMMAND_GROUPS:
        index = skip_global_options(tokens, index)
        if index >= len(tokens) or tokens[index] in HELP_OPTIONS:
            return True
        if not path and tokens[index] in {"-V", "--version"}:
            return True

        subcommand = tokens[index]
        if subcommand in READ_ONLY_SUBCOMMANDS.get(path, ()):
            return True

        path = (*path, subcommand)
        path = COMMAND_ALIASES.get(path, path)
        index += 1

    help_index = skip_global_options(tokens, index)
    if help_index < len(tokens) and tokens[help_index] in HELP_OPTIONS:
        return True
    return path in READ_ONLY_OPTIONS and has_read_only_option(tokens[index:], path)


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
        segments = list(command_segments(command))
    except ValueError:
        return command

    for segment in segments:
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

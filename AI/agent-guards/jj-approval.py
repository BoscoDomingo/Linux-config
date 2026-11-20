#!/usr/bin/env python3
"""Provider adapters for AI-only Jujutsu approval gates."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shlex
import sys
from pathlib import Path
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
SHELL_WORD_PART = re.compile(r"""'[^']*'|"(?:\\[\s\S]|[^"\\])*"|\\[\s\S]""")
SHELL_ESCAPE = re.compile(r"\\[\s\S]")
SHELL_COMMANDS = {"bash", "sh", "zsh", "fish"}

GUARD_TOOL = "~/.local/bin/ai-agent-guard-jj-approval.py"
# Names the helper can run under: the installed link, and the repo source.
GUARD_NAMES = {"ai-agent-guard-jj-approval.py", "ai-agent-guard-jj-approval", "jj-approval.py"}
GRANT_MESSAGE = (
    "AI agent wants to allow all Jujutsu writes in this chat, including pushes, "
    "without asking again. Approve the chat bypass?"
)
SESSION_BYPASS_MESSAGE = (
    'To allow all Jujutsu writes in this chat, tell the agent, '
    'for example, "you can bypass jj hooks".'
)

USER_MESSAGE = (
    "AI agent is trying to run a Jujutsu command that may commit, move the "
    "working copy, rewrite history, change bookmarks, abandon work, undo an "
    f"operation, or push. Approve this exact operation? {SESSION_BYPASS_MESSAGE}"
)


def load_input() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    return json.loads(raw)


def join_shell_lines(command: str) -> str:
    # Join continuations before lexing operators. Preserve comments, single quotes,
    # and escaped backslashes because their newlines are literal.
    def remove_continuation(match: re.Match[str]) -> str:
        token = match.group()
        return "" if token == "\\\n" else token

    def join_word_part(match: re.Match[str]) -> str:
        token = match.group()
        if token.startswith('"'):
            return SHELL_ESCAPE.sub(remove_continuation, token)
        return remove_continuation(match)

    def join_token(match: re.Match[str]) -> str:
        token = match.group()
        if match.lastgroup == "space":
            return token.replace("\\\n", "")
        if match.lastgroup == "word":
            return SHELL_WORD_PART.sub(join_word_part, token)
        return token

    return SHELL_TOKEN.sub(join_token, command)


def command_segments(command: str):
    if "\\\n" in command:
        command = join_shell_lines(command)
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


def grants_session(segment: list[str], index: int) -> bool:
    if os.path.basename(segment[index]) not in GUARD_NAMES:
        return False
    args = segment[index + 1 :]
    return "--session-action=grant" in args or any(
        token == "--session-action" and value == "grant"
        for token, value in zip(args, args[1:])
    )


def requests_grant(command: str) -> bool:
    # A grant turns off the gate for the whole chat, so the user must confirm
    # it however the agent spells the helper call (extra flags, nested shells).
    try:
        segments = list(command_segments(command))
    except ValueError:
        return False  # The jj check asks for approval of unparsable commands.
    for segment in segments:
        for index in range(len(segment)):
            if grants_session(segment, index):
                return True
            nested = nested_shell_command(segment, index)
            if nested and requests_grant(nested):
                return True
    return False


def extract_command(hook_input: dict[str, Any]) -> str:
    tool_input = hook_input.get("tool_input")
    if isinstance(tool_input, dict) and isinstance(tool_input.get("command"), str):
        return tool_input["command"]
    if isinstance(hook_input.get("command"), str):
        return hook_input["command"]
    if isinstance(hook_input.get("cmd"), str):
        return hook_input["cmd"]
    return ""


def hook_session_id(provider: str, hook_input: dict[str, Any]) -> str | None:
    field = "conversation_id" if provider == "cursor" else "session_id"
    session = hook_input.get(field)
    return session if isinstance(session, str) and session.strip() else None


def session_grant(provider: str, session: str) -> Path:
    # Use the provider's ID as data, never as a path.
    digest = hashlib.sha256(f"{provider}\0{session}".encode()).hexdigest()
    state_home = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
    return state_home / "ai-agent-jj-approval" / digest


def bind_session_action(
    provider: str, command: str, hook_input: dict[str, Any],
) -> dict[str, Any] | None:
    # Bind only the dedicated helper, with no shell operators or extra arguments.
    prefix = f"{GUARD_TOOL} --provider {provider} --session-action "
    if command.strip() not in {prefix + "grant", prefix + "revoke"}:
        return None

    session = hook_session_id(provider, hook_input)
    if session is None:
        return None
    grant = command.strip().endswith("grant")
    if grant and provider == "codex":
        return grant_response(provider, hook_input)

    updated_command = f"{command.strip()} --session-id {shlex.quote(session)}"
    tool_input = hook_input.get("tool_input")
    updated_input = {**tool_input, "command": updated_command} if isinstance(tool_input, dict) else {
        "command": updated_command,
    }
    if provider == "cursor":
        # beforeShellExecution then sees the bound grant and asks the user.
        return {"permission": "allow", "updated_input": updated_input}

    output: dict[str, Any] = {
        "hookEventName": "PreToolUse",
        # Only the user can grant the bypass. Revoking only adds checks.
        "permissionDecision": "ask" if grant else "allow",
        "updatedInput": updated_input,
    }
    if grant:
        output["permissionDecisionReason"] = GRANT_MESSAGE
    return {"hookSpecificOutput": output}


def grant_response(provider: str, hook_input: dict[str, Any]) -> dict[str, Any]:
    if provider == "cursor":
        return {
            "permission": "ask",
            "user_message": GRANT_MESSAGE,
            "agent_message": "The user must approve the Jujutsu chat bypass.",
        }
    if provider == "claude":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": GRANT_MESSAGE,
            }
        }

    # Codex hooks cannot ask, so the user runs the grant outside the agent.
    session = hook_session_id(provider, hook_input)
    if session is None:
        reason = (
            "Codex did not supply a chat ID, so the Jujutsu chat bypass is not "
            "available. Ask the user to approve each Jujutsu write."
        )
    else:
        user_command = (
            f"{GUARD_TOOL} --provider codex --session-action grant "
            f"--session-id {shlex.quote(session)}"
        )
        reason = (
            "Only the user can grant the Jujutsu chat bypass, and Codex cannot ask "
            "from this hook. Do not run the grant yourself. Ask the user to run "
            f"this command in their own Linux or WSL terminal: `{user_command}`"
        )
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def update_session_grant(provider: str, session: str, action: str) -> None:
    grant = session_grant(provider, session)
    if action == "grant":
        grant.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        grant.touch(mode=0o600)
    else:
        grant.unlink(missing_ok=True)


def cursor_response(risky: str | None) -> dict[str, Any]:
    if not risky:
        return {"permission": "allow"}
    return {
        "permission": "ask",
        "user_message": USER_MESSAGE,
        "agent_message": (
            f"Risky Jujutsu command requires express user approval: `{risky}`. "
            f"{SESSION_BYPASS_MESSAGE}"
        ),
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
                f"Jujutsu operation blocked: {risky}. "
                "Codex cannot ask for approval from this hook. "
                f"{SESSION_BYPASS_MESSAGE}"
            ),
        }
    }


def classify_response(risky: str | None) -> dict[str, Any]:
    return {"risky": bool(risky), "command": risky}


def main() -> int:
    # No abbreviations, so requests_grant sees every spelling of --session-action.
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument(
        "--provider",
        choices=("cursor", "claude", "codex", "classify"),
        default="cursor",
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--event", choices=("shell", "bind"), default="shell")
    mode.add_argument("--session-action", choices=("grant", "revoke"))
    parser.add_argument("--session-id")
    args = parser.parse_args()

    if args.session_action:
        if args.provider == "classify":
            parser.error("classify only supports shell input")
        session = args.session_id
        if not session or not session.strip():
            parser.error("the agent hook needs to supply a chat ID")
        try:
            update_session_grant(args.provider, session, args.session_action)
        except OSError as error:
            parser.exit(1, f"Could not update the Jujutsu chat grant: {error}\n")
        result = "recorded" if args.session_action == "grant" else "revoked"
        print(f"Jujutsu chat grant {result}.")
        return 0

    try:
        hook_input = load_input()
        command = extract_command(hook_input)
        if args.provider in {"claude", "codex"} or args.event == "bind":
            bound = bind_session_action(args.provider, command, hook_input)
            if bound is not None:
                print(json.dumps(bound))
                return 0
        if args.event == "bind":
            print(json.dumps({"permission": "allow"}))
            return 0
        if args.provider != "classify" and requests_grant(command):
            print(json.dumps(grant_response(args.provider, hook_input)))
            return 0

        risky = risky_jj_invocation(command)
        if risky and args.provider != "classify":
            session = hook_session_id(args.provider, hook_input)
            if session is not None and session_grant(args.provider, session).is_file():
                risky = None
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

# 2026-09-20 Use Go for bdot

Decision: Use Go for the initial implementation of `bdot`, Bosco's Dotfiles CLI.
Keep Rust as an option if requirements or maintenance preferences change, not
as a planned rewrite.

## Context

`bdot` will provide package search, interactive selection, saved package
declarations, and Home Manager activation. It will start as a CLI with an
external `fzf` picker. A full terminal UI is a possible later addition.

## Options considered

1. Go, with Cobra for commands and completion, and an external `fzf` picker.

2. Rust, with clap for commands, clap_complete for completion, and an external
   `fzf` picker. Ratatui is an option for a later terminal UI.

3. Bash with `jq` and `fzf`, consistent with existing repository scripts.

## Rationale for decision

Bosco can maintain Go more easily than Rust. Go provides structured data
handling, testing, and a compiled binary without requiring a separate language
runtime. These benefits fit a tool that must update files and handle build and
activation failures more reliably than a growing shell script.

Keep package operations separate from the picker so a later terminal UI can
reuse them. A full terminal UI does not require a language change. Reconsider
Rust only if changed requirements or maintenance preferences justify the cost
of migration.

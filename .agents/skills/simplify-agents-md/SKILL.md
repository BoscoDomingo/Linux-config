---
name: simplify-agents-md
description: Refactor all `AGENTS.md` files into concise, high-signal versions.
---

# Simplify Agents MD

Refactor all `AGENTS.md` files into concise, high-signal versions.

Goals:
- Keep under 200 lines (hard max 250).
- Preserve only repo-specific, actionable instructions.
- Move detailed procedures into referenced docs under the correct `docs/` directories.
- Remove duplicates, generic advice, and model-specific fluff.
- Keep explicit command policy (approved wrappers only), testing expectations, and safety constraints.
- Ensure monorepo guidance includes precedence order for nested AGENTS.md files.
- End with a "References" section linking every moved detail.

Output:
1) Revised `AGENTS.md` for the root and any potential subproject
2) List of content moved out + destination file paths
3) Any unresolved ambiguities as bullet questions
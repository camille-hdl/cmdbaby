---
name: unslop-agent
description: Unslop prose before delivering it, by running pstack's user-invoked `unslop` pass from its installed SKILL.md. Use when you finish a text a human will read (doc, README, PR description, commit message, brief, report, message), or when a skill or the user asks for `unslop`.
---

# Unslop (agent relay)

pstack's `unslop` sets `disable-model-invocation: true`, so the Skill tool refuses it. Reading its `SKILL.md` is the invocation. This relay carries no rules of its own and follows every `npx skills update` of pstack.

1. Read the first of these files that exists:
   - `~/.agents/skills/unslop/SKILL.md` (global install)
   - `.agents/skills/unslop/SKILL.md` in the current project
   - `.claude/skills/unslop/SKILL.md` in the current project

   If none exists, deliver the text and say that the unslop pass did not run because `unslop` is not installed.
2. Run its process on the text: check every numbered pattern against every paragraph, then rewrite. The step is done when the rewritten text replaces the draft, not when you have listed findings.
3. When you hand the text back, add one line outside the text itself: "unslop pass applied", plus anything the skill asks you to report.

<!--
Personal cross-agent instructions (AGENTS.md convention).

Symlinked by devpod-setup/setup.sh into each agent's expected user-level path:
  ~/.claude/CLAUDE.md  (Claude Code)
  add more here as needed (e.g. ~/.gemini/GEMINI.md, ~/.codex/AGENTS.md)

Keep it short — loaded into every turn, so every line is recurring tokens.
Prefer positive instructions ("do X") over negative ones ("don't Y").
Skip info that's cheap to look up; include shortcuts (paths, commands,
conventions) that would otherwise cost many turns to rediscover.
-->

- If you find yourself correcting me on the same workflow/style point twice, propose a one-line addition to this file.
- Prefer commands already in `~/.claude/settings.json` permissions.allow. When a safe, read-only command keeps prompting, suggest adding it (or invoke the `fewer-permission-prompts` skill periodically).


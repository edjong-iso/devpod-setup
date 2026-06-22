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
- In inline scripts (`python -c '...'`, heredocs, etc.), never put `#` at the start of a line inside the quoted body — the path-validation guard treats newline+`#` as a comment that can hide args. Strip comments, or write to a temp file and execute that.
- Run Python in this repo with `uv run python ...` (never `.venv/bin/python` or bare `python`).
- When you need env vars in front of an allowlisted command (e.g. `uv run`), use `env VAR1=v1 VAR2=v2 uv run ...` instead of `VAR1=v1 VAR2=v2 uv run ...` — the permission matcher is prefix-based, so `env ...` matches `Bash(env *)` and avoids the prompt-per-combination explosion.
- For multi-step log/data analysis, write a small script and run it with `uv run python <file>` instead of compound shell (`VAR=…; grep …; $(...)`) — shell var-assignment and command substitution can't be statically analyzed and always prompt.
- Keep git/read-only inspection commands plain so they match the `Bash(git *)` allowlist — no leading `VAR=…` and no `$(…)`. Need a computed ref (e.g. merge-base)? Run it as its own plain `git` command and reuse the literal, rather than inlining `$(git merge-base …)`.


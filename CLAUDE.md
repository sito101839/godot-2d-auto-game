# godot-2d-auto-game

## GodotPrompter

This is a Godot project with GodotPrompter skills available. Before implementing any game system, check for a matching `godot-prompter:*` skill and invoke it. This applies to agents, subagents, and sessions working in this repository.

Key skills: `godot-prompter:godot-brainstorming`, `godot-prompter:scene-organization`, `godot-prompter:component-system`, `godot-prompter:resource-pattern`, `godot-prompter:godot-ui`, `godot-prompter:hud-system`, `godot-prompter:save-load`, `godot-prompter:godot-testing`, `godot-prompter:ai-navigation`, `godot-prompter:audio-system`.

For the full skill list, invoke `godot-prompter:using-godot-prompter`.

## Project Rules

- Use `.codex/skills/godot-auto-battle-quality` for project quality gates and long-running validation.
- Follow `.codex/rules/quality-gates.md` before reporting implementation work complete.
- Follow `.codex/rules/skills-routing.md` when deciding which GodotPrompter skill to load.
- For large instructions, work on a `codex/` branch. Commit at sensible implementation boundaries after checks pass. Merge to `main` only after the user reviews and explicitly says OK.

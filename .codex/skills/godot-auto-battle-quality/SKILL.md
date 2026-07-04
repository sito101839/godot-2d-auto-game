---
name: godot-auto-battle-quality
description: Use when working on this Godot auto-battle project's quality gates, long-running implementation validation, smoke tests, balance simulations, beta checklist updates, or debugging regressions in guild progression, yearly cycles, saves, UI state, and battle behavior.
---

# Godot Auto Battle Quality

Use this skill for long-running implementation work in `godot-2d-auto-game`, especially before claiming a feature is complete.

## Core Workflow

1. Start with `godot --headless --path . --quit` after script or scene edits.
2. Run targeted smoke tests for the touched behavior.
3. Run `scripts/tools/run_quality_checks.ps1` before finalizing broad work.
4. Use `scripts/tools/run_quality_checks.ps1 -IncludeBalance` when battle tuning, enemy scaling, class stats, target selection, or formation behavior changed.
5. Treat `SMOKE_TEST_PASS ...` as the success source, not Godot's exit code alone.
6. Update `docs/checklists/beta-quality-checklist.md` when β scope changes or a checklist item becomes proven.

## Branch And Commit Workflow

1. For large or open-ended user requests, create or switch to a `codex/` work branch before editing.
2. Keep implementation commits aligned to coherent milestones: feature slice, validation infrastructure, docs/rules update, or focused bug fix.
3. Before committing, run the quality gate that matches the change size.
4. Commit when the user asks to commit, after reporting the validation evidence.
5. Leave `main` untouched until the user reviews the branch and explicitly approves merging to `main`.
6. Do not push unless the user explicitly asks for it.

## Available Commands

```powershell
godot --headless --path . --quit
.\scripts\tools\run_smoke_tests.ps1
.\scripts\tools\run_quality_checks.ps1
.\scripts\tools\run_quality_checks.ps1 -IncludeBalance
```

The runner writes logs under `.godot/smoke_test_logs/`.

## Smoke Test Map

- `hello_world_smoke_test.gd`: legacy scene bootstrap.
- `target_selection_smoke_test.gd`: target policy priority.
- `battle_smoke_test.gd`: battle scene integration, setup screen, effects, result return.
- `guild_progression_smoke_test.gd`: battle rewards, XP, calendar advance.
- `guild_year_cycle_smoke_test.gd`: one-year cycle and save/load.
- `guild_three_year_smoke_test.gd`: three-year β cycle, graduation, recruits, save/load.
- `ui_state_smoke_test.gd`: Japanese UI state and tournament training lockout.
- `balance_sample_smoke_test.gd`: optional sample battle distribution and finish-time check.

## Debugging Rules

- If a smoke test fails, inspect its log in `.godot/smoke_test_logs/` before editing.
- If a failure involves dynamic UI, verify the scene path first. This project uses `UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows`.
- If a failure involves typed GDScript in helper tests, prefer `Node`, `CharacterBody2D`, `get(...)`, and `call(...)` in smoke tests.
- If a nonzero Godot exit occurs with a pass marker and no fatal output, the runner can still treat it as pass. Fatal output wins over pass markers.

## Completion Bar

For implementation tasks touching gameplay, progression, UI, save/load, or battle balance, do not call the work complete until:

- `godot --headless --path . --quit` passes.
- Relevant targeted smoke tests pass.
- `.\scripts\tools\run_quality_checks.ps1` passes.
- `git diff --check` passes.
- README/docs/checklists are updated when commands or user-visible behavior changed.

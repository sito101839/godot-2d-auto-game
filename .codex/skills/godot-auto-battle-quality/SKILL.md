---
name: godot-auto-battle-quality
description: Use when working on this Godot auto-battle project's quality gates, long-running implementation validation, smoke tests, balance review, beta checklist updates, or debugging regressions in guild progression, yearly cycles, saves, UI state, and battle behavior.
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
7. For GUI layout or UX quality work, capture Viewport screenshots in normal GUI mode and inspect the PNGs before claiming visual quality.

## Branch And Commit Workflow

1. For large or open-ended user requests, create or switch to a `codex/` work branch before editing.
2. Keep implementation commits aligned to coherent milestones: feature slice, validation infrastructure, docs/rules update, or focused bug fix.
3. Before committing, run the quality gate that matches the change size.
4. Commit when the user asks to commit, after reporting the validation evidence.
5. Leave `main` untouched until the user reviews the branch and explicitly approves merging to `main`.
6. When the user approves merging a work branch to `main`, merge it and push `main` as part of the same handoff.
7. Do not push feature/work branches unless the user explicitly asks for it.

## Available Commands

```powershell
godot --headless --path . --quit
.\scripts\tools\run_smoke_tests.ps1
.\scripts\tools\run_quality_checks.ps1
.\scripts\tools\run_quality_checks.ps1 -IncludeBalance
godot --path . --script res://scripts/tools/capture_guild_hall_screenshot.gd
```

The runner writes logs under `.godot/smoke_test_logs/`.
The screenshot capture tool writes GUI-rendered PNGs under `.godot/screenshots/`.

## Balance Design Review

Use this as a lightweight design check when changing class stats, traits, missions, rewards, guild ranks, enemy scaling, target selection, movement, formations, attack timing, or battle feedback.

Current project stage: content is still sparse and tuning changes are large. Do not require win-rate validation, large simulation batches, strict DPS targets, or fixed battle-duration targets as completion gates yet. Treat those metrics as things to consider and report qualitatively unless the user explicitly asks for deeper tuning.

For balance-sensitive changes:

1. State the player-facing purpose: what decision, tension, reward, readability, or role distinction the change should create.
2. List the changed tuning knobs, such as HP, attack power, range, speed, attack interval, XP, Gold, Fame, rank thresholds, enemy level scaling, mission multipliers, role movement, or targeting priority.
3. Explain likely impact on the current prototype:
   - battle length, only as a rough expectation
   - blue/red advantage, only as a rough expectation
   - damage dealt/taken and survival shape
   - XP/Gold/Fame pace
   - rank progression and recruit/enemy scaling
   - whether any class, trait, mission, target policy, or formation becomes too dominant or useless
   - whether the player can understand why a battle was won or lost from the result UI
4. Keep important tuning values in named constants, definitions, resources, or docs. Avoid burying major balance numbers in behavior code.
5. Run `scripts/tools/run_quality_checks.ps1 -IncludeBalance` when the change touches combat tuning, enemy scaling, class stats, target selection, movement, or formation behavior. Interpret `balance_sample_smoke_test.gd` as a lightweight finish-time/regression sample, not a win-rate proof.
6. Summarize remaining balance risks instead of claiming final balance.

## GUI Screenshot Review

Use this for screen layout, visual density, clipping, readability, and UX quality checks:

```powershell
godot --path . --script res://scripts/tools/capture_guild_hall_screenshot.gd
```

Important details:

- Run it in normal GUI mode. `--headless` uses a dummy renderer and cannot reliably provide Viewport textures.
- Inspect the generated files with `view_image`, especially:
  - `.godot/screenshots/guild_hall_overview.png`
  - `.godot/screenshots/guild_hall_formation.png`
  - `.godot/screenshots/guild_hall_roster.png`
  - `.godot/screenshots/guild_hall_reports.png`
- Do not call UI quality complete from parse checks or label-state smoke tests alone when the user is concerned about real screen appearance.
- If a screenshot shows clipping, cramped layout, text overflow, or important actions below the visible area, fix the layout and capture screenshots again.

## Smoke Test Map

- `hello_world_smoke_test.gd`: legacy scene bootstrap.
- `target_selection_smoke_test.gd`: target policy priority.
- `battle_smoke_test.gd`: battle scene integration, setup screen, effects, result return.
- `guild_progression_smoke_test.gd`: battle rewards, XP, calendar advance.
- `guild_year_cycle_smoke_test.gd`: one-year cycle and save/load.
- `guild_three_year_smoke_test.gd`: three-year β cycle, graduation, recruits, save/load.
- `ui_state_smoke_test.gd`: Japanese UI state and tournament training lockout.
- `ux_flow_smoke_test.gd`: guild hall screen flow, tabs, action grouping, and UX structure.
- `capture_guild_hall_screenshot.gd`: GUI-mode Viewport PNG capture for visual review.
- `balance_sample_smoke_test.gd`: optional lightweight battle completion and finish-time regression sample; not a win-rate validation gate.

## Debugging Rules

- If a smoke test fails, inspect its log in `.godot/smoke_test_logs/` before editing.
- If a failure involves dynamic UI, verify the scene path first. This project uses `UI/PrepPanel/MarginContainer/PrepContent/RosterScroll/ConfigRows`.
- If a failure involves typed GDScript in helper tests, prefer `Node`, `CharacterBody2D`, `get(...)`, and `call(...)` in smoke tests.
- If a nonzero Godot exit occurs with a pass marker and no fatal output, the runner can still treat it as pass. Fatal output wins over pass markers.

## Completion Bar

For implementation tasks touching gameplay, progression, UI, save/load, or battle balance, do not call the work complete until:

- `godot --headless --path . --quit` passes.
- Relevant targeted smoke tests pass.
- GUI screenshots have been captured and inspected when the task touches screen layout, density, readability, or visual UX.
- `.\scripts\tools\run_quality_checks.ps1` passes.
- `git diff --check` passes.
- README/docs/checklists are updated when commands or user-visible behavior changed.

# Quality Gates

These rules apply to work in this repository.

## Required Checks

- Run `godot --headless --path . --quit` after Godot script or scene changes.
- Run `.\scripts\tools\run_quality_checks.ps1` before calling broad gameplay, progression, UI, or save/load work complete.
- Run `.\scripts\tools\run_quality_checks.ps1 -IncludeBalance` when changing battle stats, class stats, target selection, movement, formations, enemy scaling, or attack effects.
- For UI layout/readability/visual UX changes, run `godot --path . --script res://scripts/tools/capture_guild_hall_screenshot.gd` in normal GUI mode and inspect the generated PNGs under `.godot/screenshots/`.
- Run `git diff --check` before final reporting.

## Evidence Rules

- Prefer deterministic `SMOKE_TEST_PASS ...` markers over exit codes.
- Save logs under `.godot/smoke_test_logs/` and inspect logs when failures occur.
- Do not claim β-cycle completion without `SMOKE_TEST_PASS guild_three_year_cycle`.
- Do not claim save/load completion without a smoke test that mutates state after save and proves load restores it.
- Do not claim UI completion when only code parses; verify UI state with a smoke test when button state, labels, or screen flow changed.
- Do not claim visual UI quality when only headless checks pass; use GUI-mode Viewport screenshots for clipping, density, and readability.

## Documentation Rules

- Update `README.md` when player-facing commands or behavior change.
- Update `docs/godot-prompter/plans/beta-implementation-plan.md` when β scope changes.
- Update `docs/checklists/beta-quality-checklist.md` when an item becomes implemented and verified.

## Git Rules

- Keep work on a `codex/` branch unless the user says otherwise.
- For large or open-ended implementation requests, create or switch to a suitable `codex/` branch before starting edits.
- Commit at sensible implementation boundaries after the relevant quality gates pass.
- Commit when the user asks to commit after reviewing the work.
- Do not merge to `main` until the user has reviewed the branch and explicitly said OK to merge.
- Treat approval to merge a work branch to `main` as approval to push `main` after the merge succeeds.
- Do not push feature/work branches without explicit user approval.
- Do not revert unrelated user changes.

# SWE Simulator: agent instructions

Shared instructions for every coding agent. `.claude/CLAUDE.md` and `.code/AGENTS.md` are symlinks to this file; edit only this one.

The game is a satirical 2D pixel-art **portrait** mobile game: **iPhone first**, built on the developer's MacBook, with Android LATER (`docs/DECISIONS.md` D1, P1). It is built with Godot **4.7.2** (the exact version on every machine), GDScript and `gl_compatibility`, edited through the godot-ai MCP. The developer is a **first-time game developer** who wants to learn as well as ship: explain *why*, not just what, and bring design choices to them with a recommended default.

## What to read

| Need | File |
|---|---|
| Rules and numbers (wins on design) | `docs/GDD.md` |
| Every string and content id | `docs/CONTENT.md` |
| Engine facts, code rules, code skeletons (wins on engine facts) | `docs/ARCHITECTURE.md` |
| The step plan and each step's Done-when | `docs/ROADMAP.md` |
| Design decision answers | `docs/DECISIONS.md` (D1-D8, P1 and C1, decided 2026-09-26) |
| Where each task stands | `docs/task/README.md` (generated from `.project/state.json`) |
| Context for the current step | `.project/bundles/STEP-NN.md` |
| Global invariants | `.agent/rules/invariants.md` |
| Structured index of all the above | `project.yaml` |

If two docs disagree: the GDD wins on rules and numbers, ARCHITECTURE wins on engine facts. Fix the losing doc; don't pick silently.

## Session loop (ROADMAP 10, ARCHITECTURE 16)

1. Godot is open on this project before the session starts. Run `editor_state`: ready and not playing.
2. Kickoff: restate the step's goal and its Done-when from `docs/ROADMAP.md`.
3. Design huddle: bring 2-3 options per open question, each with a recommended default. The developer decides; add one line to `docs/DECISIONS.md`. Never change a design decision silently.
4. Build in small increments. After each one: run the game, take a `editor_screenshot source="game"`, read `logs_read`, run `test_run`.
5. Leave the step's "You do" task to the developer.
6. Verify, then suggest a commit message (for example `feat(interview): add doubt/composure bars`). The developer commits.
7. Wrap up: list the next tasks and any new cut-list items.

## Hard rules

- Keep every invariant in `.agent/rules/invariants.md`.
- Copy ARCHITECTURE section 17 skeletons verbatim.
- Commit before a godot-ai `script_patch` and before any engine update.
- After a new `class_name`, run `filesystem_manage op=scan`.
- Edits are rejected while the game plays: `project_manage op=stop` first.
- Move or rename files only through Godot's FileSystem dock (or keep `.uid`/`.import` files with them).
- Scope: MUST / SHOULD / LATER. A new idea replaces something; park ideas in `docs/ideas_parking_lot.md`.
- The 2x rule: a task past twice its estimate stops and gets cut or simplified.
- Comments only for non-obvious logic: the reason, invariant or constraint.
- Portrait 270x480 base; `Device` reads it from Project Settings. All critical UI fits the central 270x480, text sits on solid panels, and pixel fonts are used only at their native size.

## godot-ai gotchas

- `project_manage settings_set` does no type coercion: a Color passed as a dict or a string is saved with the wrong type. To set typed values, use a throwaway `@tool extends McpTestSuite` file that calls `ProjectSettings.set_setting()` and `ProjectSettings.save()`, run it with `test_run`, then delete it.
- Autoloads added through godot-ai can show editor-side "Identifier not found: GameState/Content/Device" parse errors until the editor restarts. The running game and `test_run` are unaffected.
- The game embedded in the editor's Game tab ignores `root.size` / `window_set_size` from `game_eval` (ISSUE-02). Check resizes by dragging or undocking the game window.
- On Windows, open Godot before starting Claude (MSIX AppData virtualization: see ARCHITECTURE 16). On the Mac it's a good habit.

## Switching machines (Windows PC <-> MacBook)

- Chat history and each agent's auto-memory are machine-local. This file, `docs/`, `project.yaml` and `.project/` carry the context. Pull before you start, and push when you stop.
- Install the same Godot 4.7.2 on both machines (ARCHITECTURE 13.1, 14).
- On Windows, git checks out the three symlinks `.claude/CLAUDE.md`, `.code/AGENTS.md` and `.claude/skills` as one-line text files unless `core.symlinks` is enabled (this needs Windows Developer Mode, then a re-checkout of those files). Until then, Claude Code on Windows loads neither this file nor the project skills automatically (ISSUE-04).
- `.project/render.py` and the skill's `check_project.py` need PyYAML. The Mac has it; the Windows PC does not (as of 2026-09-27).

## Plan-driven workflow (skill: `.agent/skills/plan-driven-development`)

- Task ids are ROADMAP steps: `STEP-00` .. `STEP-13`. Never renumber.
- Execution state lives in `.project/state.json`; `docs/task/README.md` is rendered from it with `[]`, `[!]`, `[x]`.
- A step becomes `done` only when every Done-when criterion passes: automated ones with a current `test_run` artifact in `.project/evidence/STEP-NN/<run>/`, manual and device ones with the developer's recorded confirmation. The ROADMAP checkboxes are the developer's to tick.
- Before starting a step, check its `depends_on` in `project.yaml` are done, then read its bundle.
- When a doc changes, mark affected criteria stale (`needs_revalidation`) rather than keeping old evidence.
- Validate after editing the model or the index:

```bash
python3 .agent/skills/plan-driven-development/scripts/check_project.py validate project.yaml
python3 .agent/skills/plan-driven-development/scripts/check_project.py audit-preservation project.yaml --root .
python3 .agent/skills/plan-driven-development/scripts/check_project.py audit-task-status docs/task/README.md
```

No calibrated analyzer exists for GDScript here, so the automatic logic `gate` is not used to advance tasks.

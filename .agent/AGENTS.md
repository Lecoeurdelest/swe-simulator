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
| What's waiting for the developer (merges, reviews, sign-offs, You-do, iPhone checks) | `docs/REVIEW_QUEUE.md` |
| Context for the current step | `.project/bundles/STEP-NN.md` |
| Global invariants | `.agent/rules/invariants.md` |
| Structured index of all the above | `project.yaml` |

If two docs disagree: the GDD wins on rules and numbers, ARCHITECTURE wins on engine facts. Fix the losing doc; don't pick silently.

## Session loop (ROADMAP 10, ARCHITECTURE 16)

1. Godot is open on this project before the session starts. Run `editor_state`: ready and not playing.
2. Kickoff: restate the step's goal and its Done-when from `docs/ROADMAP.md`.
3. Design huddle: bring 2-3 options per open question, each with a recommended default. The developer decides; add one line to `docs/DECISIONS.md`. Never change a design decision silently. While the developer is away (DECISIONS W4), take the recommended default, log it as "agent default, please review", and list it in the step summary; scope, tone and tip accuracy wait for the developer.
4. Build in small increments. After each one: run the game, take a `editor_screenshot source="game"`, read `logs_read`, run `test_run`.
5. Leave the step's "You do" task to the developer. If the game needs its output to run, build a plain placeholder and keep the task queued (W3). Never quiz the developer on explanations (W6).
6. Verify, then commit on the step's branch (`step-NN-<slug>`, branched from the previous step's branch) and push without asking (W1), e.g. `feat(interview): add doubt/composure bars`. The developer merges on GitHub in step order.
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
- Portrait layout rules are INV-19 in `.agent/rules/invariants.md`.
- **No agent attribution** in commit messages or PR descriptions: no `Co-Authored-By:` trailer and no "Generated with Claude Code" footer (the developer's rule, 2026-09-27). This overrides any default attribution guidance.

## godot-ai gotchas

- `project_manage settings_set` does no type coercion: a Color passed as a dict or a string is saved with the wrong type. To set typed values, use a throwaway `@tool extends McpTestSuite` file that calls `ProjectSettings.set_setting()` and `ProjectSettings.save()`, run it with `test_run`, then delete it.
- Autoloads added through godot-ai can show editor-side "Identifier not found: GameState/Content/Device" parse errors until the editor restarts. The running game and `test_run` are unaffected.
- The game embedded in the editor's Game tab ignores `root.size` / `window_set_size` from `game_eval` (ISSUE-02). Check resizes by dragging or undocking the game window.
- On Windows, open Godot before starting Claude (MSIX AppData virtualization: see ARCHITECTURE 16). On the Mac it's a good habit.
- **Stale script buffers:** if a script is open in the editor's script editor, a later `scene_save` or a run's autosave can write the OLD buffer back over a file you just wrote with `script_create`. After rewriting an open script, check the file on disk before trusting a run (seen in Step 2).
- `filesystem_manage op=remove` refuses to delete anything in this repo ("Cannot establish ownership through a linked entry: res://.code/AGENTS.md", caused by the git symlinks). Delete throwaway files with `rm`, then `filesystem_manage op=scan`.
- `game_manage input_mouse` uses **window** pixels (2x game px in the 540x960 desktop window), and a `motion` event must come before each `button` press. Real drags need `game_eval` (motion events carry no button mask).
- `theme_manage` can't set `Theme.default_font`, `default_font_size` or a type variation's base type. Use the throwaway `@tool McpTestSuite` trick above.
- Rarely, a `filesystem_manage op=scan` hangs until the MCP timeout, or the running game's main loop stops advancing (stale screenshots). Stop the game and relaunch; the editor recovers.

## Switching machines (Windows PC <-> MacBook)

- Chat history and each agent's auto-memory are machine-local. This file, `docs/`, `project.yaml` and `.project/` carry the context. Pull before you start, and push when you stop.
- Install the same Godot 4.7.2 on both machines (ARCHITECTURE 13.1, 14).
- The repo has four git symlinks: `.claude/CLAUDE.md`, `.code/AGENTS.md`, `.claude/skills` and `.code/skills`. On Windows they only work with Developer Mode on and `core.symlinks=true` set in the **repo** config (`git config --local`; git writes a local `false` when it clones on Windows, and that overrides the global setting). Otherwise they check out as one-line text files. The Windows PC has been fixed since 2026-09-27 (ISSUE-04). Never commit a placeholder replaced by a real file or folder.
- `.project/render.py` and the skill's `check_project.py` need PyYAML, which both machines have. On Windows the command is `python`, not `python3`; `render.py` writes UTF-8 with LF on both.

## Plan-driven workflow (skill: `.agent/skills/plan-driven-development`)

- Task ids are ROADMAP steps: `STEP-00` .. `STEP-13`. Never renumber.
- Execution state lives in `.project/state.json`; `docs/task/README.md` is rendered from it with `[]`, `[!]`, `[x]`.
- A step becomes `done` only when every Done-when criterion passes: automated ones with a current `test_run` artifact in `.project/evidence/STEP-NN/<run>/`, manual and device ones with the developer's recorded confirmation. The ROADMAP checkboxes are the developer's to tick.
- Before starting a step, check its `depends_on` in `project.yaml` are done, or have only developer-owned criteria left (device, You-do, manual review: DECISIONS W2), then read its bundle.
- When a doc changes, mark affected criteria stale (`needs_revalidation`) rather than keeping old evidence.
- Validate after editing the model or the index:

```bash
python3 .agent/skills/plan-driven-development/scripts/check_project.py validate project.yaml
python3 .agent/skills/plan-driven-development/scripts/check_project.py audit-preservation project.yaml --root .
python3 .agent/skills/plan-driven-development/scripts/check_project.py audit-task-status docs/task/README.md
```

No calibrated analyzer exists for GDScript here, so the automatic logic `gate` is not used to advance tasks.

# SWE Simulator: agent instructions

Shared instructions for every coding agent. `.claude/CLAUDE.md` and `.code/AGENTS.md` are symlinks to this file; edit only this one.

The game is a satirical 2D pixel-art **portrait** mobile game: **iPhone first**, built on the developer's MacBook, with Android LATER (`docs/DECISIONS.md` D1, P1). It is built with Godot **4.7.2** (the exact version on every machine), GDScript and `gl_compatibility`, edited through the godot-ai MCP. The developer is a **first-time game developer** who wants to learn as well as ship: explain *why*, not just what, and bring design choices to them with a recommended default.

Since 2026-10-07 the game is a **career roguelite** (Run Spec v1, merged into the docs: DECISIONS W8): one run is one career of up to five jobs on a macro clock, and the Phase 1 job hunt lives on as the DoomApply app, the Dana duel and the contract modal behind an adapter (GDD 0). The code is still Phase 1's v0.1 grey-box. **M1, the career run's sim core (STEP-14), is the next step** (W9; ROADMAP 12).

## What to read

| Need | File |
|---|---|
| Rules and numbers (wins on design) | `docs/GDD.md` |
| Every string and content id | `docs/CONTENT.md` |
| Engine facts, code rules, code skeletons (wins on engine facts) | `docs/ARCHITECTURE.md` (section 19: the career run's code plan, not built yet) |
| The step plan and each step's Done-when | `docs/ROADMAP.md` (section 12: the career run's M1-M6) |
| Design decision answers | `docs/DECISIONS.md`: D1-D12, P1-P3, C1-C4, W1-W9, the Run Spec's rows D-01..D-25, P-01..P-08 and Q-01..Q-07, the developer's later design decisions D-26 onward (A60), and the agent defaults A1 onward. D1-D8 were decided on 2026-09-26, D9-D12 on 2026-09-29, the Run Spec rows and D-26..D-28 on 2026-10-07 |
| The Run Spec merge: where each part went, every conflict (RC-nn resolved, MC-nn open) and every spec gap | `docs/merge-report.md` |
| The Run Spec as received (archived, read-only; the merged docs win) | `docs/run-spec-v1.md` |
| How to drive Godot through the MCP and headless (a dated reference; the commands are below) | `docs/swe-simulator-godot-access.md` (with `docs/swe-simulator-handoff.md`, the 2026-10-06 handoff) |
| Where each task stands | `docs/task/README.md` (generated from `.project/state.json`) |
| What's waiting for the developer (merges, reviews, sign-offs, iPhone checks) | `docs/REVIEW_QUEUE.md` |
| Context for the current step | `.project/bundles/STEP-NN.md` |
| Global invariants | `.agent/rules/invariants.md` |
| Structured index of all the above | `project.yaml` |

If two docs disagree: the GDD wins on rules and numbers, ARCHITECTURE wins on engine facts. Fix the losing doc; don't pick silently.

**Run Spec precedence (DECISIONS W8).** Where the career run's material meets the original material:
- **The original docs win** on pixel-art style, engine and language, code conventions, shipped UI conventions and existing characters (Dana, Remy, Ducky).
- **The Run Spec wins** on game design (run structure, systems, rules, numbers, events, endings), and it supersedes every earlier work-loop note.
- A conflict neither rule settles goes into `docs/merge-report.md` as the next MC-nn with a proposed resolution, and the doc text says "Open (MC-nn)". Never resolve one silently, and never decide an open MC item yourself: it waits for the developer.
- Keep the spec's ids everywhere: D-, P-, Q- (decisions and questions), R- (requirements), E01-E26 (events), S1-S5, O1-O9, A-01..A-05 (the spec's assumptions, not agent defaults) and M1-M6. A new design decision continues the D- series (D-29 next, A60).

## Session loop (ROADMAP 10, ARCHITECTURE 16)

1. Godot is open on this project before the session starts (a documentation-only session doesn't need it). Run `editor_state`: ready and not playing.
2. Kickoff: restate the step's goal and its Done-when from `docs/ROADMAP.md`.
3. Design huddle: bring 2-3 options per open question, each with a recommended default. The developer decides; add one line to `docs/DECISIONS.md`. Never change a design decision silently. While the developer is away (DECISIONS W4), take the recommended default, log it as "agent default, please review", and list it in the step summary; scope, tone and tip accuracy wait for the developer.
4. Build in small increments. After each one: run the game (`project_run` with `autosave=false`), take a `editor_screenshot source="game"`, read `logs_read`, run `test_run` (or the headless runner below).
5. The "You do" learning exercises are suspended (W7, supersedes W3): Claude builds those features too, and queues no new ones. What only the developer can do stays theirs: installs, signing, iPhone checks, and sign-offs on scope, tone and tips. Never quiz the developer on explanations (W6).
6. Verify, then commit on the step's branch (`step-NN-<slug>`, branched from the previous step's branch; STEP-14's `step-14-sim-core` starts from `run-spec-v1-merge`, or from `main` once that is merged: A61) and push without asking (W1), e.g. `feat(interview): add doubt/composure bars`. The developer merges on GitHub in step order.
7. Wrap up: list the next tasks and any new cut-list items.

## Hard rules

- Keep every invariant in `.agent/rules/invariants.md`.
- Copy ARCHITECTURE section 17 skeletons verbatim.
- Commit before a godot-ai `script_patch` and before any engine update.
- After a new `class_name`, run `filesystem_manage op=scan`.
- Edits are rejected while the game plays: `project_manage op=stop` first.
- Always pass `autosave=false` to `project_run`, and check `git diff` after runs (troubleshooting below).
- Move or rename files only through Godot's FileSystem dock (or keep `.uid`/`.import` files with them).
- Scope: MUST / SHOULD / LATER. A new idea replaces something; park ideas in `docs/ideas_parking_lot.md`.
- The 2x rule: a task past twice its estimate stops and gets cut or simplified.
- Comments only for non-obvious logic: the reason, invariant or constraint.
- Portrait layout rules are INV-19 in `.agent/rules/invariants.md`.
- **The art rule** (INV-20; GDD 2.5, 2.6, 2.11; D-21, D-25): one pixel-art style, the original docs', and the career run's office diorama is drawn in it. No commissioned art: reuse existing sprites and tiles first and draw anything new in the same style; a CC0 pack only if it matches the palette and its license is recorded (paid packs are Open, MC-16); AI-generated art never ships. Zoom only in whole-number steps with nearest filtering. Where the Run Spec and the art docs differ on a detail, the art docs win.
- New player-facing strings are ASCII and American spelling (A57), within the GDD 2.7 budgets, and avoid the banned-brand list (CONTENT 1.3), which bans some everyday words too ("indeed", "slack", "zoom", "meta").
- **No agent attribution** in commit messages or PR descriptions: no `Co-Authored-By:` trailer and no "Generated with Claude Code" footer (the developer's rule, 2026-09-27). This overrides any default attribution guidance.

## Build, run and test commands (from `docs/swe-simulator-godot-access.md`, A59)

**Through the godot-ai MCP** (the open editor; ARCHITECTURE 16):
1. `editor_state`: ready and not playing (`project_manage op=stop` first if it plays).
2. Code: edit files on disk, or `script_create` / `script_patch` (commit first); after a new or removed `class_name` or file, `filesystem_manage op=scan`.
3. Scenes: `scene_manage`, `ui_manage build_layout`, `node_*`, `script_attach`, then `scene_save`.
4. Tests: `test_run` (all suites) or `test_run suite="odds"`; details with `test_manage results_get`; failures without a message are in `load_errors` or `logs_read source="editor"`.
5. Run: `project_run` with `mode="main"`, `"current"` or `"custom"` plus `scene="res://features/...tscn"`, **always with `autosave=false`**. Every feature scene starts with a debug quick start, so it runs alone.
6. Inspect: `editor_screenshot source="game"`, `logs_read source="game"` (and `source="editor"` for parse errors), `game_manage get_ui_elements` / `input_mouse` (window pixels, a `motion` before each `button`) / `suspend` / `resume`, `editor_manage game_eval` (e.g. `return GameState.run.to_dict()`).
7. `project_manage op=stop` when done.

**Headless** (no editor; always on a copy of the repo, never the repo folder, so the copy's `.godot` cache can't fight the open editor):

```bash
GODOT="C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
P=<a copy of the repo without .git and .godot>

"$GODOT" --version                                          # -> 4.7.2.stable.steam.ed1daf0bf
"$GODOT" --headless --path "$P" --import                    # build the import cache and class_name table (first time ~10 s)
"$GODOT" --headless --path "$P" --script res://__run_all.gd # run every test suite -> RESULT passed=217 failed=0 total=217 suites=20
"$GODOT" --headless --path "$P" --script res://__run_all.gd -- suite=odds   # one suite -> passed=8
"$GODOT" --headless --path "$P" --script res://__check_all.gd               # load every .gd/.tscn -> CHECK files=85 failed=0
"$GODOT" --headless --path "$P" --quit-after 180            # boot the main scene for 180 frames: no errors
```

- **The runner** is in the repo (`tools/headless/`, A71; a `.gdignore` keeps Godot out of it). From the repo root: `bash tools/headless/run_tests.sh` (all suites), `bash tools/headless/run_tests.sh odds` (one suite) or `bash tools/headless/run_tests.sh parse` (the load check). It copies the game folders into `$PROJ` (a temp folder by default) and imports them there, so give each parallel run its own `PROJ`. `GODOT` overrides the Godot path (the Windows Steam build and the Mac app are tried first). The access doc's appendix is the old, dated copy.
- Autoloads exist only from the first frame on, not in `_init()`: a script that loads game scripts using `GameState`, `Content` or `Device` does its work on the first frame (as `check_all.gd` does).
- Saves still go to the shared `user://` folder (keyed by `config/name`): on Windows `%APPDATA%\Godot\app_userdata\SWE Simulator\`.
- **The career run's harness** (planned for M1, A56; ARCHITECTURE 19.6) runs the same way: `"$GODOT" --headless --path "$PROJ" --script res://tests/harness/run_harness.gd -- bot=planner seeds=10000`. It runs outside `test_run`; `tests/test_sim_smoke.gd` is its small version inside. Run it, and the suites, before every commit that changes a tuning number or an event (RC-32).

**Plan tracking** (on Windows `python`, not `python3`, with `PYTHONIOENCODING=utf-8`; on the Mac `python3`):

```bash
PYTHONIOENCODING=utf-8 python .project/render.py
PYTHONIOENCODING=utf-8 python .agent/skills/plan-driven-development/scripts/check_project.py validate project.yaml
PYTHONIOENCODING=utf-8 python .agent/skills/plan-driven-development/scripts/check_project.py audit-preservation project.yaml --root .
PYTHONIOENCODING=utf-8 python .agent/skills/plan-driven-development/scripts/check_project.py audit-task-status docs/task/README.md
```

The only expected validator warnings are "STEP-00: decision D4 is not accepted." and "STEP-00: decision D7 is not accepted." (D4 was superseded by D9, D7 by D-27).

**Git on the Windows PC** works from the Bash tool (Git Bash); it isn't on the PowerShell PATH, and there is no `gh` CLI, so pull-request status comes from the GitHub page.

## godot-ai gotchas

- **`project_run` defaults to `autosave=true`**, which saves open editor buffers, stale script tabs included, over files edited on disk. It once wiped `title.gd` and wrote its text into `docs/CONTENT.md` (repaired before any commit). Always pass `autosave=false`, close script tabs you edited outside the editor, and check `git diff` after runs.
- `project_manage settings_set` does no type coercion: a Color passed as a dict or a string is saved with the wrong type. To set typed values, use a throwaway `@tool extends McpTestSuite` file that calls `ProjectSettings.set_setting()` and `ProjectSettings.save()`, run it with `test_run`, then delete it.
- Autoloads added through godot-ai can show editor-side "Identifier not found: GameState/Content/Device" parse errors until the editor restarts. The running game and `test_run` are unaffected.
- The game embedded in the editor's Game tab ignores `root.size` / `window_set_size` from `game_eval` (ISSUE-02). Check resizes by dragging or undocking the game window.
- On Windows, open Godot before starting Claude (MSIX AppData virtualization: see ARCHITECTURE 16). On the Mac it's a good habit. A bridge error PORT_OCCUPIED means a stale backend holds port 8000: close it, reopen Godot, restart Claude.
- **Stale script buffers:** if a script is open in the editor's script editor, a later `scene_save` or a run's autosave can write the OLD buffer back over a file you just wrote with `script_create`. After rewriting an open script, check the file on disk before trusting a run (seen in Step 2).
- `game_status="break"` right after `project_run` means a parse or load error at boot: `project_manage op=stop`, read `logs_read source="editor"` (boot errors only show there), fix it, relaunch.
- `test_run` can pass old behavior after a big edit (stale preloads in the editor): confirm with the headless runner, which is a fresh process, or restart the editor.
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

- Task ids are ROADMAP steps: `STEP-00` .. `STEP-19`. STEP-00..13 are Phase 1's steps; STEP-14..19 are the career run's milestones M1-M6 (A53; ROADMAP 12). Never renumber.
- Execution state lives in `.project/state.json`; `docs/task/README.md` is rendered from it with `[]`, `[!]`, `[x]`.
- A step becomes `done` only when every Done-when criterion passes: automated ones with a current `test_run` artifact (or a headless harness report) in `.project/evidence/STEP-NN/<run>/`, manual and device ones with the developer's recorded confirmation. The ROADMAP checkboxes are the developer's to tick.
- Before starting a step, check its `depends_on` in `project.yaml` are done, or have only developer-owned criteria left (device, manual review: DECISIONS W2; You-do exercises are suspended, W7), then read its bundle. M1 (STEP-14) is W9's one exception: it starts ahead of the open Steps 7-13.
- When a doc changes, mark affected criteria stale (`needs_revalidation`) rather than keeping old evidence.
- Validate after editing the model or the index, with the plan-tracking commands above.

No calibrated analyzer exists for GDScript here, so the automatic logic `gate` is not used to advance tasks.

# Bundle: STEP-01 (Project foundation)

Snapshot: 2026-09-27, code at 6f40919 plus the uncommitted portrait amendment (D1, D2). Spec: [ROADMAP Step 1](../../docs/ROADMAP.md). State: `verifying`.
Evidence run: [.project/evidence/STEP-01/2026-09-27-r2/](../evidence/STEP-01/2026-09-27-r2/) (Windows PC, portrait).
Stale: [2026-09-26-r1](../evidence/STEP-01/2026-09-26-r1/) checked the landscape 480x270 project; its results are kept as history in `.project/state.json`.

## Portrait amendment (2026-09-26, uncommitted)

- `project.godot`: viewport 270x480, window override 540x960, orientation 1 (`SCREEN_PORTRAIT`); the other 15 Step 1 keys are unchanged.
- `autoload/device.gd` reads its base size from Project Settings, so the guard math needed no change; `ui/components/safe_area_margin.gd` comment updated.

## Criteria

| ID | Statement | Status |
|---|---|---|
| AC-S01-1 | F5 shows `window (540, 960)` / `game (270, 480) (integer)`, or the ARCHITECTURE 1.1 size for the Game tab | pass (r2: label read from the running stub) |
| AC-S01-2 | Resizing changes the game size; nothing blurs | **inconclusive**: `game_eval` resizes are ignored in the Game tab. Drag the edge, or float/undock the game window |
| AC-S01-3 | `test_run` 24 passed | pass (r2: flow 6, interview 4, odds 8, offer 3, save 3) |
| AC-S01-4 | No errors in Output | pass (r2: game log clean) |
| AC-S01-5 | `git status` clean, everything pushed, `.godot/` untracked | **pending**: `.godot/` untracked and 6f40919 pushed, but the portrait amendment is uncommitted |
| AC-S01-6 | You can explain: autoload; why only `change_phase()`; why RNG state is a string | **pending (developer)** |

Check `project_settings`: pass (r2, all 20 keys with the portrait values).

## To finish

1. Developer: run F5, drag the game window edge (or float it) to about 588x1278; the label should read `game (294, 639) (integer)` and stay crisp.
2. Developer: the portrait commit (ROADMAP Step 1 task 10): `git add -A`, check `git status` lists no `.godot/` path, `git commit -m "chore: portrait 270x480, iPhone first"`, `git push`. Then Claude re-checks AC-S01-5.
3. Developer: answer the three questions in AC-S01-6 (ARCHITECTURE 3, 4.2, 7.2 have the answers).
4. Then set STEP-01 to `done` in `.project/state.json` and run `python3 .project/render.py` on the Mac (the Windows PC has no PyYAML: ISSUE-05).

## Invariants touched by this step

INV-01, INV-03, INV-05, INV-06, INV-10, INV-12, INV-16 (all in the committed skeletons; the tests cover INV-01 transitions, INV-05, INV-06).

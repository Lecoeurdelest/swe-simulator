# Bundle: STEP-01 (Project foundation)

Snapshot: 2026-09-26, code at 64ed38f. Spec: [ROADMAP Step 1](../../docs/ROADMAP.md). State: `verifying`.
Evidence run: [.project/evidence/STEP-01/2026-09-26-r1/](../evidence/STEP-01/2026-09-26-r1/).

## Criteria

| ID | Statement | Status |
|---|---|---|
| AC-S01-1 | Title stub shows the size ARCHITECTURE 1.1 predicts | pass: Game tab 1197x539 -> `game (599, 270) (fractional)`, as the guard predicts |
| AC-S01-2 | Resizing changes the game size; nothing blurs | **inconclusive**: `root.size` is ignored in the Game tab. Drag the edge, or float/undock the game window |
| AC-S01-3 | `test_run` 24 passed | pass (flow 6, interview 4, odds 8, offer 3, save 3) |
| AC-S01-4 | No errors in Output | pass (game log clean) |
| AC-S01-5 | Foundation committed, `.godot/` untracked | pass, deviation: 2 commits, not 1 |
| AC-S01-6 | You can explain: autoload; why only `change_phase()`; why RNG state is a string | **pending (developer)** |

## To finish

1. Developer: run F5, drag the game window edge (or undock it) to about 1278x588; the label should read `game (639, 294)` and stay crisp.
2. Developer: answer the three questions in AC-S01-6 (ARCHITECTURE 3, 4.2, 7.2 have the answers).
3. Then set STEP-01 to `done` in `.project/state.json` and run `python3 .project/render.py`.

## Invariants touched by this step

INV-01, INV-03, INV-05, INV-06, INV-10, INV-12, INV-16 (all in the committed skeletons; the tests cover INV-01 transitions, INV-05, INV-06).

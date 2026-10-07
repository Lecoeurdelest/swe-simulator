# Bundle: STEP-07 (Playtest #1, tuning and the balance sim)

Snapshot: 2026-09-29, branch `step-07-dev-review` (on top of `main`, the Step 6 merge): the developer's v0.1 review (d8db453, 5c0f968, e255e6f, 501def5, 8aaae75, a04ae64) and its review fix pass (f89cf09..62c2a68 plus a docs and tracking commit). Docs: GDD 1.2, CONTENT 1.1, ARCHITECTURE 1.4, ROADMAP 1.2, DECISIONS up to A51 and P3. Spec: [ROADMAP Step 7 and section 7](../../docs/ROADMAP.md), [GDD 5.12, 10.6](../../docs/GDD.md), [ARCHITECTURE 12.4](../../docs/ARCHITECTURE.md).
State: `in_progress` since 2026-09-29 under W2 (STEP-03..06 have only developer-owned criteria left). Depends on STEP-06. About 8 h. Tests: 217/217 in 20 suites.
Updated 2026-10-07: the Run Spec v1 merge (DECISIONS W8) and W9 change this step's context. M1, the career run's sim core (STEP-14), runs ahead of this step, and what happens to this step is open (MC-01; see "Out of scope").

## Objective

Evidence that the loop is fun and fair before weeks go into art: a silent playtest with 3-5 people on the developer's iPhone, a debug-only Run Report, the GDD 5.12 balance bot as `tests/test_balance.gd`, then tuning of the `.tres` files and the D8 decision.

## Out of scope

- The career run (Run Spec v1). It replaced Phase 2's parking on 2026-10-07 (W8, superseding P3) and is built as STEP-14..19; M1 (STEP-14) runs ahead of this step (W9). What happens to this step's Playtest #1 and its Phase 1 balance sim is open (MC-01: proposed, fold Playtest #1 into the M2 gate and let the career run's R-BAL harness replace the Phase 1 sim, which takes ISSUE-09 with it). Until the developer answers, don't build either.
- New features instead of fixing confusion (ROADMAP Step 7 pitfalls); SHOULD features wait for Step 8.
- Cosmetic customization (D6 stands).
- Code changes during tuning: numbers change in the 7 `.tres` files only (INV-15).

## Requirements and criteria

| ID | Statement | Method | Owner | Status |
|---|---|---|---|---|
| AC-S07-1 | 3 of 5 testers finish a loop without help (REQ-PLAYTEST) | manual_review | developer | pending |
| AC-S07-2 | `test_balance` is green against the GDD 5.12 bands, or the new ones chosen for D8 and written in DECISIONS.md (REQ-BALANCE) | behavioral_test | agent | pending |
| AC-S07-3 | Each tester can name one career tip afterwards (REQ-EDU) | manual_review | developer | pending |
| AC-S07-4 | There is a ranked fix list, and its top 3 are fixed (REQ-PLAYTEST) | document_check | developer | pending |

## Decisions

D8 (Doubt HP 118/128/132 until this step decides), D9 (no CV editing or lying: the bot's Quick Apply sends the honest CV), D10 (best Dream score LATER), D11 (coach marks close on a tap), D12 (the VS intro waits for a tap), C2-C4 (copy), W2 (dependency gate), W4 (agent defaults while the developer is away), W7 (Claude builds the features; installs, signing, iPhone checks and sign-offs stay the developer's), P2 (PC only until the Mac and iPhone are set up), P3 (Phase 2 parked; superseded on 2026-10-07 by W8, the Run Spec merge), W9 (M1 runs ahead of this step), D-27 (Negotiate removed). Agent defaults waiting for review: A21-A51. Open questions: A42 (mirror Composure), Q3 (balance, ISSUE-09), Q5 (flick swipes) in `docs/REVIEW_QUEUE.md`.

## Tasks (ROADMAP Step 7)

1. **Playtest #1** (developer): ROADMAP section 7 with 3-5 people on the iPhone (2 job seekers or students, 1 non-gamer, 1 developer friend). Re-run the build from Xcode the day before (7-day signing). Stay silent; note pauses over 3 s, taps on non-interactive things, skipped text, laughs, whether they can say why they lost, whether they notice tailoring works, and the intro skip panel. Ask the 4 questions afterwards. Waits for the Mac and iPhone (P2).
2. **Run Report screen** (Claude), debug builds only: time to the first interview, applications per interview, pass/fail and the worst question, run length, the intro skip and its panel, tips seen. Debug UI follows DECISIONS A1/A51: English labels as script constants, hidden in release builds.
3. **Balance simulation** (Claude): port the GDD 5.12 bot into `tests/test_balance.gd` (ARCHITECTURE 12.4): the real `RunState`, `Odds` and `InterviewPlan` rules; `.tres` via `load()` and JSON via `FileAccess` inside the test, never the `Content` autoload (INV-12); one test method per background, about 1,000 runs each, well under 20 s; assert the 5.12 bands with tolerances for n = 1,000. Re-check the bot's CV rule first: since D9 only Tailor & Apply sends the Polished lines (ISSUE-09).
4. **Tuning** (Claude and the developer): `.tres` only, rerun the sim, decide D8 and write it in DECISIONS.md.

## Files and symbols

- New: `tests/test_balance.gd` (task 3), the Run Report scene under `features/dev/` (task 2; `features/dev/` is excluded from release exports, and the title may load it by path in debug builds: INV-02's exception, A1).
- Read: `core/run_state.gd`, `core/odds.gd`, `core/interview_plan.gd`, `core/hunt_tips.gd`, `data/*.tres` (`BalanceConfig`, `TierData`, `BackgroundData`), `data/content/*.json`.
- Tune: `data/balance/balance_config.tres`, `data/tiers/*.tres` and `data/backgrounds/*.tres`.
- Debug helpers already there: the hub's DEBUG row (`GameState.debug_fake_invite`, "Rent runs out"), the interview's DBG panel (forced K.O. / wheel / Composure 0), the title's "Reset first run" (`GameState.reset_first_run`, A51).

## Invariants

INV-03 (rules in the pure classes), INV-04 (no global RNG: the bot seeds its own RNGs), INV-09 (difficulty only from `.tres` numbers), INV-12 (tests are `@tool` McpTestSuites without autoloads or `user://`), INV-13 (content lint), INV-15 (numbers in `.tres`, text in JSON), INV-18 (joke, cause, one true tip; Q = 0.75 S + 0.25 I), INV-19 (portrait layout) for the Run Report.

## Verification

- `test_run` in the editor, or headless: every `tests/test_*.gd` through McpTestRunner; the parse check loads every script and scene.
- ARCHITECTURE section 17 copies stay byte-exact (cmp17).
- `python .project/render.py`, then `check_project.py validate project.yaml`, `audit-preservation project.yaml --root .` and `audit-task-status docs/task/README.md`.
- Evidence goes to `.project/evidence/STEP-07/<run>/`; the review run's is in `2026-09-29-review/` (fix_log.md, fix_test_run.txt, screenshots).

## Stop conditions

- The 2x rule: a task past 16 h stops and gets cut or simplified.
- A balance result that needs a design change beyond `.tres` numbers: bring options to the developer (W4), don't change rules silently.
- Anything that needs the iPhone waits for the developer (P2); the step stays `in_progress`.

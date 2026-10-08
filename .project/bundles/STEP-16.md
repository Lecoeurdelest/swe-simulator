# Bundle: STEP-16 (M3: run 1 end to end)

Snapshot: 2026-10-08, branch `step-16-run-one` (from `main` at the merge of PR #10, which carries M1, its sign-off and M2). Docs: GDD 3.3, 4.5, 4.6, 5.8, 5.9, 5.16, 5.18-5.20, ARCHITECTURE 19.5, CONTENT 16, ROADMAP 12 (Step 16), DECISIONS up to D-42 and A96. Spec: [ROADMAP 12, Step 16](../../docs/ROADMAP.md), [GDD 5.20](../../docs/GDD.md), [ARCHITECTURE 19.5](../../docs/ARCHITECTURE.md), [CONTENT 16.1, 16.3, 16.6](../../docs/CONTENT.md), [merge-report spec gaps](../../docs/merge-report.md).
State: built and verified on the desktop (2026-10-08); waits for the developer's tone sign-off, a look at the review and a playthrough. STEP-15 (M2) is built and merged and waits only for the developer's playtest (W2). Estimates: Claude about 20 h of tool calls (the 2x rule: stop and cut at about 40 h), the developer about 6 h (the tone sign-off, a playthrough).

## Objective

Run 1 playable from day 0 to the board and through it: the intro hands over to day 0 (a clip card), Hierarchai and its four coworkers (a team row), the resizing chain's five signs, the review as a 3-prompt duel with Kev, the layoff scene on the VS screen, and then the DoomApply board, where an application turns into an interview (the Dana duel through the adapter), a contract (Accept or Decline, signed by dragging) and, on Accept, job 2.

## Out of scope

- The Mid and Senior controls, the Home, ClikClok and Handbook apps, Scars on screen, every ending card beyond M2's, the Dream vs Reality score (per job, on Accept: M4), the other events and the clause effects (E06 and the rest: M4, M6), MegaCorp's second duel on screen (M4), the diorama (M5).
- Deciding scope, tone or tips: the new strings are my drafts for your sign-off (A96, AC-S16-3).

## Requirements and criteria

| ID | Statement | Method | Owner | Status |
|---|---|---|---|---|
| AC-S16-1 | Run 1 plays from day 0 to the board, with the five signs before the day-240 layoff | behavioral_test, manual_review | agent, developer | agent part passed; your playthrough |
| AC-S16-2 | A won interview from the board reaches the contract modal through the adapter's DuelRequest and DuelResult and OfferRequest and OfferResult, and Accept starts job 2 | behavioral_test, manual_review | agent, developer | pending |
| AC-S16-3 | You have signed off the tone of Hierarchai's coworkers and the layoff scene (GDD 1.3, W4) | manual_review | developer | pending |
| AC-STAT04-2 | The review plays as a 3-prompt duel on the Dana duel UI with a manager portrait (P-08) | manual_review | developer | pending |
| AC-JOB01-1 | The board shows 3-5 postings, refreshed every 14 days or after an application, each with company, archetype, level, salary, work mode and visible clauses; applying costs Burnout +3 employed or +2 unemployed, and a reply comes in 3-10 days | behavioral_test, manual_review | agent, developer | pending |
| AC-JOB03-1 | `test_adapter`: Composure, the meter's half-width (never below 0.06) and Doubt HP reach the interview from the work state, while knowledge P and the committee wheel read the background's stats unchanged (D-26) | behavioral_test | agent | pass |
| AC-JOB04-1 | The contract modal offers only Accept or Decline (D-27), and accepting while employed is a voluntary exit (Quit) | behavioral_test, manual_review | agent, developer | pending |
| AC-SH-06 | Drag-to-sign shipped in M3, or recorded on the cut list (D-33) | document_check | agent | pass (shipped) |

The full statements are in `project.yaml`.

## Decisions

D-02, D-03, D-05, D-22, D-23, D-26, D-27, D-33, P-02, P-06, P-08, Q-02; the huddle's D-39 (the review is three choice prompts), D-40 (the team row), D-41 (the board is a column of nodes), D-42 (the day-0 clip card) and the agent defaults A88-A96 (the adapter, dice, the callback band, clauses, the hunt's flow, the layoff scene, the review's numbers, drag-to-sign, wording). MC-06, MC-08, MC-11, MC-19, MC-20 are settled (D-34). Workflow: W1, W4, W7.

## Tasks (increments, each verified and pushed)

1. **The adapter and the phases** (Claude): `DuelAdapter` (pure), `WorkSession`'s checkpoint and seen questions, `WORK` <-> `INTERVIEW`/`OFFER` transitions, the career save in those phases, `GameState`'s career verbs, `interview.gd` and `offer.gd` reading the career request, `test_adapter`.
2. **The board** (Claude): `WorkBoard` (pure: nodes, the callback dots, applications), the board panel, the Jobs dock, Apply and Study, replies as notices.
3. **Interview and contract from the board** (Claude): the interview-day card, the rejection card, the paper with clauses and the hidden clause, the HIRED! beat, Accept starting the next job.
4. **The review duel** (Claude): `questions_review.json`, the review's numbers in `WorkOdds` and `WorkConfig`, review mode on the interview screen, Kev's placeholder portrait, his lines.
5. **Run 1's content** (Claude): the team row, the day-0 clip card, the intro's last caption, E07's prep line, the MC-20 rewording.
6. **The layoff scene** (Claude): the VS screen in a layoff mode, the hold-to-skip pill, the board opening by itself.
7. **Drag-to-sign** (Claude, timeboxed).
8. **Kill tests and evidence** (Claude on the desktop): the career run's new moments (an interview and an offer left mid-way), screenshots, the headless suites; then the developer's tone sign-off.

## Files and symbols

- **New (planned):** `core/duel_adapter.gd`, `core/work_board.gd`, `features/work/board_panel.gd/.tscn`, `data/content/questions_review.json`, `tests/test_adapter.gd`, `tests/test_work_board.gd`, `tests/test_review_duel.gd`.
- **Changed (planned):** `core/game_flow.gd`, `core/work_session.gd`, `core/work_cards.gd`, `core/work_hud.gd`, `core/work_odds.gd`, `core/interview_plan.gd`, `core/content.gd` (autoload), `autoload/game_state.gd`, `features/interview/` (checkpoint reads, review mode), `features/offer/`, `features/work/`, `features/layoff/`, `features/intro/`, `data/types/work_config.gd` and its `.tres`, `data/content/barks.json`, `emails.json`, `cutscene.json`, `work_events.json`, and the tests that cover them.
- After a new `class_name`: `filesystem_manage op=scan`, or a headless `--import` on the copy.

## Invariants

INV-01 (only `change_phase` changes the phase), INV-02 and INV-03 (screens call `GameState` verbs; rules in pure classes), INV-06 (the save's live phases now include INTERVIEW and OFFER for the career), INV-07 (plain data), INV-10 (append-only phases), INV-14 (thumb band, hit areas, mouse events only), INV-15 (text in the JSON; the JSON count goes 18 to 19), INV-19 (portrait layout), INV-21 (the sim stays pure: presentation dice never touch its stream), INV-22 (no time while a card, app or modal is open).

## Verification

- The headless runner: every suite, the load check, ARCHITECTURE section 17 byte-exact; the harness for every bot if a rule or a number in the sim changes (RC-32); the plan validators.
- In the editor (godot-ai): a whole run 1 played through the real screens (the intro handover, the clip card, the team row, the signs, the review duel, the layoff scene, the board, an interview, the contract, Accept), the kill tests of an interview and an offer, the 294x639 layout; screenshots in the evidence folder.

## Stop conditions

- The 2x rule: at about 40 h of Claude's time, stop and cut. Drag-to-sign is the first thing to cut (record it on the cut list). The tone sign-off and the playthrough are the developer's.

# Bundle: STEP-15 (M2: the grey-box UI)

Snapshot: 2026-10-08, branch `step-15-greybox-ui` (from `step-14-signoff`, itself from `main` at the merge of PR #8). Docs: GDD 2.0, CONTENT 1.2, ARCHITECTURE 1.5 and 19, ROADMAP 12, DECISIONS up to D-38 and A87. Spec: [ROADMAP 12, Step 15](../../docs/ROADMAP.md), [GDD 4.5-4.6, 5.14, 5.16, 5.17, 5.19](../../docs/GDD.md), [ARCHITECTURE 4.1, 8, 10, 19.4, 19.7](../../docs/ARCHITECTURE.md), [CONTENT 16.2, 16.5, 16.6](../../docs/CONTENT.md), [KILL_TESTS](../../docs/KILL_TESTS.md), [the playtest protocol](../../docs/PLAYTEST_M2.md).
State: built and verified on the desktop; waits for the developer's playtest. STEP-14 is done (PR #8 merged; its sign-off is `step-14-signoff`, D-29..D-38). Estimates: Claude about 16 h of tool calls (the 2x rule: stop and cut at about 32 h), the developer about 6 h.

## Objective

The career run on screen with the cheapest UI: the phone shell, the calendar strip, the four numbers, the Hours notches, event cards, the speed control, save and resume, and no diorama. Three outside players finish job 1 and can say why they were laid off (the M2 gate, which also carries Playtest #1: D-33).

## Out of scope

- The DoomApply board, the review duel, the adapter (M3); the Mid and Senior controls beyond the ticket pick, Home, ClikClok and the Handbook apps, Scars on screen, the other endings' cards (M4); the diorama and pause-and-zoom (M5); the Handbook and the Ducky pass (M6).
- Deciding scope, tone or tips: the new strings are my drafts for review (A87).

## Requirements and criteria

| ID | Statement | Method | Owner | Status |
|---|---|---|---|---|
| AC-S15-1 | Three outside players finish job 1 and can say why they were laid off (the M2 gate) | manual_review | developer | pending: the playtest |
| AC-S15-2 | Killing the game mid-run, then Continue, restores the state of the last save (O8; KILL_TESTS 6-8) | behavioral_test, device_observation | agent, developer | desktop kill tests pass; the iPhone kill is yours |
| AC-S15-3 | Every control used more than once a day sits in the thumb band, and the Junior screen has exactly one continuous control (O3) | manual_review | developer | agent-checked |
| AC-CLK-1 | No time passes while the app is closed: the clock moves only in the work state with no card, app or modal open (D-13, INV-22) | behavioral_test, manual_review | agent, developer | tests pass |
| AC-STAT01-1 | The top band shows Runway (red under 2, with its number), Burnout, the Ticket and the Codebase's 10 LEDs | manual_review | developer | agent-checked |
| AC-EVT01-2 | An event card pauses the clock, slides up into the thumb band and offers at most 3 choices behind the 250 ms lock | manual_review | developer | agent-checked |
| AC-EVT02-2 | An auto-resolved card says the choice was made for you | manual_review | developer | agent-checked |

The full statements are in `project.yaml`.

## Decisions

D-01, D-04, D-07, D-13, D-14, D-33; the huddle's agent defaults A78-A87 (entry points, the save, the clock, cards, stand-ins, after the layoff, coach marks, the layout, debug helpers, new strings); A58 (five notches, no drag), A75 (the exact save), A67 (the review stand-in). Workflow: W1, W4, W7.

## Tasks (ROADMAP 12, Step 15)

1. **Phases and the save** (Claude, done): `WORK` and `LAYOFF` appended with their transitions; `SaveIO` tells a career save from Phase 1's; `GameState`'s career verbs; `Sim.apply_inputs`.
2. **`features/work/work.tscn`** (Claude, done): the phone shell, the cards, the coach marks, the clock; `features/layoff/`; the career endings on the Plan B card; the Title's debug "Old hunt".
3. **Kill tests** (Claude on the desktop, done: `.project/evidence/STEP-15/2026-10-08-r1/kill_tests_log.md`; you on the iPhone later).
4. **The M2 playtest** (you): `docs/PLAYTEST_M2.md`.

## Files and symbols

- **New:** `core/work_clock.gd`, `work_hud.gd`, `work_cards.gd`, `work_session.gd`; `features/work/` (`work.gd/.tscn`, `event_card.gd/.tscn`, `codebase_rack.gd`, `calendar_strip.gd`); `features/layoff/` (`layoff.gd/.tscn`); `tests/test_work_clock.gd`, `test_work_hud.gd`, `test_work_cards.gd`, `test_work_session.gd`; `docs/PLAYTEST_M2.md`.
- **Changed:** `core/game_flow.gd`, `core/save_io.gd`, `core/sim.gd` (`apply_inputs`, the severance on the layoff card), `core/sim_state.gd` (`encode_value`), `autoload/game_state.gd`, `autoload/scene_router.gd`, `features/title/`, `features/game_over/`, `ui/components/ui_text.gd` (`money_k`), `data/content/barks.json`, `endings.json`, `work_events.json`, and the tests that cover them.
- After a new `class_name`: `filesystem_manage op=scan`, or a headless `--import` on the copy.

## Invariants

INV-01 (only `change_phase` changes the phase), INV-02 and INV-03 (screens only call `GameState` verbs; rules in pure classes), INV-06 (the save's live phases now include WORK and LAYOFF), INV-10 (append-only phases), INV-14 (thumb band, hit areas, mouse events only), INV-15 (text in the JSON), INV-19 (portrait layout), INV-21 (the sim stays pure), INV-22 (no time while a card, app or modal is open, or the app is away), INV-23 (one continuous control).

## Verification

- The headless runner: every suite (387 passed, 30 suites), the load check (125 files), ARCHITECTURE section 17 byte-exact (39 blocks); the plan validators.
- In the editor (godot-ai): the work and layoff scenes, a full run through `GameState`'s verbs, the desktop kill tests (moments 6, 7, 8 and 11), the 294x639 layout; screenshots in the evidence folder.

## Stop conditions

- The 2x rule: at about 32 h of Claude's time, stop and cut. The playtest is the developer's, and the step cannot be `done` without it.

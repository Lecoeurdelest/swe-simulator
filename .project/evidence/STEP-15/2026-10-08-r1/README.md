# STEP-15 evidence, 2026-10-08, run r1

What this folder holds (ROADMAP 12, Step 15; `project.yaml` AC-S15-1..3, AC-CLK-1, AC-STAT01-1, AC-EVT01-2, AC-EVT02-2):

| File | What it is |
|---|---|
| `tests.txt` | the headless test run (387 passed, 30 suites; the 34 new tests are in `work_clock`, `work_hud`, `work_cards` and `work_session`, 4 more in `flow`, `save`, `ui_text`, `sim_rules` and `content_lint`), the load check (125 files) and the ARCHITECTURE section 17 sync (39 blocks) |
| `kill_tests_log.md` | the career run's kill tests (KILL_TESTS moments 6, 7, 8 and 11) on the desktop, and a whole run played through `GameState`'s verbs |
| `screens/` | 15 screenshots of the real game at 270x480 (one at 294x639), taken through the godot-ai MCP (`editor_screenshot source="game"`) |

Commands (from the repo root; Godot 4.7.2):

```bash
bash tools/headless/run_tests.sh            # all suites
bash tools/headless/run_tests.sh parse      # load every .gd and .tscn
python tools/headless/sync_arch17.py .      # ARCHITECTURE section 17 byte-exact
```

The screens (what each criterion looks like):

| Screen | Shows |
|---|---|
| `01_day0_coach.png` | the work state on day 0: the four numbers, the Studio chip, the strip, the Hours notches, the dock, Back beside the speed control, and the first coach note (AC-STAT01-1, AC-S15-3) |
| `02_rumor_card.png`, `06_prep_card_three_choices.png`, `05_lifestyle_offer.png`, `15_recruiter_event_card.png` | cards over the clock: a notice with OK, and events with two and three choices (AC-EVT01-2); the choices wake after the 250 ms lock |
| `03_review_card.png`, `04_review_result.png`, `08_ticket_pick_card.png` | the review as a stand-in, its result, and a Mid's ticket pick |
| `07_auto_resolved_card.png` | "Too tired to choose. Burnout picked: Fix it yourself" (AC-EVT02-2) |
| `09_layoff_scene_last_beat.png`, `10_between_jobs.png` | the layoff scene's last beat, then the work state between jobs |
| `11_plan_b_ending.png` | a career ending on the Plan B card's layout |
| `12_iphone_size_layout_294x639.png` | the same screen at 294x639: the Body takes the extra height and the thumb band stays glued to the bottom (INV-19) |
| `13_pause_sheet.png`, `14_dock_app_card.png` | Back opens Pause; a dock app says "not in this build yet" and stops the clock |

What is not shown here: the M2 gate itself (three outside players, ROADMAP 7), which only the developer can run, and the iPhone's feel (the thumb, the 250 ms lock, whether a drag along the Hours notches is wanted: A58).

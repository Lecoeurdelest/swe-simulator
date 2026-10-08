# STEP-16 evidence, 2026-10-08, run r1

What this folder holds (ROADMAP 12, Step 16; `project.yaml` AC-S16-1..3, AC-STAT04-2, AC-JOB01-1, AC-JOB03-1, AC-JOB04-1, AC-SH-06):

| File | What it is |
|---|---|
| `tests.txt` | the headless test run (430 passed, 34 suites; the 38 new tests are in `adapter`, `work_board`, `review_duel` and `sign_slider`, and `work_hud`, `work_session`, `intro`, `content_lint`, `data_files` and `flow` grew), the load check (138 files), ARCHITECTURE section 17 (46 blocks), and the per-suite counts |
| `kill_tests_log.md` | the career run's kill tests that M3 adds or completes (moments 9, 10, 12, 13, 14) on the desktop, and what real-input play showed |
| `planner.json`, `coaster.json`, `grinder.json`, `lifestyle.json`, `random.json` | the harness report for each bot, 10,000 seeds: **equal to STEP-14's r2 reports in every field except the timings** (the Planner 1,279 wins, median day 861; the others never win), so M3's sim changes (the company on `job_ended`, a board that never posts a job at your own employer, public lookups) moved no run |
| `screens/` | 18 screenshots of the real game at 270x480, taken through the godot-ai MCP (`editor_screenshot source="game"`) |

Commands (from the repo root; Godot 4.7.2):

```bash
bash tools/headless/run_tests.sh            # all suites
bash tools/headless/run_tests.sh parse      # load every .gd and .tscn
python tools/headless/sync_arch17.py .      # ARCHITECTURE section 17 byte-exact
bash tools/headless/run_bots.sh seeds=10000 out=.project/evidence/STEP-16/2026-10-08-r1
```

The screens (what each criterion looks like):

| Screen | Shows |
|---|---|
| `01_clip_card_and_team.png` | run 1's day 0: Remy's clip as one card over the Body, with the team row under the job line (D-42, D-40) |
| `02_team_minh_desk_empty.png` | day 211: "Minh (desk empty)" dimmed from the fourth sign, the feed scrolling inside the Body (D-40) |
| `03_board_nodes.png`, `04_board_applied_waiting.png` | the DoomApply board (D-41): four postings as nodes joined by a line, the Apply and Study buttons with their costs in the thumb band, and after Apply the application "waiting on" its reply (AC-JOB01-1) |
| `05_callback_notice.png`, `06_interview_day_card.png` | a callback as a notice with the interview day, and the interview-day card with Start (A92) |
| `07_vs_interview.png`, `08_interview_career.png` | the VS screen and the interview screen on the career run's numbers: Composure, Doubt HP and the meter come from the work state (AC-JOB03-1) |
| `09_review_open.png`, `10_review_prompt_answers.png`, `11_review_bars_after_answer.png` | the review duel (D-39): Kev's placeholder portrait with his name, the EVIDENCE and CALIBRATION bars, three answers, the bars after one (AC-STAT04-2) |
| `12_contract_startup.png` | the contract: the yearly pay, the work mode, a perk, the fine print and "Offer expires at midnight. Probably." (AC-JOB04-1) |
| `13_sign_slider_resting.png`, `14_sign_slider_dragging.png`, `15_hired_beat.png` | drag-to-sign in the action bar (A95), its handle mid-drag, and the HIRED! stamp that follows (AC-SH-06) |
| `16_layoff_vs.png`, `17_layoff_beat.png`, `18_layoff_skip_pill.png` | the layoff scene on the VS screen ("DANA VS YOU", Dana's layoff stat and move), then her lines, and the hold-to-skip pill from the second viewing (A93) |

What is not shown here: the tone sign-off (AC-S16-3) and your look at the review (AC-STAT04-2), which only you can give, and the iPhone's feel (the thumb on the drag, the 250 ms lock, the board's four-line nodes).

# STEP-04 stage "lie_probe_pause_debug": lie probe, pause and ready overlay, debug outcomes, resume replay (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam) with the godot-ai MCP. The game ran embedded in the editor's Game tab: window 540x960, game 270x480, integer x2. Taps were real `game_manage input_mouse` events in window pixels (game px x2): a motion event, then press, then release. Esc was a real `input_key Escape` press and release. Raw trace lines: `lie_probe_pause_debug_traces.txt`. Tests: `lie_probe_pause_debug_test_run.json`.

Start state: editor ready, not playing; `test_run` 78/78 in 9 suites; the editor log (cursor 69) held only the known stale "Identifier not found / not declared: GameState/Content/Device/SceneRouter" autoload errors; no `user://save_v1.json`, no `user://settings.cfg`.

## What was built

| File | What |
|---|---|
| `core/interview_plan.gd` | `prompts(question_ids, choice_pool, probe_line)` (moved out of the scene, pure; a probe replaces knowledge prompt 2), `interview_rng(seed_text)`, `meter_rng(interview_rng)` (one roll seeds each meter's own RNG, so a pivot rolled or not never shifts later rolls), `probe_question(cv_line, company_id)` (`probe_at` for this company, else `probe`), `lie_lines(cv_pool, bg)` (for the debug toggle). |
| `core/odds.gd` | Added `bluff_band(cfg, p)`: five equal steps across bluff_min-bluff_max (agent default; see below). Everything else still 17.4 verbatim. |
| `core/run_state.gd` | Added rule method `settle_probe(company_id, cv_line_id, came_clean, busted)`: Come clean records "company\|line" in `confessed` once; Come clean or BUSTED drops the line from `lies_carried`. |
| `autoload/game_state.gd` | `finish_interview(won, composure_left, busted = false, came_clean = false)` now calls `run.settle_probe(...)` with the checkpoint's `probe_line`, so the probe's lasting effects are saved with the interview result, never mid-interview (GDD 5.11). |
| `ui/components/ui_text.gd` | `band(filled, word)` -> "[###--] Possible" (odds bands are dots plus a word, GDD 2.7). |
| `features/interview/interview.gd` (rewritten) | Lie probe prompt; BUSTED beat; `_wait()` flow guard; handle_back per ARCHITECTURE 9; meter lock re-armed after a pause; DBG panel; debug probe toggle; trace lines with the answer order, the zone centre and the probe roll. |
| `features/interview/interview.tscn` | New `DebugLayer` (full rect, IGNORE) > `SafeArea` (SafeAreaMargin) > `Column` (254) > 28 px gap, `DebugToggle` 34x34 "DBG", `DebugGrid` (2 columns, 4 px gaps) with six 84x34 buttons: K.O., Wheel win, Wheel loss, Composure 0, BUSTED, Probe: off. Freed in release builds. |
| `tests/test_interview_plan.gd`, `tests/test_lie_probe.gd` (new), `tests/test_ui_text.gd` | 10 new tests (see the test_run file). |

## The lie probe (GDD 5.8.5, S08)

- The probe replaces knowledge prompt 2. Dana says `bark_dana_probe_intro`, then types the line's probe question (`probe_question`: `probe_at` for this company if the line has one).
- The bluff is rolled on the interview RNG **before** the buttons appear (`Odds.roll(_rng, p)`), so Continue can't re-roll it and the later prompts' dice are the same whichever button you press.
- ProbeRow: [Come clean] left, [Bluff] right with "Bluff" on line 1 and `UiText.band(Odds.bluff_band(p), ui_odds_<band>)` on line 2. `p = Odds.bluff_p(..., degree_claim)`. Buttons get the 250 ms lock.
- Come clean: Doubt `come_clean_doubt` (-5), Composure -`come_clean_comp` (10), Ducky note `tip_say_i_dont_know` in the thumb band while Dana says `bark_dana_come_clean`; `finish_interview(..., came_clean = true)` records the confession at the end.
- Bluff holds: Doubt `bluff_win_doubt` (-15), `bark_dana_bluff_win`.
- Bluff fails, BUSTED: Doubt +`busted_doubt` (20), Composure -`busted_comp` (30), two 30 ms haptic pulses (GDD 9.3), "BUSTED!" banner (Press Start 2P 32) over the stage, Ducky note `tip_honesty_checks`, `bark_dana_busted`. The interview goes on; `finish_interview(..., busted = true)` blacklists the company at the end.
- The rejection card's tip keeps the previous cause order (red answer, bad choice, Tired, research); the probe's own tip already showed when it resolved.

## Pause, Ready overlay and Back (ARCHITECTURE 9)

`handle_back()`: Pause open = Resume; Ready overlay showing = open Pause; Ducky card with [ Back to the hunt ] = Back to the hunt; VS intro = skip if allowed; else open Pause. [II] still calls `Device.handle_back()` (the on-screen Back) and hides while the rejection card shows. After any unpause, the answer, probe and hunt buttons re-lock for 250 ms, and a live meter ignores taps for 250 ms.

## Debug panel (debug builds only)

"DBG" (34x34) at the stage band's top-left (game y 36-70), shown after the VS intro and hidden once an outcome starts. The grid sits at y 74-184, inside the stage band, never in the thumb band. Each force button bumps a flow counter: the prompt coroutine in progress wakes stale at its next signal and parks for good (`_wait`), so only the ending code drives the screen. K.O. / Composure 0 run `_ko()` / `_reject("composure_zero", ...)`; Wheel win / loss clamp Doubt to the committee band and run `_committee("win" | "loss")` (the wheel shows the real odds for that Doubt); BUSTED plays the real BUSTED beat (`_bust`), then the usual rejection. "Probe: off" cycles the checkpoint's `probe_line` through the background's Lie lines (edu, exp, proj, off) until knowledge prompt 2 is asked, and calls `GameState.save()` so Continue replays it (standing in for Step 5's roll).

## Layout measured in the running game (get_ui_elements, game px)

| Element | Rect | Spec |
|---|---|---|
| DBG toggle | x 8-42, y 36-70 (34x34) | middle zone, hit >= 34 |
| DBG grid | x 8-180, y 74-184; buttons 84x34, 4 px gaps | stage band (y 32-188) |
| ProbeRow | y 429-476, [Come clean] x 8-132, [Bluff] x 138-262, **124x47** each | S08: 2 x 124x44 at the bottom of the thumb band |
| Pause sheet | y 384-476; Quit to title y 391, RESUME y 433 (240x36) | S13 |

The two-line Bluff label is 2 x 13 px of monogram plus the theme's 11/10 px button padding = 47 px, so both probe buttons render 3 px taller than S08's 44. Button has no `line_spacing` constant in 4.7.2; meeting 44 needs a theme variation with 9/9 padding. Left for review, theme unchanged.

## Game runs

### Run r60742953-24: `project_run mode="custom"` interview.tscn (debug quick start: Graduate, Mid)

- DBG toggle tapped open; Probe tapped twice: `IVDEBUG|probe=cv_graduate_edu_lie`, then `cv_graduate_exp_lie`.
- Prompt 2 (kq_index_tradeoff), a miss: Q = 0.75 x 50.08 + 25 x 0.2 = 42.56; Doubt -0.9 x 12.56 = -11.31 -> 106.69; Composure -7.44 -> 92.56. Ducky's "Real answer" note appeared.
- Round 3 = the probe: "Quick question about your CV.", then "A delivery app! How did your team handle the Great Fries Outage?". [Bluff] read "[##---] Unlikely" (Graduate at Mid: 0.50 + 0.025 - 0.025 - 0.05 - 0.10 = 0.35, band 2). **Real tap on [Come clean]**: Doubt 106.69 -> 101.69, Composure 92.56 -> 82.56, `tip_say_i_dont_know` note, `bark_dana_come_clean`.
- **[II] during a live needle** (prompt 4): the Pause sheet opened, tree paused. `game_eval` read the needle's `_t` twice 0.5 s apart: 5.2114 both times (the needle does not advance while paused).
- **Esc with Pause open** = Resume (tree unpaused, needle continued: `_t` 5.594).
- **Focus loss** (`game_eval`: `GameState.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)`): tree paused, "Ready? Tap to continue." shown. **Esc on the Ready overlay** opened the Pause sheet; a **real tap on RESUME** unpaused, and the line was still waiting (not advanced).
- A second focus loss, then a **real tap on the Ready overlay**: unpaused, line still waiting.
- **Lock re-arm** (prompt 5's answers up; one `game_eval`, because tool latency exceeds 250 ms): pause then unpause -> Answer1 `mouse_filter` 2 (IGNORE) right after the unpause, 0 (STOP) 0.3 s later.
- Rejected (79.38 > 0.15 x 128). The rejection card showed with [II] hidden and DBG gone. **Esc on the card** = Back to the hunt: `finish_interview(false, 76.24, false, true)` -> JOB_HUNT, `confessed = ["co_beigeware|cv_graduate_exp_lie"]`, interviews_taken 1.
- Game log: 12 lines, all info (0 errors, 0 warnings).

### Run r61099377-25: `project_run mode="main"`, then the kill

Title (no save): tap > Intro SKIP > THE INTERN > "Fake invite (Mid)" (all real taps). VS, DBG > Probe once -> `cv_intern_edu_lie` (a degree claim), saved. Prompt 1 eq_meeting_overload showed, top to bottom: "Attend all, camera off, code quietly." / "Skip the optional ones, ask for notes." / "Book a meeting about fewer meetings." (order neutral, good, bad). The second was tapped. Then **`project_manage stop`** (the kill). The save held phase 4 (INTERVIEW), interviews_taken 0 and only the checkpoint (seed "1661572132", the 5 question ids, warmup_id, probe_line "cv_intern_edu_lie"); no Doubt, Composure or prompt index. Game log: 5 lines, all info.

### Run r61174674-26: `project_run mode="main"` > CONTINUE, then every forced outcome

**Resume replay: pass.**

| | Before the kill (run 25) | After Continue (run 26) |
|---|---|---|
| seed | 1661572132 | 1661572132 |
| question ids | eq_meeting_overload, kq_learn_fast, kq_load_balancer, kq_estimate, eq_celebrity_orders | the same; kq_load_balancer's slot now plays the saved probe cv_intern_edu_lie |
| warm-up | kq_binary_search | kq_binary_search |
| prompt 1 answer order | neutral, good, bad (texts above) | neutral, good, bad (same texts, same positions) |
| Doubt / Composure at start | 128 / 100 | 128 / 100 (the interview restarted) |

The VS again used the first-viewing 1 s minimum (interviews_taken is still 0), then the greeting and the Intern opener.

**Natural BUSTED with real input:** prompt 2 was a PERFECT (Q = 0.75 x 53.47 + 25 = 65.10; Doubt -31.59 -> 86.41). On the probe, "Very Famous University! Who supervised your master's thesis, and on what?" showed, and [Bluff] read "[##---] Unlikely" (Intern degree claim at Mid: 0.45 - 0.10 = 0.35). A **real tap on [Bluff]**: the pre-rolled result was `holds=false`, so BUSTED: Doubt 86.41 -> 106.41 (+20), Composure 100 -> 70 (-30), the "BUSTED!" banner, `bark_dana_busted`, the `tip_honesty_checks` note. The interview continued through prompts 4 and 5 and ended in a rejection. A real [ Back to the hunt ] tap -> JOB_HUNT, `blacklist = ["co_beigeware"]`, `confessed = []`.

**Forced outcomes (DBG, real taps), each through the real ending code:**

| # | Forced from | Screens seen | finish_interview result (game_eval read-back) |
|---|---|---|---|
| 1 | BUSTED, after prompt 1's answer (Dana's reaction waiting) | "BUSTED!" banner, Doubt 118 -> 138, Composure 100 -> 70, tip_honesty_checks note, bark_dana_busted; then "...WE'LL KEEP YOUR CV ON FILE.", other candidates, the Ducky card (round counter stayed 1/5: the parked prompt flow never resumed) | real [ Back to the hunt ] tap -> JOB_HUNT, blacklist gained co_beigeware (2 entries), interviews_taken 2 |
| 2 | K.O., during the greeting | "K.O.!" (Doubt bar empty), then "OFFER!" and bark_dana_ko | OFFER, `offer = {co_beigeware, job_mid_backend, mid, salary 92000, office_days 2}`. Decline + confirm (real taps) -> JOB_HUNT |
| 3 | Wheel win | committee banner, Doubt clamped to 19.20 (15%), wheel with the win wedge at 62.5% (0.40 + 0 + 45/200), pointer stopped in the win wedge, bark_dana_committee_win | OFFER (salary 92000). Decline + confirm -> JOB_HUNT |
| 4 | Wheel loss | same wheel (63% printed), pointer stopped in the lose wedge, bark_dana_committee_lose, the Ducky card with tip_research_company (GDD 8.3 committee loss) | real [ Back to the hunt ] tap -> JOB_HUNT, no offer, interviews_taken 5 |
| 5 | Composure 0 | Composure bar empty, "...WE'LL KEEP YOUR CV ON FILE.", bark_dana_composure_zero, the Ducky card | real [ Back to the hunt ] tap -> JOB_HUNT, no offer, interviews_taken 6 |

The hunt stub's "Fake invite (Mid)" always invites co_beigeware and ignores the blacklist (Step 5 filters it), so the Declines and the second BUSTED appended co_beigeware again (4 entries by the end). The real hunt never re-invites a blacklisted company.

Two DBG-leak checks: a DBG toggle press while Dana's line was typing left `_typing` true (visible_ratio 0.86); a DBG tap while a line waited left `_waiting_advance` true. The toggle keeps its own tap, like [II]. One greeting and one K.O. line seemed to advance on a single tap: tool latency (about 0.4 s per call, more for screenshots) meant the typewriter had already finished, so that tap was the advance tap.

Game log for run 26: 29 lines, all info (0 errors, 0 warnings). Editor log cursor stayed at 71 through all three runs.

## game_eval use (fallbacks and inspection)

- Fallback: `GameState.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)`, twice, to simulate a focus loss (the embedded Game tab can't be defocused reliably from the tools).
- Inspection only: the needle's `_t` / `_done` / `_meter_live` while paused; `get_tree().paused`; Ready / Pause visibility; `_typing` / `_waiting_advance` / the line text; Answer1's `mouse_filter` around a pause/unpause done inside the same eval (the lock re-arm); `GameState.run` fields after each ending (phase, offer, blacklist, confessed, interviews_taken); the Bluff button's minimum size and Button's theme constants.
- No button was pressed and no Doubt or Composure was set from game_eval in this stage: every outcome was reached by real taps (DBG buttons included).

## Cleanup

`user://save_v1.json` (written by the debug probe toggle's save in run 24, then by the main-flow runs) and `user://settings.cfg` (written by run 25's `finish_intro`, holding only `intro_seen=true`) were deleted with `rm` after the game stopped. `C:/Users/Mmotkim/AppData/Roaming/Godot/app_userdata/SWE Simulator/` now holds neither. The game is stopped.

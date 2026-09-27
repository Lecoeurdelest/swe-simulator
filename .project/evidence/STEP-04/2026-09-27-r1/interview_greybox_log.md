# STEP-04 stage "interview_greybox": VS intro, placeholder hp_bar and the interview on the real formulas (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam) with the godot-ai MCP. The game ran embedded in the editor's Game tab: window 540x960, game 270x480, integer x2. Taps were real `game_manage input_mouse` events in window pixels (game px x2): a motion event, then press, then release. Raw trace lines: `interview_greybox_traces.txt`. Tests: `interview_greybox_test_run.json`.

Start state: editor ready, not playing; `test_run` 78/78 in 9 suites; editor log cursor 55-68 held only the known stale "Identifier not found: GameState/Content/Device/SceneRouter" autoload errors; no `user://save_v1.json`, no `user://settings.cfg`.

## What was built

| File | What |
|---|---|
| `ui/components/hp_bar.tscn` + `hp_bar.gd` (new, `class_name HpBar`) | **PLACEHOLDER (W3).** Header: "PLACEHOLDER: the developer's Step 4 You-do replaces this with the 0.4 s ghost-bar version (ROADMAP Step 4)". Control 122x8 with one ProgressBar; `max_value`, `value`, `fill_color` setters; no ghost bar, no tween. |
| `features/interview/versus_intro.tscn` + `.gd` (new, `class_name VersusIntro`) | S07 / ARCHITECTURE 11.5. `play(company_id, tier)` + `finished`. AnimationPlayer clip "intro" (2.0 s) built with `animation_create` / `animation_manage`: 1-frame white flash at 0.00; busts slide along the diagonal 0.05-0.35 with an ease-out overshoot; "VS" (Press Start 2P 32) appears at 0.35; plates, special moves and the tier banner fade in 0.40-0.90; a method track calls `slam()` at 0.35 (100 ms hit-stop via `anim.pause()` + timer + `anim.play()`, a 4 px whole-pixel shake of the whole VS, `Device.haptic(40)`). Diagonal split drawn from the tier colour (top) and the background's hoodie colour (bottom). Plates: DANA (naming/interviewer), `dana_title_<tier>`, `vs_dana_stat_1..3`, `vs_dana_moves`; the player's name, `vs_nickname`, three `[###--]` stat bars (`ui_stat_*`, value / 20 rounded); banner `vs_banner_<tier>` (PS2P 16). `vs_duration_s` stretches the clip (speed_scale). Skip: tap or Back after `vs_min_view_s` on the first interview of a run, at once after that. |
| `features/interview/answer_meter.gd` (new, `class_name AnswerMeter`) | ARCHITECTURE 17.11 verbatim, plus the documented Step-4 change `set_bar_y(y)` (draws the bar at the meter row's y) and one read-only getter `zone() -> Vector2(c, h)` for the scene's zone labels (listed as a deviation). |
| `features/interview/committee_wheel.gd` (new, `class_name CommitteeWheel`) | 128 px pie, win wedge drawn at `committee_win_p` with the percentage printed on it; `spin(won, seconds)` eases the pointer 3 turns into the middle of the wedge the interview already rolled. |
| `features/interview/interview.tscn` + `interview.gd` (rewritten from the Step 3 stub, same uid) | The ARCHITECTURE 11.6 tree (Stage, AnswerMeter below SafeArea, SafeArea/Column with BarsBand, StageSpacer, DialogueBox, AnswerArea/MeterRow/ThumbSlot {AnswerColumn, TapPad, ProbeRow, DuckyCard}, VersusIntro instance, ResultLayer {KOBanner, CommitteeWheel}, ReadyOverlay) plus ModalLayer/PauseMenu and a CoachNote. One coroutine `_run()`; debug quick start; IVSTART/IVTRACE/IVWHEEL/IVRESULT lines in debug builds. |
| `data/content/barks.json`, `docs/CONTENT.md` | 9 new ids with text that already exists in the GDD mockups: `ui_composure` "COMPOSURE", `ui_doubt` "DOUBT", `ui_round` "ROUND {n}/{total}" (S08); `ui_back_to_hunt` "Back to the hunt", `bark_dana_other_candidates` "We've decided to move forward with other candidates." (S09, GDD 5.8.6); `ui_stat_knw/exp/net` "KNOWLEDGE/EXPERIENCE/NETWORK" (S03); `vs_versus` "VS" (S07, ARCHITECTURE 11.5). New placeholder `{total}` added to CONTENT.md section 0. |
| `tests/test_content_lint.gd` | `PLACEHOLDERS` gains `"total"` (mirrors CONTENT.md section 0). |

## Layout measured in the running game (get_ui_elements, game px, 270x480)

| Element | Rect | Spec |
|---|---|---|
| Bars band | y 4-32 (labels row + two 122x8 bars, 10 px gap = 254) | S08 y 0-28 |
| Stage band (StageSpacer) | y 32-188 | S08 y 28-188 |
| Dialogue box | x 8-262, y 188-264 (254x76), 4 lines, name tab in PS2P 8 | S08 254x76, y 188-264 |
| [II] pause | x 228-262, y 166-200 (34x34 hit area straddling the box's top-right corner) | 34x34 at its top-right |
| Meter row | y 264-304 (bar at row y + 15; Vague labels above it, Rambling / NAILED IT / Overthinking below) | y 280-320 |
| Answer buttons | 3 x 254x36 at y 356, 398, 440 (gap 6) | 254x36, y 348-468, gap 6 |
| Tap pad "Tap anywhere!" | y 356-476 | y 348-468 |
| Probe row (hidden until the next stage) | 2 x 124x44 | 2 x 124x44 |
| Ducky card | full width, bottom of the thumb band; `[ Back to the hunt ]` 254x36 at y 440 | S09 |

The stage's bottom edge follows the dialogue box's top (`item_rect_changed`, `resized`, `Device.layout_changed`), and the meter's bar follows the meter row, so the thumb on the pad never covers the needle.

## Game runs

### Run r58124678-21: `project_run mode="custom"` on interview.tscn (debug quick start)

`GameState.debug_quick_start("graduate", INTERVIEW)` + a checkpoint frozen through `InterviewPlan.pick` on the run RNG (seed first, like `start_interview`): Mid, co_beigeware, warm-up kq_hash_map. Real taps throughout (greeting, opener, answers, pad).

- VS finished; Dana's Mid greeting, then the Graduate's `dana_opener` (first interview of the run).
- Prompt 1 choice: 3 shuffled 254x36 answers after the 250 ms lock; good answer, Doubt 128 -> 118, Dana's reaction line.
- Warm-up before prompt 2: the round label reads "WARM-UP - DOESN'T COUNT", Ducky's `coach_meter` note sits in the stage band, the zone is drawn with its labels while Dana types the question and the needle waits at the left edge. Resolved (I 0.20); Doubt and Composure unchanged (trace line prompt=0).
- Prompt 2: h 0.1625 = 0.06 + 0.12 x 0.5207 + **0.04** (the Graduate's textbook bonus on the first real knowledge question); prompt 3 h 0.1219 (no bonus). Prompt 4: a real tap stopped the needle in Vague (CLOSE, I 0.5): Q = 0.75 x 37.27 + 25 x 0.5 = 40.45 (red), Doubt -0.9 x 10.45 = -9.41, Composure -9.55; Ducky's "Real answer: ..." note appeared full width in the thumb band.
- Prompt 5 bad answer: Doubt +8, Composure -15. Not eligible (91.64 > 0.15 x 128): the "...WE'LL KEEP YOUR CV ON FILE." banner, `bark_dana_other_candidates`, then `bark_dana_reject` with the Ducky card (tip_fundamentals = the worst red question's own tip, plus "Real answer:" and that question's green line) and `[ Back to the hunt ]`. The tap called `finish_interview(false, 63.18)`: Hunt, Energy 5/8, interviews today 1/1.
- Bug found and fixed here: the grade label ("CLOSE") stayed drawn in the meter row after the meter hid (missing redraw). Fixed; not seen again in run 22. Also added line spacing to the Press Start 2P banners (the theme's -1 Label spacing made the lines touch).

### Run r58490804-22: `project_run mode="main"`, the real flow

Title (a save existed from run 21) > `[ New game ]` > Intro SKIP > THE INTERN: Hunt, day 1, energy 9, first run. The Hunt stub only offers a Mid invite, so the Startup and Big invites were started with `game_eval` calling the real verb `GameState.start_interview({...})` (setup only; SceneRouter loaded the interview as usual). Every answer, needle stop, Sleep, Decline and button press below was a real tap.

| # | Tier / how | What was checked | Outcome |
|---|---|---|---|
| 1 | Startup (game_eval invite) | VS (first viewing); Startup greeting + Intern opener; warm-up kq_testing_pyramid; **PIVOT**: the zone jumped mid-needle and Dana's line became "Quick update: we pivoted. Keep going." (the 0.6 s "PIVOT!" label flash fell between screenshots); tap-rule: advance taps on the stage band stopped the needle | rejected (Doubt 56.38, Comp 90.43); card tip_star_stories + model answer of kq_failure_story |
| 2 | Big (after a real Sleep tap; game_eval invite) | VS frozen with `game_manage suspend`: after the slam "VS" on the diagonal; ~0.3 s later both plates, the special moves and "ROUND 1 OF 7" fading in; **instant skip** on the second interview of the run (tap at ~1.2 s, greeting typing 0.35 s later); `bark_dana_greet_again` naming the previous company, no opener; needle 0.75 bar/s, one GOOD tap (I 0.80); teamwork x1.25 on eq_impossible_deadline (72.79 -> 60.29) | rejected (60.29 / 89.16) |
| 3 | Startup, Relaxed Timing on (game_eval `set_setting("options","relaxed_timing",true)`, I = 0.9) | exclusive-free teamwork answer x1.25 (118 -> 105.5); **committee wheel**: 3-line PS2P 16 banner + `bark_dana_committee`, then the 128 px wheel with the win wedge at 68% (IVWHEEL p 0.6845 = 0.40 + 0.20 x (1 - 12.43/17.7) + 45/200), pointer spun ~2 s into the win wedge, `bark_dana_committee_win` | **wheel_win** -> Offer ($72,000/year); Decline + confirm (real taps) -> Hunt, company blacklisted |
| 4 | Mid (real "Fake invite (Mid)" tap) | **[II]** (34x34) opened Pause without advancing the dialogue (tree paused, Ready overlay hidden); Quit to title; **CONTINUE** reloaded the interview with the identical IVSTART line (same seed 2406863568, same 5 ids). Then Doubt was **forced** from 35.38 to 5.0 with game_eval before prompt 5 and the good answer was tapped | **ko**: "K.O.!" held 0.5 s, became "OFFER!" (PS2P 32), `bark_dana_ko`, Offer with salary 92000 (Mid band at full Composure x the Intern's 1.10) |
| 5 | Mid (real Fake invite tap) | **Ready overlay**: `GameState.notification(APPLICATION_FOCUS_OUT)` via game_eval paused the tree and showed "Ready? Tap to continue."; the tap unpaused without advancing the line. eq_credit_theft showed the **Intern's exclusive answer** in place of the neutral one (GDD 5.8.3). Composure was **forced** to 10 with game_eval, then the bad answer was tapped | **composure_zero**: `bark_dana_composure_zero`, card with tip_give_credit (the bad answer's own tip; no knowledge question asked, so no model answer) -> Hunt |

Game log for run 22: 36 lines, all info (the helper line, the Content line and the trace lines): **0 errors, 0 warnings**. Editor log cursor stayed at 68 during the run.

### Run r59402189-23: `project_run mode="custom"` smoke run after the last edit (typed loop variables)

IVSTART identical to run 21 (the debug quick start uses the fixed debug run seed, so it is reproducible). VS first-viewing rule: a tap at ~0.9 s did **not** skip (still playing at 1.31 s, min view 1.0 s); the clip then ended by itself at ~2.1 s (2.0 s clip + the 100 ms hit-stop). Game log: 3 info lines, 0 errors. Editor log: one new line, `Compile Error: Identifier not found: GameState` at interview.gd:94 when the scan re-parsed the file (the known stale-autoload gotcha).

## Outcomes seen

| Outcome | How |
|---|---|
| rejected | naturally, 4 times (Mid, Startup, Big, plus run 21) |
| wheel_win | naturally (Relaxed Timing on) |
| ko | branch exercised with Doubt forced to 5 via game_eval, then a real good answer |
| composure_zero | branch exercised with Composure forced to 10 via game_eval, then a real bad answer |
| wheel_loss | not seen (it shares `_rejection_card` with the rejections above; the debug outcome panel is the next task) |
| BUSTED | not built (lie probe = next task; the prompt hook `_ask_probe` is in place) |

## game_eval use (fallbacks and inspection)

- Reading state: current scene, `get_tree().paused`, `_typing` / `_waiting_advance` / `_line.text` / round label / answer texts, `GameState.run` fields, `Time.get_ticks_msec()` to measure tool latency (~0.4 s per call).
- Setup: `GameState.start_interview(...)` for the Startup and Big invites (3 times); `GameState.set_setting("options", "relaxed_timing", true)`; `GameState.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` to simulate a focus loss.
- Forced state: `_doubt = 5.0` (K.O. branch) and `_composure = 10.0` (Composure-0 branch), both marked FORCED in the traces.
- Cleanup: `SaveIO.delete()` and `DirAccess.remove_absolute("user://settings.cfg")` at the end of runs 22 and 23.
- No button was pressed by emitting `pressed` from game_eval.

## Cleanup

`user://save_v1.json` (first written by run 21) and `user://settings.cfg` (written by run 22's `finish_intro` and the Relaxed Timing setting) were deleted; `C:/Users/Mmotkim/AppData/Roaming/Godot/app_userdata/SWE Simulator/` holds neither. The game is stopped.

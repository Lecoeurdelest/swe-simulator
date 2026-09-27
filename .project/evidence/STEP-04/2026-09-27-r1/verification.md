# STEP-04 verification: adversarial verifier and agent playtest (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam), godot-ai MCP, game embedded in the editor's Game tab (window 540x960, game 270x480 at 2x). Branch `step-04-interview-greybox`. Per-interview tables, the summary and the raw trace lines: `interview_traces.md`. Final tests: `test_run.json`.

Start state: editor ready, not playing; `test_run` 88/88 in 10 suites; editor log cursor 71 held only the known stale "Identifier not found / not declared: GameState/Content/Device/SceneRouter" autoload lines; no `user://save_v1.json`, no `user://settings.cfg`.

## Result

**Two real defects found and fixed; 88/88 tests before and after; 0 errors in every game log (runs r62233196-27 to r65563361-33); the editor log gained only the known stale autoload lines (cursor 72-74).** Everything else in the task list passed, with the notes below.

## Defects fixed

### D1. The Answer Meter's Vague zone was drawn past the ends of the bar

- **Seen:** I1's warm-up (`kq_hash_map`, c 0.1554, h 0.1305). The orange Vague rect started at x 14 while the bar starts at x 35, so the bar looked 21 px wider on the left and the zone looked off-centre. c - 2h is below 0 whenever c < 2h, and c + 2h is above 1 near the right edge; since c is drawn from [h, 1 - h], the overflow can reach 0.17 x 200 = 34 px, almost to the screen edge. It is purely visual: the needle and `Odds.input_quality` were right.
- **Cause:** ARCHITECTURE 17.11 `_draw()` draws Vague as `[c - 2h, c + 2h]` without clipping it to the bar.
- **Fix (smallest change):** `features/interview/answer_meter.gd` `_draw()` clips the Vague rect to `[0, 1]` (`vague_from := maxf(_c - 2.0 * _h, 0.0)`, `vague_to := minf(_c + 2.0 * _h, 1.0)`). NAILED IT needs no clip (c is in [h, 1 - h], also after a pivot). **This is a change to ARCHITECTURE 17.11 beyond the documented set_bar_y() change: listed as a deviation.** Recommended doc follow-up (not done here): the same two lines in the 17.11 skeleton.
- **Verified:** run r64023884-30, I8 prompt 2 at 294x639: with the zone centre moved to the bar edge by `game_eval` (c = h) and the game slowed with `Engine.time_scale` 0.02, the screenshot shows green starting exactly at the bar's left end (x 47), no orange outside the bar; a pixel read of the zone label confirmed #00e436. The centre was restored before the tap; the trace's c is the original.

### D2. The probe's tips came before Dana's line (GDD 8.1 rule 1, INV-18)

- **Seen:** BUSTED (I7) and Come clean (I8): `_bust()` and the Come clean branch called `_show_note(tip)` and then `_say_dana(line)`, so Ducky's tip appeared in the same frame as the BUSTED! banner, before Dana's consequence line typed out. INV-18 and GDD 8.1 rule 1: "Joke -> consequence -> tip. The tip is always last." The code's own comment on `_bust()` already promised "then the one true tip".
- **Fix:** `features/interview/interview.gd`: a new `_say_dana_then_note(text, note)` types Dana's line, then shows the note, then waits for the advancing tap. Both call sites use it; the two tip ids stay literal `Content.field()` calls, so `ui_text/test_screen_text_ids_exist` still checks them. Agent default, please review: the tip shows as soon as Dana's line is out (a tap that finishes the typewriter shows it at once), and stays until the next tap.
- **Verified (run r65082541-31, real taps):** Come clean: note hidden at visible_ratio 0.25 and 0.50 of Dana's line, shown once the line was out (`tip_say_i_dont_know`), then waiting for the tap. DBG BUSTED: banner up, note hidden while "I checked. During your answer..." typed (ratio 0.24), then `tip_honesty_checks`. Dana's line (the consequence) now always precedes the tip. The red-answer "Real answer:" note was left as is: it is the GDD 8.4 teaching line, not a tip, and GDD S08 places it with the red answer.

## Checks (task items 1-7)

### 1. Agent playtest: 13 interviews plus a resumed replay

All 3 tiers x all 3 backgrounds (Graduate/Mid 3x, Intern/Startup 2x, Self-Taught/Mid 2x plus the resume, the rest once), see `interview_traces.md`. Real `input_mouse` taps for every answer, probe choice, advance, [II], RESUME, DBG button and Back to the hunt; needle taps were real at varied (mostly late) times, plus near-perfect taps through a `game_eval` fallback (`Input.parse_input_event` when the needle is within 0.1 h of c), because the 2-3 s tool latency makes a deliberate near-perfect `input_mouse` tap impossible. Summary: knowledge prompts moved Doubt by -21.04 on average (29 prompts; PERFECT -28.88, MISS -6.58), choice prompts by -5.84 (19); natural outcomes 6 rejections and 1 natural wheel loss at 82% (I11). Four prompts were recomputed by hand from the Odds formulas and the `.tres` values, with the luck replayed from the checkpoint seed through the real code path: all match the traces to the printed precision (INV-18: Q = 0.75 S + 25 I). Stats' share of Q averaged 69% in this thumb-best-case sample (14 of 29 taps near-perfect); the weights themselves are exact.

### 2. Every outcome and the state it leads to

| Outcome | Where | State afterwards (read with game_eval) |
|---|---|---|
| K.O. | I10 (DBG during a live needle) | "K.O.!" then "OFFER!", Dana's line; `finish_interview(true)` -> OFFER, offer built: co_bytebistro, $84,000 (hand-checked), office_days 2; the save holds phase OFFER |
| Wheel win | I12 (DBG, 42.5% wedge) | pointer stopped mid win wedge (turn 3.2125); OFFER, $75,000 (Self-Taught x0.9, hand-checked) |
| Wheel loss | I11 natural (82%), I5 DBG (62.5%) | pointer mid lose wedge (3.9098, 3.8125); `bark_dana_committee_lose`, then the card with `tip_research_company` + the worst question's model answer; JOB_HUNT |
| Composure 0 | I8 (DBG) | `bark_dana_composure_zero`, card (`tip_fundamentals` = the red question's own tip + model answer); JOB_HUNT; the Come clean earlier recorded `co_stealth|cv_self_taught_edu_lie` in `run.confessed` |
| BUSTED (debug) | I7, I13 | BUSTED! banner, Dana's line, then `tip_honesty_checks`; the interview went on to a rejection; `run.blacklist` = [co_adverse] / [co_beigeware] |
| Rejection with tip + model answer | I1, I2, I3, I4, I6b, I9 | "...WE'LL KEEP YOUR CV ON FILE." (joke), "We've decided to move forward with other candidates." (cause), Ducky card: one tip + "Real answer:" of the worst knowledge question + `[ Back to the hunt ]` (254x36); [II] hidden; tap or Esc -> JOB_HUNT, `interviews_taken` 1, `interview` {} |

Also seen: bluff held (I5, pre-rolled 25%, Doubt -15), Come clean (I8, I13: -5 / -10), the Intern's exclusive answer, teamwork x1.25 and x0.6, the Tired greeting and Tired label, the first-interview warm-up with Ducky's coach note, `bark_dana_greet_again` never on a first interview of a run (each setup was a fresh run).

### 3. Visible luck and thumb rules (measured with game_eval rects)

| | 270x480 | 294x639 with notch insets (0,45,0,26) |
|---|---|---|
| Meter row | x 8-262, y 264-304 | x 20-274, y 401-441 |
| Needle bar (drawn by AnswerMeter at the row y + 15) | x 35-235, y 279-289: inside the meter row | x 47-247, y 416-426: inside the meter row |
| Tap pad ("Tap anywhere!") | y 356-476 (67 px below the bar) | y 493-613 (67 px below the bar) |
| Answers | 3 x 254x36 at x 8, y 356 / 398 / 440 (gap 6), bottom at the safe edge | 3 x 254x36 at x 20, y 493 / 535 / 577 |
| [II] | 34x34 at (228,166) | 34x34 at (240,303) |
| Probe row | 2 x 124x47 at y 429 (gap 6) | 2 x 124x47 at y 566 |

- **Zone drawn before the needle moves:** during Dana's question the meter is visible with its zone and labels, `_meter_live` false, `_elapsed` 0, the needle at the left end, the meter IGNORE (screenshots at both sizes; I1, I7, I8 and I13).
- **250 ms locks:** a `game_eval`-timed tap on Answer 1 91 ms after the answers appeared was ignored (buttons IGNORE, answers still up), STOP again 300 ms later. The needle: a tap during Dana's typing finished the line without stopping the needle; a second tap 0.152 s after the needle started was ignored; a third at 0.456 s resolved it (GOOD) (run r65563361-33, timed taps). Real taps at 0.272-0.275 s were accepted.
- **Tap rule:** [II] (real tap) during a live needle opened Pause without resolving it; `_t` stayed 0.8397 over 0.5 s; Esc resumed. Real taps that stopped the needle: stage band (I1, I4, I5), bars band (I2), dialogue box (I1), meter row (I13); tap pad (timed taps: I3 prompt 4 and the lock check). The DBG button is the only other control that keeps its tap (debug builds only).

### 4. Tier personalities

- Startup PIVOT: I2 prompt 2 rolled `jump_at` 1.767 s, jumped once at 1.789 s (c 0.3274 -> 0.1251), `zone_jumped` emitted once, "PIVOT!" flashed, Dana's line became `bark_dana_pivot`. Other Startup prompts rolled 1.016-2.490 s: all inside 1.0-2.5 s. Mid and Big: `jump_at` -1.
- Needle speed: Startup and Mid 0.60, Big 0.75 bar-widths/s; Tired x1.15: Mid 0.69 (I6), Big 0.8625 (I3); the TIRED label showed.

### 5. Kill and resume (independent repeat)

Real flow: Title > New game > Intro SKIP > THE SELF-TAUGHT > Fake invite (Mid) (I6a). The save held phase INTERVIEW and the checkpoint (seed 205125375). After prompt 1, the warm-up and prompt 2 the game was killed with `project_manage stop`; `project_run main` > Title > CONTINUE put the same checkpoint back with `GameState.rng.state` = the saved 8554108018227685648. The replay (I6b) showed the same answer order on prompt 1 (same three texts), the same warm-up (S 50.73, h 0.1209, c 0.1998) and the same prompt 2 zone (c 0.847660601139069, h 0.120843315582275, S 50.70) although the answers and tap times were different. The debug quick start also replayed seed 2109228122 identically in runs 27, 31, 32 and 33.

### 6. Invariant and skeleton audit

- **INV-02/INV-01:** no `change_scene`, `change_phase(` or phase assignment under `features/` (grep + `flow/test_screens_never_change_phase_or_scene`); VersusIntro, HpBar, DuckyNote and PauseMenu are instanced.
- **INV-03:** every interview number comes from `Odds` (knowledge_p, stat_score, roll_luck, zone_half, needle_speed, answer_q, the deltas, spoken_grade, ethics_*, teamwork_mult, committee_*, bluff_p, bluff_band) or straight from `BalanceConfig` (probe deltas, which have no formula). The scene keeps Doubt and Composure (ARCHITECTURE 8).
- **INV-04:** `randf/randi/randi_range/shuffle/pick_random` appear only as methods of an explicit RandomNumberGenerator (`Odds`, `InterviewPlan.meter_rng`, `AnswerMeter` on the meter RNG, `GameState.rng`) and in tests; the global `randi()` only picks the run seed (skeleton). Interview randomness: interview RNG seeded from `run.interview.seed` in a fixed order, each meter on its own RNG seeded by one interview-RNG draw; answers shuffled with `Odds.shuffled`.
- **INV-05/INV-06/INV-07:** seed and RNG state are strings in the save; the checkpoint is plain (String/int/bool/Array); saves appeared only in live phases (INTERVIEW, JOB_HUNT, OFFER) and the kill/resume above.
- **INV-12:** the 10 test files are `@tool extends McpTestSuite`, every test asserts, none touches an autoload or `user://` (grep).
- **INV-14:** hit areas >= 34x34 with gaps >= 4 (table above; DBG 34x34 and 84x34 with 4 px gaps); everything tappable sits in a SafeAreaMargin except the full-screen tap-anywhere surfaces (meter, VS, Ready overlay); containers and panels in SafeArea are IGNORE; mouse events only.
- **INV-15:** no player-facing literal in the interview scripts except the "II" pause-icon stand-in (art pass) and number formats ("%d%%", "[###--]"); the dynamically built ids (`bark_dana_greet_<tier>`, `dana_title_<tier>`, `vs_banner_<tier>`, `bark_dana_<great|ok|bad>_<1-3>`, `ui_odds_<1-5>`) all exist in barks.json (checked with a script); `content_lint` 32/32.
- **INV-18:** formulas recomputed (section 1); the joke -> cause -> tip order now holds for BUSTED and Come clean (D2).
- **INV-19:** the column stays 254 px and centred at 294 px width; extra height went to the stage (spacer 252 px at 294x639 with insets); fonts at native sizes (PS2P 32/16, 8/16 name plates, monogram 16).
- **ARCHITECTURE 17 vs code** (extracted every 17.x code block and diffed): 17.1, 17.3, 17.5, 17.6, 17.8, 17.9, 17.10 and the 17.13 test skeletons match (test_flow has two later additions). Changes: 17.11 AnswerMeter: `set_bar_y()` (documented), `zone()` getter (builders' deviation) and the Vague clip (D1, this stage); 17.2 RunState: `settle_probe()` added (lie-probe stage); 17.4 Odds: `bluff_band()` added (lie-probe stage); 17.7 GameState: `start_interview` fills the Step-4 TODOs with InterviewPlan and adds `warmup_id`, `finish_interview` gains `came_clean` and calls `settle_probe` (documented in each builder's report; ARCHITECTURE text not updated yet).

### 7. Visual sanity (screenshots taken; no overlap or clipping found except as noted)

- **VS intro:** at 270x480 and at 294x639 with insets applied to its own SafeArea (plates inside y 45-613, split and colours full-bleed, "VS" on the diagonal, banner "ROUND 1: VIBE CHECK" / "ROUND 1 OF 7" in PS2P 16 on two lines).
- **Choice prompt:** 270x480, three answers stacked at the bottom, text left-aligned, no clipping (longest line "I'm a perfectionist who works too hard.").
- **Knowledge prompt with the meter:** 270x480 (warm-up with Ducky's coach note in the stage band) and 294x639 (zone and labels while Dana types, "Tap anywhere!" pad 67 px lower).
- **Wheel:** 270x480 twice (63% and 82%), 128 px in the stage band, percentage on the green wedge.
- **Ducky card:** 270x480 and 294x639: tip + "Real answer:" (up to 6 lines) and `[ Back to the hunt ]` inside the thumb band, banner in the stage band, [II] hidden.
- **BUSTED:** 294x639, banner over the busts, note in the thumb band.

## Findings not fixed (for the developer and the lead)

1. **Content typo:** `bark_dana_greet_big` + `co_adverse` renders "Welcome to Engagement Farms Inc.. You have 45 minutes." (double period). Needs a wording decision in CONTENT.md (drop the period from the company name, or rephrase the greeting); not changed here (W: no new text).
2. **Probe buttons are 124x47, not 124x44** (GDD S08, ARCHITECTURE 11.6): the two-line Bluff label plus the button padding needs 47 px. Harmless for touch (>= 34, fits the thumb band); fix in the theme pass if the exact size matters.
3. **Art-pass risk for INV-19:** the bars band labels (COMPOSURE, ROUND n/5, DOUBT) and the DBG toggle sit directly over the full-bleed stage. Fine on today's solid tier colour; when the stage becomes parallax art, the bars band needs its own solid strip.
4. **Replay after seeing the ending:** [II] stays available during the K.O., wheel and rejection beats, so Pause > Quit to title > CONTINUE replays the whole interview (same dice, same questions) with hindsight about the answers. That is how ARCHITECTURE 8 / GDD 5.11 define resume ("quitting can't re-roll" holds for the dice); flagging it as a design question, not a defect.
5. **UX note:** on a Startup PIVOT, Dana's question is replaced by "Quick update: we pivoted." while the needle is still running, so the question text disappears mid-answer.
6. **Balance (D8 input):** 0 natural wins in 7 natural interviews (first interview of each run, no research, no study). Consistent with GDD 5.12's first-interview pass rates (15-37%), but worth feeling on the device before Playtest #1.

## game_eval use

- **Setup:** `GameState.debug_quick_start(bg, JOB_HUNT, seed)` + `GameState.start_interview({...})` for 10 of the 13 interviews (the hunt stub only offers a Mid invite); `run.first_run = false` in 9 of them to skip the warm-up; `GameState.set_setting("options", "relaxed_timing", true/false)` for I9.
- **Timed input (fallback):** near-perfect needle taps, the VS skip timing (0.58 s ignored, 1.10 s skipped), the answer-lock tap at 91 ms and the needle-lock taps (0.152 s ignored, 0.456 s accepted), all through `Input.parse_input_event`.
- **Probes and captures:** the 294x639 viewport (`root.content_scale_aspect` KEEP + `content_scale_size`) and `SafeAreaMargin.debug_fake_insets`, then back to EXPAND 270x480; `Engine.time_scale` 0.02-0.05 to screenshot the VS and the typing state; the zone centre set to h and restored for the D1 screenshot; the luck replay for the hand recomputation.
- **Read-only:** scene state, rects, run state, save contents.
- No button was pressed by emitting `pressed`, and no Doubt or Composure was set from game_eval (forced outcomes used the DBG buttons with real taps).

## Cleanup

`user://save_v1.json` and `user://settings.cfg` were deleted with `SaveIO.delete()` and `DirAccess.remove_absolute()` at the end of the runs that wrote them; `C:/Users/Mmotkim/AppData/Roaming/Godot/app_userdata/SWE Simulator/` holds neither. The game is stopped. Both fixed files were checked on disk after the last run (no stale editor buffer wrote them back).

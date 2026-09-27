# STEP-04 agent playtest: interview traces (verifier, 2026-09-27, Windows PC)

Godot 4.7.2-stable (steam), godot-ai MCP, game embedded in the editor (window 540x960, game 270x480 at 2x unless noted). 13 interviews plus one resumed replay (I6a killed, I6b continued after Continue): every tier and every background, several combinations twice. Raw IVSTART/IVTRACE/IVRESULT lines are at the end.

**Input legend** (the "input" column):
- **R**: a real `game_manage input_mouse` tap (motion to the spot, then press and release; window px = 2x game px). Tool latency is 2-3 s per call, so real needle taps land at effectively random times ("varied timing"), often late.
- **T**: a **game_eval fallback** for a near-perfect tap: a `game_eval` coroutine waits until the needle is within 0.1 h of the zone centre, then sends a left press and release with `Input.parse_input_event` at a stage or tap-pad position (the engine input path; it reaches `AnswerMeter._gui_input` through the GUI). The tool latency makes a deliberate near-perfect `input_mouse` tap impossible.
- **A**: auto-miss (GDD 5.8.4: no tap within 3 round trips = I 0.2); the real tap arrived after it.
- **F**: an outcome forced with the debug panel (real `input_mouse` taps on DBG and the outcome button).

Tables: prompt 0 is the warm-up (it changes nothing). Doubt and Comp are the values after the prompt. S = Stat Score, h = NAILED IT half-width, c = zone centre before any pivot, I = input quality, Q = 0.75 S + 25 I.

## I1: Graduate / Mid (co_beigeware)

- Setup: project_run custom interview.tscn, debug quick start (fixed debug seed). Run `r62233196-27`.
- Checkpoint: seed 2109228122, tired=false, warm-up `kq_hash_map`, questions `eq_weakness,kq_index_tradeoff,kq_star_conflict,kq_learn_fast,eq_leaked_password`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_weakness | choice |  |  |  |  |  | good (order bad,neutral,good) | 118.00 | 100.00 | R good |
| 0 | kq_hash_map | warmup | 58.72 | 0.1305 | 0.1554 | 0.20 | 49.04 | yellow | 118.00 | 100.00 | A (auto-miss: no tap in 3 round trips; the real tap arrived later) |
| 2 | kq_index_tradeoff | knowledge | 50.08 | 0.1601 | 0.2855 | 0.80 | 57.56 | yellow | 93.19 | 100.00 | R tap on the dialogue box |
| 3 | kq_star_conflict | knowledge | 33.40 | 0.1001 | 0.6620 | 0.20 | 30.05 | red | 93.15 | 80.05 | R tap on the stage band |
| 4 | kq_learn_fast | knowledge | 42.18 | 0.1106 | 0.6922 | 1.00 | 56.63 | yellow | 69.18 | 80.05 | T |
| 5 | eq_leaked_password | choice |  |  |  |  |  | bad (order good,neutral,bad) | 77.18 | 65.05 | R bad |

**Result:** `rejected`, Doubt 77.18, Composure 65.05, busted=false, came_clean=false.

## I2: Intern / Startup (co_synergai)

- Setup: game_eval: debug_quick_start(intern, JOB_HUNT, 111) + start_interview. Run `r62233196-27`.
- Checkpoint: seed 1691385151, tired=false, warm-up `kq_recursion_base`, questions `eq_credit_theft,kq_cache_first_fix,kq_failure_story,kq_password_storage,eq_leaked_password`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_credit_theft | choice |  |  |  |  |  | good (order good,good,bad) | 105.50 | 100.00 | R Intern exclusive answer (good) |
| 0 | kq_recursion_base | warmup | 46.40 | 0.1157 | 0.2618 | 0.80 | 54.80 | yellow | 105.50 | 100.00 | R (after the PIVOT) |
| 2 | kq_cache_first_fix | knowledge | 53.03 | 0.1236 | 0.3274 | 1.00 | 64.78 | green | 74.20 | 100.00 | T (after the PIVOT at 1.789 s) |
| 3 | kq_failure_story | knowledge | 62.80 | 0.1354 | 0.7727 | 0.20 | 52.10 | yellow | 54.32 | 100.00 | R tap on the bars band (late, 9.1 s) |
| 4 | kq_password_storage | knowledge | 42.87 | 0.1114 | 0.2175 | 1.00 | 57.15 | yellow | 29.88 | 100.00 | T |
| 5 | eq_leaked_password | choice |  |  |  |  |  | good (order good,bad,neutral) | 19.88 | 100.00 | R good |

**Result:** `rejected`, Doubt 19.88, Composure 100.00, busted=false, came_clean=false.

## I3: Self-Taught / Big, Tired (co_omniglobal)

- Setup: game_eval: debug_quick_start(self_taught, JOB_HUNT, 222) + start_interview; first_run=false. Run `r62233196-27`.
- Checkpoint: seed 2917880068, tired=true, warm-up `-`, questions `eq_meeting_overload,kq_cache_first_fix,kq_password_storage,kq_nested_loops,eq_any_questions`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_meeting_overload | choice |  |  |  |  |  | neutral (order neutral,good,bad) | 128.00 | 90.00 | R neutral |
| 2 | kq_cache_first_fix | knowledge | 35.57 | 0.1027 | 0.5481 | 0.20 | 31.67 | red | 126.49 | 71.67 | A (the real [II] tap arrived after the auto-miss) |
| 3 | kq_password_storage | knowledge | 48.71 | 0.1185 | 0.6125 | 0.20 | 41.54 | red | 116.11 | 63.21 | A ([II] tapped during the live needle: paused, needle frozen; Esc resumed; the tap-pad tap arrived after the auto-miss) |
| 4 | kq_nested_loops | knowledge | 53.25 | 0.1239 | 0.4914 | 1.00 | 64.93 | green | 84.67 | 63.21 | T |
| 5 | eq_any_questions | choice |  |  |  |  |  | bad (order good,neutral,bad) | 92.67 | 48.21 | R bad |

**Result:** `rejected`, Doubt 92.67, Composure 48.21, busted=false, came_clean=false.

## I4: Graduate / Startup (co_quantumleaf)

- Setup: game_eval setup, seed 333, first_run=false. Run `r62233196-27`.
- Checkpoint: seed 2205089396, tired=false, warm-up `-`, questions `eq_harsh_review,kq_idempotent,kq_sql_injection,kq_rebase_merge,eq_any_questions`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_harsh_review | choice |  |  |  |  |  | good (order neutral,bad,good) | 108.00 | 100.00 | R good |
| 2 | kq_idempotent | knowledge | 42.32 | 0.1508 | 0.5575 | 1.00 | 56.74 | yellow | 83.93 | 100.00 | T |
| 3 | kq_sql_injection | knowledge | 50.84 | 0.1210 | 0.3777 | 0.50 | 50.63 | yellow | 65.36 | 100.00 | R (0.27 s after the needle started) |
| 4 | kq_rebase_merge | knowledge | 52.91 | 0.1235 | 0.4915 | 1.00 | 64.68 | green | 34.15 | 100.00 | T |
| 5 | eq_any_questions | choice |  |  |  |  |  | good (order good,neutral,bad) | 24.15 | 100.00 | R good |

**Result:** `rejected`, Doubt 24.15, Composure 100.00, busted=false, came_clean=false.

## I5: Intern / Big (co_nimbus)

- Setup: game_eval setup, seed 444; VS skip timing checked with game_eval-timed taps; DBG Probe: edu (real taps). Run `r62233196-27`.
- Checkpoint: seed 3624943265, tired=false, warm-up `-`, questions `eq_weakness,kq_idempotent,kq_binary_search,kq_password_storage,eq_any_questions`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_weakness | choice |  |  |  |  |  | good (order good,bad,neutral) | 122.00 | 100.00 | R good |
| 2 | kq_idempotent | knowledge | 58.40 | 0.1301 | 0.7138 | 1.00 | 68.80 | green | 87.08 | 100.00 | T |
| 3 | cv_intern_edu_lie | probe |  |  |  |  |  | bluff_win (p 0.2500, band 2, pre-rolled holds=true) | 72.08 | 100.00 | R Bluff (pre-rolled: held) |
| 4 | kq_password_storage | knowledge | 32.58 | 0.0991 | 0.1407 | 0.20 | 29.43 | red | 72.08 | 79.43 | R (0.49 s) |

`IVDEBUG|probe=cv_intern_edu_lie`

`IVFORCE|outcome=wheel_loss|prompt=5|doubt=72.08|comp=79.43`

`IVWHEEL|p=0.6250|won=false|forced=true`

**Result:** `wheel_loss`, Doubt 19.80, Composure 79.43, busted=false, came_clean=false.

## I6a: Self-Taught / Mid, Tired (co_beigeware), before the kill

- Setup: REAL FLOW: project_run main > New game > Intro SKIP > THE SELF-TAUGHT > Fake invite (Mid); killed with project_manage stop during Dana's reaction to prompt 2. Run `r63557049-28`.
- Checkpoint: seed 205125375, tired=true, warm-up `kq_learn_fast`, questions `eq_credit_theft,kq_rebase_merge,kq_estimate,kq_failure_story,eq_celebrity_orders`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_credit_theft | choice |  |  |  |  |  | good (order good,neutral,bad) | 122.00 | 90.00 | R good |
| 0 | kq_learn_fast | warmup | 50.73 | 0.1209 | 0.1998 | 0.80 | 58.05 | yellow | 122.00 | 90.00 | R (0.37 s) |
| 2 | kq_rebase_merge | knowledge | 50.70 | 0.1208 | 0.8477 | 0.20 | 43.03 | red | 110.28 | 83.03 | R (late, 8.1 s) |

**Result:** none (killed here; I6b is the same interview after Continue).

## I6b: Self-Taught / Mid, Tired (co_beigeware), after Continue

- Setup: project_run main > Title > CONTINUE (same checkpoint, RNG state restored). Run `r63698806-29`.
- Checkpoint: seed 205125375, tired=true, warm-up `kq_learn_fast`, questions `eq_credit_theft,kq_rebase_merge,kq_estimate,kq_failure_story,eq_celebrity_orders`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_credit_theft | choice |  |  |  |  |  | bad (order good,neutral,bad) | 136.00 | 75.00 | R bad |
| 0 | kq_learn_fast | warmup | 50.73 | 0.1209 | 0.1998 | 1.00 | 63.05 | green | 136.00 | 75.00 | R (0.27 s) |
| 2 | kq_rebase_merge | knowledge | 50.70 | 0.1208 | 0.8477 | 0.20 | 43.03 | red | 124.28 | 68.03 | R (late, 7.9 s) |
| 3 | kq_estimate | knowledge | 47.97 | 0.1176 | 0.5977 | 0.20 | 40.98 | red | 114.40 | 59.00 | R (late, 7.3 s) |
| 4 | kq_failure_story | knowledge | 31.47 | 0.0978 | 0.7240 | 0.20 | 28.60 | red | 114.40 | 37.60 | R (late, 7.2 s) |
| 5 | eq_celebrity_orders | choice |  |  |  |  |  | bad (order bad,good,neutral) | 122.40 | 22.60 | R bad |

**Result:** `rejected`, Doubt 122.40, Composure 22.60, busted=false, came_clean=false.

## I7: Graduate / Big (co_adverse), 294x639 + insets

- Setup: game_eval setup, seed 777, viewport 294x639, SafeAreaMargin.debug_fake_insets (0,45,0,26). Run `r64023884-30`.
- Checkpoint: seed 706147463, tired=false, warm-up `-`, questions `eq_meeting_overload,kq_sql_injection,kq_testing_pyramid,kq_estimate,eq_rto`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_meeting_overload | choice |  |  |  |  |  | good (order neutral,bad,good) | 122.00 | 100.00 | R good |
| 2 | kq_sql_injection | knowledge | 51.45 | 0.1617 | 0.3343 | 1.00 | 63.59 | green | 91.77 | 100.00 | T |
| 3 | kq_testing_pyramid | knowledge | 48.43 | 0.1181 | 0.6356 | 1.00 | 61.32 | green | 63.58 | 100.00 | T |
| 4 | kq_estimate | knowledge | 27.46 | 0.0929 | 0.5698 | 1.00 | 45.59 | yellow | 49.55 | 95.59 | T |
| 4 | - | probe (forced) |  |  |  |  |  | busted | 69.55 | 65.59 | F BUSTED (real taps on DBG) |

`IVFORCE|outcome=busted|prompt=4|doubt=49.55|comp=95.59`

**Result:** `rejected`, Doubt 69.55, Composure 65.59, busted=true, came_clean=false.

## I8: Self-Taught / Startup (co_stealth), 294x639 + insets

- Setup: game_eval setup, seed 888; DBG Probe: edu (real taps). Run `r64023884-30`.
- Checkpoint: seed 2175101251, tired=false, warm-up `-`, questions `eq_harsh_review,kq_sql_injection,kq_load_balancer,kq_learn_fast,eq_ai_takehome`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_harsh_review | choice |  |  |  |  |  | neutral (order neutral,bad,good) | 114.00 | 90.00 | R neutral |
| 2 | kq_sql_injection | knowledge | 41.92 | 0.1103 | 0.7177 | 0.20 | 36.44 | red | 108.20 | 76.44 | R (late, 9.9 s; zone centre moved to the bar edge by game_eval for the Vague-clip screenshot, restored before the tap) |
| 3 | cv_self_taught_edu_lie | probe |  |  |  |  |  | come_clean (p 0.2750, band 2, pre-rolled holds=false) | 103.20 | 66.44 | R Come clean |

`IVDEBUG|probe=cv_self_taught_edu_lie`

`IVFORCE|outcome=composure_zero|prompt=3|doubt=103.20|comp=66.44`

**Result:** `composure_zero`, Doubt 103.20, Composure 0.00, busted=false, came_clean=true.

## I9: Intern / Mid, Relaxed Timing on (co_pixelpivot)

- Setup: game_eval setup, seed 999; set_setting(options, relaxed_timing, true). Run `r64023884-30`.
- Checkpoint: seed 1847185421, tired=false, warm-up `-`, questions `eq_friday_deploy,kq_two_sum,kq_nested_loops,kq_cache_first_fix,eq_celebrity_orders`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_friday_deploy | choice |  |  |  |  |  | good (order neutral,bad,good) | 118.00 | 100.00 | R good |
| 2 | kq_two_sum | knowledge | 51.21 | 0.1214 | 0.6846 | 0.90 | 60.91 | green | 90.18 | 100.00 | R (0.46 s) |
| 3 | kq_nested_loops | knowledge | 53.75 | 0.1245 | 0.4116 | 0.90 | 62.81 | green | 60.65 | 100.00 | R (7.7 s) |
| 4 | kq_cache_first_fix | knowledge | 41.44 | 0.1097 | 0.1225 | 0.90 | 53.58 | yellow | 39.43 | 100.00 | R (7.8 s) |
| 5 | eq_celebrity_orders | choice |  |  |  |  |  | good (order bad,neutral,good) | 29.43 | 100.00 | R good |

**Result:** `rejected`, Doubt 29.43, Composure 100.00, busted=false, came_clean=false.

## I10: Graduate / Mid (co_bytebistro)

- Setup: game_eval setup, seed 1010. Run `r64023884-30`.
- Checkpoint: seed 3997514125, tired=false, warm-up `-`, questions `eq_weakness,kq_recursion_base,kq_deadlock,kq_rebase_merge,eq_ai_takehome`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_weakness | choice |  |  |  |  |  | good (order good,bad,neutral) | 118.00 | 100.00 | R good |
| 2 | kq_recursion_base | knowledge | 59.20 | 0.1710 | 0.7447 | 1.00 | 69.40 | green | 82.54 | 100.00 | T |

`IVFORCE|outcome=ko|prompt=3|doubt=82.54|comp=100.00`

**Result:** `ko`, Doubt 0.00, Composure 100.00, busted=false, came_clean=false.

## I11: Intern / Startup (co_synergai)

- Setup: game_eval setup, seed 1111. Run `r64023884-30`.
- Checkpoint: seed 987467840, tired=false, warm-up `-`, questions `eq_weakness,kq_failure_story,kq_cache_first_fix,kq_left_join,eq_impossible_deadline`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_weakness | choice |  |  |  |  |  | good (order bad,good,neutral) | 108.00 | 100.00 | R good |
| 2 | kq_failure_story | knowledge | 44.43 | 0.1133 | 0.2412 | 1.00 | 58.32 | yellow | 82.51 | 100.00 | T |
| 3 | kq_cache_first_fix | knowledge | 56.49 | 0.1278 | 0.4375 | 1.00 | 67.37 | green | 48.88 | 100.00 | T (after the PIVOT) |
| 4 | kq_left_join | knowledge | 59.86 | 0.1318 | 0.6976 | 1.00 | 69.90 | green | 12.97 | 100.00 | T |
| 5 | eq_impossible_deadline | choice |  |  |  |  |  | good (order neutral,good,bad) | 0.47 | 100.00 | R good (teamwork x1.25) |

`IVWHEEL|p=0.8196|won=false|forced=false`

**Result:** `wheel_loss`, Doubt 0.47, Composure 100.00, busted=false, came_clean=false.

## I12: Self-Taught / Mid, Tired (co_beigeware)

- Setup: game_eval setup, seed 1212. Run `r64023884-30`.
- Checkpoint: seed 2843172672, tired=true, warm-up `-`, questions `eq_harsh_review,kq_learn_fast,kq_rebase_merge,kq_sql_injection,eq_any_questions`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|

`IVFORCE|outcome=wheel_win|prompt=0|doubt=128.00|comp=90.00`

`IVWHEEL|p=0.4250|won=true|forced=true`

**Result:** `wheel_win`, Doubt 19.20, Composure 90.00, busted=false, came_clean=false.

## I13: Graduate / Mid (co_beigeware), after both fixes

- Setup: project_run custom, debug quick start; DBG Probe: edu. Run `r65082541-31`.
- Checkpoint: seed 2109228122, tired=false, warm-up `kq_hash_map`, questions `eq_weakness,kq_index_tradeoff,kq_star_conflict,kq_learn_fast,eq_leaked_password`.

| prompt | id | kind | S | h | c | I | Q | answer | Doubt | Comp | input |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | eq_weakness | choice |  |  |  |  |  | good (order bad,neutral,good) | 118.00 | 100.00 | R good |
| 0 | kq_hash_map | warmup | 58.72 | 0.1305 | 0.1554 | 1.00 | 69.04 | green | 118.00 | 100.00 | R tap on the meter row (0.275 s) |
| 2 | kq_index_tradeoff | knowledge | 50.08 | 0.1601 | 0.2855 | 0.80 | 57.56 | yellow | 93.19 | 100.00 | R (0.27 s) |
| 3 | cv_graduate_edu_lie | probe |  |  |  |  |  | come_clean (p 0.3500, band 2, pre-rolled holds=true) | 88.19 | 90.00 | R Come clean |
| 3 | cv_graduate_edu_lie | probe (forced) |  |  |  |  |  | busted | 108.19 | 60.00 | F BUSTED |

`IVDEBUG|probe=cv_graduate_edu_lie`

`IVFORCE|outcome=busted|prompt=3|doubt=88.19|comp=90.00`

**Result:** `rejected`, Doubt 108.19, Composure 60.00, busted=true, came_clean=true.

## Summary

### Outcomes per tier and background

| # | tier | background | outcome | how |
|---|---|---|---|---|
| I1 | mid | graduate | rejected | natural |
| I2 | startup | intern | rejected | natural |
| I3 | big | self_taught | rejected | natural |
| I4 | startup | graduate | rejected | natural |
| I5 | big | intern | wheel_loss | forced (DBG) |
| I6b | mid | self_taught | rejected | natural |
| I7 | big | graduate | rejected | forced (DBG) |
| I8 | startup | self_taught | composure_zero | forced (DBG) |
| I9 | mid | intern | rejected | natural |
| I10 | mid | graduate | ko | forced (DBG) |
| I11 | startup | intern | wheel_loss | natural |
| I12 | mid | self_taught | wheel_win | forced (DBG) |
| I13 | mid | graduate | rejected | forced (DBG) |

- Natural outcomes by tier: big rejected x1, mid rejected x3, startup rejected x2, startup wheel_loss x1.
- Natural outcomes by background: graduate rejected x2, intern rejected x2, intern wheel_loss x1, self_taught rejected x2.
- Forced with the debug panel: I5 wheel_loss (big/intern), I7 rejected (big/graduate), I8 composure_zero (startup/self_taught), I10 ko (mid/graduate), I12 wheel_win (mid/self_taught), I13 rejected (mid/graduate).
- Every outcome was seen at least once: K.O. (I10), wheel win (I12), wheel loss (I11 natural at 82%, I5 forced), Composure 0 (I8), BUSTED via debug (I7, I13), and rejections with a tip plus the model answer (I1, I2, I3, I4, I6b, I9, and after I7/I13).

### Doubt damage: knowledge vs choice prompts

- Knowledge prompts (29; warm-ups, forced beats and the killed I6a excluded): mean Doubt change **-21.04** (range -35.91 to 0.00).
- Choice prompts (19): mean Doubt change **-5.84** (range -12.50 to 8.00).
- Probe prompts (3, natural): -15.00, -5.00, -5.00.
- Knowledge prompts with PERFECT taps (14): mean Doubt change -28.88; with MISS or auto-miss (9): -6.58.

### Do stats dominate the thumb? (INV-18, GDD 5.8.4)

- Share of Q from the stats (0.75 S / Q) over the 29 knowledge prompts: mean **69%** (range 45% to 90%); share from the tap (25 I / Q): mean 31%. The realized stats share sits below 75% because this sample is skewed toward the thumb's best case (14 of the 29 prompts were near-perfect "T" taps, I 1.0, where a mid S gives about 60%); with a miss it is 85-90%. The weights themselves are exactly 0.75 and 25 (hand recomputation below), which is what INV-18 fixes.
- S ranged 27.46 to 62.80, so the stats part of Q (0.75 S) ranged 20.6 to 47.1 points, while the tap can move Q by at most 20 points (I 0.2 to 1.0). S also sets the zone width h (0.09 to 0.17 here), so a weaker character gets a smaller target as well.
- I11 (Intern at Startup) with three PERFECT taps reached Doubt 0.47 and the wheel; I4 (Graduate at Startup) with two PERFECT taps and one CLOSE ended at Doubt 24.15 (rejected); I7 (Graduate at Big) with three PERFECT taps was still at Doubt 49.55 before prompt 5. Stats and luck, not the thumb, separated those interviews.
- Relaxed Timing (I9, I fixed at 0.9) left the Intern at Mid on Doubt 29.43 (rejected), in line with GDD 5.12 ("slightly below an average tapper").

### Hand recomputation (INV-18: Q = 0.75 S + 25 I)

Formulas from GDD 5.8.4 / `Odds` (ARCHITECTURE 17.4) with the `.tres` values: `balance_config.tres` keeps the script defaults (stat_sensitivity 0.7, luck_range 12, weak_penalty 15, tech 0.7/0.3, behavioral 0.3/0.7, question_diff_offsets -5/0/+5, zone 0.06 + 0.12 S/100, Q weights 0.75 and 25, Doubt -0.9 x max(0, Q - 30), Composure -max(0, 50 - Q), green >= 60, yellow >= 45); tiers: Startup difficulty 40, Mid 42 (script default), Big 44; backgrounds: Graduate KNW 55 / EXP 15 / textbook +0.04 (script defaults), Intern 50 / 40 / textbook 0, Self-Taught 55 / 10 / textbook 0. The luck value is the only hidden input, so it was replayed in the running game with the real code path (`InterviewPlan.interview_rng(seed)`, then the same draw order: `Odds.shuffled` for prompt 1's three answers, then `Odds.roll_luck` + one `InterviewPlan.meter_rng` draw per knowledge prompt).

| Interview / prompt | P | d | luck (replayed) | S | h | Q | Doubt after | Comp after | grade | trace |
|---|---|---|---|---|---|---|---|---|---|---|
| I1 p2 `kq_index_tradeoff` (Graduate, Mid; tech, diff 2, weak_for graduate; first real knowledge prompt: textbook +0.04; GOOD I 0.8) | 0.7x55 + 0.3x15 - 15 = 28 | 42 | +9.8830 | 50 + 0.7x(28 - 42) + 9.883 = 50.083 | 0.06 + 0.0601 + 0.04 = 0.1601 | 37.562 + 20 = 57.562 | 118 - 0.9x27.562 = 93.194 | 100 | yellow | S 50.08, h 0.1601, Q 57.56, Doubt 93.19: match |
| I1 p3 `kq_star_conflict` (Graduate, Mid; behavioral, diff 1, not weak; MISS I 0.2) | 0.3x55 + 0.7x15 = 27 | 37 | -9.6041 | 33.396 | 0.1001 | 25.047 + 5 = 30.047 | 93.194 - 0.042 = 93.152 | 100 - 19.953 = 80.047 | red | S 33.40, h 0.1001, Q 30.05, Doubt 93.15, Comp 80.05: match |
| I2 p2 `kq_cache_first_fix` (Intern, Startup; tech, diff 3, not weak; PERFECT I 1.0) | 0.7x50 + 0.3x40 = 47 | 45 | +1.6335 | 53.034 | 0.1236 | 39.775 + 25 = 64.775 | 105.5 - 31.298 = 74.202 | 100 | green | S 53.03, h 0.1236, Q 64.78, Doubt 74.20: match |
| I3 p4 `kq_nested_loops` (Self-Taught, Big, Tired; tech, diff 1, weak_for self_taught and gap topic algorithms, one -15; PERFECT) | 0.7x55 + 0.3x10 - 15 = 26.5 | 39 | +11.9960 | 53.246 | 0.1239 | 39.934 + 25 = 64.934 | 116.111 - 31.441 = 84.670 | 63.21 | green | S 53.25, h 0.1239, Q 64.93, Doubt 84.67: match |

Other numbers checked against the traces: teamwork good answers -12.5 (Intern x1.25, I2 and I11) and -6 (Self-Taught x0.6, I6a); neutral -4, bad +8 / -15; bluff odds 0.25 (Intern at Big, degree claim: 0.50 + 0 + 0.10 - 0.15 - 0.20), 0.275 (Self-Taught at Startup, degree claim: 0.50 + 0.025 - 0.05 - 0 - 0.20), 0.35 (Graduate at Mid, normal lie: 0.50 + 0.025 - 0.025 - 0.05 - 0.10), each band 2 "Unlikely"; Come clean -5 / -10; bluff held -15; BUSTED +20 / -30; wheel odds 0.8196 (I11: 0.40 + 0.20 x (1 - 0.475 / 17.7) + 45/200), 0.625 (I5, Doubt at the band edge), 0.425 (I12: Self-Taught NET 5); offers $84,000 (Graduate, Mid, Composure 100/100: band 0.25 + 0.50 = 0.75 -> 83,750 -> 84,000) and $75,000 (Self-Taught x0.9 -> 75,375 -> 75,000).

## Raw trace lines (logs_read source="game")

All game logs of runs r62233196-27 to r65321727-32 held only info lines: 0 errors, 0 warnings.

```
RUN r62233196-27 (project_run custom interview.tscn; interviews 2-5 set up with game_eval GameState.debug_quick_start + GameState.start_interview)
IVSTART|tier=mid|bg=graduate|company=co_beigeware|seed=2109228122|doubt=128.00|comp=100.00|tired=false|warmup=kq_hash_map|probe=|ids=eq_weakness,kq_index_tradeoff,kq_star_conflict,kq_learn_fast,eq_leaked_password|taken=0
IVTRACE|prompt=1|id=eq_weakness|kind=choice|order=bad,neutral,good|answer=good|doubt=118.00|comp=100.00
IVTRACE|prompt=0|id=kq_hash_map|kind=warmup|S=58.72|h=0.1305|c=0.1554|I=0.20|Q=49.04|answer=yellow|doubt=118.00|comp=100.00
IVTRACE|prompt=2|id=kq_index_tradeoff|kind=knowledge|S=50.08|h=0.1601|c=0.2855|I=0.80|Q=57.56|answer=yellow|doubt=93.19|comp=100.00
IVTRACE|prompt=3|id=kq_star_conflict|kind=knowledge|S=33.40|h=0.1001|c=0.6620|I=0.20|Q=30.05|answer=red|doubt=93.15|comp=80.05
IVTRACE|prompt=4|id=kq_learn_fast|kind=knowledge|S=42.18|h=0.1106|c=0.6922|I=1.00|Q=56.63|answer=yellow|doubt=69.18|comp=80.05
IVTRACE|prompt=5|id=eq_leaked_password|kind=choice|order=good,neutral,bad|answer=bad|doubt=77.18|comp=65.05
IVRESULT|outcome=rejected|doubt=77.18|comp=65.05|busted=false|came_clean=false|tier=mid|bg=graduate
IVSTART|tier=startup|bg=intern|company=co_synergai|seed=1691385151|doubt=118.00|comp=100.00|tired=false|warmup=kq_recursion_base|probe=|ids=eq_credit_theft,kq_cache_first_fix,kq_failure_story,kq_password_storage,eq_leaked_password|taken=0
IVTRACE|prompt=1|id=eq_credit_theft|kind=choice|order=good,good,bad|answer=good|doubt=105.50|comp=100.00
IVTRACE|prompt=0|id=kq_recursion_base|kind=warmup|S=46.40|h=0.1157|c=0.2618|I=0.80|Q=54.80|answer=yellow|doubt=105.50|comp=100.00
IVTRACE|prompt=2|id=kq_cache_first_fix|kind=knowledge|S=53.03|h=0.1236|c=0.3274|I=1.00|Q=64.78|answer=green|doubt=74.20|comp=100.00
IVTRACE|prompt=3|id=kq_failure_story|kind=knowledge|S=62.80|h=0.1354|c=0.7727|I=0.20|Q=52.10|answer=yellow|doubt=54.32|comp=100.00
IVTRACE|prompt=4|id=kq_password_storage|kind=knowledge|S=42.87|h=0.1114|c=0.2175|I=1.00|Q=57.15|answer=yellow|doubt=29.88|comp=100.00
IVTRACE|prompt=5|id=eq_leaked_password|kind=choice|order=good,bad,neutral|answer=good|doubt=19.88|comp=100.00
IVRESULT|outcome=rejected|doubt=19.88|comp=100.00|busted=false|came_clean=false|tier=startup|bg=intern
IVSTART|tier=big|bg=self_taught|company=co_omniglobal|seed=2917880068|doubt=132.00|comp=90.00|tired=true|warmup=|probe=|ids=eq_meeting_overload,kq_cache_first_fix,kq_password_storage,kq_nested_loops,eq_any_questions|taken=0
IVTRACE|prompt=1|id=eq_meeting_overload|kind=choice|order=neutral,good,bad|answer=neutral|doubt=128.00|comp=90.00
IVTRACE|prompt=2|id=kq_cache_first_fix|kind=knowledge|S=35.57|h=0.1027|c=0.5481|I=0.20|Q=31.67|answer=red|doubt=126.49|comp=71.67
IVTRACE|prompt=3|id=kq_password_storage|kind=knowledge|S=48.71|h=0.1185|c=0.6125|I=0.20|Q=41.54|answer=red|doubt=116.11|comp=63.21
IVTRACE|prompt=4|id=kq_nested_loops|kind=knowledge|S=53.25|h=0.1239|c=0.4914|I=1.00|Q=64.93|answer=green|doubt=84.67|comp=63.21
IVTRACE|prompt=5|id=eq_any_questions|kind=choice|order=good,neutral,bad|answer=bad|doubt=92.67|comp=48.21
IVRESULT|outcome=rejected|doubt=92.67|comp=48.21|busted=false|came_clean=false|tier=big|bg=self_taught
IVSTART|tier=startup|bg=graduate|company=co_quantumleaf|seed=2205089396|doubt=118.00|comp=100.00|tired=false|warmup=|probe=|ids=eq_harsh_review,kq_idempotent,kq_sql_injection,kq_rebase_merge,eq_any_questions|taken=0
IVTRACE|prompt=1|id=eq_harsh_review|kind=choice|order=neutral,bad,good|answer=good|doubt=108.00|comp=100.00
IVTRACE|prompt=2|id=kq_idempotent|kind=knowledge|S=42.32|h=0.1508|c=0.5575|I=1.00|Q=56.74|answer=yellow|doubt=83.93|comp=100.00
IVTRACE|prompt=3|id=kq_sql_injection|kind=knowledge|S=50.84|h=0.1210|c=0.3777|I=0.50|Q=50.63|answer=yellow|doubt=65.36|comp=100.00
IVTRACE|prompt=4|id=kq_rebase_merge|kind=knowledge|S=52.91|h=0.1235|c=0.4915|I=1.00|Q=64.68|answer=green|doubt=34.15|comp=100.00
IVTRACE|prompt=5|id=eq_any_questions|kind=choice|order=good,neutral,bad|answer=good|doubt=24.15|comp=100.00
IVRESULT|outcome=rejected|doubt=24.15|comp=100.00|busted=false|came_clean=false|tier=startup|bg=graduate
IVSTART|tier=big|bg=intern|company=co_nimbus|seed=3624943265|doubt=132.00|comp=100.00|tired=false|warmup=|probe=|ids=eq_weakness,kq_idempotent,kq_binary_search,kq_password_storage,eq_any_questions|taken=0
IVDEBUG|probe=cv_intern_edu_lie
IVTRACE|prompt=1|id=eq_weakness|kind=choice|order=good,bad,neutral|answer=good|doubt=122.00|comp=100.00
IVTRACE|prompt=2|id=kq_idempotent|kind=knowledge|S=58.40|h=0.1301|c=0.7138|I=1.00|Q=68.80|answer=green|doubt=87.08|comp=100.00
IVTRACE|prompt=3|id=cv_intern_edu_lie|kind=probe|degree_claim=true|p=0.2500|band=2|holds=true|answer=bluff_win|doubt=72.08|comp=100.00
IVTRACE|prompt=4|id=kq_password_storage|kind=knowledge|S=32.58|h=0.0991|c=0.1407|I=0.20|Q=29.43|answer=red|doubt=72.08|comp=79.43
IVFORCE|outcome=wheel_loss|prompt=5|doubt=72.08|comp=79.43
IVWHEEL|p=0.6250|won=false|forced=true
IVRESULT|outcome=wheel_loss|doubt=19.80|comp=79.43|busted=false|came_clean=false|tier=big|bg=intern
RUN r63557049-28 (project_run main: Title > New game > Intro SKIP > THE SELF-TAUGHT > Hunt > Fake invite (Mid); killed with project stop during prompt 3)
IVSTART|tier=mid|bg=self_taught|company=co_beigeware|seed=205125375|doubt=128.00|comp=90.00|tired=true|warmup=kq_learn_fast|probe=|ids=eq_credit_theft,kq_rebase_merge,kq_estimate,kq_failure_story,eq_celebrity_orders|taken=0
IVTRACE|prompt=1|id=eq_credit_theft|kind=choice|order=good,neutral,bad|answer=good|doubt=122.00|comp=90.00
IVTRACE|prompt=0|id=kq_learn_fast|kind=warmup|S=50.73|h=0.1209|c=0.1998|I=0.80|Q=58.05|answer=yellow|doubt=122.00|comp=90.00
IVTRACE|prompt=2|id=kq_rebase_merge|kind=knowledge|S=50.70|h=0.1208|c=0.8477|I=0.20|Q=43.03|answer=red|doubt=110.28|comp=83.03
RUN r63698806-29 (project_run main: Title > CONTINUE; the same interview replayed, different answers and taps)
IVSTART|tier=mid|bg=self_taught|company=co_beigeware|seed=205125375|doubt=128.00|comp=90.00|tired=true|warmup=kq_learn_fast|probe=|ids=eq_credit_theft,kq_rebase_merge,kq_estimate,kq_failure_story,eq_celebrity_orders|taken=0
IVTRACE|prompt=1|id=eq_credit_theft|kind=choice|order=good,neutral,bad|answer=bad|doubt=136.00|comp=75.00
IVTRACE|prompt=0|id=kq_learn_fast|kind=warmup|S=50.73|h=0.1209|c=0.1998|I=1.00|Q=63.05|answer=green|doubt=136.00|comp=75.00
IVTRACE|prompt=2|id=kq_rebase_merge|kind=knowledge|S=50.70|h=0.1208|c=0.8477|I=0.20|Q=43.03|answer=red|doubt=124.28|comp=68.03
IVTRACE|prompt=3|id=kq_estimate|kind=knowledge|S=47.97|h=0.1176|c=0.5977|I=0.20|Q=40.98|answer=red|doubt=114.40|comp=59.00
IVTRACE|prompt=4|id=kq_failure_story|kind=knowledge|S=31.47|h=0.0978|c=0.7240|I=0.20|Q=28.60|answer=red|doubt=114.40|comp=37.60
IVTRACE|prompt=5|id=eq_celebrity_orders|kind=choice|order=bad,good,neutral|answer=bad|doubt=122.40|comp=22.60
IVRESULT|outcome=rejected|doubt=122.40|comp=22.60|busted=false|came_clean=false|tier=mid|bg=self_taught
RUN r64023884-30 (project_run main; 294x639 probe: root content_scale_size 294x639 + SafeAreaMargin.debug_fake_insets (0,45,0,26); setups via game_eval debug_quick_start + start_interview)
IVSTART|tier=big|bg=graduate|company=co_adverse|seed=706147463|doubt=132.00|comp=100.00|tired=false|warmup=|probe=|ids=eq_meeting_overload,kq_sql_injection,kq_testing_pyramid,kq_estimate,eq_rto|taken=0
IVTRACE|prompt=1|id=eq_meeting_overload|kind=choice|order=neutral,bad,good|answer=good|doubt=122.00|comp=100.00
IVTRACE|prompt=2|id=kq_sql_injection|kind=knowledge|S=51.45|h=0.1617|c=0.3343|I=1.00|Q=63.59|answer=green|doubt=91.77|comp=100.00
IVTRACE|prompt=3|id=kq_testing_pyramid|kind=knowledge|S=48.43|h=0.1181|c=0.6356|I=1.00|Q=61.32|answer=green|doubt=63.58|comp=100.00
IVTRACE|prompt=4|id=kq_estimate|kind=knowledge|S=27.46|h=0.0929|c=0.5698|I=1.00|Q=45.59|answer=yellow|doubt=49.55|comp=95.59
IVFORCE|outcome=busted|prompt=4|doubt=49.55|comp=95.59
IVTRACE|prompt=4|id=|kind=probe|answer=busted|forced=true|doubt=69.55|comp=65.59
IVRESULT|outcome=rejected|doubt=69.55|comp=65.59|busted=true|came_clean=false|tier=big|bg=graduate
IVSTART|tier=startup|bg=self_taught|company=co_stealth|seed=2175101251|doubt=118.00|comp=90.00|tired=false|warmup=|probe=|ids=eq_harsh_review,kq_sql_injection,kq_load_balancer,kq_learn_fast,eq_ai_takehome|taken=0
IVDEBUG|probe=cv_self_taught_edu_lie
IVTRACE|prompt=1|id=eq_harsh_review|kind=choice|order=neutral,bad,good|answer=neutral|doubt=114.00|comp=90.00
IVTRACE|prompt=2|id=kq_sql_injection|kind=knowledge|S=41.92|h=0.1103|c=0.7177|I=0.20|Q=36.44|answer=red|doubt=108.20|comp=76.44
IVTRACE|prompt=3|id=cv_self_taught_edu_lie|kind=probe|degree_claim=true|p=0.2750|band=2|holds=false|answer=come_clean|doubt=103.20|comp=66.44
IVFORCE|outcome=composure_zero|prompt=3|doubt=103.20|comp=66.44
IVRESULT|outcome=composure_zero|doubt=103.20|comp=0.00|busted=false|came_clean=true|tier=startup|bg=self_taught
IVSTART|tier=mid|bg=intern|company=co_pixelpivot|seed=1847185421|doubt=128.00|comp=100.00|tired=false|warmup=|probe=|ids=eq_friday_deploy,kq_two_sum,kq_nested_loops,kq_cache_first_fix,eq_celebrity_orders|taken=0
IVTRACE|prompt=1|id=eq_friday_deploy|kind=choice|order=neutral,bad,good|answer=good|doubt=118.00|comp=100.00
IVTRACE|prompt=2|id=kq_two_sum|kind=knowledge|S=51.21|h=0.1214|c=0.6846|I=0.90|Q=60.91|answer=green|doubt=90.18|comp=100.00
IVTRACE|prompt=3|id=kq_nested_loops|kind=knowledge|S=53.75|h=0.1245|c=0.4116|I=0.90|Q=62.81|answer=green|doubt=60.65|comp=100.00
IVTRACE|prompt=4|id=kq_cache_first_fix|kind=knowledge|S=41.44|h=0.1097|c=0.1225|I=0.90|Q=53.58|answer=yellow|doubt=39.43|comp=100.00
IVTRACE|prompt=5|id=eq_celebrity_orders|kind=choice|order=bad,neutral,good|answer=good|doubt=29.43|comp=100.00
IVRESULT|outcome=rejected|doubt=29.43|comp=100.00|busted=false|came_clean=false|tier=mid|bg=intern
IVSTART|tier=mid|bg=graduate|company=co_bytebistro|seed=3997514125|doubt=128.00|comp=100.00|tired=false|warmup=|probe=|ids=eq_weakness,kq_recursion_base,kq_deadlock,kq_rebase_merge,eq_ai_takehome|taken=0
IVTRACE|prompt=1|id=eq_weakness|kind=choice|order=good,bad,neutral|answer=good|doubt=118.00|comp=100.00
IVTRACE|prompt=2|id=kq_recursion_base|kind=knowledge|S=59.20|h=0.1710|c=0.7447|I=1.00|Q=69.40|answer=green|doubt=82.54|comp=100.00
IVFORCE|outcome=ko|prompt=3|doubt=82.54|comp=100.00
IVRESULT|outcome=ko|doubt=0.00|comp=100.00|busted=false|came_clean=false|tier=mid|bg=graduate
IVSTART|tier=startup|bg=intern|company=co_synergai|seed=987467840|doubt=118.00|comp=100.00|tired=false|warmup=|probe=|ids=eq_weakness,kq_failure_story,kq_cache_first_fix,kq_left_join,eq_impossible_deadline|taken=0
IVTRACE|prompt=1|id=eq_weakness|kind=choice|order=bad,good,neutral|answer=good|doubt=108.00|comp=100.00
IVTRACE|prompt=2|id=kq_failure_story|kind=knowledge|S=44.43|h=0.1133|c=0.2412|I=1.00|Q=58.32|answer=yellow|doubt=82.51|comp=100.00
IVTRACE|prompt=3|id=kq_cache_first_fix|kind=knowledge|S=56.49|h=0.1278|c=0.4375|I=1.00|Q=67.37|answer=green|doubt=48.88|comp=100.00
IVTRACE|prompt=4|id=kq_left_join|kind=knowledge|S=59.86|h=0.1318|c=0.6976|I=1.00|Q=69.90|answer=green|doubt=12.97|comp=100.00
IVTRACE|prompt=5|id=eq_impossible_deadline|kind=choice|order=neutral,good,bad|answer=good|doubt=0.47|comp=100.00
IVWHEEL|p=0.8196|won=false|forced=false
IVRESULT|outcome=wheel_loss|doubt=0.47|comp=100.00|busted=false|came_clean=false|tier=startup|bg=intern
IVSTART|tier=mid|bg=self_taught|company=co_beigeware|seed=2843172672|doubt=128.00|comp=90.00|tired=true|warmup=|probe=|ids=eq_harsh_review,kq_learn_fast,kq_rebase_merge,kq_sql_injection,eq_any_questions|taken=0
IVFORCE|outcome=wheel_win|prompt=0|doubt=128.00|comp=90.00
IVWHEEL|p=0.4250|won=true|forced=true
IVRESULT|outcome=wheel_win|doubt=19.20|comp=90.00|busted=false|came_clean=false|tier=mid|bg=self_taught
RUN r65082541-31 (after both fixes; project_run custom interview.tscn, debug quick start Graduate/Mid; DBG Probe edu; Come clean; DBG BUSTED)
IVSTART|tier=mid|bg=graduate|company=co_beigeware|seed=2109228122|doubt=128.00|comp=100.00|tired=false|warmup=kq_hash_map|probe=|ids=eq_weakness,kq_index_tradeoff,kq_star_conflict,kq_learn_fast,eq_leaked_password|taken=0
IVDEBUG|probe=cv_graduate_edu_lie
IVTRACE|prompt=1|id=eq_weakness|kind=choice|order=bad,neutral,good|answer=good|doubt=118.00|comp=100.00
IVTRACE|prompt=0|id=kq_hash_map|kind=warmup|S=58.72|h=0.1305|c=0.1554|I=1.00|Q=69.04|answer=green|doubt=118.00|comp=100.00
IVTRACE|prompt=2|id=kq_index_tradeoff|kind=knowledge|S=50.08|h=0.1601|c=0.2855|I=0.80|Q=57.56|answer=yellow|doubt=93.19|comp=100.00
IVTRACE|prompt=3|id=cv_graduate_edu_lie|kind=probe|degree_claim=false|p=0.3500|band=2|holds=true|answer=come_clean|doubt=88.19|comp=90.00
IVFORCE|outcome=busted|prompt=3|doubt=88.19|comp=90.00
IVTRACE|prompt=3|id=cv_graduate_edu_lie|kind=probe|answer=busted|forced=true|doubt=108.19|comp=60.00
IVRESULT|outcome=rejected|doubt=108.19|comp=60.00|busted=true|came_clean=true|tier=mid|bg=graduate
```

Run r65563361-33 (the needle-lock check after the fixes; stopped after the warm-up, not counted as an interview):

```
IVSTART|tier=mid|bg=graduate|company=co_beigeware|seed=2109228122|doubt=128.00|comp=100.00|tired=false|warmup=kq_hash_map|probe=|ids=eq_weakness,kq_index_tradeoff,kq_star_conflict,kq_learn_fast,eq_leaked_password|taken=0
IVTRACE|prompt=1|id=eq_weakness|kind=choice|order=bad,neutral,good|answer=good|doubt=118.00|comp=100.00
IVTRACE|prompt=0|id=kq_hash_map|kind=warmup|S=58.72|h=0.1305|c=0.1554|I=0.80|Q=64.04|answer=green|doubt=118.00|comp=100.00
```

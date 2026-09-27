# STEP-06 endings stage: the Hired card with Dream vs Reality, and the Plan B card

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings.
ROADMAP Step 6 tasks 3-4, per ARCHITECTURE 9, 10, 11.7 and GDD S11, S12, 2.7, 2.8, 5.9.5, 5.10, 8.1, 8.3, 9.1; CONTENT.md 14.
Tests: `endings_test_run.txt` (220/220, 20 suites; 214/19 after the offer stage).

This stage resumed an attempt cut off by a usage limit. Its uncommitted, unverified changes were read file by file (git was off-limits), checked against ARCHITECTURE section 17 and the GDD, kept where correct, fixed where not (below), and everything was verified again here.

## What changed

| File | Change |
|---|---|
| `core/odds.gd` | `DREAM_ROWS` (salary, remote, commute, flags, rent), `DREAM_GRADE_MINS` (40, 60, 80), `dream_breakdown(...)`: the five terms of `dream_score`, unrounded, added in the same order, so their rounded sum is always `dream_score`; `dream_grade(score)` 1-4. `dream_score` itself is unchanged (identical to ARCHITECTURE 17.4). |
| `core/run_state.gd` | `hire(cfg, bg, company_red_flags)`: `employment` = a copy of the offer + `red_flags` (GDD 10.4), `dream_score` from `Odds.dream_score`; the offer stays as it was. `dream_breakdown(cfg, bg)`: the card's rows from the same numbers. |
| `autoload/game_state.gd` | `answer_offer(true)` calls `run.hire(...)` with the company's `red_flags`; `dream_breakdown()` for the Hired card. |
| `core/hunt_tips.gd` | `plan_b(run)`: no invite all run -> `tip_tailor_over_spray`; invites but no job -> `tip_rejection_numbers`. |
| `ui/components/ending_art.tscn` + `.gd` (new, `class_name EndingArt`) | The 254x140 grey-box illustration (sky, floor, bust in the hoodie colour) and the stamp on its own cream panel (Press Start 2P 32, red border). `slam()`: 2x for 0.05 s, then 1x, a 4 px whole-pixel shake of the picture only, a 40 ms haptic, then `landed`. |
| `features/phase2_stub/phase2_stub.tscn` + `.gd` | The S11 Hired card in two beats (below). **Fixed this stage:** only the Dream vs Reality sheet slides now (the attempt slid the whole column, action bar included, against GDD 9.1); TO BE CONTINUED overlapped itself on 2 lines (Press Start 2P 8 at line spacing -1) and now sits in its own panel with line spacing 4, as the banners do. |
| `features/game_over/game_over.tscn` + `.gd` | The S12 Plan B card in one beat (below). **Added this stage:** Title and RETRY stay off until the stamp lands plus the 250 ms input lock. |
| `features/job_hunt/job_hunt.gd` | `_rent_text(0)` shows `ui_rent_due_today` ("Rent due today") instead of "Rent due in 0 days" (HUD and night summary on the grace day and the Plan B morning). |
| `data/content/barks.json`, `docs/CONTENT.md` 10.1 | `ui_tap_to_continue`, `ui_rent_due_today` (both need sign-off). |
| `tests/test_endings.gd` (new, 6 tests) | The breakdown against the GDD 5.9.5 examples (row by row, score and grade), the rounded-sum property over 19,488 offers, grade bands, `hire()` (employment, red flags, score, save round trip), ending texts, the Plan B tip rule. |

## The screens (270x480)

**Hired card (`phase2_stub.tscn`), beat 1:** SafeArea > Column: `EndingArt` 254x140 at y 4 (HIRED! stamp, tier-coloured sky) · Info panel: company, role (the posting title), `$84,000/year`, then the tier's `end_hired_<tier>` (plus Stealth Mode's `hired_extra`) · Body · "Tap to continue" (36 px, shows once the stamp is down + 250 ms). A tap (on release) or Back moves on.

**Beat 2:** the Sheet (z above the action bar) slides up from the bottom in 0.3 s and covers the illustration exactly: the DREAM vs REALITY panel (header, 5 rows `end_dream_row_*` with one-decimal points, the grade word + the score in Press Start 2P 16, the footer `end_dream_footer`), the Ducky note `tip_written_offer`, the TO BE CONTINUED panel (`end_tbc`). Rows appear one per 0.35 s with the running score (the rounded running sum); then the grade, footer, tip and TBC; the final score is `run.dream_score`. A tap finishes the tally at once. `[ < Title 80 ][ NEW RUN 168 ]` stay in the thumb band the whole time, disabled until the tally ends + 250 ms.

**Plan B card (`game_over.tscn`):** `EndingArt` (PLAN B stamp, purple ring-light sky) · a panel with `end_plan_b`, the background's `plan_b_line`, `end_plan_b_final` · one Ducky tip (`HuntTips.plan_b`) · the stats panel `end_stats` (days, applications, interviews, rejections; 2 lines) · Body · `[ < Title ][ RETRY ]`. About 362 px of content + the action bar.

## Dream vs Reality: numbers vs the formula (GDD 5.9.5)

| Run | Offer | Rows shown | Sum | Card |
|---|---|---|---|---|
| 64, Graduate, Mid | Beigeware $84,000; 2 days x 45 min = 3.0 h; 1 red flag; rent 12/12 | 22.4 (40x84/150) · 15.0 (25x3/5) · 10.5 (15x(1-3.0/10)) · 5.0 (10-5x1) · 10.0 | 62.9 | 63 Pretty good |
| 65, Intern, Startup | Entangled Greens $72,000, remote; 1 red flag; rent 14/15 (hired on day 2) | 19.2 · 25.0 · 15.0 · 5.0 · 9.3 (10x14/15) | 73.53 | 74 Pretty good |
| 66, Self-Taught, Big | Murkcloud $106,000; 4 days x 95 min = 12.7 h; 1 red flag; rent 12/12 | 28.3 · 5.0 · 0.0 (12.7 h > 10 h) · 5.0 · 10.0 | 48.27 | 48 Doable |
| 66, Intern, Startup (game_eval setup) | Stealth Mode Inc. $65,000, remote; 1 red flag; rent 3/15 | 17.3 · 25.0 · 15.0 · 5.0 · 2.0 | 64.33 | 64 Pretty good |

`GameState.dream_breakdown()` returned exactly these terms, `run.dream_score` equalled their rounded sum, and the card's labels read them back. `employment.red_flags` held the company's list from companies.json.

## Verification

Runs: 64, 65, 66, 67 (all `project_run` main). Input: real `input_mouse` taps (motion, press, release; window px = 2x game px) and real `input_key Escape`. game_eval was used for: state reads and waits; fast-forwarding days with the real verbs (`GameState.quick_apply` / `sleep` / `start_day`) in runs 65 and 67 before a real Sleep; slowing the tally tween to 0.1x (run 66) so the real tap that finished it could be told apart from the tween; the Stealth Mode Hired setup (`debug_quick_start`, `make_offer`, `answer_offer(true)`); a debug Plan B for the 294x639 probe; the 294x639 KEEP content scale with SafeArea fake insets (0,45,0,26), restored to EXPAND 270x480.

| Check | Result | Detail |
|---|---|---|
| test_run all | pass | 220/220, 20 suites. |
| Hired card through the real flow, Mid | pass | Run 64: New game -> intro Skip -> Graduate CHOOSE -> 2 Quick Applies -> DEBUG -> fake invite MID -> DBG K.O. -> tap -> offer -> ACCEPT (all real taps). Beat 1 read Beigeware Financial / Backend Developer / $84,000/year / end_hired_mid; hint after the stamp. Tap -> beat 2 -> 63 Pretty good, footer, tip_written_offer, TBC. NEW RUN -> Background select, Graduate preselected, save deleted, run_count 0 -> 1. |
| Hired card, Startup + Back on beat 1 | pass | Run 65: Intern, a real Sleep + night + START DAY first (hired on day 2), DEBUG START, K.O., ACCEPT. Beat 1 (Entangled Greens, end_hired_startup). Esc on beat 1 -> beat 2 (TALLY), the sheet at y 4, the action bar unmoved at y 440 and disabled. `< Title` (real tap) -> Title, save deleted, run_count 2 -> 3. |
| Hired card, Big + kill + Continue | pass | Run 65 -> 66: Self-Taught, DEBUG BIG (Murkcloud), K.O. (composure 90/90 -> $106,000), ACCEPT -> Hired (save on disk stayed the OFFER one, rng_state -2187652908439735845, employment {} and dream_score -1 in it). Project stopped on the card. Run 66: CONTINUE -> the identical offer and RNG state -> ACCEPT -> Hired, same 48 and rows, run_count unchanged (4). NEW RUN -> 4 -> 5, Self-Taught preselected. |
| Tally one by one; a tap finishes it | pass | Run 66 (Stealth): mid-tally screenshot with 4 rows and a running 62 (17.3+25+15+5); a real tap then showed all 5 rows, 64, the grade, the TBC panel at once (tween slowed to 0.1x beforehand, so the tap did it). Buttons came on 250 ms later. Run 66 Big: tally screenshot before the first row (score 0). |
| Stealth Mode hired_extra | pass | Run 66: "You may now know what we do. ...It's a to-do app." under end_hired_startup; Info panel 104 px, beat 1 fits. |
| Plan B via DEBUG "Rent runs out" | pass | Run 64: Self-Taught, 1 Quick Apply, DEBUG -> Rent runs out (real taps) -> Plan B: "Days: 1 - Applications: 1 - Interviews: 0 - Rejections: 0", tip_tailor_over_spray (no invite), the Self-Taught plan_b_line; save deleted, run_count 1 -> 2. RETRY (real tap) -> Background select, Self-Taught preselected, run_count still 2. |
| Plan B through Mail's START DAY, invites came and went | pass | Run 65: Graduate, days 1-12 fast-forwarded (24 applications, invites arrived and expired, 15 rejections), then a real Sleep + night + START DAY at rent 0 (plan_b, no grace) -> Plan B: "Days: 13 - Applications: 24 - Interviews: 0 - Rejections: 15" = run.day / total_applications / interviews_taken / total_rejections; tip_rejection_numbers; Graduate plan_b_line. Right after the fade Title and RETRY were disabled, then on. Esc -> Title, run_count 3 -> 4 once. |
| Plan B through START DAY, no invite | pass | Run 67: Self-Taught, 15 applications, no invite; night and HUD said "Rent due today"; START DAY -> Plan B: "Days: 13 - Applications: 15 - Interviews: 0 - Rejections: 12", tip_tailor_over_spray; save deleted, run_count 7 -> 8; RETRY -> Background select, Self-Taught preselected, fresh run (background_id empty). |
| Layout 294x639 + insets (0,45,0,26) | pass | Run 66: Hired beat 2: column at x 20, sheet 254x239 at y 45 over the art (y 45), tip 189, TBC 250, `< Title` 80x36 and NEW RUN 168x36 at y 577 (x 106-274), ending at 613 = 639 - 26. Plan B (124 / 12 / 109 stats, still 2 lines): art y 45, tip 302, stats 382, buttons y 577. Screenshots checked, then restored to 270x480. |
| Layout 270x480 | pass | Hired beat 2: sheet 254x239 from y 4 (its panel 140 = the art's 140), tip 148-205, TBC panel 209-243 (2 lines, no overlap), NEW RUN 168x36 at (94, 440), `< Title` 80x36 at (8, 440). Plan B: art 4-144, story 148-, tip 261, stats 341-366, RETRY 168x36 at (94, 440), `< Title` 80x36 at (8, 440). |
| Game log | pass | Runs 64-67: 0 errors, 0 warnings (only the helper line, "Content: 3 backgrounds...", IVSTART/IVFORCE/IVRESULT). Editor: only the known stale "Identifier not found: GameState" lines. |
| Files on disk | pass | Every file of the attempt compared with a scratch snapshot before and after the runs: only the files edited here changed; LF endings; `phase2_stub.tscn` / `game_over.tscn` were never opened in the editor. |
| Cleanup | pass | `settings.cfg` (left by the interrupted attempt with intro_seen, and again by these runs) deleted; no `save_v1.json`; `user://` holds only godot_ai_server.pid and the engine's folders. Project stopped. |

## Agent defaults, please review (W4)

1. **Only the sheet slides** in beat 2 (drawn above the action bar); `[ < Title ][ NEW RUN ]` never move (GDD 9.1) and stay disabled until the tally ends plus the 250 ms lock.
2. **Tally pace:** 0.3 s slide, then one row per 0.35 s with the running (rounded) sum, then the grade, footer, tip and TBC together; a tap finishes it at once. Rows show one decimal ("25.0", "0.0").
3. **Score row:** grade word left, the score right in Press Start 2P 16; the footer sits inside the panel under it.
4. **TO BE CONTINUED** in its own panel (HeaderLabel, line spacing 4), so the 2-line banner doesn't overlap and sits on a solid panel.
5. **Back:** Hired beat 1 -> beat 2 (even while the stamp is landing); during or after the tally -> Title (as ARCHITECTURE 9). Plan B: Back -> Title.
6. **Plan B input lock:** Title and RETRY come on only after the stamp lands + 250 ms, because RETRY sits where Mail's START DAY is.
7. **Plan B tip:** no invite all run -> `tip_tailor_over_spray` (nobody replied; tailoring gets replies); invites but no job -> `tip_rejection_numbers`. Known edge: if the 8th Quick Apply lands on the last day, the night shows `tip_tailor_over_spray` and the Plan B card repeats it (GDD 8.1 rule 4 "not twice in a row"). Rare; not handled.
8. **Plan B text:** `end_plan_b`, the background's line, then `end_plan_b_final`, in one panel.
9. **Grey-box art:** Hired sky = the tier colour (`VersusIntro.tier_color`), Plan B sky = a purple "ring-light glow"; the bust in the hoodie colour; the stamp drops in at 2x then 1x (whole multiples only).
10. **`Rent due today`** at 0 rent days (grace day, Plan B morning) instead of "Rent due in 0 days".

Not decided (developer's call): the huddle question "Is the Dream vs Reality footer funny or smug?" is tone; the card shows `end_dream_footer` exactly as CONTENT.md has it.

## Content ids added (need developer sign-off)

| id | Text | Source |
|---|---|---|
| `ui_tap_to_continue` (barks) | Tap to continue | new functional hint for beat 1 (GDD S11 "Tap anywhere to continue") |
| `ui_rent_due_today` (barks) | Rent due today | grammatical variant of `ui_rent_due` |

## You-do queue (W3, unchanged)

- Choose the fine-print jokes you like best (ROADMAP Step 6 You-do).
- Kill the app on your iPhone at the 5 moments, including on the Hired card, and check Continue (device, P2).

## Doc follow-ups for the Doc sync stage (not edited here)

- ARCHITECTURE 3: `EndingArt` (`ui/components/ending_art.*`); `HuntTips.plan_b`; `Odds.DREAM_ROWS`, `DREAM_GRADE_MINS`, `dream_breakdown`, `dream_grade`; `RunState.hire`, `RunState.dream_breakdown`; `GameState.dream_breakdown`.
- ARCHITECTURE 7.1: `employment` = the offer copy + `red_flags` (`hire()`), `dream_score` set by `hire()`.
- ARCHITECTURE 9 table: Hired: beat 1 -> beat 2, else `quit_to_title()`; Plan B: `quit_to_title()`.
- ARCHITECTURE 11.7: as built (above); beat 2's rows come from `Odds.dream_breakdown`, not `Odds.dream_score`.
- ARCHITECTURE 12.2: `test_endings.gd` (suite `endings`, 6 tests).
- ARCHITECTURE 17.2, 17.4, 17.7 (and the HuntTips block): re-sync with the code (`answer_offer` -> `run.hire`, the new Odds and RunState methods, `_count_finished_run` in `change_phase`).

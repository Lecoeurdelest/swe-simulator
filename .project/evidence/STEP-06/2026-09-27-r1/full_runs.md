# STEP-06 verifier: full runs of the v0.1 grey-box (desktop)

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings, no code changed in this stage.
One game process for all full runs: run 79 (`r95244596-79`), started from a clean profile (no `save_v1.json`, no `settings.cfg`).
ROADMAP Step 6 Done-when "3 full runs (Easy, Medium, Hard) with no crash": the desktop equivalent. The iPhone runs stay the developer's (P2).

## Method

- **Real input** (`game_manage input_mouse` motion + press + release in window px = 2x game px; `input_key Escape`): the Title taps, the mid-intro hold on the pill, INTERN / GRADUATE / SELF-TAUGHT and CHOOSE, the Graduate's first CV change, every ACCEPT, the Hired card's tap, `< Title` and NEW RUN, RETRY, the Esc that left Run 3's Hired card.
- **Bulk play** by an in-memory driver node injected with `game_eval` (`GDScript.new()` + `reload()`, attached to a Node under the root; never written to the project). Every driver action is a tap sent through `Input.parse_input_event` at the target control's centre in window pixels, so the real GUI path runs, touch emulation included (the job card flips on its emulated `InputEventScreenTouch`). The driver never calls GameState verbs.
- **The driver's player:** Quick Apply cards with 1+ matching tags; flip and TAILOR & APPLY when 2+ tags match (or when tailoring clears a knockout); a referral on Big cards with 2+ tags; skip 0-tag cards (after skipping the deck twice it sprays); STUDY once after each interview loss; GO NOW on the first invite it can take; choice answers good about 70%, neutral 20%, bad 10%; Answer Meter aim error up to 1.3 zone half-widths (0.8 from Run 2a day 8, a player who has learned the meter); from Run 3a day 11 it re-aims after a startup PIVOT; Come clean 50% / Bluff 50%.
- `game_eval` also read state (read-only), hashed the save, and in Runs 2b, 3a and 3b set the CV with driver taps on the CV screen (segment, then DONE or `< Back`).
- Game log after the runs: 152 lines, every one `info` (the helper line, `Content: 3 backgrounds, 3 tiers, 16/16 JSON files`, `IVSTART`/`IVTRACE`/`IVWHEEL`/`IVRESULT`). The editor error cursor never moved (150).

## Summary

| Run | Background | End | Days | Applications | Interviews: outcomes | Offer | Dream | Leaves by | Crashes / log errors |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Intern (Easy), first run | Hired | 6 | 23 (18 quick, 5 tailored) | 4: rejected, rejected, rejected, **K.O.** | Entangled Greens, Mobile Dev (Also Barista), $72,000, 0.0001%, fully remote | 71 Pretty good | `< Title` | 0 / 0 |
| 2a | Graduate (Medium) | **Plan B** (day 14, after the grace day) | 14 | 58 | 4: all rejected (the last one on the grace day) | - | - | RETRY | 0 / 0 |
| 2b | Graduate, retry | Hired | 11 | 44 | 5: rejected x4, **wheel win** (P 0.61) | Stealth Mode Inc., Software Engineer (Under NDA), $65,000, 0.0001%, fully remote | 64 Pretty good | NEW RUN | 0 / 0 |
| 3a | Self-Taught (Hard), Education Lie | **Plan B** (day 13) | 13 | 27 | 6: rejected x3, wheel loss (P 0.55), come clean + rejected, BUSTED + rejected | - | - | RETRY | 0 / 0 |
| 3b | Self-Taught, retry, honest Education | Hired | 5 | 12 | 2: rejected, **wheel win** (P 0.51, arrived Tired) | Lukewarm Express, Full-Stack Developer (Full-Full), $75,000, hybrid 2 days, 2 x 95 min = 6.3 h | 52 Doable | Esc (= `< Title`) | 0 / 0 |

All three backgrounds reached the Hired card; two of them after a natural Plan B and a RETRY. 21 natural interviews: 1 K.O., 3 wheel wins, 1 wheel loss, 16 rejections.

## Run 1: Intern (Easy), first run of the profile

- Title "Tap to start" (real tap) -> the intro auto-played (first run, `intro_seen` false). Nine injected taps: each one either finished the caption being typed or showed the next one (p1 c1 ... p3 c1). A real press on "Hold to skip" while panel 3's first caption was typing -> Background select after 0.5 s, `intro_seen` = true. The release landed over CHOOSE and did nothing (the Button never had the press).
- INTERN + CHOOSE (real). Day 1: 9 energy, rent 15, 2 referrals, stats 50/40/45, no gap topics (gap_topics_count 0), `first_run` true, save written.
- Day 1: 6 applications, deck empty, Sleep coach mark. Day 2: the **first-run guarantee** invite (Synergai, startup, kind `guarantee`) -> GO NOW -> interview with the warm-up (kq_learn_fast, "doesn't count"): rejected at Doubt 43.94/118, Composure 82.76 (a bad choice answer first). STUDY (KNW 50 -> 55).
- Day 4: Nimbus (Big) rejected at Doubt 33.55/132 with full Composure. Day 5: Beigeware (Mid) rejected at 42.25/128. Day 6: Entangled Greens (startup): K.O. on prompt 4 (three green answers, Doubt 105.5 -> -6.31).
- **Offer** (screenshot): 18 lines on a 254x231 paper at y 90, `tip_equity_lottery`, `< Back` 80x36 at y 398, Decline 80x36 + ACCEPT 168x36 at y 440. $72,000 = 65k band at 0.75 x 1.10. Perks Kombucha on tap + Unlimited PTO*, fine print `fp_unlimited_pto`.
- ACCEPT (real) -> Hired. Save on disk still the OFFER one (phase 5); run_count 0. Dream **71** = 19.2 + 25 + 15 + 5 + 6.67 (rent 10/15); red flag "Paid partly in tokens". Beat 1 (screenshot), real tap -> tally -> 71 Pretty good, the sheet 254x239 at y 4, buttons on after the tally + 250 ms. `< Title` (real) -> Title without CONTINUE, save deleted, run_count **0 -> 1**.

## Run 2a: Graduate (Medium)

- Title tap (real) -> **straight to Background select** (the intro never auto-plays again), Intern preselected. GRADUATE + CHOOSE (real). CV (real taps): Experience -> Polished (the first CV open shows `tip_quantify_impact` and scrolls to keep it in view, Step 5 behaviour), DONE -> the save holds `exp: polished`.
- Days 1-13: 58 applications, no invite until day 6 (not a first run: no guarantee). Interviews: day 6 Beigeware rejected at 44.45; day 8 Beigeware again (Dana's "greet again" path) rejected at 49.74; day 12 Adverse (Big) rejected at 33.02 (night: "Rent due TOMORROW"); day 13 = **grace day** (rent 0, a waiting invite: `grace_used` true, day_mail `grace_day` true, `decline_ends_run()` true): Pixelpivot rejected at 38.13.
- Day 14 morning: `plan_b` true -> START DAY -> **Plan B**: "Days: 14 - Applications: 58 - Interviews: 4 - Rejections: 33", `tip_rejection_numbers` (invites came), the Graduate's plan_b_line. Save deleted, run_count **1 -> 2**. RETRY (real) -> Background select, Graduate preselected, run_count still 2.

## Run 2b: Graduate retry

- CHOOSE (real); CV Experience Polished (driver taps), saved. Days 1-11, 44 applications.
- Interviews: day 5 Nimbus (Big) rejected at 42.32/132; day 6 ByteBistro rejected at 30.12; day 7 Beigeware rejected at 25.41; day 8 Beigeware rejected at 50.65; day 11 Stealth Mode (startup): Doubt 5.70 -> **committee wheel**, P 0.6106, won.
- One `game_eval` chunk ran past 8 s (the driver's meter wait) and was aborted (EVAL_HUNG); the game was unaffected and the driver got a deadline.
- **Offer**: $65,000 (band 0.75, x1.00), equity, fully remote, perks Kombucha + Unlimited PTO (3 startup perks, so the same pair as Run 1 is a 1-in-3 chance), `fp_runway`, 18 lines.
- ACCEPT (real) -> Hired: Dream **64** = 17.33 + 25 + 15 + 5 + 1.67 (rent 2/12), Stealth Mode's `hired_extra` line under the tier line, red flag "You can't know what you're applying for"; save still OFFER, run_count 2. Tap -> 64 Pretty good. NEW RUN (real) -> Background select, Graduate preselected, save deleted, run_count **2 -> 3**.

## Run 3a: Self-Taught (Hard), lying about the degree

- SELF-TAUGHT (real): the card previewed "Gaps: Data structures, Web and HTTP"; CHOOSE -> `gap_topics` = [data_structures, web] (the preview matches the roll). Stats 55/10/5, 6 energy, rent 12. CV (driver taps): Education **Lie** (a degree claim), Experience Polished; saved.
- Days 1-12, 27 applications (mostly tailored startup and mid cards: tailored startup P 0.307).
- Interviews: day 3 Quantumleaf (startup, video: 3 pips) rejected at 28/118; day 6 Beigeware (Mid, in person: 3 + 1 travel pips, 6 -> 2) rejected at 70; day 7 Quantumleaf: Doubt 6.21 -> wheel P 0.5548 (= 0.40 + 0.20 x (1 - 6.21/17.7) + 5/200), **lost** -> Ducky's card; day 10 Quantumleaf rejected at 29.
- Day 11 Stealth Mode: **lie probe** on `cv_self_taught_edu_lie` (Bluff shows "[##---] Unlikely", P 0.35 = 0.50 + 20/200 - 10/200 - 0 - 0.20) -> **Come clean** (Doubt -5, Composure -10, `confessed` = co_stealth|edu lie). Rejected at 55.54: the prompt-4 needle ran out (I = 0.20) while I was editing the driver between chunks, so this result is partly my idle time. The driver's first probe taps fell inside the 250 ms lock (`mouse_filter` IGNORE) and were ignored; the game took the third tap. Correct behaviour.
- Day 12 Stealth Mode again: the day-11 Quick Apply had re-sent the Education Lie to Stealth, so Dana probed it again (P 0.375) -> **Bluff -> BUSTED** (Doubt +20, Composure -30), Stealth Mode blacklisted, rejected.
- Day 13 morning: rent 0 and no invite -> `plan_b` -> **Plan B**: "Days: 13 - Applications: 27 - Interviews: 6 - Rejections: 14", `tip_rejection_numbers`, the Self-Taught's plan_b_line. Save deleted, run_count **3 -> 4**. RETRY (real).

## Run 3b: Self-Taught retry, honest

- Self-Taught preselected, run_count 4. CHOOSE (real); CV Experience Polished only (driver taps). Gaps [concurrency, databases].
- Days 1-5, 12 applications. Day 4 Synergai (startup) rejected at 41.85. Day 5 ByteBistro (Mid, in person, **Tired** by design: 6 - 3 - 1 = 2 pips, GDD 5.3): three green answers, Doubt 10.83 -> wheel P 0.5122, **won**.
- **Offer**: Lukewarm Express, $75,000 (65-90k at 0.75 = 83.75k x 0.90), "Hybrid: 2 office days a week", commute "2 days x 95 min each way = 6.3 h a week", perks 20 days PTO + Pizza Friday, `fp_probation`, `tip_total_comp`, 17 lines (paper y 102, 254x219). No lie was sent, so ACCEPT rolled no background check.
- ACCEPT (real) -> Hired: Dream **52** = 20 + 15 + 5.5 + 5 + 6.67 (rent 8/12) "Doable", red flag "'Fast-paced' (no documentation)"; save still OFFER, run_count 4. Tap -> 52 Doable (screenshot). Real **Esc** after the tally -> Title: no CONTINUE, save deleted, run_count **4 -> 5**.

## Observations for the developer (not code defects; please review)

1. **Balance vs GDD 5.12 (Step 7).** Every interview trace matches the GDD 5.8.4 formulas exactly (e.g. S 61.12, I 1.00 -> Q 70.84, Doubt -36.76; h 0.1733 includes the Graduate's +0.04), and the P_invite examples are covered by `test_odds`. But the grey-box plays much harder than the GDD 5.12 table: 1 K.O. and 4 committee wheels in 21 interviews (GDD: 30-43% of interviews end on the wheel), Graduate and Self-Taught first runs ending in Plan B, 12-58 applications per run (GDD means 10 / 19 / 15). Typical Mid/Big interviews with good choices and GOOD/PERFECT taps ended at 20-40% of Doubt, above the 15% committee band. Part of the gap is Research (SHOULD, not built; GDD calls it the strongest lever) and this driver's strategy. Step 7's balance sim is the place to settle it.
2. **The same joke twice on one contract.** Run 1's startup offer drew the perk "Unlimited PTO* (*average taken: 4 days)" and the fine print "Unlimited PTO*. *Subject to approval, deadlines, and vibes." Perks and fine print are picked independently. Your call as part of "choose the fine-print jokes you like best".
3. **Dana probes a confessed lie again** when you send that lie to the same company again in a new application (Run 3a, days 11-12). It follows the rules (the probe reads the application; `confessed` only waives the background check) and it's arguably funny; say if it should be excluded.
4. **Debug trace only:** after a startup PIVOT, `IVTRACE`'s `c=` still shows the zone centre from before the jump, so a good tap can read like a miss next to it. Not player-facing; left as is.

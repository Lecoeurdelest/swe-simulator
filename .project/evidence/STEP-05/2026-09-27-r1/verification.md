# STEP-05 verifier stage: adversarial verification and agent playtest

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-05-hunt-greybox. No git was run.
Tests: `test_run.json` (200/200, 19 suites; 199/199 before this stage).

## How it was driven

- Runs: r80001840-53 (Graduate first run, days 1-2), r80212797-54 (Continue after the kill, days 2-13, Plan B, grace-day branch, Intern lie loop), r81033093-55 and r81155388-56 (Intern interviews; both ended in a debugger break caused by a type-inference parse error in **my own game_eval snippet**, not project code), r81455913-57 (card tap/drag checks, Come clean), r81972577-58 (after the fix: rescind lands on Mail, Mail tip order).
- Real input: `game_manage input_mouse` (motion, press, release; window px = 2x game px) for Title, intro skip, Background select taps (selector, dice, CHOOSE, Back), the first APPLY, Sleep dock, sleep confirm, lock-screen unlock, START DAY, Flip all, GO NOW, CV segments, referral toggle, TAILOR & APPLY, interview answers/Bluff/Come clean/DBG buttons, Back to the hunt, offer Decline/confirm/Accept, Plan B `< Title`/RETRY, Hired `< Title`, Pause Quit to title; `input_key Escape` for every Back check.
- **Fell back to game_eval** for: state reads; the bulk of the ~30 Apply taps and the day loops (a helper that sends the *same* `Input.parse_input_event` motion/press/release events `input_mouse` sends, at the same window px); card and background swipes and list drags (`InputEventScreenTouch/Drag` and mouse motion with a button mask, which `input_mouse` can't send); adding waiting invites with the debug verb `GameState.debug_fake_invite()` (grace-day and invite-withdrawal setups); peeking a *copy* of the run RNG; **moving the run RNG state forward to a draw < 0.30 before Accept** (to force a background-check catch for the rescind and confession checks); the 294x639 content-scale + fake-insets probe (restored). Save files were copied/restored in user:// between branches (day-12 save, Intern day-3/interview/offer saves).

## Done-when (desktop parts)

| Criterion | Result | Evidence |
|---|---|---|
| Medium first run: invite on the morning of day 2 after >= 3 day-1 applications | pass | Graduate, first run, seed 577840907, name "Emerson" (dice). Day 1: 6 applications (5 APPLY, 1 flip + TAILOR on `job_mid_qa` with 2 matching tags), Sleep (1 pip left, no confirm). **8 taps + 1 unlock tap** from the deck to the invite. Day-2 Mail: guarantee invite from app 2 (`job_mid_qa` @ Beigeware, highest P 13.1%), coach "An interview! Rest up..." pointing at GO NOW. Night: "Applied 6 - Rejected 2 - Ghosted 0 - Rent due in 11 days". |
| ~30 Apply taps across days, tailor at >= 2 tags | pass | 30 applications by day 5 (6 tailored, 24 Quick); `job_mid_backend` tailored = 16.8% (GDD 5.6 example 1). Each day the 6-card deck ran out before the 8 pips did. |
| Knockout rejections name the knockout | pass | 7 knockouts (apps 6, 10, 13, 16, 21, 25, 31), each rejected the next morning whatever the tier, mail `mail_knockout`: "...Knockout: 3+ years experience. - Parsinator 3000" (Flip all opened by a real tap). Knockout + ghost (apps 6, 13) = knockout, per GDD 5.7 order. |
| Ghosts stay silent | pass | Ghost apps 1, 8, 28 never produced mail; counted in "N applications: no reply", turned "ghosted" 7 days after sending (day 8: ghosted 2). |
| Radar only with relevant non-knockout applications | pass | End of the Graduate run: pity_count 5 = relevant non-knockout apps revealed without an invite after the day-2 guarantee reset (9, 15, 18, 28 ghost-relevant, 30). Mail "Recruiter Radar [#-------] -> [###-----]" etc. matched each morning. Intern run: radar invite at 6/6. |
| Wasting energy until rent runs out -> Plan B | pass | Days 6-12 slept without applying (confirm on 8 pips each time). Day 13: rent 0, no invite -> plan_b morning (Mail shows only the Radar; HUD "Rent due in 0 days" red) -> START DAY -> GAME_OVER "PLAN B ... Days: 13 - Applications: 30 - Interviews: 0 - Rejections: 19"; save deleted; run_count 0 -> 1. |
| ... with the grace day when an invite is waiting | pass | Day-12 save restored, one waiting invite added (debug verb), Sleep -> day 13 rent 0: grace_day true, grace_used true; Mail: "Your landlord gave you one more day. ONE." (red), GO NOW enabled -> interview -> DBG K.O. -> Offer -> Decline -> confirm -> GAME_OVER (grace-day decline = Plan B). Also: Pause > Quit to title on a plan_b morning keeps the save file (the morning is still pending in it). |
| Kill right after Sleep, relaunch, Continue: the SAME morning | pass | After day-1 Sleep: morning_report JSON, rng_state 3370950375833464038, save md5 16287935ef421caf8d0fc369ec11b3c0. `project_manage stop`, file md5 unchanged; relaunch > CONTINUE: night screen replayed, identical morning_report JSON, identical rng_state, identical save md5. |

## Background select (S03)

| Check | Result | Detail |
|---|---|---|
| Numbers vs data | pass | Intern: EASY, 9 pips + 1 grey, runway 15, KNW [###--] EXP [##---] NET [##---] (50/40/45). Graduate: MEDIUM, 8 + 2 grey, 12, [###--] [#----] [#----] (55/15/15). Self-Taught: HARD, 6 + 4 grey, 12, [###--] [#----] [-----] (55/10/5), "Gaps: Security, Data structures". Perk/flaw text = backgrounds.json. |
| Swipe | pass | 90 px drags: Self-Taught -> Graduate (right), Graduate -> Self-Taught (left); ends don't wrap; a 40 px drag settles back. |
| Dice | pass | Real tap: "Alex" -> "Emerson" (never the current name); max_length 10. |
| Preselection | pass | No settings: Graduate. Plan B > RETRY: Graduate (same background). After choosing Intern, stop + relaunch > New game: Intern (settings meta `last_background`). Esc on the screen -> Title. |
| Hit sizes / zones | pass | Dice 34x34, selector 80x40 (gaps 7), `< Title` 80x36, CHOOSE 168x36; nothing tappable above y 110. |

## Hub (S04-S06)

| Check | Result | Detail |
|---|---|---|
| Hit areas >= 34, gaps >= 4 | pass | Every BaseButton in the hub (34 incl. hidden ones by min size) >= 34x34; [=] 34x36, SKIP 80x36, APPLY 128x36 (gaps 6), dock 47x40 (gaps 4), CV segments 82x34 (gaps 4), Later 80x34 / GO NOW 154x34, invite header 240x34, Flip all 80x34, referral 240x34, action bars 80+168x36, START DAY 254x36. |
| Card <= ~30 words | pass (borderline) | Worst front over all 61 posting x company pairs: 32 tokens counting each "[v Tag]" as 2 words (`job_mid_web_rescue` @ Scope & Creep Digital, with knockout chip and odds line); about 29 counting a tag as one word. |
| Card taps vs drags | pass | 2 px = flip (and back), 20 px = settle (no flip, no action), -30 px = settle, -80 px = skip, +90 px at 0 energy = settle, no application. |
| Mail stack drag vs tap | pass | A 50 game-px drag (mouse motion with the button held) starting on Flip all scrolled the list (0 -> 83, its end) and did not fire it; a real tap then opened the stack. |
| CV list drag vs tap | pass | A 70 game-px drag starting on the Experience "Lie" segment scrolled the list and did not change the CV; real taps then set Edu/Exp to Lie. |
| handle_back / Esc | pass | Card back -> flips front; CV -> Jobs and commits (save holds edu/exp = lie); Mail -> Jobs; morning Mail -> Pause; Study -> Jobs; Jobs front -> Pause; Pause -> resume; sleep confirm -> closes; night lock screen -> unlocks to Mail; [=] -> Pause; dock tap while the card shows its back flips it front. |
| 270x480 frame | pass | Column x 8-262, HUD y 4-32, app header 36-52, body from 56, action row 392-428, dock 436-476. Self-Taught HUD row with a 10-slot Radar measures 250 px min width (fits 254). |
| 294x639 probe, fake insets (0,45,0,26) | pass | Visible 359x639, column 254 centred (x 52), y 45-613; Mail, Jobs + card back, CV (all three rows without scrolling) fit; taps at the offset origin (91,161) worked. Restored to 270x480, zero insets. |
| Nothing interactive in the top band | pass (with note) | HUD and app header (y 4-52) are labels only. The body starts at y 56 as in the GDD S04 y-table, so a scrolled list row or the first invite's header button (y 63-97) can sit at 56-72; the only other top-band control is the Step 4 interview DBG button (debug builds). |

## Lie loop (Intern, second run, first_run false)

| Step | Result | Detail |
|---|---|---|
| Lie on the CV | pass | Real taps: Education -> Lie ("M.Sc. AI, Very Famous University", degree claim), Experience -> Lie; Lie risk 2 red dots; Esc committed it. |
| Apply to matching postings | pass | 6 cards, all 3/3 or 2/3 tags; `job_mid_qa` @ Beigeware TAILOR + referral (53%), `job_big_new_grad_sre` @ OmniGlobal TAILOR + referral (24.5%), others tailored/quick; both lie ids recorded. |
| Interview | pass | Day-3 invite (rolled, Beigeware) -> real GO NOW. |
| Probe triggers sometimes (roll) | pass | Probe rolled in start_interview: day-3 attempt and day-4 attempt (different run-RNG draws) both probed `cv_intern_edu_lie` in round 3 (knowledge prompt 2 replaced); 2 counting lines at Mid = 1 - 0.55^2 = 70%. Invites with no application (debug/"profile") never probed (by design). Rate/replay covered by probe_trigger tests. |
| Bluff | pass | Bluff band "[##---] Unlikely" (35%); won twice ("...Okay. I'll allow it."). |
| Come clean | pass | "Thank you for being honest. Genuinely rare..."; after K.O. + Accept with the run RNG set to a catching draw, **no** background check (confessed `co_beigeware|cv_intern_edu_lie`) -> Hired. |
| BUSTED blacklists | pass | DBG BUSTED (forced; natural bluffs won): BUSTED beat, `tip_honesty_checks`, rejection card; Back to the hunt -> Beigeware blacklisted, both waiting Beigeware invites withdrawn without mail, edu lie dropped from lies_carried; 4 more morning deals: no Beigeware card. |
| Degree check on Accept can rescind | pass after fix | Unconfessed degree claim, RNG draw 0.24 < 0.30 -> rescinded, Beigeware blacklisted, waiting Beigeware invite withdrawn, back to JOB_HUNT same day. Natural draws were 0.90 and 0.50 (hired). **Defect D1 below.** |

## Invariants and code checks

| Check | Result | Detail |
|---|---|---|
| INV-01/02 | pass | Only scene_router.gd calls `change_scene_to_packed`; features preload only their own sub-scenes and ui/components (mail_screen: invite_card, coach_mark, ducky_note); flow test `test_screens_never_change_phase_or_scene` green. |
| INV-03/04 | pass | Global RNG: only `new_run_seed()` (seed pick) and the name dice's own RandomNumberGenerator; rules roll `Odds.*` on the run RNG. |
| INV-06 | pass | Saves only in live phases (save md5 checks, delete on GAME_OVER and on leaving PHASE2_STUB observed). |
| INV-07 | pass | Saves hold plain JSON only (no `&"`, no objects); rng_seed/state are strings. |
| INV-14 | pass | Containers only (the Parsinator scan line and the invite header's inner row are the only anchored/absolute children, both decoration inside a control); every tappable thing inside SafeAreaMargin; overlays IGNORE (coach slot, coach, spacer, empty deck). |
| INV-15 | pass (noted) | No hard-coded player text: .tscn texts are editor previews overwritten at runtime; script strings are icon stand-ins ("=", "v", "x", "+", "-", "< ") and the DEBUG row. Script constants quoting GDD thresholds (2 pips, 4 applications, 8 Quick Applies, every 10th rejection) remain as the hub_apps stage listed them. |
| INV-19 | pass | No 270/480/254 literals in scripts; thresholds read from Project Settings. |
| content_lint | pass | Green in both test runs. |
| Game logs | pass | Runs 53, 54, 57, 58: 0 errors, 0 warnings (only the helper line, "Content: ...", and the Step 4 IV* trace prints). Run 56: no errors logged before my eval's parse error broke it; run 55's lines were no longer retained. |

## Defect found and fixed

**D1. A rescinded offer was invisible, with no tip (GDD 5.9.4, 8.3, 8.1 rule 1, INV-18).** After ACCEPT the background check rescinded the offer and the hub opened on the Jobs deck: the "OFFER RESCINDED" mail sat unseen in Mail (no badge), and `tip_honesty_checks` ("BUSTED or rescinded") was never shown. Fix (smallest change):
- `core/hunt_tips.gd` `inbox()`: while `run.rescinded` is set, Mail's one tip is `tip_honesty_checks`.
- `features/job_hunt/mail_screen.gd`: that tip sits right under the rescind mail (joke, then tip); otherwise the tip stays under the rejection stack (new `_add_tip()` helper; order otherwise unchanged).
- `features/job_hunt/job_hunt.gd` `_ready()`: when `run.rescinded` is set (and no morning is pending) the hub opens on Mail.
- `tests/test_hunt_tips.gd`: `test_a_rescinded_offer_takes_the_mail_tip`.
Re-verified in run 58: real ACCEPT -> hub on Mail with the rescind mail, the Ducky honesty tip under it, then the day's rejection and Radar; `< Back`/Esc -> Jobs; next Sleep clears it; a non-rescind morning (day 10, 8 -> 13 rejections) still shows `tip_rejection_numbers` right under the stack. Files on disk match what was written after the runs (no stale buffer).

## Open items for the lead / developer (not fixed here)

1. **Flick not implemented** (GDD 9.1 "commits past 68 px ... or on a flick", ARCHITECTURE 11.4): both swipe cards commit on distance only. It needs a velocity threshold no doc gives, and a wrong one turns fast taps into Quick Applies, so it belongs with the You-do "judge the swipe feel on the iPhone".
2. **Rescind UX** (agent default, please review): Mail + tip is the MVP stand-in; CONTENT `end_rescinded` ("Offer rescinded. Back to the job boards.") is unused and fits a Step 6 offer-screen beat. With A10 (a win after BUSTED still makes an offer), BUSTED then a rescind at the same company would show `tip_honesty_checks` twice in a row (GDD 8.1 rule 4).
3. Copy without singular/zero forms (developer text needed): "Posted 1 days ago", "Posted 0 days ago" (startups roll 0-5), "1 applications: no reply", HUD/night "Rent due in 0 days" on the grace day and the Plan B morning.
4. The offer Decline confirm says "Rent keeps ticking" even on the grace day, where Decline ends the run (Step 6 offer screen).
5. The Plan B morning shows only the Radar line before START DAY ends the run; no line warns that this morning is the end (existing strings don't cover it).
6. Board: once the MVP pairs of a tier run dry (seen on day 12 of the Graduate run, after 30 applications and a week of unapplied deals), the deck deals the non-MVP companies (Stealth Mode, Scope & Creep, Engagement Farms) with placeholder logos: the wiring stage's rule default (a), noted because GDD 5.5 says those three ship after their logos exist.

## ARCHITECTURE 17 changes to sync (Doc sync stage)

- 17.2 RunState: consts `TIER_IDS`, `CV_LINES`, `CV_LEVELS`, `GUARANTEE_DAY`, `REJECT_MAIL_PREFIX`; fields `dropped`, `day_mail`, `tips_shown`, `rescinded`; board/application/invite record fields (application `relevant`, `knockout_reason`; invite `uid`, `mail_id`); `sleep(cfg, tiers, bg, content, rng) -> morning_report`; methods `settle_probe`, `set_background`, `set_cv_level`, `pair_key`, `deal_board`, `blacklist_company`, `skip_card`, `cv_sent`, `card_odds`, `apply_card`, `start_day`, `take_invite`, `roll_probe`, `background_check_caught`, `rescind_offer`, `reject_mail_id`, `cv_line`.
- 17.4 Odds: `roll_card`, `knockout_reason`, `reply_day`, `reveal_outcome`, `pity_after`, `invite_expired`, `is_ghosted`, `rent_check`, `bluff_band`.
- 17.7 GameState: `preselect_background` read from settings meta `last_background`; `choose_background` stores it and uses `new_run_seed()`; `preview_gap_topics`, `debug_fake_invite`; `_init_run` calls `set_background` and `deal_board`; verbs `quick_apply`, `tailor_apply`, `skip_card`, `set_cv_level`, `commit_cv`, full `sleep`, `start_day`, `card_odds`, `mark_tip_shown`, `interview_cost`, `can_take_interview`; `start_interview` (take_invite, InterviewPlan, `roll_probe`, invite_uid = the invite's uid); `finish_interview(..., came_clean)` with `blacklist_company`/`settle_probe`; `answer_offer` grace-day decline -> Plan B and background check -> rescind.
- 17.8 Device: `keyboard_height()`. ARCHITECTURE 3 / INV-03 pure classes: add `HuntTips` (and `UiText`, `InterviewPlan` if listed there).
- 11.4 (from this stage): after a rescind the hub opens on Mail; Mail's one tip is `tip_honesty_checks` under the rescind mail.

## Cleanup

`project_manage stop` done; `save_v1.json` and `settings.cfg` deleted from user:// (it holds only the engine folders and godot_ai_server.pid). Temporary save copies live only in the session scratchpad.

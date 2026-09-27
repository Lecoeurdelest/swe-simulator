# STEP-05 hub deck stage: DoomApply part 1 (HUD, deck, card back, action row, dock, Sleep)

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-05-hunt-greybox.
ROADMAP Step 5 task 4 (part 1), per ARCHITECTURE 11.4 and GDD S04 (4.2) with its y-table, 2.7, 2.8, 5.3, 5.6, 9.1.
Tests: `hub_deck_test_run.txt` (187/187). Nothing from the interrupted run had reached disk; the stage was done in full.

## What changed

| File | Change |
|---|---|
| `features/job_hunt/job_hunt.tscn` + `.gd` | The Step 3 stub replaced by the hub: HUD (2 rows), app header, Body with one panel per app (Jobs, CV, Mail, Study), the action row (4 variants: front, card back, app, morning) and the dock. ModalLayer: the Sleep confirm (`confirm_dialog.tscn`) and Pause. Containers only, inside SafeAreaMargin, 254 px column. |
| `features/job_hunt/job_card.tscn` + `.gd` (new, `class_name JobCard`) | The card: front and back faces stacked in one PanelContainer (one height for both), the scan overlay and the SENT stamp. The root reads `InputEventScreenTouch/Drag` (swipe, tap), the Panel follows the finger, tilts up to 6 degrees, flings, flips and rises. |
| `features/job_hunt/dock_button.gd` (new, `class_name DockButton`) | A dock slot: a drawn 16x16 placeholder icon above the label (a moon for Sleep) and a gold badge. |
| `autoload/game_state.gd` | `card_odds(card)` (wraps `RunState.card_odds` with the right data), `debug_fake_invite(tier_id)` + `_first_entry_id()` for the DEBUG row. No rule changed. |
| `ui/components/ui_text.gd` | `cost()` ("APPLY  1"), `meter()` ("[##----]"), `count()` ("1,247"); `band()` and `money()` reuse them. |
| `tests/test_ui_text.gd` | 3 tests for the new helpers. |
| `ui/theme/main_theme.tres` | Type variations `DockButton` (Button; label at the bottom, current app = amber 2 px border), `Chip` (PanelContainer; dark red with a red border: knockout chip, SENT stamp), `GoldPill` (PanelContainer; the "Invite waiting" pill). Added through the editor's own Theme instance (a throwaway `@tool` test, deleted after it ran), so the open editor never held a stale copy. |
| `data/content/barks.json`, `docs/CONTENT.md` 10.1 | 4 new ids (below). |

## Content ids added (text already in the GDD; none newly written)

| id | Text | Source / where |
|---|---|---|
| `ui_radar_short` | Radar | S04 mockup "Radar [###---]"; HUD row 2 (`ui_radar` "Recruiter Radar" plus a 10-segment meter is 310 px, the row has 254) |
| `ui_odds_quick` | Quick apply | S04 mockup "Quick apply [##---] Unlikely"; card front |
| `ui_odds_tailored` | Tailored | GDD 5.6 "Tailored odds on the back"; card back |
| `ui_deck_empty` | {n} new cards per morning. | S04 "6 new cards per morning"; `{n}` = `board_new_per_day`; the empty deck |

Existing ids used: `ui_day`, `ui_rent_due`, `ui_rent_due_one`, `ui_energy`, `ui_invite_waiting`, `ui_skip`, `ui_apply`, `ui_tailor`, `ui_back`, `ui_use_referral`, `ui_odds_1..5`, `ui_tab_jobs/cv/mail/study`, `ui_sleep`, `ui_sleep_confirm`, `ui_start_day`, `ui_study_title`, naming `app_jobs`, `app_cv`, `app_study`, `_keywords`; postings `title`, `joke`, `salary_text`, `card_applicants`, `card_posted`, `card_reposted`, `card_knockout`, `knock_degree`, `knock_years`, `hirebot_scan`, `hirebot_found`, `stamp_sent`; companies `name`; tiers `name`, `tag`.

## Agent defaults, please review (W4)

1. **Scan and stamp:** applications 1-3 of a run (`total_applications <= full_scan_animations`) play the Parsinator scan (1 s: a line sweeps the card under "Parsinator 3000 is reading your CV..." for 0.7 s, then "Keywords found: n/3" with the application's hits for 0.3 s), then the SENT stamp (0.3 s: slams from 2x to 1x in 0.1 s, holds); later applications play the stamp only. Then the card flies off right (0.15 s) and the next one rises (0.12 s).
2. **The verb commits first:** the apply/skip is saved the moment it is sent, then the animation plays; the deck ignores input (and Back waits) until the card has flown. A refused swipe (not enough energy) settles back.
3. **Swipe:** a drag over a quarter of the base width (67.5 px of 270) commits, a shorter one settles back, a move under the scroll deadzone (6 px) is a tap; the 10 ms haptic plays when the drag crosses the threshold. No flick: no flick speed is documented (same call as S03).
4. **The card back doesn't swipe:** a tap flips it back; its actions are on the action row (`[ < Back ][ TAILOR & APPLY  2 ]`). Esc/Back also flips it back.
5. **Card back:** job title, "Company - Tier name", applicants with thousands separators, "Posted N days ago" (+ amber "Reposted"), salary text, the knockout chip for the tailored CV (or none with a referral), "Tailored [####-] Decent", and `[Use referral (n left)]` in the lower half when tokens > 0 (SelectorButton look: amber border when on; it swaps the band and the chip to the referral quote). Research (SHOULD) not built.
6. **Card height:** both faces stay in the layout (the hidden one transparent, its toggle takes no taps), so a flip never changes the height. The card sits at the bottom of the Body; extra height goes above it (the S03 decision). Without the SHOULD site tabs the card area is y 56-384.
7. **Sleep and the morning (stub for part 2):** Sleep asks "You still have N energy. Sleep anyway?" `[ < Back ][ SLEEP ]` when 2 or more pips remain (the 2 is a script constant quoting GDD S04, not a BalanceConfig field), then `GameState.sleep()`. While `run.morning_report` is set the hub stays on Mail with one full-width `[ START DAY ]`; the other apps and Sleep are greyed; Back opens Pause. START DAY calls `GameState.start_day()` (Plan B or back to Jobs). A kill before START DAY reopens on the same morning. Part 2 fills Mail's list and adds the night lock screen.
8. **Other stubs:** CV = empty panel under the "Buzzwordsmith" header with `[ < Back ]`; Mail (no morning) = empty panel with `[ < Back ]`; Study = "BigOhNo" header, the `ui_study_title` line and `[ < Back ][ STUDY  2 ]` calling `GameState.study()` (greyed when unaffordable). The app header shows the open app's name (DoomApply for Jobs and Mail).
9. **HUD:** row 1 "Day N" / rent (red at `rent_warning_days` = 3 or less; "Rent due TOMORROW" at 1); row 2 "Energy", 10 pips (energy filled, commute greyed), "6/8", then "Radar" and a text meter with `bg.pity_n` segments ([--------] Graduate, [------] Intern). Rent at 0 (grace day) reads "Rent due in 0 days" until part 2's morning handles the grace message.
10. **Placeholders (grey-box):** header strip colored by tier in the GDD 2.5 moods (startup purple, mid beige, big blue-grey), logo = 16x16 grey square, tag marks "v"/"x" plus green/red (colorblind-safe: the mark carries it), dock icons = outlined square, Sleep = moon, `[=]` = "=", Mail badge = 6x6 gold square, the stamp is untilted so the pixel font stays crisp.
11. **Dock:** 5 slots of 47x40 with 4 px gaps = 251 px, centred in the 254 column (x 9-260). Jobs/CV/Mail/Study toggle (current app highlighted); Sleep is a plain button at the right end.
12. **DEBUG row (debug builds only, collapsed):** a DEBUG toggle in the space above the card; expanded: "Fake invite" MID / START / BIG and "Rent runs out". Fake invite adds a waiting invite (the tier's first MVP company that isn't blacklisted, the tier's first open posting, no application behind it, so no probe, no dice) and starts its interview at once; if refused (energy or today's interview), it stays in Mail and a status line says so. Rent runs out = `end_run_plan_b()`. The hub also calls `debug_quick_start("graduate", JOB_HUNT)` when launched on its own (ARCHITECTURE 16 pattern).

## Verification

Runs: `r75807940-42`, `r75956416-43`, `r76073851-44`, `r76304312-45`, `r76407034-46` (project_run main) and `r76770079-47` (project_run custom on job_hunt.tscn: `debug_quick_start` set up a Graduate day 1 with 6 cards; no save written). Input: real `input_mouse` taps (motion, press, release; window px = 2x game px) and `input_key Escape`.
Fell back to game_eval: the swipes (real `InputEventScreenTouch/Drag` through `Input.parse_input_event`, since `input_mouse` motion carries no button mask), waits and state reads, `Engine.time_scale = 0.05` to screenshot the stamp (restored to 1), the 294x639 probe, the rent-colour probe (rent set in memory, restored, never saved), energy set to 2 for the refused Fake-invite path, and one Pause resume.

| Check | Result | Detail |
|---|---|---|
| test_run all | pass | 187/187, 18 suites (184 before). |
| 6 cards on day 1 | pass | Graduate (seed 546371822) and Intern runs: 6 cards, 2 per tier, energy 8 / 9, rent 12 / 15, Radar 0 of 8 / 6. |
| Layout 270x480 = S04 y-table | pass | HUD y 4-32, app header 36-52, Body 56-384 (+4), card bottom 384 (150 tall with a 1-line joke, 182 with a 2-line joke and a knockout chip), action row 392-428 (`[=]` 8-42, SKIP 48-128, APPLY 134-262, spans the centre), dock 436-476. Every tappable control is >= 34 px and in the thumb band (the debug row excepted). Screenshots checked. |
| Layout 294x639 + insets (0,45,0,26) | pass | Column x 20, HUD y 45, dock ends 613 = 639 - 26, the extra 137 px above the card. Screenshot checked; restored to EXPAND 270x480, zero insets. |
| Card front | pass | Strip, logo, company, tier tag, title, 3 tags ("[v Git]" green, "[x Mobile]" red), joke in quotes, knockout chip ("Knockout: 2+ years experience" on job_mid_data_eng), "Quick apply [##---] Unlikely". |
| Flip (real tap) and back | pass | Tap flips (action row becomes `[ < Back ][ TAILOR & APPLY  2 ]`); `< Back` and Esc flip to the front. First run found a bug (the release's settle() killed the flip tween): fixed, re-verified in runs 43-46. |
| Swipe right (game_eval touch) | pass | Panel followed 1:1 in game px, tilt 0.89 / 2.67 / 4.44 / 6 / 6 degrees at 10-90 px; release at 90 px = Quick Apply: energy 8 -> 7, application 1 sent, scan shown, next card rose. |
| Swipe left / short drag | pass | -80 px: card 2 went to the back ([2..6] -> [3,4,5,6,2]), energy unchanged, tilt -6 at release. 60 px: settled back, no action, no flip. |
| SKIP / APPLY buttons (real taps) | pass | SKIP moved the top card to the back; APPLY sent Quick Applies (1 pip each). |
| TAILOR & APPLY (real taps) | pass | Graduate job_st_founding: 2 pips (7 -> 5), tailored, hits 2, P 20.1%, relevant; the next card showed its front. |
| Referral (Intern, real taps) | pass | Back shows "Use referral (2 left)"; toggling it turned the band [###--] Possible -> [####-] Decent without flipping the card; TAILOR & APPLY: tokens 2 -> 1, energy 9 -> 7, application referral = true, P 19.03% (GDD 5.6 worked example 3: 19.0%); the next card showed "(1 left)". |
| 3 scans, then stamps | pass | Graduate run: applications 1-3 showed the scan overlay ("Parsinator 3000 is reading your CV...", then "Keywords found: 1/3"), the 4th the SENT stamp only (screenshots at time scale 0.05). Intern run: 1-3 scan, 4-6 stamp only (overlay state read after each real tap or swipe). |
| Empty deck | pass | Intern: 6 applications (the last by swipe) emptied the deck: card hidden, "6 new cards per morning.", SKIP and APPLY greyed. |
| Energy and Radar HUD | pass | Pips and "n/8" followed every action (8 -> 7 -> 5 -> 4 -> 3, Study 3 -> 1). Intern day 3 morning: 2 relevant mid applications went silent, Radar [------] -> [##----] (pity 2 of 6). |
| Sleep confirm | pass | 3 pips: "You still have 3 energy. Sleep anyway?" `< Back` cancelled (still day 1); 2 pips: same dialog, SLEEP slept; 1 pip: slept at once. |
| Morning -> Mail -> Start day | pass | After Sleep: day 2, 8/8, rent 11, Mail open with START DAY, other docks greyed, "Invite waiting" pill + Mail badge (the day-2 guarantee invite, 4 day-1 applications). Esc opened Pause, not Jobs. START DAY -> Jobs, day 2 board. |
| Kill after Sleep, Continue | pass | Stopped the game on the morning, relaunched, CONTINUE: same morning report (md5 729a9e12...), same RNG state and board, hub reopened on Mail with START DAY. |
| Pause | pass | `[=]` (real tap) opened Pause, Esc resumed (tree unpaused). |
| Apps and Back | pass | CV (Buzzwordsmith header), Mail, Study (STUDY 2: energy 3 -> 1, knowledge 55 -> 60, button greyed at 1); Esc and `< Back` returned to Jobs. |
| Rent colour | pass | 4 days: default colour; 3: red; 1: "Rent due TOMORROW", red. |
| DEBUG row | pass | Collapsed by default; expanded fits above the card at 270x480. Fake invite MID started a Mid interview at co_beigeware (energy 8 -> 5, the guarantee invite still waiting). With 2 pips: refused, status line shown, the invite waited in Mail (pill + badge). Rent runs out -> Plan B, save deleted. |
| Game log | pass | Runs 42, 44, 45, 46, 47: 0 errors, 0 warnings. Run 43: 2 errors from my own game_eval (a 15 s await passed the 8 s eval limit, the aborted eval resumed after its tree was gone and broke into the debugger); no project code involved; stopped and relaunched. Editor: only the known "Identifier not found: Content/GameState/SceneRouter/Device" autoload errors and the untyped-declaration warnings of the game_eval snippets. |
| Files on disk after the runs | pass | job_card.gd, job_hunt.gd, game_state.gd, ui_text.gd, both scenes and the theme hold the new code after the editor's save-on-run. `job_hunt.tscn` was open in the editor: reloaded with `scene_open force_reload` (the first call only switched to it, `reloaded_from_disk: false`; the second one reloaded) before any run, then saved by the editor (uids and unique_ids added). |
| Cleanup | pass | `save_v1.json` and `settings.cfg` deleted from user://; only godot_ai_server.pid remains. Project stopped. Throwaway theme test deleted. |

## You-do queue (W3, unchanged by this stage)

- Judge the one-thumb swipe feel on the iPhone (threshold 67.5 px, 6 degree tilt, no flick, 10 ms haptic): device, P2.
- Write 5 posting jokes of your own into `postings.json`.
- Build the 5-segment `stat_bar` (the placeholder from the background select stage).

## Doc follow-ups for the Doc sync stage (not edited here)

- ARCHITECTURE 10.2: type variations gain `DockButton`, `Chip`, `GoldPill` (and `SelectorButton` from the last stage).
- ARCHITECTURE 17.7: GameState gains `card_odds()`, `debug_fake_invite()`, `_first_entry_id()`.
- ARCHITECTURE 11.4: the card faces are stacked (one height), no flick, the card back doesn't swipe, the morning keeps Mail open until Start day (defaults 3, 4, 6, 7).
- GDD 2.8 #4 / ARCHITECTURE 11.4: "5 app slots of 47 px, 4 px gaps" adds up to 251 px, not the 254 column (centred here). Small arithmetic mismatch, not changed.
- UiText's `cost()`, `meter()`, `count()` could be listed where ARCHITECTURE mentions UiText.

# STEP-05 hub apps stage: DoomApply part 2 (CV screen, Mail, night summary, Study, first-run coach)

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-05-hunt-greybox.
ROADMAP Step 5 task 4 (part 2), per ARCHITECTURE 11.4 and GDD S04-S06, 4.3, 8.1, 8.3, 5.3, 5.7, 5.10.
Tests: `hub_apps_test_run.txt` (199/199, 19 suites; 187/18 before). Nothing from the interrupted run had reached disk; the stage was done in full.

## What changed

| File | Change |
|---|---|
| `core/run_state.gd` | Two plain-data fields: `day_mail` (Start day moves the morning report here; Mail keeps showing it until the next Sleep, which clears it like `rescinded`) and `tips_shown` (once-per-run tip ids). `cv_line(cv_lines, line, level)` returns this background's entry (the CV screen shows its text and tags). No rule changed. |
| `core/hunt_tips.gd` (new, `class_name HuntTips`, pure `@tool`) | Where the hunt's tips fire (GDD 8.3): `inbox(run, report)`, `night(run)`, `cv_opened(run)`, `cv_level_chosen(run, cv_lines, line, level)`, `studied(run)`, `had_invite(run)`. |
| `autoload/game_state.gd` | `mark_tip_shown(id)`, `interview_cost(invite)` (3, +travel pips in person), `can_take_interview(invite)`; `start_interview` now uses those two (same checks as before). |
| `features/job_hunt/job_hunt.tscn` + `.gd` | The hub gains the CV panel (header, scroll list of 3 `cv_row` + tip), Mail panel (scroll list), Study panel (tip, KNOWLEDGE bar, joke), a `CoachSlot` overlay in the body, `[ DONE ]` in the app action row, and the night screen in the ModalLayer. Script: night screen after Sleep and on a resumed morning, GO NOW, Study, CV commit on leave (DONE, Back, dock, Quit to title), first-run coach marks. |
| `features/job_hunt/cv_screen.gd` (new, `CvScreen`), `cv_row.gd/.tscn` (new, `CvRow`) | Buzzwordsmith. |
| `features/job_hunt/mail_screen.gd` (new, `MailScreen`), `invite_card.gd/.tscn` (new, `InviteCard`) | The inbox list. |
| `features/job_hunt/night_screen.gd/.tscn` (new, `NightScreen`) | The lock screen. |
| `features/job_hunt/coach_mark.gd/.tscn` (new, `CoachMark`) | A Ducky note with drawn arrows; every node mouse_filter IGNORE. |
| `features/job_hunt/job_card.gd` | `strip_bottom()` (where coach marks sit). |
| `ui/components/pip_bar.gd` | `filled_color` export (red Lie-risk dots; energy stays amber). |
| `tests/test_hunt_tips.gd` (new) | 12 tests (list in the test file). |
| `data/content/barks.json`, `docs/CONTENT.md` 10.1 | 6 new ids (below). |

## Content ids added (text already in the GDD; none newly written)

| id | Text | Source / where |
|---|---|---|
| `ui_yes` | yes | GDD S05 "Degree: yes/no": fills `{yes_no}` |
| `ui_no` | no | same |
| `ui_cv_edu` | Education | GDD S05 / 5.4: CV row label |
| `ui_cv_exp` | Experience | same |
| `ui_cv_proj` | Projects | same |
| `ui_invite_line` | Interview with {company}: today or tomorrow | GDD S06: the invite card's line |

Existing ids used: `ui_cv_degree`, `ui_cv_years`, `ui_cv_risk`, `ui_honest/polished/lie`, `ui_done`, `ui_go_now`, `ui_later`, `ui_flip_all`, `ui_rejections`, `ui_ghost_footer`, `ui_radar`, `ui_grace_day`, `ui_night_summary`, `ui_rent_due(_one)`, `ui_stat_knw`, `ui_study_joke_1..3`, `coach_apply/flip/sleep/invite_no_research`, naming `app_jobs`, emails `mail_invite_*` (subject/body), `mail_invite_expired`, `mail_knockout`, `mail_reject_*`, `mail_rescinded`, tips `tip_quantify_impact`, `tip_projects_count`, `tip_ats_knockouts`, `tip_rejection_numbers`, `tip_referrals`, `tip_tailor_over_spray`, `tip_fundamentals`.

## Agent defaults, please review (W4)

1. **Mail = the day's inbox.** Before Start day it shows `run.morning_report`; after Start day the report moves to `run.day_mail` and Mail keeps showing it (grace line, expiry notices, rejections, footer, Radar) until the next Sleep. Invites are always the live `run.invites`; a rescinded offer (`run.rescinded`) shows as a mail card. Mid-day Mail with nothing in it is an empty list (no empty-state string exists).
2. **List order:** grace-day line (`ui_grace_day`, red) first, the first-run coach mark, invites (oldest first: it expires sooner), rescinded offer, expiry notices ("Update / Company - Title / The role was filled internally..."), rejections, the inbox tip, the no-reply footer (`no_reply` > 0), the Radar ("Recruiter Radar [#-------] -> [##------]" when it moved, else the current meter).
3. **Invite card:** header = golden-envelope placeholder + company; then the subject (gold), the body (`{player_name}`, `{company}`, `{job_title}` filled), "Interview with {company}: today or tomorrow" only on the day it arrived (the next day it would be false), `[ Later ][ GO NOW  3 ]` (cost like APPLY 1; the S06 mockup says "3 energy"; 4 for the Self-Taught in person). Later folds the card to its header; a tap on the header reopens it; the invite stays (pill + badge).
4. **GO NOW** is greyed when today's interview is used, the pips are short (GDD 5.3), or on a Plan B morning. From the morning inbox it runs Start day first, then `start_interview` (so the interview never leaves a pending morning behind).
5. **Rejections:** one rejection shows as a single entry (no "1 rejections" header); two or more are one stack card "N rejections" [Flip all], which opens in place (stays open for that morning in this scene). Each entry: "Company - Job title", then the Parsinator email (`mail_knockout` body naming the knockout) or the stored `mail_reject_*` line.
6. **Inbox tip** (one, under the stack; HuntTips.inbox): the run's first knockout rejection -> `tip_ats_knockouts`; else the run's first rejection or every 10th -> `tip_rejection_numbers`. Derived from the run, so "first ever" is per run (not across runs).
7. **Night lock screen:** dark full-bleed sky, one notification card ("DoomApply", "Applied n - Rejected r - Ghosted g - Rent due in N days"; "Rent due TOMORROW" at 1), at most one Ducky tip under it; tap anywhere or Back unlocks (250 ms lock so the Sleep tap can't skip it). It replays when the hub opens on a pending morning (Continue after a kill).
8. **Night tips** (the night is a natural pause, GDD 8.1 rule 3), once per run: the first referral used -> `tip_referrals`; 8 Quick Applies with no invite yet in the run -> `tip_tailor_over_spray`. `tip_rest` ("Sleep with 0 pips for 3 days") is **skipped**: no counter exists.
9. **CV screen:** header row 1 = the tag set + "Lie risk" + 3 dots (red = Lie lines); row 2 = "Degree: yes/no" and "Counts as 1+ yrs: yes/no" (word + green/red). Each row: label (HeaderLabel), line text (2 lines max), Honest | Polished | Lie (SelectorButton, 82x34), its tags in grey ("-" when none). One tip slot above the action bar: `tip_quantify_impact` on the run's first open; `tip_projects_count` (replacing it) when Polished Experience turns a years-failing honest line into a passing one (Graduate, Self-Taught; decided by the lines, INV-09), once per run. The CV commits on DONE, Back/Esc, another dock app and Pause > Quit to title.
10. **270x480:** the header + three rows + a tip don't fit the 328 px body, so the CV list scrolls (drag; scrollbars hidden) and the tip is scrolled into view, which puts Education's text above the fold (~60 px). At 294x639 with insets everything fits with room to spare (screenshot checked).
11. **Study:** "BigOhNo: Knowledge +5 (2 energy)", the KNOWLEDGE bar (the StatBar placeholder), and after each study a rotating BigOhNo joke (`ui_study_joke_1..3`, cosmetic); `tip_fundamentals` after the run's first study. STUDY is greyed at the KNOWLEDGE cap (80) as well as when short of pips.
12. **Coach marks** (first run only, GDD 4.3; never block input): day 1 APPLY (arrow at APPLY + a swipe-right arrow) until the first application; flip (arrow at the card) after it until a card is flipped (this session) or an application is tailored; Sleep (arrow at the moon) at 2 energy or less or 4 applications, until Sleep. They sit over the card's header strip, hide during a send/skip and on the card's back. Mail: `coach_invite_no_research` above the first invite with its arrow at GO NOW until the first interview (Research is SHOULD), hidden while that card is folded. The 2 pips and 4 applications are script constants quoting GDD 4.3 (like SLEEP_CONFIRM_PIPS); HuntTips' 8 and 10 quote GDD 8.3.
13. Once-per-run tips are recorded in `run.tips_shown` when shown and saved with the next commit.

## Verification

Runs: `r78346738-48` (project_run custom on job_hunt.tscn, smoke), `r78527323-49` (main: Title > intro Esc > Background select > Graduate first run, days 1-12), `r79041457-50` (main: Continue after a kill on the grace morning), `r79145444-51` (main: Continue, grace day, Plan B by sleeping), `r79294278-52` (main: Intern run, DEBUG Rent runs out, Retry > Graduate, 294x639 probe).
Input: real `input_mouse` taps (motion, press, release; window px = 2x game px, and origin (123,161) at 1x during the 294x639 probe) and `input_key Escape`.
Fell back to game_eval: state reads and waits; scrolling the Mail list to read its bottom (input_mouse can't drag); fast-forwarding days 5-12 with the same `GameState.sleep()/start_day()` verbs; adding waiting invites with `GameState.debug_fake_invite()` (and backdating one by a day) for the grace-day/expiry setup and the folded-invite check; setting `first_run = true` in memory on run 52 for the fold/coach check; probing `interview_cost` with `background_id` swapped in memory (restored); the 294x639 content scale + fake insets (restored); deleting the save and settings.cfg.

| Check | Result | Detail |
|---|---|---|
| test_run all | pass | 199/199, 19 suites (187/18 before). |
| Full day loop: apply -> Sleep -> night -> Mail -> Flip all -> Start day | pass | Run 49, Graduate first run (seed 329567546). Day 1: 4 applications by real taps (APPLY x3 + one after SKIPs); Sleep with 4 pips asked "You still have 4 energy. Sleep anyway?", SLEEP -> lock screen "Applied 4 - Rejected 1 - Ghosted 0 - Rent due in 11 days" -> tap -> Mail. Day 2 after 5 more applications: night "Applied 5 - Rejected 0 - Ghosted 0 - Rent due in 10 days", Mail "3 applications: no reply. Probably ever." + "Recruiter Radar [--------] -> [#-------]". Day 4 morning: "3 rejections" [Flip all] -> tap -> 3 entries ("Murkcloud - Associate Cloud Engineer / Due to shifting priorities..."), Radar 1 -> 2, no tip (rejections 2-4). START DAY -> Jobs; `day_mail` saved (3 rejections in the save). |
| Day-2 invite on a first run -> GO NOW -> interview -> back | pass | Day-2 morning: the guarantee invite (Hierarchai, "Saw your profile!", "Interview with Hierarchai: today or tomorrow"), coach mark "An interview! Rest up..." with its arrow at GO NOW, the knockout rejection naming "3+ years experience" and `tip_ats_knockouts` under it. Later folded the card; the header tap reopened it. GO NOW (real tap) from the morning: Start day ran (morning cleared, mail kept in `day_mail`), 8 -> 5 pips, phase INTERVIEW at co_synergai. DBG > Composure 0 (real taps) -> rejection card -> "Back to the hunt" -> JOB_HUNT, Jobs, day 2, interview used. Mid-day Mail then showed the kept rejection, its tip and the Radar under `[ < Back ]`. |
| CV changes change the card tags/odds | pass | Top card `job_mid_backend` at Beigeware (GDD 5.6 example 1): before, "[v Java] [v SQL] [x APIs]", chip "Knockout: 1+ years experience", Quick 5.2% [##---] (Tailored 16.8%, the GDD's number). CV: Polished Experience ("Capstone team of 4 + TA for 120 students", tags Python, Agile, "Counts as 1+ yrs: yes", `tip_projects_count`) and Polished Projects (tags SQL, Git, APIs). DONE -> the card shows "[v Java] [v SQL] [v APIs]", no chip, Quick 6.7%; the save holds exp/proj = polished. Run 52 (Intern): Lie on Experience -> "Tech Lead, cloud platform team (2 years)", tags + APIs, Cloud, Lie risk 1 red dot, no `tip_projects_count` (the Intern's honest line already passes). |
| CV first open tip | pass | Runs 48, 49, 52: `tip_quantify_impact` above `[ < Back ][ DONE ]` on the run's first open, recorded in `tips_shown`. |
| Study raises KNOWLEDGE | pass | Run 48: STUDY 2 (real tap): energy 8 -> 6, KNOWLEDGE 55 -> 60, joke "Invert a binary tree...", `tip_fundamentals` shown and recorded. |
| First-run coach marks | pass | Run 49: day 1 APPLY mark over the card strip (arrows at APPLY and swipe-right); after the 1st application the flip mark (arrow at the card); a real tap flipped the card and the mark went; at 4 applications the Sleep mark (arrow over the moon). Day 2: no Jobs coach marks. Run 52 (not a first run): none. Mail invite mark hidden while its card is folded (fix below, re-checked in run 52). |
| Night tips | pass | Run 52 (Intern): TAILOR & APPLY with "Use referral (2 left)" on (tokens 2 -> 1) -> Sleep -> the lock screen shows `tip_referrals` under the summary. `tip_tailor_over_spray` is covered by hunt_tips tests (no in-game run had 8 Quick Applies before an invite). |
| Single rejection | pass | Run 52 day 2: one plain rejection shown as one entry (no "1 rejections" header) with `tip_rejection_numbers` (the run's first rejection). |
| Plan B via "Rent runs out" | pass | Run 52: DEBUG (real tap) > "Rent runs out" (real tap) -> GAME_OVER, save deleted, run_count 1 -> 2. |
| Grace day with a waiting invite | pass | Run 49: fast-forward to day 12, rent 1; two waiting invites added (Mid received today; Startup backdated to yesterday); real Sleep -> day 13, rent 0: grace_day true, the Startup invite expired. Mail (run 51, after the Continue): "Your landlord gave you one more day. ONE." first (red), the Mid invite (no "today or tomorrow" line: it arrived yesterday) with GO NOW, the "Update / Entangled Greens - AI Generalist ... filled internally" notice, the Radar; HUD "Rent due in 0 days" in red. GO NOW -> Beigeware interview (grace_used true) -> Composure 0 -> back. |
| Plan B via real sleeping | pass | Run 51, grace day evening: Sleep (confirm) -> night "... Rent due in 0 days" -> Mail (plan_b morning) -> START DAY -> GAME_OVER, save deleted, run_count 0 -> 1. |
| Kill after Sleep, Continue | pass | Run 49 stopped with the grace-morning night screen up; relaunch (run 50/51) > CONTINUE -> the night screen again, the same morning report (md5 134b3cc7263d5fa5f023cef691c45384 before and after). |
| GO NOW cost | pass | Intern Big 3; Self-Taught Big (in person) 4, Startup (video) 3 (`interview_cost`). |
| Layout 294x639 + insets (0,45,0,26) | pass | Run 52: column x 20 / y 45, dock ends at 613. CV with the first-open tip fits without scrolling (tip right above `[ < Back ][ DONE ]`); night card centred on the full-bleed sky; Mail with START DAY and the dock at the bottom. Restored to EXPAND 270x480, zero insets. |
| Game log | pass | Runs 48, 49, 51, 52: 0 errors, 0 warnings (only the helper line, "Content: ...", and the interview's IVSTART/IVFORCE/IVRESULT traces). Run 50: project_run reported no errors at launch; its lines were no longer retained when re-read. Editor: only the known "Identifier not found: Content/GameState/SceneRouter/Device" errors. |
| Files on disk | pass | All changed scripts and scenes hold the last edits (checked after the runs); `job_hunt.tscn` was reloaded in the editor with `scene_open force_reload` after every external write, and the editor never wrote a stale copy back. |
| Cleanup | pass | `save_v1.json` and `settings.cfg` deleted; `user://` holds only godot_ai_server.pid (and the engine's own folders). Project stopped. |

## Found and fixed during verification

1. The CV and Mail lists were 4 px off to the left: the vertical scrollbar took width from a 254 px list, so it scrolled sideways. Scrollbars are now "show never" (drag scrolling still works, as on phones).
2. Opening the hub straight on Mail (Continue into a morning) pushed the HUD and the thumb band off the screen: the coach spacer copied the Jobs card's height before the card had ever been laid out (678 px for zero-width text). The spacer now follows the card only while a coach mark shows on Jobs, and it is clamped to the body.
3. The CV tip got cut off when the tag set wrapped to a second line after the tip scrolled into view: the tip is re-pinned when the list resizes.
4. The invite header clipped the subject into the company name: the header now holds the envelope and the company; the subject is the card's first line.
5. The Mail coach mark stayed (arrowless) when its invite was folded: it now hides with the fold.

## You-do queue (W3, unchanged by this stage)

- Judge the one-thumb swipe feel on the iPhone (and the Mail/CV list drag): device, P2.
- Write 5 posting jokes of your own into `postings.json`.
- Build the 5-segment `stat_bar` (the placeholder is used on the S03 card and now in Study).

## Doc follow-ups for the Doc sync stage (not edited here)

- ARCHITECTURE 7.1: RunState gains `day_mail` and `tips_shown`; `cv_line()`. ARCHITECTURE 3 / INV-03 list the pure classes (GameFlow, RunState, SaveIO, Odds): add `HuntTips`.
- ARCHITECTURE 17.7: GameState gains `mark_tip_shown()`, `interview_cost()`, `can_take_interview()`.
- ARCHITECTURE 11.4: Mail keeps the day's mail after Start day; the night screen replays on a resumed morning; GO NOW from the morning runs Start day first; the CV list scrolls at 270x480; list scrollbars hidden (Step 2 PASS buttons applied).
- GDD S05 vs 2.8: header (2 rows) + 3 rows "about 90 tall" + a tip "in the free space above the action bar" need about 360-400 px; the 270x480 body has 328, so the tip only has free space on taller phones.
- GDD 4.3 says "Tired? Tap the moon..." while CONTENT 10.2 `coach_sleep` says "Out of energy? ..." (the JSON text is used).
- CONTENT 10.1: `ui_rejections` and `ui_ghost_footer` have no singular ("1 applications: no reply" shows for n = 1; one rejection is shown without the header). Developer copy needed.
- Unused content, as before this stage: `mail_invite_grace` (the grace line uses `ui_grace_day`), `ui_rent_warning`, `coach_radar`, `coach_cv`, `coach_first_reject` (Notebook, SHOULD), `notif_*`.
- No string for rent at 0 in the HUD ("Rent due in 0 days" on the grace day).
- INV-15: the coach/tip thresholds (2 pips, 4 applications, 8 Quick Applies, every 10th rejection) are script constants quoting the GDD, not BalanceConfig fields.
- Juice not built (grey-box): invite fanfare/confetti, REJECTED stamp, Mail badge bounce (GDD 9.1).

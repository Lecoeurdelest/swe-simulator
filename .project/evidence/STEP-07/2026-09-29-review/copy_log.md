# Copy slice: plain-language choice questions, Hired card, wording fixes (2026-09-29)

Branch `step-07-dev-review`, on top of d8db453 (CV editing and lying removed, DECISIONS D9).

## What changed
- `data/content/questions_choice.json`: every prompt / answer / reaction string reworded for non-tech players (ids, kinds, tiers, tips, exclusives' backgrounds unchanged). Right answer jokingly obvious, wrong answer the joke (GDD 5.8.3).
- `data/content/endings.json`: Hired card header, 5 row labels, grade 1 and footer (REVIEW_QUEUE Q4).
- `data/content/backgrounds.json`: Graduate perk "first tech question" -> "first knowledge question". The Graduate flaw already says "unless you Tailor & Apply" (d8db453).
- `data/content/tips.json`: plainer tip_small_changes, tip_blameless, tip_secrets, tip_teamwork_without_job, tip_star_stories, tip_ask_questions.
- `ui/components/ui_text.gd`: `UiText.fill(template, args)`; `autoload/content.gd` text()/field() use it (no "Engagement Farms Inc.." double period).
- `core/run_state.gd`: `RunState.fine_print_pool()`; a startup offer never deals fp_unlimited_pto with perk_unlimited_pto.
- Tests: 3 in `tests/test_ui_text.gd`, 1 in `tests/test_offer.gd`.

## Headless
- `copy_test_run.txt`: RESULT passed=208 failed=0 total=208 suites=19 (204 before + 4 new).
- `copy_parse.txt`: CHECK files=84 failed=0.
- Grep of data/content for "CV", "Polished", "polish": no string tells the player to edit or polish a CV. Remaining hits are real-world tips, reject jokes, the ATS scan line, and the cv_lines "polished" variant ids that Tailor & Apply sends.

## In the editor (Godot 4.7.2, 270x480, project_run autosave=false)
Ran `res://features/interview/interview.tscn` (debug quick start: Graduate vs Beigeware, mid tier). Plan: eq_credit_theft, kq_password_storage, kq_estimate, kq_deadlock, eq_leaked_password.
- `copy_choice_credit_theft.png`: prompt 1, two-line prompt "Your teammate Jordan fixed the big bug. In the meeting, your manager thanks YOU." inside the dialogue box; the three answer buttons each fit on one line. Picking the good answer showed the two-line reaction "Correct. Steal credit once and your whole team starts keeping receipts." with no clipping.
- `copy_choice_leaked_password.png`: prompt 5, the three-line prompt "Someone posted the password to all our customer data in the company-wide group chat." fits the box; the buttons "Tell security so they change it." / "Screenshot it. Might be handy." / "Delete the message and move on." fit. The neutral reaction "Deleting it doesn't change it. Hacker bots copied it in seconds." fits on two lines.
- DBG > K.O. > OFFER! > the offer paper > ACCEPT > HIRED! > tap > Dream card.
- `copy_hired_card.png`: header "YOUR JOB vs REMY'S VIDEO" on one line; rows "Salary (Remy: $150k) 21.6", "Days at home (Remy: 5 of 5) 15.0", "Commute (Remy: 3 steps) 10.5", "Red flags (Remy: none) 5.0", "Rent days to spare 10.0", each on one line with its points right-aligned; grade "Pretty good" with score 62; the footer "100 is the life in Remy's video. Nobody gets 100. Not even Remy." wraps to two lines, ending at y=131, inside the 140 px DreamPanel (its content ends at y=137). Row name labels are 212 px wide (35 columns). The longest row label has 27 characters, and the longest grade ("Suspiciously close to the video", 31) fits the 204 px Grade label.
- Game log: IVSTART, 5 IVTRACE, IVFORCE and IVRESULT lines only. No warnings and no errors. The only editor log entry is an older shadowing warning at `core/run_state.gd:343` (`offer_commute`'s `commute_minutes` parameter). It was already there at HEAD, and this slice did not change it.
- Files on disk were checked after the run: unchanged (autosave off).

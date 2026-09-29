# Review fix pass (2026-09-29)

Branch `step-07-dev-review`, after a04ae64. A review of the branch found 20 confirmed issues (leftovers, docs, UX, content); the orchestrator also queued 6 follow-ups. Commits: f89cf09 (D9 leftovers), 9c2a4b0 (offer tip, VS fade), 804301a (Hired-card points, scene placeholders), d03c8ff (tips), 62c2a68 (debug Reset first run), then the docs and tracking commit. Test results: `fix_test_run.txt` (217/217, parse 85/0, cmp17 all SAME, validators valid).

## Findings

| Finding | Outcome |
|---|---|
| `barks.ui_done` orphaned | Removed from barks.json and CONTENT 10.1, together with `ui_yes` / `ui_no` and the lint's `{yes_no}` placeholder (follow-up 2); CONTENT 0 and 10.1 say so. Nothing read them (grep over autoload, core, features, ui, tests, .tscn). |
| `MailScreen._from(with_title)` and the empty-subject branch dead | `_from(entry)` always returns "Company - Job title"; `_mail_card` always adds the subject. |
| `start_interview` kept a redundant `tier_data` | Dropped; `can_take_interview()` already refuses an unknown tier. ARCHITECTURE 17.7 synced. |
| `test_offer` "Accept rolls no dice" could not fail | RNG scaffolding and the assertion removed; the doc comment says hire() takes no RNG. ARCHITECTURE 17.13 synced; ARCHITECTURE 7.2 "Accept rolls no dice" says the guarantee is structural. |
| Stale editor-preview texts (interview.tscn, phase2_stub.tscn, GDD S08 mockup) | Set to the current C3/C4 copy (and "22.4/40"-style points); the GDD S08 mockup redrawn with the same box width. `grep "sponsored\|Deploy and turn off" features/` is empty. |
| versus_intro.gd three blank lines | One removed. |
| C3 said all 14 questions were rewritten | DECISIONS C3, REVIEW_QUEUE, project.yaml and copy_log.md now say 11 reworded, 3 already plain. |
| Docs said every Dream row names Remy's number | GDD 5.9.5 and S11, CONTENT 14, ARCHITECTURE 11.7, DECISIONS C4 and project.yaml say the four video rows do; the rent row has none. |
| W7 row lacked the carve-out other docs cite | Added in place: installs, signing, iPhone checks and sign-offs stay the developer's. REVIEW_QUEUE's W7 line too. |
| REVIEW_QUEUE Q6 had no evidence | Probed (below): it was the 0.3 s slide-in, not an overlap at rest. Q6 left the questions table with a note that A47 answers it; ISSUE-10 no longer lists it. |
| REVIEW_QUEUE heads-up named the save's state | Now state-independent ("may have left a test run ... tap New game"), plus a note that this PC's next New game is a first run (A51 was used). |
| A44-A46 in no step's review list | STEP-04 lists A44-A46, STEP-05 A45 (and the new A-numbers per step). |
| Offer paper slides up under the tip | Fixed (A47): the tip waits at `modulate.a = 0` (the column keeps its room) and fades in over 0.15 s once the paper lands. |
| CoachMark `coach_id` / `text` parameters shadow methods | `point(id, tip, ...)`; the unused `coach_id()` removed. The tap rule itself moved into `DuckyNote` (see follow-up 1). A `-d` load of every script now warns only about intro.gd:234 (pre-existing, not in scope). |
| VS clip starts under the scene fade | `VersusIntro.play()` pauses on the 0.00 s frame (flash hidden) while `SceneRouter.busy`, then seeks to 0 and plays after `transition_finished`. ARCHITECTURE 11.5 and GDD S07 say so. |
| Hired rows read as days / flags | Each row shows points out of its maximum ("34.4/40", A48). GDD S11, ARCHITECTURE 11.7, CONTENT 14 updated. |
| Leaked-password reaction still about hacker bots | "Deleting it doesn't change it. Half the company already saw it. Some took screenshots." (A50; CONTENT 7). |
| `tip_star_stories` ran two lists together | "Prepare 5 stories: conflict, failure, teamwork, a win, learning fast. Tell each as situation, task, action, result." (115 chars, 3 lines). |
| `tip_small_changes` hyperbole | "Release small, tested updates early in the week, so problems get fixed before the weekend." |
| `tip_teamwork_without_job` "coding contests" | "team coding events". |
| `eq_harsh_review`'s tip didn't match the cause | New `tip_take_feedback` (A49); `tip_teamwork_without_job` has no trigger in the MVP; GDD 8.3 table updated. Tip accuracy is queued for the developer (W4). |
| Scene placeholder text (duplicate of the stale-preview finding) | Covered above. |

## Follow-ups

1. **Offer tip (Q6):** besides the fade-in, the tip is `closable` (A47). The tap rule (release on the note, no drag past the 6 px deadzone, PASS inside a ScrollContainer) moved from CoachMark into DuckyNote, which emits `close_tapped`; CoachMark and the offer both listen. Closing it hides the note for that offer only; the paper and the desk line ease (0.2 s) into the room, and into Dana's Decline line. INV-14 and ARCHITECTURE 10.5 / 11.4 / 11.7 say so.
2. `ui_yes` / `ui_no` / `{yes_no}`: removed (above).
3. `RunState.offer_commute(office_days, minutes_each_way)`: the shadowing warning is gone; sync17 + cmp17 all SAME.
4. **Debug "Reset first run"** (A51): the title's new `%DebugRow` (hidden in release builds) holds "Device check" and "Reset first run". `GameState.reset_first_run()` sets settings meta `run_count` to 0; `GameState.next_run_is_first()` is what `_init_run` and the button read. Labels are English script constants like "Device check" (not player text).
5. DECISIONS P3 added after W7.
6. `.project/bundles/STEP-07.md` written (project.yaml indexes no bundles by file, only the folder in a comment, so nothing else changed).

## Verified in the editor (540x960 window, 270x480 game)

- Title: the debug row shows `[Device check][Reset first run]` (86x34 and 104x34, 4 px apart) above Replay intro (`fix_title_debug_row.png`). A real tap set `run_count` 1 -> 0 and turned the button off (`fix_title_first_run_reset.png`).
- New game > Intern > CHOOSE: `run.first_run` true, and day 1 shows the Apply coach mark (`fix_coach_first_run_day1.png`). A real tap on the note closed it: `coach_closed = ["coach_apply"]`, the card didn't flip (`fix_coach_first_run_closed.png`).
- GO NOW on a startup invite, sampled per frame: during the fade (`SceneRouter.busy`) the clip is paused with the flash hidden; at +430 ms the fade ends and the clip starts at 0.00 with the flash; the slam's hit-stop follows. The same after Continue into the saved interview. The held frame: `fix_vs_held_after_fade.png`.
- Offer (startup), sampled per frame from the scene start: the paper rose from y 570 to its place 90-321 while the tip (325-394) stayed at alpha 0; ACCEPT turned on at landing (+705 ms), then the tip faded in over 0.15 s (`fix_offer_tip_landed.png`). A mid-tier offer rests at 102-321, a big one at 114-321; the tip at 325-394 and the thumb band from 398 in all three, so nothing overlaps at rest.
- A real tap on the tip closed it; the paper and the desk line eased from 102 to 175 in 0.2 s (`fix_offer_tip_closed.png`). Decline > confirm then eased the paper from 175 back to 122 for Dana's line (345-394). A first build of the settle jumped down before rising, because the wrapped Dana line took two layout passes; the settle now aims at the latest place each step.
- Accept on a big offer: the Hired card rows read "34.4/40", "5.0/25", "11.0/15", "5.0/10", "10.0/10" (score 65); the widest row ("Days at home (Remy: 5 of 5)" + "5.0/25") fits the 240 px sheet on one line (`fix_hired_points_out_of_max.png`).
- In-memory editor scenes checked: interview.tscn's Answer2 and phase2_stub.tscn's Footer show the new placeholder copy. The editor's 2D viewport screenshot was a stale image, so none is saved.
- Game log: only IVSTART / IVFORCE / IVRESULT debug lines, no errors. Editor test_run 217/217.

## Incident (repaired before any commit)

A throwaway probe that synced the script editor's buffers mapped the open editor tabs to the wrong files: `docs/CONTENT.md` was open as a text tab next to `features/title/title.gd`. The next run's autosave wrote title.gd empty and CONTENT.md with title.gd's text. Both were rebuilt (title.gd from the byte-exact ARCHITECTURE 17.12 copy, CONTENT.md from HEAD plus this pass's edits), both tabs were put back to the disk text and closed (File > Close All), and `git diff` was checked after every later editor run. No commit contains the damage.

## Left for the developer

- Review A47-A51 and the new copy (REVIEW_QUEUE sections 2-3), including the new tip's accuracy (W4).
- This PC's `settings.cfg` has `run_count=0` (the debug button was used), so the next New game shows the coach marks; the save holds a test run at the offer (big tier).

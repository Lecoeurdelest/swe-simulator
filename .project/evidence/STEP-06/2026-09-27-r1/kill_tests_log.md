# STEP-06 robustness stage: the 5 kill tests, desktop equivalent

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings. Runs 73-78.
ROADMAP Step 6 Done-when "All 5 kill tests resume correctly. A kill on the Hired card resumes at the offer; leaving the Hired card clears the save." The checklist the developer runs on the iPhone is `docs/KILL_TESTS.md`.

## Method

- **Kill** = godot-ai `project_manage op=stop` while the game runs. The editor ends the process; the game gets no pause or close notification, so nothing is saved on the way out. This is harsher than the iPhone, where the app switcher first sends `APPLICATION_PAUSED` (a save) and only then is the app killed.
- **Resume** = `project_run` again, then a real tap on CONTINUE (window 270,836 = game 135,418).
- **Compared** before the kill, on disk after the kill, and after CONTINUE: the phase, the run fields named below, the run RNG state (`GameState.rng.state`) and the md5 of `user://save_v1.json`. The live values were read with `game_eval` (read-only); every action was a real tap or a real Esc (`game_manage input_mouse` / `input_key`).
- One run of Graduate ("Alex"), first run of the profile (run_count 0), fresh `user://` (no save, no settings.cfg) at the start of run 73.

## Results

| # | Moment | Before the kill | Save on disk after the kill | After CONTINUE | Result |
|---|---|---|---|---|---|
| 1 | Mid-hunt (run 73 -> 74) | JOB_HUNT, day 1, energy 6/8, 2 applications (`job_st_growth\|co_synergai`, `job_mid_mobile\|co_bytebistro`), board uids [3, 4, 5, 6], CV `exp` = polished (changed on the CV screen, committed on its `< Back`), rng -4620382227031484853, save md5 b1fbbabd... | unchanged: md5 b1fbbabd2e3309e37e37cc7eac02e211, phase 3, day 1, energy 6, 2 applications, board [3, 4, 5, 6], CV as set, rng state as live | the hub on Jobs with the same day, energy, applications, board, top card (uid 3), CV and rng state; the save md5 is the same after the resume's own save | pass |
| 2 | Right after Sleep (run 74 -> 75) | SLEEP (real taps: moon, SLEEP in the confirm) -> night lock screen "Applied 2 - Rejected 0 - Ghosted 0 - Rent due in 11 days"; day 2, energy 8, morning_report md5 26626e55..., rng -1281692546808135644, save md5 5f20862e... | unchanged: md5 5f20862e771db8656305e22e9ca73faa | the night lock screen again with the identical summary, the same morning_report (md5 26626e5537c926f96f57cf09d8c04c09), day 2, energy 8, same rng and save md5; Esc -> the same morning inbox ("1 application: no reply. Probably ever.", Radar) -> START DAY | pass |
| 3 | Mid-interview (run 75 -> 76) | INTERVIEW from the DEBUG MID invite: IVSTART tier=mid, co_beigeware, seed 918087422, ids eq_celebrity_orders, kq_index_tradeoff, kq_left_join, kq_star_conflict, eq_harsh_review, warm-up kq_learn_fast; prompt 1 answered (good; Doubt 128 -> 118); energy 5, interviews_today 1, invites 0, rng 3482029313897798913, save md5 621f1930... | unchanged: md5 621f19303a1fcf8d1ca0ec9ddd0e2c19, phase 4 with the same checkpoint | the interview restarts from the VS intro with the identical IVSTART line; Doubt 128 and Composure 100 again, prompt 1 not answered; energy 5 (not charged again), interviews_today 1, the invite still gone, same rng and save md5 | pass |
| 4 | On the offer (run 76 -> 77) | OFFER after a forced wheel win (DBG): co_beigeware, Backend Developer, $83,000/year, hybrid 2 office days, commute 2 x 45 min = 3.0 h, perks perk_banana + perk_pto20, fine print fp_perks; contract text md5 27131bb2...; rng 3482029313897798913; save md5 09738f2d... (interview checkpoint cleared) | unchanged: md5 09738f2ddb4434bf1b70f5963bc9ec36, phase 5, the same offer | the same offer dictionary, the same contract text (md5 27131bb26bf9d0d7c8aff2116ffbeb8f), same rng and save md5; ACCEPT and Decline enabled after the slide | pass |
| 5 | On the Hired card (run 77 -> 78) | ACCEPT (real tap) -> Hired card beat 1: employment = the offer + red_flags ["Legacy code from 1998"], Dream 62; the save on disk is still the OFFER one (md5 09738f2d...), run_count not set (0) | unchanged: md5 09738f2ddb4434bf1b70f5963bc9ec36, phase 5, employment {}, dream_score -1; settings.cfg has no run_count | the OFFER again with the same contract (md5 27131bb2...) and rng; ACCEPT -> the same Hired card (Dream 62, same company/role/salary), run_count still 0, save still present; Esc -> tally, tap -> done ("Pretty good 62"), Esc (= `< Title`) -> Title: save deleted, run_count 0 -> 1 (once), no CONTINUE | pass |

All 5 pass. No background-check dice were rolled on either Accept (the DEBUG invite has no application, so no Lie was sent): the rng state is the same before and after both Accepts.

## Also checked

- Every kill left the save byte-identical to the last committed state (md5 before = md5 after), and each resume's own `change_phase()` save wrote the same bytes again (same md5), so a resume is deterministic.
- Game log for runs 73-78: 0 errors, 0 warnings (the helper line, "Content: 3 backgrounds, 3 tiers, 16/16 JSON files", and the debug IVSTART / IVTRACE / IVFORCE / IVWHEEL / IVRESULT lines only).
- After the runs the save was already gone (leaving Plan B / the Hired card deletes it); `user://settings.cfg`, which these runs created, was deleted.

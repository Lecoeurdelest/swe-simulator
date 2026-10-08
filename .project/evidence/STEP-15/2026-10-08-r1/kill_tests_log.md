# STEP-15 kill tests on the desktop, 2026-10-08

The career run's moments of `docs/KILL_TESTS.md` (6-11), run by Claude in the editor through the godot-ai MCP on the Windows PC. A "kill" is `project_manage op=stop` (harsher than an iPhone's: the game gets no "paused" notification, so it cannot save on the way out), then `project_run mode=main` and a tap on CONTINUE. `user://save_v1.json` is the one slot. Moments 9 and 10 belong to M3 (the review duel) and the layoff scene's own kill is not run yet.

| # | What was done | Expected | Seen |
|---|---|---|---|
| 6 | New run on the Intern, 4x, a recruiter DM card answered on day 2 (a save), then 1x to live day 6 with no card open. Kill. | the day of the last save, the saved numbers, the clock waiting, paused | CONTINUE: day 2 (the card's answer was the last save), Ticket 5.14 % (the saved value; live was 15.41 %), Hours 3, speed Pause. **pass** |
| 6b | Pause menu > Quit to title, then CONTINUE, on a run laid off on day 240 and between jobs. | the same screen | day 240, "Between jobs", the feed, Hours notch 1, the Studio coach note still open, runway 4.0 mo, the clock paused. **pass** |
| 7 | A rumor notice open on day 150 (the first of the five signs). Kill. | the same card, before any choice | CONTINUE: day 150, the same notice with its OK waking after the 250 ms lock. **pass** |
| 8 | An E12 incident card, Escalate pressed, the Ducky tip notice up. Kill at once. | the choice made, its effects applied once | CONTINUE: day 40, MO -3 (once, not -6), Burnout 22, the card gone, the Ducky tip notice open, `tips_seen` has `tip_escalate`. The live state and the saved one were equal before the kill. **pass** |
| 11 | Plan B forced (savings below zero 29 days, then one more). The ending card showed. Kill. | no CONTINUE | `SaveIO.exists()` false on the ending card (entering GAME_OVER deletes the save and counts the run); after the kill the Title shows no CONTINUE. **pass** |

Also played through `GameState`'s own verbs, the way the screen calls them (a careful autoplay at Hours 1): New game, WORK, the layoff on day 240 (LAYOFF), WORK between jobs, the Plan B ending on day 390 (GAME_OVER), one layoff, the Handbook merged four tips, the save deleted, `run_count` up by one. The phases ran 8, 9, 8, 7 (WORK, LAYOFF, WORK, GAME_OVER).

What it showed that the tests did not (fixed in the same session): the day counter and the bars only refreshed on eventful days (`career_tick` returned early on an empty day), the E07 prep card had no text of its own, and the speed row was 5 px too wide (the "Pause" button needs 44 px).

One more, found while writing row 6b: quiet days were lost on a Quit to title. The run saves on its eventful days, so Pause > Quit to title then CONTINUE could go back to the last eventful day (seen: day 3 became day 1). Pause now saves when it opens, and `quit_to_title()` saves before it leaves. Checked after the fix on a fresh run at 1x: day 13 before Back, day 13 in the save the moment Pause opened, day 13 after Quit to title and CONTINUE, the clock paused, the Work scene.

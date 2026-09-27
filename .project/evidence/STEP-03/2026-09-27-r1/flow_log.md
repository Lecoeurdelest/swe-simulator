# STEP-03 part B: the real Title and the stub flow (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam) with the godot-ai MCP. The game ran embedded in the editor's Game tab: window 540x960, game 270x480, integer x2. Taps were real `game_manage input_mouse` events in window pixels (game px x2): a motion event, then press, then release at the control's centre. Back was a real `input_key Escape` press and release. **No step fell back to emitting `pressed` from `game_eval`.** `game_eval` was used only to read state (`GameState.run.phase`, `SaveIO.exists()`, labels, rects) and, once, to send `NOTIFICATION_APPLICATION_FOCUS_OUT` to GameState. Screenshots (`editor_screenshot source="game"`) can't be saved as files, so this log describes them.

## What was built

| File | What |
|---|---|
| `features/title/title.tscn` + `.gd` | The real Title, without art. Skeleton: Background, SafeArea > Column (254) > SkyBand (36, debug size readout), Sign (PanelContainer 216 wide: "SOFTWARE" / "ENGINEER" in Press Start 2P 24, "SIMULATOR" in 16, HeaderLabel amber), Body (expands), ThumbBand ("Tap to start" / `[ New game ]` + full-width primary `[ CONTINUE ]` / bottom row: flat "Replay intro", debug "Device check", version bottom-right), ModalLayer (layer 10) > QuitDialog (confirm_dialog) |
| `features/intro/` | Stub: header, card, `[ < Back ][ SKIP ]`. Skip calls `finish_intro()`; `handle_back()` calls `finish_intro()` too |
| `features/background_select/` | Stub: header, prompt "How did you spend those four years?", a plain VBox of 3 buttons (INTERN / GRADUATE / SELF-TAUGHT) calling `choose_background(id, "Alex")`, `[ < Back ]`. The preselected one (`preselect_background`, else graduate) uses PrimaryButton. `handle_back()` calls `quit_to_title()` |
| `features/job_hunt/` | Stub: HUD (Day, Rent due in N days, Energy n/max, Knowledge), status card, `[ Fake invite (Mid) ]`, `[ Rent runs out ]` (Danger), action row `[=]` 34 + Study 104 + Sleep 104; PauseMenu in the ModalLayer. It refreshes on `run_changed` |
| `features/interview/` | Stub: company/tier/template from `run.interview`, `[ Lose ]` (Danger), `[ < Back ][ WIN ]`; PauseMenu plus a "Ready? Tap to continue." overlay (process_mode WHEN_PAUSED) for GameState's focus-loss pause |
| `features/offer/` | Stub: PaperPanel contract (company, template, `$salary/year`, office days), `[ < Back ]` row, `[ Decline ][ ACCEPT ]`; PauseMenu + DeclineDialog (confirm_dialog, danger) |
| `features/phase2_stub/` | Stub Hired card: summary + Dream vs Reality score + "TO BE CONTINUED", `[ < Title ][ NEW RUN ]` |
| `features/game_over/` | Stub Plan B: `end_plan_b` text + `end_stats` line, `[ < Title ][ RETRY ]` |
| `tests/test_flow.gd` | +2 tests: one screen per phase with `handle_back()`, and no screen that changes the phase or the scene (INV-01/02) |

The `.gitkeep` files in the 7 now-populated feature folders were removed. The scene files were written, then opened and saved in the editor, which stamped the scene uids and node `unique_id`s. No `.gd` file changed during those saves (md5 and mtime compared before and after).

## Click-through (phase = `GameState.run.phase`, save = `SaveIO.exists()`, read after each step)

Start state: `user://save_v1.json` absent, `user://settings.cfg` absent (intro not seen, run_count 0).

| # | Screen / action (window px) | Observed afterwards | phase | save |
|---|---|---|---|---|
| 1 | Boot | Title: size readout "win 540x960 game 270x480 integer"; logo sign 216x86 at (27,44); "Tap to start" (8,400 254x36) blinking; no New game / CONTINUE; bottom row: Replay intro 86x34 at (8,442), Device check 86x34 at (98,442), "v0.1.0" right-aligned | TITLE | false |
| 2 | Tap empty space (270,500) | Intro stub: header "INTRO", card text, `< Back` 80x36 at (8,440), `SKIP` 168x36 at (94,440) | INTRO | false |
| 3 | Tap SKIP (356,916) | Background select; intro_seen = true; GraduateButton = PrimaryButton, the other two plain; preselect "" | BACKGROUND_SELECT | false |
| 4 | Tap `< Back` (96,916) | Title again; Tap to start visible, CONTINUE hidden | TITLE | false |
| 5 | Tap empty space (270,500) | Straight to Background select (intro_seen, so no intro) | BACKGROUND_SELECT | false |
| 6 | Tap THE GRADUATE (270,748) | Hunt: "Day 1 / Rent due in 12 days / Energy 8/8 / Knowledge 55", "Interviews today: 0/1"; bg graduate, name Alex | JOB_HUNT | **true** |
| 7 | Tap Study (200,916) | Energy 6/8, Knowledge 60; the save holds energy 6, knw 60 | JOB_HUNT | true |
| 8 | Tap Sleep (420,916) | Day 2, Rent due in 11 days, Energy 8/8; save day 2 | JOB_HUNT | true |
| 9 | Tap Study | Energy 6/8, Knowledge 65 | JOB_HUNT | true |
| 10 | Tap `=` (50,916) | Pause sheet open, tree paused; Quit to title 240x36 at (15,391), Resume 240x36 at (15,433). Screenshot: dimmed hunt, slate sheet at the bottom | JOB_HUNT | true |
| 11 | Esc | Pause closed, tree unpaused | JOB_HUNT | true |
| 12 | Esc | Pause open again (Esc = `[=]`) | JOB_HUNT | true |
| 13 | Tap Quit to title (270,818) | Title with `[ New game ]` 254x36 at (8,358) above `[ CONTINUE ]` 254x36 PrimaryButton at (8,400); Tap to start hidden. Save = day 2, energy 6, knw 65, rent 11, phase JOB_HUNT | TITLE | true |
| 14 | Tap empty space (270,500) | Nothing (with a save, tap-anywhere is off) | TITLE | true |
| 15 | Tap CONTINUE (270,836) | Hunt resumed: "Day 2 / Rent due in 11 days / Energy 6/8 / Knowledge 65" (same day, energy and stats) | JOB_HUNT | true |
| 16 | Tap Fake invite (Mid) (270,748) | Interview stub "co_beigeware (mid) / job_mid_backend"; energy 6 -> 3, interviews_today 1; run.interview seed "4281149098"; save phase INTERVIEW | INTERVIEW | true |
| 17 | Tap `< Back` (96,916) | Pause open; Ready overlay stays hidden | INTERVIEW | true |
| 18 | Tap outside the sheet (270,300) | Resumed, unpaused | INTERVIEW | true |
| 19 | Esc, Esc | Pause open, then closed (Esc = `< Back`) | INTERVIEW | true |
| 20 | `GameState.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` | Tree paused, "Ready? Tap to continue." overlay shown, save phase INTERVIEW. Screenshot: dimmed interview, one slate panel mid-screen with the line | INTERVIEW | true |
| 21 | Tap where WIN is (356,916) | Only unpauses and hides the overlay; WIN not pressed | INTERVIEW | true |
| 22 | Esc, tap Quit to title | Title with CONTINUE; save phase INTERVIEW | TITLE | true |
| 23 | Tap CONTINUE | The same interview (seed 4281149098), energy 3 | INTERVIEW | true |
| 24 | Tap WIN (356,916) | Offer stub: paper "co_beigeware / job_mid_backend / $80000/year, 2 office days a week"; `< Back` 80x36 at (8,398); Decline 80x36 at (8,440); ACCEPT 168x36 at (94,440); interviews_taken 1; save phase OFFER | OFFER | true |
| 25 | Tap Decline (96,916) | Confirm dialog: "Decline this offer? Rent keeps ticking.", `[ Back ]` 80x36 + `[ Decline ]` DangerButton 168x36 | OFFER | true |
| 26 | Esc | Dialog cancelled; offer kept; Pause not opened | OFFER | true |
| 27 | Tap `< Back` (96,832) | Pause open (Back never declines) | OFFER | true |
| 28 | Tap Resume (270,902); Esc; Esc | Resumed; Esc opens Pause; Esc closes it | OFFER | true |
| 29 | Tap Decline, then the dialog's Decline (356,916) | Back to the hunt, same day 2, energy 3; blacklist ["co_beigeware"]; offer {} | JOB_HUNT | true |
| 30 | Tap Fake invite (Mid) | Refused: status "No interview: it needs 3 energy and today's slot." (day's slot used) | JOB_HUNT | true |
| 31 | Tap Sleep, Fake invite | Day 3, rent 10; Interview | INTERVIEW | true |
| 32 | Tap Lose (270,832) | Back to the hunt, day 3; interviews_taken 2; offer {} | JOB_HUNT | true |
| 33 | Tap Sleep, Fake invite, WIN | Day 4; Offer $80000 | OFFER | true |
| 34 | Tap ACCEPT (356,916) | Hired stub: "co_beigeware / job_mid_backend / $80000/year / Dream vs Reality: 64 / TO BE CONTINUED - Phase 2: The Working Life"; `< Title` 80x36, `NEW RUN` 168x36; run_count 1. The save still holds the OFFER checkpoint (by design: a kill on the Hired card can Continue) | PHASE2_STUB | true |
| 35 | Esc | Title; **CONTINUE hidden**, Tap to start visible (leaving the Hired card deleted the save) | TITLE | **false** |
| 36 | Esc | "Quit the game?" dialog, `[ Back ]` + `[ Quit ]` DangerButton. Screenshot: dimmed title, paper line above the red Quit | TITLE | false |
| 37 | Tap empty space behind the dialog (270,500) | Dimmer blocks it: no new game, dialog still open | TITLE | false |
| 38 | Tap the dialog's Back (96,916) | Closed | TITLE | false |
| 39 | Esc, Esc | Opens, then Esc cancels | TITLE | false |
| 40 | Tap Replay intro (94,918) | Intro (even with intro_seen = true) | INTRO | false |
| 41 | Esc | Skipped to Background select (Esc = `< Back` = `finish_intro()`) | BACKGROUND_SELECT | false |
| 42 | Esc | Title (Esc = `< Back` = `quit_to_title()`), no CONTINUE | TITLE | false |
| 43 | Tap empty space, tap THE SELF-TAUGHT (270,832) | Hunt: "Day 1 / Rent due in 12 days / Energy 6/6 / Knowledge 55" | JOB_HUNT | true |
| 44 | Tap Rent runs out (270,832) | Plan B stub: `end_plan_b` text, "Days: 1 - Applications: 0 - Interviews: 0 - Rejections: 0", `< Title` 80x36, `RETRY` 168x36 | GAME_OVER | **false** |
| 45 | Tap RETRY (356,916) | Background select, fresh run (no background, day 1), preselect "self_taught" (SelfTaughtButton = PrimaryButton) | BACKGROUND_SELECT | false |
| 46 | Tap THE INTERN (270,664) | Hunt: "Day 1 / Rent due in 15 days / Energy 9/9 / Knowledge 50" | JOB_HUNT | true |
| 47 | Tap Rent runs out, then `< Title` (96,916) | Plan B, then Title with **no CONTINUE** | TITLE | false |
| 48 | Tap empty space, THE GRADUATE, Rent runs out, Esc | Plan B, then Esc -> Title (Esc = `< Title`), no CONTINUE | TITLE | false |
| 49 | Tap empty space, GRADUATE, Fake invite, WIN, ACCEPT, NEW RUN (356,916) | Background select, fresh run, preselect "graduate"; save deleted by leaving the Hired card | BACKGROUND_SELECT | false |
| 50 | GRADUATE, Fake invite, WIN, ACCEPT, `< Title` (96,916) | Title, no CONTINUE | TITLE | false |
| 51 | Esc, tap Quit (356,916) | `get_tree().quit()`: the game process stopped (`editor_state` status "stopped") | - | false |

Both Done-when paths ran on desktop: Title > Intro > Background select > Hunt > Interview > Offer > Hired > Title (steps 2-35), and Hunt > Plan B > Retry > Background select (steps 43-45).

## Back: on-screen vs Esc (every screen)

| Screen | On-screen Back | What it did | Esc |
|---|---|---|---|
| Title | none (the root; iOS never quits) | - | "Quit?" (Windows); Esc again or Back cancels; Quit exits |
| Intro | `< Back` (step 40 used Esc; the button calls the same `Device.handle_back`) | `finish_intro()` | same (step 41) |
| Background select | `< Back` (step 4) | `quit_to_title()` | same (step 42) |
| Hunt | `[=]` (step 10) | Pause open / close | same (steps 11-12) |
| Interview | `< Back` (step 17) | Pause open / close | same (step 19) |
| Offer | `< Back` (step 27) | Pause open / close; the Decline dialog closes first | same (steps 26, 28) |
| Hired | `< Title` (step 50) | `quit_to_title()`, save deleted | same (step 35) |
| Plan B | `< Title` (step 47) | `quit_to_title()` | same (step 48) |

Every on-screen Back button is connected to `Device.handle_back()`, the same entry point as Esc, and each screen's `handle_back()` does the ARCHITECTURE 9 action.

## Hit areas and layout (all 8 screens instantiated on a canvas layer behind the Title, measured after 2 frames, then freed)

- Every Column: x 8, width 254.
- The smallest side of any shown button: **34 px** (Title's Replay intro and Device check are 86x34; `[=]` is 34x36; everything else is 36 tall).
- Action bars: `< Back`/`< Title`/Decline 80x36 at x 8; the primary 168x36 at x 94-262 (GDD 2.8).
- Full-width buttons are 254x36. The pause sheet buttons are 240x36 and the dialog's are 80x36 + 168x36 (measured while open).
- Gaps: 6 px in columns and action bars, 4 px in the Title's bottom row.
- Every thumb-band control is at y >= 314. The top bands hold only labels.

| Screen | Shown buttons (x, y, w, h) |
|---|---|
| Title (no save) | Replay intro 8,442,86,34 · Device check 98,442,86,34 |
| Title (save) | New game 8,358,254,36 · CONTINUE 8,400,254,36 · Replay intro · Device check |
| Intro | < Back 8,440,80,36 · SKIP 94,440,168,36 |
| Background select | INTERN 8,314,254,36 · GRADUATE 8,356 · SELF-TAUGHT 8,398 · < Back 8,440,80,36 |
| Hunt | Fake invite 8,356,254,36 · Rent runs out 8,398,254,36 · = 8,440,34,36 · Study 48,440,104,36 · Sleep 158,440,104,36 |
| Interview | Lose 8,398,254,36 · < Back 8,440,80,36 · WIN 94,440,168,36 |
| Offer | < Back 8,398,80,36 · Decline 8,440,80,36 · ACCEPT 94,440,168,36 |
| Hired / Plan B | < Title 8,440,80,36 · NEW RUN / RETRY 94,440,168,36 |

## Fonts

- TapToStart, Version, SizeReadout, ReplayIntroButton and DeviceCheckButton all resolve `font` to `res://ui/fonts/monogram/ttf/monogram.ttf` at size **16**, with no per-node font or size override. They inherit the project theme default (monogram 16).
- A 40-character line measures 240x13.
- The logo "SOFTWARE" is Press Start 2P at 24 (a whole multiple of its native 8).

## Logs

- **Clean relaunch** (run r52620029-16, Title + Device check + Quit dialog): the game log has only the helper line and `Content: 3 backgrounds, 3 tiers, 0/16 JSON files`. **0 errors, 0 warnings.**
- The editor log has nothing new since the session start (cursor 53). The 53 older lines are only the known stale "Identifier not declared / not found: GameState/Content/Device/SceneRouter" autoload errors (AGENTS.md gotcha).
- **Main click-through run** (r51895725-15, steps 1-51): 2 errors, both **caused by my first probe**, not by the game. I called `GameState.setting("meta", "intro_seen", null)`, and `ConfigFile.get_value` logs an error when the key is missing and the default is null. Every later probe passed a real default, and the ~70 scene transitions logged nothing.

## Cleanup

- At the end, `SaveIO.delete()` and `DirAccess.remove_absolute("user://settings.cfg")` ran through `game_eval`. The settings file had `[meta] intro_seen=true run_count=6`, and it did not exist before the session.
- The relaunch confirmed: no save, no settings file, intro_seen false, run_count 0, Tap to start visible.
- The developer's first tap will play the intro again, and the next run counts as the first (for the day-2 guarantee).
- `project_manage stop` ran at the end.

## Notes

- The Title's "Tap to start" blinks by toggling its alpha every 0.5 s (a tween loop, no layout change). Screenshots caught both phases: steps 1 and 13 show it hidden, and the clean relaunch shows it visible, centred at about y 418.
- `addons/godot_ai/utils/log_buffer.gd` got a new mtime (06:53:48) during a scene save, but its bytes equal the file in the updater's v4 payload. The editor re-saved an open script, so git sees no content change.

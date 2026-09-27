# STEP-04 r1: stub and component text from Content JSON (INV-15, Step 3 finding F5)

Stage: "ui text" (INV-15 cleanup), Windows PC, Godot 4.7.2 (steam), 2026-09-27.

## Method

- `project_run mode=main`, driven with `game_manage input_mouse` (window px = 2x game px, a `motion` before each press, press + release), Esc through `input_key`.
- Each screen's visible text was read with `game_manage get_ui_elements` and compared with `data/content/*.json` (screenshots taken with `editor_screenshot source="game"`, not saved as files).
- `game_eval` was used only to read state (current scene, `get_tree().paused`, dialog visibility, `run.offer`), plus three setups, each marked below: rent set to 1 day to show `ui_rent_due_one`; a DuckyNote instanced once, because no screen places one yet; and the cleanup at the end.
- Tree pause: checked after every Pause, Quit and scene change. It was never left paused.
- Game log (`logs_read source=game`): 0 errors, 0 warnings. That includes no `Content: missing text` warning, so every id resolved. Editor log since the pre-run cursor (55): no new entries.
- Route: Title (no save) > Esc "Quit?" > `< Back` > tap anywhere > Intro > SKIP > Background select (Graduate) > Hunt > `=` Pause > RESUME > Fake invite > Interview stub > WIN > Offer > Decline > `< Back` > ACCEPT > Hired > `< Title` > Title > tap > Background select (Self-Taught) > Hunt > Rent runs out > Plan B > RETRY > Background select (Self-Taught preselected) > Hunt > Pause > Quit to title > Title with save > CONTINUE > Hunt > Pause > Quit to title.

Source key: `file/id` = `Content.text()`/`field()`; `UPPER(...)` = `UiText.primary()` (PrimaryButton, agent default); `< ` + ... = `UiText.back()`; `DEBUG_*` = debug-only English constant in the screen script (temporary stub text, not player content); "format" = a number or join format kept in code.

## Title (no save)

| Node | Shown | Source | Match |
|---|---|---|---|
| Software | SOFTWARE | barks/ui_logo_1 (new) | yes |
| Engineer | ENGINEER | barks/ui_logo_2 (new) | yes |
| Simulator | SIMULATOR | barks/ui_logo_3 (new) | yes |
| TapToStart | Tap to start | barks/ui_tap_to_start | yes |
| ReplayIntroButton | Replay intro | barks/ui_replay_intro | yes |
| DeviceCheckButton | Device check | DEBUG_DEVICE_CHECK (debug builds only) | debug |
| SizeReadout | win 540x960 game 270x480 integer | Step 1 debug overlay (debug builds only) | debug |
| Version | v0.1.0 | format "v%s" + `application/config/version` | format |

Quit dialog (desktop Esc):

| Node | Shown | Source | Match |
|---|---|---|---|
| Message | Quit the game? | barks/ui_quit_confirm | yes |
| CancelButton | < Back | `< ` + barks/ui_back | yes |
| ConfirmButton (DangerButton) | Quit | barks/ui_quit (new, needs the developer's sign-off) | yes |

## Title (with a save, after Pause > Quit to title)

| Node | Shown | Source | Match |
|---|---|---|---|
| NewGameButton | New game | barks/ui_new_game | yes |
| ContinueButton (PrimaryButton) | CONTINUE | UPPER(barks/ui_continue "Continue") | yes |
| ReplayIntroButton, DeviceCheckButton, Version | as above | as above | yes |

CONTINUE resumed the Self-Taught run in the Hunt.

## Intro (first run)

| Node | Shown | Source | Match |
|---|---|---|---|
| Header | INTRO | DEBUG_HEADER | debug |
| Text | Stub: the intro cutscene arrives in Step 6. / Skip, Back or Esc goes to Background select. | DEBUG_NOTE | debug |
| BackButton | < Back | `< ` + barks/ui_back | yes |
| SkipButton (PrimaryButton) | SKIP | UPPER(barks/ui_skip) | yes |

## Background select

| Node | Shown | Source | Match |
|---|---|---|---|
| Header | BACKGROUND SELECT | DEBUG_HEADER | debug |
| Prompt | How did you spend those four years? | barks/ui_background_header (new) | yes |
| Text | Stub: three plain buttons, name Alex. / The highlighted one is preselected. | DEBUG_NOTE | debug |
| InternButton | THE INTERN - EASY | backgrounds/intern.title + " - " (format) + .difficulty | yes |
| GraduateButton | THE GRADUATE - MEDIUM | backgrounds/graduate.title + .difficulty | yes |
| SelfTaughtButton | THE SELF-TAUGHT - HARD | backgrounds/self_taught.title + .difficulty | yes |
| BackButton | < Title | `< ` + barks/ui_title (GDD S03 `[ < Title ]`) | yes |
| (player name) | Alex (`run.player_name` after choosing) | names/default | yes |

First visit: The Graduate is highlighted (PrimaryButton). After Retry from a Self-Taught run, The Self-Taught is highlighted (theme variations read back: "", "", "PrimaryButton").

## Job hunt (stub)

| Node | Shown | Source | Match |
|---|---|---|---|
| Day | Day 1 | barks/ui_day {day} | yes |
| Rent | Rent due in 12 days | barks/ui_rent_due {days} | yes |
| Rent (game_eval setup: rent_days_left = 1, then run_changed) | Rent due TOMORROW | barks/ui_rent_due_one | yes |
| Energy | Energy 8/8 (Graduate), Energy 6/6 (Self-Taught) | barks/ui_energy + " %d/%d" (format) | yes |
| Knowledge | Knowledge 55 | DEBUG_KNOWLEDGE | debug |
| Header | DoomApply | naming/app_jobs | yes |
| Status | Interviews today: 0/1 | DEBUG_INTERVIEWS_TODAY | debug |
| FakeInviteButton | Fake invite (Mid) | DEBUG_FAKE_INVITE | debug |
| RentOutButton | Rent runs out | DEBUG_RENT_OUT | debug |
| PauseButton | = | the `[=]` icon stand-in (glyph in the .tscn, GDD S04) | glyph |
| StudyButton | Study | barks/ui_tab_study | yes |
| SleepButton | Sleep | barks/ui_sleep | yes |

Not shown in this run (debug only): DEBUG_TOO_TIRED, DEBUG_NO_INTERVIEW.

Pause sheet:

| Node | Shown | Source | Match |
|---|---|---|---|
| QuitButton | Quit to title | barks/ui_pause_title | yes |
| ResumeButton (PrimaryButton) | RESUME | UPPER(barks/ui_pause_resume "Resume") | yes |

## Interview (NOT in scope: features/interview/ is rebuilt by the next stage)

Passed through only. It still shows hard-coded text: "INTERVIEW (STUB)", "co_beigeware (mid) / job_mid_backend", the stub note, "Lose", "< Back", "WIN", and (not seen) "Ready? Tap to continue." (id `ui_ready` exists).

## Offer (via WIN; offer = co_beigeware, job_mid_backend, mid, salary 80000)

| Node | Shown | Source | Match |
|---|---|---|---|
| Header | OFFER! | barks/vs_offer | yes |
| Contract line 1 | OFFER OF EMPLOYMENT - Beigeware Financial | emails/offer_title (new) {company = companies/co_beigeware.name} | yes |
| Contract line 2 | Backend Developer | postings/job_mid_backend.title | yes |
| Contract line 3 | $80,000/year | emails/offer_salary (new) {salary = UiText.money(80000)} | yes |
| Contract line 4 | Hybrid: 2 office days a week | emails/offer_mode_mid | yes |
| BackButton | < Back | `< ` + barks/ui_back | yes |
| DeclineButton | Decline | barks/ui_decline | yes |
| AcceptButton (PrimaryButton) | ACCEPT | UPPER(barks/ui_accept) | yes |

Decline dialog:

| Node | Shown | Source | Match |
|---|---|---|---|
| Message | Decline this offer? Rent keeps ticking. | barks/ui_decline_confirm | yes |
| CancelButton | < Back | `< ` + barks/ui_back | yes |
| ConfirmButton (DangerButton) | Decline | barks/ui_decline | yes |

## Hired card (after ACCEPT; dream_score 62)

| Node | Shown | Source | Match |
|---|---|---|---|
| Header | HIRED! | endings/end_hired_title | yes |
| Summary line 1 | Beigeware Financial | companies/co_beigeware.name | yes |
| Summary line 2 | Backend Developer | postings/job_mid_backend.title | yes |
| Summary line 3 | $80,000/year | emails/offer_salary {salary} | yes |
| Summary line 4 | DREAM vs REALITY: 62 | endings/end_dream_header + ": %d" (format) | yes |
| ToBeContinued | TO BE CONTINUED - Phase 2: The Working Life | endings/end_tbc | yes |
| TitleButton | < Title | `< ` + barks/ui_title | yes |
| NewRunButton (PrimaryButton) | NEW RUN | UPPER(barks/ui_new_run "New run") | yes |

`< Title` went to the title, and the save was gone (`SaveIO.exists()` false).

## Plan B (via "Rent runs out", Self-Taught run)

| Node | Shown | Source | Match |
|---|---|---|---|
| Header | PLAN B | endings/end_plan_b_title | yes |
| Text | Rent's due. You became a ClikClok career coach. Your course 'How I Almost Got Into Tech' has 40,000 students. | endings/end_plan_b | yes |
| Stats | Days: 1 - Applications: 0 - Interviews: 0 - Rejections: 0 | endings/end_stats {day, n, i, r} | yes |
| TitleButton | < Title | `< ` + barks/ui_title | yes |
| RetryButton (PrimaryButton) | RETRY | UPPER(barks/ui_retry "Retry") | yes |

## DuckyNote component (game_eval: instanced once in the Hunt's ModalLayer, then freed)

| Node | Shown | Source | Match |
|---|---|---|---|
| Name | Ducky | naming/mascot | yes |
| Tip | ATS software rarely auto-rejects on keywords. Knockout questions (degree, years, location) do. | set by the eval from tips/tip_ats_knockouts.short (the owner sets tip_text) | yes |

## Automated check

`tests/test_ui_text.gd` `test_screen_text_ids_exist` scans every `.gd` under `res://features/` and `res://ui/` for `Content.text()`/`field()` calls with literal ids: 44 calls, 38 distinct ids, all present in the JSON. It skips ids built at runtime (`"offer_mode_" + tier`, `Content.field("backgrounds", id, ...)`); the run above covered those.

## Cleanup

A save and `user://settings.cfg` did not exist before the run. After the run (on the title, phase TITLE): `SaveIO.delete()`, and `DirAccess.remove_absolute("user://settings.cfg")` returned 0. Both were confirmed absent, the game was stopped, and `C:/Users/Mmotkim/AppData/Roaming/Godot/app_userdata/SWE Simulator/` holds neither file.

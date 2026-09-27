# Verification: Step 2 (PC part) and Step 3, adversarial pass

- Date: 2026-09-27. Machine: Windows PC, Godot 4.7.2-stable (steam), godot-ai MCP, game embedded in the editor's Game tab (window 540x960, game 270x480, integer x2).
- Starting state: git clean on `step-03-stub-flow` at 0da5d1a; no `user://save_v1.json` and no `user://settings.cfg` (checked in-game before the first tap).
- Game runs: `r53077595-17` (the full click-through, before any change) and `r54104239-18` (after the theme fix). Both game logs hold only the helper line and `Content: 3 backgrounds, 3 tiers, 0/16 JSON files`: **0 errors, 0 warnings**. The editor log gained no lines (cursor 53 before and after; the 53 older lines are the known stale "Identifier not found" autoload errors).
- Input method: every button, tap-anywhere surface and Back was driven with real `game_manage input_mouse` (motion, then press, then release, in window pixels = 2x game pixels) and `input_key Escape`. `game_eval` was used only to read state, to deliver `NOTIFICATION_APPLICATION_*` through `root.propagate_notification`, for one layout probe (294x639 game with fake insets, restored afterwards) and for one DuckyNote instance probe. No button was ever pressed by emitting `pressed` from `game_eval`.

## 1. ROADMAP Step 3 Done-when (the desktop part)

| Criterion | Result | What was observed |
|---|---|---|
| Title > Intro > Background select > Hunt > Interview > Offer > Hired > Title | pass | First run (no settings): tap at game (135,250) -> INTRO; SKIP and `< Back` -> BACKGROUND_SELECT; THE GRADUATE -> JOB_HUNT (Day 1, Energy 8/8, Rent 12, knw 55, save written); Fake invite -> INTERVIEW (seed saved); WIN -> OFFER ($80000/year, 2 office days); ACCEPT -> PHASE2_STUB (Dream vs Reality 64, run_count 1); Esc -> TITLE. Repeated twice more (Intern, Graduate) with `< Title` and NEW RUN. |
| Hunt > Plan B > Retry | pass | Self-Taught -> Rent runs out -> GAME_OVER (save deleted on entry, run_count +1) -> RETRY -> BACKGROUND_SELECT with a fresh RunState (background_id "", day 1) and THE SELF-TAUGHT drawn as PrimaryButton. |
| Quit to title mid-hunt makes Continue appear; Continue resumes the hunt | pass | Day 2, energy 6, knw 65, rent 11 -> `=` -> Quit to title -> TITLE, tree unpaused, `[ New game ]` 254x36 at y 358 above CONTINUE 254x36 at y 400, TapToStart hidden, saved phase JOB_HUNT. CONTINUE -> HUD "Day 2 / Rent due in 11 days / Energy 6/8 / Knowledge 65", `str(rng.state) == run.rng_state`. Also checked mid-interview (Continue restored seed 4099311234) and on the offer (Continue restored the same contract). |
| Continue gone after Plan B and after leaving the Hired card | pass | After Plan B via `< Title` and via Esc: SaveIO.exists() false, ContinueButton hidden, TapToStart shown. After the Hired card via Esc, via `< Title`, and via NEW RUN (lands on BACKGROUND_SELECT, save gone). |
| Every screen has an on-screen Back that does the right thing; desktop Esc does the same | pass | See section 2. |
| Body text is monogram 16 | pass | Label and Button resolve to `res://ui/fonts/monogram/ttf/monogram.ttf` size 16 from the project theme, no overrides; 40 characters = 240x13. HeaderLabel = Press Start 2P 8, amber #feae34. |
| No hit area smaller than 34x34 | pass | See section 3: smallest are `=` (34x36) and Replay intro / Device check (86x34). |
| `test_run` green | pass | 30/30, 6 suites, before and after the fix (`test_run.json`). |
| On the iPhone, one thumb, readable at arm's length | not run | PC only (DECISIONS P2). |

## 2. Back and Esc on every screen

| Screen | On-screen Back (real tap) | Esc |
|---|---|---|
| Title (no save) | none by design (ARCHITECTURE 9: Title has no Back on iOS) | opens "Quit the game?" (paper + `Back` 80x36 + red `Quit` 168x36). A tap on the dimmer at (135,200) did nothing (phase stayed TITLE, dialog open). `Back` closed it. Esc opened it, a second Esc closed it. Quit was not pressed (it would close the game). |
| Device check (overlay on Title) | `< Back` -> counter "back 1" | "back 2"; overlay stays. Close freed it; phase stayed TITLE (the release did not leak to the title's tap-anywhere). Row 2 tap -> "pressed 1 (row 2)"; Haptic 10 -> "haptic 1". PAUSED/RESUMED/FOCUS_OUT counters rose when the notifications were propagated. |
| Intro | `< Back` -> BACKGROUND_SELECT, intro_seen written | via Replay intro, Esc -> BACKGROUND_SELECT; SKIP -> BACKGROUND_SELECT |
| Background select | `< Back` -> TITLE | Esc -> TITLE |
| Hunt | `=` opens the pause sheet (tree paused) | Esc opens it, Esc again resumes. Tap outside the sheet -> resumes. Tap on the sheet padding (135,386) -> stays paused. Resume -> unpaused, and the Sleep button under it did not fire (day unchanged). Quit to title -> TITLE, unpaused. |
| Interview | `< Back` opens pause | Esc resumes. Focus-out -> tree paused + "Ready? Tap to continue." (screenshot). Esc on the Ready overlay -> overlay hidden, pause sheet shown; Esc -> unpaused. Second focus-out, tap at the WIN position -> only unpaused, still INTERVIEW. Quit to title from pause -> TITLE unpaused. Lose -> JOB_HUNT (interviews_taken +1). |
| Offer | `< Back` opens pause; Esc resumes | Decline opens "Decline this offer? Rent keeps ticking."; Esc closes it and keeps the offer (phase OFFER). Decline + red Decline -> JOB_HUNT, co_beigeware blacklisted, offer cleared, same day. Back never declined. |
| Hired | `< Title` -> TITLE, save deleted | Esc -> TITLE, save deleted |
| Plan B | `< Title` -> TITLE | Esc -> TITLE |

Also seen: Fake invite with the day's interview used -> "No interview: it needs 3 energy and today's slot." (stays JOB_HUNT).

## 3. Every Button rect (game px, from `get_ui_elements`)

| Screen | Button: x,y wxh |
|---|---|
| Title, no save | Replay intro 8,442 86x34; Device check 98,442 86x34 (gap 4) |
| Title, with save | New game 8,358 254x36; CONTINUE 8,400 254x36; Replay intro 8,442 86x34; Device check 98,442 86x34 |
| Quit dialog / Decline dialog | Back 8,440 80x36; confirm 94,440 168x36 |
| Device check | 20 rows 246x36, gap 4 (scrollbar 8); Haptic 10 ms 8,400 86x36; Haptic 40 ms 100,400 86x36; Rows STOP 192,400 70x36; `< Back` 8,440 80x36; Close 94,440 168x36 |
| Intro | `< Back` 8,440 80x36; SKIP 94,440 168x36 |
| Background select | Intern 8,314 254x36; Graduate 8,356 254x36; Self-Taught 8,398 254x36; `< Back` 8,440 80x36 |
| Hunt | Fake invite 8,356 254x36; Rent runs out 8,398 254x36; `=` 8,440 34x36; Study 48,440 104x36; Sleep 158,440 104x36 |
| Pause sheet | Quit to title 15,391 240x36; Resume 15,433 240x36 (sheet 8,384 254x92) |
| Interview | Lose 8,398 254x36; `< Back` 8,440 80x36; WIN 94,440 168x36 |
| Offer | `< Back` 8,398 80x36; Decline 8,440 80x36; ACCEPT 94,440 168x36 |
| Hired | `< Title` 8,440 80x36; NEW RUN 94,440 168x36 |
| Plan B | `< Title` 8,440 80x36; RETRY 94,440 168x36 |

Every column is 254 wide at x 8; every tappable control is at y >= 314 (thumb band) and gaps are 4 or 6 px. Probe at a 294x639 game area with fake insets (0,45,0,26) on Background select: the visible rect became 359x639, the column stayed 254 wide at x 52 (centred), the top band started at y 45 and `< Back` ended at y 613 = 639 - 26. Restored to 270x480 afterwards.

## 4. Code audit

- ARCHITECTURE 17 skeletons: `core/game_flow.gd`, `core/run_state.gd`, `core/save_io.gd`, `core/odds.gd`, `data/types/tier_data.gd`, `background_data.gd`, `balance_config.gd`, `autoload/content.gd`, `game_state.gd`, `device.gd`, `scene_router.gd`, `ui/components/safe_area_margin.gd` are byte-identical (CR stripped) to the section 17 code blocks. `features/title/title.gd` replaces the 17.12 Step 1 stub as 17.12 itself says, keeping the size readout.
- INV-02: `change_scene` appears only in `scene_router.gd`. One `load()` in a screen: `title.gd` loads `features/dev/device_check.tscn` by path and adds it as a debug-only overlay child (not a phase, no scene change). See finding F8.
- INV-04: no `randf/randi/randi_range/shuffle/pick_random` outside `Odds` and the tests; `GameState.choose_background` uses `randi()` only to pick the seed (skeleton code, commented).
- INV-14: no `layout_mode = 0`, no `offset_*`/`position`/`size` in any `.tscn` under features/ or ui/; the only anchored nodes are full-rect backgrounds, SafeAreas, dimmers and screen roots. No script sets a Control's position or size. mouse_filter: screen roots IGNORE except Title (STOP, tap-anywhere) and DeviceCheck (STOP, blocks the title); dimmers STOP; DuckyNote and every child IGNORE (probe: 6 nodes, all 2); SceneRouter curtain IGNORE when idle. Only `_gui_input`/`gui_input` handlers read `InputEventMouseButton`; no screen reads touch events.
- INV-16: no `class_name` in `autoload/`.
- INV-12: every test is `@tool`, `extends McpTestSuite`; none references GameState/Content/Device/SceneRouter or `user://` (mentions are comments and strings; test_flow reads `scene_router.gd` as text).
- INV-15: tuning numbers only come from the `.tres` files. Hard-coded text: see finding F5.

## 5. Data, fonts, theme

- `.tres` spot check in the running game against values typed from ARCHITECTURE 6.2 (not from the scripts): 71 fields across all 7 files (startup 10, mid 9, big 12, intern 11, graduate 9, self_taught 14, balance 6), **0 mismatches**. Energy per day 9/8/6. Each `id` equals its file name. GDD 11 agrees with the same fields.
- Font `.import` (all 4 `.ttf`): antialiasing 0, hinting 0, subpixel_positioning 0, generate_mipmaps false, multichannel_signed_distance_field false; the loaded FontFiles report the same values at runtime. monogram 16: 6 px advance, 13 px height; Press Start 2P: 8x8 at 8.
- Theme (ROADMAP Step 3 task 2): `gui/theme/custom` = `res://ui/theme/main_theme.tres`; default font monogram 16; a plain Button, PrimaryButton and DangerButton with "OK" all measure 26x34 minimum (34 = 11 + 13 + 10); type variations PrimaryButton/DangerButton (base Button), PaperPanel (base PanelContainer, #ead4aa), HeaderLabel (base Label, Press Start 2P 8, #feae34).

## 6. Pause behaviour

- `PauseMenu.open()` pauses the tree; Resume, a tap outside the sheet and Back (on-screen and Esc) unpause it; a tap on the sheet's own padding does not.
- Quit to title leaves the tree paused until SceneRouter swaps the scene: after every Quit to title (hunt, interview, offer) the title had `get_tree().paused == false`. No stuck-paused state was found, including after focus-out in the interview.

## 7. Findings

Fixed:
- **F1 (theme vs GDD 2.7).** GDD 2.7 specifies monogram 16 as "a 12 px line ... 40 lines in the 270x480 frame". The theme left Label `line_spacing` at Godot's default 3, so multi-line text stepped 16 px per line (a 4-line label was 61 px tall: only 30 lines fit, and the intro's 4-line caption band, y 360-432 = 72 px, would overflow with panel padding). Fix: `Label/constants/line_spacing = -1` in `ui/theme/main_theme.tres` (set with `theme_manage set_constant`). After: 1 line 13 px, 2 lines 25, the intro's 4 lines 49 (12 px pitch); screenshots of the intro and Plan B text show no touching glyphs. Readability at arm's length still needs the iPhone check (AC-S03-4).
- **F2 (doc vs repo).** ARCHITECTURE 1.4 and the section 2 folder tree said `res://ui/fonts/monogram.ttf`; the file is `res://ui/fonts/monogram/ttf/monogram.ttf` (the developer's unpacked download, used by the theme and the device check). Both lines corrected.

Open (not fixed, for the lead or the developer):
- **F3.** `project.yaml` STEP-02 `outputs` and `.project/bundles/STEP-02.md` (line 84) still name `ui/fonts/monogram.ttf`. ARCHITECTURE 1.4 still calls monogram's cell "unverified"; the desktop measurement (6 px advance, 13 px height) belongs in ARCHITECTURE 18.1 with the Step 2 results.
- **F4 (docs disagree).** GDD S03: "The last background played is preselected, otherwise The Graduate." ARCHITECTURE 11.3: "`preselect_background` picks the card after Retry; otherwise The Graduate." Observed: `preselect_background` is set by `retry()` and never cleared, so Retry -> Title -> New game still preselects the last background (matches the GDD, not 11.3), while a quit-to-title or a fresh launch followed by New game preselects The Graduate (matches 11.3, not the GDD). The fix touches the 17.7 skeleton, so it waits for the real S03 (the developer's You-do layout and Step 6).
- **F5 (INV-15).** Stub text is hard-coded in scenes/scripts although CONTENT.md already has ids for it: ui_tap_to_start, ui_new_game, ui_continue, ui_replay_intro, ui_quit_confirm, ui_decline_confirm, ui_ready, ui_pause_title, ui_pause_resume, ui_back, ui_accept, ui_decline, ui_retry, ui_new_run, ui_title, ui_day, ui_energy, ui_rent_due, ui_rent_due_one, end_plan_b, end_tbc and the S03 header. Debug-only strings ("Knowledge %d", "Interviews today", "Too tired to study...", "No interview...") have no ids. All must move to `Content.text()` when `barks.json` and the endings JSON land (Step 4 starts `test_content_lint`).
- **F6.** `features/dev/.gitkeep` and `ui/fonts/.gitkeep` remain in folders that now hold files (part A removed the others).
- **F7.** `device_check.tscn` still embeds its own Theme sub-resource (monogram 16) from before `main_theme.tres`; redundant, harmless.
- **F8.** The Title loading `device_check.tscn` by path is a literal exception to INV-02's "never load other scenes" (debug-only, not a phase, no scene change); `test_screens_never_change_phase_or_scene` does not look for `load(`. Worth one line in the invariants or ARCHITECTURE 11.1.
- **F9.** No `export_presets.cfg` exists yet, so "features/dev/ is excluded from release exports" depends on the developer adding `features/dev/*` to the release preset (ARCHITECTURE 13.1).

## 8. Screenshots (editor_screenshot source="game", not saved as files)

1. Title, no save: size readout, logo sign (Press Start 2P 24/24/16 on a navy panel), Replay intro, Device check, v0.1.0.
2. Quit dialog: dimmed title, cream paper "Quit the game?", navy Back and red Quit.
3. Device check: PS2P 8 header, readout "Windows ... (debug) / window 540x960 / game 270x480 integer x2.00 / insets 0 / margin L4 T4 R4 B4", rows, haptic row, `< Back` + Close, 1 px red safe-area outline.
4. Intro stub; Background select (Graduate amber); Hunt HUD; pause sheet; Interview; Ready overlay; Offer paper with `< Back` above `[Decline][ACCEPT]`; Decline dialog; Hired card; Plan B card; Title with save (New game above amber CONTINUE).
5. After F1: Intro and Plan B text at 12 px line pitch, readable, no touching glyphs.

## 9. Cleanup

In the second run: `SaveIO.delete()` (no save remained) and `user://settings.cfg` removed, because it did not exist before this session (leaving it would skip the intro and mark the next run as not the first). Checked on disk after the stop: neither file exists. The game is stopped; the editor is on `res://features/title/title.tscn`.

Side effect to check in git: the second `project_run` (autosave on) re-saved two files at 07:31:59 without a request: `features/title/title.tscn` (its content matches the file as read at the start of this session, node for node) and `addons/godot_ai/utils/log_buffer.gd` (an addon file, probably open in the editor's Script tab). This session was not allowed to run git, so run `git diff --stat` before committing and restore either file if it differs.

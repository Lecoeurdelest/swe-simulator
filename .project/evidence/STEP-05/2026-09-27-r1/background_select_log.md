# STEP-05 background select stage: the real S03 screen

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-05-hunt-greybox.
ROADMAP Step 5 task 3, per ARCHITECTURE 11.3, GDD S03 (4.2), 2.7, 2.8, CONTENT 3. Tests: `background_select_test_run.txt`.

## What changed

| File | Change |
|---|---|
| `features/background_select/background_select.tscn` + `.gd` | The real S03 screen, replacing the Step 3 stub: header, one card, the name row (label, LineEdit max 10, dice), the 3-button selector (80x40, 7 px gaps), `[ < Title ][ CHOOSE ]` (80 + 168), and a hidden keyboard spacer. Containers only, inside SafeAreaMargin, 254 px column. |
| `features/background_select/background_card.tscn` + `.gd` (new, `class_name BackgroundCard`) | The card, built from `BackgroundData` + `backgrounds.json`: bust placeholder (60x72 grey), title + difficulty, energy pips with the commute pips greyed, rent runway, one-liner in quotes, 3 stat bars, perk (+) and flaw (-) with a hanging indent, the Self-Taught's gaps line. Also the S03 swipe surface: the root reads `InputEventScreenTouch/Drag`, the inner Panel follows the finger and tilts (max 6 degrees). |
| `features/background_select/dice_button.gd` (new) | The dice button: a drawn 14x14 die face until the art pass gives it an icon. |
| `ui/components/stat_bar.tscn` + `.gd` (new, `class_name StatBar`) | **PLACEHOLDER** for the developer's Step 5 You-do: a Label showing `[###--]`, `value` 0-100 -> `roundi(value * 5 / 100)` of 5 segments. Header comment says the You-do replaces it and which API to keep. |
| `ui/components/pip_bar.gd` (new, `class_name PipBar`) | Energy pips (GDD 2.6: 6x8, 2 px apart): `set_pips(total, filled, locked)`; filled amber, empty outline, locked (greyed) at the right end. Reusable for the hub HUD. |
| `ui/theme/main_theme.tres` | New type variation `SelectorButton` (base Button): Button's styleboxes with 4 px top/bottom content margins so two lines fit 80x40; selected (pressed) = amber 2 px border and amber text. |
| `autoload/game_state.gd` | `new_run_seed()` (never 0); `preview_gap_topics(bg_id, run_seed)`; `_gap_pool()`; `choose_background()` uses `new_run_seed()` when no seed is passed; `_init_run()` comment: the gap roll must stay the run RNG's first draw. |
| `autoload/device.gd` | `keyboard_height()`: the on-screen keyboard in game px (native px / scale, like `safe_insets()`), 0 when the display server has no virtual keyboard. |
| `data/content/barks.json`, `data/content/backgrounds.json`, `docs/CONTENT.md` 3.1 + 10.1 | New ids (below). |

## Content ids added (text from the GDD S03 mockup / ARCHITECTURE 11.3, none newly written)

| id | Text | Where |
|---|---|---|
| `ui_energy_per_day` | Energy/day | card, energy row (GDD S03 mockup "Energy/day oooooooo..") |
| `ui_rent_runway` | Rent runway: {days} days | card (GDD S03 mockup "Rent runway: 12 days") |
| `ui_name` | NAME | name row (GDD S03 mockup "NAME [ Alex ] [dice]") |
| `backgrounds.intern.selector` | INTERN | selector button, above the difficulty (GDD S03 mockup, ARCHITECTURE 11.3) |
| `backgrounds.graduate.selector` | GRADUATE | same |
| `backgrounds.self_taught.selector` | SELF-TAUGHT | same (11 chars = 66 px = the 80 px button's text width) |

Existing ids used: `ui_background_header`, `ui_choose`, `ui_title`, `ui_stat_knw/exp/net`, backgrounds `title`, `difficulty`, `one_liner`, `perk`, `flaw`, `gaps_line`, naming `_topics` (gap labels), names `default` + `pool`.

## Agent defaults, please review (W4)

1. **The Self-Taught's gaps show the real roll, not example topics.** GDD S03 and ARCHITECTURE 11.3 say the card shows "its 2 rolled knowledge gaps". The screen picks the run seed when it opens (`GameState.new_run_seed()`), previews the gap roll with that seed (`preview_gap_topics`) and passes the same seed to `choose_background()`. The gap roll is the run RNG's first draw after seeding, so the card and the run always agree (checked below). This differs from the lead's plan ("template text with 2 example topics"), which was there to avoid a roll that would not match; this one matches by construction. Reopening the screen re-rolls the seed (and so the gaps). To revert: show `gaps_line` with fixed topics and drop the seed argument.
2. **Selector look:** a `SelectorButton` theme variation (above). The theme's Button has 11 + 10 px vertical margins, which only fit one line in 40 px; the mockup puts the name and the difficulty on two lines.
3. **Swipe rules:** left = the next background (to the right in the selector), right = the previous; a drag over a quarter of the base width (67.5 px of 270, read from Project Settings, the job card's number) switches; a shorter drag or a canceled touch settles back in 0.12 s; the ends don't wrap; a 10 ms haptic when the drag crosses the threshold (as the job card, GDD 9.3). The new card slides in 24 px from the side it comes from; selector taps slide it too. No flick: no flick speed is documented anywhere, so only distance counts.
4. **Keyboard while typing (ARCHITECTURE 10.3 #8):** the selector and the action bar (under the keyboard anyway) give way to a spacer as tall as the keyboard, so the name row sits just above it; when the column still doesn't fit (the 270x480 frame with a 40% keyboard), the card steps aside until the keyboard closes. Return/Enter ends typing; an empty name goes back to Alex. Desktop has no virtual keyboard, so this was only exercised by calling the lift with a fake height; the unit (native px assumed) stays ARCHITECTURE 18.1 #12 for the iPhone.
5. **The card sits at the bottom of the Body** (extra height goes above it, like the job card in 11.4), just above the name row.
6. **Dice** never rolls the name already in the field; the UI dice RNG is its own `RandomNumberGenerator`, never the run RNG. The name field selects all on focus, so typing replaces the name.
7. **Header** uses the body font (monogram), not the Press Start 2P `HeaderLabel`: GDD 2.7 keeps the display font for the logo, the VS screen and banners.
8. **Bust:** a plain 60x72 grey placeholder (the 96 px bust cropped to 72); the hoodie colours are not drawn yet.

Not built (not in this task's list): ARCHITECTURE 11.3 "Out: the chosen card flies up and the phone boots DoomApply (0.35 s)". CHOOSE goes through the normal SceneRouter fade.

## You-do queue (W3)

- **Step 5 You-do: build the 5-segment `stat_bar` yourself.** `ui/components/stat_bar.tscn` is a plain text placeholder (`[###--]`) so the screen runs; keep `class_name StatBar` and `value` (0-100) in your version.
- **Step 3 You-do superseded:** "build the Background Select stub layout yourself with Containers" was replaced by this real screen. For the lead to record (the stub it would have built no longer exists; the Container lesson can move to another screen or be read from `background_select.tscn`).

## Verification

Runs: `r74079244-38`, `r74242276-39`, `r74331813-40`, `r74539294-41` (project_run main). Input: real `input_mouse` taps (motion, press, release, window px = 2x game px) and `input_key Escape`. game_eval was used to read state, for the swipes (real `InputEventScreenTouch/Drag` events through `Input.parse_input_event`, see the gotcha below), for typing (key events with unicode), for the fake keyboard height, for the 294x639 probe, and for the cleanup.

| Check | Result | Detail |
|---|---|---|
| test_run all | pass | 184/184, 18 suites (before and after). |
| Real flow | pass | Clean start (no save, no settings.cfg): title tap -> intro -> Esc -> Background select; Graduate preselected (no last background). |
| Card numbers vs data, all 3 | pass | Graduate: 10 pips, 8 filled + 2 greyed (energy_max 10, commute 2), "Rent runway: 12 days", bars [###--] [#----] [#----] (55/15/15), gaps hidden. Intern: 9 + 1 greyed, 15 days, [###--] [##---] [##---] (50/40/45). Self-Taught: 6 + 4 greyed, 12 days, [###--] [#----] [-----] (55/10/5), gaps line shown. Titles "THE X - DIFFICULTY", one-liner in quotes, perk and flaw equal to backgrounds.json. |
| Selector (real taps) | pass | INTERN and SELF-TAUGHT taps switched the card; the tapped button is pressed, the others released (ButtonGroup). |
| Swipe | pass | Run 40 (clean build): +120 px self_taught -> graduate -> intern, +120 at intern stays (no wrap), -40 stays (under 67.5), -100 intern -> graduate. Panel followed the finger 1:1 in game px, tilt capped at 6 degrees (-60 px drag: -5.33 degrees), rest position 0/0 after every release. One step per swipe: the touch-to-mouse emulation never double-fired. Run 38 gave the same results (+100, -100, -40, -100 at the end, +120). |
| Real mouse drag | as expected | `input_mouse` motion carries no button mask, so no drag reached the card (known gotcha: drags need game_eval); it acted as a tap on the card, which does nothing. |
| Dice (real taps) | pass | Alex -> Charlie -> Quinn; 30 more rolls: all in the 20-name pool, never the same name twice in a row. |
| Typing | pass | Real tap on the field starts editing (all selected); 13 typed chars -> "Bartholome" (max_length 10); Enter ends editing and stops `_process`; clearing the field + Enter restores "Alex". |
| Keyboard lift (fake height) | pass | 270x480, 192 px keyboard: card steps aside, name row bottom 282 < keyboard top 288, header stays at y 4. 120 px: card stays, name row bottom 354 < 360. 294x639 with insets, 250 px: card stays (top 92), name row bottom 383 < 389. Restored: selector, action bar and card visible, CHOOSE back at (94, 440). |
| CHOOSE (real taps) | pass | SELF-TAUGHT + one dice roll ("Rowan"), card showed "Gaps: Web and HTTP, Databases", seed 424714276. After CHOOSE: JOB_HUNT scene, `run.background_id` self_taught, `player_name` Rowan, `gap_topics` [web, databases] (= the card), `rng_seed` "424714276" (= the screen's seed), stats knw 55 / exp 10 / net 5, energy 6, rent 12, referral 0, 6 cards on day 1, save written, settings last_background = self_taught. |
| Back to the title | pass | Hunt Pause > Quit to title, then New game: Self-Taught preselected, name Alex. Real tap on `< Title`: TITLE, the save survives for Continue. |
| Layout 270x480 | pass | Column 254 at x 8, y 4-476. Header y 4. Card 254 wide, 240 tall (253 with the gaps line) at the bottom of the Body. Thumb band from y 354: name row 34 (field 184, dice 34x34), selector 3 x 80x40 at x 8/95/182, action bar 80 + 168 at y 440 (CHOOSE x 94-262). Every tappable control >= 34 px and in the thumb band; gaps 6-7 px. Screenshot checked. |
| Layout 294x639 + insets (0,45,0,26) | pass | Visible rect 294x639; column 254 centred at x 20, header at y 45, `< Title` / CHOOSE end at y 613 = 639 - 26; extra height above the card. Screenshot checked; restored to EXPAND 270x480 and zero insets. |
| Game log | pass | Runs 40 and 41: 0 errors, 0 warnings. Run 38 had one warning per frame while typing ("Virtual keyboard not supported by this display server", from `keyboard_height()`); fixed by checking `DisplayServer.FEATURE_VIRTUAL_KEYBOARD` first, and run 41 repeated the typing path clean. Run 39's log was not read before it ended. Editor: only the known "Identifier not found: Content/GameState" autoload errors. |
| Files on disk after the runs | pass | game_state.gd, device.gd, background_select.gd, background_card.gd and main_theme.tres still hold the new code after the editor's save-on-run (stale-buffer gotcha). |
| Cleanup | pass | `SaveIO.delete()` and user://settings.cfg removed (twice: runs 40 and 41); user:// holds only godot_ai_server.pid. Project stopped. |

## Doc follow-ups for the Doc sync stage (not edited here)

- ARCHITECTURE 6.3: `backgrounds.json` field list gains `"selector"`.
- ARCHITECTURE 10.2: type variations gain `SelectorButton`.
- ARCHITECTURE 17.7: GameState gains `new_run_seed()`, `preview_gap_topics()`, `_gap_pool()`; 17.8: Device gains `keyboard_height()`.
- ARCHITECTURE 11.3: the card previews the gap roll with the run's seed (default 1 above), and the keyboard behaviour (default 4).
- ROADMAP Step 3 You-do: superseded by the real S03 (see the queue above).

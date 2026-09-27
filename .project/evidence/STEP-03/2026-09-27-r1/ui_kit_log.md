# STEP-03 part A: UI kit and data (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam) with the godot-ai MCP. The game ran embedded in the editor's Game tab: window 540x960, game 270x480, integer x2. Screenshots came from `editor_screenshot source="game"` (the 270x480 framebuffer). They can't be saved as files, so this log describes them. Raw numbers are in `runtime_checks.json` and `test_run.json`.

## 1. Theme: `ui/theme/main_theme.tres`

Built with `theme_manage` (`create`, then one `batch_execute` of 35 `theme_set_*` commands). `theme_manage` has no op for `Theme.default_font`, `default_font_size` or `set_type_variation()`. Those three were set by a throwaway `@tool McpTestSuite` (`tests/test_zz_theme_setup.gd`), run once with `test_run suite="theme_setup"` and then deleted (the same workaround AGENTS.md gives for typed project settings). After that, `project_manage settings_set gui/theme/custom = "res://ui/theme/main_theme.tres"` (a String; `project.godot` [gui] now has `theme/custom=...`).

| Item | Value |
|---|---|
| Default font | monogram 16 (`res://ui/fonts/monogram/ttf/monogram.ttf`) |
| Button (all states) | StyleBoxFlat, 1 px border, square corners, antialiasing off. Content margins L7 R7 T11 B10: the 13 px monogram line + 21 = **34 px minimum height**; a 254 px button leaves 240 px = 40 columns of text |
| Button colors | normal/hover `#3a4466` border `#5a6988`; pressed/hover_pressed `#262b44` border `#8b9bb4`; disabled `#262b44` border `#3a4466`, text `#8b9bb4`; focus = transparent fill + 1 px `#fee761` border; text `#ffffff` |
| PrimaryButton (base Button) | fill `#feae34` border `#f77622`; pressed `#f77622` border `#733e39`; disabled like Button; text `#181425` in every state |
| DangerButton (base Button) | fill `#a22633` border `#e43b44`; pressed `#3e2731` border `#a22633`; disabled like Button; text white (from Button) |
| PanelContainer / Panel | `#262b44`, 1 px `#3a4466` border, content margins 7 (254 outside = 240 of text, GDD 2.6/2.7) |
| PaperPanel (base PanelContainer) | cream `#ead4aa`, 2 px `#c28569` border, content margins 7 |
| Label | font color `#ffffff` |
| HeaderLabel (base Label) | Press Start 2P 8, `#feae34` |

The colors come from Endesga 32 (GDD 2.5's suggested palette), on the near-black `Color(0.07, 0.07, 0.1)` clear color.

**Contrast (WCAG ratios, all at least 4.5:1):**

| Pair | Ratio |
|---|---|
| Button text | 9.6 |
| Disabled text | 4.9 |
| Primary text | 9.7 (pressed 6.5) |
| Danger text | 7.3 |
| Label on panel | 13.9 |
| Label on the background | 18.6 |
| Ink `#262b44` on paper | 9.6 |
| HeaderLabel on panel | 7.5 |

**Colorblind safety (GDD 2.7):**
- Primary and Danger differ strongly in lightness (fill luminance 0.52 vs 0.09), not only in hue.
- Every button says what it does, so color is never the only signal.

**Measured in the running game:**
- A plain Button, PrimaryButton and DangerButton with "Quit to title" all have a minimum size of 92x34.
- A 40-character monogram line is 240x13.
- HeaderLabel "PAUSED" is 48x8 in Press Start 2P.
- `ThemeDB.get_project_theme()` is the file, and its type variations are {Button: Danger/Primary, PanelContainer: PaperPanel, Label: HeaderLabel}.

## 2. Data: the 7 `.tres` files

Created with `resource_manage create`, `type` = TierData / BackgroundData / BalanceConfig, with the ARCHITECTURE 6.2 values (cross-checked against GDD 11: the two agree everywhere).
- `data/tiers/{startup,mid,big}.tres`
- `data/backgrounds/{intern,graduate,self_taught}.tres`
- `data/balance/balance_config.tres`

Godot writes only the values that differ from the script defaults:
- `mid.tres` and `graduate.tres` hold just their `id`, because the script defaults are the Mid and Graduate values.
- `balance_config.tres` holds only its three packed arrays (Godot always writes those), because the script defaults are the GDD defaults.

The `id` of every file equals its file name (`&"startup"` ... `&"self_taught"`). The `.gitkeep` files in `data/tiers/`, `data/backgrounds/`, `data/balance/` and `ui/theme/` were removed.

`tests/test_data_files.gd` (suite `data_files`, `@tool`, extends McpTestSuite, loads `res://` `.tres` files only, never touches autoloads or `user://`):
- Its expected values are typed from the GDD 11 tables, not copied from the scripts.
- It checks each field's type and value in all 7 files.
- It fails when a Resource class gets a field the test doesn't list.
- It checks that each folder holds exactly the 3 expected files, that each `id` equals its file name, and the derived values (energy 9/8/6, only Self-Taught starts as a lone wolf).
- Its header says a `.tres` change means updating GDD 11 and this test in the same commit.

The game log on boot reads exactly: `Content: 3 backgrounds, 3 tiers, 0/16 JSON files`.

## 3. Components in `ui/components/`

- **`confirm_dialog.tscn` + `.gd`** (`class_name ConfirmDialog`)
  - Structure: root Control (full rect, IGNORE) > `Dimmer` ColorRect (full rect, `Color(0.07,0.07,0.1,0.8)`, STOP) > `SafeArea` (SafeAreaMargin, IGNORE) > `Column` (VBox, 254, SHRINK_CENTER, separation 6, alignment END, IGNORE).
  - In the Column: `Paper` (PaperPanel, STOP) holds `%Message` (ink color, centred, word-smart autowrap). Below it is `ActionBar` (HBox 36 tall, separation 6): `%CancelButton` "Back" (80x36) and `%ConfirmButton` "OK" (168x36, PrimaryButton).
  - API: `open(message, confirm_text="", cancel_text="", danger=false)`. An empty text restores the scene default; `danger` switches the confirm button to DangerButton. Also `is_open()`, `handle_back()` (cancel when open), and signals `confirmed` / `cancelled`.
  - It hides itself in `_ready()` and after an answer. It answers only once per `open()`.
- **`pause_menu.tscn` + `.gd`** (`class_name PauseMenu`)
  - Structure: root Control (full rect, `process_mode = ALWAYS`, IGNORE) > `%Dimmer` (STOP; a tap outside the sheet = Resume, acting on release) > `SafeArea` > `Column` (254, alignment END) > `Sheet` (PanelContainer, STOP) > `Buttons` (VBox, separation 6).
  - Buttons: `%QuitButton` "Quit to title" on top (plain Button, 36 tall) and `%ResumeButton` "Resume" at the bottom (PrimaryButton, 36 tall).
  - API: `open()` pauses the tree; `resume()` / Resume / outside tap / `handle_back()` unpause and emit `resumed`; `is_open()`.
  - Quit emits `quit_to_title_pressed`, disables itself so a second press can't ask for an illegal TITLE -> TITLE change, and leaves the tree paused: SceneRouter unpauses when it swaps the scene (ARCHITECTURE 17.9).
- **`ducky_note.tscn` + `.gd`** (`class_name DuckyNote`)
  - Structure: a PanelContainer (PaperPanel, `custom_minimum_size.x = 254`, IGNORE). Inside: a header row (a 16x16 amber ColorRect placeholder for the duck, plus "Ducky" in ink), then `%Tip` (ink, autowrap, 240 px wide = 40 columns).
  - Every node is mouse_filter IGNORE (GDD 4.3/8.1: Ducky notes never block input).
  - `@export_multiline var tip_text` has a setter that updates the label, before or after `_ready()`.

All three follow ARCHITECTURE 10.1: containers only, no absolute positions, every tappable control inside a SafeAreaMargin and 36 px tall, action bar 80 + 6 + 168 = 254. The scene files were written, then opened and saved in the editor (it added the scene uid and node `unique_id`s, and dropped `mouse_filter = 0` on the PanelContainers because STOP is already their default in 4.7.2). No `.gd` file's mtime changed during those saves (checked before and after, because of the Step 2 stale-buffer issue).

## 4. Click-through (desktop, embedded window)

The components were instantiated at runtime by `game_eval`, never saved:
- a scratch `CanvasLayer` "ScratchModal" (layer 10, standing in for a screen's ModalLayer) under `/root`;
- a scratch "ScratchLog" node, whose script counts signals;
- a scratch "Behind (scratch)" Button at game (8,60) 254x36 inside the Title, to prove what blocks taps and what doesn't.

Input: `game_manage input_mouse` in window pixels (game x2), a motion event before each press and release (Step 2 finding).

| # | Action | Observed |
|---|---|---|
| 1 | Boot | Title as in Step 1/2 ("SWE Simulator 0.1.0 / window (540, 960) / game (270, 480) (integer) / save file: false"), now in monogram 16 from the project theme. The "Device check" button (8,440 96x36) has the theme's flat slate style |
| 2 | Show a DuckyNote at (8,50) with a 100-character tip | Screenshot: a cream paper note, 2 px tan border, amber square + "Ducky", then 3 wrapped lines of dark ink ("Compare total pay: salary, bonus, / equity, benefits and commute. 3 hours a / day on a bus is a pay cut."). Rect 254x77, tip 240x45 |
| 3 | Tap window (270,156) = the Behind button under the note | `behind_pressed`: the note lets taps through |
| 4 | `open("Decline this offer? Rent keeps ticking.", "Decline", "", true)` | Screenshot: the screen is dimmed; above the bottom edge sit a one-line cream paper message and the action bar `[ Back ][ Decline ]`, Back slate 80x36 at x 8, Decline red 168x36 at x 94-262, bottom at y 476 |
| 5 | Tap (270,156) over the dimmer | Nothing reaches the Behind button; the dialog stays open |
| 6 | Tap the paper (270,840) | No answer; still open |
| 7 | Tap Decline (356,916) | `confirmed`; the dialog hides |
| 8 | `open("You still have 3 energy. Sleep anyway?", "Sleep")` | Screenshot: the same layout with an amber "Sleep" primary (dark text); cancel text back to "Back", variation PrimaryButton |
| 9 | Tap Back (96,916) | `cancelled`; hidden |
| 10 | `handle_back()` closed, then open + `handle_back()` | false; then true + `cancelled` + hidden |
| 11 | `PauseMenu.open()` | `tree.paused = true`; the pause menu can process, the title can't. Screenshot: dimmed title, a slate bottom sheet 254x92 glued to the bottom safe edge, "Quit to title" (slate, 240x36) above "Resume" (amber, 240x36), 6 px apart |
| 12 | Tap the sheet padding (22,774) | Still open, still paused, no signal |
| 13 | Tap Resume (270,902) | `resumed`; hidden; unpaused |
| 14 | Open, tap outside on the dimmer (270,156) | `resumed`; unpaused; the Behind button under the dimmer was not pressed |
| 15 | Open, tap Quit to title (270,818) | `quit_to_title_pressed`; the Quit button is disabled (greyed text in the screenshot); the sheet stays up and the tree stays paused. Quit has focus, but no yellow focus border is drawn (mouse/touch focus stays hidden) |
| 16 | `handle_back()` open, then closed | true + `resumed` + unpaused; then false. Reopening re-enables Quit |
| 17 | Notch preview: `debug_fake_insets = (0,45,0,26)` on both SafeAreas | The pause sheet moves to y 362-454 and the dialog's action bar to y 418-454: both honor the bottom inset |
| 18 | Clean relaunch, tap Device check, then Close | The Step 2 overlay opens and lays out as before (its buttons now use the theme), and Close returns to the title |

Game log for every run: the helper line plus `Content: 3 backgrounds, 3 tiers, 0/16 JSON files`, with **0 errors and 0 warnings**. The editor log since the session start shows only the known stale `Identifier not found: Device` (device_check.gd) autoload error (AGENTS.md gotcha).

`test_run` (all suites): **28/28** (the 24 existing + 4 in `data_files`).

## 5. Defaults taken without the developer (W4; please review)

- **Hover looks like normal** on every button. With touch-emulated mouse the pointer stays where the finger lifted, so a hover style would stay lit after a tap on the iPhone. Pressed is the tap feedback.
- **HeaderLabel = Press Start 2P 8 in amber.** GDD 2.7 says monogram is for "everything except titles", so screen headers count as titles. Alternative: monogram 16 in amber.
- **PaperPanel is cream paper with dark ink.** A theme can't recolor the Labels inside a panel, so labels on paper carry a `font_color` override (`#262b44`), as the three components do. Alternative: a fifth type variation, e.g. `InkLabel`.
- **The confirm dialog uses the action-bar pattern** `[ Back 80 ][ PRIMARY 168 ]` at the bottom, with the message on paper just above it. The dimmer only blocks: a tap outside does not cancel (the pause sheet's tap-outside = Resume is specific to Pause in GDD S13).
- **The Ducky note is PaperPanel** with a 16x16 amber square as the duck placeholder.
- **Button heights of 36 per scene:** answer and action-bar buttons get their 36 px from `custom_minimum_size` in the scene (the task allowed either). No fifth type variation was added.

## 6. Tool notes

- A `game_eval` with a parse error (`Engine.get_main_loop().root` can't be type-inferred) parks the game in a debugger break: `editor_state` shows `status = break`, and later evals return `EVAL_GAME_NOT_READY`. Fix: `project_manage stop`, relaunch, and cast with `(Engine.get_main_loop() as SceneTree).root`.
- `game_manage input_sequence` only takes InputMap actions (`steps` with `action` / `at_frame`); mouse taps need individual `input_mouse` calls.
- A `const Dictionary` can't hold `PackedFloat32Array(...)`: it isn't a constant expression. The balance table in the test is a `var` for that reason.

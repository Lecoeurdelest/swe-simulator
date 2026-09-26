# STEP-02 PC part: device check and font import (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam), godot-ai MCP. The game ran embedded in the editor's Game tab: window 540x960, game 270x480, integer x2. Screenshots came from `editor_screenshot source="game"` (the 270x480 framebuffer); they can't be saved as files, so this log describes them.

## 1. Font import settings (ARCHITECTURE 1.4)

- Edited the four `.import` files (`ui/fonts/PressStart2P-Regular.ttf`, `ui/fonts/monogram/ttf/monogram.ttf`, `monogram-extended.ttf`, `monogram-extended-italic.ttf`): `antialiasing=0` (None), `hinting=0` (None), `subpixel_positioning=0` (Disabled). `generate_mipmaps=false` and `multichannel_signed_distance_field=false` were already set. Then `filesystem_manage reimport` on all four: the `.fontdata` files were regenerated at 05:32, and the `.import` files kept the values (`import_settings.txt`).
- The running game loads every FontFile with antialiasing 0, hinting 0, subpixel_positioning 0, no mipmaps and no MSDF (`font_metrics.json`).
- `ui/fonts/monogram/pico-8/`: added an empty `.gdignore`, and deleted the generated `monogram.p8.png.import` sidecar Godot had created there (untracked). Why: the game never uses the PICO-8 cartridge or its PNG, and ignoring the folder keeps an unused texture out of the export pack. `credits.txt` and the `.p8` files stay on disk untouched.
- Measured metrics: monogram 16 has a 6 px advance (40 characters = 240 px exactly) and a **13 px** font height (ascent 11 + descent 2), not the 12 px line GDD 2.7 assumes. Press Start 2P is an exact 8 px grid.

## 2. What was built

- `features/dev/device_check.tscn` + `.gd` (debug only). The layout follows the ARCHITECTURE 10.1 skeleton:
  - Backdrop (solid ColorRect) and SafeArea (SafeAreaMargin), with a 1 px `SafeOutline` Panel. Its StyleBoxFlat has a 1 px border, antialiasing off and `expand_margin` 1, so the line sits on the last unsafe pixel and the content starts right inside it.
  - Column (254 px, centred):
    - a Press Start 2P 8 header;
    - the readout (OS and model, window, game size + stretch + scale, `Device.safe_insets()`, the SafeAreaMargin's applied margins, the raw `DisplayServer.get_display_safe_area()`, haptics on/off and the list's `scroll_deadzone`);
    - a monogram 16 line that is exactly 40 characters;
    - a Press Start 2P 16 line;
    - the counters (pressed / last row / scrolled / scroll y; back / haptic; paused / resumed / focus_out);
    - a ScrollContainer with 20 buttons 36 px tall;
    - the thumb band: Haptic 10 ms / Haptic 40 ms / Rows STOP-PASS, then `< Back` (80) + `Close` (168).
  - A local Theme on the root makes monogram 16 the default font inside the overlay.
- `features/title/`: a SafeArea > Column > `DeviceCheckButton` ("Device check", 96x36, bottom-left, monogram 16). It is shown only when `OS.is_debug_build()` and the scene file exists. It instantiates the overlay as a child of the title (loaded by path, never preloaded, because `features/dev/` is excluded from release exports). While the overlay is open, `title.handle_back()` forwards Back to it; Close frees it. The Step 1 readout lines are unchanged.

## 3. Click-through (desktop)

Input method: `game_manage input_mouse`. Its coordinates are **window pixels** (game px x2 here); game-pixel coordinates hit nothing, which answers ARCHITECTURE 18.1 #13 for the embedded window. A button press only registers when a `motion` event to the same point comes first: without it the Button isn't hovered, and `BaseButton` ignores the press.

| # | Action | How | Observed |
|---|---|---|---|
| 1 | Title after launch | screenshot | Step 1 readout: "SWE Simulator 0.1.0 / window (540, 960) / game (270, 480) (integer) / save file: false". A dark "Device check" button at the bottom-left (rect 8,440 96x36) |
| 2 | Tap "Device check" | input_mouse motion + press + release at window (112,916) | Overlay opens: full screen, dark backdrop, red 1 px outline 1 px outside the 4 px margin |
| 3 | Read the readout | game_eval of `%Readout` | "Windows B650M AORUS ELITE AX ICE (debug) / window 540x960 / game 270x480 integer x2.00 / insets L0.0 T0.0 R0.0 B0.0 / margin L4 T4 R4 B4 / safe px 0,154 1920x1080 / haptics on  deadzone 6" |
| 4 | Font lines | screenshot | "DEVICE CHECK (PRESS START 2P 8)" fits in 248 px; "monogram 16: forty columns = 240 px wide" fills the column exactly; "PS2P 16 OK!" in large block letters. No grey antialiasing pixels at 1x |
| 5 | Tap Row 02, then Row 04 | input_mouse at (262,546), (262,706) | Counters "pressed 2 (row 4)"; Row 04 shows the hover style |
| 6 | Drag the list (STOP rows) | game_eval, real drag events (see `drag_tests.json`) | No scroll, nothing pressed |
| 7 | Drag with PASS rows | game_eval, runtime toggle | Scrolls 1:1, then inertia to y 215; nothing pressed; a plain tap still presses |
| 8 | Tap Haptic 10 ms, Haptic 40 ms | input_mouse at (140,836), (400,836) | "haptic 2" (`Device.haptic()` is a no-op on desktop, as expected) |
| 9 | Tap `< Back` | input_mouse at (96,916) | "back 1": the button calls `Device.handle_back()`, which asks the title, which forwards to `device_check.handle_back()` (returns true, counts) |
| 10 | Press Esc | input_key Escape press/release | "back 2": the same Device chain (`ui_cancel` in `Device._unhandled_input`); the overlay stays open |
| 11 | Lifecycle counters | game_eval `root.propagate_notification()` with APPLICATION_PAUSED, RESUMED, FOCUS_OUT (what SceneTree does with OS events) | "paused 1  resumed 1  focus_out 1"; tree not paused, no save written (TITLE phase) |
| 12 | Tap Close | input_mouse at (356,916) | Overlay freed; the title is back (screenshot matches #1) |
| 13 | Esc with the overlay closed | game_eval key event | `Device.back_unhandled` emitted (the title returns false, as in Step 1) |
| 14 | Reopen | game_eval `DeviceCheckButton.pressed.emit()` | The overlay opens again (the title's reference was cleared on Close) |
| 15 | Rows toggle | input_mouse at (443,836), twice | "Rows PASS" (rows' mouse_filter 1), and the same drag now scrolls (scrolled 1, y 215, pressed 0); second tap shows "Rows STOP" (mouse_filter 0) |
| 16 | Notch preview | game_eval: `debug_fake_insets = (0,45,0,26)` on the overlay's SafeAreaMargin (runtime only) | Readout "margin L4 T45 R4 B26"; outline at y 44 / 454; the whole column still fits at 270x480 (list 118 px tall, 3 rows visible) |

Final game log: 0 errors, 0 warnings (`game_log.json`). `test_run`: 24/24 (`test_run.json`).

## 4. Findings for ARCHITECTURE 18.1 (desktop evidence; the iPhone still decides)

- **#1 / 10.3 #7 (drag and release):** with default STOP buttons, a drag that starts on a row does not scroll the list at all, so a list made of buttons can't be drag-scrolled on touch. With PASS rows it scrolls, never fires the row (even a short drag that releases over the same row), and taps still fire. The 10.3 #7 fallback of ignoring releases after the deadzone looks unnecessary: the ScrollContainer already cancels the press.
- **#2 (deadzone unit):** the drag followed the pointer 1:1 in game px (16 window px = 8 game px of scroll). The iPhone still has to tell whether 6 feels right.
- **#6 (fonts):** monogram 16 is 6 px advance / 13 px height; Press Start 2P 8 px grid. Crispness at 4x needs the phone.
- **#13 (input_mouse space):** window pixels, not game pixels, and a motion event must precede the press.
- **ScrollContainer and the project deadzone:** saving any scene with a ScrollContainer bakes the current `gui/common/default_scroll_deadzone` into it (`scroll_deadzone = 6` appeared in the .tscn). Changing the project setting later won't reach saved scenes. The device check re-reads the setting in `_ready()`.

## 5. Tool issues seen during the session

- The editor's script editor had `features/title/title.gd` open with the Step 1 text. Saving `device_check.tscn` (`scene_save`) wrote that stale buffer back over the new `title.gd`, and the first click-through ran the old title. Fixed by rewriting the file, then syncing the stale buffer to the disk content with a throwaway `@tool McpTestSuite` (deleted afterwards). Later saves and runs kept the file (timestamps checked).
- One `filesystem_manage scan` hung for 30 minutes, until the MCP timeout. The editor was responsive afterwards; the next scans took seconds.
- In one run the game's main loop stopped advancing ("window backgrounded"); a relaunch fixed it.

## 6. Still to do on the iPhone (developer)

AC-S02-8 to AC-S02-19 are all device or written checks. The device check is ready for them: portrait, the game size row, the island/home-indicator outline, fonts at 4x, thumb reach, drag vs tap (try both "Rows STOP" and "Rows PASS"), 10/40 ms haptics, home/reopen and Control Center counters, the two-swipe home gesture, the Back counter, and where logs appear.

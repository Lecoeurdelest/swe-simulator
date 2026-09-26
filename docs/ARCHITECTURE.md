# SWE Simulator: Technical Architecture (MVP)

| | |
|---|---|
| Version | 1.1, 2026-09-26 (portrait, iPhone first: `docs/DECISIONS.md` D1, D2, P1) |
| Engine | Godot 4.7.2-stable on both machines (Steam build on the Windows PC, the godotengine.org zip on the MacBook), GDScript, `gl_compatibility` renderer |
| Readers | You (the developer) and every future Claude session that implements the game |
| Design source of truth | `docs/GDD.md` (rules and numbers) and `docs/CONTENT.md` (every string and id) |
| Companion | `docs/ROADMAP.md` (the step-by-step plan) |

**How to read this doc.**
- Sections 1-10 are the rules of the codebase.
- Section 11 explains how to build each feature.
- Sections 12-16 cover testing, export, git, performance and the godot-ai workflow.
- Section 17 has the code skeletons. Copy them verbatim.
- Section 18 lists what is still unverified, plus the pitfalls.

If this doc and the GDD disagree on a rule or a number, the GDD wins; fix this doc. If they disagree on an engine fact, this doc wins; fix the GDD.

**Verification tags**
- **(verified 4.7.2)**: checked in this editor on 2026-09-26, using `settings_get`, ClassDB or the 4.7.2 engine source.
- **(verified: scratch run)**: the section-17 code was compiled and run headless on Godot 4.7.2.stable.steam in a throwaway project outside the repo, with the common GDScript warnings turned into errors.
  - 24 unit tests passed.
  - 42 runtime checks passed: the scale guard at 8 screen sizes; the save rules for new game, Continue, Retry, Plan B and Hired; the interview checkpoint; the focus pause; the Answer Meter idle fix; and SafeAreaMargin.
  - Those guard sizes were landscape. The portrait guard is the same math with the axes swapped, and was checked live in this project on 2026-09-26: the title stub reads `window (540, 960)` / `game (270, 480) (integer)`, and `test_run` passes 24/24.
- **(verified: addon source)**: read in `res://addons/godot_ai` (v4.2.3).
- **(unverified)**: test it on a device before you rely on it. The full list is in section 18.

---

## 0. The decisions in one list

1. **270x480 base resolution** (portrait), with stretch mode `viewport`, aspect `expand` and scale mode `integer`. A runtime **scale guard** in `Device` grows the game area so it fills the screen with square pixels. On iPhone SE- and 720p-class screens it falls back to fractional scaling.
2. **Portrait only** (`orientation = 1`, no upside-down), played with one thumb. Touch goes through ordinary Control nodes. Only the job-card and background-card swipes read raw touch events.
3. **Fonts:** **monogram at 16** for all body text. **Press Start 2P** only for the title logo, the VS screen and big banners. Its OFL license ships in the credits.
4. **Folders are organized by feature** (`features/<screen>/`), plus `core/` (pure logic), `data/` (numbers and text) and `ui/` (theme, fonts, shared components).
5. **Four autoloads:** `Content`, `GameState`, `Device`, `SceneRouter`.
   - There is no event bus, and Audio is LATER.
   - There are four pure `@tool` classes: `GameFlow`, `RunState`, `SaveIO`, `Odds`.
6. **Where data lives:**
   - Numbers you tune are in **7 `.tres` files**: 1 BalanceConfig, 3 BackgroundData, 3 TierData. All odds live in TierData.
   - All text is in **16 JSON files keyed by id**. Companies are JSON only; there is no company `.tres`.
7. **Randomness:** there is one seeded RNG per run. Each interview gets its own RNG, seeded from a checkpoint, so a resume replays the same interview. 64-bit seeds and states are saved as **strings**.
8. **One JSON save** in `user://`.
   - It is written only while a run is live (hunt, interview, offer).
   - It is written after every committed action, and whenever the app loses focus.
9. **Rules live in pure code** that the editor-side tests can run (autoloads don't exist there). Scenes only display state and call `GameState` verbs.
10. **iPhone first.** You develop on the Windows PC and build for the iPhone on the MacBook (Xcode, free Personal Team signing). Git keeps the two machines in sync. Android is LATER; JDK 17 is already on the PC.

---

## 1. Display and pixel art

### 1.1 Base resolution and the scale guard

**Why 270x480** (D2, the portrait mirror of 480x270): the reference art is about 400-500 px wide at its native resolution, so one art pixel = 4 screen pixels on 1080-class phones matches its density. A 360x640 base would need about 1.8x more art for the same look. A 12 px text line at 4x is physically the same size as a 16 px line at 3x, so you lose no text capacity (about 40 characters x 40 lines, GDD 2.7).

**Why `viewport` and not `canvas_items`:**
- `viewport` renders at 270x480 and then scales up, so every pixel is the same size and pixel fonts stay crisp.
- Only about 130-240k pixels are shaded per frame, which saves battery.
- The 4.7 docs recommend `viewport` + integer for pixel art (verified 4.7.2).

**Why the guard exists:** on its own, integer + expand **letterboxes**. For example, a 1179x2556 screen shows 270x585 with 50/108 px black bars (verified 4.7.2 source, `Window::_update_viewport_size`).

The guard (section 17.8) reads the base size from Project Settings, so the two never disagree. It picks the integer scale `s = floor(min(W/270, H/480))`, then sets `content_scale_size = floor(window / s)`, so the game area grows to use the leftover space. If integer scaling would use less than 80% of the exact scale, it switches to fractional instead.

The math is the scratch-run-verified landscape guard with the axes swapped. The 540x960 row was checked live on 2026-09-26; the other rows are computed, and Step 2 confirms your iPhone's row on the device:

| Screen (portrait px) | Mode | Visible game area |
|---|---|---|
| 540x960 (the desktop test window) | 2x integer | 270x480 |
| 750x1334 (iPhone SE 2/3) | 2.78x fractional | 270x480 |
| 828x1792 (iPhone 11) | 3x integer | 276x597 |
| 1170x2532 (iPhone 12-14) | 4x integer | 292x633 |
| 1179x2556 (iPhone 14 Pro-16) | 4x integer | 294x639 |
| 1206x2622 (iPhone 16 Pro) | 4x integer | 301x655 |
| 1290x2796 / 1320x2868 (Pro Max) | 4x integer | 322x699 / 330x717 |
| 1640x2360 (iPad, LATER) | 4x integer | 410x590 |
| 1080x2400 (Android 20:9, LATER) | 4x integer | 270x600 |
| 720x1600 (budget Android, LATER) | 2.67x fractional | 270x600 |

**Rules that follow:**
- **All critical content fits the central 270x480.** Extra width shows more background, never more UI: the UI column stays 254 px wide and centred. Extra height goes to the middle zone (GDD 2.8): the stage or card area grows, and backgrounds show more sky.
- Backgrounds are built from layers that tile sideways and are anchored to the screen bottom (sky, far, mid, near, ground; GDD 2.5). Never stretch pixel art.
- Test every screen at 270x480, 294x639 and 330x717. On desktop, resize the running window to **540x960, 588x1278 and 660x1434** (2x), or to 294x639 and 330x717 (1x) when the monitor is too short. Each gives exactly that area.
  - Dragging the window edge always works. `editor_manage game_eval` with `Engine.get_main_loop().root.size = Vector2i(588, 1278)` is ignored by the window embedded in the editor's Game tab (seen in Step 1); in a floating game window it is unverified.
- On desktop, `size_changed` doesn't always fire when you resize, so `Device` compares the window size every frame. Phones are fine, because their window size is fixed at launch.

### 1.2 Project settings (applied in Step 1, 2026-09-26)

All of these keys exist in 4.7.2 (verified 4.7.2 with `settings_get`; a made-up key returns `Setting not found`). The "Applied" column is exactly what `project.godot` holds now.
- They were applied with `project_manage op=settings_set`, **one key per call**.
- The main scene is the one exception: `settings_set` refuses it, so use `project_manage set_main_scene`.
- **`settings_set` does no type coercion:** a Color passed as a string or a dictionary is saved with the wrong type. Set typed values from a throwaway `@tool extends McpTestSuite` file that calls `ProjectSettings.set_setting()` and `ProjectSettings.save()`, run it with `test_run`, then delete it.

| Key | Default | Applied | Why |
|---|---|---|---|
| `display/window/size/viewport_width` | 1152 | **270** | base resolution (D2) |
| `display/window/size/viewport_height` | 648 | **480** | |
| `display/window/size/window_width_override` | 0 | **540** | desktop test window, 270x480 at 2x. Whether iOS ignores it is unverified |
| `display/window/size/window_height_override` | 0 | **960** | |
| `display/window/stretch/mode` | "disabled" | **"viewport"** | renders at low resolution |
| `display/window/stretch/aspect` | "keep" | **"expand"** | the guard does the rest |
| `display/window/stretch/scale_mode` | "fractional" | **"integer"** | the guard switches to fractional on SE- and 720p-class screens |
| `display/window/handheld/orientation` | 0 | **1** | `SCREEN_PORTRAIT` (D1; enum value verified 4.7.2). The iOS exporter writes it as `UIInterfaceOrientationPortrait` only (verified: 4.7.2 exporter source) |
| `rendering/textures/canvas_textures/default_texture_filter` | 1 (Linear) | **0** (Nearest) | crisp pixels |
| `rendering/2d/snap/snap_2d_transforms_to_pixel` | false | **true** | no half-pixel shimmer |
| `rendering/textures/vram_compression/import_etc2_astc` | false | **true** | **mandatory**: the iOS exporter marks the project invalid without it (verified: 4.7.2 exporter source), and Android export stays greyed out. Reimport after changing it |
| `input_devices/pointing/emulate_touch_from_mouse` | false | **true** | your mouse acts like a finger on desktop, so the card swipe works there |
| `application/config/quit_on_go_back` | true | **false** | Android Back (LATER) goes back instead of quitting. No effect on iOS |
| `application/run/max_fps` | 0 | **60** | stops 120 Hz iPhones rendering at 120 fps |
| `gui/common/default_scroll_deadzone` | 0 | **6** | about 1.3 mm on an iPhone 15 if the unit is game px. The unit is unverified; test it in Step 2 |
| `application/boot_splash/use_filter` | true | **false** | crisp pixel splash |
| `application/boot_splash/bg_color` | grey | **Color(0.07, 0.07, 0.1, 1)** | near-black, so any 1-3 px leftover is invisible |
| `rendering/environment/defaults/default_clear_color` | grey | **Color(0.07, 0.07, 0.1, 1)** | same near-black. Whether the letterbox uses it is unverified; with ≤ 3 px it doesn't matter |
| `debug/gdscript/warnings/untyped_declaration` | 0 | **1** (Warn) | keeps code typed. `res://addons` is already excluded by `directory_rules` |
| `application/config/version` | "" | **"0.1.0"** | shown on the title screen |
| `application/run/main_scene` | "" | `res://features/title/title.tscn` | via `project_manage set_main_scene`, after the scene exists |
| `gui/theme/custom` | "" | `res://ui/theme/main_theme.tres` | **Step 3 only, after the file exists** |

**Keep as they are:**
- `gl_compatibility` renderer, `vsync_mode` 1, `keep_screen_on` true, `resizable` true
- the iOS keys `display/window/ios/hide_home_indicator`, `hide_status_bar`, `suppress_ui_gesture` and `allow_high_refresh_rate` (all true, checked 2026-09-26). `suppress_ui_gesture` makes system edge swipes need two swipes, which protects the card swipe
- `low_processor_mode` false, `snap_2d_vertices_to_pixel` false, `snap_controls_to_pixels` true, `emulate_mouse_from_touch` true
- **Do not add** `debug/gdscript/warnings/exclude_addons`. It doesn't exist in 4.7.2; `directory_rules = {"res://addons": 0}` replaced it.

The resulting `project.godot` section, for reference only (let the editor write it):

```ini
[application]
config/version="0.1.0"
config/quit_on_go_back=false
run/max_fps=60
boot_splash/use_filter=false
boot_splash/bg_color=Color(0.07, 0.07, 0.1, 1)

[debug]
gdscript/warnings/untyped_declaration=1

[display]
window/size/viewport_width=270
window/size/viewport_height=480
window/size/window_width_override=540
window/size/window_height_override=960
window/stretch/mode="viewport"
window/stretch/aspect="expand"
window/stretch/scale_mode="integer"
window/handheld/orientation=1

[gui]
common/default_scroll_deadzone=6

[input_devices]
pointing/emulate_touch_from_mouse=true

[rendering]
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
textures/vram_compression/import_etc2_astc=true
environment/defaults/default_clear_color=Color(0.07, 0.07, 0.1, 1)
```

### 1.3 Pixel rules for art and nodes

- **1 art pixel = 1 base pixel, everywhere.**
  - Never scale a sprite by a non-integer factor.
  - Shakes and tweens move by whole pixels (use `roundf`).
  - Camera positions stay on whole pixels, and camera smoothing stays off in the MVP.
- **Texture import:** the filter is Nearest (global), `compress/mode` is Lossless, mipmaps are off, and nothing is larger than 2048 px.
- **Asset sizes** at 270x480 (GDD 2.6):

| Asset | Size |
|---|---|
| Side-view full-body character | 40-48 px tall |
| VS and interview busts | 96 px tall, at most 80 px wide |
| Interview background | 330x400, bottom-anchored at the desk line. The essential area is the bottom-centre 270x160 |
| Title background | `Parallax2D` layers, tiles at least 270 wide, the sky layer 720 tall, bottom-anchored |
| Intro panel | 270x480 (up to 480x480 for a sideways pan, 270x720 for a tilt) |
| Ending illustration | 254x140 |
| Company logos, icons | 16x16 (energy pip 6x8) |
| UI panels | 9-slice, 4 px border + 3 px padding, whole-pixel margins |

- **Parallax2D defaults** (`scroll_scale.x`): sky 0.1 (clouds `autoscroll` -4 px/s), far 0.3, buildings 0.6, props 0.9, ground 1.0. Layers still scroll horizontally in portrait.
  - Set `repeat_size.x` to the texture width and `repeat_times` to 2-3, so 330 px wide screens are covered.
  - Anchor every layer to the screen bottom, so taller phones show more sky, never more floor.
  - The Parallax2D properties are verified 4.7.2.

### 1.4 Fonts

| Role | Font | License | Size |
|---|---|---|---|
| All body text, UI, dialogue, CV | **monogram** (datagoblin, itch.io) | CC0 | **16**, or 32 for a rare big number |
| Title logo, VS screen, K.O. / OFFER! / BUSTED! banners | **Press Start 2P** | OFL 1.1 | 8 / 16 / 24 / 32 |

- Put the files in `res://ui/fonts/`: `monogram.ttf`, `PressStart2P-Regular.ttf`, and the Press Start 2P license as `OFL.txt`.
  - `.txt` is not a resource type (verified: scratch run), so the export preset needs the non-resource include filter `ui/fonts/*.txt`.
  - The Credits screen shows `OFL.txt`. CC0 fonts need nothing.
- **Import settings for every `.ttf`** (Import dock, then Reimport):
  - `antialiasing` = **None**
  - `hinting` = None
  - `subpixel_positioning` = Disabled
  - `generate_mipmaps` = off
  - `multichannel_signed_distance_field` = off
- Use each font only at its native size or whole multiples of it.
  - monogram's exact cell at size 16 is unverified. The GDD assumes a 12 px line and a 6 px advance, so a 240 px text column holds exactly 40 characters (GDD 2.7); answer buttons have zero slack.
  - Press Start 2P's 8 px grid is also unverified.
  - Check both in the editor at 4x before building layouts, and on the iPhone in Step 2.
- Make monogram 16 the default font inside `main_theme.tres`. `gui/theme/custom_font` also exists, but the theme is the one place to change it.
- If you plan Vietnamese or any other non-English language, **check glyph coverage before committing** (unverified for both fonts).

### 1.5 Safe area (Dynamic Island, notch, home indicator)

Portrait only, so each device's insets are fixed: **top** = the Dynamic Island or notch, **bottom** = the home indicator, **left and right** = 0 on iPhones. There is no 180-degree flip.
- Backgrounds are full-bleed: the sky runs up under the island, the ground down under the home indicator.
- **Everything the player reads or taps goes inside a `SafeAreaMargin`** (section 17.10), at least 4 px per side.
- Top and bottom are applied separately. Left and right use the larger of the two insets on both sides, in case a device reports them unevenly.

In viewport stretch mode, `get_final_transform()` is the identity for the root (verified 4.7.2 source). On iOS, `get_display_safe_area()` returns native pixels: the view's `safeAreaInsets` in points times the screen scale (verified: 4.7.2 `display_server_apple_embedded.mm`). So `Device.safe_insets()` converts device pixels to game pixels by hand: scale, then letterbox offset.

**Worked example, iPhone 15 (1179x2556 at 4x):** the game area is 294x639 with 3 px of side letterbox (2 left, 1 right). The insets are 59 pt top and 34 pt bottom, which is 177 and 102 device px, so 44.25 and 25.5 game px. SafeAreaMargin rounds up to 45 / 26, leaving 294x568 for UI, and the central 270x480 block (y about 80-560) sits entirely inside the safe area. The other iPhones are in GDD 2.9; an iPhone 16 Pro gives about 46.25 / 25.25 on 301x655.

- Whether Godot still reports the 59 pt top inset while the status bar is hidden is unverified (section 18.1). Measure it in Step 2.
- Preview on desktop: a 588x1278 window (294x639 game) with `debug_fake_insets = Vector4i(0, 45, 0, 26)` on the screen's SafeAreaMargin.

---

## 2. Folders and naming

**Organize by feature.** Everything for one screen lives in one folder, so cutting or rebuilding a feature touches one place. Claude also finds related files without searching.

There are two exceptions:
- `data/` is grouped by kind, because you edit it in bulk.
- `ui/` holds the shared theme, fonts and components.

```
res://
├─ addons/godot_ai/                vendor tool (godot-ai 4.2.3). Never edit. Excluded from exports.
├─ autoload/                       content.gd, game_state.gd, device.gd, scene_router.gd
├─ core/                           pure @tool classes: game_flow.gd, run_state.gd, save_io.gd, odds.gd
├─ data/
│  ├─ types/                       balance_config.gd, background_data.gd, tier_data.gd  (Resource classes)
│  ├─ balance/balance_config.tres
│  ├─ backgrounds/                 intern.tres, graduate.tres, self_taught.tres
│  ├─ tiers/                       startup.tres, mid.tres, big.tres
│  └─ content/                     the 16 JSON files (section 6.3)
├─ features/
│  ├─ title/                       title.tscn + title.gd  (main scene)
│  ├─ intro/                       intro.tscn + intro.gd, art/
│  ├─ background_select/           background_select.tscn, background_card.tscn
│  ├─ job_hunt/                    job_hunt.tscn, deck/, cv/, inbox/, art/
│  ├─ interview/                   interview.tscn, versus_intro.tscn, answer_meter.gd, hp_bar.tscn, committee_wheel.tscn, art/, sfx/
│  ├─ offer/                       offer.tscn
│  ├─ phase2_stub/                 phase2_stub.tscn  (the Hired card)
│  ├─ game_over/                   game_over.tscn    (the Plan B ending)
│  └─ dev/                         device_check.tscn (debug only; excluded from release exports)
├─ ui/
│  ├─ theme/                       main_theme.tres + 9-slice PNGs
│  ├─ fonts/                       monogram.ttf, PressStart2P-Regular.ttf, OFL.txt
│  └─ components/                  safe_area_margin.gd, dialogue_box, confirm_dialog, ducky_note, stat_bar, pip_bar, odds_band
├─ art/shared/                     palette.png, icons, logos
├─ audio/sfx/   audio/music/
├─ tests/                          test_*.gd (excluded from exports)
├─ art_src/                        .aseprite sources (has a .gdignore, so Godot never imports it)
├─ builds/                         ios/ (the exported Xcode project), later APK/AAB (.gdignore; git-ignored except that file)
└─ docs/                           GDD.md, CONTENT.md, ARCHITECTURE.md, ROADMAP.md
```

| Thing | Convention | Example |
|---|---|---|
| Folders and files | **snake_case**. The exported pack is case-sensitive on the phone; the Windows and macOS file systems are not | `features/job_hunt/job_card.tscn` |
| Script next to its scene | same base name | `job_card.tscn` + `job_card.gd` |
| `class_name` | PascalCase, matching the file | `class_name AnswerMeter` in `answer_meter.gd` |
| Autoload | PascalCase name, and **no `class_name`** in its script | `GameState` = `autoload/game_state.gd` |
| Nodes | PascalCase. Nodes you reference get a unique name | `%ApplyButton` |
| Signals | past tense, snake_case | `resolved`, `layout_changed` |
| Constants and enum values | `CONSTANT_CASE`; enum names are PascalCase | `enum Phase { TITLE, ... }` |
| `.tres` data | **file name = the `id` field** | `data/tiers/mid.tres` with `id = &"mid"` |
| Content ids | the GDD 5.0 prefixes | `co_`, `job_`, `cv_`, `eq_`, `kq_`, `tip_`, `mail_`, `fp_`, `perk_`, `bark_`, `vs_`, `end_`, `evt_`, `intro_`, `news_` |
| Art | `<subject>_<variant>_<size>.png` | `dana_big_neutral_96.png`, `bust_intern_96.png`, `logo_co_synergai_16.png`, `bg_interview_startup.png` |
| Tests | `tests/test_<area>.gd`, with `suite_name()` = `<area>` | `test_odds.gd` has the suite `odds` |

**Finding art:** scenes find art by the naming convention above. A missing file shows a magenta placeholder of the final size, never a crash. When you draw a new file, save it under the right name and it simply appears.

---

## 3. Autoloads and pure classes

Register the autoloads with `autoload_manage add`, **in this order**. Keep godot-ai's `_mcp_game_helper` first.

The order matters because each autoload's `_ready()` may only use autoloads above it. `Device` reads `GameState` settings in `_ready`, and `SceneRouter` connects to `GameState` in `_ready`.

| # | Name | Script | Job | Public API |
|---|---|---|---|---|
| 0 | `_mcp_game_helper` | addon | godot-ai's runtime bridge. The addon's export plugin strips it from exports (verified: addon source) | (none) |
| 1 | `Content` | `autoload/content.gd` | read-only registry of the `.tres` and JSON data | `balance`, `background(id)`, `tier(id)`, `entries(file)`, `entry(file, id)`, `text(file, id, args)`, `field(file, id, key, args)`, static `load_tres_dir(dir)`, static `load_json(path)` |
| 2 | `GameState` | `autoload/game_state.gd` | owns the RunState, the run RNG, the phase and `settings.cfg` | signals `phase_changed(from, to)` and `run_changed`; `run`, `rng`, `preselect_background`; `setting()`, `set_setting()`, `save()`; flow verbs (section 4); hunt, interview and offer verbs |
| 3 | `Device` | `autoload/device.gd` | phone glue: scale guard, safe area, Back, haptics | signals `layout_changed` and `back_unhandled`; `safe_insets()`, `handle_back()`, `haptic(ms)`, `haptics_enabled` |
| 4 | `SceneRouter` | `autoload/scene_router.gd` (CanvasLayer) | fades between scenes when the phase changes | signal `transition_finished(phase)`; `busy`, `go_to(phase)` |

**Pure classes** (`@tool`, `class_name`, `RefCounted`; no nodes, no autoloads, no global RNG):

| Class | File | Holds |
|---|---|---|
| `GameFlow` | `core/game_flow.gd` | `Phase` enum, `TRANSITIONS`, `SAVED_PHASES`, `can_transition`, `is_saved`, `deletes_save`, `can_resume` |
| `RunState` | `core/run_state.gd` | all saved run data, plus rule methods that change it (`spend_energy`, `sleep`, and the hunt rules added in Step 5); `to_dict` / `from_dict` |
| `SaveIO` | `core/save_io.gd` | `exists`, `write` (temp file, then rename), `read`, `delete` |
| `Odds` | `core/odds.gd` | every formula in GDD 5.6-5.9, plus RNG helpers (`roll`, `pick`, `shuffled`) |

**Why the rules live in pure classes:** godot-ai's `test_run` runs inside the editor, where **autoloads don't exist** (verified: addon source). The balance simulation (Step 7) must also run there.

So there is one split:
- **`RunState`, `Odds` and `GameFlow` are the model.** They are data plus rules, and they take `cfg`, `tier`, `bg` and `rng` as arguments.
- **`GameState` is the controller.** It fetches data from `Content`, calls the model, saves and emits signals.
- **Scenes are the view.** They read `GameState.run` and call `GameState` verbs.

**Rules**
- Autoload scripts never have a `class_name`. It would clash with the autoload name.
- There is no `Events` bus. Signals belong to the node that owns the change (`GameState.run_changed`, `Device.layout_changed`).
- **Call down, signal up.** A parent calls methods on its children. A child emits signals and never reaches up with `get_parent()`.
- A scene that connects to an autoload signal uses a method `Callable`, never a lambda, so the connection dies with the scene.
- Pure classes and Resource classes must be `@tool`. The editor-side tests and godot-ai's `resource_manage create` refuse non-tool scripts (verified: addon source).
- After creating a script with a new `class_name` through godot-ai, run `filesystem_manage op=scan`. `script_create` and `write_text` don't rebuild the global class list.

---

## 4. Game flow

### 4.1 Phases and transitions

```
enum Phase { TITLE, INTRO, BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER, PHASE2_STUB, GAME_OVER }
```

**Append new phases at the end only**, for example `WORK` in Phase 2. Saves store the phase as an int, so reordering the enum breaks every existing save.

| From | To | Trigger (the GameState verb) |
|---|---|---|
| TITLE | INTRO | `start_new_game()` on the first run, or `replay_intro()` |
| TITLE | BACKGROUND_SELECT | `start_new_game()` once `intro_seen` is set |
| TITLE | JOB_HUNT / INTERVIEW / OFFER | `continue_game()` (the saved phase) |
| INTRO | BACKGROUND_SELECT | `finish_intro()`: the intro ends, or Skip, or Back |
| BACKGROUND_SELECT | JOB_HUNT | `choose_background()` |
| JOB_HUNT | INTERVIEW | `start_interview(invite)` |
| JOB_HUNT | GAME_OVER | `end_run_plan_b()`: the morning when rent is at 0 and no invite is waiting (grace day already used) |
| INTERVIEW | OFFER / JOB_HUNT | `finish_interview(won, ...)` |
| OFFER | PHASE2_STUB | `answer_offer(true)`, when the background check passes |
| OFFER | JOB_HUNT | `answer_offer(false)` (Decline), or the offer is rescinded by the background check |
| PHASE2_STUB | TITLE / BACKGROUND_SELECT | `quit_to_title()` / `retry()` ("New run") |
| GAME_OVER | TITLE / BACKGROUND_SELECT | `quit_to_title()` / `retry()` |
| BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER | TITLE | `quit_to_title()`: Back or Pause, then "Quit to title" |

**The last row is four transitions added to the required list.** They are needed because:
- GDD S13 Pause (MUST) has "Quit to Title".
- GDD 4.2 says every screen needs an on-screen way back.

They never touch the save: TITLE is never written, and the file stays for Continue.

**States inside a scene, not phases:**
- the hunt's Morning inbox, Day, Night summary and grace day
- the interview's VS intro, prompts, result, committee wheel and Ducky card

`tests/test_flow.gd` locks all of this down.

### 4.2 Rules

- **Only `GameState.change_phase()` changes the phase.**
  - Scenes call verbs such as `finish_interview(true, composure)`.
  - `SceneRouter` listens to `phase_changed` and loads the matching scene.
  - Scenes never load other scenes.
- Scenes get what they need from `GameState.run` (for example `run.interview`), so nothing is passed between scenes.
- An illegal change calls `push_error` and does nothing. The flow tests make that impossible to ship.
- `continue_game()` falls back to `start_new_game()` when the saved phase can't resume. Continue is never a dead button.

---

## 5. SceneRouter and transitions

`SceneRouter` (section 17.9) is a CanvasLayer on layer 100 with a full-screen near-black `ColorRect` curtain. On each phase change it:
1. Starts `ResourceLoader.load_threaded_request(path)`.
2. Fades the curtain to opaque over 0.2 s.
3. Calls `load_threaded_get`, which blocks until loaded (verified 4.7.2).
4. Unpauses the tree, then calls `change_scene_to_packed`.
5. Awaits `SceneTree.scene_changed`, which exists (verified 4.7.2).
6. Fades back in.

**Rules**
- **Taps during a transition:** the curtain is `MOUSE_FILTER_STOP` while fading and `IGNORE` otherwise. An invisible Control still eats taps unless it's IGNORE.
- **`busy` is public.** `Device.handle_back()` ignores Back while it's true.
- **The last request wins** if a change arrives mid-transition.
- **A missing scene** calls `push_error` and stays put. This is why Step 1 runs fine with only the title scene.
- **The curtain uses `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` after `add_child`,** so it follows the guard's size changes.
- **Adding a phase scene:** create `features/<name>/<name>.tscn`, and add one line to `SCENES`.
- **Later (SHOULD):** a pixel-wipe shader on the same curtain. Tween a `progress` uniform instead of `modulate:a`. Ship the plain fade first.

---

## 6. Data model

### 6.1 Static data vs runtime state

| | Static data | Runtime state |
|---|---|---|
| What | numbers you tune; all text | this run: stats, energy, rent, board, applications, the interview checkpoint, the offer |
| Where | `res://data/**/*.tres` and `res://data/content/*.json` | `GameState.run` (a `RunState`), saved to `user://save_v1.json` |
| Changes at runtime? | **never**. Loaded Resources are cached and shared, and in `@tool` code a change can even be saved back to disk | constantly |
| Refers to other things by | ids | **ids only** (Strings), never Resources or Nodes |

### 6.2 Resources (`.tres`): the numbers

There are three `@tool` Resource classes (code in section 17.5). **Every field is a GDD section 11 constant with the same name.** The only exceptions are GDD rows that pack several numbers, which are split into single fields:

| GDD row | Fields |
|---|---|
| `*_range` | `_min` / `_max` |
| `invite_mult (big/mid/startup)` | `invite_mult_big` / `_mid` / `_startup`, read through `bg.invite_mult(tier_id)` |
| `dream_weights` | `dream_w_salary` / `_remote` / `_commute` / `_flags` / `_runway` |
| `knw/exp/net start` | `start_knw` / `start_exp` / `start_net` |
| `jump_window_s` | `jump_window_min_s` / `jump_window_max_s` |

- **`BalanceConfig`**: one file, `data/balance/balance_config.tres`.
  - Its script defaults **are** the GDD defaults, so creating the file with no property changes is correct.
  - Tune the `.tres`, never the script: the formula tests build `BalanceConfig.new()` and expect GDD numbers.
  - If the file is missing, `Content` uses `BalanceConfig.new()`, so the game runs before any data exists.
- **`TierData`**: one per tier. **All odds live here.** Script defaults are the Mid values.

| Field | `startup.tres` | `mid.tres` | `big.tres` |
|---|---|---|---|
| `id` | `&"startup"` | `&"mid"` | `&"big"` |
| `base_invite` | 0.10 | 0.065 | 0.03 |
| `ghost_job_rate` | 0.05 | 0.10 | 0.20 |
| `silent_share` | 0.40 | 0.30 | 0.50 |
| `reply_delay_days` | 1 | 2 | 3 |
| `posted_days_min` / `_max` | 0 / 5 | 1 / 14 | 1 / 30 |
| `applicants_min` / `_max` | 20 / 120 | 150 / 500 | 1500 / 3000 |
| `in_person` | false | true | true |
| `doubt_hp` | 118 | 128 | 132 |
| `tier_difficulty` | 40 | 42 | 44 |
| `needle_speed` (bar-widths/s) | 0.60 | 0.60 | 0.75 |
| `zone_jumps` | true | false | false |
| `lie_probe_chance` | 0.30 | 0.45 | 0.60 |
| `bluff_detect` | 0.0 | 0.05 | 0.15 |
| `background_check` | 0.0 | 0.30 | 0.70 |
| `salary_min_k` / `salary_max_k` (yearly, $k) | 50 / 70 | 65 / 90 | 95 / 125 |
| `office_days` | 0 | 2 | 4 |
| `meeting_load` / `layoff_risk` / `growth_mult` (Phase 2) | 0.2 / 0.3 / 1.5 | 0.5 / 0.1 / 1.0 | 0.8 / 0.2 / 0.8 |

- **`BackgroundData`**: one per background. Script defaults are the Graduate values.

| Field | `intern.tres` | `graduate.tres` | `self_taught.tres` |
|---|---|---|---|
| `id` | `&"intern"` | `&"graduate"` | `&"self_taught"` |
| `start_knw` / `start_exp` / `start_net` | 50 / 40 / 45 | 55 / 15 / 15 | 55 / 10 / 5 |
| `teamwork_mult` | 1.25 | 1.0 | 0.6 |
| `teamwork_mult_after_network` | 1.25 | 1.0 | 1.0 |
| `gap_topics_count` | 0 | 0 | 2 |
| `commute_pips` / `commute_minutes` | 1 / 20 | 2 / 45 | 4 / 95 |
| `runway_days` | 15 | 12 | 12 |
| `interview_travel_pips` | 0 | 0 | 1 |
| `invite_mult_big` / `_mid` / `_startup` | 1.0 / 1.0 / 0.8 | 1.2 / 1.0 / 1.0 | 1.0 / 1.0 / 1.3 |
| `referral_tokens` | 2 | 0 | 0 |
| `pity_n` | 6 | 8 | 10 |
| `has_degree_honest` / `years_pass_honest` | true / true | true / false | false / false |
| `composure_max` | 100 | 100 | 90 |
| `startup_exp_bonus` | 0 | 0 | 5 |
| `textbook_zone_bonus` | 0.0 | 0.04 | 0.0 |
| `salary_mult` | 1.10 | 1.00 | 0.90 |

**Derived values (not fields):**
- Energy per day = `energy_max - commute_pips`, which gives 9 / 8 / 6.
- `lone_wolf` starts as `teamwork_mult < teamwork_mult_after_network`, which is true only for the Self-Taught. `Odds.teamwork_mult(bg, lone_wolf)` picks which multiplier applies.
- `has_degree_honest` and `years_pass_honest` repeat what `cv_lines.json` says about the honest lines. The runtime knockout logic reads the **CV lines actually sent**; the BG flags are for the background card. `test_content_lint` checks that the two agree.

**Creating them with godot-ai:** use `resource_manage create` with `type=TierData`, `resource_path=res://data/tiers/big.tres` and the table's values. This works because the classes are `@tool`.

### 6.3 JSON content: the text

**Rules**
- **One file = one JSON object keyed by id.** A value is either a **plain string** (UI text) or an **object** (a structured entry).
- Keys that start with `_` are metadata, not ids. For example, `naming.json` has `_keywords`, `_topics` and `_gap_topic_pool`.
- **JSON numbers load as floats: wrap them in `int()`.** Tier lists are always explicit, as `["startup", "mid", "big"]`; don't write `"all"`.
- **ASCII only** in player-facing strings (lint-checked).
- **Every displayed string goes through `tr()`.** `Content.text()` and `Content.field()` do this, then fill `{placeholders}` with `String.format(args)`.
  - Static Label text in scenes is English. Controls translate it automatically when a translation exists later.
- Non-displayed fields (`art`, `visual`, `audio`, `note`) are notes for the artist. The lint skips them.
- `Content` reads JSON with `FileAccess` from `res://`. **`.json` is a recognized resource type in 4.7.2**, so "export all resources" includes it (verified: scratch run). Still confirm on the phone in Step 5 that the texts load.

| File | CONTENT.md | Entry shape (key = id) |
|---|---|---|
| `naming.json` | 1 | `"city": "Byteburg"`, `"app_jobs": "DoomApply"`, ...; `"_keywords": {"python": "Python", ...}`, `"_topics": {"algorithms": "Algorithms", ...}`, `"_gap_topic_pool": ["algorithms", "data_structures", "databases", "web", "concurrency", "system_design", "security"]` |
| `cutscene.json` | 2 | `"intro_p1": {"order": 1, "seconds": 6, "captions": [{"speaker": "", "text": "2022. You are 17."}], "visual": "...", "audio": "..."}` |
| `backgrounds.json` | 3.1 | `"intern": {"title", "difficulty", "one_liner", "perk", "flaw", "vs_nickname", "dana_opener", "commute_line", "plan_b_line", "gaps_line"?, "commute_strip"?, "hoodie"}` |
| `names.json` | 3.2 | `"default": "Alex"`, `"pool": [20 names]` |
| `tiers.json` | GDD 7 | `"startup": {"name": "Startup", "tag": "START"}`, `"mid": {"name": "Mid-size", "tag": "MID"}`, `"big": {"name": "Big corp", "tag": "BIG"}` |
| `companies.json` | 4 | `"co_beigeware": {"name", "tier", "mvp", "tagline", "card_joke", "insider", "dana_line", "review", "red_flags": [], "hired_extra"?, "art"}` |
| `postings.json` | 5 | `"job_mid_backend": {"tier", "company": "any" or a co_ id, "title", "tags": [3], "degree": bool, "min_years": int, "ghost": "roll" or "always", "joke", "salary_text", "should": bool}`, plus the plain-string UI ids `card_*`, `knock_*`, `research_*`, `hirebot_*`, `stamp_sent` |
| `cv_lines.json` | 6 | `"cv_intern_edu_honest": {"background", "line": "edu", "variant": "honest", "text", "tags": [], "degree": bool, "passes_years": bool, "degree_claim": bool, "probe": "", "probe_at": {"co_stealth": "..."}?}` |
| `questions_choice.json` | 7 | `"eq_friday_deploy": {"prompt", "teamwork": bool, "tiers": [...], "tip", "opener_only": bool, "answers": [{"kind": "good", "text", "reaction"}, ...], "exclusive": {"background", "kind", "text", "reaction"}?}` |
| `questions_knowledge.json` | 9 | `"kq_hash_map": {"prompt", "topic", "kind": "tech" or "behavioral", "difficulty": 1-3, "weak_for": a bg id or "none", "tiers": [...], "tip", "green", "yellow", "red", "ducky"}` |
| `barks.json` | 8, 10 | plain strings: `dana_title_*`, `bark_*`, `vs_*`, `meter_*`, `ducky_real_answer`, `ui_*`, `coach_*` |
| `tips.json` | 11 | `"tip_ats_knockouts": {"short", "more", "triggers"}` |
| `emails.json` | 12, 13 | `mail_invite_*` / `mail_knockout`: `{"subject", "body"}`; `mail_reject_NN`, `notif_*`, `mail_rescinded`, `offer_*`: plain strings; `perk_*` / `fp_*`: `{"tiers": [...], "text"}` |
| `endings.json` | 14 | plain strings (`end_*`) |
| `events.json` | 15.1 | `"evt_mom_call": {"text", "effect", "ducky"?}` (SHOULD) |
| `news.json` | 15.2 | plain strings (`news_*`) |

Reading text:
- `Content.text("barks", "ui_rent_due", {"days": 9})` returns "Rent due in 9 days".
- `Content.field("questions_knowledge", "kq_hash_map", "green")` returns one field of a structured entry.

### 6.4 Stable ids (GDD 5.0)

| Kind | Ids |
|---|---|
| Backgrounds | `intern`, `graduate`, `self_taught` |
| Tiers | `startup`, `mid`, `big` |
| Stats | `knw`, `exp`, `net` |
| CV lines | `edu`, `exp`, `proj` |
| CV variants | `honest`, `polished`, `lie` |
| Keywords | `python, javascript, java, sql, git, cloud, testing, apis, mobile, data, agile, ai` |
| Knowledge topics | `algorithms, data_structures, databases, web, tools, concurrency, system_design, security, behavioral` |

**Never rename an id** once code refers to it; change the text instead.

---

## 7. Runtime state and randomness

### 7.1 RunState

`RunState` (section 17.2) is the whole run: every GDD 10.4 Phase 2 hook plus what the MVP needs.

**Every `var` in it is saved automatically.** `to_dict()` walks the script's properties, so adding a field is one line. The consequence: only plain data goes in (String, int, float, bool, Array, Dictionary). Ids are Strings.

| Group | Fields |
|---|---|
| Flow and RNG | `phase`, `rng_seed`, `rng_state` (both Strings), `first_run` |
| Character (Phase 2 carries it to work) | `background_id`, `player_name`, `stats {knw, exp, net}`, `lone_wolf`, `gap_topics`, `commute_pips`, `commute_minutes`, `cv_levels {edu, exp, proj}`, `lies_carried`, `confessed` |
| Day loop | `day`, `energy`, `rent_days_left`, `grace_used`, `referral_tokens`, `pity_count` (the Recruiter Radar), `interviews_today`, `next_uid`, `board`, `applications`, `applied` ("template_id\|company_id" pairs), `invites`, `morning_report`, `blacklist`, `researched`, `seen_question_ids` |
| Interview | `interview` (the checkpoint), `interviews_taken`, `times_met_dana`, `dana_last_company` |
| Offer and job | `offer`, `employment {company_id, tier, job_title, salary, work_mode, office_days, perks, red_flags, equity_text, negotiated}`, `dream_score` |
| Run stats | `total_applications`, `total_rejections` |

**Rule methods:**
- The hunt rules added in Step 5 live on `RunState`, taking data and the RNG as arguments. They cover dealing the board, applying, the morning reveal, the Radar, the day-2 guarantee, invite expiry and the Plan B check.
- **Sleep is one committed action.** The night tick, the morning reveal and the board refill all happen at once, and the result is stored in `run.morning_report`. The hunt scene plays the night summary, then the inbox, from that report; "Start day" clears it. A kill between night and morning can therefore never lose or repeat a reveal.
- Hunt rules that the GDD fixes deliberately:
  - **Outcomes are rolled on the reveal morning, in send order**, not at send time.
  - **The Radar counts only relevant applications** (at least 2 of 3 tags) and never counts knockout failures.
  - **The day-2 guarantee applies to the first run only** (`run.first_run`).
  - Invites are valid for 2 days, with at most 1 interview per day.

### 7.2 Seeded randomness

- **One run RNG.** `GameState.rng` is seeded in `choose_background()`. The global `randi()` is used only to pick that seed.
- **The interview gets its own RNG.**
  - `start_interview()` rolls `interview.seed` from the run RNG and saves the checkpoint.
  - The interview scene seeds a fresh `RandomNumberGenerator` from it.
  - So a resume replays the same luck, zone centres, pivots and wheel, and the run RNG doesn't move during the interview.
- **Never use the global RNG in gameplay:** that means `randf()`, `randi()`, `randi_range()`, `Array.shuffle()` and `Array.pick_random()`. Use `Odds.roll`, `Odds.pick` and `Odds.shuffled` with the run or interview RNG.
  - Cosmetic randomness may use the global RNG: shake offsets, confetti, which idle frame plays.
- **Roll in a fixed order** in rule code only, never in UI code or `_process`.
- **Save the seed and the state as Strings.** JSON numbers are doubles, which hold integers exactly only up to 2^53 (verified: scratch run with 2^53 + 1 and a negative state).
  - Restore the **seed first, then the state**, because setting the seed resets the state (verified 4.7.2).
- `RandomNumberGenerator` has `seed`, `state` and `rand_weighted()` (verified 4.7.2).

---

## 8. Save and load

| Rule | Detail |
|---|---|
| Format | One slot: JSON at `user://save_v1.json`, app-private on Android and iOS. `SaveIO.write` writes `.tmp`, then renames it; if the rename fails, it removes the old file and renames again |
| When it's written | **Only while the run is live** (`JOB_HUNT`, `INTERVIEW`, `OFFER`). Three triggers: after every committed action (`_commit()`); on every change into those phases; and on `NOTIFICATION_APPLICATION_PAUSED`, `APPLICATION_FOCUS_OUT` and `WM_CLOSE_REQUEST` |
| Never written on | entering TITLE, INTRO, BACKGROUND_SELECT, PHASE2_STUB or GAME_OVER |
| Deleted when | **entering GAME_OVER**, and **leaving PHASE2_STUB** (Title or New run). Killing the app on the Hired card resumes at the offer |
| Committed actions | apply, tailor, skip, research, study, network, a CV change (on leaving the CV screen), sleep, start interview, interview result, negotiate, offer decision |
| Interview | `start_interview()` pays energy, then saves a **checkpoint**: `seed`, `question_ids`, `probe_line`, `tired`, company and tier. Doubt, Composure and the prompt index live in the scene, so a resume **restarts that interview with the same seed and the same questions** (GDD 5.11). Saves during the interview rewrite the same checkpoint, which is harmless |
| Continue | `SaveIO.read()`. Then `GameFlow.can_resume(saved.phase)` must be true, or it falls back to `start_new_game()`. Then set the seed, then the state, then `change_phase(saved)` |
| Retry / New run | `retry()` builds a **fresh `RunState`** and remembers `preselect_background` |
| Versioning | `RunState.VERSION = 1`. When the format changes, bump it and migrate the dictionary at the top of `from_dict` |
| JSON gotchas | numbers come back as floats (`from_dict` turns whole ones back into ints, recursively); no Vector2 or Color; 64-bit values travel as strings |
| Security | **Never load `.tres` or `.res` from `user://`**: a resource file can carry a script that runs on load. `JSON.to_native` defaults to `allow_objects=false` (verified 4.7.2), and we use `JSON.parse_string` anyway |
| Settings | `user://settings.cfg` (ConfigFile), separate from the run, written only by the game. `[meta]` holds `intro_seen`, `run_count`, `tips_unlocked` (SHOULD) and `best_dream_<bg>`. `[options]` holds `haptics`, `relaxed_timing`, `reduced_motion`, `text_speed` (40 / 80 / 0 = instant) and `music_db` / `sfx_db` (SHOULD) |
| Tests | never write to `user://` in tests. In the editor that is the real save folder. `test_save` round-trips through JSON strings instead |

---

## 9. Mobile lifecycle and the Back button

| Event | Handled by | Does |
|---|---|---|
| `NOTIFICATION_APPLICATION_PAUSED` (app sent to background: home swipe, app switcher) | `GameState` | `save()`. If the phase is INTERVIEW, pauses the tree |
| `NOTIFICATION_APPLICATION_FOCUS_OUT` (iOS Control Center, Notification Center, call banners; desktop alt-tab) | `GameState` | the same |
| `NOTIFICATION_WM_CLOSE_REQUEST` (desktop close) | `GameState` | `save()` |
| `NOTIFICATION_WM_GO_BACK_REQUEST` (Android Back, LATER; never sent on iOS) | `Device` | `handle_back()` |
| Esc (`ui_cancel`) on desktop only | `Device` | `handle_back()` |
| The tree gets paused during an interview | `interview.gd` (`NOTIFICATION_PAUSED`) | shows the "Ready? Tap to continue" overlay (`process_mode = WHEN_PAUSED`). A tap unpauses and re-arms the 250 ms input lock |
| The intro loses focus | `intro.gd` | pauses its tween or AnimationPlayer |

Phones kill background apps without warning, which is why saving happens on pause and on focus loss, not on quit. On iOS, after `APPLICATION_PAUSED` the app gets about 5 s before iOS may kill it, so keep `save()` small (verified: 4.7.2 `os_apple_embedded.mm`). The notification constants are verified 4.7.2.

**iOS has no Back button** (`NOTIFICATION_WM_GO_BACK_REQUEST` is implemented only on Android; verified 4.7.2 `Node.xml`), and games get no edge-swipe back gesture. So every screen shows its own on-screen Back: the action bar's bottom-left `[ < Back ]`, `[=]` on the hub, `[II]` in the interview. There are **no Quit buttons on iOS**.

**The Back chain:**
1. On-screen Back buttons, Android Back (LATER) and desktop Esc all call `Device.handle_back()`.
2. **Every node** receives `WM_GO_BACK_REQUEST` (verified 4.7.2), so **scenes must not handle that notification themselves.**
3. Instead, every screen root implements `handle_back() -> bool`. Return `true` if it used the press.
4. `Device.handle_back()` ignores Back while `SceneRouter.busy`. Otherwise it asks the current scene. If the scene returns false, `Device` emits `back_unhandled`.

| Screen | `handle_back()` |
|---|---|
| Title | close an open dialog; else show "Quit?" (Android and desktop only; iOS apps never quit themselves). Confirm calls `get_tree().quit()` |
| Intro | `finish_intro()` (skip) |
| Background select | `quit_to_title()` |
| Job hunt | close the top modal, flip the card back, or return from an app (CV, Mail, Study) to Jobs; else open Pause |
| Interview | skip the VS intro if allowed; else open Pause |
| Offer | open Pause. Back never declines an offer |
| Hired / Plan B | `quit_to_title()` |

---

## 10. UI, theme and touch

### 10.1 One skeleton for every screen

```
ScreenRoot (Control, full rect; script has handle_back())
├─ Background (TextureRect or Parallax2D stage; full-bleed, bottom-anchored, OUTSIDE the safe area)
├─ SafeArea (MarginContainer + SafeAreaMargin, full rect)
│  └─ Column (VBoxContainer, custom_minimum_size.x = 254, size_flags_horizontal = SHRINK_CENTER, separation 4)
│     ├─ TopBand (information only, y 0-72 at most): HUD, HP bars or a header. Nothing tappable
│     ├─ Body (size_flags_vertical = EXPAND_FILL): content; it takes all the extra height
│     └─ ThumbBand (the bottom 40%, glued to the bottom safe edge): the controls used more than once a day
│        └─ ActionBar (HBox, 36 px tall, separation 6): [ < Back ] 80 px (bottom-left) + PRIMARY 168 px (spans the centre)
└─ ModalLayer (CanvasLayer, layer 10): confirm dialogs, the offer paper, Ducky notes, the pause sheet
```

- Only the screen root uses anchors. Children are sized by containers and `size_flags`.
- The column is always 254 px wide and centred, whatever the screen width (GDD 2.7). Extra height goes to Body, so the thumb band sits the same distance from the thumb on every iPhone (GDD 2.8).
- 80 + 6 + 168 = 254. A screen with one action uses one full-width 254 px button, never a lone small primary in a corner.
- **Pause (S13)** is a bottom sheet in the ModalLayer: full-width buttons stacked with the most used lowest (Quit to title on top, [Notebook], [Settings], RESUME at the bottom as the primary). Tapping outside the sheet = Resume.
- Build layouts with `ui_manage build_layout`. It builds a whole tree in one go.

### 10.2 Theme

- **One file:** `ui/theme/main_theme.tres`, built with `theme_manage`. Set `gui/theme/custom` to it only after it exists.
- **Default font:** monogram 16.
- **Type variations:** `PrimaryButton`, `DangerButton`, `PaperPanel`, `HeaderLabel`.
- **Grey-box styling:** flat `StyleBoxFlat` colors now. In the art pass, swap in pixel 9-slices with `set_stylebox_texture` and whole-pixel margins; layouts stay the same.
- **Colorblind-safe:** green/red is never the only signal. Match tags carry a check or a cross; meter zones carry text; odds bands are dots plus a word.

### 10.3 Touch rules (GDD 2.8)

**Size and placement**
1. **Art is at least 32x32 game px; the hit area is at least 34x34**, with gaps of at least 4 px. At 4x on a 3x iPhone, 34 px is 45 pt (32 px would be 42.7 pt, under Apple's 44 pt minimum). Answer buttons and the action bar are 36 px tall. A hit area may be larger than its art.
2. **Three zones** in the 270x480 frame, y measured from the safe-area top:
   - **Top band, y 0-72:** information only (HUD, HP bars, headers).
   - **Middle, y 72-288:** content. Large surfaces may be tappable anywhere (the job card, tap-anywhere); occasional small controls are allowed (Research, GO NOW, the interview's `[II]`).
   - **Thumb band, y 288-480:** every control used more than once a day. The primary sits bottom-right and spans the screen centre (x 94-262); Back and secondary actions go bottom-left.

**Input handling**

3. **Controls handle mouse events only.** On phones, touches arrive as emulated mouse events (`emulate_mouse_from_touch`).
4. **Only swipe code reads `InputEventScreenTouch/Drag`.** That's the job card and the S03 background card, which handle their taps from the same touch events.
   - Handling both kinds in one Control fires one tap twice.
   - On desktop, `emulate_touch_from_mouse` feeds the cards too.
   - Swipe surfaces stay out of the safe-area insets: `suppress_ui_gesture` only defers the home-indicator swipe, it doesn't disable it.
5. **Tap anywhere** advances text and stops the Answer Meter. The Answer Meter is a full-screen Control with `MOUSE_FILTER_STOP`. A control that consumes its own tap (the interview's `[II]`) never counts as the needle tap (section 11.6).

**Timing**

6. **250 ms input lock** whenever answer buttons or the meter appear, so the tap that finished the typewriter text can't also pick an answer.
7. **Buttons use `action_mode` Button Release** (the default). Whether dragging a ScrollContainer triggers a release is **unverified**; test it in Step 2.
   - If it does, set list-row buttons to `mouse_filter = PASS`.
   - Then ignore a release when the pointer moved more than the deadzone since the press.
8. **No typing** except the optional name field (10 characters); the dice button is the main path. The iOS keyboard covers roughly the bottom 40% in portrait, so the name row lifts above it while typing, using `DisplayServer.virtual_keyboard_get_height()` (implemented on iOS; its unit, likely native px, is unverified).

### 10.4 Text

- The typewriter runs at 40 chars/s (`typewriter_cps`). Tween `Label.visible_ratio` (verified 4.7.2). The first tap finishes the line; the second advances.
- **Text always sits on solid panels**, never directly over dithered sky or parallax.
- A full-width panel is 254 px outside and 240 px of text: 40 characters at monogram 16.
- The GDD 2.7 text budgets (120 / 100 / 40 / 80 / 60 / 120 / 240) and their line caps at 40 columns are enforced by `test_content_lint` (section 12.3).

---

## 11. Building each feature

### 11.1 Title (S01)

- Static art in the GDD 2.5 portrait template (parallax SHOULD): the logo on a sign panel in the sky band (Press Start 2P 24 and 16), skyline and street in the middle, the road under the buttons, the version from `application/config/version` bottom-right.
- **Tap anywhere** calls `start_new_game()` ("Tap to start" blinks in the thumb band).
  - When `SaveIO.exists()`, show two stacked buttons instead: `[ New game ]` above a full-width primary `[ CONTINUE ]`.
  - A small "Replay intro" text button bottom-left calls `replay_intro()`.
- `handle_back()` shows "Quit?" on Android and desktop only; never on iOS.
- The Step 1 stub (section 17.12) prints the window size, game size and scale mode. Keep it as a debug overlay.

### 11.2 Intro cutscene (S02)

- **Build it data-driven from `cutscene.json`. Text slides first, art last.**
  - Each panel: a 270x480 `TextureRect` (a grey placeholder until art exists) that pans, tilts or zooms with one Tween over `seconds`. On taller phones it sits centred on the near-black clear color.
  - Captions are typed out in a `DialogueBox` on a solid band (about y 360-432, up to 4 lines).
- **Taps:** a tap finishes the current caption; the next tap shows the next caption. A tap never skips everything.
- **Skip:** a "Hold to skip" pill bottom-right (96x34) that you **hold for 0.5 s** (a ring fills). Desktop Esc and Android Back (LATER) also skip.
- Every exit goes through `finish_intro()`, so skipping is always safe.
- It auto-plays only when `intro_seen` is false. It pauses on focus loss.
- **Cost warning:** frame-by-frame animation is out of scope. This is a motion comic: pans, zooms, 2-4 frame loops and captions.

### 11.3 Background select (S03)

- **One full-width `background_card.tscn`** (254 wide, about 250 tall), showing numbers from `BackgroundData` and text from `backgrounds.json`:
  - the 96 px bust cropped to its top 72 px, the name and difficulty
  - energy pips, with the commute pips greyed out; runway days
  - the one-liner, 3 stat bars (each 5 segments, value / 20, rounded), a perk and a flaw
  - the Self-Taught's two rolled gaps
- Below it, in the thumb band: the name row, a **3-button selector** (80x40 each: INTERN / GRADUATE / SELF-TAUGHT) and `[ < Title ][ CHOOSE ]`.
- **Switching:** tap a selector button, or swipe the card left or right (it reads touch like the job card). CHOOSE confirms.
- The name field shows "Alex" with a dice button that picks from `names.json` (`LineEdit.max_length = 10`; section 10.3 rule 8 while typing).
- It calls `choose_background(id, name)`. `preselect_background` picks the card after Retry; otherwise The Graduate.
- Out: the chosen card flies up and the phone "boots" DoomApply (0.35 s).

### 11.4 Job hunt (S04-S06)

- **`job_hunt.tscn` is one scene: your phone running the DoomApply app** (GDD S04). From the top: the HUD (y 0-32, information only: day, rent, energy pips, Radar), the app header ("DoomApply" plus a gold "Invite waiting" pill), the body, the action row, and a **bottom dock**.
  - **Dock:** 5 app slots of 47 px (6 of 39 px with Network, SHOULD), 4 px gaps, 40 px tall, each an icon plus a label of up to 6 characters: Jobs, CV, Mail, Study, [Network], and Sleep (the moon) at the right end. Mail shows a gold badge while an invite is waiting.
  - The body swaps **panels, not scenes:** Jobs (the deck), CV, Mail (the inbox), Study. Every app except Jobs shows `[ < Back ]` to Jobs, which is also what `handle_back()` does.
  - Morning (the inbox) and Night (a lock-screen notification card) are overlays inside the same scene.
- **The deck:** 6 new cards each morning (2 per tier), at most 10 on the board. The card is 254 wide and anchored just above the action row; extra height goes above it.
  - **Card front:** a 238x48 header strip cropped from the tier's interview background, logo, company and tier, title, 3 tags with a check or cross against the CV as set, the joke, and the Quick Apply odds band. A red chip shows when the card fails a knockout.
  - **Action row:** `[=]` 34 px (Pause: the hub's on-screen Back), SKIP 80, APPLY 128 (APPLY spans the screen centre).
  - **Swipe right or APPLY** = Quick Apply (1 pip). **Swipe left or SKIP** = skip. **Tap** = flip.
  - **Card back:** applicants, posted date, salary text and the tailored odds band; Research (SHOULD) and the referral toggle in its lower half. The action row becomes `[ < Back ][ TAILOR & APPLY  2 ]`.
- **Card input:** `job_card.gd` reads `InputEventScreenDrag`, moving by the drag's x and tilting at most 6 degrees. It plays a 10 ms haptic when the drag crosses the threshold. On `InputEventScreenTouch` released:
  - a move over 68 px (a quarter of 270), or a flick, is a swipe;
  - a move under the deadzone is a tap.
- **The CV screen (Buzzwordsmith):** a 2-row header (the tag set, the "Degree" and "Counts as 1+ yrs" chips, a Lie-risk row of up to 3 dots), then 3 stacked rows 254 wide, each with a full-width Honest / Polished / Lie segmented control (3 x 82 x 34). `[ < Back ][ DONE ]`. It commits on leaving the screen.
- **Mail (the morning inbox):** a vertical `ScrollContainer` list: invites (with `[ Later ]` and `[ GO NOW  3 energy ]` inside the card), one rejection stack card with [Flip all], the quiet ghost footer, the Radar update. `[ Start day ]` is pinned full width below the scroll, always visible.
- **Rules** all sit on `RunState` and `Odds`. The scene only shows `run` and calls verbs:
  - `quick_apply(card_uid)`, `tailor_apply(card_uid, use_referral)`, `skip_card(card_uid)`
  - `set_cv_level(line, level)`, `study()`, `sleep()`, `start_day()`
  - `start_interview(invite)`, `end_run_plan_b()`
- **Sleep** asks first when 2 or more pips are left: "You still have N energy. Sleep anyway?" with `[ < Back ][ Sleep ]`.

### 11.5 VS intro (S07)

- **One reusable `versus_intro.tscn`**, with `play(company_id, tier)` and a `finished` signal. Build it with an **AnimationPlayer** (`animation_create` + `animation_manage`) so you can retime it in the editor.
- **Portrait split:** a diagonal across the middle (about y 210-270). Dana's half is on top (company color, tier background behind), her bust top-right with her plate to its left. Your half is below (hoodie color), your bust bottom-left with your plate to its right. The tier banner sits at the bottom.

| Time | What happens |
|---|---|
| 0.00 s | 1-frame white flash; the diagonal split appears |
| 0.05-0.35 s | busts slide in along the diagonal (Dana down from the top-right, you up from the bottom-left), easing out with a small overshoot |
| 0.35 s | "VS" (Press Start 2P 32) slams onto the diagonal, driven by a method track |
| 0.4-0.9 s | name plates, and the tier banner from `barks.json` (`vs_banner_*`, Press Start 2P 16, up to 2 lines) |
| 2.0 s | `finished` |

- **The slam at 0.35 s** (the method track):
  - a 100 ms hit-stop: `anim.pause()`, a timer, then `anim.play()`;
  - a 4 px whole-pixel shake;
  - `Device.haptic(40)` and a sound effect.
- **Skip (tap anywhere):** after `vs_min_view_s` (1.0 s) on the first viewing of a run; immediately after that. Skip calls `_finish()`, which stops the animation and emits `finished`.

### 11.6 Interview (S08-S09)

```
Interview (Control, full rect)  interview.gd
├─ Stage (full-bleed; its bottom edge, the desk line, follows the DialogueBox's top)
│    TierBackground (330x400, bottom-anchored), PlayerBust (96 px, left), DanaBust (96 px, right), Desk
├─ AnswerMeter (full rect, hidden until a knowledge prompt; BELOW SafeArea, see the tap rule)
├─ SafeArea (every container and panel in it: mouse_filter = IGNORE)
│  └─ Column (VBox, 254 wide, separation 0; y values from GDD S08)
│     ├─ BarsBand (y 0-28): ComposureBar (hp_bar, 122x8) · "ROUND 2/5" · DoubtBar (hp_bar, 122x8)
│     ├─ StageSpacer (EXPAND_FILL, empty: the stage shows through; 160 px on 270x480, 248 on an iPhone 15)
│     ├─ DialogueBox (254x76): name tab, 4 lines, PauseButton [II] (34x34 hit area) at its top-right
│     └─ AnswerArea (212 px, glued to the bottom safe edge)
│        ├─ MeterRow (40 px): the Answer Meter's bar is drawn here
│        └─ ThumbSlot: AnswerColumn (3 x 254x36, gap 6) | TapPad ("Tap anywhere!") | ProbeRow (2 x 124x44) | DuckyCard
├─ VersusIntro (instance, full rect)
├─ ResultLayer: KOBanner, CommitteeWheel (128 px, in the stage band)
└─ ReadyOverlay (full rect, process_mode = When Paused)
```

**The tap rule (GDD 2.8 rule 6):** any tap counts for the needle except `[II]`, which consumes its own tap. Containers default to `mouse_filter` PASS (verified 4.7.2 ClassDB), and a PASS container on top would swallow the tap. So the AnswerMeter sits below SafeArea in the tree, and every container and panel in SafeArea is set to IGNORE. A tap that misses a real control then falls through to the meter, while `[II]` (a Button, STOP) keeps its own.

**Keeping the stage on the desk line:** on `resized` and `Device.layout_changed`, set the Stage's bottom to `%DialogueBox`'s top, so extra height shows more wall and sky above the characters, never more floor.

**The flow in `interview.gd`** is one coroutine, written with `await`:

1. **Set up.**
   - Seed the interview RNG from `run.interview.seed`.
   - Build the 5 prompts (`[choice, knowledge, knowledge, knowledge, choice]`) from `question_ids`. A probe replaces knowledge prompt 2.
   - Doubt = `tier.doubt_hp`; Composure = `bg.composure_max`.
2. **Open.** Play the VS intro, then the greeting: `bark_dana_greet_again` from the second interview, then the background opener on the first interview of a run.
3. **Choice prompt.** Type out the prompt in the dialogue box. Show 3 stacked answer buttons at the bottom of the thumb band, shuffled with `Odds.shuffled`, after the 250 ms lock. When one is tapped, apply `Odds.ethics_doubt_delta` and `ethics_composure_loss`, then show Dana's reaction.
4. **Knowledge prompt.** Compute S, h and the needle speed, then show the TapPad, `meter.start(...)` and `await meter.resolved`.
   - Q from `Odds.answer_q`, then apply the deltas.
   - Your character speaks the green, yellow or red line in the dialogue box; on red, Ducky's "Real answer: ..." appears as a full-width note in the thumb band.
   - **The zone width is visible before the needle moves.** That is the visible-luck rule.
5. **Lie probe.** Two half-width buttons (124x44) at the bottom of the thumb band: [Come clean] left, [Bluff] right with its odds band on a second line, using `Odds.bluff_p`.
6. **After each prompt:** Doubt at or below 0 is a **K.O.**; Composure at or below 0 is a rejection.
7. **After prompt 5:**
   - If `committee_eligible`, spin the wheel in the stage band with its win wedge drawn at `committee_win_p`, rolled on the interview RNG.
   - Otherwise it's a rejection. The thumb band becomes the Ducky card: one tip, the model answer of your worst question, and a full-width `[ Back to the hunt ]`.
8. **Finish.** Call `GameState.finish_interview(won, composure_left, busted)`.

**The Answer Meter** (section 17.11):
- **Position:** the skeleton draws its bar 40 px above its own bottom edge, which would put the needle under the thumb. In Step 4, draw it at the MeterRow's y instead (the scene passes it on `resized` and `Device.layout_changed`), so the TapPad sits under the thumb and never covers the needle. `answer_meter_width_px` stays 200 (GDD S08).
- The tech-verified bug is fixed: it calls `set_process(false)` in `_ready()`, and `_process` returns when `_done`.
- The needle speed is at least 0.6 bar-widths/s and the zone half-width at least 0.06, so the GOOD window is at least about 160 ms.
- **Relaxed Timing** fixes the input quality at 0.9.
- On a startup interview, the zone jumps once between 1.0 and 2.5 s and emits `zone_jumped`, which the scene shows as "PIVOT!".

**Debug:**
- The scene's `_ready()` calls `GameState.debug_quick_start(...)` and builds a fake checkpoint when `run.background_id` is empty, so `project_run mode="custom"` can open it directly.
- A debug-only panel forces each outcome: K.O., wheel win, wheel loss, Composure 0, BUSTED.

### 11.7 Offer, Hired card, Plan B (S10-S12)

- **`offer.tscn`:** the dimmed interview stage (Dana stays visible) with a `PaperPanel` contract (`RichTextLabel`, 254 wide, about 250 tall) that slides up from the bottom. One field per line after a 12-character label column, values wrapping at 28 columns: the role and company, the **yearly** salary (`$71,000/year`), the work mode, a commute preview (`offer_commute_office`, 2 lines), 2 perks and 1 fine-print joke (up to 4 lines).
  - Buttons: [Negotiate] full width above the action bar (once, SHOULD), then `[ Decline ][ ACCEPT ]` (80 + 168). Decline opens a confirm dialog. SHOULD: ACCEPT becomes drag-to-sign along a 200 px line.
  - Tips: `tip_total_comp` or `tip_negotiate`, plus `tip_equity_lottery` at startups.
- **`phase2_stub.tscn`** (the Hired card), in two beats, because everything at once needs about 500 px:
  - beat 1: the HIRED stamp slams onto a 254x140 illustration, with company, role and salary and the tier's hired line below; tap anywhere to continue;
  - beat 2: the Dream vs Reality panel slides up: its 5 rows (`Odds.dream_score`) tallying one by one, the score, `tip_written_offer` and "TO BE CONTINUED".
  - Buttons: `[ Title ][ NEW RUN ]`.
- **`game_over.tscn`:** the Plan B card in one beat (about 400 px): the stamp over a 254x140 illustration, the background line, one tip and the run stats. Buttons: `[ Title ][ RETRY ]`.

### 11.8 Viewpoints

- **Side view** (title, intro, interview, endings): `Parallax2D` layers as described in section 1.3, bottom-anchored in the GDD 2.5 portrait template. The interview, VS and commute stages are a wide vignette inside a band at least 270x160.
- **Top-down** is SHOULD/LATER.
  - The room hub (SHOULD) is **one static 330x720 illustration with 4 tap hotspots** (at least 48x48, in the lower 60%): invisible `TextureButton`s. There is no walking sprite.
  - Phase 2's office uses `TileMapLayer` (16x16 tiles) with y-sorted characters, scrolling vertically.
  - If you ever use `Area2D` input, turn on the viewport's `physics_object_picking`.
  - Every new viewpoint needs its own character sprite set. That doubles character art, so defer it.

---

## 12. Testing with godot-ai

### 12.1 Conventions (verified: addon source)

- **Discovery:** `test_run` finds `res://tests/test_*.gd` **non-recursively**.
- **Every test file must be `@tool` and `extends McpTestSuite`.** The handler needs `can_instantiate()`, which is false in the editor for non-tool scripts.
- **Order:** `suite_name()` names the suite, and `test_*` methods run in **alphabetical order**.
- **A test with 0 assertions fails.** A SCRIPT ERROR aborts the test.
- **Helpers available:**
  - `assert_true`, `assert_false`, `assert_eq`, `assert_ne`, `assert_gt`, `assert_has_key`, `assert_contains`, `assert_is_error`
  - `skip`, `skip_suite`, `fail_setup`, `track`, `expect_script_error_containing`
  - the hooks `setup`, `teardown`, `suite_setup`, `suite_teardown`
- **There is no `assert_lt` and no float tolerance.** Use `assert_true(absf(a - b) <= eps, msg)` (the `_near` helper in section 17.13).
- **Tests run in the editor process, so there are no autoloads.** Test the pure classes and Resources. Build fixtures in code; `BalanceConfig.new()` carries the GDD defaults.
- **Time limits:** the whole run has a 300 s budget, and a single test that blocks for more than 20 s can drop the session.
- **Reading errors:** test-file errors can be missing from `project_run`'s fallback `recent_errors` summary. Read the `load_errors` in the `test_run` result, or use `logs_read source="editor"`.

### 12.2 The test files (GDD 10.6)

| File | Suite | Covers | Created in |
|---|---|---|---|
| `test_flow.gd` | `flow` | every required transition, the illegal jumps, the save policy (`is_saved`, `deletes_save`, `can_resume`), and a fresh RunState for Retry | Step 1 (section 17.13) |
| `test_save.gd` | `save` | RunState <-> JSON round trip; 64-bit RNG state (2^53 + 1 and negative); seed-then-state replay | Step 1 (section 17.13) |
| `test_odds.gd` | `odds` | P_invite worked examples (16.8%, 12.3%, 30.7%, 19.0%), clamps, bands, knockouts, relevance, determinism. **Step 5 adds** the RunState hunt rules: reveal in send order, the Radar ignoring knockouts, the day-2 guarantee on the first run only | Step 1 (section 17.13) |
| `test_interview.gd` | `interview` | the GDD 5.8.7 walkthrough with fixed luck (Doubt 105.5, 68.6, then about 13.1; wheel 68%), bluff 45 / 35 / 32.5%, Tired, input bands | Step 1 (section 17.13) |
| `test_offer.gd` | `offer` | salary $71,000, negotiation 77.5 / 62.5% with the 85% cap, Dream scores 68 / 57 / 49 | Step 1 (section 17.13) |
| `test_content_lint.gd` | `content_lint` | see 12.3 | Step 4, grows each step |
| `test_balance.gd` | `balance` | the GDD 5.12 simulation, ported | Step 7 |

The 5 Step-1 files contain 24 tests, and all pass against the section-17 code (verified: scratch run, and in this repo on 2026-09-26 after the portrait change).

### 12.3 `test_content_lint.gd` checks

1. **Every file parses** to a Dictionary.
2. **Every referenced id exists:**
   - company `tier`; posting `company` (or `"any"`) and `tier`
   - tags in `_keywords`; topics in `_topics`
   - question `tip` in `tips.json`; `weak_for` is a background or `"none"`; `exclusive.background`
   - perk and fine-print `tiers`
   - background ids match the `.tres` ids
3. **Text budgets** from GDD 2.7, per field. The test also word-wraps each string at 40 columns and checks the line cap:

   | Field | Max chars | Lines at 40 columns |
   |---|---|---|
   | dialogue, reaction, bark, coach, `ducky` | 120 | 4 |
   | `prompt` | 100 | 3 |
   | answer `text` | 40 | 1 |
   | `green` / `yellow` / `red` | 80 | 3 |
   | posting `joke`, `card_joke`, `one_liner`, CV `text` | 60 | 2 |
   | tip `short` | 120 | 4 |
   | email `body` | 240 | 7 |
   | `insider`, each `red_flags` entry, posting `title`, `salary_text` | 40 | 1 |

4. **Banned brands** (CONTENT 1.3): a case-insensitive, **whole-word** match (`RegEx` `\bword\b`) over every player-facing string.
   - The list and an allowlist of `{word, reason}` live as constants **in the test file**. `tests/` is never exported, so real brand names never ship.
5. **ASCII only:** every character code is below 128.
6. **Placeholders:** every `{x}` is in the CONTENT 0 list.
7. **Shape checks:**
   - each choice question has exactly one good, one neutral and one bad answer;
   - each background has 9 CV lines;
   - `has_degree_honest` / `years_pass_honest` match that background's honest CV lines;
   - per tier there are at least 11 choice and at least 19 knowledge questions.

### 12.4 `test_balance.gd` (Step 7)

- Port the GDD 5.12 bot:
  - it keeps a Polished CV;
  - it tailors when 2 or more tags match, and uses referrals on Mid and Big;
  - it researches before 30% of interviews, and studies once after each lost interview;
  - it taps with about 75 ms of timing error;
  - it picks good / neutral / bad ethics answers 85 / 10 / 5%;
  - it accepts the first offer.
- Drive the **real** `RunState` and `Odds` rules. Load the `.tres` and JSON with `load()` and `Content.load_json()` inside the test.
- **Split it by background:** one test method each, **about 1,000 runs**, which keeps every test well under 20 s.
- Assert the 5.12 bands with tolerances that suit n = 1,000. For example, Medium offers 88-98% and the Hard first-interview pass rate 10-20%.

---

## 13. Export

### 13.1 iOS from the MacBook (Step 2)

Godot exports an Xcode project; Xcode signs it, builds it and installs it on the iPhone (verified: 4.7 docs). All of this happens on the Mac: the Windows PC can't build for iOS.

| Need | Value | Notes |
|---|---|---|
| macOS | Godot 4.7 needs macOS 13+ on Apple silicon (11+ on Intel). **Xcode sets the real floor:** Xcode 26.0-26.3 need macOS 15.6+, Xcode 26.4-26.6 need macOS 26.2+, Xcode 27 needs macOS 26.6+ | verified: godot-docs 4.7 system requirements; developer.apple.com/support/xcode |
| Xcode | the version that supports your iPhone's iOS. An iPhone on iOS 27 needs Xcode 27 (released 2026-09-14) | whether Xcode 26.x can deploy to an iOS 27 phone is unverified |
| Godot | **4.7.2**, the universal zip from godotengine.org: the same version as the PC, and it never auto-updates. Its settings live in `~/Library/Application Support/Godot/` | verified: godotengine.org, 4.7 docs |
| Export templates | exactly **4.7.2.stable**, iOS | installed from the editor (task 2) |
| Apple account | a free Apple ID (Personal Team). The paid program only from Step 13 | limits below |

**1. Xcode.** Install it, launch it once and accept the license. In **Xcode > Settings > Accounts**, press **+** and add your Apple ID; it shows as "(Personal Team)". Then use **Manage Certificates... > + > Apple Development**. The iOS Simulator runtime isn't needed for device builds (unverified).

**2. Export templates.** In the Mac editor, open **Editor > Manage Export Templates** and install the iOS templates (Install Selected Templates), or use "Install from file" with `export_templates.tpz`.

**3. Team ID.** Godot needs the 10-character code (like `ABCDE12XYZ`), not your name; a wrong value causes a "JSON error" on export (verified: 4.7 docs). A free account can't see it on the developer website: open **Keychain Access > login > My Certificates**, double-click "Apple Development: <you>" and copy the **Organizational Unit** (community sources, not Apple docs).

**4. Create the preset:** **Project > Export > Add... > iOS**. `application/app_store_team_id` and `application/bundle_identifier` are required; export fails without them. Option names and defaults are verified against the 4.7 docs and the 4.7.2 exporter source unless marked.

| Setting | Value |
|---|---|
| Runnable | ticked |
| `application/app_store_team_id` | the Team ID from task 3 (not a secret) |
| `application/bundle_identifier` | `com.<you>.swesimulator`: lowercase letters, digits and dots only, so it is also a valid Android package name. **Pick it once and never change it**: a Personal Team allows 10 App IDs per 7 days |
| `application/export_method_debug` | Development (the default) |
| `application/export_project_only` | **on**: Godot writes the Xcode project and Xcode builds it. Off makes Godot also run `xcodebuild` to produce an .ipa, which is unverified with a Personal Team |
| `application/min_ios_version` | 15.0 (the default; Xcode 27 accepts it) |
| `application/targeted_device_family` | **0 = iPhone** (the default 2 is iPhone & iPad). iPad-native is LATER (GDD 2.10) |
| `application/icon_interpolation` | **0 = Nearest neighbor** (the default 4, Lanczos, blurs pixel art) |
| `icons/icon_1024x1024` | the 32 or 64 px icon upscaled by a whole number to 1024 (Step 12). Blank falls back to the project icon; whether the other sizes are generated from it is unverified |
| `storyboard/use_custom_bg_color` + `storyboard/custom_bg_color` | on, `Color(0.07, 0.07, 0.1)`, matching the boot splash (the look is unverified) |
| `storyboard/image_scale_mode` | Center |
| `user_data/accessible_from_files_app` | off (the default): the save stays private |
| `capabilities/*`, `privacy/*` | the defaults (all off): the game is offline |
| Resources: exclude filter | `addons/godot_ai/*, tests/*`. Add `features/dev/*` for release builds. The addon's export plugin also strips `_mcp_game_helper` (verified: addon source) |
| Resources: include non-resource files | `ui/fonts/*.txt` |

Orientation isn't a preset option: the exporter turns `display/window/handheld/orientation = 1` into `UIInterfaceOrientationPortrait` only (verified: 4.7.2 exporter source). The exporter also refuses the project without `import_etc2_astc`, which Step 1 set.

**5. Export and run from Xcode** (the guaranteed path):
- **Project > Export > Export Project** into `builds/ios/` (git-ignored). You get an Xcode project folder with the `.xcodeproj`, the `.pck` and the Godot library (the exact file list is unverified).
- Open the `.xcodeproj`. Under **Signing & Capabilities**, tick "Automatically manage signing" and choose Team = "<you> (Personal Team)".
- Pick your iPhone as the run destination and press **Cmd+R**. Logs appear in Xcode's console (unverified).

**6. The iPhone:**
- On the first USB connection, accept **Trust This Computer**.
- **Developer Mode** (iOS 16+): Settings > Privacy & Security > Developer Mode, switch it on, tap Restart, then confirm Enable with your passcode. **The toggle appears only after the phone has been connected to Xcode** (verified: Apple, "Enabling Developer Mode on a device").
- The first launch is blocked as "Untrusted Developer": **Settings > General > VPN & Device Management > your Apple ID > Trust** (verified: Apple Developer Forums).
- Wi-Fi: after one USB pairing, tick "Connect via network" in Xcode's **Window > Devices and Simulators**, with both devices on the same Wi-Fi (community guides).

**7. Remote debug (optional).** The macOS editor has one-click deploy for iOS: it exports with debugging on and runs the game on the connected iPhone, so errors from the phone appear in the Output and Debugger panels (verified: 4.7 docs; macOS editor only).
- It needs Xcode signed in, and the phone paired, unlocked and in Developer Mode, over USB or the same network (Editor Settings > Network > Debug > Remote Host).
- Build each new bundle ID once in Xcode first, so its provisioning profile exists.
- Whether it works with a Personal Team is unverified. Xcode Run stays the guaranteed path.
- **godot-ai cannot see device builds.** Read Xcode's console, or the Debugger panel with one-click deploy.

**Personal Team limits** (verified: developer.apple.com, compare memberships):
- **Provisioning profiles expire 7 days after they are issued.** The app then stops launching; press Run in Xcode again to re-sign it. Write the install date down.
- Up to 3 devices, 10 App IDs (each expiring after 7 days) and 3 apps per device.
- Reinstalling over the same bundle ID should keep the save (unverified).

**The paid Apple Developer Program** (99 USD a year; verified: Apple's enrollment page) is needed for TestFlight, App Store Connect and release, for profiles that don't expire weekly (about a year; unverified), and for Game Center, In-App Purchase and iCloud. Join it before Step 13, not before.
- **Release build (Step 13):** keep `application/export_method_release` = App Store (the default), set `app_store_team_id` to the paid team's ID (it may differ from the Personal Team's; unverified), then archive in Xcode (Product > Archive) and upload to App Store Connect for TestFlight (the standard Xcode flow; unverified in the Godot docs).
- App Store Connect uploads need Xcode 26+ with the iOS 26 SDK (since 2026-04-28; verified: developer.apple.com).

### 13.2 Android (LATER)

Android returns after the MVP and needs an Android phone to test on. Keep it possible now: no iOS-only plugins, haptics behind `Device.haptic()`, and one id (`com.<you>.swesimulator`) for both stores. The facts already checked:

| Need | Value | Notes |
|---|---|---|
| JDK | OpenJDK **17** | already on the PC: `C:\Program Files\Eclipse Adoptium\jdk-17.0.15.6-hotspot` |
| Android SDK | platform-tools, build-tools 35.0.1, **`platforms;android-35` and `platforms;android-36`**, cmdline-tools, CMake 3.10.2.4988404, NDK r28b | the 4.7 docs list API 35, but the 4.7.2 Gradle template targets compileSdk/targetSdk **36** (build-tools 36.1.0, NDK 29.0.14206865, minSdk 24; verified: 4.7.2 `config.gradle`) |
| Export templates | exactly **4.7.2.stable**, Android | |

- **Install the SDK yourself, outside Claude** (MSIX AppData virtualization, section 16): Android Studio's SDK Manager, or `sdkmanager --sdk_root=<android_sdk_path> "platform-tools" "build-tools;35.0.1" "platforms;android-35" "platforms;android-36" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"` (`--sdk_root` is required). Then set the Java SDK and Android SDK paths in **Editor > Editor Settings > Export > Android**.
- **`import_etc2_astc`** is mandatory for Android too; Step 1 set it.
- **Preset:** Runnable; `package/unique_name` = the iOS bundle id; `package/name` SWE Simulator; `version/code` 1, `version/name` 0.1.0; `architectures/arm64-v8a` only; `screen/immersive_mode` on; **`permissions/vibrate` on** (haptics); the same exclude and include filters as iOS.
- **Debug keystore:** the editor generates one with `keytool` from the configured JDK when none is set (verified: 4.7.2 `platform/android/export/export_plugin.cpp`).
- **Deploy:** Developer options and USB debugging on the phone, then one-click deploy with **Debug > Deploy with Remote Debug** on; `adb logcat` for logs.
- **Before Google Play:**
  - Project > Install Android Build Template, then `gradle_build/use_gradle_build` on, `gradle_build/export_format` = AAB, and untick "Export With Debug".
  - **Target API 36:** required for new apps and updates since 2026-08-31, with extensions to 2026-11-01 (verified: developer.android.com). The 4.7.2 template targets 36; confirm the preset's `gradle_build/target_sdk` (its default is unverified) and the uploaded bundle's targetSdkVersion.
  - **Release keystore:** `keytool -v -genkey -keystore swe_sim_release.keystore -alias swesim -keyalg RSA -validity 10000`, with the same password for the keystore and the key. **Never commit it. Back it up in two places.**
  - **Play Console:** the Data safety form, even though the game collects nothing. New personal accounts reportedly need a closed test with 12 testers for 14 days (unverified).

---

## 14. Version control

### 14.1 Git on both machines (Windows PC and MacBook)

- **Done:** git works on the PC, and the repo is `Lecoeurdelest/swe-simulator` on GitHub (branch `main`), with `.gitignore` and `.gitattributes` in history from the start.
  - If a shell that Claude launched can't find `git`, restart Claude after changing PATH. GitHub Desktop also bundles git under `%LOCALAPPDATA%\GitHubDesktop\app-<version>\resources\app\git\cmd\git.exe`; the version folder changes with every update, so don't hard-code it.
- **On the Mac:** git comes with Xcode's command-line tools (run `xcode-select --install` if `git --version` asks). Set the same `user.name` and `user.email`, sign in to GitHub the way you do on the PC (GitHub Desktop also runs on macOS), and `git clone https://github.com/Lecoeurdelest/swe-simulator.git`.

**Working on two machines:**
- **Pull before you start, push before you switch.** Work that isn't pushed doesn't exist on the other machine, and a conflict in a `.tscn` is painful to merge.
- **Line endings:** `.gitattributes` forces LF (`* text=auto eol=lf`), so both machines write identical files.
- **`.godot/` is ignored.** The first open on the Mac rebuilds it and reimports everything. It's slow once; that's expected.
- **Commit the `*.uid` and `*.import` files** (173 `.uid` files are tracked; `.import` files arrive with the first assets). Move and rename files only in Godot's FileSystem dock.
- **The `.claude/skills` symlink:** git stores it as a symlink (mode 120000) to `../.agent/skills`. This PC has `core.symlinks=false`, so here it's a plain text file containing `../.agent/skills`; git on macOS makes a real link, so the project skills load only on the Mac. Never replace the Windows placeholder with a real folder and commit it: that turns the symlink into a normal entry.
- **Python caches** are ignored (`__pycache__/`, section 14.2). One `.pyc` under `.agent/skills/plan-driven-development/scripts/__pycache__/` was committed before that rule; remove it from the index once with `git rm -r --cached .agent/skills/plan-driven-development/scripts/__pycache__`.
- **Path case:** both file systems are case-insensitive, but the exported pack is not. Match the case of every `res://` path exactly.
- **Engine:** both machines run exactly 4.7.2. Commit before any update, and update both machines together.
- `export_presets.cfg` is committed and holds the iOS preset (and the Android one, LATER). Export credentials live in `.godot/`, which is ignored (section 14.3).

### 14.2 The two files (exact content)

`.gitignore`:

```gitignore
# Godot 4.1+ cache and generated files
.godot/
*.translation

# godot-ai updater staging (it also ignores itself)
addons/.godot_ai_update/

# Build outputs (keep the folder's .gdignore so Godot never scans it)
/builds/*
!/builds/.gdignore
/android/
*.apk
*.aab
*.idsig

# Signing keys: never commit; back the release keystore up separately
*.keystore
*.jks

# Local tool settings
.claude/settings.local.json

# OS junk
Thumbs.db
desktop.ini
.DS_Store

# Python bytecode (skill helper scripts)
__pycache__/
```

`.gitattributes`:

```gitattributes
# Normalize text files to LF (the Godot 4 docs' recommendation)
* text=auto eol=lf

# Binary assets: never diff them or convert line endings
*.png binary
*.jpg binary
*.jpeg binary
*.webp binary
*.gif binary
*.ogg binary
*.wav binary
*.mp3 binary
*.ttf binary
*.otf binary
*.aseprite binary
*.ase binary
*.res binary
*.scn binary
```

### 14.3 What to commit

| Path | Commit? | Why |
|---|---|---|
| `project.godot`, `*.tscn`, `*.tres`, `*.gd`, `*.gdshader`, `*.json`, `export_presets.cfg` | yes | Since 4.1 the export secrets live in `.godot/`, not in `export_presets.cfg` (verified: 4.7 docs) |
| **`*.uid`** | **yes** | since 4.4, scenes point to scripts by `uid://` |
| **`*.import`** | **yes** | per-asset import settings (filter, font antialiasing) |
| `addons/godot_ai/` | yes | `project.godot` references its plugin and autoload |
| `.godot/`, `addons/.godot_ai_update/`, `/android/`, `/builds/*`, `__pycache__/` | no | cache, updater staging, regenerable build template, outputs (including `builds/ios/`), Python caches |
| `*.keystore`, `*.jks` | **never** | back the release keystore up separately |

**Habits**
- Commit every time something works, and push at the end of every session. Use messages like `feat(interview): add doubt/composure bars`.
- **Always commit before a godot-ai `script_patch`** (it can't be undone with Ctrl+Z) and before any engine update.
- Tag milestones: `v0.1-greybox`, `v0.5-mvp`.
- Move and rename files only in Godot's FileSystem dock, never in Explorer. The `.uid` and `.import` files move with them.
- Git LFS isn't needed until art or audio gets large.

---

## 15. Performance and battery

- **`viewport` stretch mode is the biggest win.** It shades 130-240k pixels per frame whatever the phone's resolution.
- **`max_fps = 60` plus vsync** stops 120 Hz iPhones from rendering twice as often.
- **Leave low-processor mode off.** It's the default (verified 4.7.2); it helps only static screens and hurts frame pacing. If battery becomes a problem, try `OS.low_processor_usage_mode = true` on the CV and inbox panels only.
- **Keep `gl_compatibility`.** It has the widest device support and starts fastest, and it's the only renderer the iOS simulator supports. On iOS it runs on native OpenGL ES 3.0, its only iOS driver in 4.7.2 (verified: 4.7.2 `main.cpp`); Apple has deprecated OpenGL ES since iOS 12, but it still runs.
- **Habits:**
  - call `queue_redraw()` only while something moves (the Answer Meter stops processing when it's done);
  - use `create_tween()` on the node itself, so the tween dies with the node;
  - use Parallax2D `autoscroll` instead of per-frame scripts;
  - keep textures at 2048 px or less, and put UI in one atlas when the art arrives;
  - no `print()` in `_process`;
  - use OGG for music and WAV for short sound effects.
- **Measure:**
  - on desktop: `editor_manage monitors_get` (FPS, draw calls, memory);
  - on the iPhone: the remote Debugger's Monitors tab (with one-click deploy from the Mac), or Xcode's debug gauges.
  - Test on the **oldest iPhone you can borrow** (an SE or an 11), and on a cheap Android phone once Android returns.

---

## 16. Working with godot-ai (the loop for every session)

**0. Pull, then open Godot with this project before starting Claude.**
- **On the Windows PC this order is required.** The bridge authenticates with a capability file in AppData, and MSIX AppData virtualization can hide it from a Claude started first (your setup note).
- **On the Mac it's only a good habit.** The file sits at `~/Library/Application Support/godot-ai/capabilities/http-8000.json`, and the editor and a Terminal-launched `claude` see the same path (verified: addon source). First-time setup is at the end of this section.

**1. Check the editor.** Run `editor_state`: the editor must be ready and **not playing**. Edits during play are rejected; calling `editor_state` resyncs.

**2. Code.**
- Use `script_create` or `script_patch`. The response includes parse diagnostics.
- **Commit before `script_patch`**, because it can't be undone.
- After a new `class_name`, run `filesystem_manage op=scan`.

**3. Scenes.**
- `scene_manage create` gives you the root.
- `ui_manage build_layout` builds a whole UI tree in one go.
- Then `script_attach`, then **`scene_save`**. Changes stay in editor memory until you save.
- `batch_execute` groups edits so they roll back together.

**4. Data.** Use `resource_manage create` (`@tool` classes only). JSON goes through the file tools.

**5. Tests.** Run `test_run`, or `test_run suite="odds"` for one suite, then `test_manage results_get`. If something fails without a message, read `load_errors`, or `logs_read source="editor"`.

**6. Run.**
- Use `project_run`; `mode="custom"` plus a scene runs one feature. `project_run` defaults to `autosave=true`, which writes in-memory scene changes to disk first.
- Then check:
  - `editor_screenshot source="game"` (a minimized game window gives a stale frame);
  - `logs_read source="game"`;
  - `game_manage get_ui_elements`, then `input_mouse` on an element's rect centre (whether the coordinates are game or window pixels is unverified);
  - `editor_manage game_eval` to inspect or cheat, for example `return GameState.run.to_dict()`.
- **`game_status="break"` at boot means a parse error.** Run `project_manage stop`, then `logs_read source="editor"` (boot parse errors only appear there), fix it and relaunch.

**7. Stop.** Run `project_manage stop`.

**8. You play it.** Test it on the iPhone for feel, readability and one-thumb reach (on the Mac: pull, export, Run in Xcode). Then commit and push.

**Debug quick start.** Every feature scene starts like this, so `project_run mode="custom"` can launch it alone:

```gdscript
func _ready() -> void:
	if OS.is_debug_build() and GameState.run.background_id == "":
		GameState.debug_quick_start("graduate", GameFlow.Phase.JOB_HUNT)  # the scene's own phase
```

`debug_quick_start` sets up the run in place: background, stats, energy, rent, the RNG seed and the phase. It calls **no `change_phase()` and emits no signal**, so `SceneRouter` never replaces the scene you launched (tech-verified fix #5).

| Task | godot-ai tools |
|---|---|
| Project settings | `project_manage settings_get` / `settings_set` (one key per call). The tool refuses `autoload/*`, `editor_plugins/*` and the main scene: use `autoload_manage add` and `project_manage set_main_scene` |
| API questions | `api_manage get_class` (ask for specific sections; `"all"` is large) |
| UI | `ui_manage build_layout` / `set_anchor_preset`, `theme_manage` (`create`, `set_font`, `set_stylebox_texture`, `apply`) |
| VS intro, idles | `animation_create`, `animation_manage` |
| Data | `resource_manage create`, `filesystem_manage read_text` / `write_text` / `scan` |
| Running and inspecting | `project_run`, `editor_screenshot`, `logs_read`, `game_manage`, `editor_manage game_eval` / `monitors_get` |
| Phase 2 top-down | `tileset_manage`, `tilemap_manage` |

**Setting up godot-ai on the Mac (once, in Step 2):**
- Install **uv**, which provides `uvx`: `brew install uv`, or `curl -LsSf https://astral.sh/uv/install.sh | sh`. You don't need to install Python; uv downloads one when needed.
- Install Claude Code (the `claude` CLI). The addon looks for `claude` and `uvx` in `~/.local/bin`, `~/.claude/local`, `~/.cargo/bin`, `/opt/homebrew/bin` and `/usr/local/bin`, then asks your login shell, so a Godot started from Finder still finds them (verified: addon source).
- Open the project in Godot; the addon comes with the repo. In the Godot AI dock, pick Claude Code, set the scope to **local** (Editor Settings `godot_ai/mcp_client_scope`; the PC uses local too) and press **Configure**. It removes any old entry, then runs `claude mcp add --scope local godot-ai -- <uvx> ... godot-ai==4.2.3 ...`. The first server start installs 60+ packages, so it's slow once.
- Start `claude` in the repo folder and check the connection with a read-only call such as `editor_state`.
- **Never use the "project" scope.** It writes a `.mcp.json` holding a machine-specific absolute path; committed, it breaks the other OS.
- Chat history and Claude's auto-memory stay on the machine that made them. `.agent/AGENTS.md` (loaded through the `.claude/CLAUDE.md` symlink), `docs/`, `project.yaml` and `.project/` carry the context (ROADMAP section 10).

---

## 17. Code skeletons (verified: scratch run)

Copy these verbatim. They compile on 4.7.2 with `untyped_declaration` and the other common warnings set to **error**, and the tests in section 17.13 pass against them.
- "Step N:" comments mark where later steps add code.
- Transient "Identifier not found: Content" (or `GameState`, `SceneRouter`, `Device`) errors are expected until all four autoloads are registered.

### 17.1 `core/game_flow.gd`

```gdscript
@tool
class_name GameFlow
extends RefCounted
## Which phase may follow which, and when the run save is written or deleted (GDD 4.1, 5.11).
## Pure data: tested by tests/test_flow.gd. Only GameState.change_phase() changes the phase.

enum Phase { TITLE, INTRO, BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER, PHASE2_STUB, GAME_OVER }

const TRANSITIONS: Dictionary = {
	Phase.TITLE: [Phase.INTRO, Phase.BACKGROUND_SELECT, Phase.JOB_HUNT, Phase.INTERVIEW, Phase.OFFER],
	Phase.INTRO: [Phase.BACKGROUND_SELECT],
	Phase.BACKGROUND_SELECT: [Phase.JOB_HUNT, Phase.TITLE],
	Phase.JOB_HUNT: [Phase.INTERVIEW, Phase.GAME_OVER, Phase.TITLE],
	Phase.INTERVIEW: [Phase.OFFER, Phase.JOB_HUNT, Phase.TITLE],
	Phase.OFFER: [Phase.PHASE2_STUB, Phase.JOB_HUNT, Phase.TITLE],
	Phase.PHASE2_STUB: [Phase.TITLE, Phase.BACKGROUND_SELECT],
	Phase.GAME_OVER: [Phase.TITLE, Phase.BACKGROUND_SELECT],
}

## A run is "live" only in these phases; they are the only phases ever written to the save.
const SAVED_PHASES: Array[Phase] = [Phase.JOB_HUNT, Phase.INTERVIEW, Phase.OFFER]


static func can_transition(from: Phase, to: Phase) -> bool:
	var allowed: Array = TRANSITIONS.get(from, [])
	return allowed.has(to)


static func is_saved(phase: Phase) -> bool:
	return SAVED_PHASES.has(phase)


## The run is over: Plan B reached, or the player left the Hired card.
static func deletes_save(from: Phase, to: Phase) -> bool:
	return to == Phase.GAME_OVER or from == Phase.PHASE2_STUB


## Continue may only resume a live run that can legally follow TITLE.
static func can_resume(saved: Phase) -> bool:
	return is_saved(saved) and can_transition(Phase.TITLE, saved)
```

### 17.2 `core/run_state.gd`

```gdscript
@tool
class_name RunState
extends RefCounted
## One playthrough (GDD 10.4). EVERY `var` below is saved to JSON automatically by to_dict(),
## so only plain data lives here: String / int / float / bool, Array, Dictionary. Ids are Strings.
## Never store a Resource, a Node or a StringName here.
## Rule methods (spend_energy, sleep, ...) change this object. They never touch autoloads, scenes
## or the global RNG: they take cfg / tier / bg / rng as arguments, so tests and the balance sim
## can run them inside the editor.

const VERSION := 1

# --- flow and RNG ---
var phase: GameFlow.Phase = GameFlow.Phase.TITLE
var rng_seed: String = "0"            # 64-bit RNG values travel as strings (JSON numbers are doubles)
var rng_state: String = "0"
var first_run: bool = true            # the day-2 guarantee (GDD 5.7) only applies to the first run

# --- character (Phase 2 takes this person to work) ---
var background_id: String = ""
var player_name: String = "Alex"
var stats: Dictionary[String, int] = {"knw": 0, "exp": 0, "net": 0}
var lone_wolf: bool = false           # Self-Taught until the first Network (SHOULD)
var gap_topics: Array[String] = []
var commute_pips: int = 0
var commute_minutes: int = 0
var cv_levels: Dictionary[String, String] = {"edu": "honest", "exp": "honest", "proj": "honest"}
var lies_carried: Array[String] = []  # Lie cv-line ids that were sent and never busted or confessed
var confessed: Array[String] = []     # "company_id|cv_line_id": no background check for that pair

# --- day loop ---
var day: int = 1
var energy: int = 0
var rent_days_left: int = 0
var grace_used: bool = false
var referral_tokens: int = 0
var pity_count: int = 0               # Recruiter Radar
var interviews_today: int = 0
var next_uid: int = 1
var board: Array[Dictionary] = []         # {uid, template_id, company_id, tier, posted_days_ago, applicants, is_ghost, reposted}
var applications: Array[Dictionary] = []  # {uid, template_id, company_id, tier, day_sent, reveal_day, p, hits, knockout, is_ghost, referral, tailored, lies, status}
var applied: Array[String] = []           # "template_id|company_id": never dealt again this run
var invites: Array[Dictionary] = []       # {app_uid, company_id, template_id, tier, day_received, kind}
var morning_report: Dictionary = {}       # built by Sleep; the hunt scene shows it, "Start day" clears it
var blacklist: Array[String] = []         # company ids: declined, BUSTED or rescinded
var researched: Array[String] = []        # company ids (SHOULD)
var seen_question_ids: Array[String] = []

# --- interview checkpoint: a resume replays exactly this interview (GDD 5.11) ---
var interview: Dictionary = {}        # {invite_uid, company_id, template_id, tier, seed, question_ids, probe_line, warmup_id, tired}
var interviews_taken: int = 0
var times_met_dana: int = 0
var dana_last_company: String = ""

# --- offer, job, result ---
var offer: Dictionary = {}            # {company_id, template_id, job_title, salary, work_mode, office_days, perks, fine_print, equity_text, negotiated}
var employment: Dictionary = {}       # the accepted offer + tier + red_flags (Phase 2 reads this)
var dream_score: int = -1
var total_applications: int = 0
var total_rejections: int = 0


# ---------- rule methods (examples; more arrive with each feature) ----------

func stat(id: String) -> int:
	return stats.get(id, 0)


func spend_energy(pips: int) -> bool:
	if pips > energy:
		return false
	energy -= pips
	return true


func new_uid() -> int:
	next_uid += 1
	return next_uid - 1


## Night: one Sleep. The morning reveal runs when the next day starts.
func sleep(cfg: BalanceConfig) -> void:
	day += 1
	rent_days_left = maxi(rent_days_left - 1, 0)
	energy = cfg.energy_max - commute_pips
	interviews_today = 0


# ---------- save format ----------

func to_dict() -> Dictionary:
	var d: Dictionary = {"version": VERSION}
	for prop: Dictionary in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[prop["name"]] = get(prop["name"])
	return d


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	# When VERSION changes, migrate `d` here first, e.g. if int(d.get("version", 1)) < 2: ...
	for prop: Dictionary in r.get_property_list():
		var key: String = prop["name"]
		if not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) or not d.has(key):
			continue
		var value: Variant = _whole_floats_to_ints(d[key])
		var current: Variant = r.get(key)
		match typeof(current):
			TYPE_ARRAY:
				(current as Array).assign(value)        # keeps the typed array (Array[String] ...)
			TYPE_DICTIONARY:
				(current as Dictionary).assign(value)
			TYPE_INT:
				r.set(key, int(value))
			TYPE_FLOAT:
				r.set(key, float(value))
			TYPE_BOOL:
				r.set(key, bool(value))
			_:
				r.set(key, str(value))
	return r


## JSON turns every number into a float. Whole numbers become ints again, recursively.
static func _whole_floats_to_ints(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var f: float = v
			if f == floorf(f) and absf(f) < 9.0e15:
				return int(f)
			return f
		TYPE_ARRAY:
			var arr: Array = []
			for e: Variant in v:
				arr.append(_whole_floats_to_ints(e))
			return arr
		TYPE_DICTIONARY:
			var dict: Dictionary = {}
			var src: Dictionary = v
			for k: Variant in src:
				dict[k] = _whole_floats_to_ints(src[k])
			return dict
	return v
```

### 17.3 `core/save_io.gd`

```gdscript
@tool
class_name SaveIO
extends RefCounted
## The one run save: JSON in user:// (app-private on Android and iOS), written to a temp file,
## then renamed, so a crash mid-write never leaves half a save.
## Never load .tres/.res from user://: a resource file can carry a script that runs on load.

const PATH := "user://save_v1.json"


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(path)


static func write(run: RunState, path: String = PATH) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(run.to_dict(), "\t"))
	f.close()
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:  # some platforms refuse to rename over an existing file
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	return err == OK


static func read(path: String = PATH) -> RunState:
	if not exists(path):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_warning("Save file unreadable; ignoring it.")
		return null
	return RunState.from_dict(data)


static func delete(path: String = PATH) -> void:
	if exists(path):
		DirAccess.remove_absolute(path)
```

### 17.4 `core/odds.gd`

```gdscript
@tool
class_name Odds
extends RefCounted
## Every game formula (GDD 5.6-5.9) as static functions. No state, no autoloads, no global RNG:
## anything random takes the run's RandomNumberGenerator. Tested by test_odds / test_interview / test_offer.
## Never call randf(), randi(), Array.shuffle() or Array.pick_random() in gameplay: they use the global RNG.

# ---------- dice ----------

static func roll(rng: RandomNumberGenerator, p: float) -> bool:
	return rng.randf() < p


## n distinct items from pool, in an order decided by this RNG.
static func pick(rng: RandomNumberGenerator, pool: Array, n: int) -> Array:
	var bag := pool.duplicate()
	var out: Array = []
	while out.size() < n and not bag.is_empty():
		out.append(bag.pop_at(rng.randi_range(0, bag.size() - 1)))
	return out


static func shuffled(rng: RandomNumberGenerator, items: Array) -> Array:
	return pick(rng, items, items.size())


# ---------- job hunt (GDD 5.6) ----------

static func tag_hits(posting_tags: PackedStringArray, tags_sent: PackedStringArray) -> int:
	var hits := 0
	for tag: String in posting_tags:
		if tags_sent.has(tag):
			hits += 1
	return hits


static func is_relevant(cfg: BalanceConfig, hits: int) -> bool:
	return hits >= cfg.relevant_min_tags


static func is_knockout(degree_required: bool, min_years: int, cv_has_degree: bool, cv_passes_years: bool, referral: bool) -> bool:
	if referral:
		return false
	return (degree_required and not cv_has_degree) or (min_years > 0 and not cv_passes_years)


## P_invite for one application. hits = matched tags out of the posting's 3 (M = hits / 3).
static func p_invite(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, hits: int, tailored: bool, net: int, referral: bool) -> float:
	var p := tier.base_invite * (cfg.match_base + hits / 3.0)
	p *= cfg.tailor_apply_mult if tailored else cfg.quick_apply_mult
	p *= 1.0 + net / cfg.net_divisor
	p *= bg.invite_mult(tier.id)
	p *= cfg.referral_mult if referral else 1.0
	return clampf(p, cfg.p_invite_min, cfg.p_invite_max)


## 1-5 dots on a card: Long shot, Unlikely, Possible, Decent, Good.
static func odds_band(cfg: BalanceConfig, p: float) -> int:
	var band := 1
	for threshold: float in cfg.band_thresholds:
		if p >= threshold:
			band += 1
	return band


# ---------- interview (GDD 5.8) ----------

static func teamwork_mult(bg: BackgroundData, lone_wolf: bool) -> float:
	return bg.teamwork_mult if lone_wolf else bg.teamwork_mult_after_network


static func is_tired(cfg: BalanceConfig, pips_left_after_paying: int) -> bool:
	return pips_left_after_paying <= cfg.tired_threshold


static func needle_speed(cfg: BalanceConfig, tier: TierData, tired: bool) -> float:
	return tier.needle_speed * (cfg.tired_needle_mult if tired else 1.0)


## P: how well your character knows this question (before luck).
static func knowledge_p(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, knw: int, experience: int, is_tech: bool, weak: bool) -> float:
	var exp_eff := experience + (bg.startup_exp_bonus if tier.id == &"startup" else 0)
	var p: float
	if is_tech:
		p = cfg.tech_knw_w * knw + cfg.tech_exp_w * exp_eff
	else:
		p = cfg.behav_knw_w * knw + cfg.behav_exp_w * exp_eff
	return p - (cfg.weak_penalty if weak else 0.0)


static func roll_luck(cfg: BalanceConfig, rng: RandomNumberGenerator) -> float:
	return rng.randf_range(-cfg.luck_range, cfg.luck_range)


## S, the Stat Score (5-95). question_difficulty is 1, 2 or 3.
static func stat_score(cfg: BalanceConfig, tier: TierData, p: float, question_difficulty: int, luck: float) -> float:
	var d := tier.tier_difficulty + cfg.question_diff_offsets[question_difficulty - 1]
	return clampf(50.0 + cfg.stat_sensitivity * (p - d) + luck, 5.0, 95.0)


## h, the NAILED IT half-width as a fraction of the bar.
static func zone_half(cfg: BalanceConfig, s: float, bonus: float = 0.0) -> float:
	return cfg.zone_half_base + cfg.zone_half_per_s * s / 100.0 + bonus


## I, the input quality from where the needle stopped (tap, center and h are fractions of the bar).
static func input_quality(cfg: BalanceConfig, tap: float, center: float, h: float) -> float:
	var dist := absf(tap - center)
	if dist <= cfg.perfect_frac * h:
		return cfg.input_perfect
	if dist <= h:
		return cfg.input_good
	if dist <= cfg.close_mult * h:
		return cfg.input_close
	return cfg.input_miss


static func answer_q(cfg: BalanceConfig, s: float, input: float) -> float:
	return cfg.q_stat_weight * s + cfg.q_input_scale * input


## Signed change to Doubt (negative = good for you).
static func knowledge_doubt_delta(cfg: BalanceConfig, q: float) -> float:
	return -cfg.doubt_dmg_scale * maxf(0.0, q - cfg.doubt_dmg_floor)


static func knowledge_composure_loss(cfg: BalanceConfig, q: float) -> float:
	return maxf(0.0, cfg.comp_dmg_ceiling - q)


static func spoken_grade(cfg: BalanceConfig, q: float) -> StringName:
	if q >= cfg.green_q_min:
		return &"green"
	if q >= cfg.yellow_q_min:
		return &"yellow"
	return &"red"


## kind: good | neutral | bad | insider.
static func ethics_doubt_delta(cfg: BalanceConfig, kind: StringName, teamwork_question: bool, teamwork: float) -> float:
	match kind:
		&"good":
			return cfg.ethics_good * (teamwork if teamwork_question else 1.0)
		&"neutral":
			return cfg.ethics_neutral
		&"insider":
			return cfg.insider_why_us
		&"bad":
			return cfg.ethics_bad_doubt
	return 0.0


static func ethics_composure_loss(cfg: BalanceConfig, kind: StringName) -> float:
	return cfg.ethics_bad_comp if kind == &"bad" else 0.0


static func committee_eligible(cfg: BalanceConfig, doubt: float, doubt_max: float) -> bool:
	return doubt <= cfg.committee_band * doubt_max


static func committee_win_p(cfg: BalanceConfig, doubt: float, doubt_max: float, net: int) -> float:
	var closeness := 1.0 - doubt / (cfg.committee_band * doubt_max)
	return minf(cfg.committee_cap, cfg.committee_base + cfg.committee_close_bonus * closeness + net / cfg.committee_net_div)


static func bluff_p(cfg: BalanceConfig, tier: TierData, knw: int, experience: int, degree_claim: bool) -> float:
	var p := cfg.bluff_base + (knw - 50) / cfg.bluff_knw_div + (experience - cfg.bluff_exp_ref) / cfg.bluff_exp_div
	p -= tier.bluff_detect + (cfg.bluff_weight_degree if degree_claim else cfg.bluff_weight_lie)
	return clampf(p, cfg.bluff_min, cfg.bluff_max)


# ---------- offer and endings (GDD 5.9) ----------

static func round_to(value: float, step: int) -> int:
	return roundi(value / step) * step


## Yearly salary in whole dollars.
static func offer_salary(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, composure_left: float, composure_max: float) -> int:
	var band_pos := clampf(cfg.band_base + cfg.band_perf_weight * composure_left / composure_max, 0.0, 1.0)
	var raw := lerpf(tier.salary_min_k * 1000.0, tier.salary_max_k * 1000.0, band_pos) * bg.salary_mult
	return round_to(raw, cfg.salary_round)


static func negotiate_p(cfg: BalanceConfig, net: int, other_invite_waiting: bool) -> float:
	return minf(cfg.nego_cap, cfg.nego_base + net / cfg.nego_net_div + (cfg.nego_leverage if other_invite_waiting else 0.0))


static func negotiated_salary(cfg: BalanceConfig, salary: int, rng: RandomNumberGenerator) -> int:
	return round_to(salary * (1.0 + rng.randf_range(cfg.nego_gain_min, cfg.nego_gain_max)), cfg.salary_round)


static func dream_score(cfg: BalanceConfig, salary: int, office_days: int, commute_minutes: int, red_flags: int, rent_days_left: int, runway_days: int) -> int:
	var weekly_commute_h := office_days * 2.0 * commute_minutes / 60.0
	var pts := cfg.dream_w_salary * minf(1.0, float(salary) / cfg.dream_salary_target)
	pts += cfg.dream_w_remote * (5 - office_days) / 5.0
	pts += cfg.dream_w_commute * maxf(0.0, 1.0 - weekly_commute_h / cfg.dream_commute_zero_h)
	pts += maxf(0.0, cfg.dream_w_flags - cfg.dream_flag_penalty * red_flags)
	pts += cfg.dream_w_runway * rent_days_left / float(runway_days)
	return roundi(pts)
```

### 17.5 Resource classes: `data/types/`

`tier_data.gd` (the example Resource class):

```gdscript
@tool
class_name TierData
extends Resource
## One company tier (GDD section 11, owner "T"). Files: res://data/tiers/startup.tres, mid.tres, big.tres.
## All hiring odds live here. Display text lives in data/content/tiers.json under the same id.
## Script defaults = the Mid-size values. Never change a loaded TierData at runtime.

@export var id: StringName = &""              # startup | mid | big (== file name)

@export_group("Board and applications")
@export var base_invite: float = 0.065
@export var ghost_job_rate: float = 0.10
@export var silent_share: float = 0.30
@export var reply_delay_days: int = 2
@export var posted_days_min: int = 1
@export var posted_days_max: int = 14
@export var applicants_min: int = 150
@export var applicants_max: int = 500

@export_group("Interview")
@export var in_person: bool = true
@export var doubt_hp: int = 128
@export var tier_difficulty: int = 42
@export var needle_speed: float = 0.60        # bar-widths per second
@export var zone_jumps: bool = false          # startup "PIVOT!"
@export var lie_probe_chance: float = 0.45
@export var bluff_detect: float = 0.05
@export var background_check: float = 0.30

@export_group("Offer")
@export var salary_min_k: int = 65            # yearly salary, thousands of dollars
@export var salary_max_k: int = 90
@export var office_days: int = 2

@export_group("Phase 2 (stored, unused in the MVP)")
@export var meeting_load: float = 0.5
@export var layoff_risk: float = 0.1
@export var growth_mult: float = 1.0
```

`background_data.gd`:

```gdscript
@tool
class_name BackgroundData
extends Resource
## One playable background = one difficulty (GDD section 11, owner "BG").
## Files: res://data/backgrounds/intern.tres, graduate.tres, self_taught.tres.
## Script defaults = the Graduate values. Text lives in data/content/backgrounds.json.

@export var id: StringName = &""              # intern | graduate | self_taught (== file name)

@export_group("Stats")
@export var start_knw: int = 55
@export var start_exp: int = 15
@export var start_net: int = 15
@export var teamwork_mult: float = 1.0
@export var teamwork_mult_after_network: float = 1.0
@export var gap_topics_count: int = 0

@export_group("Day loop")
@export var commute_pips: int = 2
@export var commute_minutes: int = 45
@export var runway_days: int = 12
@export var interview_travel_pips: int = 0

@export_group("Applications")
@export var invite_mult_big: float = 1.2
@export var invite_mult_mid: float = 1.0
@export var invite_mult_startup: float = 1.0
@export var referral_tokens: int = 0
@export var pity_n: int = 8
@export var has_degree_honest: bool = true   # must match cv_lines.json (content_lint checks it)
@export var years_pass_honest: bool = false

@export_group("Interview")
@export var composure_max: int = 100
@export var startup_exp_bonus: int = 0
@export var textbook_zone_bonus: float = 0.04

@export_group("Offer")
@export var salary_mult: float = 1.0


func invite_mult(tier_id: StringName) -> float:
	match tier_id:
		&"big":
			return invite_mult_big
		&"startup":
			return invite_mult_startup
	return invite_mult_mid
```

`balance_config.gd`:

```gdscript
@tool
class_name BalanceConfig
extends Resource
## Global tuning constants (GDD section 11, owner "B"). One file: res://data/balance/balance_config.tres.
## These defaults ARE the GDD defaults. Tune the .tres in the Inspector; leave these lines alone
## (the formula tests build BalanceConfig.new() and expect the GDD numbers).

@export_group("Energy, time, board (11.1)")
@export var energy_max: int = 10
@export var rent_warning_days: int = 3
@export var cost_quick_apply: int = 1
@export var cost_tailor_apply: int = 2
@export var cost_research: int = 1
@export var cost_study: int = 2
@export var cost_network: int = 2
@export var cost_interview: int = 3
@export var tired_threshold: int = 2
@export var tired_needle_mult: float = 1.15
@export var max_interviews_per_day: int = 1
@export var invite_valid_days: int = 2
@export var board_new_per_day: int = 6
@export var board_max: int = 10
@export var ghost_posted_days_min: int = 60
@export var ghost_posted_days_max: int = 500
@export var full_scan_animations: int = 3

@export_group("Stats and growth (11.2)")
@export var stat_cap: int = 80
@export var study_knw_gain: int = 5
@export var network_net_gain: int = 5
@export var network_ref_base: float = 0.35
@export var network_ref_net_div: float = 200.0

@export_group("Applications and responses (11.3)")
@export var match_base: float = 0.5
@export var quick_apply_mult: float = 0.6
@export var tailor_apply_mult: float = 1.5
@export var referral_mult: float = 2.5
@export var net_divisor: float = 100.0
@export var p_invite_min: float = 0.01
@export var p_invite_max: float = 0.60
@export var relevant_min_tags: int = 2
@export var knockout_reply_delay_days: int = 1
@export var ghosted_after_days: int = 7
@export var day2_guarantee_min_apps: int = 3
@export var band_thresholds: PackedFloat32Array = PackedFloat32Array([0.03, 0.07, 0.12, 0.20])
@export var site_megaboard_ghost_add: float = 0.05
@export var site_humblebrag_invite_mult: float = 1.1

@export_group("Interview (11.4)")
@export var prompt_pattern: PackedStringArray = PackedStringArray(["choice", "knowledge", "knowledge", "knowledge", "choice"])
@export var question_diff_offsets: PackedInt32Array = PackedInt32Array([-5, 0, 5])
@export var stat_sensitivity: float = 0.7
@export var luck_range: float = 12.0
@export var weak_penalty: float = 15.0
@export var tech_knw_w: float = 0.7
@export var tech_exp_w: float = 0.3
@export var behav_knw_w: float = 0.3
@export var behav_exp_w: float = 0.7
@export var zone_half_base: float = 0.06
@export var zone_half_per_s: float = 0.12
@export var perfect_frac: float = 0.4
@export var close_mult: float = 2.0
@export var input_perfect: float = 1.0
@export var input_good: float = 0.8
@export var input_close: float = 0.5
@export var input_miss: float = 0.2
@export var relaxed_input: float = 0.9
@export var q_stat_weight: float = 0.75
@export var q_input_scale: float = 25.0
@export var jump_window_min_s: float = 1.0
@export var jump_window_max_s: float = 2.5
@export var max_round_trips: int = 3
@export var answer_meter_width_px: int = 200
@export var doubt_dmg_scale: float = 0.9
@export var doubt_dmg_floor: float = 30.0
@export var comp_dmg_ceiling: float = 50.0
@export var green_q_min: float = 60.0
@export var yellow_q_min: float = 45.0
@export var ethics_good: float = -10.0        # Doubt change (negative = Doubt goes down = good for you)
@export var ethics_neutral: float = -4.0
@export var ethics_bad_doubt: float = 8.0
@export var ethics_bad_comp: float = 15.0     # Composure lost
@export var insider_why_us: float = -18.0
@export var committee_band: float = 0.15
@export var committee_base: float = 0.40
@export var committee_close_bonus: float = 0.20
@export var committee_net_div: float = 200.0
@export var committee_cap: float = 0.85
@export var input_lock_ms: int = 250
@export var vs_duration_s: float = 2.0
@export var vs_min_view_s: float = 1.0
@export var typewriter_cps: float = 40.0

@export_group("Lying (11.5)")
@export var max_probes_per_interview: int = 1
@export var bluff_base: float = 0.50
@export var bluff_knw_div: float = 200.0
@export var bluff_exp_ref: float = 20.0
@export var bluff_exp_div: float = 200.0
@export var bluff_weight_lie: float = 0.10
@export var bluff_weight_degree: float = 0.20
@export var bluff_min: float = 0.10
@export var bluff_max: float = 0.80
@export var bluff_win_doubt: float = -15.0
@export var busted_doubt: float = 20.0
@export var busted_comp: float = 30.0
@export var come_clean_doubt: float = -5.0
@export var come_clean_comp: float = 10.0

@export_group("Offer and endings (11.6)")
@export var band_base: float = 0.25
@export var band_perf_weight: float = 0.50
@export var salary_round: int = 1000
@export var nego_base: float = 0.55
@export var nego_net_div: float = 200.0
@export var nego_leverage: float = 0.15
@export var nego_cap: float = 0.85
@export var nego_gain_min: float = 0.05
@export var nego_gain_max: float = 0.08
@export var dream_salary_target: int = 150000
@export var dream_w_salary: float = 40.0      # GDD "dream_weights" 40 / 25 / 15 / 10 / 10
@export var dream_w_remote: float = 25.0
@export var dream_w_commute: float = 15.0
@export var dream_w_flags: float = 10.0
@export var dream_w_runway: float = 10.0
@export var dream_commute_zero_h: float = 10.0
@export var dream_flag_penalty: float = 5.0
@export var grace_day: bool = true
```

### 17.6 `autoload/content.gd` (autoload `Content`)

```gdscript
extends Node
## Autoload "Content": read-only registry of static data (GDD 5.0).
##   Numbers you tune (.tres): Content.balance, Content.background(id), Content.tier(id)
##   Text keyed by id (JSON):  Content.entry("companies", "co_beigeware"), Content.text("barks", "ui_apply")
## Never modify what it returns: loaded Resources are cached and shared by the whole game.
## Missing files only warn, so the game runs before the data exists (Step 1-3).

const BALANCE_PATH := "res://data/balance/balance_config.tres"
const JSON_FILES: PackedStringArray = [
	"naming", "backgrounds", "tiers", "companies", "postings", "cv_lines",
	"questions_choice", "questions_knowledge", "barks", "emails", "tips",
	"endings", "events", "cutscene", "names", "news",
]

var balance: BalanceConfig
var _backgrounds: Dictionary[StringName, BackgroundData] = {}
var _tiers: Dictionary[StringName, TierData] = {}
var _json: Dictionary[String, Dictionary] = {}   # file name -> { id -> entry }


func _ready() -> void:
	balance = load(BALANCE_PATH) if ResourceLoader.exists(BALANCE_PATH) else BalanceConfig.new()
	for res: Resource in load_tres_dir("res://data/backgrounds/"):
		var bg := res as BackgroundData
		if bg != null:
			_backgrounds[bg.id] = bg
	for res: Resource in load_tres_dir("res://data/tiers/"):
		var tier_data := res as TierData
		if tier_data != null:
			_tiers[tier_data.id] = tier_data
	for file: String in JSON_FILES:
		_json[file] = load_json("res://data/content/%s.json" % file)
	print("Content: %d backgrounds, %d tiers, %d/%d JSON files" % [
		_backgrounds.size(), _tiers.size(), _json.values().filter(func(d: Dictionary) -> bool: return not d.is_empty()).size(), JSON_FILES.size()])


func background(id: StringName) -> BackgroundData:
	return _backgrounds.get(id)


func tier(id: StringName) -> TierData:
	return _tiers.get(id)


func entries(file: String) -> Dictionary:
	return _json.get(file, {})


func entry(file: String, id: String) -> Variant:
	return entries(file).get(id)


## Display text for an id: translated with tr(), {placeholders} filled from args.
func text(file: String, id: String, args: Dictionary = {}) -> String:
	var e: Variant = entry(file, id)
	if e == null:
		push_warning("Content: missing text %s/%s" % [file, id])
		return id
	var raw: String = e if e is String else str((e as Dictionary).get("text", id))
	return tr(raw).format(args)


## One text field of a structured entry, e.g. field("questions_knowledge", "kq_hash_map", "prompt").
func field(file: String, id: String, key: String, args: Dictionary = {}) -> String:
	var e: Variant = entry(file, id)
	if not (e is Dictionary) or not (e as Dictionary).has(key):
		push_warning("Content: missing %s/%s.%s" % [file, id, key])
		return id
	return tr(str(e[key])).format(args)


static func load_tres_dir(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for file: String in ResourceLoader.list_directory(dir):  # original names, also in exported builds
		if file.ends_with(".tres"):
			var res := load(dir + file)
			if res != null:
				out.append(res)
	return out


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_error("Content: %s must be one JSON object keyed by id" % path)
		return {}
	return data
```

### 17.7 `autoload/game_state.gd` (autoload `GameState`)

```gdscript
extends Node
## Autoload "GameState" (no class_name: it would clash with the autoload name).
## Owns the RunState, the run's RNG, the phase and the settings file.
## Scenes read `run` and call verbs. Only change_phase() changes the phase.
## Every verb that commits a player action ends with _commit() (save + HUD refresh).

signal phase_changed(from: GameFlow.Phase, to: GameFlow.Phase)
signal run_changed   # energy, rent, stats, board... changed: refresh the HUD

const SETTINGS_PATH := "user://settings.cfg"

var run: RunState = RunState.new()
var rng := RandomNumberGenerator.new()
var settings := ConfigFile.new()
var preselect_background: String = ""   # set by retry(): Background select focuses this card


func _ready() -> void:
	settings.load(SETTINGS_PATH)  # a missing file just means defaults


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save()
			if run.phase == GameFlow.Phase.INTERVIEW:
				get_tree().paused = true  # interview.gd shows "Ready? Tap to continue", then unpauses
		NOTIFICATION_WM_CLOSE_REQUEST:
			save()


# ---------- settings (meta + options; never part of the run) ----------

func setting(section: String, key: String, default: Variant) -> Variant:
	return settings.get_value(section, key, default)


func set_setting(section: String, key: String, value: Variant) -> void:
	settings.set_value(section, key, value)
	settings.save(SETTINGS_PATH)


# ---------- saving ----------

## Writes only while a run is live (JOB_HUNT / INTERVIEW / OFFER); a no-op otherwise.
func save() -> void:
	if not GameFlow.is_saved(run.phase):
		return
	run.rng_state = str(rng.state)
	SaveIO.write(run)


func _commit() -> void:
	save()
	run_changed.emit()


# ---------- flow ----------

func change_phase(to: GameFlow.Phase) -> void:
	var from := run.phase
	if not GameFlow.can_transition(from, to):
		push_error("Illegal phase change %s -> %s" % [GameFlow.Phase.find_key(from), GameFlow.Phase.find_key(to)])
		return
	run.phase = to
	if GameFlow.deletes_save(from, to):
		SaveIO.delete()
	save()
	phase_changed.emit(from, to)


func start_new_game() -> void:  # Title: "Tap to start"
	run = RunState.new()
	var intro_seen: bool = setting("meta", "intro_seen", false)
	change_phase(GameFlow.Phase.BACKGROUND_SELECT if intro_seen else GameFlow.Phase.INTRO)


func replay_intro() -> void:  # Title: "Replay intro"
	run = RunState.new()
	change_phase(GameFlow.Phase.INTRO)


func finish_intro() -> void:  # the intro ended, or Skip, or Android Back
	set_setting("meta", "intro_seen", true)
	change_phase(GameFlow.Phase.BACKGROUND_SELECT)


func continue_game() -> void:
	var loaded := SaveIO.read()
	if loaded == null or not GameFlow.can_resume(loaded.phase):
		start_new_game()  # never leave Continue dead
		return
	var resume_at := loaded.phase
	run = loaded
	run.phase = GameFlow.Phase.TITLE
	rng.seed = run.rng_seed.to_int()   # seed first: setting seed resets state
	rng.state = run.rng_state.to_int()
	change_phase(resume_at)


## Plan B "Retry" and Hired "New run": a brand-new RunState, same background preselected.
func retry() -> void:
	var from := run.phase
	preselect_background = run.background_id
	run = RunState.new()
	run.phase = from  # keeps the transition legal; leaving PHASE2_STUB deletes the save
	change_phase(GameFlow.Phase.BACKGROUND_SELECT)


## Pause "Quit to title", Background select Back, ending "Title". The save survives for Continue.
func quit_to_title() -> void:
	change_phase(GameFlow.Phase.TITLE)


func choose_background(bg_id: String, player_name: String, run_seed: int = 0) -> void:
	_init_run(bg_id, player_name, run_seed if run_seed != 0 else randi())  # the global RNG only picks the seed
	change_phase(GameFlow.Phase.JOB_HUNT)


## Debug only: set a run up in place so `project_run mode="custom"` can launch one feature scene.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched.
func debug_quick_start(bg_id: String, phase: GameFlow.Phase, run_seed: int = 20260926) -> void:
	run = RunState.new()
	_init_run(bg_id, "Alex", run_seed)
	run.phase = phase


func _init_run(bg_id: String, player_name: String, run_seed: int) -> void:
	var bg := Content.background(bg_id)
	var cfg := Content.balance
	rng.seed = run_seed
	run.rng_seed = str(run_seed)
	run.background_id = bg_id
	run.player_name = player_name
	run.stats.assign({"knw": bg.start_knw, "exp": bg.start_exp, "net": bg.start_net})
	run.commute_pips = bg.commute_pips
	run.commute_minutes = bg.commute_minutes
	run.energy = cfg.energy_max - bg.commute_pips
	run.rent_days_left = bg.runway_days
	run.referral_tokens = bg.referral_tokens
	run.lone_wolf = bg.teamwork_mult < bg.teamwork_mult_after_network
	var gap_pool: Array = Content.entries("naming").get("_gap_topic_pool", [])
	run.gap_topics.assign(Odds.pick(rng, gap_pool, bg.gap_topics_count))
	run.first_run = int(setting("meta", "run_count", 0)) == 0


# ---------- job hunt verbs (Step 5 fills these in; each ends with _commit()) ----------

func study() -> bool:
	var cfg := Content.balance
	if not run.spend_energy(cfg.cost_study):
		return false
	run.stats["knw"] = mini(run.stats["knw"] + cfg.study_knw_gain, cfg.stat_cap)
	_commit()
	return true


## Night tick + (Step 5) morning reveal and board refill into run.morning_report: ONE commit,
## so a kill between "night" and "morning" can't lose or repeat the reveal.
func sleep() -> void:
	run.sleep(Content.balance)
	_commit()


# ---------- interview ----------

## Inbox "GO NOW": pay energy, freeze the interview (seed + questions), go.
func start_interview(invite: Dictionary) -> void:
	var cfg := Content.balance
	var tier_data := Content.tier(invite["tier"])
	var bg := Content.background(run.background_id)
	var cost := cfg.cost_interview + (bg.interview_travel_pips if tier_data.in_person else 0)
	if run.interviews_today >= cfg.max_interviews_per_day or not run.spend_energy(cost):
		return
	run.interviews_today += 1
	run.interview = {
		"invite_uid": invite["app_uid"], "company_id": invite["company_id"],
		"template_id": invite["template_id"], "tier": invite["tier"],
		"seed": str(rng.randi()), "tired": Odds.is_tired(cfg, run.energy),
		"question_ids": [],  # Step 4: pick from the tier's pools minus run.seen_question_ids
		"probe_line": "",    # Step 4: lie-probe roll (GDD 5.8.5)
	}
	change_phase(GameFlow.Phase.INTERVIEW)  # saves the checkpoint


## won = K.O. or committee win. busted = the lie probe ended in BUSTED (company blacklisted).
func finish_interview(won: bool, composure_left: float, busted: bool = false) -> void:
	var iv := run.interview
	var company_id: String = iv.get("company_id", "")
	run.interviews_taken += 1
	run.times_met_dana += 1
	run.dana_last_company = company_id
	if busted:
		run.blacklist.append(company_id)
	if won:
		var tier_data := Content.tier(iv["tier"])
		var bg := Content.background(run.background_id)
		run.offer = {
			"company_id": company_id, "template_id": iv["template_id"], "tier": iv["tier"],
			"salary": Odds.offer_salary(Content.balance, tier_data, bg, composure_left, bg.composure_max),
			"office_days": tier_data.office_days, "negotiated": false,
			# Step 6: job_title, perks, fine_print, equity_text (picked with the interview's RNG)
		}
	run.interview = {}
	change_phase(GameFlow.Phase.OFFER if won else GameFlow.Phase.JOB_HUNT)


# ---------- offer and endings ----------

func answer_offer(accept: bool) -> void:
	var company_id: String = run.offer.get("company_id", "")
	if not accept:  # Decline (after the confirm dialog): blacklisted, back to the same day
		run.blacklist.append(company_id)
		run.offer = {}
		change_phase(GameFlow.Phase.JOB_HUNT)
		return
	# Step 6/8: an unconfessed degree-claim Lie rolls tier.background_check here -> rescinded -> JOB_HUNT.
	var bg := Content.background(run.background_id)
	var flags: Array = Content.entries("companies").get(company_id, {}).get("red_flags", [])
	run.employment = run.offer.duplicate(true)
	run.dream_score = Odds.dream_score(Content.balance, run.offer["salary"], run.offer["office_days"],
		run.commute_minutes, flags.size(), run.rent_days_left, bg.runway_days)
	_count_finished_run()
	change_phase(GameFlow.Phase.PHASE2_STUB)


## Morning with rent at 0, no invite, grace day used (or none waiting).
func end_run_plan_b() -> void:
	_count_finished_run()
	change_phase(GameFlow.Phase.GAME_OVER)


func _count_finished_run() -> void:
	set_setting("meta", "run_count", int(setting("meta", "run_count", 0)) + 1)
```

### 17.8 `autoload/device.gd` (autoload `Device`)

```gdscript
extends Node
## Autoload "Device": phone glue. Scale guard (GDD 2.2), safe area (2.9), Back button (4.4), haptics (9.3).

signal layout_changed    # game-area size or scale mode changed: SafeAreaMargin re-applies
signal back_unhandled    # Back pressed and the current scene didn't use it: Title shows "Quit?"

var haptics_enabled: bool = true
## Base resolution (GDD 2.2: 270x480 portrait), read from Project Settings so the two never disagree.
var _base := Vector2(
	int(ProjectSettings.get_setting("display/window/size/viewport_width")),
	int(ProjectSettings.get_setting("display/window/size/viewport_height")))
var _last_window_size := Vector2i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	haptics_enabled = bool(GameState.setting("options", "haptics", true))
	_check_window()


## size_changed doesn't always fire on desktop resizes, so compare every frame (one Vector2i compare).
func _process(_delta: float) -> void:
	_check_window()


func _check_window() -> void:
	var now := get_tree().root.size
	if now != _last_window_size:
		_last_window_size = now
		_update_scale_mode()


## Square pixels that fill the screen: integer scale, and the game area grows to use the leftover.
## Falls back to fractional when integer would waste over 20% (720p-class phones). Tech-verified.
func _update_scale_mode() -> void:
	var win := get_tree().root
	var w := Vector2(win.size)
	if w.x <= 0.0 or w.y <= 0.0:
		return
	var exact := minf(w.x / _base.x, w.y / _base.y)
	var s := floorf(exact)
	var stretch := Window.CONTENT_SCALE_STRETCH_INTEGER
	var game_size := Vector2i(_base)
	if s >= 1.0 and s / exact >= 0.8:
		game_size = Vector2i(floori(w.x / s), floori(w.y / s))  # 1179x2556 (iPhone 15) -> 294x639 @4x
	else:
		stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL       # 720x1600 -> 270x600 @2.67x
	if win.content_scale_stretch != stretch or win.content_scale_size != game_size:
		win.content_scale_stretch = stretch
		win.content_scale_size = game_size
		layout_changed.emit()


## Safe-area insets in GAME pixels (left, top, right, bottom); zero on desktop.
## In viewport stretch mode get_final_transform() is the identity, so convert by hand (tech-verified).
func safe_insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var win := get_tree().root
	var game := win.get_visible_rect().size
	var px := Vector2(win.size)
	var s := minf(px.x / game.x, px.y / game.y)
	if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER:
		s = maxf(floorf(s), 1.0)
	var origin := ((px - game * s) * 0.5).round()  # letterbox offset
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var tl := (safe.position - origin) / s
	var br := (safe.end - origin) / s
	return Vector4(maxf(tl.x, 0.0), maxf(tl.y, 0.0), maxf(game.x - br.x, 0.0), maxf(game.y - br.y, 0.0))


# ---------- Back ----------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android Back (needs quit_on_go_back = false)
		handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.has_feature("mobile") and event.is_action_pressed(&"ui_cancel"):  # Esc = Back on desktop
		get_viewport().set_input_as_handled()
		handle_back()


## The current scene gets the first chance: close a modal, flip a card back, skip the cutscene, open pause.
func handle_back() -> void:
	if SceneRouter.busy:
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method(&"handle_back") and bool(scene.call(&"handle_back")):
		return
	back_unhandled.emit()


# ---------- haptics ----------

func haptic(ms: int = 10) -> void:
	if haptics_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)  # Android: enable permissions/vibrate in the export preset
```

### 17.9 `autoload/scene_router.gd` (autoload `SceneRouter`)

```gdscript
extends CanvasLayer
## Autoload "SceneRouter": swaps scenes behind a fade whenever GameState's phase changes.
## Scenes never call change_scene_*() themselves.

signal transition_finished(phase: GameFlow.Phase)

const FADE_SEC := 0.2
const SCENES: Dictionary = {
	GameFlow.Phase.TITLE: "res://features/title/title.tscn",
	GameFlow.Phase.INTRO: "res://features/intro/intro.tscn",
	GameFlow.Phase.BACKGROUND_SELECT: "res://features/background_select/background_select.tscn",
	GameFlow.Phase.JOB_HUNT: "res://features/job_hunt/job_hunt.tscn",
	GameFlow.Phase.INTERVIEW: "res://features/interview/interview.tscn",
	GameFlow.Phase.OFFER: "res://features/offer/offer.tscn",
	GameFlow.Phase.PHASE2_STUB: "res://features/phase2_stub/phase2_stub.tscn",
	GameFlow.Phase.GAME_OVER: "res://features/game_over/game_over.tscn",
}

var busy: bool = false
var _curtain := ColorRect.new()
var _queued: int = -1


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain.color = Color(0.07, 0.07, 0.1)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE  # an invisible rect still eats taps unless IGNORE
	_curtain.modulate.a = 0.0
	add_child(_curtain)
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(_from: GameFlow.Phase, to: GameFlow.Phase) -> void:
	go_to(to)


func go_to(phase: GameFlow.Phase) -> void:
	if busy:
		_queued = phase  # the last request wins
		return
	var path: String = SCENES.get(phase, "")
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: no scene for %s at '%s'" % [GameFlow.Phase.find_key(phase), path])
		return
	busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP  # no double taps during the fade
	ResourceLoader.load_threaded_request(path)         # loads while the screen fades out
	await _fade_to(1.0)
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().paused = false
	get_tree().change_scene_to_packed(packed)
	await get_tree().scene_changed
	await _fade_to(0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	transition_finished.emit(phase)
	if _queued != -1:
		var next := _queued as GameFlow.Phase
		_queued = -1
		go_to(next)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_curtain, "modulate:a", alpha, FADE_SEC)
	await tween.finished
```

### 17.10 `ui/components/safe_area_margin.gd`

```gdscript
class_name SafeAreaMargin
extends MarginContainer
## Put every tappable thing inside one of these; keep backgrounds outside it (full-bleed).
## Portrait: the Dynamic Island / notch is the top inset, the home indicator the bottom one.
## Left and right use the larger inset on both sides, in case a device reports asymmetric insets.

@export var min_margin: int = 4
@export var debug_fake_insets := Vector4i.ZERO  # game px (left, top, right, bottom): preview a notch on desktop


func _ready() -> void:
	Device.layout_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var inset := Vector4(debug_fake_insets) if debug_fake_insets != Vector4i.ZERO else Device.safe_insets()
	var side := maxi(ceili(maxf(inset.x, inset.z)), min_margin)
	add_theme_constant_override(&"margin_left", side)
	add_theme_constant_override(&"margin_right", side)
	add_theme_constant_override(&"margin_top", maxi(ceili(inset.y), min_margin))
	add_theme_constant_override(&"margin_bottom", maxi(ceili(inset.w), min_margin))
```

### 17.11 `features/interview/answer_meter.gd` (Step 4)

```gdscript
class_name AnswerMeter
extends Control
## The one-tap "stop the needle" Answer Meter (GDD 5.8.4). Called TimingBar in earlier drafts.
## Make it cover the whole screen (full rect) so a tap anywhere counts; it draws the bar 40 px above
## its bottom edge (Step 4 moves it to the S08 meter row, section 11.6). Positions are fractions of the bar (0..1). The scene adds the zone labels.

signal resolved(input_quality: float)
signal zone_jumped  # startup "PIVOT!"

const BAR_HEIGHT := 10.0

var _cfg: BalanceConfig
var _speed := 0.6        # bar-widths per second (TierData.needle_speed, x1.15 when Tired)
var _h := 0.1            # NAILED IT half-width
var _c := 0.5            # zone centre
var _t := 0.0            # distance travelled, in bar-widths
var _elapsed := 0.0
var _jump_at := -1.0     # seconds; negative = no pivot
var _relaxed := false
var _done := true
var _rng: RandomNumberGenerator


func _ready() -> void:
	set_process(false)  # tech-verified: _process would otherwise run (and auto-miss) before start()
	mouse_filter = Control.MOUSE_FILTER_STOP


func start(cfg: BalanceConfig, speed: float, half_width: float, zone_jumps: bool, relaxed: bool, rng: RandomNumberGenerator) -> void:
	_cfg = cfg
	_speed = speed
	_h = half_width
	_relaxed = relaxed
	_rng = rng
	_c = rng.randf_range(_h, 1.0 - _h)
	_jump_at = rng.randf_range(cfg.jump_window_min_s, cfg.jump_window_max_s) if zone_jumps else -1.0
	_t = 0.0
	_elapsed = 0.0
	_done = false
	set_process(true)
	queue_redraw()


func needle() -> float:
	return pingpong(_t, 1.0)


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	_t += delta * _speed
	if _jump_at >= 0.0 and _elapsed >= _jump_at:
		_jump_at = -1.0
		_c = _rng.randf_range(_h, 1.0 - _h)
		zone_jumped.emit()
	if _t >= 2.0 * _cfg.max_round_trips:  # one round trip = there and back = 2 bar-widths
		_resolve(-1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _done:
		return
	accept_event()
	if _elapsed * 1000.0 >= _cfg.input_lock_ms:  # the tap that finished Dana's line can't stop the needle
		_resolve(needle())


func _resolve(tap: float) -> void:
	_done = true
	set_process(false)
	var q := _cfg.input_miss if tap < 0.0 else Odds.input_quality(_cfg, tap, _c, _h)
	if _relaxed:
		q = _cfg.relaxed_input  # Relaxed Timing setting: always 0.9
	Device.haptic(20 if q >= _cfg.input_perfect else 10)
	resolved.emit(q)


func _draw() -> void:
	if _cfg == null:
		return
	var w := float(_cfg.answer_meter_width_px)
	var origin := Vector2(floorf((size.x - w) * 0.5), floorf(size.y - 40.0))
	draw_rect(Rect2(origin, Vector2(w, BAR_HEIGHT)), Color("#1d2b53"))                                        # Rambling / Overthinking
	draw_rect(Rect2(origin + Vector2(floorf((_c - 2.0 * _h) * w), 0), Vector2(floorf(4.0 * _h * w), BAR_HEIGHT)), Color("#ffa300"))  # Vague
	draw_rect(Rect2(origin + Vector2(floorf((_c - _h) * w), 0), Vector2(floorf(2.0 * _h * w), BAR_HEIGHT)), Color("#00e436"))        # NAILED IT
	draw_rect(Rect2(origin + Vector2(floorf(needle() * w) - 1.0, -3.0), Vector2(2.0, BAR_HEIGHT + 6.0)), Color.WHITE)
```

### 17.12 `features/title/title.gd` (the Step 1 boot stub)

The scene `features/title/title.tscn` has a root `Title` (Control, full rect) with this script. It has one child, `Info` (a Label with a unique name, at 8,8).

```gdscript
extends Control
## Step 1 stub of the Title screen (GDD S01): proves settings, autoloads and the scale guard.
## Resize the desktop window and watch "game" change. Replaced by the real Title in Step 3.

@onready var _info: Label = %Info


func _process(_delta: float) -> void:
	var win := get_tree().root
	var mode := "integer" if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER else "fractional"
	_info.text = "SWE Simulator %s\nwindow %s\ngame %s (%s)\nsave file: %s" % [
		ProjectSettings.get_setting("application/config/version"), win.size,
		Vector2i(win.get_visible_rect().size), mode, SaveIO.exists()]


func handle_back() -> bool:
	return false  # nothing to close here: Device emits back_unhandled (the "Quit?" dialog arrives in Step 3)
```

Expected output in the 540x960 desktop window: `window (540, 960)` / `game (270, 480) (integer)` (checked live on 2026-09-26, with no runtime errors), then `save file: false` until a run is saved.

### 17.13 Tests: `tests/`

`test_flow.gd`:

```gdscript
@tool
extends McpTestSuite
## GameFlow transitions (GDD 4.1) and the save policy (GDD 5.11). Editor-side: no autoloads.

const LEGAL: Array[Array] = [
	[GameFlow.Phase.TITLE, GameFlow.Phase.INTRO],
	[GameFlow.Phase.TITLE, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.TITLE, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.TITLE, GameFlow.Phase.INTERVIEW],
	[GameFlow.Phase.TITLE, GameFlow.Phase.OFFER],
	[GameFlow.Phase.INTRO, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.BACKGROUND_SELECT, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB],
	[GameFlow.Phase.OFFER, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE],
	[GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.TITLE],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.BACKGROUND_SELECT],
	# Back / pause "Quit to title" (the save survives):
	[GameFlow.Phase.BACKGROUND_SELECT, GameFlow.Phase.TITLE],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.TITLE],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.TITLE],
	[GameFlow.Phase.OFFER, GameFlow.Phase.TITLE],
]

const ILLEGAL: Array[Array] = [
	[GameFlow.Phase.TITLE, GameFlow.Phase.TITLE],
	[GameFlow.Phase.TITLE, GameFlow.Phase.PHASE2_STUB],
	[GameFlow.Phase.TITLE, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.INTRO, GameFlow.Phase.OFFER],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.OFFER],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.JOB_HUNT],
]


func suite_name() -> String:
	return "flow"


func test_required_transitions_are_legal() -> void:
	for pair: Array in LEGAL:
		assert_true(GameFlow.can_transition(pair[0], pair[1]),
			"%s -> %s should be legal" % [GameFlow.Phase.find_key(pair[0]), GameFlow.Phase.find_key(pair[1])])


func test_illegal_jumps_are_blocked() -> void:
	for pair: Array in ILLEGAL:
		assert_false(GameFlow.can_transition(pair[0], pair[1]),
			"%s -> %s should be illegal" % [GameFlow.Phase.find_key(pair[0]), GameFlow.Phase.find_key(pair[1])])


func test_only_live_run_phases_are_saved() -> void:
	for phase: int in GameFlow.Phase.values():
		var live := phase in [GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER]
		assert_eq(GameFlow.is_saved(phase), live, "is_saved(%s)" % GameFlow.Phase.find_key(phase))


func test_save_deleted_on_plan_b_and_after_hired() -> void:
	assert_true(GameFlow.deletes_save(GameFlow.Phase.JOB_HUNT, GameFlow.Phase.GAME_OVER))
	assert_true(GameFlow.deletes_save(GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE))
	assert_true(GameFlow.deletes_save(GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT))
	assert_false(GameFlow.deletes_save(GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB), "killed on the Hired card: Continue still works")
	assert_false(GameFlow.deletes_save(GameFlow.Phase.JOB_HUNT, GameFlow.Phase.TITLE), "Quit to title keeps the run")


func test_continue_only_resumes_live_runs() -> void:
	for phase: int in GameFlow.Phase.values():
		var live := phase in [GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER]
		assert_eq(GameFlow.can_resume(phase), live, "can_resume(%s)" % GameFlow.Phase.find_key(phase))


func test_fresh_run_state_is_empty() -> void:  # retry() builds exactly this
	var r := RunState.new()
	assert_eq(r.phase, GameFlow.Phase.TITLE)
	assert_eq(r.day, 1)
	assert_eq(r.pity_count, 0)
	assert_true(r.applied.is_empty() and r.applications.is_empty() and r.blacklist.is_empty())
	assert_true(r.interview.is_empty() and r.offer.is_empty())
```

`test_save.gd`:

```gdscript
@tool
extends McpTestSuite
## RunState <-> JSON round trip (GDD 5.11). Never writes to user:// (in the editor that is the real save folder).

func suite_name() -> String:
	return "save"


func _round_trip(r: RunState) -> RunState:
	return RunState.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))


func test_round_trip_keeps_every_kind_of_field() -> void:
	var r := RunState.new()
	r.phase = GameFlow.Phase.INTERVIEW
	r.background_id = "self_taught"
	r.stats["knw"] = 60
	r.gap_topics.assign(["web", "security"])
	r.cv_levels["exp"] = "lie"
	r.applications.append({"uid": 7, "tier": "mid", "reveal_day": 3, "p": 0.168, "knockout": false})
	r.interview = {"seed": "3141592653", "question_ids": ["kq_hash_map", "kq_left_join"]}
	var back := _round_trip(r)
	assert_eq(back.phase, GameFlow.Phase.INTERVIEW)
	assert_eq(back.background_id, "self_taught")
	assert_eq(back.stats["knw"], 60)
	assert_eq(back.gap_topics, r.gap_topics)
	assert_eq(back.cv_levels["exp"], "lie")
	assert_eq(typeof(back.applications[0]["reveal_day"]), TYPE_INT, "whole JSON numbers come back as ints")
	assert_eq(back.applications[0]["p"], 0.168)
	assert_eq(back.interview["question_ids"], ["kq_hash_map", "kq_left_join"])


func test_64bit_rng_state_survives_json() -> void:
	var r := RunState.new()
	r.rng_state = str(9007199254740993)  # 2^53 + 1: a JSON number would corrupt it
	var back := _round_trip(r)
	assert_eq(back.rng_state.to_int(), 9007199254740993)
	r.rng_state = str(-4611686018427387905)
	assert_eq(_round_trip(r).rng_state.to_int(), -4611686018427387905, "negative states too")


func test_seed_then_state_replays_the_same_dice() -> void:
	var a := RandomNumberGenerator.new()
	a.seed = 20260926
	for _i: int in 5:
		a.randi()
	var saved_seed := str(a.seed)
	var saved_state := str(a.state)
	var expected := [a.randi(), a.randi(), a.randi()]
	var b := RandomNumberGenerator.new()
	b.seed = saved_seed.to_int()    # seed first: setting seed resets state
	b.state = saved_state.to_int()
	assert_eq([b.randi(), b.randi(), b.randi()], expected)
```

`test_odds.gd` (the example test):

```gdscript
@tool
extends McpTestSuite
## Job-hunt formulas (GDD 5.6). Fixtures are built in code, so tuning the .tres files never breaks these;
## BalanceConfig.new() carries the GDD section 11 defaults.

var cfg: BalanceConfig


func suite_name() -> String:
	return "odds"


func setup() -> void:
	cfg = BalanceConfig.new()


func _tier(id: StringName, base_invite: float) -> TierData:
	var t := TierData.new()
	t.id = id
	t.base_invite = base_invite
	return t


func _bg(big: float, mid: float, startup: float) -> BackgroundData:
	var b := BackgroundData.new()
	b.invite_mult_big = big
	b.invite_mult_mid = mid
	b.invite_mult_startup = startup
	return b


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


func test_example_1_graduate_mid_backend_tailored() -> void:
	var p := Odds.p_invite(cfg, _tier(&"mid", 0.065), _bg(1.2, 1.0, 1.0), 3, true, 15, false)
	_near(p, 0.168, 0.0005, "Graduate, Mid, Tailor, M = 3/3")
	assert_eq(Odds.odds_band(cfg, p), 4, "16.8% shows as [####-] Decent")


func test_example_2_self_taught_startup_quick_vs_tailored() -> void:
	var tier := _tier(&"startup", 0.10)
	var bg := _bg(1.0, 1.0, 1.3)
	_near(Odds.p_invite(cfg, tier, bg, 3, false, 5, false), 0.123, 0.0005, "Quick Apply")
	_near(Odds.p_invite(cfg, tier, bg, 3, true, 5, false), 0.307, 0.0005, "Tailor & Apply")


func test_example_3_intern_big_referral() -> void:
	_near(Odds.p_invite(cfg, _tier(&"big", 0.03), _bg(1.0, 1.0, 0.8), 2, true, 45, true), 0.190, 0.0005, "Intern, Big, referral")


func test_p_invite_is_clamped() -> void:
	_near(Odds.p_invite(cfg, _tier(&"startup", 0.10), _bg(1.0, 1.0, 1.3), 3, true, 80, true), cfg.p_invite_max, 0.0001, "cap")
	_near(Odds.p_invite(cfg, _tier(&"big", 0.03), _bg(1.0, 1.0, 1.0), 0, false, 0, false), cfg.p_invite_min, 0.0001, "floor")


func test_odds_bands() -> void:
	assert_eq(Odds.odds_band(cfg, 0.02), 1, "Long shot")
	assert_eq(Odds.odds_band(cfg, 0.05), 2, "Unlikely")
	assert_eq(Odds.odds_band(cfg, 0.10), 3, "Possible")
	assert_eq(Odds.odds_band(cfg, 0.15), 4, "Decent")
	assert_eq(Odds.odds_band(cfg, 0.30), 5, "Good")


func test_knockouts() -> void:
	# Graduate, Mid "Backend Developer" (1+ years): Honest Experience fails, Polished passes.
	assert_true(Odds.is_knockout(false, 1, true, false, false), "Quick Apply with Honest TA line")
	assert_false(Odds.is_knockout(false, 1, true, true, false), "Tailor sends Polished: passes")
	# Self-Taught vs a degree-required Big posting: knocked out unless a referral is used.
	assert_true(Odds.is_knockout(true, 0, false, true, false))
	assert_false(Odds.is_knockout(true, 5, false, false, true), "a referral skips knockouts")


func test_relevance_needs_two_matching_tags() -> void:
	var tags_sent := PackedStringArray(["java", "python", "sql", "git"])
	assert_eq(Odds.tag_hits(PackedStringArray(["java", "sql", "apis"]), tags_sent), 2)
	assert_true(Odds.is_relevant(cfg, 2))
	assert_false(Odds.is_relevant(cfg, 1))


func test_same_seed_same_rolls() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	var ra: Array[bool] = []
	var rb: Array[bool] = []
	for _i: int in 50:
		ra.append(Odds.roll(a, 0.3))
		rb.append(Odds.roll(b, 0.3))
	assert_eq(ra, rb)
	assert_eq(Odds.pick(a, ["x", "y", "z"], 2), Odds.pick(b, ["x", "y", "z"], 2))
```

`test_interview.gd`:

```gdscript
@tool
extends McpTestSuite
## GDD 5.8.7 worked example (Intern vs Dana at Hierarchai) with the luck values fixed, plus bluff and Tired.

var cfg: BalanceConfig
var startup: TierData
var mid: TierData
var intern: BackgroundData


func suite_name() -> String:
	return "interview"


func setup() -> void:
	cfg = BalanceConfig.new()
	startup = TierData.new()
	startup.id = &"startup"
	startup.doubt_hp = 118
	startup.tier_difficulty = 40
	mid = TierData.new()  # defaults are Mid
	mid.id = &"mid"
	intern = BackgroundData.new()
	intern.start_knw = 50
	intern.start_exp = 40
	intern.start_net = 45
	intern.teamwork_mult = 1.25
	intern.teamwork_mult_after_network = 1.25
	intern.startup_exp_bonus = 0


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.3f, got %.3f" % [what, expected, actual])


func test_worked_example_5_8_7() -> void:
	var doubt := float(startup.doubt_hp)
	var composure := 100.0
	# 1. eq_credit_theft (teamwork), Intern exclusive good answer
	doubt += Odds.ethics_doubt_delta(cfg, &"good", true, Odds.teamwork_mult(intern, false))
	_near(doubt, 105.5, 0.01, "after prompt 1")
	# 2. kq_hash_map: difficulty 1, not weak, luck +3, PERFECT
	var p := Odds.knowledge_p(cfg, startup, intern, 50, 40, true, false)
	_near(p, 47.0, 0.001, "P tech")
	var s := Odds.stat_score(cfg, startup, p, 1, 3.0)
	_near(s, 61.4, 0.01, "S")
	_near(Odds.zone_half(cfg, s), 0.134, 0.001, "h")
	var q := Odds.answer_q(cfg, s, cfg.input_perfect)
	_near(q, 71.05, 0.01, "Q")
	assert_eq(Odds.spoken_grade(cfg, q), &"green")
	doubt += Odds.knowledge_doubt_delta(cfg, q)
	_near(doubt, 68.56, 0.01, "after prompt 2")
	# 3. kq_deadlock: difficulty 3, weak_for intern, luck -5, GOOD
	s = Odds.stat_score(cfg, startup, Odds.knowledge_p(cfg, startup, intern, 50, 40, true, true), 3, -5.0)
	_near(s, 35.9, 0.01, "S weak")
	q = Odds.answer_q(cfg, s, cfg.input_good)
	assert_eq(Odds.spoken_grade(cfg, q), &"yellow")
	doubt += Odds.knowledge_doubt_delta(cfg, q)
	composure -= Odds.knowledge_composure_loss(cfg, q)
	_near(composure, 96.93, 0.01, "composure after prompt 3")
	# 4. kq_estimate: behavioral, difficulty 2, luck +6, GOOD
	s = Odds.stat_score(cfg, startup, Odds.knowledge_p(cfg, startup, intern, 50, 40, false, false), 2, 6.0)
	_near(s, 58.1, 0.01, "S behavioral")
	doubt += Odds.knowledge_doubt_delta(cfg, Odds.answer_q(cfg, s, cfg.input_good))
	# 5. eq_any_questions, good (not teamwork)
	doubt += Odds.ethics_doubt_delta(cfg, &"good", false, 1.0)
	_near(doubt, 13.1, 0.05, "Doubt after 5 prompts (GDD rounds to 13.2)")
	# 6. committee wheel
	assert_true(Odds.committee_eligible(cfg, doubt, startup.doubt_hp))
	_near(Odds.committee_win_p(cfg, doubt, startup.doubt_hp, 45), 0.68, 0.01, "wheel P_win")


func test_bluff_odds_by_background_at_mid() -> void:
	_near(Odds.bluff_p(cfg, mid, 50, 40, false), 0.45, 0.001, "Intern")
	_near(Odds.bluff_p(cfg, mid, 55, 15, false), 0.35, 0.001, "Graduate")
	_near(Odds.bluff_p(cfg, mid, 55, 10, false), 0.325, 0.001, "Self-Taught")


func test_tired_rule() -> void:
	assert_true(Odds.is_tired(cfg, 6 - 3 - 1), "Self-Taught in person: 6 - 3 - 1 = 2 pips left")
	assert_false(Odds.is_tired(cfg, 9 - 3))
	_near(Odds.needle_speed(cfg, mid, true), 0.69, 0.0001, "Tired needle")


func test_input_quality_bands() -> void:
	assert_eq(Odds.input_quality(cfg, 0.50, 0.50, 0.1), cfg.input_perfect)
	assert_eq(Odds.input_quality(cfg, 0.58, 0.50, 0.1), cfg.input_good)
	assert_eq(Odds.input_quality(cfg, 0.65, 0.50, 0.1), cfg.input_close)
	assert_eq(Odds.input_quality(cfg, 0.90, 0.50, 0.1), cfg.input_miss)
```

`test_offer.gd`:

```gdscript
@tool
extends McpTestSuite
## GDD 5.9: salary, negotiation, Dream vs Reality examples.

var cfg: BalanceConfig


func suite_name() -> String:
	return "offer"


func setup() -> void:
	cfg = BalanceConfig.new()


func test_salary_example() -> void:
	var startup := TierData.new()
	startup.salary_min_k = 50
	startup.salary_max_k = 70
	var intern := BackgroundData.new()
	intern.salary_mult = 1.10
	assert_eq(Odds.offer_salary(cfg, startup, intern, 96.925, 100.0), 71000)


func test_negotiation_odds() -> void:
	assert_true(absf(Odds.negotiate_p(cfg, 45, false) - 0.775) < 0.0001, "Intern")
	assert_true(absf(Odds.negotiate_p(cfg, 15, false) - 0.625) < 0.0001, "Graduate")
	assert_true(absf(Odds.negotiate_p(cfg, 45, true) - 0.85) < 0.0001, "capped at 85%")


func test_dream_score_examples() -> void:
	assert_eq(Odds.dream_score(cfg, 71000, 0, 20, 2, 13, 15), 68, "Intern at Hierarchai")
	assert_eq(Odds.dream_score(cfg, 126000, 4, 20, 2, 11, 15), 57, "Intern at OmniGlobal")
	assert_eq(Odds.dream_score(cfg, 72000, 2, 95, 1, 5, 12), 49, "Self-Taught at Beigeware")
```

---

## 18. Unverified items and pitfalls

### 18.1 Test these on the iPhone (Step 2 unless noted)

| # | Item | What to do if it's wrong |
|---|---|---|
| 1 | Does dragging a ScrollContainer fire a button release? | Set list-row buttons to `mouse_filter = PASS` and ignore a release when the pointer moved more than the deadzone |
| 2 | The unit of `gui/common/default_scroll_deadzone` (assumed game px) | adjust the value until a flick scrolls and a tap taps |
| 3 | Whether `window_width/height_override` are ignored on iOS | if not, clear them in an `ios` feature override (and `android`, LATER) |
| 4 | Whether the letterbox uses `default_clear_color` | irrelevant with ≤ 3 px |
| 5 | Safe area on a real Dynamic Island: does Godot still report the 59 pt top and 34 pt bottom insets with the status bar and home indicator hidden? | preview with `debug_fake_insets = (0, 45, 0, 26)`; measure on the phone and update GDD 2.9 |
| 6 | Fonts on the iPhone at 4x: monogram's 16 px metrics (the 40-column budgets need a 6 px advance) and Press Start 2P's 8 px grid; glyph coverage for other languages | pick a native size before building layouts |
| 7 | iOS haptics: is a 10 ms tap felt, and do haptics survive a background/resume? No entitlement is expected (unverified) | raise tap-level haptics to 20 ms, or add an amplitude parameter to `Device.haptic()` (GDD 9.3); keep the Settings toggle |
| 8 | That the JSON texts load in the exported iOS build (Step 5) | add `data/content/*.json` to the include filter |
| 9 | The 7-day Personal Team expiry: does reinstalling over the same bundle ID keep the save? | re-run from Xcode before every playtest; join the paid program before Step 13 |
| 10 | One-click deploy and remote debug with a Personal Team (Mac editor) | build and run from Xcode, and read Xcode's console |
| 11 | The name of Steam's "update only on launch" option (Windows PC) | find it; commit before any engine update. The Mac's zip never updates itself |
| 12 | `DisplayServer.virtual_keyboard_get_height()` unit on iOS (likely native px; Step 5, S03 name field) | divide by the scale, as `safe_insets()` does |
| 13 | `game_manage input_mouse` coordinate space | test on one button first |
| 14 | The game embedded in the editor's Game tab (possible since 4.4): the window size is the tab's size, the 540x960 override may not apply, and `game_eval` resizes are ignored (seen in Step 1). Desktop-only | float or undock the game window to test exact sizes. The guard rule still holds at any size |
| 15 | (Android, LATER) `gradle_build/target_sdk` shows 36 in the preset; the 4.7.2 template already targets 36 | set it to 36 |
| 16 | (Android, LATER) Play's closed-testing rule for new personal accounts (12 testers x 14 days) | check the Play Console when you create the account |

### 18.2 Pitfalls this architecture prevents (don't undo them)

1. **Changing a loaded `.tres` at runtime.** It changes it for everyone, and can even save it to disk. Copy values into `RunState` instead.
2. **An autoload with a `class_name`.** The autoload script needs none.
3. **Blurry pixels.** Causes: a Linear filter, font antialiasing, non-integer scales, sub-pixel tweens.
4. **Placing Controls by absolute position.** Layouts break on tall iPhones and wider screens. Use containers.
5. **An invisible full-screen Control eating taps.** Set `mouse_filter` to IGNORE unless it's meant to block.
6. **One Control handling both touch and mouse events**, which fires double taps.
7. **Back quitting the app, or not saving on pause.** Both are handled in `Device` and `GameState`.
8. **Case-mismatched `res://` paths.** They work on Windows and macOS and break on phones. Never hand-type paths: drag them in or use `uid://`.
9. **JSON surprises.** Floats instead of ints; 64-bit values losing precision.
10. **The global RNG, `Array.shuffle()` or `pick_random()` in gameplay.**
11. **`if difficulty == HARD` anywhere.** Difficulty is only ever numbers from `BackgroundData`.
12. **Reordering the `Phase` enum**, which breaks saves. Only append.
13. **Loading anything but our own JSON or `settings.cfg` from `user://`.**
14. **Tests that touch autoloads or `user://`, lack `@tool`, or make zero assertions.**
15. **Engine or template drift.** A Steam update on the PC, or a different download on the Mac, means the two machines and the templates no longer match 4.7.2. Commit first and update both together.
16. **Testing only in the editor.** Fonts, the Dynamic Island, touch and performance only reveal themselves on the iPhone.

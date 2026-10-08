# SWE Simulator: Technical Architecture (MVP)

| | |
|---|---|
| Version | 1.5, 2026-10-07: the career run's code plan (Run Spec v1, DECISIONS W8) added as section 19, planned and not built, with pointers in sections 0, 4.1, 6.3, 11.8 and 12; section 17 is unchanged, because the merge changed no code. 1.4, 2026-09-29: synced with the code after the Step 7 developer review (CV editing and lying removed, DECISIONS D9; coach marks close on a tap, D11; the VS intro waits for a tap, D12; the real HP and stat bars, W7). 1.3, 2026-09-27: synced with the code at the end of Step 6 (offer, endings, intro, Back). 1.2, 2026-09-27: synced with the code at the end of Step 5 (ISSUE-08). 1.1, 2026-09-26: portrait, iPhone first (`docs/DECISIONS.md` D1, D2, P1) |
| Engine | Godot 4.7.2-stable on both machines (Steam build on the Windows PC, the godotengine.org zip on the MacBook), GDScript, `gl_compatibility` renderer |
| Readers | You (the developer) and every future Claude session that implements the game |
| Design source of truth | `docs/GDD.md` (rules and numbers) and `docs/CONTENT.md` (every string and id) |
| Companion | `docs/ROADMAP.md` (the step-by-step plan) |

**How to read this doc.**
- Sections 1-10 are the rules of the codebase.
- Section 11 explains how to build each feature.
- Sections 12-16 cover testing, export, git, performance and the godot-ai workflow.
- Section 17 has the code skeletons: each one is its repo file, byte for byte. Copy them verbatim.
- Section 18 lists what is still unverified, plus the pitfalls.
- Section 19 is the career run's code plan (Run Spec v1): planned, not built.

If this doc and the GDD disagree on a rule or a number, the GDD wins; fix this doc. If they disagree on an engine fact, this doc wins; fix the GDD.

**Verification tags**
- **(verified 4.7.2)**: checked in this editor on 2026-09-26, using `settings_get`, ClassDB or the 4.7.2 engine source.
- **(verified: scratch run)**: the section-17 code was compiled and run headless on Godot 4.7.2.stable.steam in a throwaway project outside the repo, with the common GDScript warnings turned into errors.
  - 24 unit tests passed.
  - 42 runtime checks passed: the scale guard at 8 screen sizes; the save rules for new game, Continue, Retry, Plan B and Hired; the interview checkpoint; the focus pause; the Answer Meter idle fix; and SafeAreaMargin.
  - Those guard sizes were landscape. The portrait guard is the same math with the axes swapped, and was checked live in this project on 2026-09-26: the title stub reads `window (540, 960)` / `game (270, 480) (integer)`, and `test_run` passes 24/24.
  - Section 17 has since grown with Steps 3-6. At the end of Step 6 (2026-09-27) every block was compared with its repo file and the changed ones re-copied, and those files pass the repo's `test_run` (225 tests in 21 suites; `.project/evidence/STEP-06/2026-09-27-r1/test_run.json`). After the Step 7 review (2026-09-29) every block was re-synced the same way; the repo then passes 217 tests in 20 suites (`.project/evidence/STEP-07/2026-09-29-review/`).
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
   - The rules live in six pure `@tool` classes: `GameFlow`, `RunState`, `SaveIO`, `Odds`, plus `InterviewPlan` (Step 4) and `HuntTips` (Step 5). `UiText` (Step 4, label styling) and `CutscenePlan` (Step 6, the intro's play order) are pure helpers, not rule classes.
6. **Where data lives:**
   - Numbers you tune are in **11 `.tres` files**: 1 BalanceConfig, 3 BackgroundData, 3 TierData (all the hiring odds), and the career run's 1 WorkConfig and 3 ArchetypeData (since Step 14).
   - All text is in **19 JSON files keyed by id** (the career run's `work_events` and `coworkers` joined the 16 in Step 14). Companies are JSON only; there is no company `.tres`.
7. **Randomness:** there is one seeded RNG per run. Each interview gets its own RNG, seeded from a checkpoint, so a resume replays the same interview; the offer's contract is picked on another one seeded from the same checkpoint (section 7.2). 64-bit seeds and states are saved as **strings**.
8. **One JSON save** in `user://`.
   - It is written only while a run is live (hunt, interview, offer).
   - It is written after every committed action, and whenever the app loses focus.
9. **Rules live in pure code** that the editor-side tests can run (autoloads don't exist there). Scenes only display state and call `GameState` verbs.
10. **iPhone first.** You develop on the Windows PC and build for the iPhone on the MacBook (Xcode, free Personal Team signing). Git keeps the two machines in sync. Android is LATER; JDK 17 is already on the PC.
11. **The career run (Run Spec v1) is planned in section 19:** a pure, deterministic sim core in `core/` that bots play headless, its own data files (`WorkConfig`, `ArchetypeData`, the event JSON), and an adapter in front of the shipped duel and contract. None of it is built yet; M1 (STEP-14) starts it. The decisions above all carry over to it.

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
| Title logo, VS screen, K.O. / OFFER! banners | **Press Start 2P** | OFL 1.1 | 8 / 16 / 24 / 32 |

- Put the files in `res://ui/fonts/`: `PressStart2P-Regular.ttf`, the Press Start 2P license as `OFL.txt`, and monogram's `monogram/` folder as its download unpacks it. The body font is `res://ui/fonts/monogram/ttf/monogram.ttf`; `monogram-extended*.ttf` are unused, and `monogram/pico-8/` has a `.gdignore`.
  - `.txt` is not a resource type (verified: scratch run), so the export preset needs the non-resource include filter `ui/fonts/*.txt`.
  - The Credits screen shows `OFL.txt`. CC0 fonts need nothing.
- **Import settings for every `.ttf`** (Import dock, then Reimport):
  - `antialiasing` = **None**
  - `hinting` = None
  - `subpixel_positioning` = Disabled
  - `generate_mipmaps` = off
  - `multichannel_signed_distance_field` = off
- Use each font only at its native size or whole multiples of it.
  - **monogram 16, measured on desktop (Step 2, `.project/evidence/STEP-02/2026-09-27-pc/font_metrics.json`): a 6 px advance and a 13 px glyph height** (ascent 11 + descent 2). The 6 px advance is what GDD 2.7 assumes, so a 240 px text column holds exactly 40 characters; answer buttons have zero slack. The theme's `Label/constants/line_spacing = -1` gives the 12 px line pitch the GDD budgets use (DECISIONS A3).
  - A 13 px glyph makes two-line buttons taller than planned: with the default button padding the lie probe's 124x44 buttons rendered 124x47. Step 6's `ProbeButton` theme variation trimmed the padding to 10 px top and 9 px bottom, so two 12 px-pitch lines filled 44 px exactly. The probe and that variation were removed on 2026-09-29 (DECISIONS D9); a future two-line button needs the same trim.
  - Press Start 2P measured an exact 8 px grid (8x8 at size 8, 16x16 at 16).
  - These are font-file metrics, so they hold on every platform; crispness at 4x still needs the iPhone (section 18.1 #6).
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
├─ core/                           pure @tool classes: game_flow.gd, run_state.gd, save_io.gd, odds.gd,
│                                  interview_plan.gd (Step 4), hunt_tips.gd (Step 5)
├─ data/
│  ├─ types/                       balance_config.gd, background_data.gd, tier_data.gd  (Resource classes)
│  ├─ balance/balance_config.tres
│  ├─ backgrounds/                 intern.tres, graduate.tres, self_taught.tres
│  ├─ tiers/                       startup.tres, mid.tres, big.tres
│  └─ content/                     the 19 JSON files (section 6.3)
├─ features/                       every screen has <name>.tscn + <name>.gd; the extras are listed
│  ├─ title/                       title.tscn + title.gd  (main scene)
│  ├─ intro/                       intro.tscn (its dialogue box is inside it), cutscene_plan.gd (CutscenePlan,
│  │                               a pure helper), hold_skip_pill.gd (art/ arrives with the art pass)
│  ├─ background_select/           background_select.tscn, background_card.tscn, dice_button.gd
│  ├─ job_hunt/                    job_hunt.tscn (the hub; its Mail and Study panels are inside it),
│  │                               job_card.tscn, invite_card.tscn, night_screen.tscn, coach_mark.tscn,
│  │                               mail_screen.gd, dock_button.gd (the CV screen's cv_screen.gd and
│  │                               cv_row.tscn were removed on 2026-09-29, DECISIONS D9)
│  ├─ interview/                   interview.tscn, versus_intro.tscn, answer_meter.gd, committee_wheel.gd
│  │                               (art/ and sfx/ arrive with the art pass)
│  ├─ offer/                       offer.tscn        (the paper contract, S10)
│  ├─ phase2_stub/                 phase2_stub.tscn  (the Hired card, S11)
│  ├─ game_over/                   game_over.tscn    (the Plan B card, S12)
│  └─ dev/                         device_check.tscn (debug only; excluded from release exports)
├─ ui/
│  ├─ theme/                       main_theme.tres (9-slice PNGs arrive with the art pass)
│  ├─ fonts/                       monogram/ (ttf/monogram.ttf is the body font; credits.txt; pico-8/ has
│  │                               a .gdignore), PressStart2P-Regular.ttf, OFL.txt
│  └─ components/                  safe_area_margin.gd, confirm_dialog, pause_menu, ducky_note, pip_bar.gd,
│                                  ui_text.gd (a pure UI helper), ending_art (the ending cards' 254x140
│                                  picture and stamp, Step 6), hp_bar and stat_bar (section 10.5; W3
│                                  placeholders until Claude built them in the Step 7 review, DECISIONS W7)
├─ art/shared/                     palette.png, icons, logos (empty until the art pass)
├─ audio/sfx/   audio/music/       (empty until the audio pass)
├─ tests/                          test_*.gd (excluded from exports)
├─ art_src/                        .aseprite sources (has a .gdignore, so Godot never imports it)
├─ builds/                         ios/ (the exported Xcode project), later APK/AAB (.gdignore; git-ignored except that file)
└─ docs/                           GDD.md, CONTENT.md, ARCHITECTURE.md, ROADMAP.md, DECISIONS.md, KILL_TESTS.md
                                   (the Step 6 kill-test checklist), task/README.md
```

There is no `dialogue_box` or `odds_band` component: the interview and the intro each draw their own dialogue box (sections 11.6 and 11.2), and odds bands are text from `UiText.band()` (section 17.15).

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
| 2 | `GameState` | `autoload/game_state.gd` | owns the RunState, the run RNG, the phase and `settings.cfg` | signals `phase_changed(from, to)` and `run_changed`; `run`, `rng`, `preselect_background`; `setting()`, `set_setting()`, `save()`; flow verbs (section 4) plus `new_run_seed()` and `preview_gap_topics()` for Background select; hunt verbs `quick_apply`, `tailor_apply`, `skip_card`, `study`, `sleep`, `start_day`, `mark_tip_shown`, `close_coach_mark` (Step 7 review) and the read-only `card_odds(card)` (`set_cv_level` and `commit_cv` were removed with the CV screen, DECISIONS D9); interview verbs `start_interview`, `finish_interview` (a win builds the offer) and the read-only `interview_cost(invite)`, `can_take_interview(invite)`; offer verbs `answer_offer`, `end_run_plan_b` and the read-only `dream_breakdown()` (the Hired card's rows); debug only `debug_quick_start`, `debug_fake_invite` (section 17.7) |
| 3 | `Device` | `autoload/device.gd` | phone glue: scale guard, safe area, Back, haptics | signals `layout_changed` and `back_unhandled`; `safe_insets()`, `keyboard_height()`, `handle_back()`, `haptic(ms)`, `haptics_enabled` |
| 4 | `SceneRouter` | `autoload/scene_router.gd` (CanvasLayer) | fades between scenes when the phase changes | signal `transition_finished(phase)`; `busy`, `go_to(phase)` |

**Pure classes** (`@tool`, `class_name`, `RefCounted`; no nodes, no autoloads, no global RNG):

| Class | File | Holds |
|---|---|---|
| `GameFlow` | `core/game_flow.gd` | `Phase` enum, `TRANSITIONS`, `SAVED_PHASES`, `can_transition`, `is_saved`, `deletes_save`, `can_resume` |
| `RunState` | `core/run_state.gd` | all saved run data, plus the rule methods that change it (section 7.1: the character, the board, applying, Sleep and the morning reveal, invites, and since Step 6 the offer, hiring and the Dream vs Reality rows; the lie-probe and background-check rolls were removed on 2026-09-29, DECISIONS D9); `to_dict` / `from_dict` |
| `SaveIO` | `core/save_io.gd` | `exists`, `write` (temp file, then rename), `read`, `delete` |
| `Odds` | `core/odds.gd` | every formula in GDD 5.6-5.10 (P_invite, bands, knockouts, card rolls, the reveal, the Radar, expiry, ghosting, the rent check, the interview, the offer, the Dream vs Reality score, its rows `dream_breakdown` and grade `dream_grade`), plus RNG helpers (`roll`, `pick`, `shuffled`) |
| `InterviewPlan` | `core/interview_plan.gd` (Step 4) | question picking for one interview (`pick`, `eligible`, `warmup_due`, `mark_seen`), the prompts a checkpoint plays (`prompts`), the interview and meter RNGs (`interview_rng`, `meter_rng`), and since the Step 7 review Dana's VS plate (`vs_plate`). The probe question (`probe_question`, `lie_lines`) was removed on 2026-09-29 (DECISIONS D9) |
| `HuntTips` | `core/hunt_tips.gd` (Step 5) | which Ducky tip the hunt shows, and when (GDD 8.3): `inbox`, `night` (since D9 also the two Tailor & Apply tips that `cv_opened` and `cv_level_chosen` gave on the removed CV screen), `studied`, `had_invite`; since Step 6 also the offer's tip (`offer`) and the Plan B card's (`plan_b`); since the Step 7 review the first-run coach marks (`coach`, `coach_invite`). It only reads the run |

`UiText` (`ui/components/ui_text.gd`, Step 4) is also `@tool` and pure, but it is a **UI helper, not a rule class**: static string styling (`primary`, `back`, `cost`, `meter`, `band`, `count`, `money`) for text that scenes fetch from `Content`, and since Step 6 `word_wrap` (the lint's line rule, returning the lines) and `field` (the offer contract's label column). Since the Step 7 review it also has `fill(template, args)`, which `Content.text()` and `Content.field()` use to fill placeholders (section 6.3). It holds no words of its own (INV-15).

`CutscenePlan` (`features/intro/cutscene_plan.gd`, Step 6, section 17.17) is the same kind of pure `@tool` helper: `panels(entries)` turns `cutscene.json` into the intro's play order, `total_seconds(plan)` sums the pans, and `pan_path(picture, frame)` says where a picture pans. It lives with the intro because nothing else uses it.

**Why the rules live in pure classes:** godot-ai's `test_run` runs inside the editor, where **autoloads don't exist** (verified: addon source). The balance simulation (Step 7) must also run there.

So there is one split:
- **`RunState`, `Odds`, `GameFlow`, `InterviewPlan` and `HuntTips` are the model.** They are data plus rules, and they take `cfg`, `tier`, `bg`, `rng` and the parsed content as arguments.
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
enum Phase { TITLE, INTRO, BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER, PHASE2_STUB, GAME_OVER, WORK, LAYOFF }
```

**Append new phases at the end only.** Saves store the phase as an int, so reordering the enum breaks every existing save. `WORK` and `LAYOFF` are the career run's (M2): their transitions are the last rows below and in section 19.4.

| From | To | Trigger (the GameState verb) |
|---|---|---|
| TITLE | INTRO | `start_new_game()` on the first run, or `replay_intro()` |
| TITLE | BACKGROUND_SELECT | `start_new_game()` once `intro_seen` is set |
| TITLE | JOB_HUNT / INTERVIEW / OFFER | `continue_game()` (the saved phase) |
| INTRO | BACKGROUND_SELECT | `finish_intro()`: the intro ends, or Skip, or Back |
| BACKGROUND_SELECT | JOB_HUNT | `choose_background()` |
| JOB_HUNT | INTERVIEW | `start_interview(invite)` |
| JOB_HUNT | GAME_OVER | `end_run_plan_b()`, called by Mail's `start_day()` when the morning report says `plan_b`: rent is at 0 and no invite is waiting, or the grace day is already used |
| INTERVIEW | OFFER / JOB_HUNT | `finish_interview(won, composure_left)` |
| OFFER | PHASE2_STUB | `answer_offer(true)` (Accept; there is no background check since DECISIONS D9) |
| OFFER | JOB_HUNT | `answer_offer(false)` (Decline). The background check's rescind, which also led here, was removed on 2026-09-29 (D9) |
| OFFER | GAME_OVER | `answer_offer(false)` on the grace day (rent at 0): Decline -> Plan B (GDD 5.10) |
| PHASE2_STUB | TITLE / BACKGROUND_SELECT | `quit_to_title()` / `retry()` ("New run") |
| GAME_OVER | TITLE / BACKGROUND_SELECT | `quit_to_title()` / `retry()` |
| BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER | TITLE | `quit_to_title()`: Back or Pause, then "Quit to title" |
| TITLE | WORK / LAYOFF | `continue_game()` with a career save (the saved phase), or `start_new_game()` for run 1 once the intro has been seen (`_begin_career`) |
| INTRO | WORK | `finish_intro()` after a new game's intro (run 1); a replayed intro goes to BACKGROUND_SELECT |
| BACKGROUND_SELECT | WORK | `choose_background()` in the career flow (runs 2 and later) |
| WORK | LAYOFF / GAME_OVER / TITLE | the `career_*` verbs when a layoff is next (`wants_layoff_scene`); the sim's ending; `quit_to_title()` |
| LAYOFF | WORK / TITLE | `career_acknowledge()` (the scene's last OK); `quit_to_title()` |

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
| `salary_min_k` / `salary_max_k` (yearly, $k) | 50 / 70 | 65 / 90 | 95 / 125 |
| `office_days` | 0 | 2 | 4 |
| `meeting_load` / `layoff_risk` / `growth_mult` (Phase 2) | 0.2 / 0.3 / 1.5 | 0.5 / 0.1 / 1.0 | 0.8 / 0.2 / 0.8 |

Removed on 2026-09-29 with lying (DECISIONS D9): TierData's `lie_probe_chance`, `bluff_detect` and `background_check`, and BalanceConfig's whole "Lying (11.5)" group (`max_probes_per_interview`, the `bluff_*` fields, `busted_doubt` / `busted_comp`, `come_clean_doubt` / `come_clean_comp`). The Step 7 review also removed BalanceConfig's `vs_min_view_s` (section 11.5). `test_data_files` expects none of them.

Removed on 2026-10-08, the code cleanup of Negotiate (DECISIONS D-27, 2026-10-07): BalanceConfig's six `nego_*` fields (`nego_base`, `nego_net_div`, `nego_leverage`, `nego_cap`, `nego_gain_min`, `nego_gain_max`), together with `Odds.negotiate_p` and `Odds.negotiated_salary`. `test_data_files` expects none of them, and GDD 11.6 has no rows for them.

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
- `has_degree_honest` and `years_pass_honest` repeat what `cv_lines.json` says about the honest lines. The runtime knockout logic reads the **CV lines actually sent**; the BG flags are for the background card, and `years_pass_honest` also picks the first Tailor & Apply night tip (`HuntTips.night`: `tip_projects_count` when the honest CV fails "1+ years"). `test_content_lint` checks that the two agree.

**Creating them with godot-ai:** use `resource_manage create` with `type=TierData`, `resource_path=res://data/tiers/big.tres` and the table's values. This works because the classes are `@tool`.

### 6.3 JSON content: the text

**Rules**
- **One file = one JSON object keyed by id.** A value is either a **plain string** (UI text) or an **object** (a structured entry).
- Keys that start with `_` are metadata, not ids. For example, `naming.json` has `_keywords`, `_topics` and `_gap_topic_pool`.
- **JSON numbers load as floats: wrap them in `int()`.** Tier lists are always explicit, as `["startup", "mid", "big"]`; don't write `"all"`.
- **ASCII only** in player-facing strings (lint-checked).
- **Every displayed string goes through `tr()`.** `Content.text()` and `Content.field()` do this, then fill `{placeholders}` with `UiText.fill(template, args)` (since the Step 7 review). It is `String.format`, except that a value ending in "." swallows a "." right after its placeholder, so "Welcome to {company}." with "Engagement Farms Inc." never prints "..", while an ellipsis after a placeholder keeps its three dots (`test_ui_text` fills every `{company}` / `{last_company}` template with every company name).
  - Static Label text in scenes is English. Controls translate it automatically when a translation exists later.
- Non-displayed fields (`art`, `visual`, `audio`, `note`) are notes for the artist. The lint skips them.
- `Content` reads JSON with `FileAccess` from `res://`. **`.json` is a recognized resource type in 4.7.2**, so "export all resources" includes it (verified: scratch run). Still confirm on the phone in Step 5 that the texts load.

| File | CONTENT.md | Entry shape (key = id) |
|---|---|---|
| `naming.json` | 1 | `"city": "Byteburg"`, `"app_jobs": "DoomApply"`, ...; `"_keywords": {"python": "Python", ...}`, `"_topics": {"algorithms": "Algorithms", ...}`, `"_gap_topic_pool": ["algorithms", "data_structures", "databases", "web", "concurrency", "system_design", "security"]` |
| `cutscene.json` | 2 | `"intro_p1": {"order": 1, "seconds": 6, "captions": [{"speaker": "", "text": "2022. You are 17."}], "visual": "...", "audio": "..."}`; a caption may add `"style": "title"` (the title card, section 11.2) |
| `backgrounds.json` | 3.1 | `"intern": {"title", "selector" (the S03 selector button), "difficulty", "one_liner", "perk", "flaw", "vs_nickname", "dana_opener", "commute_line", "plan_b_line", "gaps_line"?, "commute_strip"?, "hoodie"}` |
| `names.json` | 3.2 | `"default": "Alex"`, `"pool": [20 names]` |
| `tiers.json` | GDD 7 | `"startup": {"name": "Startup", "tag": "START"}`, `"mid": {"name": "Mid-size", "tag": "MID"}`, `"big": {"name": "Big corp", "tag": "BIG"}` |
| `companies.json` | 4 | `"co_beigeware": {"name", "tier", "mvp", "tagline", "card_joke", "insider", "dana_line", "review", "red_flags": [], "hired_extra"?, "art"}` |
| `postings.json` | 5 | `"job_mid_backend": {"tier", "company": "any" or a co_ id, "title", "tags": [3], "degree": bool, "min_years": int, "ghost": "roll" or "always", "joke", "salary_text", "should": bool, "research_reveal"? and "note"? (the SHOULD Unicorn only)}`, plus the plain-string UI ids `card_*`, `knock_*`, `research_*`, `hirebot_*`, `stamp_sent` |
| `cv_lines.json` | 6 | `"cv_intern_edu_honest": {"background", "line": "edu", "variant": "honest" or "polished", "text", "tags": [], "degree": bool, "passes_years": bool}`: 6 per background. The `lie` variant and the lie-only fields `degree_claim`, `probe` and `probe_at` were removed on 2026-09-29 (DECISIONS D9) |
| `questions_choice.json` | 7 | `"eq_friday_deploy": {"prompt", "teamwork": bool, "tiers": [...], "tip", "opener_only": bool, "answers": [{"kind": "good", "text", "reaction"}, ...], "exclusive": {"background", "kind", "text", "reaction"}?}` |
| `questions_knowledge.json` | 9 | `"kq_hash_map": {"prompt", "topic", "kind": "tech" or "behavioral", "difficulty": 1-3, "weak_for": a bg id or "none", "tiers": [...], "tip", "green", "yellow", "red", "ducky"}` |
| `barks.json` | 8, 10 | plain strings: `dana_title_*`, `bark_*`, `vs_*`, `meter_*`, `ducky_real_answer`, `ui_*`, `coach_*` |
| `tips.json` | 11 | `"tip_ats_knockouts": {"short", "more", "triggers"}` |
| `emails.json` | 12, 13 | `mail_invite_*` / `mail_knockout`: `{"subject", "body"}`; `mail_reject_NN`, `notif_*`, `offer_*`: plain strings (`mail_rescinded` was removed with the background check, D9); `perk_*` / `fp_*`: `{"tiers": [...], "text"}` |
| `endings.json` | 14 | plain strings (`end_*`) |
| `events.json` | 15.1 | `"evt_mom_call": {"text", "effect", "ducky"?}` (SHOULD) |
| `news.json` | 15.2 | plain strings (`news_*`) |

Reading text:
- `Content.text("barks", "ui_rent_due", {"days": 9})` returns "Rent due in 9 days".
- `Content.field("questions_knowledge", "kq_hash_map", "green")` returns one field of a structured entry.

The career run's planned JSON (`work_events.json`, `coworkers.json`) and its two planned Resource classes (`WorkConfig`, `ArchetypeData`) are in section 19.3.

### 6.4 Stable ids (GDD 5.0)

| Kind | Ids |
|---|---|
| Backgrounds | `intern`, `graduate`, `self_taught` |
| Tiers | `startup`, `mid`, `big` |
| Stats | `knw`, `exp`, `net` |
| CV lines | `edu`, `exp`, `proj` |
| CV variants | `honest`, `polished` (`lie` was removed on 2026-09-29, DECISIONS D9) |
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
| Character (Phase 2 carries it to work) | `background_id`, `player_name`, `stats {knw, exp, net}`, `lone_wolf`, `gap_topics`, `commute_pips`, `commute_minutes`. Your CV is your background's true CV, so the run stores no CV setting |
| Day loop | `day`, `energy`, `rent_days_left`, `grace_used`, `referral_tokens`, `pity_count` (the Recruiter Radar), `interviews_today`, `next_uid`, `board`, `applications`, `applied` ("template_id\|company_id" pairs never dealt again), `dropped` (pairs that fell off the board unapplied: they return "Reposted"), `invites`, `morning_report` (built by Sleep), `day_mail` (the morning report after Start day, until the next Sleep), `tips_shown` (once-per-run tips, `HuntTips`), `coach_closed` (first-run coach mark ids tapped closed: never shown again this run; Step 7 review, section 11.4), `blacklist` (companies whose offer you declined), `researched`, `seen_question_ids` |
| Interview | `interview` (the checkpoint, section 8), `interviews_taken`, `times_met_dana`, `dana_last_company` |
| Offer and job | `offer` (the offer on the table, built by `make_offer`: shape below), `employment` (set by `hire()` on Accept: the offer copied, plus `red_flags`, the company's `companies.json` list; Phase 2 reads it), `dream_score` (-1 until `hire()` scores the job) |
| Run stats | `total_applications`, `total_rejections` |

**Removed on 2026-09-29 (DECISIONS D9):** `cv_levels`, `lies_carried`, `confessed` and `rescinded`, an application's `lies` and the checkpoint's `probe_line`. **Old saves still load** (`test_a_save_from_before_d9_still_loads`): `from_dict` copies only the fields the RunState has, so the removed top-level keys are ignored and the next save drops them. An old application's `lies` and an old checkpoint's `probe_line` stay inside their dictionaries, but nothing reads them: a resumed interview asks its knowledge prompt 2. No `VERSION` bump was needed.

The comments in section 17.2 give the shapes of the list entries: a board card `{uid, template_id, company_id, tier, posted_days_ago, applicants, is_ghost, reposted}`; an application `{uid, template_id, company_id, tier, day_sent, reveal_day, p, hits, relevant, knockout, knockout_reason {id, args}, is_ghost, referral, tailored, status}`, where status goes pending -> invited | rejected | silent (-> ghosted) and invited -> interview | expired; an invite `{uid, app_uid, company_id, template_id, tier, day_received, kind, mail_id}`, where kind is rolled, radar, guarantee or profile.

The offer (GDD 5.9, S10) is `{company_id, template_id, tier, job_title, salary, work_mode, office_days, commute {id, args}, perks, fine_print, equity_text}`, plain data only (INV-07), so the paper can be drawn again after a resume:
- `job_title` is the posting's `title` as the JSON has it; the screen `tr()`s it.
- `salary` is `Odds.offer_salary` (yearly dollars) and `office_days` is `tier.office_days`.
- Every other text is an `emails.json` id: `work_mode` is `offer_mode_<tier>`; `commute.id` is `offer_commute_remote` (no office days) or `offer_commute_office`, with `commute.args` = `{office_days, commute_min, hours}` and the weekly hours as one-decimal text ("12.7"); `perks` holds 2 `perk_*` ids and `fine_print` 1 `fp_*` id, all listed for the offer's tier. The fine print comes from `fine_print_pool(emails, tier_id, perks)` (Step 7 review): the tier's `fp_*` ids minus any `fp_<x>` whose `perk_<x>` was dealt on the same paper, so a startup never lists "Unlimited PTO*" twice (today `perk_unlimited_pto` / `fp_unlimited_pto` is the only such pair; a thematic overlap such as `perk_pizza` with `fp_perks` is allowed as a joke); `equity_text` is `offer_equity` at startups, else `""`.
- **Removed on 2026-10-08 (DECISIONS D-27):** the offer's `negotiated` flag, with `Odds.negotiate_p`, `Odds.negotiated_salary`, BalanceConfig's `nego_*` fields and `test_offer`'s negotiation test (Negotiate was removed on 2026-10-07). **Old saves still load**, with no `VERSION` bump (the D9 precedent above, DECISIONS A23): an old offer, and the `employment` copied from it, keeps a `negotiated: false` inside its dictionary, and nothing reads it.

**Rule methods** (section 17.2). They take their data as arguments: `cfg` (BalanceConfig), `tiers` (`{"startup": TierData, "mid": ..., "big": ...}`), `bg` (this run's BackgroundData), `rng` (the run RNG) and `content` (the parsed `postings`, `companies`, `cv_lines` and `emails` JSON, keyed by file name; `GameState._hunt_content()` builds it).
- **Character and CV:** `set_background(cfg, bg)`, `cv_sent(cv_lines, tailored)` (your background's true CV: Quick Apply sends every line Honest, Tailor & Apply sends every line as its Polished version, an honest reframing, for that one application; returns the lines, tags, degree and `passes_years` actually sent), `stat(id)`, `spend_energy(pips)`, `new_uid()`. `set_cv_level` and `cv_line` were removed with the CV screen (D9).
- **Board:** `deal_board(cfg, tiers, content, rng)`, `skip_card(card_uid)`, `blacklist_company(company_id)`, static `pair_key(template_id, company_id)`.
- **Applying:** `card_odds(cfg, tiers, bg, content, card)` (what a card shows: tags checked against your honest CV, and `{p, band, hits, relevant, knockout}` for quick, tailored and referral) and `apply_card(cfg, tiers, bg, content, card_uid, tailored, referral)`. P is frozen when the application is sent, rounded to 9 decimals so a Continue rolls against exactly the same P.
- **The day:** `sleep(cfg, tiers = {}, bg = null, content = {}, rng = null) -> Dictionary`, `start_day() -> bool`, `take_invite(invite_uid)`, static `reject_mail_id(content, app_uid)`.
- **Interview and offer** (removed 2026-09-29, DECISIONS D9): `roll_probe`, `settle_probe`, `background_check_caught` and `rescind_offer` are gone with the lie probe and the background check.
- **The offer and the job (Step 6):** `make_offer(cfg, tier, bg, content, composure_left)` builds the whole offer from the interview checkpoint (so `finish_interview()` calls it before clearing the checkpoint) and returns a copy; static `offer_rng(interview_seed)` (section 7.2); static `offer_commute(office_days, commute_minutes)`; static `fine_print_pool(emails, tier_id, perks)` (Step 7 review); `decline_ends_run()` (rent at 0: a Decline on the grace day is Plan B, GDD 5.10); `hire(cfg, bg, company_red_flags)` (Accept: the offer becomes `employment` and is scored into `dream_score`; the offer itself stays); `dream_breakdown(cfg, bg)` (the Hired card's five rows, from the numbers `hire()` scored).

**Sleep is one committed action.** `sleep()` runs the night tick (day +1, rent -1 down to 0, energy refilled, today's interview slot freed, `day_mail` cleared, every board card one day older), then the whole morning: invites expire, applications due today reveal in send order (the Radar moves as each one resolves), the day-2 guarantee, ghosting, the board refill, the "saw your profile" fallback and the rent check. The result is stored in `run.morning_report` and returned:

| Key | Holds |
|---|---|
| `day` | the new day |
| `night` | `{applied, rejected, ghosted, rent_days_left}`: the lock-screen summary |
| `invites` | the invites that arrived this morning, inbox first |
| `rejections` | `[{app_uid, company_id, template_id, tier, knockout, mail_id}]` in send order. `knockout` is `{id, args}` into `postings.json`, or `{}`; `mail_id` is `mail_knockout`, or for a plain rejection the `mail_reject_*` line that `reject_mail_id()` picks |
| `no_reply` | how many applications revealed silent (including ghost jobs) |
| `ghosted` | `[{app_uid, company_id, template_id, tier, days}]` |
| `expired` | `[{invite_uid, app_uid, company_id, template_id, tier, mail_id}]` ("filled internally") |
| `radar` | `{before, after, max}` |
| `guarantee` | `""`, `"guarantee"` or `"profile"` |
| `board_new` | how many cards were dealt |
| `grace_day`, `plan_b`, `rent_days_left` | the rent check (GDD 5.10) |

- Called with `cfg` alone (the Step 1 form), `sleep()` runs only the night tick and returns `{}`.
- The hunt scene plays the night summary, then Mail's morning inbox, from that report. "Start day" (`start_day()`) moves the report to `day_mail`, so Mail keeps showing the day's mail until the next Sleep, and returns `plan_b`. A kill between night and morning can therefore never lose or repeat a reveal.

**Hunt rules that the GDD fixes deliberately:**
- **Outcomes are rolled on the reveal morning, in send order**, not at send time.
- **The Radar counts only relevant applications** (at least 2 of 3 tags) and never counts knockout failures.
- **The day-2 guarantee applies to the first run only** (`run.first_run`).
- Invites are valid for 2 days, with at most 1 interview per day.

**Step 5 agent defaults** (please review; `test_hunt_defaults` pins them):
- **A dry deck falls back.** A tier deals from its MVP companies first. Once none of their template+company pairs is free, the tier's other companies step in, so the board never starves (38 pairs with the 6 MVP companies, 58 with all 9; GDD 5.6).
- **A blacklist is immediate** (a declined offer; BUSTED and a rescinded offer also blacklisted until D9 removed them). The company's cards leave the board at once, its waiting invites are withdrawn without a mail (their applications end "expired"), and its pending applications reveal silent, without dice.
- **A plain rejection's email is picked from the application's uid**, without dice, so a resume or a replayed Sleep shows the same line.
- **The guarantee never picks a ghost job or a blacklisted company.** The "saw your profile" fallback takes the startup card with the best tailored odds; ties go to the oldest card, never to deck order. With only ghost startup cards left, there is no fallback invite.
- **`passes_years` stays a yes/no.** A line that counts as years passes every years knockout, whatever `min_years` says.
- **The lie probe** (removed 2026-09-29, DECISIONS D9). Every application sends only true CV lines, so nothing is probed.
- **The background check** (removed 2026-09-29, DECISIONS D9). Accept always hires; no offer is rescinded.

**Step 6 agent defaults** (please review; `test_offer`, `test_endings` and `test_flow` pin them; the build logs in `.project/evidence/STEP-06/2026-09-27-r1/` list the screen-level ones):
- **Startup equity is its own contract field** ("Equity: 0.0001%", under the salary). S10 has no Equity line, and `fp_equity` is one of the startup fine-print picks, so a startup contract can mention equity twice.
- **The offer's one tip:** a startup offer (it carries the equity) shows `tip_equity_lottery`; every other offer `tip_total_comp`. `tip_negotiate` was removed with Negotiate (D-27).
- **The Plan B tip matches the cause:** no invite all run -> `tip_tailor_over_spray`; invites that led nowhere -> `tip_rejection_numbers`.
- **The Dream vs Reality rows** are `Odds.dream_breakdown`: `dream_score`'s five terms, unrounded, added in the same order, so the card's rounded sum is always `dream_score`. The grade bands are `Odds.DREAM_GRADE_MINS` (40 / 60 / 80), fixed GDD 5.9.5 rules rather than tuning.
- **A run counts once** (settings `run_count`, which `first_run` reads) when its save is deleted: entering Plan B, or leaving the Hired card. Not on Accept, because a kill on the Hired card resumes at the offer. A run abandoned with New game is never counted.

**Step 7 review** (`test_hunt_tips` and `test_offer` pin these):
- **A closed coach mark stays closed for the run** (`coach_closed`, written at once by `GameState.close_coach_mark`, because Quit to title writes no save), and the next mark still waits for its own rule (section 11.4). Agent defaults, please review (DECISIONS A32, A33).
- **The fine print never repeats a perk** (`fine_print_pool`, above): one of the REVIEW_QUEUE wording fixes (DECISIONS C2).

### 7.2 Seeded randomness

- **One run RNG.** `GameState.rng` is seeded in `choose_background()`. The global `randi()` is used only to pick that seed.
- **The interview gets its own RNG.**
  - `start_interview()` rolls on the run RNG in this order: `interview.seed`, then the questions and the warm-up (`InterviewPlan.pick`). Then it saves the checkpoint. (The lie-probe roll that came third was removed on 2026-09-29, DECISIONS D9.)
  - The interview scene seeds a fresh `RandomNumberGenerator` from the seed (`InterviewPlan.interview_rng`).
  - Each Answer Meter gets a generator of its own, seeded from one roll of the interview RNG (`InterviewPlan.meter_rng`). The pivot only rolls if you tap after it, so rolling it on the interview RNG itself would shift every later roll.
  - The committee wheel is rolled before it spins.
  - So a resume replays the same luck, zone centres, pivots and wheel however early or late you tap, and the run RNG doesn't move during the interview.
- **The offer gets its own dice** (Step 6). `RunState.offer_rng(interview.seed)` seeds a fresh generator from the checkpoint's seed plus a salt (`"|offer"`, hashed), so it never replays the interview's own rolls. `make_offer()` picks the 2 perks, then the fine print (from `fine_print_pool`), on it. A replayed interview builds the same contract, and neither the run RNG nor the global RNG moves.
- **Accept rolls no dice.** The background check that rolled on the run RNG at Accept was removed on 2026-09-29 (DECISIONS D9), so `GameState.answer_offer(true)` and `RunState.hire()` use no RNG at all. Accept writes no save (section 8), so after a kill on the Hired card, accepting again hires the same job (`test_accept_after_a_hired_kill_hires_the_same_job`).
- **The VS plate takes turns without dice** (Step 7 review): `InterviewPlan.vs_plate(run)` picks Dana's one joke stat and one special move by `posmod(run.times_met_dana, 3)`, so a resumed interview shows the same lines (INV-04).
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
| When it's written | **Only while the run is live** (`JOB_HUNT`, `INTERVIEW`, `OFFER`, and the career run's `WORK` and `LAYOFF`). Three triggers: after every committed action (`_commit()`); on every change into those phases; and on `NOTIFICATION_APPLICATION_PAUSED`, `APPLICATION_FOCUS_OUT` and `WM_CLOSE_REQUEST` |
| Never written on | entering TITLE, INTRO, BACKGROUND_SELECT, PHASE2_STUB or GAME_OVER |
| Deleted when | **entering GAME_OVER**, and **leaving PHASE2_STUB** (Title or New run). `change_phase()` deletes it and counts the finished run in the same place (`run_count`, below) |
| Accept and the Hired card | Accept writes **no** save: PHASE2_STUB is never saved, so the file on disk stays the OFFER one. Killing the app on the Hired card resumes at the offer with the same contract, and accepting again hires the same job (section 7.2) |
| Committed actions | apply, tailor, skip, research, study, network, closing a first-run coach mark (`close_coach_mark`, Step 7 review), sleep, start day, start interview, interview result (a win saves the whole offer with the OFFER phase), an offer decision that stays in the run (Decline: saved with JOB_HUNT). The CV change and the rescind were removed on 2026-09-29 (DECISIONS D9), and negotiate on 2026-10-07 (D-27) |
| Interview | `start_interview()` checks today's slot and the energy, takes the invite out of Mail, pays, then freezes a **checkpoint** in `run.interview`: `invite_uid`, `company_id`, `template_id`, `tier`, `seed`, `question_ids` (in prompt order), `warmup_id` (`""` except on the first interview of the first run) and `tired`. (An old save's `probe_line` is never read, section 7.1.) `change_phase(INTERVIEW)` saves it. Doubt, Composure and the prompt index live in the scene, so a resume **restarts that interview with the same seed and the same questions** (GDD 5.11). Saves during the interview rewrite the same checkpoint, which is harmless. `finish_interview()` clears it |
| Continue | `SaveIO.kind()` says which run the slot holds. Phase 1's: `SaveIO.read()`, then `GameFlow.can_resume(saved.phase)` must be true, or it falls back to `start_new_game()`; then set the seed, then the state, then `change_phase(saved)`. A career run's: `WorkSession.from_save` (section 19.4), paused |
| Retry / New run | `retry()` builds a **fresh `RunState`** and remembers `preselect_background` |
| Versioning | `RunState.VERSION = 1`. When the format changes, bump it and migrate the dictionary at the top of `from_dict`. The career run's save is `version: 2` (`SaveIO.CAREER_VERSION`, `{version, phase, sim, ui}`: section 19.4) |
| JSON gotchas | numbers come back as floats (`from_dict` turns whole ones back into ints, recursively); no Vector2 or Color; 64-bit values travel as strings |
| Security | **Never load `.tres` or `.res` from `user://`**: a resource file can carry a script that runs on load. `JSON.to_native` defaults to `allow_objects=false` (verified 4.7.2), and we use `JSON.parse_string` anyway |
| Settings | `user://settings.cfg` (ConfigFile), separate from the run, written only by the game. `[meta]` holds `intro_seen` (set by `finish_intro()`), `run_count` (a run counts once, when `change_phase()` deletes its save: Plan B or leaving the Hired card; `first_run` is `run_count == 0`, read through `GameState.next_run_is_first()`; the debug-only title button "Reset first run" sets it back to 0), `last_background` (Background select preselects it), and later `tips_unlocked` (SHOULD) and `best_dream_<bg>` (LATER, DECISIONS D10); neither is written yet. `[options]` holds `haptics`, `relaxed_timing`, `reduced_motion`, `text_speed` (40 / 80 / 0 = instant) and `music_db` / `sfx_db` (SHOULD) |
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
| The intro loses focus (`APPLICATION_FOCUS_OUT` or `PAUSED`) | `intro.gd` | pauses the pan and typewriter tweens and cancels a hold on the skip pill; `FOCUS_IN` / `RESUMED` plays them on. There is no "Ready?" overlay: the intro waits for taps anyway |

Phones kill background apps without warning, which is why saving happens on pause and on focus loss, not on quit. On iOS, after `APPLICATION_PAUSED` the app gets about 5 s before iOS may kill it, so keep `save()` small (verified: 4.7.2 `os_apple_embedded.mm`). The notification constants are verified 4.7.2.

**iOS has no Back button** (`NOTIFICATION_WM_GO_BACK_REQUEST` is implemented only on Android; verified 4.7.2 `Node.xml`), and games get no edge-swipe back gesture. So every screen shows its own on-screen Back: the action bar's bottom-left `[ < Back ]` (on the offer, a row of its own above `[ Decline ][ ACCEPT ]`), `[ < Title ]` on Background select and the ending cards, `[=]` on the hub, `[II]` in the interview, and the intro's "Hold to skip" pill. There are **no Quit buttons on iOS**.

**The Back chain:**
1. On-screen Back buttons, Android Back (LATER) and desktop Esc all call `Device.handle_back()`.
2. **Every node** receives `WM_GO_BACK_REQUEST` (verified 4.7.2), so **scenes must not handle that notification themselves.**
3. Instead, every screen root implements `handle_back() -> bool`. Return `true` if it used the press.
4. `Device.handle_back()` ignores Back while `SceneRouter.busy`. Otherwise it asks the current scene. If the scene returns false, `Device` emits `back_unhandled`.

| Screen | `handle_back()` |
|---|---|
| Title | pass Back to the open debug device check (it counts presses) or close an open dialog; else show "Quit?" (Android and desktop only; iOS apps never quit themselves). Confirm calls `get_tree().quit()` |
| Intro | `finish_intro()` (skip). It has no `[ < Back ]` button: a one-tap skip next to hold-to-skip would defeat the hold, so the pill is its on-screen way out |
| Background select | `quit_to_title()`. While you type the name, the field takes the first Esc (typing ends), and a tap anywhere outside the field also ends typing, because the iOS keyboard hides `[ < Title ]` |
| Job hunt | close the top modal (Pause, the Sleep confirm, the night screen); wait while a card is flying; flip the card back; or return from an app (Mail, Study) to Jobs, except during the morning; else open Pause |
| Interview | Pause open: resume; the "Ready?" overlay: open Pause (during an ending beat: resume only); Ducky's card: `[ Back to the hunt ]`; an ending beat (K.O., the committee banner and wheel, a rejection): nothing, taps advance it, and `[II]` is hidden from the first ending beat on, so Pause > Quit to title > Continue can't replay an interview whose ending you've seen; the VS intro: Back acts like a tap (`VersusIntro.tap()`: nothing before the slam, then jump to the clip's end, then continue), so there is no Pause during the VS intro; else open Pause |
| Offer | the Decline confirm open: cancel it; Pause open: resume; Dana's Decline line: move on (that commits the Decline); after ACCEPT: nothing; else open Pause. Back never declines an offer |
| Hired | beat 1: move on to the tally, like a tap; after that: `quit_to_title()` (a tap finishes the tally; Back leaves) |
| Plan B | `quit_to_title()` |

**Kill tests.** [`docs/KILL_TESTS.md`](KILL_TESTS.md) is the checklist for the ROADMAP Step 6 iPhone check (still the developer's under DECISIONS W7): kill the game at 5 moments (mid-hunt, right after Sleep, mid-interview, on the offer, on the Hired card) and check that CONTINUE puts you back where this section and section 8 say. It also gives the desktop equivalent (stop the game from the editor, which is harsher: no pause notification). All 5 passed on the Windows PC on 2026-09-27; the iPhone row is yours.

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
- **Type variations:** `PrimaryButton`, `DangerButton`, `PaperPanel`, `HeaderLabel`; Step 5 added `SelectorButton` (toggle buttons: the S03 selector, the referral toggle, the hub's DEBUG toggle; the CV segments used it until D9), `DockButton` (the hub's dock), `Chip` (the job card's knockout chips) and `GoldPill` ("Invite waiting"). Step 6's `ProbeButton` (the lie probe's Come clean / Bluff) was removed on 2026-09-29 with the probe (DECISIONS D9; its padding trick is in section 1.4).
- **Labels:** `Label/constants/line_spacing = -1`, for the 12 px line pitch (section 1.4, DECISIONS A3). Primary-button labels are upper-cased and Back labels get "< " by `UiText` (section 17.15), not by the theme.
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
7. **Buttons use `action_mode` Button Release** (the default). Whether dragging a ScrollContainer triggers a release is **unverified on the iPhone**; test it in Step 2.
   - Desktop result (Step 2, `.project/evidence/STEP-02/2026-09-27-pc/`): with default STOP buttons, a drag that starts on a row doesn't scroll the list at all. With `mouse_filter = PASS` rows it scrolls, never fires the row, and taps still fire: the ScrollContainer cancels the press.
   - So buttons inside a scrolling list use PASS (Mail's buttons; the CV rows' segments until D9). Mail's invite coach note passes its events on too, so a drag that starts on it still scrolls (section 11.4). A saved scene bakes the project's scroll deadzone into its ScrollContainer, so the lists re-read `gui/common/default_scroll_deadzone` in `_ready()`.
   - If the iPhone still fires a row on a drag, also ignore a release when the pointer moved more than the deadzone since the press.
8. **No typing** except the optional name field (10 characters); the dice button is the main path. The iOS keyboard covers roughly the bottom 40% in portrait, so the name row lifts above it while typing, using `Device.keyboard_height()`: it reads `DisplayServer.virtual_keyboard_get_height()` (implemented on iOS), assumes native pixels and divides by the scale, as `safe_insets()` does. The unit is unverified until the iPhone test (section 18.1 #12).

### 10.4 Text

- The typewriter runs at 40 chars/s (`typewriter_cps`). Tween `Label.visible_ratio` (verified 4.7.2). The first tap finishes the line; the second advances.
- **Text always sits on solid panels**, never directly over dithered sky or parallax.
- A full-width panel is 254 px outside and 240 px of text: 40 characters at monogram 16.
- The GDD 2.7 text budgets (120 / 100 / 40 / 80 / 60 / 120 / 240) and their line caps at 40 columns are enforced by `test_content_lint` (section 12.3).

### 10.5 Shared components (Step 7 review)

`hp_bar` and `stat_bar` were plain W3 placeholders until Claude built them in the Step 7 review (DECISIONS W7). Both are `@tool` Controls that draw themselves in `_draw()`, so the editor shows them and the editor-side tests can build one (section 12.1); they never animate in the editor. `test_bars` tests them. The look and feel choices are agent defaults for your review (DECISIONS A40-A45).

- **`HpBar`** (`ui/components/hp_bar.gd` + `.tscn`, 122x8; the interview's Composure and Doubt bars, GDD S08 and 9.1). API: `fill_color`, `max_value`, `value`, static `fill_px(amount, full, width)` and `ghost_value()`.
  - When the value drops, the coloured fill jumps to it and a white ghost over the lost part shrinks to the new value over `GHOST_SEC` (0.4 s, eased in, quad), so it lingers, then catches up. A rise just jumps. A second hit mid-drain continues from where the ghost is.
  - Widths are whole pixels (section 1.3), so the ghost shrinks 1 px at a time. Anything above 0 shows at least 1 px, so a sliver of Doubt never reads as a K.O. Values are clamped to 0..`max_value` for display.
  - Setting `max_value` settles the bar with no ghost, so the interview start and a resume (which rebuilds the scene) never animate.
  - The ghost's tween belongs to the bar node, so it stops while the tree is paused (Pause, focus loss).
  - Colours: background `#181425` (the palette's darkest ink), ghost white. Both bars fill left to right; mirroring Composure so both anchor at the centre is a design question for the developer.
- **`StatBar`** (`ui/components/stat_bar.gd` + `.tscn`; a Control, it was a Label): a stat (0-100) as 5 blocks of 7x7 px, 1 px apart. Filled blocks = static `filled_segments(value)` = `clampi(roundi(value * 5 / 100.0), 0, 5)` (value / 20, rounded, GDD 5.1).
  - Its minimum size is 39x13, one monogram 16 line: the blocks sit on rows 4-10, the capitals of the label beside it, so a row of text keeps its 13 px height.
  - Filled amber `#FEAE34` (the PrimaryButton amber), empty `#181425`. `mouse_filter` IGNORE.
  - Used on the S03 background card (3 bars), the Study app's KNOWLEDGE row, and the VS intro's player plate (3 bars). The hub HUD has no stat bar.
- **`DuckyNote`** (`ui/components/ducky_note.tscn`): the 254 px Ducky tip note. Every node in it is IGNORE, so it never blocks input, unless `closable = true`: then it shows a small "x" (`DuckyNote.CLOSE_MARK`, a placeholder until the art pass) at the header's right end and takes its own tap. A tap counts on release, like a Button (press and release both on the note, no drag past the 6 px scroll deadzone) and emits `close_tapped`; the owner hides the note. The note is PASS: inside a ScrollContainer it lets the events go on, so a drag that starts on it still scrolls; elsewhere it accepts them, so the control under it never sees the tap. Closable notes: the first-run coach marks (section 11.4) and the offer's tip (section 11.7).

---

## 11. Building each feature

### 11.1 Title (S01)

- Static art in the GDD 2.5 portrait template (parallax SHOULD): the logo on a sign panel in the sky band (Press Start 2P 24 and 16), skyline and street in the middle, the road under the buttons, the version from `application/config/version` bottom-right.
- **Tap anywhere** calls `start_new_game()` ("Tap to start" blinks in the thumb band).
  - When `SaveIO.exists()`, show two stacked buttons instead: `[ New game ]` above a full-width primary `[ CONTINUE ]`.
  - A small "Replay intro" text button bottom-left calls `replay_intro()`.
- `handle_back()` shows "Quit?" on Android and desktop only; never on iOS.
- As built in Step 3 (section 17.12; DECISIONS A4): with a save, tap-anywhere is off and only the two buttons start play; "Replay intro" always shows. The Step 1 stub's size readout survives as a debug-only `%SizeReadout` in the sky band, and debug builds also show a `%DebugRow` above the bottom row with the "Device check" button (DECISIONS A1) and "Reset first run" (A51: `GameState.reset_first_run()` sets `run_count` to 0, so the next New game gets the first-run coach marks, the day-2 guarantee and the warm-up again; the button is off when the next run already is a first run). The whole row is hidden in release builds. The art is still grey boxes.

### 11.2 Intro cutscene (S02)

As built in Step 6 (text slides with grey placeholders; the art arrives in Step 11). Files: `intro.tscn` + `intro.gd`, `cutscene_plan.gd` (`CutscenePlan`, section 17.17), `hold_skip_pill.gd` (`HoldSkipPill`).

```
Intro (Control, full rect, STOP: it takes every tap no control takes)   intro.gd
├─ Background (near-black ColorRect, full-bleed)
├─ Stage (CenterContainer, full rect) > Frame (270x480, clips) > Picture (TextureRect)
├─ SafeArea > Column (254)
│  ├─ TopBand: DebugReadout (debug builds only: "intro_p3  caption 1/3")
│  ├─ Body (EXPAND_FILL): TitleCard (PanelContainer, HeaderLabel in Press Start 2P 24, centred)
│  └─ ThumbBand: DialogueBox (254x72: Panel, NameTab, Line; y 360-432 on 270x480)
│                ActionBar (34 px): TapHintPanel ("Tap to continue") ... SkipPill (96x34, y 442-476)
└─ ModalLayer
```

- **Data-driven from `cutscene.json`** through `CutscenePlan.panels(Content.entries("cutscene"))`: the panels in `order` (ties by id), each `{id, order, seconds, captions [{speaker, text, style}]}`. Entries without an `order` or without a caption with text are skipped; an empty or missing file goes straight to Background select.
- **Each panel's picture** sits in the 270x480 `Frame` (the base size read from Project Settings, INV-19), centred on the near-black on taller phones, and pans over the panel's `seconds` with one sine in-out Tween. `CutscenePlan.pan_path()` sets the motion from the picture's size (GDD 2.6): wider than the frame pans sideways, taller tilts down, frame-sized stays still, in whole pixels. **No zoom:** zooming scales art by non-integer factors (section 1.3). The grey box is a generated 294x480 checkerboard, one shade per panel, so each drifts 24 px and the cuts show.
- **Captions** are typed at `typewriter_cps` (section 10.4) in the scene's own dialogue box (4 lines). A speaker's name shows in capitals in the amber name tab; narration shows none. `Line` uses `CHARS_AFTER_SHAPING`, so words never jump lines while typing. The box hides with `modulate`, never `hide()`, so nothing jumps when it comes back.
- **The title card:** a caption with `"style": "title"` cuts the picture to black, hides the box and slams the title in on its own panel (2x for 0.05 s, then 1x, a 40 ms haptic, as the ending stamps). It stays up under the last caption.
- **Taps** act on the press: a tap finishes the caption being typed; the next shows the next caption, then the next panel; the tap after the last caption ends the intro. A tap never skips everything, and taps during the scene fade do nothing. **No auto-advance** (agent default): `seconds` is only how long the picture pans, and the intro waits for taps. "Tap to continue" shows on its own panel bottom-left once caption 1 is typed, until the first advancing tap.
- **Skip:** `HoldSkipPill` bottom-right. Hold it for 0.5 s while a ring fills; letting go early empties the ring, so a stray tap never skips. Desktop Esc and Android Back (LATER) skip at once through `handle_back()`. There is no `[ < Back ]` button (section 9).
- **Every exit** (the last tap, the pill, Back) goes through `_leave()` once, which calls `finish_intro()`; that sets `intro_seen`, so skipping is always safe.
- It auto-plays only when `intro_seen` is false (`start_new_game()`); the title's "Replay intro" plays it again. Losing focus pauses the pan and the typewriter and cancels a hold (section 9).
- **Cost warning:** frame-by-frame animation is out of scope. This is a motion comic: pans, tilts, 2-4 frame loops and captions.

### 11.3 Background select (S03)

As built in Step 5 (`background_select.tscn`, `background_card.tscn`, `dice_button.gd`):
- **One full-width `background_card.tscn`** (254 wide; its height follows its content), showing numbers from `BackgroundData` and text from `backgrounds.json`:
  - a 60x72 bust placeholder (the 96 px bust cropped to its top 72 px arrives with the art), then "title - difficulty"
  - energy pips with the commute pips greyed out (`PipBar`), and the runway days
  - the one-liner, 3 stat bars (`StatBar`, section 10.5: 5 amber 7x7 blocks, value / 20, rounded), a perk (+) and a flaw (-)
  - the Self-Taught's two gap topics under the flaw
- Below it, in the thumb band: the name row (label, a `LineEdit` 34 px tall with `max_length = 10`, a 34x34 dice button), a **3-button selector** (80x40 each, two lines: INTERN / EASY, GRADUATE / MEDIUM, SELF-TAUGHT / HARD) and `[ < Title ][ CHOOSE ]` (80 + 168).
- **Switching:** tap a selector button, or swipe the card (it reads raw touch like the job card: a quarter of the base width, with a haptic when the drag crosses it). The ends don't wrap, and the new card slides in from the side. CHOOSE confirms.
- **The run seed is picked when the screen opens** (`GameState.new_run_seed()`), so the Self-Taught's card shows the very gaps the run will roll (`preview_gap_topics()`: the gap roll is the run RNG's first draw after seeding). CHOOSE calls `choose_background(id, name, run_seed)`.
- The name field shows "Alex"; the dice picks a different name from `names.json` (cosmetic, so it uses its own unseeded RNG). While typing, `Device.keyboard_height()` hides the selector and the action bar behind a spacer as tall as the keyboard, and the card too when the screen is short (section 10.3 rule 8). Typing ends with the keyboard's Return, Esc, or (since Step 6) a tap anywhere outside the field, because the keyboard hides `[ < Title ]`. An empty name falls back to "Alex".
- `preselect_background` (settings meta `last_background`, or the run's background after Retry) picks the card; otherwise The Graduate.
- Not built yet: the card flying up and the phone "booting" DoomApply (0.35 s). The SceneRouter fade covers the change for now.

### 11.4 Job hunt (S04-S06)

As built in Step 5 (grey boxes; the files are listed in section 2):
- **`job_hunt.tscn` is one scene: your phone running the DoomApply app** (GDD S04). From the top: the HUD (information only: day, rent in red from `rent_warning_days`, energy pips with "n/m", and the Radar as a text meter), the app header (the app's name, plus a gold "Invite waiting" pill), the body, the action row, and a **bottom dock**.
  - **Dock** (`dock_button.gd`): 4 slots of 60x40 px, 4 px apart (5 of 47x40 px until the CV slot was removed on 2026-09-29, DECISIONS D9), each a 16x16 icon (drawn placeholders) above a label of up to 6 characters: Jobs, Mail, Study, and Sleep (the moon) at the right end. Network (SHOULD) will need one more, narrower slot. Mail shows a gold badge while an invite is waiting.
  - The body swaps **panels, not scenes:** Jobs (the deck), Mail (`mail_screen.gd`), Study (BigOhNo: the KNOWLEDGE `StatBar`, a joke per study, `tip_fundamentals` on the first). Every app except Jobs shows `[ < Back ]` to Jobs, which is also what `handle_back()` does.
  - **Night** is a modal (`night_screen.tscn` in the ModalLayer): the lock screen's one notification card with the night numbers from `morning_report.night` and at most one tip (`HuntTips.night`, each once per run: the first referral -> `tip_referrals`; 8 Quick Applies without an invite -> `tip_tailor_over_spray`; after a Tailor & Apply, `tip_projects_count` when your honest CV fails "1+ years", then `tip_quantify_impact`. The last two moved here from the removed CV screen, D9). A tap or Back unlocks it; then the hub opens on Mail with the morning report. Until Start day, only Mail is open: the other dock slots and Sleep are disabled. A Continue between Sleep and Start day replays the night, then the same morning.
  - A rescinded offer opening the hub on Mail (removed 2026-09-29, DECISIONS D9): there is no background check, so no offer is rescinded.
- **The deck:** 6 new cards each morning (2 per tier), at most 10 on the board (section 7.1). The card (`job_card.tscn`) is 254 wide; with no card left, an "empty deck" note shows instead.
  - **Card front:** a 238x48 header strip (a tier-colored placeholder until the crops of the tier's interview background exist), a 16x16 logo placeholder, company and tier, title, 3 tags with a check or cross against your honest CV, the joke, a red knockout chip when your honest CV fails one, and the Quick Apply odds band.
  - **Action row:** `[=]` 34 px (Pause: the hub's on-screen Back), SKIP 80, `APPLY  1` 128 (APPLY spans the screen centre). Actions you can't afford are greyed out.
  - **Swipe right or APPLY** = Quick Apply (1 pip). **Swipe left or SKIP** = skip. **Tap** = flip.
  - **Card back:** title, company and tier, applicants, posted days ago (plus "Reposted"), salary text, the knockout chip, the tailored odds band, and the `[Use referral]` toggle (34 px tall; the odds switch to the referral quote). Research (SHOULD) is not built. The action row becomes `[ < Back ][ TAILOR & APPLY  2 ]`. Both faces stay in the layout, so the card keeps one height.
  - **Sending:** the first `full_scan_animations` (3) applications of a run play the Parsinator 3000 scan (1 s), every one the SENT stamp (0.3 s); then the card flies off (0.15 s) and the next one rises.
- **Card input:** `job_card.gd` reads `InputEventScreenTouch/Drag`. The front follows the drag's x, tilting at most 6 degrees, and plays a haptic when the drag crosses the threshold. On release:
  - a move over 68 px (a quarter of the base width) is a swipe (there is no flick detection);
  - a move under the scroll deadzone is a tap;
  - anything else settles back. The back doesn't swipe: its actions are on the action row.
- **The CV screen (Buzzwordsmith)** (removed 2026-09-29, DECISIONS D9, with `cv_screen.gd`, `cv_row.tscn`, the CV dock slot and the Honest / Polished / Lie control). Your CV is your background's true CV: Quick Apply sends it as it is, and the card back's TAILOR & APPLY sends every line as its honest Polished reframing for that one application (`RunState.cv_sent`). There is no separate "Polish CV" button: none of KNOWLEDGE, EXPERIENCE or NETWORK fits it, and Tailor & Apply already is the per-job polish.
- **Mail (`mail_screen.gd`):** one vertical `ScrollContainer` list, in this order: the grace-day line, the first-run coach mark, the waiting invites (`invite_card.tscn`: `[ Later ]` folds the card to its header; `[ GO NOW  3 ]` shows `interview_cost()` and is greyed out when `can_take_interview()` is false or on a Plan B morning), the expiry notices, the rejections as one stack card with [Flip all] (and `HuntTips.inbox`'s tip under it), the quiet no-reply footer and the Radar update. It shows `morning_report` before Start day and `day_mail` later that day; the invites are always the live `run.invites`. `[ START DAY ]` is the pinned action row below the scroll, full width, always visible during the morning.
- **Coach marks** (GDD 4.3, first run, day 1; `coach_mark.tscn`, `CoachMark`; agent defaults A30-A35): apply, flip, then Sleep (at `HuntTips.COACH_SLEEP_PIPS` = 2 energy or less, or after `COACH_SLEEP_APPS` = 4 applications), over the card's header strip; the first invite points at its GO NOW. The rule is `HuntTips.coach(run, has_card, card_back, flipped)` (returns `coach_apply` / `coach_flip` / `coach_sleep` / `""`) and `HuntTips.coach_invite(run)`. Since the Step 7 review (DECISIONS D11):
  - **A tap on the Ducky note closes the mark** at once, and doing the action still closes it too. This covers `coach_apply`, `coach_flip`, `coach_sleep` and Mail's invite mark (id `HuntTips.COACH_INVITE` = `"coach_invite"`, text `coach_invite_no_research`). The interview's `coach_meter` note is unchanged: it isn't tappable, because the Answer Meter takes taps anywhere.
  - The note shows a small "x" (`closable`, section 10.5). A tap counts on release, like a Button: press and release both on the note, with no drag past the 6 px scroll deadzone. Over the deck the note accepts the events, so the card under it never flips or swipes; inside Mail's ScrollContainer it passes them on, so a drag that starts on the note still scrolls. The arrow strip stays IGNORE. Since the review fix pass the tap rule lives in `DuckyNote` (`close_tapped`), and `CoachMark` only listens to it.
  - `CoachMark` API: `point(id, tip, target, swipe = false)` (the mark id is the first argument), `clear()`, `text()`, `signal closed(coach_id)`. `MailScreen` re-emits its mark's close as `signal coach_closed(coach_id)`. The hub connects both to `GameState.close_coach_mark`, which adds the id to `run.coach_closed` and saves at once (Quit to title writes no save).
  - A closed mark never shows again this run, and the next mark still waits for its own rule: closing Apply with no application shows nothing, and Flip waits for the first application.
  - Fix: the hub also refits the mark on `CoachMark.resized`. On its first show it used to be placed before its text had wrapped, so it sat mid-card over the title, tags and joke instead of over the header strip.
- **Rules** all sit on `RunState`, `Odds` and `HuntTips`. The scene only shows `run` and calls verbs:
  - `quick_apply(card_uid)`, `tailor_apply(card_uid, use_referral)`, `skip_card(card_uid)`, `card_odds(card)`
  - `study()`, `sleep()`, `start_day()`, `mark_tip_shown(tip_id)`, `close_coach_mark(coach_id)`
  - `start_interview(invite)` (Mail's GO NOW; from the morning inbox it calls `start_day()` first), `quit_to_title()`
- **Sleep** asks first when 2 or more pips are left: "You still have N energy. Sleep anyway?" with `[ < Back ][ SLEEP ]`.
- **Debug builds** show a DEBUG row above the deck: "Fake invite" for each tier (`debug_fake_invite(tier)`, then straight into its interview) and "Rent runs out" (`end_run_plan_b()`). With the row open, a Jobs coach note covers "Rent runs out" (a tap there closes the note); release builds have no DEBUG row.

### 11.5 VS intro (S07)

- **One reusable `versus_intro.tscn`**, with `play(company_id, tier)` and a `finished` signal. Build it with an **AnimationPlayer** (`animation_create` + `animation_manage`) so you can retime it in the editor.
- **Portrait split:** a diagonal across the middle (about y 210-270). Dana's half is on top (company color, tier background behind), her bust top-right with her plate to its left. Your half is below (hoodie color), your bust bottom-left with your plate to its right. The tier banner sits at the bottom.

| Time | What happens |
|---|---|
| 0.00 s | 1-frame white flash; the diagonal split appears |
| 0.05-0.35 s | busts slide in along the diagonal (Dana down from the top-right, you up from the bottom-left), easing out with a small overshoot |
| 0.35 s | "VS" (Press Start 2P 32) slams onto the diagonal, driven by a method track |
| 0.4-0.9 s | name plates, and the tier banner from `barks.json` (`vs_banner_*`, Press Start 2P 16, up to 2 lines) |
| 2.0 s | the last frame holds; "Tap to continue" (`ui_tap_to_continue`) blinks under the banner until a tap (Step 7 review, DECISIONS D12). Before the review this row was `finished` |

- **The slam at 0.35 s** (the method track):
  - a 100 ms hit-stop: `anim.pause()`, a timer, then `anim.play()`;
  - a 4 px whole-pixel shake;
  - `Device.haptic(40)` and a sound effect.
- **Skip (tap anywhere)** (removed in the Step 7 review with `vs_min_view_s`, DECISIONS D12): the screen no longer ends by itself, so there is nothing to skip. It waits for a tap instead:
- **`VersusIntro.tap() -> bool`** (a tap anywhere goes through `_gui_input`; the interview's Back calls it too, section 9). It returns false when the VS screen isn't showing. Before the slam (0.35 s) a tap is ignored, so the tap on GO NOW can't also skip it. During the rest of the clip it jumps to the last frame (`_hold()`: every key applied, so all the text shows, and the hint starts blinking). On the held frame it calls `_finish()`, which emits `finished`, and the interview starts Dana's greeting.
- **The hint** is `%TapHintPanel`, a PanelContainer of its own under the banner, so it reads on any hoodie colour. It is IGNORE and transparent until the hold, then blinks 0.5 s on / 0.5 s off (`BLINK_S`, 1 flash/s like the title's "Tap to start"; GDD 9.1 allows up to 3).
- **Less text** (D12; agent defaults A36-A39 and A46): Dana's plate shows her name, her title (`dana_title_<tier>`, 2 lines) and **one** joke stat, and the moves panel **one** special move. `InterviewPlan.vs_plate(run)` returns `{stat, move}` from `VS_DANA_STATS` (`vs_dana_stat_1..3`) and `VS_DANA_MOVES` (`vs_dana_move_1..3`, which replaced the one-line list `vs_dana_moves`), both at index `posmod(run.times_met_dana, 3)`, with no dice (section 7.2). Your plate is unchanged: name, nickname and 3 stats, now as `StatBar`s (section 10.5) in a 2-column GridContainer `PlayerStats` (h_separation 6, v_separation -1, so it keeps the old text rows' 170x37 size and the bars start where the "[###--]" text did).
- A resumed interview (Continue) plays the VS screen again and waits for the tap.
- **The clip starts after the scene fade** (review fix pass, 2026-09-29): `play()` runs while `SceneRouter` still fades the interview in, so it applies the 0.00 s keys, pauses on that frame with `Flash` hidden, awaits `SceneRouter.transition_finished`, then seeks to 0.00 again and plays. The fade reveals the first frame, and the flash and the bust slide-in are seen, as the offer paper waits for the fade (section 11.7).
- As built in Step 4 and the Step 7 review: the AnimationPlayer's `intro` clip holds this table and its method track calls `slam()`; `vs_duration_s` (2.0) stretches the whole clip to that length. The halves are grey-box colors by tier and hoodie (`VersusIntro.tier_color()`, `hoodie_color()`), and the sound effect arrives with the audio pass. `try_skip()`, `_process` and `_min_view_s` are gone.

### 11.6 Interview (S08-S09)

As built in Step 4 (grey boxes: ColorRect placeholders for the background, busts and desk):

```
Interview (Control, full rect)  interview.gd
├─ Stage (full-bleed; its bottom edge, the desk line, follows the DialogueBox's top)
│    TierBackground (330x400, bottom-anchored), PlayerBust (96 px, left), DanaBust (96 px, right), Desk
├─ AnswerMeter (full rect, hidden until a knowledge prompt; BELOW SafeArea, see the tap rule)
├─ SafeArea (every container and panel in it: mouse_filter = IGNORE)
│  └─ Column (VBox, 254 wide, separation 0; y values from GDD S08)
│     ├─ BarsBand (y 0-28): labels COMPOSURE · "ROUND 2/5" · DOUBT, then ComposureBar and DoubtBar
│     │                     (HpBar, 122x8 each: the white ghost bar, section 10.5)
│     ├─ StageSpacer (EXPAND_FILL, empty: the stage shows through; 160 px on 270x480, 248 on an iPhone 15)
│     ├─ DialogueBox (254x76): NameTab, Line (4 lines), PauseButton [II] (34x34 hit area) at its top-right
│     └─ AnswerArea (212 px, glued to the bottom safe edge)
│        ├─ MeterRow (40 px): the Answer Meter's bar is drawn 15 px down it; the zone labels are drawn
│        │                    on the row itself (Vague above the bar, the others below)
│        └─ ThumbSlot (one child visible at a time): AnswerColumn (3 x 254x36, gap 6) | TapPad (120 px:
│             "Tap anywhere!", "TIRED: needle is faster") | DuckyCard (a full-width DuckyNote +
│             [ Back to the hunt ]). The lie probe's ProbeRow was removed on 2026-09-29 (DECISIONS D9)
├─ VersusIntro (instance, full rect)
├─ ResultLayer (covers the stage band): CoachNote (the warm-up's Ducky line), KOBanner, CommitteeWheel (128 px)
├─ DebugLayer (debug builds only; freed in release): the DBG toggle (34x34, stage band top-left) and its grid
├─ ReadyOverlay (full rect, process_mode = When Paused)
└─ ModalLayer (CanvasLayer): PauseMenu
```

**The tap rule (GDD 2.8 rule 6):** any tap counts for the needle except `[II]`, which consumes its own tap. Containers default to `mouse_filter` PASS (verified 4.7.2 ClassDB), and a PASS container on top would swallow the tap. So the AnswerMeter sits below SafeArea in the tree, and every container and panel in SafeArea is set to IGNORE. A tap that misses a real control then falls through to the meter, while `[II]` (a Button, STOP) keeps its own.

**Keeping the stage on the desk line:** on `resized`, `Device.layout_changed` and when the dialogue box, the stage spacer or the meter row move, set the Stage's bottom to `%DialogueBox`'s top, so extra height shows more wall and sky above the characters, never more floor. The same pass fits the ResultLayer over the stage band and passes the meter row's y to `AnswerMeter.set_bar_y()`.

**The flow in `interview.gd`** is one coroutine, `_run()`, written with `await`. Every wait goes through `_wait()`, so a forced debug outcome can park the flow it replaces.

1. **Set up** from the checkpoint (section 8).
   - The interview RNG is `InterviewPlan.interview_rng(run.interview.seed)`.
   - The prompts are `InterviewPlan.prompts(question_ids, choice_pool)`: one per `cfg.prompt_pattern` slot (`[choice, knowledge, knowledge, knowledge, choice]`). Every knowledge slot asks a knowledge question; an old save's `probe_line` is never read.
   - Doubt = `tier.doubt_hp`; Composure = `bg.composure_max`.
2. **Open.** Play the VS intro and wait for its `finished` (after your tap, section 11.5). Then the greeting: `bark_dana_greet_again` ({last_company}) once you have met Dana this run, else `bark_dana_greet_<tier>`; then the background's `dana_opener` on the first interview of a run; then `bark_dana_tired` if you arrived Tired.
3. **The warm-up** (`warmup_id`, only on the first interview of the first run) comes before prompt 2: a knowledge prompt labelled "WARM-UP - DOESN'T COUNT" (`vs_warmup`), with Ducky's `coach_meter` note. It changes neither Doubt nor Composure (DECISIONS A6).
4. **Choice prompt.** Type out the prompt in the dialogue box (the Step 7 review rewrote every choice question in plain language for non-tech players, DECISIONS C3; ids, tiers and tips are unchanged). Show 3 stacked answer buttons in the thumb band, shuffled with `Odds.shuffled` on the interview RNG (your background's exclusive answer replaces the neutral one), after the 250 ms lock. When one is tapped, apply `Odds.ethics_doubt_delta` (teamwork questions use `Odds.teamwork_mult`) and `ethics_composure_loss`, then show Dana's reaction.
5. **Knowledge prompt.** Compute P, S (luck on the interview RNG), h (the Graduate's `textbook_zone_bonus` on the first real knowledge prompt) and the needle speed (Tired: faster), then show the TapPad and `meter.start(..., InterviewPlan.meter_rng(rng))`.
   - **The zone and its labels show while Dana asks; the needle starts when her line ends** (DECISIONS A8). That is the visible-luck rule.
   - `await meter.resolved`, then Q from `Odds.answer_q` and the deltas; the input grade (PERFECT, GOOD, CLOSE, ...uhh) shows over the needle.
   - Your character speaks the green, yellow or red line in the dialogue box; on red, Ducky's "Real answer: ..." appears as a full-width note in the thumb band. Then Dana reacts (`bark_dana_great_*`, `_ok_*`, `_bad_*`).
6. **Lie probe** (removed 2026-09-29, DECISIONS D9, with Come clean / Bluff, BUSTED, their barks and tips, `Odds.bluff_p` / `bluff_band` and the ProbeRow). Knowledge prompt 2 is always a knowledge question.
7. **After each prompt:** Doubt at or below 0 is a **K.O.** ("K.O.!" for 0.5 s, then "OFFER!"); Composure at or below 0 is a rejection. From the first ending beat (K.O., the committee banner, a rejection) `[II]` hides and Back does nothing but resume a "Ready?" overlay (Step 6, section 9).
8. **After prompt 5:**
   - If `committee_eligible`, roll the result on the interview RNG, then spin the wheel in the stage band for 2 s with its win wedge drawn at `committee_win_p`. A loss is a rejection with `tip_research_company`.
   - Otherwise it's a rejection. The thumb band becomes the Ducky card: one tip (DECISIONS A9), the model answer of your worst knowledge question, and a full-width `[ Back to the hunt ]`.
9. **Finish.** Call `GameState.finish_interview(won, composure_left)`. It counts the interview, builds the whole offer on a win (`RunState.make_offer`, section 7.1) and clears the checkpoint. (Its `busted` and `came_clean` arguments went with the probe, D9.)

**The Answer Meter** (section 17.11):
- **Position:** it draws its bar at the y the scene passes to `set_bar_y()`: 15 px down the MeterRow, in the meter's own coordinates. Before the first call it falls back to 40 px above its own bottom edge. So the TapPad sits under the thumb and never covers the needle. `answer_meter_width_px` stays 200 (GDD S08).
- `zone()` returns the zone as (centre, half-width), so the scene can place the zone labels. The Vague band is clipped to the bar (c - 2h can be below 0, c + 2h above 1).
- The tech-verified bug is fixed: it calls `set_process(false)` in `_ready()`, and `_process` returns when `_done`.
- The needle speed is at least 0.6 bar-widths/s and the zone half-width at least 0.06, so the GOOD window is at least about 160 ms.
- **Relaxed Timing** (settings `options/relaxed_timing`) fixes the input quality at 0.9.
- On a startup interview, the zone jumps once between 1.0 and 2.5 s and emits `zone_jumped`. The scene shows "PIVOT!" in the zone label for 0.6 s and switches Dana's line to `bark_dana_pivot`.
- The meter has its own 250 ms lock: it ignores taps for the first `input_lock_ms` of needle time. After a pause the scene adds one more lock, so the tap that closed "Ready?" or Pause can't also stop the needle.
- On the tap it plays a haptic (20 ms for PERFECT, else 10 ms) and emits `resolved(input_quality)`; no tap after `max_round_trips` (3) is a miss.

**Debug** (debug builds only):
- Launched alone (`project_run mode="custom"`, `run.background_id` empty), `_ready()` calls `GameState.debug_quick_start()` and freezes a checkpoint the way `start_interview()` does, with the real `InterviewPlan` picks. User args choose the setup: `--iv-bg=intern --iv-tier=big` (defaults: Graduate, Mid).
- The DBG panel forces each outcome through the real ending code: K.O., wheel win, wheel loss, Composure 0. (The BUSTED button, the probe toggle and `--iv-probe` went with the probe, D9.)
- It prints `IVSTART`, `IVTRACE`, `IVWHEEL`, `IVFORCE` and `IVRESULT` lines for agent playtests.

### 11.7 Offer, Hired card, Plan B (S10-S12)

As built in Step 6 (grey boxes; the ending pictures are `ui/components/ending_art.tscn`). The agent defaults behind these screens are listed, for your review, in `offer_log.md` and `endings_log.md` under `.project/evidence/STEP-06/2026-09-27-r1/`.

```
Offer (Control, full rect)   offer.gd
├─ Background (dark ColorRect)
├─ Stage (full width; its bottom = the paper's resting top): TierBackground (tier colour), PlayerBust
│    (hoodie colour), Desk, Dimmer (0.6), DanaBust (above the dimmer: Dana stays visible)
├─ SafeArea > Column (254, separation 4)
│    StageSpacer (EXPAND_FILL) · Paper (PaperPanel 254) > Contract (RichTextLabel 240, fit_content,
│    line spacing -1, autowrap off) · TipNote (DuckyNote, closable) · DanaLine (hidden: Dana's Decline answer) ·
│    ThumbBand: BackRow [ < Back ] 80x36 · ActionBar [ Decline ] 80x36 + [ ACCEPT ] 168x36
└─ ModalLayer: PauseMenu, DeclineDialog (confirm_dialog)
```

- **`offer.tscn`** (S10) only shows `run.offer` (section 7.1), one tip, and calls `answer_offer()`.
  - **The contract** is pre-wrapped at 40 columns by `UiText.word_wrap` and `UiText.field`, so the label never wraps by itself. Top to bottom (CONTENT.md 13.1): `offer_title` (the company), `offer_dear`, `offer_role` (the posting's title), a blank line, then one field per line after a 12-column label, values wrapping at 28 columns: Salary (yearly, `offer_salary`: `$71,000/year`), Equity (startups only: `offer_equity`, agent default), Work mode, Commute (2 lines), Perks (2, the second under the first, no trailing period), Fine print (up to 4 lines; never a repeat of a perk, `fine_print_pool`, section 7.1), then `offer_deadline`. The worst case is 19 lines, a 243 px paper (`test_contract_fits_the_paper` checks every tier).
  - **The paper slides up** (0.3 s ease-out) after the scene fade. ACCEPT and Decline stay off until it lands, which is also the input lock. The stage's desk line follows the paper's top edge, so Dana sits right above the contract: at 270x480 only her lower part shows, at 294x639 all of her. While the paper rises from below, the desk line already waits at the paper's place.
  - **One tip** under the paper, `HuntTips.offer(run)`: `tip_equity_lottery` for a startup offer, else `tip_total_comp` (section 7.1). It waits invisible (`modulate`, not `hide()`, so the column keeps its room and the paper's place doesn't move) and fades in (0.15 s) once the paper has landed; before the review fix pass the paper rose under the note and the buttons, which hid most of the contract for 0.3 s (REVIEW_QUEUE Q6). At rest nothing overlaps: at 270x480 the startup contract's paper spans y 90-321, the tip 325-394 and the thumb band 398-476. The tip is closable (agent default A47): a tap hides it for this offer only (nothing is saved), and the paper and the desk line ease (0.2 s) into the room it leaves. The same ease covers Dana's Decline line replacing the tip; each step aims at the column's latest place, because a wrapped label can take two layout passes to find its height.
  - **Buttons:** the `[ < Back ]` row (it opens Pause; section 9), then `[ Decline ][ ACCEPT ]` (80 + 168). Drag-to-sign (SHOULD) is not built. Negotiate, which GDD S10 put full width above the action bar where the Back row now sits, was removed on 2026-10-07 (D-27).
  - **Decline** opens the confirm dialog: `ui_decline_confirm`, or `ui_decline_confirm_grace` when `run.decline_ends_run()` (rent at 0: the grace day, where Decline is Plan B). Confirmed, Dana's `bark_dana_decline` replaces the tip; a tap, Back or 2.5 s moves on, and only then is `answer_offer(false)` called, so a kill during her line leaves the offer open.
  - **ACCEPT** calls `answer_offer(true)`: `run.hire()` and the Hired card. Accept writes no save (section 8). The background check and its rescind (back to the hunt, the same day) were removed on 2026-09-29 (DECISIONS D9).
- **`phase2_stub.tscn`** (S11, the Hired card), in two beats, because everything at once needs about 500 px:
  - **Beat 1:** `EndingArt` (254x140: a sky in the tier colour, your bust in your hoodie colour) and the HIRED! stamp on its own panel, slammed in after the fade (2x for 0.05 s, then 1x; a 4 px whole-pixel shake of the picture; 40 ms haptic). Below it company, role and yearly salary (3 lines), then the tier's `end_hired_<tier>` (plus Stealth Mode's `hired_extra`). "Tap to continue" shows once the stamp is down plus the input lock; a tap (on release) or Back moves on. Beat 1 has no buttons.
  - **Beat 2:** a second column appears: the Dream vs Reality sheet slides up (0.3 s) over the illustration while the action bar stays put (GDD 9.1). The panel holds `end_dream_header` ("YOUR JOB vs REMY'S VIDEO"), the 5 rows (`end_dream_row_*`, label left; the salary, remote, commute and flags labels name Remy's value, e.g. "Salary (Remy: $150k)", the rent label has none; points right out of the row's maximum, `"%.1f/%d"` with the `dream_w_*` weights, e.g. "18.9/40", agent default A48), the grade word (`Odds.dream_grade`, `end_dream_grade_N`; grade 1 is "All reality, no dream") with the score in Press Start 2P 16, and `end_dream_footer` ("100 is the life in Remy's video. Nobody gets 100. Not even Remy.", 2 lines); the Step 7 review rewrote these labels so the score explains itself (DECISIONS C4); below it `tip_written_offer` and TO BE CONTINUED (`end_tbc`) on its own panel. The rows come from `GameState.dream_breakdown()` and appear one per 0.35 s with the running (rounded) score, then everything else; the final score is `run.dream_score`. A tap finishes the tally at once.
  - **Buttons:** `[ < Title ][ NEW RUN ]` (80 + 168), on once the tally ends plus the input lock. Leaving deletes the save and counts the run (section 8); NEW RUN is `retry()`.
- **`game_over.tscn`** (S12, the Plan B card) in one beat, about 362 px of content: `EndingArt` with the PLAN B stamp (a purple ring-light sky); one panel with `end_plan_b`, the background's `plan_b_line` and `end_plan_b_final`; one tip, `HuntTips.plan_b(run)` (section 7.1); the run stats (`end_stats`: days, applications, interviews, rejections; 2 lines). Buttons `[ < Title ][ RETRY ]`, on only after the stamp lands plus the input lock, because RETRY sits where Mail's START DAY is, and a second tap on it must not skip the ending. RETRY opens Background select with the same background preselected. The save was already deleted on entering GAME_OVER.

### 11.8 Viewpoints

- **Side view** (title, intro, interview, endings): `Parallax2D` layers as described in section 1.3, bottom-anchored in the GDD 2.5 portrait template. The interview, VS and commute stages are a wide vignette inside a band at least 270x160.
- **Top-down** is SHOULD/LATER.
  - The room hub (SHOULD) is **one static 330x720 illustration with 4 tap hotspots** (at least 48x48, in the lower 60%): invisible `TextureButton`s. There is no walking sprite.
  - Phase 2's office uses `TileMapLayer` (16x16 tiles) with y-sorted characters, scrolling vertically. It is now the career run's office diorama (GDD 2.11), planned in section 19.8.
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

| File | Suite | Tests | Covers | Created in |
|---|---|---|---|---|
| `test_flow.gd` | `flow` | 10 | every required transition (including Decline on the grace day, OFFER -> GAME_OVER), the illegal jumps, the save policy (`is_saved`, `deletes_save`, `can_resume`), a fresh RunState for Retry; and, reading scripts as text, that `SceneRouter.SCENES` has one existing screen per phase, each with `handle_back()`, and that no script under `features/` calls `change_scene_*()` or `change_phase()` or assigns a phase (INV-01, INV-02); since Step 6, that a run counts once, next to the save deletion (a Hired-card kill, then Continue and Accept again, still counts it once) | Step 1, grew in Steps 3, 5 and 6 (section 17.13) |
| `test_save.gd` | `save` | 4 | RunState <-> JSON round trip; 64-bit RNG state (2^53 + 1 and negative); seed-then-state replay; since the Step 7 review, a save from before D9 still loads and the next save drops the removed keys | Step 1, grew in the Step 7 review (section 17.13) |
| `test_odds.gd` | `odds` | 8 | P_invite worked examples (16.8%, 12.3%, 30.7%, 19.0%), clamps, bands, knockouts, relevance, determinism | Step 1 (section 17.13) |
| `test_interview.gd` | `interview` | 3 | the GDD 5.8.7 walkthrough with fixed luck (Doubt 105.5, 68.6, then about 13.1; wheel 68%), Tired, input bands (the bluff odds test went with D9) | Step 1 (section 17.13) |
| `test_offer.gd` | `offer` | 13 | salary $71,000, Dream scores 68 / 57 / 49 (the negotiation test, 77.5 / 62.5% with the 85% cap, went with D-27); since Step 6 the whole offer (GDD 5.9, S10): `make_offer` fills every field as plain data, 2 different perks and 1 fine print listed for the tier, the same checkpoint builds the same contract, a startup offer is remote with equity, the contract fits the paper at every tier, the commute hours, the offer surviving a save, the offer's tip, `decline_ends_run` only at 0 rent, and Accept after a Hired-card kill hiring the same job; since the Step 7 review, the fine print never repeating a perk | Step 1, grew in Step 6 and the Step 7 review (section 17.13) |
| `test_data_files.gd` | `data_files` | 7 | the 11 `.tres` files hold exactly the GDD section 11 numbers (since Step 14 the career run's `WorkConfig`, with its three tuned values, and the three `ArchetypeData`, whose `duel_tier` must name a tier file), and the derived values (9 / 8 / 6 energy; only the Self-Taught is a lone wolf; a Startup Junior's 2.55 k$). Changing a tuned value means updating GDD 11 and this test in the same commit | Step 3, grown in Step 14 |
| `test_content_lint.gd` | `content_lint` | 36 | see 12.3 (Step 14 added the career run's events and coworkers) | Step 4, grows each step |
| `test_interview_plan.gd` | `interview_plan` | 15 | `InterviewPlan` (GDD 5.8.2): prompt order and tier filtering, no opener-only picks, no repeats across interviews, the warm-up (first interview of the first run only, an unpicked difficulty-1 question that leaves the real picks unchanged), same seed same picks, dry pools, the prompts a checkpoint plays, and a resume or an early or late tap replaying the same luck; since the Step 7 review Dana's VS plate taking turns (the probe-question test went with D9) | Step 4 |
| `test_ui_text.gd` | `ui_text` | 14 | `UiText` (capitals, the Back arrow, costs, meters, bands, thousands, money; since Step 6 `word_wrap` wrapping where the lint counts lines, and `field`'s label column), and every literal `Content.text()` / `Content.field()` id in the scripts exists in the JSON; since the Step 7 review `fill` never doubling a period, `Content` filling through `UiText.fill` (read as text), and every `{company}` / `{last_company}` template filled with every company name. The `ProbeButton` test went with D9 | Step 4, grew in Step 6 and the Step 7 review |
| `test_lie_probe.gd` | `lie_probe` | 0 | removed 2026-09-29 with the lie probe (DECISIONS D9); it tested the bluff odds, the degree-claim weight and `settle_probe` | Step 4 |
| `test_hunt_board.gd` | `hunt_board` | 10 | GDD 5.6 board: 6 cards (2 per tier) from MVP companies, card rolls in range, the 10-card cap, applied pairs never dealt again, reposts, blacklisted companies, same seed same board, skip, cards aging overnight | Step 5 |
| `test_hunt_apply.gd` | `hunt_apply` | 11 | applying through the real `RunState` path: Quick Apply sending the honest CV and Tailor & Apply the Polished one, the gates actually sent (only a referral skips a degree knockout), the GDD 5.6 worked examples end to end, referrals, energy, the application record, an application recording no lies (D9), the card's odds and knockout chip | Step 5 |
| `test_hunt_reveal.gd` | `hunt_reveal` | 14 | GDD 5.7: the reveal in send order on the reveal morning, knockouts the next morning, ghost jobs, ghosting after 7 days, the Radar, invite validity, the day-2 guarantee and its fallback, and that every content id the rules emit exists | Step 5 |
| `test_hunt_sleep.gd` | `hunt_sleep` | 10 | Sleep as one committed action (section 7.1), the Step 1 night-tick form, the report surviving a save, a kill after Sleep showing the same morning, Plan B and the grace day (GDD 5.10), Start day, `take_invite` | Step 5 |
| `test_hunt_sim.gd` | `hunt_sim` | 2 | a smoke simulation of a Medium first run: an invite on the morning of day 2 (ROADMAP Step 5 Done-when); 2 day-1 applications are below the guarantee | Step 5 |
| `test_hunt_edges.gd` | `hunt_edges` | 25 | edge cases and invariants: exact-cost energy, double applies, empty and blacklisted tiers, Radar sequencing, send order across tiers, which reveals use dice, expiry on the last valid day, rent at 0, plain data and determinism over long runs (with or without nightly saves) | Step 5 |
| `test_hunt_defaults.gd` | `hunt_defaults` | 11 | the Step 5 agent defaults (section 7.1): the dry-deck fallback (38 pairs with the 6 MVP companies, all 58 of the 9 companies, each dealt once), blacklist effects, the rejection mail picked by uid, the ghost-free profile fallback, `passes_years` staying a yes/no (the `set_cv_level` test went with D9) | Step 5 |
| `test_probe_trigger.gd` | `probe_trigger` | 0 | removed 2026-09-29 with the lie probe and the background check (DECISIONS D9); it tested `roll_probe`, `background_check_caught` and `rescind_offer` | Step 5 |
| `test_hunt_tips.gd` | `hunt_tips` | 14 | `HuntTips` (GDD 8.3): the inbox, night (since D9 including the Tailor & Apply tips) and Study tips, once-per-run tips, `had_invite`; since the Step 7 review the first-run coach marks (the day-1 rule, a mark tapped closed staying closed, the invite mark until the first interview); `day_mail`, `tips_shown` and `coach_closed` surviving a save (an old save without `coach_closed` loads with `[]`) | Step 5, grew in the Step 7 review |
| `test_endings.gd` | `endings` | 6 | GDD 5.9.5 Dream vs Reality: `Odds.dream_breakdown` row by row against the three worked examples, its rounded sum always equal to `dream_score` (and each row within its weight), the grade bands; `RunState.hire` (employment, red flags, score, a save round trip); the texts both ending cards show; the Plan B tip matching the cause | Step 6 |
| `test_bars.gd` | `bars` | 5 | `StatBar` segments (value / 20, rounded, clamped) and its 39x13 size; `HpBar.fill_px` in whole pixels (a 1 px sliver, clamps); the start settling with no ghost, and the settled ghost following the value (no drain out of the tree) | Step 7 review |
| `test_intro.gd` | `intro` | 4 | `CutscenePlan`: panels in `order`, not id order; what is not a panel is skipped; `pan_path` from the picture's size; the real `cutscene.json` plays as GDD S02 says (6 panels in order 1-6, at most 40 s of pans, exactly one title card) | Step 6 |
| `test_balance.gd` | `balance` | | the GDD 5.12 simulation, ported | Step 7 |

The 5 Step-1 files had 24 tests, all passing against the section-17 code (verified: scratch run, and in this repo on 2026-09-26 after the portrait change). At the end of Step 5 there were 19 suites and 200 tests. At the end of Step 6 there were 21 suites and 225 tests (2026-09-27, `.project/evidence/STEP-06/2026-09-27-r1/test_run.json`). The Step 7 review removed the 2 lie-probe suites (204 tests in 19 suites after D9) and added `bars`: there are now **20 suites and 217 tests**, all passing (2026-09-29, headless and in the editor; `.project/evidence/STEP-07/2026-09-29-review/`). D-27's code cleanup (2026-10-08) removed `test_offer`'s negotiation test: 216 tests in 20 suites, all passing headless. The suites that load data read the real `.tres` with `load()` and the JSON with `FileAccess`, never through `Content` (INV-12).

### 12.3 `test_content_lint.gd` checks

It reads the 19 JSON files with `FileAccess` and the background `.tres` with `load()`. Since Step 14 it also checks `work_events.json` (the `evt_eNN_name` ids, the tiers, archetypes and levels, the trigger kinds, at most 3 choices, known `requires` and effects, an exhausted choice that names a choice or is "none", a tip id that exists or "none": O7) and `coworkers.json` (four authored coworkers, a 16-name pool, no name shared with the dice pool, Dana, Remy or Jordan). Artist-only fields (`art`, `visual`, `audio`, `note`, naming.json's `_notes`) and id or enum fields are never linted as text.

1. **Every file parses** to a Dictionary (and none is missing).
2. **Every referenced id exists:**
   - `tiers.json` holds exactly `startup`, `mid`, `big`
   - company `tier`; posting `company` (or `"any"`, and a pinned company belongs to the posting's tier) and `tier`
   - tags in `_keywords`; topics in `_topics`; every `_gap_topic_pool` entry in `_topics`
   - question `tip` in `tips.json` and question `tiers`; `weak_for` is a background or `"none"`; `exclusive.background`
   - perk and fine-print `tiers`
   - CV line `background` (the `probe_at` company check went with D9)
   - background ids match the `.tres` ids, and every background `.tres` has its text in `backgrounds.json`
3. **Text budgets** from GDD 2.7, per field. The test also word-wraps each string at 40 columns and checks the line cap. The wrap is greedy by spaces, like an autowrapped Label: a newline starts a line, and a word longer than a line breaks mid-word.

   | Field | Max chars | Lines at 40 columns |
   |---|---|---|
   | dialogue: reactions, barks (all of `barks.json`, so coach and UI lines too), `ducky`, `dana_line`, `dana_opener`, cutscene captions | 120 | 4 |
   | `prompt` (CV `probe` and `probe_at` lines until D9) | 100 | 3 |
   | answer `text`, the exclusive answer, `insider` (the "Why us?" button) | 40 | 1 |
   | `green` / `yellow` / `red` | 80 | 3 |
   | posting `joke`, `card_joke`, company `review`, `one_liner`, CV `text` | 60 | 2 |
   | tip `short` (`more` scrolls in the Notebook and `triggers` never show, so neither is budgeted) | 120 | 4 |
   | email `body`, and the plain-string `mail_*` lines | 240 | 7 |
   | each `red_flags` entry, posting `title`, `salary_text` | 40 | 1 |
   | player names (`names.json`; `LineEdit.max_length`) | 10 | 1 |
   | any other displayed string (it must at least fit the dialogue box) | 120 | 4 |

4. **Banned brands** (CONTENT 1.3): a case-insensitive, **whole-word** match (`RegEx` `\bword\b`) over every player-facing string.
   - The list and an allowlist of `{word, reason}` live as constants **in the test file**. `tests/` is never exported, so real brand names never ship. Every allowlist entry must be on the banned list and give a reason.
5. **ASCII only:** every character code is below 128.
6. **Placeholders:** every `{x}` is in the CONTENT 0 list.
7. **Shape checks:**
   - each choice question has exactly one good, one neutral and one bad answer;
   - each background has 6 CV lines, one per line and variant (`honest`, `polished`; 9 with `lie` until D9);
   - CV lines stay true (D9): no other variant, no lie-only field (`degree_claim`, `probe`, `probe_at`), and a Polished Education line never changes the degree (only a referral skips a degree knockout);
   - `has_degree_honest` / `years_pass_honest` match that background's honest CV lines;
   - per tier there are at least 11 choice and at least 19 knowledge questions.

### 12.4 `test_balance.gd` (Step 7)

- Port the GDD 5.12 bot:
  - it keeps a Polished CV. Since DECISIONS D9 there is no CV setting: a Quick Apply sends the honest CV and only Tailor & Apply sends the Polished lines, so this bot rule and the 5.12 numbers need re-checking when the port happens;
  - it tailors when 2 or more tags match, and uses referrals on Mid and Big;
  - it researches before 30% of interviews, and studies once after each lost interview;
  - it taps with about 75 ms of timing error;
  - it picks good / neutral / bad ethics answers 85 / 10 / 5%;
  - it accepts the first offer.
- Drive the **real** `RunState`, `Odds` and `InterviewPlan` rules. Load the `.tres` with `load()` and the JSON with `FileAccess` inside the test, as the Step 5 hunt suites do; never through the `Content` autoload, which doesn't exist in the editor (INV-12).
- **Split it by background:** one test method each, **about 1,000 runs**, which keeps every test well under 20 s.
- Assert the 5.12 bands with tolerances that suit n = 1,000. For example, Medium offers 88-98% and the Hard first-interview pass rate 10-20%.
- Step 7 no longer ports this Phase 1 simulation: the career run's R-BAL harness replaces it (MC-01, D-33). The career run's planned test suites are in section 19.10, and its headless harness, which runs outside `test_run` (A56), in section 19.6.

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
- **The git symlinks:** git stores four symlinks (mode 120000): `.claude/CLAUDE.md`, `.claude/skills` (to `../.agent/skills`), `.code/AGENTS.md` and `.code/skills`. On Windows they work only with Developer Mode on and `core.symlinks=true` in the **repo** config (`git config --local`: git writes a local `false` when it clones on Windows, and that overrides the global setting); otherwise they check out as one-line text files. The Windows PC was fixed on 2026-09-27 (ISSUE-04); git on macOS makes real links. Never replace a placeholder with a real file or folder and commit it: that turns the symlink into a normal entry.
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
- **Leave low-processor mode off.** It's the default (verified 4.7.2); it helps only static screens and hurts frame pacing. If battery becomes a problem, try `OS.low_processor_usage_mode = true` on the Mail and Study panels only.
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
  - `game_manage get_ui_elements`, then `input_mouse` on an element's rect centre (window pixels, not game pixels, and a motion event must come before the press: Step 2, desktop);
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

`debug_quick_start` sets up the run in place, the way `choose_background()` does (`_init_run()`: background, stats, energy, rent, the RNG seed, the gap topics, `first_run` and the day-1 board), then sets the phase. It calls **no `change_phase()` and emits no signal**, so `SceneRouter` never replaces the scene you launched (tech-verified fix #5).

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

## 17. Code skeletons (synced with the repo, 2026-09-29)

Copy these verbatim. **Each block is its repo file, byte for byte, as of the Step 7 developer review** (the 2026-09-29 doc sync, after DECISIONS D9-D12; the Step 6 sync was 2026-09-27, the Step 5 one ISSUE-08).
- The Step 1 skeletons were first verified in a scratch run: they compiled on 4.7.2 with `untyped_declaration` and the other common warnings set to **error**, and the section 17.13 tests passed against them. The synced files pass the repo's tests: 217 tests in 20 suites on 2026-09-29 (section 12.2).
- "Step N:" comments mark where a step added code, or where a later step adds it.
- Some blocks need files that aren't shown here. `game_state.gd` (17.7) needs the other pure classes (17.1-17.4, 17.14). `title.gd` (17.12) needs `ConfirmDialog` (`ui/components/confirm_dialog.tscn`), `UiText` (17.15) and the `barks.json` ids it reads. Section 17.13 shows 5 of the 20 test files; the rest are listed in section 12.2.
- Transient "Identifier not found: Content" (or `GameState`, `SceneRouter`, `Device`) errors are expected until all four autoloads are registered.

### 17.1 `core/game_flow.gd`

```gdscript
@tool
class_name GameFlow
extends RefCounted
## Which phase may follow which, and when the run save is written or deleted (GDD 4.1, 5.11).
## Pure data: tested by tests/test_flow.gd. Only GameState.change_phase() changes the phase.

## Append new phases at the end only: saves store the phase as an int (INV-10). WORK and LAYOFF are the career run's.
enum Phase { TITLE, INTRO, BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER, PHASE2_STUB, GAME_OVER, WORK, LAYOFF }

const TRANSITIONS: Dictionary = {
	Phase.TITLE: [Phase.INTRO, Phase.BACKGROUND_SELECT, Phase.JOB_HUNT, Phase.INTERVIEW, Phase.OFFER, Phase.WORK, Phase.LAYOFF],
	Phase.INTRO: [Phase.BACKGROUND_SELECT, Phase.WORK],
	Phase.BACKGROUND_SELECT: [Phase.JOB_HUNT, Phase.WORK, Phase.TITLE],
	Phase.JOB_HUNT: [Phase.INTERVIEW, Phase.GAME_OVER, Phase.TITLE],
	Phase.INTERVIEW: [Phase.OFFER, Phase.JOB_HUNT, Phase.WORK, Phase.TITLE],
	Phase.OFFER: [Phase.PHASE2_STUB, Phase.JOB_HUNT, Phase.WORK, Phase.GAME_OVER, Phase.TITLE],
	Phase.PHASE2_STUB: [Phase.TITLE, Phase.BACKGROUND_SELECT],
	Phase.GAME_OVER: [Phase.TITLE, Phase.BACKGROUND_SELECT],
	# The career run (ARCHITECTURE 19.4, 19.5): an interview day or a review leaves WORK for INTERVIEW and comes back (or
	# goes on to OFFER after a win); an offer is answered in OFFER and leads back to WORK. The same phases serve Phase 1.
	Phase.WORK: [Phase.LAYOFF, Phase.INTERVIEW, Phase.OFFER, Phase.GAME_OVER, Phase.TITLE],
	Phase.LAYOFF: [Phase.WORK, Phase.TITLE],
}

## A run is "live" only in these phases; they are the only phases ever written to the save.
const SAVED_PHASES: Array[Phase] = [Phase.JOB_HUNT, Phase.INTERVIEW, Phase.OFFER, Phase.WORK, Phase.LAYOFF]


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
## Job hunt ids (GDD 5.0). The board deals round-robin in TIER_IDS order.
const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
const CV_LINES: PackedStringArray = ["edu", "exp", "proj"]
const GUARANTEE_DAY := 2              # the first-run guarantee: day-1 applications, the morning of day 2
const REJECT_MAIL_PREFIX := "mail_reject_"   # emails.json: the plain rejection lines
const OFFER_PERKS := 2                # GDD 5.9, S10: every offer lists 2 perks and 1 fine-print joke
const EQUITY_TIER := "startup"        # GDD 7: only startups add the joke equity to the salary
const OFFER_SEED_SALT := "|offer"     # offer_rng(): the interview seed plus this names the offer's dice

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

# --- day loop ---
var day: int = 1
var energy: int = 0
var rent_days_left: int = 0
var grace_used: bool = false
var referral_tokens: int = 0
var pity_count: int = 0               # Recruiter Radar
var interviews_today: int = 0
var next_uid: int = 1
var board: Array[Dictionary] = []         # the deck, top card first: {uid, template_id, company_id, tier, posted_days_ago, applicants, is_ghost, reposted}
# applications, in send order: {uid (= the card's), template_id, company_id, tier, day_sent, reveal_day, p, hits,
#   relevant, knockout, knockout_reason {id, args}, is_ghost, referral, tailored, status}
#   status: pending -> invited | rejected | silent (-> ghosted); invited -> interview | expired
var applications: Array[Dictionary] = []
var applied: Array[String] = []           # "template_id|company_id": never dealt again this run
var dropped: Array[String] = []           # "template_id|company_id" pairs that fell off the board unapplied: they return "reposted"
# invites waiting in Mail: {uid, app_uid, company_id, template_id, tier, day_received, kind, mail_id}
#   kind: rolled | radar | guarantee | profile (the guarantee's "saw your profile!" from a board card)
var invites: Array[Dictionary] = []
var morning_report: Dictionary = {}       # built by Sleep; the hunt scene shows it, "Start day" clears it
var day_mail: Dictionary = {}             # the morning report after "Start day": Mail keeps showing it until the next Sleep
var tips_shown: Array[String] = []        # tip ids a once-per-run trigger already showed (HuntTips, GDD 8.3)
var coach_closed: Array[String] = []      # first-run coach marks tapped closed: never shown again this run (HuntTips.coach)
var blacklist: Array[String] = []         # company ids whose offer you declined
var researched: Array[String] = []        # company ids (SHOULD)
var seen_question_ids: Array[String] = []

# --- interview checkpoint: a resume replays exactly this interview (GDD 5.11) ---
var interview: Dictionary = {}        # {invite_uid, company_id, template_id, tier, seed, question_ids, warmup_id, tired}
var interviews_taken: int = 0
var times_met_dana: int = 0
var dana_last_company: String = ""

# --- offer, job, result ---
# the offer on the table (make_offer): {company_id, template_id, tier, job_title, salary, work_mode, office_days,
#   commute {id, args}, perks [ids], fine_print, equity_text}; texts are emails.json ids, job_title the posting's title
var offer: Dictionary = {}
var employment: Dictionary = {}       # the accepted offer + red_flags (hire(); Phase 2 reads this)
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


## A new run's starting numbers from its background (GDD 5.2). GameState adds the name, the seed,
## the gap topics and first_run, then deals the day-1 board.
func set_background(cfg: BalanceConfig, bg: BackgroundData) -> void:
	background_id = String(bg.id)
	stats.assign({"knw": bg.start_knw, "exp": bg.start_exp, "net": bg.start_net})
	commute_pips = bg.commute_pips
	commute_minutes = bg.commute_minutes
	energy = cfg.energy_max - bg.commute_pips
	rent_days_left = bg.runway_days
	referral_tokens = bg.referral_tokens
	lone_wolf = bg.teamwork_mult < bg.teamwork_mult_after_network


# ---------- job hunt (GDD 5.6-5.10). Every rule takes its data as arguments: ----------
# cfg: BalanceConfig; tiers: {"startup": TierData, "mid": ..., "big": ...};
# bg: this run's BackgroundData; rng: the run RNG;
# content: {"postings": ..., "companies": ..., "cv_lines": ...}, the parsed JSON files keyed by file name.

## "template_id|company_id": one card identity, as stored in applied and dropped.
static func pair_key(template_id: String, company_id: String) -> String:
	return template_id + "|" + company_id


## The morning deal (GDD 5.6): cfg.board_new_per_day cards, round-robin over the tiers (6 = 2 per
## tier), put on top of the deck. Blacklisted companies leave the board first; then the oldest cards
## drop off down to cfg.board_max. Returns how many cards were dealt.
func deal_board(cfg: BalanceConfig, tiers: Dictionary, content: Dictionary, rng: RandomNumberGenerator) -> int:
	var postings := _file(content, "postings")
	var companies := _file(content, "companies")
	for i: int in range(board.size() - 1, -1, -1):
		if blacklist.has(str(board[i]["company_id"])):
			board.remove_at(i)
	var tier_ids: Array[String] = []
	for id: String in TIER_IDS:
		if _tier(tiers, id) != null:
			tier_ids.append(id)
	if tier_ids.is_empty():
		return 0
	var dealt: Array[Dictionary] = []
	for i: int in cfg.board_new_per_day:
		var card := _deal_card(cfg, _tier(tiers, tier_ids[i % tier_ids.size()]), postings, companies, dealt, rng)
		if not card.is_empty():
			dealt.append(card)
	var dealt_count := dealt.size()
	dealt.append_array(board)
	board = dealt
	while board.size() > cfg.board_max:
		_drop_oldest()
	return dealt_count


## A declined offer (GDD 5.7): the company is blacklisted for the run. Its cards leave the board at
## once (not only at the next morning's deal), its waiting invites are withdrawn without a mail (their
## applications end "expired"), and its pending applications reveal as silent (_reveal_outcomes).
func blacklist_company(company_id: String) -> void:
	if not blacklist.has(company_id):
		blacklist.append(company_id)
	for i: int in range(board.size() - 1, -1, -1):
		if str(board[i]["company_id"]) == company_id:
			board.remove_at(i)
	for i: int in range(invites.size() - 1, -1, -1):
		if str(invites[i]["company_id"]) != company_id:
			continue
		var app := _application(int(invites[i]["app_uid"]))
		if not app.is_empty():
			app["status"] = "expired"
		invites.remove_at(i)


## Swipe left: the card goes to the back of the deck.
func skip_card(card_uid: int) -> bool:
	var i := _card_index(card_uid)
	if i < 0:
		return false
	board.append(board.pop_at(i))
	return true


## The CV lines actually sent (GDD 5.4): your background's true CV. Quick Apply sends every line
## Honest; Tailor & Apply sends every line as its Polished version (honest reframing) for that one
## application. Returns {line_ids, tags (the union), degree, passes_years}.
func cv_sent(cv_lines: Dictionary, tailored: bool) -> Dictionary:
	var level := "polished" if tailored else "honest"
	var line_ids: Array[String] = []
	var tags: Array[String] = []
	var degree := false
	var passes_years := false
	for line: String in CV_LINES:
		var id := _cv_line_id(cv_lines, line, level)
		if id.is_empty():
			continue
		var entry: Dictionary = cv_lines[id]
		line_ids.append(id)
		for tag: Variant in entry.get("tags", []):
			if not tags.has(str(tag)):
				tags.append(str(tag))
		degree = degree or bool(entry.get("degree", false))
		passes_years = passes_years or bool(entry.get("passes_years", false))
	return {"line_ids": line_ids, "tags": tags, "degree": degree, "passes_years": passes_years}


## What a card shows (GDD S04): its 3 tags checked against your honest CV ({tag, hit}), and for each
## way to apply ("quick", "tailored", "referral" = tailored + a token) {p, band, hits, relevant,
## knockout}. knockout is the red chip: {id, args} into postings.json ("card_knockout" wraps
## it), or {} for none. Ghost risk is never included. {} if the card's data is missing.
func card_odds(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary, card: Dictionary) -> Dictionary:
	var tier := _tier(tiers, str(card.get("tier", "")))
	var posting := _posting(content, str(card.get("template_id", "")))
	if tier == null or posting.is_empty():
		return {}
	var cv := _file(content, "cv_lines")
	var honest: Array = cv_sent(cv, false)["tags"]
	var tag_rows: Array[Dictionary] = []
	for tag: Variant in posting.get("tags", []):
		tag_rows.append({"tag": str(tag), "hit": honest.has(str(tag))})
	return {
		"tags": tag_rows,
		"quick": _quote(cfg, tier, bg, posting, cv, false, false),
		"tailored": _quote(cfg, tier, bg, posting, cv, true, false),
		"referral": _quote(cfg, tier, bg, posting, cv, true, true),
	}


## Quick Apply (tailored = false) or Tailor & Apply (tailored = true), optionally with a referral
## token (GDD 5.3, 5.6). Pays the energy, freezes P_invite with today's stats and schedules the
## reply. The outcome is NOT rolled now: the reveal morning rolls it (GDD 5.7).
## Returns the new application, or {} when the card is gone, its company is blacklisted or it
## can't be paid for.
func apply_card(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary, card_uid: int, tailored: bool, referral: bool) -> Dictionary:
	var i := _card_index(card_uid)
	if i < 0 or blacklist.has(str(board[i]["company_id"])):
		return {}
	var card: Dictionary = board[i]
	var tier := _tier(tiers, str(card["tier"]))
	var posting := _posting(content, str(card["template_id"]))
	if tier == null or posting.is_empty() or (referral and referral_tokens <= 0):
		return {}
	if not spend_energy(cfg.cost_tailor_apply if tailored else cfg.cost_quick_apply):
		return {}
	if referral:
		referral_tokens -= 1
	var quote := _quote(cfg, tier, bg, posting, _file(content, "cv_lines"), tailored, referral)
	var knockout: Dictionary = quote["knockout"]
	var app := {
		"uid": card["uid"], "template_id": card["template_id"], "company_id": card["company_id"],
		"tier": card["tier"], "day_sent": day,
		"reveal_day": Odds.reply_day(cfg, tier, day, not knockout.is_empty()),
		"p": _frozen_p(quote["p"]), "hits": quote["hits"], "relevant": quote["relevant"],
		"knockout": not knockout.is_empty(), "knockout_reason": knockout,
		"is_ghost": card["is_ghost"], "referral": referral, "tailored": tailored, "status": "pending",
	}
	applications.append(app)
	applied.append(pair_key(str(card["template_id"]), str(card["company_id"])))
	board.remove_at(i)
	total_applications += 1
	return app


## Sleep: ONE committed action (ARCHITECTURE 7.1). The night tick, then the whole morning: expired
## invites, the reveal in send order, ghosting, the board refill, the day-2 guarantee and the rent
## check (GDD 5.3, 5.6, 5.7, 5.10). The result is written to morning_report and returned:
##   day, night {applied, rejected, ghosted, rent_days_left} (the lock-screen summary),
##   invites [invite] (inbox first), rejections [{app_uid, company_id, template_id, tier, knockout, mail_id}]
##   in send order (knockout {id, args} names it; mail_id "mail_knockout", or for a plain rejection the
##   mail_reject_* line reject_mail_id() picks, "" without emails.json),
##   no_reply (silent and ghost-job reveals), ghosted [{app_uid, company_id, template_id, tier, days}],
##   expired [{invite_uid, app_uid, company_id, template_id, tier, mail_id}] ("filled internally"),
##   radar {before, after, max}, guarantee ("", "guarantee" or "profile"), board_new,
##   grace_day, plan_b (GameState ends the run after the inbox), rent_days_left.
## Called with cfg alone (the Step 1 form) it only runs the night tick and returns {}.
func sleep(cfg: BalanceConfig, tiers: Dictionary = {}, bg: BackgroundData = null, content: Dictionary = {}, rng: RandomNumberGenerator = null) -> Dictionary:
	var applied_today := 0
	for app: Dictionary in applications:
		if int(app["day_sent"]) == day:
			applied_today += 1
	day += 1
	rent_days_left = maxi(rent_days_left - 1, 0)
	energy = cfg.energy_max - commute_pips
	interviews_today = 0
	day_mail = {}
	for card: Dictionary in board:
		card["posted_days_ago"] = int(card["posted_days_ago"]) + 1
	if tiers.is_empty() or bg == null or rng == null:
		return {}
	morning_report = _morning(cfg, tiers, bg, content, rng, applied_today)
	return morning_report


## Mail "Start day": the morning has been seen and the report is cleared. It moves to day_mail, so
## Mail still shows the day's mail (expiry notices, rejections, the grace-day line) until the next Sleep.
## Returns true when this morning ended the run (GameState then calls end_run_plan_b()).
func start_day() -> bool:
	var plan_b := bool(morning_report.get("plan_b", false))
	day_mail = morning_report
	morning_report = {}
	return plan_b


## Mail "GO NOW": the invite leaves the inbox and its application is marked "interview".
## Returns the invite, or {} if it isn't waiting (GameState pays and checks the day's limit first).
func take_invite(invite_uid: int) -> Dictionary:
	for i: int in invites.size():
		if int(invites[i]["uid"]) == invite_uid:
			var invite: Dictionary = invites.pop_at(i)
			var app := _application(int(invite["app_uid"]))
			if not app.is_empty():
				app["status"] = "interview"
			return invite
	return {}


## GDD 5.9, S10: the whole offer, built by GameState.finish_interview from the interview checkpoint
## (so call it before the checkpoint is cleared). Plain data only (INV-07): the numbers, the posting's
## title (the raw JSON text; the screen tr()s it) and emails.json ids for every other text, so the
## paper can be drawn again after a resume. The perks and the fine print are picked on offer_rng(),
## seeded from the checkpoint's seed: a replayed interview builds the same contract, and neither the
## run RNG nor the global RNG moves. Returns a copy of the new offer.
func make_offer(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, content: Dictionary, composure_left: float) -> Dictionary:
	var tier_id := String(tier.id)
	var template_id := str(interview.get("template_id", ""))
	var emails := _file(content, "emails")
	var rng := offer_rng(str(interview.get("seed", "")))
	var perks := Odds.pick(rng, _tier_entries(emails, "perk_", tier_id), OFFER_PERKS)
	var fine_print := Odds.pick(rng, fine_print_pool(emails, tier_id, perks), 1)
	offer = {
		"company_id": str(interview.get("company_id", "")), "template_id": template_id, "tier": tier_id,
		"job_title": str(_posting(content, template_id).get("title", "")),
		"salary": Odds.offer_salary(cfg, tier, bg, composure_left, bg.composure_max),
		"work_mode": "offer_mode_" + tier_id, "office_days": tier.office_days,
		"commute": offer_commute(tier.office_days, commute_minutes),
		"perks": perks, "fine_print": str(fine_print[0]) if not fine_print.is_empty() else "",
		"equity_text": "offer_equity" if tier_id == EQUITY_TIER else "",
	}
	return offer.duplicate(true)


## The offer's own dice (ARCHITECTURE 7.2): a generator seeded from the interview checkpoint's seed
## (a String) and a salt, so it never replays the interview's own rolls.
static func offer_rng(interview_seed: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = (interview_seed + OFFER_SEED_SALT).hash()
	return rng


## The contract's commute line (GDD S10) as {id, args} into emails.json: no office days is the remote
## line; otherwise days x minutes each way and the weekly hours (GDD 5.9.5), one decimal: "12.7".
static func offer_commute(office_days: int, minutes_each_way: int) -> Dictionary:
	if office_days <= 0:
		return {"id": "offer_commute_remote", "args": {}}
	var hours := office_days * 2.0 * minutes_each_way / 60.0
	return {"id": "offer_commute_office",
		"args": {"office_days": office_days, "commute_min": minutes_each_way, "hours": "%.1f" % hours}}


## GDD 5.9.4-5.9.5, Accept: the offer becomes the job, with its
## company's red flags (GDD 10.4; company_red_flags is that company's companies.json list), and is
## scored Dream vs Reality with the rent days left today. The offer stays as it was.
func hire(cfg: BalanceConfig, bg: BackgroundData, company_red_flags: Array) -> void:
	employment = offer.duplicate(true)
	employment["red_flags"] = company_red_flags.duplicate()
	dream_score = Odds.dream_score(cfg, int(employment.get("salary", 0)), int(employment.get("office_days", 0)),
		commute_minutes, company_red_flags.size(), rent_days_left, bg.runway_days)


## The Hired card's five rows (Odds.dream_breakdown) for the job taken, from the numbers hire() scored:
## their rounded sum is dream_score.
func dream_breakdown(cfg: BalanceConfig, bg: BackgroundData) -> Array[float]:
	return Odds.dream_breakdown(cfg, int(employment.get("salary", 0)), int(employment.get("office_days", 0)),
		commute_minutes, (employment.get("red_flags", []) as Array).size(), rent_days_left, bg.runway_days)


## GDD 5.10: Decline on the grace day (0 rent days: the only way an offer is open with no rent left)
## is Plan B, not back to the hunt. The offer screen asks with the matching question.
func decline_ends_run() -> bool:
	return rent_days_left <= 0


## A plain rejection's email (GDD S06), picked without dice: the application uid chooses one of the
## mail_reject_* lines (sorted ids), so a resume or a replayed Sleep shows the same line.
## "" when the content has no emails.
static func reject_mail_id(content: Dictionary, app_uid: int) -> String:
	var ids: Array[String] = []
	for key: Variant in _file(content, "emails"):
		if str(key).begins_with(REJECT_MAIL_PREFIX):
			ids.append(str(key))
	if ids.is_empty():
		return ""
	ids.sort()
	return ids[posmod(app_uid, ids.size())]


# ---------- job hunt internals ----------

func _morning(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary, rng: RandomNumberGenerator, applied_today: int) -> Dictionary:
	var report := {
		"day": day, "night": {}, "invites": [], "rejections": [], "no_reply": 0, "ghosted": [],
		"expired": [], "radar": {"before": pity_count, "after": pity_count, "max": bg.pity_n},
		"guarantee": "", "board_new": 0, "grace_day": false, "plan_b": false, "rent_days_left": rent_days_left,
	}
	_expire_invites(cfg, report)
	var outcomes := _reveal_outcomes(tiers, bg, rng)
	var guarantee_due := _guarantee_due(cfg, outcomes)
	if guarantee_due:
		var best := _best_day1_application()
		if not best.is_empty():
			_set_outcome(outcomes, best, "guarantee")
			report["guarantee"] = "guarantee"
			pity_count = 0
	_apply_outcomes(outcomes, report, content)
	_ghost_silent(cfg, report)
	report["board_new"] = deal_board(cfg, tiers, content, rng)
	if guarantee_due and report["guarantee"] == "":
		var invite := _profile_invite(cfg, tiers, bg, content)
		if not invite.is_empty():
			(report["invites"] as Array).append(invite)
			report["guarantee"] = "profile"
			pity_count = 0
	(report["radar"] as Dictionary)["after"] = pity_count
	var rent := Odds.rent_check(cfg, rent_days_left, grace_used, not invites.is_empty())
	if rent == "grace":
		grace_used = true
	report["grace_day"] = rent == "grace"
	report["plan_b"] = rent == "plan_b"
	report["night"] = {
		"applied": applied_today, "rejected": (report["rejections"] as Array).size(),
		"ghosted": (report["ghosted"] as Array).size(), "rent_days_left": rent_days_left,
	}
	return report


func _expire_invites(cfg: BalanceConfig, report: Dictionary) -> void:
	var expired: Array = report["expired"]
	for i: int in range(invites.size() - 1, -1, -1):
		var invite: Dictionary = invites[i]
		if not Odds.invite_expired(cfg, int(invite["day_received"]), day):
			continue
		invites.remove_at(i)
		var app := _application(int(invite["app_uid"]))
		if not app.is_empty():
			app["status"] = "expired"
		expired.push_front({
			"invite_uid": invite["uid"], "app_uid": invite["app_uid"], "company_id": invite["company_id"],
			"template_id": invite["template_id"], "tier": invite["tier"], "mail_id": "mail_invite_expired",
		})


## GDD 5.7 steps 1-4 for each application due this morning, in send order (applications are appended
## as they are sent). The Radar moves as each one resolves. Statuses change later, in _apply_outcomes.
## A blacklisted company never answers: its applications reveal as silent, without dice.
func _reveal_outcomes(tiers: Dictionary, bg: BackgroundData, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var outcomes: Array[Dictionary] = []
	for app: Dictionary in applications:
		if app["status"] != "pending" or int(app["reveal_day"]) > day:
			continue
		var tier := _tier(tiers, str(app["tier"]))
		if tier == null:
			continue
		var outcome := "silent"
		if not blacklist.has(str(app["company_id"])):
			outcome = Odds.reveal_outcome(tier, bg, app, pity_count, rng)
		# A knockout failure never fills the Radar, even when a blacklist turned it silent.
		var counts := bool(app["relevant"]) and not bool(app["knockout"])
		pity_count = Odds.pity_after(bg, pity_count, outcome, counts)
		outcomes.append({"app": app, "outcome": outcome})
	return outcomes


## First run, the morning of day 2, at least day2_guarantee_min_apps sent on day 1, no invite yet.
func _guarantee_due(cfg: BalanceConfig, outcomes: Array[Dictionary]) -> bool:
	if not first_run or day != GUARANTEE_DAY:
		return false
	for o: Dictionary in outcomes:
		if o["outcome"] in ["invite", "radar"]:
			return false
	var sent_day1 := 0
	for app: Dictionary in applications:
		if int(app["day_sent"]) == GUARANTEE_DAY - 1:
			sent_day1 += 1
	return sent_day1 >= cfg.day2_guarantee_min_apps


## The best eligible day-1 application: highest P, not a ghost job, not knocked out, not to a
## blacklisted company, not resolved before this morning (this morning's reveals are still "pending"
## here). Ties go to the first sent.
func _best_day1_application() -> Dictionary:
	var best: Dictionary = {}
	for app: Dictionary in applications:
		if int(app["day_sent"]) != GUARANTEE_DAY - 1 or app["status"] != "pending":
			continue
		if bool(app["knockout"]) or bool(app["is_ghost"]) or blacklist.has(str(app["company_id"])):
			continue
		if best.is_empty() or float(app["p"]) > float(best["p"]):
			best = app
	return best


func _set_outcome(outcomes: Array[Dictionary], app: Dictionary, outcome: String) -> void:
	for o: Dictionary in outcomes:
		if int((o["app"] as Dictionary)["uid"]) == int(app["uid"]):
			o["outcome"] = outcome
			return
	outcomes.append({"app": app, "outcome": outcome})


func _apply_outcomes(outcomes: Array[Dictionary], report: Dictionary, content: Dictionary) -> void:
	var new_invites: Array = report["invites"]
	var rejections: Array = report["rejections"]
	for o: Dictionary in outcomes:
		var app: Dictionary = o["app"]
		var outcome: String = o["outcome"]
		match outcome:
			"invite":
				app["status"] = "invited"
				new_invites.append(_add_invite(app, "rolled", "mail_invite_" + str(app["tier"])))
			"radar", "guarantee":
				app["status"] = "invited"
				new_invites.append(_add_invite(app, outcome, "mail_invite_" + outcome))
			"knockout", "rejected":
				app["status"] = "rejected"
				total_rejections += 1
				var knockout: Dictionary = {}
				if outcome == "knockout":
					knockout = (app["knockout_reason"] as Dictionary).duplicate(true)
				rejections.append({
					"app_uid": app["uid"], "company_id": app["company_id"], "template_id": app["template_id"],
					"tier": app["tier"], "knockout": knockout,
					"mail_id": "mail_knockout" if outcome == "knockout" else reject_mail_id(content, int(app["uid"])),
				})
			_:  # "ghost" and "silent": nothing arrives
				app["status"] = "silent"
				report["no_reply"] = int(report["no_reply"]) + 1


func _ghost_silent(cfg: BalanceConfig, report: Dictionary) -> void:
	var ghosted: Array = report["ghosted"]
	for app: Dictionary in applications:
		if app["status"] == "silent" and Odds.is_ghosted(cfg, int(app["day_sent"]), day):
			app["status"] = "ghosted"
			ghosted.append({
				"app_uid": app["uid"], "company_id": app["company_id"], "template_id": app["template_id"],
				"tier": app["tier"], "days": day - int(app["day_sent"]),
			})


## The guarantee's fallback (GDD 5.7): the highest-odds startup card on the board "saw your profile".
## Never a ghost job: with only ghost startup cards left there is no fallback invite (rare). The card
## leaves the board and its pair counts as applied. Ties go to the oldest card (lowest uid), never to
## deck order, so how the deck was swiped can't change the morning.
func _profile_invite(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_p := -1.0
	for card: Dictionary in board:
		if card["tier"] != "startup" or bool(card["is_ghost"]):
			continue
		var odds := card_odds(cfg, tiers, bg, content, card)
		if odds.is_empty():
			continue
		var p := float((odds["tailored"] as Dictionary)["p"])
		if p > best_p or (p == best_p and int(card["uid"]) < int(best["uid"])):
			best = card
			best_p = p
	if best.is_empty():
		return {}
	board.remove_at(_card_index(int(best["uid"])))
	applied.append(pair_key(str(best["template_id"]), str(best["company_id"])))
	return _add_invite({"uid": best["uid"], "company_id": best["company_id"], "template_id": best["template_id"],
		"tier": best["tier"]}, "profile", "mail_invite_guarantee")


func _add_invite(source: Dictionary, kind: String, mail_id: String) -> Dictionary:
	var invite := {
		"uid": new_uid(), "app_uid": source["uid"], "company_id": source["company_id"],
		"template_id": source["template_id"], "tier": source["tier"], "day_received": day,
		"kind": kind, "mail_id": mail_id,
	}
	invites.append(invite)
	return invite.duplicate(true)


## One card for tier: a template of that tier (not a SHOULD one such as the Unicorn), paired with a
## company of the tier (a pinned template only with its own company). Never a pair that was applied
## to or is already on the board; templates not on the board yet go first. The MVP companies deal
## first; once none of their pairs is free, the tier's other companies step in, so the board never
## starves (GDD 5.6: 38 pairs with the 6 MVP companies, 58 with all 9).
func _deal_card(cfg: BalanceConfig, tier: TierData, postings: Dictionary, companies: Dictionary, dealt: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var tier_id := String(tier.id)
	var on_board: Array[String] = []
	var templates_seen: Array[String] = []
	for card: Dictionary in board + dealt:
		on_board.append(pair_key(str(card["template_id"]), str(card["company_id"])))
		templates_seen.append(str(card["template_id"]))
	var free: Dictionary = {}       # template_id -> company ids still free
	for mvp: bool in [true, false]:
		free = _free_pairs(postings, tier_id, _companies_of(companies, tier_id, mvp), on_board)
		if not free.is_empty():
			break
	if free.is_empty():
		return {}
	var usable: Array[String] = []
	var fresh: Array[String] = []   # templates not on the board or dealt this morning
	for tid: String in free:
		usable.append(tid)
		if not templates_seen.has(tid):
			fresh.append(tid)
	var template_id: String = Odds.pick(rng, fresh if not fresh.is_empty() else usable, 1)[0]
	var company_id: String = Odds.pick(rng, free[template_id], 1)[0]
	var posting: Dictionary = postings[template_id]
	var rolled := Odds.roll_card(cfg, tier, str(posting.get("ghost", "roll")) == "always", rng)
	return {
		"uid": new_uid(), "template_id": template_id, "company_id": company_id, "tier": tier_id,
		"posted_days_ago": rolled["posted_days_ago"], "applicants": rolled["applicants"],
		"is_ghost": rolled["is_ghost"], "reposted": dropped.has(pair_key(template_id, company_id)),
	}


## template_id -> the company ids of `enabled` still free for it (in sorted template order), for a
## tier's templates that aren't SHOULD; a pinned template only with its own company.
func _free_pairs(postings: Dictionary, tier_id: String, enabled: Array[String], on_board: Array[String]) -> Dictionary:
	var free: Dictionary = {}
	for tid: String in _ids(postings):
		var entry: Dictionary = postings[tid]
		if str(entry.get("tier", "")) != tier_id or bool(entry.get("should", false)):
			continue
		var pinned := str(entry.get("company", "any"))
		var company_ids: Array[String] = []
		for cid: String in enabled:
			var pair := pair_key(tid, cid)
			if (pinned == "any" or pinned == cid) and not applied.has(pair) and not on_board.has(pair):
				company_ids.append(cid)
		if not company_ids.is_empty():
			free[tid] = company_ids
	return free


## A tier's companies that aren't blacklisted (GDD 5.5): the MVP ones ("mvp": true), or the others.
func _companies_of(companies: Dictionary, tier_id: String, mvp: bool) -> Array[String]:
	var out: Array[String] = []
	for id: String in _ids(companies):
		var company: Dictionary = companies[id]
		if str(company.get("tier", "")) == tier_id and not blacklist.has(id) and bool(company.get("mvp", false)) == mvp:
			out.append(id)
	return out


func _drop_oldest() -> void:
	var oldest := 0
	for i: int in board.size():
		if int(board[i]["uid"]) < int(board[oldest]["uid"]):
			oldest = i
	var pair := pair_key(str(board[oldest]["template_id"]), str(board[oldest]["company_id"]))
	if not dropped.has(pair):
		dropped.append(pair)
	board.remove_at(oldest)


func _quote(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, posting: Dictionary, cv_lines: Dictionary, tailored: bool, referral: bool) -> Dictionary:
	var sent := cv_sent(cv_lines, tailored)
	var posting_tags: Array = posting.get("tags", [])
	var sent_tags: Array = sent["tags"]
	var hits := Odds.tag_hits(PackedStringArray(posting_tags), PackedStringArray(sent_tags))
	var p := Odds.p_invite(cfg, tier, bg, hits, tailored, stat("net"), referral)
	return {
		"p": p, "band": Odds.odds_band(cfg, p), "hits": hits, "relevant": Odds.is_relevant(cfg, hits),
		"knockout": Odds.knockout_reason(bool(posting.get("degree", false)), int(posting.get("min_years", 0)),
			bool(sent["degree"]), bool(sent["passes_years"]), referral),
	}


## P as frozen in an application, rounded to 9 decimals: the JSON save keeps about 15 significant
## digits, so an unrounded P reads back a hair different and a Continue would roll against another P.
static func _frozen_p(p: float) -> float:
	return ("%.9f" % p).to_float()


## The cv_lines.json id for this background's line at a level, "honest" or "polished" (the fields
## decide, not the id's spelling).
func _cv_line_id(cv_lines: Dictionary, line: String, level: String) -> String:
	for key: Variant in cv_lines:
		var entry: Variant = cv_lines[key]
		if entry is Dictionary and entry.get("background") == background_id \
				and entry.get("line") == line and entry.get("variant") == level:
			return str(key)
	return ""


func _card_index(card_uid: int) -> int:
	for i: int in board.size():
		if int(board[i]["uid"]) == card_uid:
			return i
	return -1


func _application(app_uid: int) -> Dictionary:
	for app: Dictionary in applications:
		if int(app["uid"]) == app_uid:
			return app
	return {}


static func _posting(content: Dictionary, template_id: String) -> Dictionary:
	var entry: Variant = _file(content, "postings").get(template_id)
	if entry is Dictionary:
		return entry
	return {}


static func _tier(tiers: Dictionary, id: String) -> TierData:
	return tiers.get(id) as TierData


static func _file(content: Dictionary, file: String) -> Dictionary:
	var d: Variant = content.get(file)
	if d is Dictionary:
		return d
	return {}


## GDD S10: the tier's fine print (fp_* in emails.json) minus any that repeats a perk on the same
## paper: fp_<x> is left out when perk_<x> was dealt, so a startup never lists "Unlimited PTO*" twice.
static func fine_print_pool(emails: Dictionary, tier_id: String, perks: Array) -> Array[String]:
	var pool: Array[String] = []
	for id: String in _tier_entries(emails, "fp_", tier_id):
		if not perks.has("perk_" + id.trim_prefix("fp_")):
			pool.append(id)
	return pool


## The sorted ids starting with prefix whose "tiers" list this tier (perk_*, fp_* in emails.json).
static func _tier_entries(entries: Dictionary, prefix: String, tier_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _ids(entries):
		if id.begins_with(prefix) and ((entries[id] as Dictionary).get("tiers", []) as Array).has(tier_id):
			ids.append(id)
	return ids


## A content file's entry ids, sorted, so dealing never depends on dictionary order. Plain-string UI
## ids (e.g. "card_posted") and "_" metadata keys are skipped.
static func _ids(entries: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in entries:
		if entries[key] is Dictionary and not str(key).begins_with("_"):
			ids.append(str(key))
	ids.sort()
	return ids


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
##
## Two kinds share the slot (ARCHITECTURE 19.4): Phase 1's hunt run (RunState.to_dict, version 1) and the career
## run's ({version: 2, phase, sim, ui}: WorkSession.to_save). kind_of() tells them apart; a hunt save never reads as a
## career one, so Continue can route to the right flow.

const PATH := "user://save_v1.json"
const KIND_NONE := ""
const KIND_HUNT := "hunt"
const KIND_CAREER := "career"
const CAREER_VERSION := 2


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(path)


## Phase 1's run (RunState). false when the slot holds nothing writable.
static func write(run: RunState, path: String = PATH) -> bool:
	return write_text(JSON.stringify(run.to_dict(), "\t"), path)


## The career run: WorkSession.to_save(phase).
static func write_career(payload: Dictionary, path: String = PATH) -> bool:
	return write_text(encode(payload), path)


static func encode(payload: Dictionary) -> String:
	return JSON.stringify(payload, "\t")


## Temp file, then rename. Some platforms refuse to rename over an existing file, so remove it and retry.
static func write_text(text: String, path: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	f.close()
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	return err == OK


## The save file as parsed JSON ({} when there is none or it is unreadable).
static func peek(path: String = PATH) -> Dictionary:
	if not exists(path):
		return {}
	return decode(FileAccess.get_file_as_string(path))


static func decode(text: String) -> Dictionary:
	var json := JSON.new()   # not parse_string: that prints an engine error for a bad file
	if json.parse(text) != OK or not (json.data is Dictionary):
		push_warning("Save file unreadable; ignoring it.")
		return {}
	return json.data


## "career" for a version-2 save with a sim, "hunt" for any other save, "" for nothing.
static func kind_of(data: Dictionary) -> String:
	if data.is_empty():
		return KIND_NONE
	if int(data.get("version", 1)) >= CAREER_VERSION and data.has("sim"):
		return KIND_CAREER
	return KIND_HUNT


static func kind(path: String = PATH) -> String:
	return kind_of(peek(path))


## Phase 1's run, or null when the slot is empty, unreadable or holds a career run.
static func read(path: String = PATH) -> RunState:
	var data := peek(path)
	if kind_of(data) != KIND_HUNT:
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

## Dream vs Reality (GDD 5.9.5): the rows in dream_breakdown's order (endings.json end_dream_row_<id>),
## and the lowest score of grades 2-4: <40 Reality, 40-59 Doable, 60-79 Pretty good, 80+.
const DREAM_ROWS: PackedStringArray = ["salary", "remote", "commute", "flags", "rent"]
const DREAM_GRADE_MINS: Array[int] = [40, 60, 80]

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


# ---------- offer and endings (GDD 5.9) ----------

static func round_to(value: float, step: int) -> int:
	return roundi(value / step) * step


## Yearly salary in whole dollars.
static func offer_salary(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, composure_left: float, composure_max: float) -> int:
	var band_pos := clampf(cfg.band_base + cfg.band_perf_weight * composure_left / composure_max, 0.0, 1.0)
	var raw := lerpf(tier.salary_min_k * 1000.0, tier.salary_max_k * 1000.0, band_pos) * bg.salary_mult
	return round_to(raw, cfg.salary_round)


static func dream_score(cfg: BalanceConfig, salary: int, office_days: int, commute_minutes: int, red_flags: int, rent_days_left: int, runway_days: int) -> int:
	var weekly_commute_h := office_days * 2.0 * commute_minutes / 60.0
	var pts := cfg.dream_w_salary * minf(1.0, float(salary) / cfg.dream_salary_target)
	pts += cfg.dream_w_remote * (5 - office_days) / 5.0
	pts += cfg.dream_w_commute * maxf(0.0, 1.0 - weekly_commute_h / cfg.dream_commute_zero_h)
	pts += maxf(0.0, cfg.dream_w_flags - cfg.dream_flag_penalty * red_flags)
	pts += cfg.dream_w_runway * rent_days_left / float(runway_days)
	return roundi(pts)


## The five Dream vs Reality rows (GDD 5.9.5), unrounded, in DREAM_ROWS order. They are dream_score's
## terms, added in the same order, so their rounded sum is always dream_score. The Hired card shows them.
static func dream_breakdown(cfg: BalanceConfig, salary: int, office_days: int, commute_minutes: int, red_flags: int, rent_days_left: int, runway_days: int) -> Array[float]:
	var weekly_commute_h := office_days * 2.0 * commute_minutes / 60.0
	var parts: Array[float] = [
		cfg.dream_w_salary * minf(1.0, float(salary) / cfg.dream_salary_target),
		cfg.dream_w_remote * (5 - office_days) / 5.0,
		cfg.dream_w_commute * maxf(0.0, 1.0 - weekly_commute_h / cfg.dream_commute_zero_h),
		maxf(0.0, cfg.dream_w_flags - cfg.dream_flag_penalty * red_flags),
		cfg.dream_w_runway * rent_days_left / float(runway_days),
	]
	return parts


## The score's grade, 1-4 (endings.json end_dream_grade_N): below the first DREAM_GRADE_MINS value is 1.
static func dream_grade(score: int) -> int:
	var grade := 1
	for min_score: int in DREAM_GRADE_MINS:
		if score >= min_score:
			grade += 1
	return grade


# ---------- job hunt: board, apply, reveal (GDD 5.6-5.10, Step 5) ----------

## A new card's hidden rolls, always in this order: ghost flag, posted days ago, applicants.
## always_ghost = the template says "ghost": "always" (no roll).
static func roll_card(cfg: BalanceConfig, tier: TierData, always_ghost: bool, rng: RandomNumberGenerator) -> Dictionary:
	var ghost := always_ghost or roll(rng, tier.ghost_job_rate)
	var posted: int
	if ghost:
		posted = rng.randi_range(cfg.ghost_posted_days_min, cfg.ghost_posted_days_max)
	else:
		posted = rng.randi_range(tier.posted_days_min, tier.posted_days_max)
	return {"is_ghost": ghost, "posted_days_ago": posted, "applicants": rng.randi_range(tier.applicants_min, tier.applicants_max)}


## The knockout a CV fails, as a postings.json text id plus its args ({} = none). A referral skips
## knockouts. When both fail, the degree is named (the card shows one chip).
static func knockout_reason(degree_required: bool, min_years: int, cv_has_degree: bool, cv_passes_years: bool, referral: bool) -> Dictionary:
	if not is_knockout(degree_required, min_years, cv_has_degree, cv_passes_years, referral):
		return {}
	if degree_required and not cv_has_degree:
		return {"id": "knock_degree", "args": {}}
	return {"id": "knock_years", "args": {"n": min_years}}


## The morning an application's reply arrives: a knockout at 3:07 AM the next morning whatever the
## tier, anything else after the tier's reply delay.
static func reply_day(cfg: BalanceConfig, tier: TierData, day_sent: int, knockout: bool) -> int:
	return day_sent + (cfg.knockout_reply_delay_days if knockout else tier.reply_delay_days)


## One application's reveal (GDD 5.7), rolled on its reveal morning with the run RNG:
## "knockout", "ghost", "radar" (the Recruiter Radar was full), "invite", "silent" or "rejected".
## app needs knockout, is_ghost, relevant and p (frozen when it was sent).
static func reveal_outcome(tier: TierData, bg: BackgroundData, app: Dictionary, pity_count: int, rng: RandomNumberGenerator) -> String:
	if bool(app.get("knockout", false)):
		return "knockout"
	if bool(app.get("is_ghost", false)):
		return "ghost"
	if bool(app.get("relevant", false)) and pity_count >= bg.pity_n:
		return "radar"
	if roll(rng, float(app.get("p", 0.0))):
		return "invite"
	return "silent" if roll(rng, tier.silent_share) else "rejected"


## The Recruiter Radar after one outcome: any invite empties it; a relevant application without an
## invite adds 1 (it stops at pity_n); knockouts and irrelevant applications never count.
static func pity_after(bg: BackgroundData, pity_count: int, outcome: String, relevant: bool) -> int:
	if outcome in ["invite", "radar", "guarantee"]:
		return 0
	if outcome == "knockout" or not relevant:
		return pity_count
	return mini(pity_count + 1, bg.pity_n)


## Invites are valid on the day they arrive and the next (invite_valid_days = 2).
static func invite_expired(cfg: BalanceConfig, day_received: int, today: int) -> bool:
	return today - day_received >= cfg.invite_valid_days


## A silent application turns "ghosted" this many days after it was sent.
static func is_ghosted(cfg: BalanceConfig, day_sent: int, today: int) -> bool:
	return today - day_sent >= cfg.ghosted_after_days


## GDD 5.10, checked every morning after the reveal: "" while rent lasts; at 0 rent days a waiting
## invite buys one "grace" day (once per run); otherwise "plan_b".
static func rent_check(cfg: BalanceConfig, rent_days_left: int, grace_used: bool, invite_waiting: bool) -> String:
	if rent_days_left > 0:
		return ""
	if cfg.grace_day and invite_waiting and not grace_used:
		return "grace"
	return "plan_b"
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

@export_group("Career run (11.7)")
@export var start_savings_months: float = 0.8   # months of expenses: Phase 1's runway_days / 15 (A68, doubled by D-30)


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
@export var typewriter_cps: float = 40.0

@export_group("Offer and endings (11.6)")
@export var band_base: float = 0.25
@export var band_perf_weight: float = 0.50
@export var salary_round: int = 1000
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

`work_config.gd`:

```gdscript
@tool
class_name WorkConfig
extends Resource
## The career run's global constants (GDD section 11.7, owner "W"). One file: res://data/work/work_config.tres.
## These defaults are the Run Spec's numbers (and my gap-fills, DECISIONS A63-A73). The .tres holds the tuned ones: three
## differ after STEP-14's first tuning (DECISIONS A74; GDD 11.7 lists both). Tune the .tres, leave these lines alone (the
## sim tests build WorkConfig.new() and expect the Run Spec's worked examples). Per-archetype numbers live in
## ArchetypeData, an event's own numbers in data/content/work_events.json (DECISIONS A54).
## Level arrays run junior, mid, senior; home arrays run shared room, one-bed, studio, penthouse;
## notch arrays run Hours notch 1 to 5.

@export_group("Clock (5.14)")
@export var days_per_month: int = 30
@export var days_per_year: int = 360
@export var speeds: PackedInt32Array = PackedInt32Array([1, 2, 4])
@export var calendar_days: int = 60
@export var legacy_day: int = 2160

@export_group("Money (5.15)")
@export var rent_day: int = 1
@export var payday: int = 25
@export var living_cost_k: float = 1.2
@export var living_cost_growth: float = 0.06
@export var living_cost_growth_days: int = 180
@export var lease_raise: float = 0.10
@export var lease_days: int = 360
@export var raise_meets: float = 0.01
@export var raise_exceeds: float = 0.03
@export var plan_b_days: int = 30
@export var runway_red_months: float = 2.0
@export var salary_base_k: PackedFloat64Array = PackedFloat64Array([3.0, 4.2, 6.0])
@export var resume_gap_offer_cut: float = 0.10
@export var home_rent_k: PackedFloat64Array = PackedFloat64Array([0.9, 1.5, 2.4, 4.0])
@export var home_recovery: PackedFloat64Array = PackedFloat64Array([0.0, 0.10, 0.25, 0.35])
@export var move_cost_months: float = 1.0
@export var start_home: int = 0
@export var run1_pay_days_accrued: int = 5
@export var run1_company: String = "co_synergai"
@export var run1_archetype: String = "startup"
@export var run1_remote: bool = false

@export_group("Work stats (5.16)")
@export var burnout_max: float = 100.0
@export var stat_max: float = 100.0
@export var mo_min: float = -100.0
@export var mo_max: float = 100.0
@export var skill_per_ticket: float = 2.0
@export var rust_per_day: float = 0.1
@export var ticket_size_days: PackedInt32Array = PackedInt32Array([10, 20, 35])
@export var ticket_deadline_mult: float = 1.0
@export var hours_speed: PackedFloat64Array = PackedFloat64Array([0.6, 0.8, 1.0, 1.25, 1.5])
@export var hours_burnout: PackedFloat64Array = PackedFloat64Array([-0.6, -0.3, 0.1, 0.5, 1.0])
@export var hours_mo: PackedFloat64Array = PackedFloat64Array([-0.15, -0.05, 0.0, 0.05, 0.10])
@export var hours_default: int = 3
@export var skill_speed_div: float = 200.0
@export var codebase_speed_div: float = 200.0
@export var codebase_burnout_min: float = 70.0
@export var codebase_burnout: float = 0.2
@export var low_runway_burnout: float = 0.4
@export var incident_base: float = 0.002
@export var incident_per_codebase: float = 0.0006
@export var mo_on_time: float = 5.0
@export var mo_late: float = -5.0

@export_group("The review (5.16)")
@export var review_prompts: int = 3
@export var evidence_base: float = 50.0
@export var evidence_mo_div: float = 2.0
@export var evidence_per_ticket: float = 5.0
@export var rating_below_max: float = 0.25
@export var rating_exceeds_min: float = 0.70
@export var pip_days: int = 60
@export var pip_mo_min: float = 0.0
@export var review_standin_damage: float = 0.55
@export var review_standin_noise: float = 0.20
@export var review_hit_good: float = 0.4          # the review duel (D-39, A94): a good answer takes this share of the manager's chip,
@export var review_hit_okay: float = 1.0          # an okay one takes all of it,
@export var review_hit_joke: float = 1.8          # and a joke nearly doubles it

@export_group("Controls (5.17)")
@export var pick_feature_mo: float = 6.0
@export var pick_feature_codebase: float = 3.0
@export var pick_bugfix_skill: float = 3.0
@export var pick_bugfix_codebase: float = -2.0
@export var pick_paydown_codebase: float = -15.0
@export var pick_paydown_mo: float = 0.0
@export var push_back_deadline: float = 0.30
@export var push_back_mo: float = -3.0
@export var quality_clean_codebase: float = -0.05
@export var quality_clean_speed: float = 0.85
@export var quality_fast_codebase: float = 0.12
@export var quality_fast_speed: float = 1.2
@export var fast_blame_days: int = 30
@export var calendar_tax: float = 0.85

@export_group("Archetypes and floors (5.18, 6.1)")
@export var floor_event_step: float = 0.15
@export var floor_doubt_step: float = 0.08
@export var floor_salary_step: float = 0.04
@export var max_jobs: int = 5
@export var coworker_level_weights: PackedFloat64Array = PackedFloat64Array([0.35, 0.40, 0.25])
@export var coworker_salary_noise: float = 0.05
@export var coworker_rapport_start: float = 50.0

@export_group("Events (5.19)")
@export var auto_resolve_from: float = 75.0
@export var auto_resolve_base: float = 70.0
@export var auto_resolve_span: float = 30.0
@export var burnout_warnings: PackedFloat64Array = PackedFloat64Array([60.0, 70.0, 75.0])
@export var burnout_warning_rearm: float = 10.0
@export var layoff_salary_weight: float = 0.8
@export var layoff_luck_weight: float = 0.2
@export var layoff_min_cut: int = 1
@export var final_threat_mult: float = 3.0
@export var rumor_lead_days_min: int = 10
@export var rumor_lead_days_max: int = 30

@export_group("The job hunt (5.20)")
@export var board_size: int = 4
@export var board_refresh_days: int = 14
@export var apply_burnout_employed: float = 3.0
@export var apply_burnout_unemployed: float = 2.0
@export var reply_days_min: int = 3
@export var reply_days_max: int = 10
@export var notice_p: float = 0.05
@export var notice_mo: float = -10.0
@export var callback_base: float = 0.35
@export var callback_level_same: float = 1.0
@export var callback_level_up: float = 0.5
@export var callback_level_down: float = 0.8
@export var callback_short_tenure_cut: float = 0.15
@export var callback_reference_bonus: float = 0.10
@export var callback_band_steps: PackedFloat64Array = PackedFloat64Array([0.10, 0.20, 0.30, 0.40])   # the 5-dot band's thresholds (A90)
@export var interview_days_min: int = 3
@export var interview_days_max: int = 7
@export var study_burnout: float = 4.0
@export var study_rust: float = -20.0
@export var study_skill: float = 1.0
@export var studies_prevent_gap: int = 3
@export var posting_level_weights: PackedFloat64Array = PackedFloat64Array([0.15, 0.60, 0.25])
@export var clause_remote_in_writing_p: float = 0.30
@export var clause_on_call_p: float = 0.25
@export var clause_unlimited_pto_p: float = 0.20
@export var duel_composure_burnout_div: float = 200.0
@export var duel_zone_skill_div: float = 200.0
@export var duel_zone_rust_div: float = 200.0
@export var reference_rapport: float = 60.0

@export_group("Scars and forced leave (5.21)")
@export var scar_max_stacks: int = 3
@export var short_tenure_days: int = 180
@export var short_tenure_clear_days: int = 360
@export var burnout_history_floor: float = 15.0
@export var burnout_history_clear_days: int = 120
@export var burnout_history_calm: float = 30.0
@export var bad_reference_mo: float = -20.0
@export var bad_reference_quit_mo: float = -30.0
@export var resume_gap_days: int = 60
@export var corner_cutter_leave_codebase: float = 80.0
@export var corner_cutter_codebase: float = 15.0
@export var corner_cutter_clear_codebase: float = 40.0
@export var forced_leave_days: int = 30
@export var forced_leave_pay: float = 0.5
@export var forced_leave_burnout: float = 50.0

@export_group("The Studio and the Handbook (3.4, 5.21)")
@export var studio_days: int = 90
@export var studio_burnout_max: float = 30.0
@export var studio_runway_months: float = 6.0
@export var studio_home: int = 2
@export var edge_emergency_months: float = 1.0
@export var edge_brag_evidence: float = 10.0
@export var edge_take_call_postings: int = 1
@export var edge_overtime_burnout_mult: float = 0.9
```

`archetype_data.gd`:

```gdscript
@tool
class_name ArchetypeData
extends Resource
## One company archetype (GDD 5.18, 11.7, owner "A"): the rules of a job. Files: res://data/archetypes/startup.tres,
## agency.tres, megacorp.tres. Script defaults = the Agency values. Never branch on an archetype's id (INV-09):
## every difference between archetypes is a number or a field here. Text lives in data/content/.

@export var id: StringName = &""              # startup | agency | megacorp (== file name)

@export_group("Duel and board")
@export var duel_tier: StringName = &"mid"    # the Phase 1 tier whose Doubt, difficulty and questions the duel borrows (MC-05)
@export var duels_per_offer: int = 1
@export var remote_share: float = 0.10
@export var board_weight: float = 1.0         # relative share of the board's postings
@export var company_ids: PackedStringArray = PackedStringArray(["co_pixelpivot", "co_beigeware", "co_bytebistro"])

@export_group("Pay")
@export var pay_mult: float = 0.80
@export var severance_options: PackedFloat64Array = PackedFloat64Array([0.5])   # months of salary, rolled with equal odds
@export var severance_per_year: float = 0.0   # extra months per 360 days of tenure, prorated
@export var leave_level_drop: int = 1         # levels lost on leaving (title inflation)

@export_group("The job")
@export var codebase_start: float = 55.0
@export var codebase_drift: float = 0.03
@export var ticket_speed: float = 1.0
@export var utilization_mo: float = -0.2      # MO a day at Hours notches 1-2
@export var floor_size: int = 12              # employees in the layoff pool, you included

@export_group("The review")
@export var review_cadence_days: int = 120
@export var calibration_hp: float = 50.0
@export var promotion_min_rating: int = 1     # 1 = Meets, 2 = Exceeds
@export var promotion_streak: int = 1         # consecutive reviews at that rating

@export_group("Layoffs and the return-to-office memo")
@export var layoff_share: float = 0.15        # of the floor, per resizing
@export var layoff_interval_days: int = 300   # days from a job's start (or the last resizing) to the next
@export var layoff_jitter_days: int = 60      # rolled between -jitter and +jitter
@export var rto_after_days: int = -1          # E08 can fire once tenure reaches this; -1 never
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
	"endings", "events", "cutscene", "names", "news", "work_events", "coworkers", "questions_review",
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
	return UiText.fill(tr(raw), args)


## One text field of a structured entry, e.g. field("questions_knowledge", "kq_hash_map", "prompt").
func field(file: String, id: String, key: String, args: Dictionary = {}) -> String:
	var e: Variant = entry(file, id)
	if not (e is Dictionary) or not (e as Dictionary).has(key):
		push_warning("Content: missing %s/%s.%s" % [file, id, key])
		return id
	return UiText.fill(tr(str(e[key])), args)


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
## Owns the RunState, the run's RNG, the phase and the settings file. The career run (M2) lives in `session`, a
## WorkSession: `run` then only holds the phase and the background, and the career_* verbs below drive the session.
## Scenes read `run` / `session` and call verbs. Only change_phase() changes the phase.
## Every verb that commits a player action ends with _commit() (save + HUD refresh).

signal phase_changed(from: GameFlow.Phase, to: GameFlow.Phase)
signal run_changed   # energy, rent, stats, board... changed: refresh the HUD

const SETTINGS_PATH := "user://settings.cfg"

var run: RunState = RunState.new()
var rng := RandomNumberGenerator.new()
var settings := ConfigFile.new()
## The career run on screen (ARCHITECTURE 19.4, 19.7): null in Phase 1's hunt and outside a run.
var session: WorkSession = null
## New game starts the career run. Only the Title's debug button turns this off, for Phase 1's hunt (until M4 retires it).
var career_flow: bool = true
var _intro_starts_career: bool = false   # the intro in front of us is a new game's, not a replay
## Background select focuses this card: the last background played (settings meta "last_background",
## GDD S03), "" before the first run (The Graduate then).
var preselect_background: String = ""


func _ready() -> void:
	settings.load(SETTINGS_PATH)  # a missing file just means defaults
	preselect_background = str(setting("meta", "last_background", ""))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if session != null:
				session.clock.speed = WorkClock.PAUSE   # no time passes while the app is away (D-13, INV-22)
				session.clock.hold()
				run_changed.emit()                      # the speed control shows Pause when you come back
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


## The next new run is a first run: no run has counted yet (settings meta run_count, below).
func next_run_is_first() -> bool:
	return int(setting("meta", "run_count", 0)) == 0


## Debug builds only (the Title's "Reset first run"): the next New game is a first run again, with its
## coach marks, the day-2 guarantee and the warm-up. A saved run keeps its own first_run.
func reset_first_run() -> void:
	set_setting("meta", "run_count", 0)


# ---------- saving ----------

## Writes only while a run is live (JOB_HUNT / INTERVIEW / OFFER, WORK / LAYOFF); a no-op otherwise. The career run saves
## the session ({version: 2, phase, sim, ui}), Phase 1's hunt the RunState.
func save() -> void:
	if not GameFlow.is_saved(run.phase):
		return
	if session != null and _is_career_phase(run.phase):
		SaveIO.write_career(session.to_save(run.phase))
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
	if GameFlow.deletes_save(from, to):  # the run is over: its save goes, and it counts once
		SaveIO.delete()
		_count_finished_run()
	save()
	phase_changed.emit(from, to)


## The career run (DECISIONS A78): run 1 is the Intern at the authored job, after the intro the first time; later runs pick
## a background first. Phase 1's hunt is only reachable through start_hunt_game().
func start_new_game() -> void:  # Title: "Tap to start"
	run = RunState.new()
	session = null
	career_flow = true
	_intro_starts_career = false
	if not next_run_is_first():
		change_phase(GameFlow.Phase.BACKGROUND_SELECT)
	elif setting("meta", "intro_seen", false):
		_begin_career(1, "intern", "", new_run_seed())
	else:
		_intro_starts_career = true
		change_phase(GameFlow.Phase.INTRO)


## Debug builds only (the Title's "Old hunt" button): Phase 1's job hunt, as v0.1 shipped it, until M4 retires it.
func start_hunt_game() -> void:
	run = RunState.new()
	session = null
	career_flow = false
	_intro_starts_career = false
	var intro_seen: bool = setting("meta", "intro_seen", false)
	change_phase(GameFlow.Phase.BACKGROUND_SELECT if intro_seen else GameFlow.Phase.INTRO)


func replay_intro() -> void:  # Title: "Replay intro"
	run = RunState.new()
	session = null
	career_flow = true
	_intro_starts_career = false
	change_phase(GameFlow.Phase.INTRO)


func finish_intro() -> void:  # the intro ended, or Skip, or Android Back
	set_setting("meta", "intro_seen", true)
	if career_flow and _intro_starts_career:
		_intro_starts_career = false
		_begin_career(1, "intern", "", new_run_seed())
	else:
		change_phase(GameFlow.Phase.BACKGROUND_SELECT)


## Continue resumes whichever run the slot holds: a career run (version 2) or Phase 1's hunt. Never a dead button.
func continue_game() -> void:
	match SaveIO.kind():
		SaveIO.KIND_CAREER:
			if _resume_career():
				return
		SaveIO.KIND_HUNT:
			if _resume_hunt():
				return
	start_new_game()


func _resume_hunt() -> bool:
	var loaded := SaveIO.read()
	if loaded == null or not GameFlow.can_resume(loaded.phase):
		return false
	var resume_at := loaded.phase
	session = null
	career_flow = false
	run = loaded
	run.phase = GameFlow.Phase.TITLE
	rng.seed = run.rng_seed.to_int()   # seed first: setting seed resets state
	rng.state = run.rng_state.to_int()
	change_phase(resume_at)
	return true


func _resume_career() -> bool:
	var data := SaveIO.peek()
	var resume_at := int(data.get("phase", GameFlow.Phase.WORK)) as GameFlow.Phase
	if not CAREER_PHASES.has(resume_at) or not GameFlow.can_resume(resume_at):
		return false
	var bg_id := str((data.get("sim", {}) as Dictionary).get("bg_id", "intern"))
	session = WorkSession.from_save(data, SimContext.load_default(bg_id))   # the clock starts paused (KILL_TESTS 6)
	career_flow = true
	_intro_starts_career = false
	run = RunState.new()
	run.background_id = bg_id
	run.player_name = session.player_name
	if resume_at == GameFlow.Phase.INTERVIEW:
		if session.duel_checkpoint.is_empty():
			resume_at = GameFlow.Phase.WORK
		else:
			_prepare_run_for_duel(session.duel_checkpoint)
	elif resume_at == GameFlow.Phase.OFFER:
		if session.wants_offer():
			_prepare_run_for_offer()
		else:
			resume_at = GameFlow.Phase.WORK
	change_phase(resume_at)
	return true


## Plan B "Retry" and Hired "New run": a brand-new RunState, same background preselected.
func retry() -> void:
	var from := run.phase
	preselect_background = run.background_id
	session = null
	run = RunState.new()
	run.phase = from  # keeps the transition legal; leaving PHASE2_STUB deletes the save
	change_phase(GameFlow.Phase.BACKGROUND_SELECT)


## Pause "Quit to title", Background select Back, ending "Title". The save survives for Continue.
func quit_to_title() -> void:
	if session != null:
		save()   # a career run resumes where you left it, not at its last eventful day
	change_phase(GameFlow.Phase.TITLE)
	session = null


func choose_background(bg_id: String, player_name: String, run_seed: int = 0) -> void:
	var chosen_seed := run_seed if run_seed != 0 else new_run_seed()
	preselect_background = bg_id
	set_setting("meta", "last_background", bg_id)
	if career_flow:
		_begin_career(int(setting("meta", "run_count", 0)) + 1, bg_id, player_name, chosen_seed)
		return
	_init_run(bg_id, player_name, chosen_seed)
	change_phase(GameFlow.Phase.JOB_HUNT)


## A fresh run seed: the global RNG only ever picks seeds. Never 0, which means "pick one" above.
## Background select picks it when it opens, so its card can show the gaps this seed will roll.
func new_run_seed() -> int:
	var run_seed := 0
	while run_seed == 0:
		run_seed = randi()
	return run_seed


## The gap topics a run with this seed will roll (GDD S03 shows them before CHOOSE). It matches
## _init_run() because the gap roll is the run RNG's first draw after seeding.
func preview_gap_topics(bg_id: String, run_seed: int) -> Array:
	var bg := Content.background(bg_id)
	if bg == null:
		return []
	var preview := RandomNumberGenerator.new()
	preview.seed = run_seed
	return Odds.pick(preview, _gap_pool(), bg.gap_topics_count)


## Debug only: set a career run up in place so `project_run mode="custom"` can launch the work or layoff scene alone.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched. to_layoff plays run 1 to the
## layoff scene (answering whatever comes, the simplest way).
func debug_career_quick_start(to_layoff: bool = false, run_seed: int = 20261009) -> void:
	run = RunState.new()
	run.background_id = "intern"
	run.player_name = "Alex"
	career_flow = true
	session = WorkSession.start(SimContext.load_default("intern"), 1, run_seed, [], "Alex", true)
	run.phase = GameFlow.Phase.WORK
	if to_layoff:
		session.play_to_layoff()
		run.phase = GameFlow.Phase.LAYOFF


## Debug only: set a run up in place so `project_run mode="custom"` can launch one feature scene.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched.
func debug_quick_start(bg_id: String, phase: GameFlow.Phase, run_seed: int = 20260926) -> void:
	run = RunState.new()
	_init_run(bg_id, "Alex", run_seed)
	run.phase = phase


## Debug only (the hub's DEBUG row keeps an interview one tap away): a waiting invite from the tier's
## first MVP company that isn't blacklisted, for the tier's first open posting, as if it arrived this
## morning. No application backs it. No dice. {} when the tier has no company left.
func debug_fake_invite(tier_id: String) -> Dictionary:
	var company_id := _first_entry_id("companies", func(id: String, e: Dictionary) -> bool:
		return str(e.get("tier", "")) == tier_id and bool(e.get("mvp", false)) and not run.blacklist.has(id))
	var template_id := _first_entry_id("postings", func(_id: String, e: Dictionary) -> bool:
		return str(e.get("tier", "")) == tier_id and str(e.get("company", "any")) == "any" \
			and not bool(e.get("should", false)))
	if company_id.is_empty() or template_id.is_empty():
		return {}
	var invite := {
		"uid": run.new_uid(), "app_uid": -1, "company_id": company_id, "template_id": template_id,
		"tier": tier_id, "day_received": run.day, "kind": "rolled", "mail_id": "mail_invite_" + tier_id,
	}
	run.invites.append(invite)
	_commit()
	return invite.duplicate()


## The first id, in sorted order, of a content file's entries that passes test(id, entry).
func _first_entry_id(file: String, test: Callable) -> String:
	var entries := Content.entries(file)
	var ids: Array = entries.keys()
	ids.sort()
	for id: Variant in ids:
		var entry: Variant = entries[id]
		if entry is Dictionary and bool(test.call(str(id), entry)):
			return str(id)
	return ""


## The background's starting numbers, the name, the seed, the gap topics, first_run, then the
## day-1 board, all on the run RNG in this order. Keep the gap roll the first draw after seeding:
## preview_gap_topics() shows it on the Background select card.
func _init_run(bg_id: String, player_name: String, run_seed: int) -> void:
	var bg := Content.background(bg_id)
	var cfg := Content.balance
	rng.seed = run_seed
	run.rng_seed = str(run_seed)
	run.set_background(cfg, bg)
	run.player_name = player_name
	run.gap_topics.assign(Odds.pick(rng, _gap_pool(), bg.gap_topics_count))
	run.first_run = next_run_is_first()
	run.deal_board(cfg, _tiers(), _hunt_content(), rng)


func _gap_pool() -> Array:
	return Content.entries("naming").get("_gap_topic_pool", [])


# ---------- the career run (M2; ARCHITECTURE 19.4, 19.7) ----------
## The WORK scene calls these; the rules are the sim's (WorkSession -> Sim). Every answer is applied without a tick, so
## time moves only in career_tick(), which the scene calls once a day while nothing is open. Each answer saves.

## The phases a career save can hold. INTERVIEW and OFFER are Phase 1's too, so they count as the career's only while a
## session exists (the hunt has none): otherwise save() would write a hunt save over the career one (A88).
const CAREER_PHASES: Array[GameFlow.Phase] = [GameFlow.Phase.WORK, GameFlow.Phase.LAYOFF, GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER]


func _is_career_phase(phase: GameFlow.Phase) -> bool:
	if phase == GameFlow.Phase.INTERVIEW or phase == GameFlow.Phase.OFFER:
		return session != null
	return CAREER_PHASES.has(phase)


## A new career run: the sim's first state, the Handbook's collected tips, then the work state (which saves).
func _begin_career(run_number: int, bg_id: String, player_name: String, run_seed: int) -> void:
	var from := run.phase
	var first := next_run_is_first()
	if player_name.is_empty():   # run 1 skips Background select, where the name dice live
		player_name = Content.text("names", "default")
	var topics_rng := RandomNumberGenerator.new()
	topics_rng.seed = DuelAdapter.seed_text(run_seed, DuelAdapter.SALT_PICK, 0, 0).to_int()
	var topics := Odds.pick(topics_rng, _gap_pool(), Content.background(bg_id).gap_topics_count)
	session = WorkSession.start(SimContext.load_default(bg_id), run_number, run_seed, collected_tips(), player_name, first, topics)
	run = RunState.new()
	run.phase = from   # keeps the transition legal, like retry()
	run.background_id = bg_id
	run.player_name = player_name
	change_phase(GameFlow.Phase.WORK)


## The tips the player has collected over all runs (the Handbook, GDD 5.21), as ids.
func collected_tips() -> Array:
	return Array(setting("meta", "handbook", []))


## One day (the clock). Saves when something happened worth keeping: a card, a payday, a shipped ticket.
func career_tick() -> void:
	if session == null:
		return
	var events := session.tick()
	_after_career(events, _career_events_worth_a_save(events))   # refreshes the screen after every day, saves on the notable ones


func career_set_speed(position: int) -> void:
	if session != null:
		session.clock.set_speed(position, session.ctx.cfg)
		run_changed.emit()


func career_set_hours(notch: int) -> void:
	_career_answer(func() -> Array: return session.set_hours(notch))


func career_choose(choice_id: String) -> void:
	_career_answer(func() -> Array: return session.choose(choice_id))


func career_pick_ticket(pick: String) -> void:
	_career_answer(func() -> Array: return session.pick_ticket(pick))


func career_resolve_review() -> void:
	_career_answer(func() -> Array: return session.resolve_review())


## The DoomApply board's two actions (GDD 5.20): apply to a posting, study.
func career_apply(posting_id: int) -> void:
	_career_answer(func() -> Array: return session.apply_to(posting_id))


func career_study() -> void:
	_career_answer(func() -> Array: return session.study())


## Start button of an interview day (or, from M3's review duel, of a review): the sim's request becomes the interview
## checkpoint (DuelAdapter), the run is filled with what the duel screen reads, and INTERVIEW saves it (A88).
func career_begin_duel() -> void:
	if session == null or run.phase != GameFlow.Phase.WORK:
		return
	var checkpoint := session.begin_duel()
	if checkpoint.is_empty():
		return
	session.clock.set_speed(WorkClock.PAUSE, session.ctx.cfg)
	_prepare_run_for_duel(checkpoint)
	change_phase(GameFlow.Phase.INTERVIEW)


## The interview ended (the duel screen calls finish_interview): a win leads to the contract, a loss back to work.
func career_finish_duel(won: bool, composure_left: float) -> void:
	if session == null:
		return
	run.interview = {}
	session.finish_duel(won, composure_left)
	_after_duel()


## The review duel ended with this much Evidence left.
func career_finish_review(evidence_left: float) -> void:
	if session == null:
		return
	run.interview = {}
	session.finish_review(evidence_left)
	_after_duel()


func _after_duel() -> void:
	if session.is_over():
		_finish_career()
	elif session.wants_offer():
		_prepare_run_for_offer()
		change_phase(GameFlow.Phase.OFFER)
	else:
		change_phase(GameFlow.Phase.WORK)


## Accept or Decline on the contract (the offer screen calls answer_offer). Accepting while employed is a voluntary exit;
## the sim starts the next job. Back at work either way, or at an ending when leaving job 5 ended the career.
func career_answer_offer(accept: bool) -> void:
	if session == null:
		return
	run.offer = {}
	session.answer_offer(accept)
	if session.is_over():
		_finish_career()
	else:
		change_phase(GameFlow.Phase.WORK)


## An offer on the table while the work state shows (a resumed or odd state): go to the contract.
func career_begin_offer() -> void:
	if session != null and run.phase == GameFlow.Phase.WORK and session.wants_offer():
		session.clock.set_speed(WorkClock.PAUSE, session.ctx.cfg)
		_prepare_run_for_offer()
		change_phase(GameFlow.Phase.OFFER)


## Declining an offer never ends a career run (it did on Phase 1's grace day); the offer screen asks.
func decline_ends_run() -> bool:
	return false if career_flow else run.decline_ends_run()


## The duel screen reads the run the way Phase 1 filled it: the background's starting stats (KNOWLEDGE, EXPERIENCE and
## NETWORK stay there in the career run, D-26), the gap topics, how often Dana has met you, and the checkpoint.
func _prepare_run_for_duel(checkpoint: Dictionary) -> void:
	_prepare_run_basics()
	run.gap_topics.assign(session.gap_topics)
	run.first_run = session.first_run
	run.interviews_taken = session.dana_met
	run.times_met_dana = session.dana_met
	run.dana_last_company = session.dana_last_company
	run.interview = checkpoint.duplicate(true)


## The offer screen shows run.offer, the contract paper (DuelAdapter.offer_paper).
func _prepare_run_for_offer() -> void:
	_prepare_run_basics()
	run.offer = session.offer_paper()


func _prepare_run_basics() -> void:
	run.set_background(Content.balance, Content.background(session.sim.bg_id))
	run.player_name = session.player_name


func career_fail_interview() -> void:
	_career_answer(func() -> Array: return session.fail_interview())


func career_decline_offer() -> void:
	_career_answer(func() -> Array: return session.decline_offer())


## OK on the layoff scene or the forced leave.
func career_acknowledge() -> void:
	_career_answer(func() -> Array: return session.acknowledge())


## OK on a notice. Not an input to the sim: only the screen's own state changes.
func career_dismiss_notice() -> void:
	if session == null:
		return
	session.dismiss_notice()
	_after_career([], true)


func career_close_coach(coach_id: String) -> void:
	if session != null:
		session.close_coach(coach_id)
		_commit()


func _career_answer(answer: Callable) -> void:
	if session == null:
		return
	_after_career(answer.call(), true)


## After any step or answer: an ending leaves the run, the layoff scene is its own phase, and the save keeps what
## happened (the run log and the screen's state travel with it).
func _after_career(events: Array, save_now: bool) -> void:
	if session.is_over():
		_finish_career()
		return
	if run.phase == GameFlow.Phase.WORK and session.wants_layoff_scene():
		session.clock.set_speed(WorkClock.PAUSE, session.ctx.cfg)   # the scene is a beat of its own: the clock waits after it
		change_phase(GameFlow.Phase.LAYOFF)   # saves
		return
	if run.phase == GameFlow.Phase.LAYOFF and not WorkCards.is_layoff_pending(session.sim):
		change_phase(GameFlow.Phase.WORK)     # saves
		return
	if run.phase == GameFlow.Phase.WORK and session.wants_offer() and session.notices.is_empty():
		career_begin_offer()
		return
	if save_now or session.is_blocked():
		_commit()
	else:
		run_changed.emit()


func _career_events_worth_a_save(events: Array) -> bool:
	for e: Dictionary in events:
		if String(e.get("kind", "")) in ["payday", "rent", "ticket_shipped", "job_ended", "event", "review"]:
			return true
	return false


## The sim ended the run: the tips it showed join the Handbook, then the ending card. Entering GAME_OVER deletes the save
## and counts the run (change_phase).
func _finish_career() -> void:
	var tips: Array = collected_tips()
	for tip: Variant in session.sim.tips_seen:
		if not tips.has(tip):
			tips.append(tip)
	set_setting("meta", "handbook", tips)
	change_phase(GameFlow.Phase.GAME_OVER)


# ---------- job hunt verbs (each committed action ends with _commit()) ----------

## Swipe right or APPLY: Quick Apply with your honest CV (1 pip). False when refused: the card is
## gone, its company is blacklisted, or there isn't enough energy.
func quick_apply(card_uid: int) -> bool:
	return _apply(card_uid, false, false)


## Card back TAILOR & APPLY (2 pips): every CV line goes out Polished for this application; optionally
## spending a referral token.
func tailor_apply(card_uid: int, use_referral: bool) -> bool:
	return _apply(card_uid, true, use_referral)


func _apply(card_uid: int, tailored: bool, referral: bool) -> bool:
	if run.apply_card(Content.balance, _tiers(), _bg(), _hunt_content(), card_uid, tailored, referral).is_empty():
		return false
	_commit()
	return true


## Swipe left or SKIP: the card goes to the back of the deck.
func skip_card(card_uid: int) -> bool:
	if not run.skip_card(card_uid):
		return false
	_commit()
	return true


func study() -> bool:
	var cfg := Content.balance
	if not run.spend_energy(cfg.cost_study):
		return false
	run.stats["knw"] = mini(run.stats["knw"] + cfg.study_knw_gain, cfg.stat_cap)
	_commit()
	return true


## Sleep: the night tick, the morning reveal, the board refill, the day-2 guarantee and the rent
## check all land in run.morning_report with exactly ONE save, so a kill right after Sleep resumes on
## the same morning and a kill before it replays the same dice (ARCHITECTURE 7.1).
func sleep() -> void:
	run.sleep(Content.balance, _tiers(), _bg(), _hunt_content(), rng)
	_commit()


## Mail "Start day": the morning has been seen. Rent at 0 with no grace day ends the run (GDD 5.10).
func start_day() -> void:
	if run.start_day():
		end_run_plan_b()
	else:
		_commit()


## What a board card shows (GDD S04): its 3 tags checked against your honest CV, and the odds of each
## way to apply (RunState.card_odds). {} if the card's data is missing. Changes nothing.
func card_odds(card: Dictionary) -> Dictionary:
	return run.card_odds(Content.balance, _tiers(), _bg(), _hunt_content(), card)


## A Ducky tip a once-per-run trigger just showed (HuntTips, GDD 8.3). Not a player action: it is
## saved with the next commit.
func mark_tip_shown(tip_id: String) -> void:
	if not run.tips_shown.has(tip_id):
		run.tips_shown.append(tip_id)


## A first-run coach mark tapped closed (GDD 4.3, HuntTips.coach): it never shows again this run. Saved
## at once, because Quit to title writes no save and Continue must not bring it back.
func close_coach_mark(coach_id: String) -> void:
	if coach_id.is_empty() or run.coach_closed.has(coach_id):
		return
	run.coach_closed.append(coach_id)
	_commit()


## The hunt rules' data arguments (RunState, "job hunt" section).
func _tiers() -> Dictionary:
	var out: Dictionary = {}
	for id: String in RunState.TIER_IDS:
		out[id] = Content.tier(id)
	return out


func _hunt_content() -> Dictionary:
	var out: Dictionary = {}
	for file: String in ["postings", "companies", "cv_lines", "emails"]:
		out[file] = Content.entries(file)
	return out


func _bg() -> BackgroundData:
	return Content.background(run.background_id)


# ---------- interview ----------

## Mail "GO NOW": today's slot and the energy are checked, the invite leaves Mail, the energy is paid,
## then the interview is frozen: its seed, then its questions (GDD 5.13), on the run RNG in that
## order, so a resume replays it exactly. Nothing changes when refused.
func start_interview(invite: Dictionary) -> void:
	var cfg := Content.balance
	if not can_take_interview(invite):
		return
	var cost := interview_cost(invite)
	var taken := run.take_invite(int(invite.get("uid", -1)))
	if taken.is_empty():
		return  # expired, withdrawn or already taken
	run.spend_energy(cost)
	run.interviews_today += 1
	var tier_id := str(taken["tier"])
	var interview_seed := str(rng.randi())
	var plan := InterviewPlan.pick(cfg, tier_id, Content.entries("questions_choice"),
		Content.entries("questions_knowledge"), run.seen_question_ids, rng, InterviewPlan.warmup_due(run))
	run.interview = {
		"invite_uid": taken["uid"], "company_id": taken["company_id"],
		"template_id": taken["template_id"], "tier": tier_id,
		"seed": interview_seed, "tired": Odds.is_tired(cfg, run.energy),
		"question_ids": plan["question_ids"],  # prompt order (cfg.prompt_pattern)
		"warmup_id": plan["warmup_id"],        # "" unless the first interview of the first run
	}
	InterviewPlan.mark_seen(run.seen_question_ids, plan["question_ids"] + [plan["warmup_id"]])
	change_phase(GameFlow.Phase.INTERVIEW)  # saves the checkpoint


## GDD 5.3: an interview costs cfg.cost_interview pips, plus the background's travel pips when the
## tier interviews in person (the Self-Taught's +1). -1 for an unknown tier.
func interview_cost(invite: Dictionary) -> int:
	var tier_data := Content.tier(str(invite.get("tier", "")))
	if tier_data == null:
		return -1
	return Content.balance.cost_interview + (_bg().interview_travel_pips if tier_data.in_person else 0)


## GO NOW is possible: today's interview isn't used yet and the pips are there (GDD 5.3). Mail greys
## GO NOW out otherwise.
func can_take_interview(invite: Dictionary) -> bool:
	var cost := interview_cost(invite)
	return cost >= 0 and run.interviews_today < Content.balance.max_interviews_per_day and run.energy >= cost


## won = K.O. or committee win. A win builds the whole offer from the checkpoint (RunState.make_offer)
## before it is cleared.
func finish_interview(won: bool, composure_left: float) -> void:
	if session != null and career_flow:
		career_finish_duel(won, composure_left)
		return
	var iv := run.interview
	var company_id: String = iv.get("company_id", "")
	run.interviews_taken += 1
	run.times_met_dana += 1
	run.dana_last_company = company_id
	if won:
		run.make_offer(Content.balance, Content.tier(str(iv["tier"])), _bg(), _hunt_content(), composure_left)
	run.interview = {}
	change_phase(GameFlow.Phase.OFFER if won else GameFlow.Phase.JOB_HUNT)


# ---------- offer and endings ----------

## Decline (after the confirm dialog): the company is blacklisted and the hunt goes on the same day,
## except on the grace day (rent at 0), when declining is Plan B (GDD 5.10, RunState.decline_ends_run).
## Accept: the offer becomes the job (run.hire) and the Hired card shows. Accept writes no save:
## PHASE2_STUB is never saved, so a kill on the Hired card resumes at the offer (GDD 5.11), and
## accepting again hires with the same contract. No dice.
## The review duel's end (the interview screen calls it with the Evidence it has left): the sim rates it.
func finish_review(evidence_left: float) -> void:
	career_finish_review(evidence_left)


func answer_offer(accept: bool) -> void:
	if session != null and career_flow:
		career_answer_offer(accept)
		return
	var company_id: String = run.offer.get("company_id", "")
	if not accept:
		var ends_run := run.decline_ends_run()
		run.blacklist_company(company_id)
		run.offer = {}
		if ends_run:
			end_run_plan_b()
		else:
			change_phase(GameFlow.Phase.JOB_HUNT)
		return
	run.hire(Content.balance, _bg(), Content.entries("companies").get(company_id, {}).get("red_flags", []))
	change_phase(GameFlow.Phase.PHASE2_STUB)


## The Hired card's Dream vs Reality rows (RunState.dream_breakdown). Changes nothing.
func dream_breakdown() -> Array[float]:
	return run.dream_breakdown(Content.balance, _bg())


## Morning with rent at 0, no invite, grace day used (or none waiting); or Decline on the grace day.
func end_run_plan_b() -> void:
	change_phase(GameFlow.Phase.GAME_OVER)


## settings meta run_count (first_run reads it): a run counts once, when it is over for good, which is
## when change_phase() deletes its save (Plan B, or leaving the Hired card). Not on Accept: a kill on
## the Hired card resumes at the offer, and accepting again must not count the run twice.
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


## The on-screen keyboard's height in GAME pixels; 0 while it is hidden and on desktop (S03 name field).
## Assumes native pixels and divides by the scale, as safe_insets() does: the unit is unverified until
## the iPhone test (ARCHITECTURE 18.1 #12).
func keyboard_height() -> float:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD):
		return 0.0  # desktop display servers warn on every call otherwise
	var native := DisplayServer.virtual_keyboard_get_height()
	if native <= 0:
		return 0.0
	var win := get_tree().root
	var game := win.get_visible_rect().size
	var px := Vector2(win.size)
	var s := minf(px.x / game.x, px.y / game.y)
	if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER:
		s = maxf(floorf(s), 1.0)
	return native / s


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
	GameFlow.Phase.WORK: "res://features/work/work.tscn",
	GameFlow.Phase.LAYOFF: "res://features/layoff/layoff.tscn",
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
## Make it cover the whole screen (full rect) so a tap anywhere counts; it draws the bar at the y the scene
## passes to set_bar_y() (the S08 meter row, section 11.6), or 40 px above its bottom edge until then.
## Positions are fractions of the bar (0..1). The scene adds the zone labels.

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
var _bar_y := -1.0       # Step 4: the meter row's y in this Control; negative = 40 px above the bottom


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


## Step 4: the zone as (centre, half-width), so the scene can place the zone labels.
func zone() -> Vector2:
	return Vector2(_c, _h)


## Step 4 (ARCHITECTURE 11.6): the scene passes the meter row's y, in this Control's coordinates, on
## `resized` and Device.layout_changed, so the bar sits above the tap pad and never under the thumb.
func set_bar_y(y: float) -> void:
	_bar_y = y
	queue_redraw()


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
	var origin := Vector2(floorf((size.x - w) * 0.5), floorf(_bar_y if _bar_y >= 0.0 else size.y - 40.0))
	var vague_from := maxf(_c - 2.0 * _h, 0.0)  # Step 4 fix: Vague is clipped to the bar (c - 2h can be < 0, c + 2h > 1)
	var vague_to := minf(_c + 2.0 * _h, 1.0)
	draw_rect(Rect2(origin, Vector2(w, BAR_HEIGHT)), Color("#1d2b53"))                                        # Rambling / Overthinking
	draw_rect(Rect2(origin + Vector2(floorf(vague_from * w), 0), Vector2(floorf((vague_to - vague_from) * w), BAR_HEIGHT)), Color("#ffa300"))  # Vague
	draw_rect(Rect2(origin + Vector2(floorf((_c - _h) * w), 0), Vector2(floorf(2.0 * _h * w), BAR_HEIGHT)), Color("#00e436"))        # NAILED IT
	draw_rect(Rect2(origin + Vector2(floorf(needle() * w) - 1.0, -3.0), Vector2(2.0, BAR_HEIGHT + 6.0)), Color.WHITE)
```

### 17.12 `features/title/title.gd` (Step 3; it replaced the Step 1 boot stub)

The real Title (section 11.1) replaced the Step 1 stub in Step 3. The stub's window, game and scale-mode readout lives on as the debug-only `%SizeReadout`.

The scene `features/title/title.tscn`: a root `Title` (Control, full rect) with this script; `Background` (ColorRect, full-bleed); `SafeArea` (MarginContainer + SafeAreaMargin) > `Column` (254 wide) > `SkyBand` (`%SizeReadout`), `Sign` (a PanelContainer holding `%Software`, `%Engineer`, `%Simulator`), `Body` (it expands), `ThumbBand` (`%TapToStart`, `%NewGameButton`, `%ContinueButton`, and a `BottomRow` with `%ReplayIntroButton`, `%DeviceCheckButton`, `%Version`); `ModalLayer` (CanvasLayer) > `%QuitDialog` (an instance of `confirm_dialog.tscn`). Every container is `mouse_filter = IGNORE`, so a tap that misses the buttons reaches the root.

```gdscript
extends Control
## Title screen (GDD S01, ARCHITECTURE 11.1), before the art pass.
## No save: tap anywhere = New game. With a save: [ New game ] above a full-width CONTINUE.
## Debug builds also show the Step 1 size readout and a debug row: the Step 2 "Device check" button
## and "Reset first run" (the next New game gets the first-run coach marks again).

## Loaded by path when pressed, never preloaded: features/dev/ is excluded from release exports.
const DEVICE_CHECK_PATH := "res://features/dev/device_check.tscn"
const BLINK_SEC := 0.5
## Debug-only labels, English on purpose (not player text, so not in CONTENT.md).
const DEBUG_DEVICE_CHECK := "Device check"
const DEBUG_FIRST_RUN := "Reset first run"
const DEBUG_HUNT := "Old hunt"   # Phase 1's job hunt, until M4 retires it (DECISIONS A78)

var _has_save: bool = false
var _device_check: Control = null

@onready var _software: Label = %Software
@onready var _engineer: Label = %Engineer
@onready var _simulator: Label = %Simulator
@onready var _size_readout: Label = %SizeReadout
@onready var _tap_to_start: Label = %TapToStart
@onready var _new_game_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
@onready var _replay_intro_button: Button = %ReplayIntroButton
@onready var _hunt_button: Button = %HuntButton
@onready var _debug_row: Control = %DebugRow
@onready var _device_check_button: Button = %DeviceCheckButton
@onready var _first_run_button: Button = %FirstRunButton
@onready var _version: Label = %Version
@onready var _quit_dialog: ConfirmDialog = %QuitDialog


func _ready() -> void:
	_software.text = Content.text("barks", "ui_logo_1")
	_engineer.text = Content.text("barks", "ui_logo_2")
	_simulator.text = Content.text("barks", "ui_logo_3")
	_tap_to_start.text = Content.text("barks", "ui_tap_to_start")
	_new_game_button.text = Content.text("barks", "ui_new_game")
	_continue_button.text = UiText.primary(Content.text("barks", "ui_continue"))
	_replay_intro_button.text = Content.text("barks", "ui_replay_intro")
	_hunt_button.text = DEBUG_HUNT
	_hunt_button.visible = OS.is_debug_build()
	_device_check_button.text = DEBUG_DEVICE_CHECK
	_first_run_button.text = DEBUG_FIRST_RUN
	_has_save = SaveIO.exists()
	_tap_to_start.visible = not _has_save
	_new_game_button.visible = _has_save
	_continue_button.visible = _has_save
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	_size_readout.visible = OS.is_debug_build()
	set_process(OS.is_debug_build())
	_debug_row.visible = OS.is_debug_build()
	_device_check_button.visible = OS.is_debug_build() and ResourceLoader.exists(DEVICE_CHECK_PATH)
	_first_run_button.disabled = GameState.next_run_is_first()  # off: the next run already is one
	_new_game_button.pressed.connect(GameState.start_new_game)
	_continue_button.pressed.connect(GameState.continue_game)
	_replay_intro_button.pressed.connect(GameState.replay_intro)
	_hunt_button.pressed.connect(GameState.start_hunt_game)
	_device_check_button.pressed.connect(_open_device_check)
	_first_run_button.pressed.connect(_reset_first_run)
	_quit_dialog.confirmed.connect(get_tree().quit)
	if not _has_save:
		var blink := create_tween().set_loops()
		blink.tween_interval(BLINK_SEC)
		blink.tween_callback(_toggle_tap_to_start)


## Step 1's scale-guard readout, kept as a debug overlay (ARCHITECTURE 11.1): resize the window
## and "game" changes while the pixels stay square.
func _process(_delta: float) -> void:
	var win := get_tree().root
	var game := Vector2i(win.get_visible_rect().size)
	var mode := "integer" if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER else "fractional"
	_size_readout.text = "win %dx%d game %dx%d %s" % [win.size.x, win.size.y, game.x, game.y, mode]


## No save: a tap anywhere outside the buttons starts a new game. Every container here is IGNORE,
## so the tap falls through to this root. It acts on release, like a Button.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if _has_save or mb == null or mb.button_index != MOUSE_BUTTON_LEFT or mb.pressed:
		return
	accept_event()
	GameState.start_new_game()


## Close the open overlay first; else "Quit?" on Android and desktop. iOS apps never quit themselves.
func handle_back() -> bool:
	if _device_check != null:
		return bool(_device_check.call(&"handle_back"))  # the device check counts Back presses
	if _quit_dialog.is_open():
		return _quit_dialog.handle_back()
	if OS.get_name() == "iOS":
		return false
	_quit_dialog.open(Content.text("barks", "ui_quit_confirm"), Content.text("barks", "ui_quit"), "", true)
	return true


func _toggle_tap_to_start() -> void:
	_tap_to_start.modulate.a = 1.0 - _tap_to_start.modulate.a


func _open_device_check() -> void:
	if _device_check != null:
		return
	_device_check = (load(DEVICE_CHECK_PATH) as PackedScene).instantiate() as Control
	_device_check.connect(&"closed", _close_device_check)
	add_child(_device_check)  # full rect, mouse_filter STOP: covers and blocks the title while open


func _close_device_check() -> void:
	_device_check.queue_free()
	_device_check = null


func _reset_first_run() -> void:
	GameState.reset_first_run()
	_first_run_button.disabled = true
```

In a debug build in the 540x960 desktop window, the readout shows `win 540x960 game 270x480 integer`. (The Step 1 stub showed the same numbers as `window (540, 960)` / `game (270, 480) (integer)`, checked live on 2026-09-26 with no runtime errors.)

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
	[GameFlow.Phase.OFFER, GameFlow.Phase.GAME_OVER],  # Decline on the grace day (GDD 5.10)
	[GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE],
	[GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.TITLE],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.BACKGROUND_SELECT],
	# Back / pause "Quit to title" (the save survives):
	[GameFlow.Phase.BACKGROUND_SELECT, GameFlow.Phase.TITLE],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.TITLE],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.TITLE],
	[GameFlow.Phase.OFFER, GameFlow.Phase.TITLE],
	# The career run (ARCHITECTURE 19.4): New game and Continue reach WORK; the layoff scene is its own phase.
	[GameFlow.Phase.TITLE, GameFlow.Phase.WORK],
	[GameFlow.Phase.TITLE, GameFlow.Phase.LAYOFF],
	[GameFlow.Phase.INTRO, GameFlow.Phase.WORK],
	[GameFlow.Phase.BACKGROUND_SELECT, GameFlow.Phase.WORK],
	[GameFlow.Phase.WORK, GameFlow.Phase.LAYOFF],
	[GameFlow.Phase.WORK, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.WORK, GameFlow.Phase.TITLE],
	[GameFlow.Phase.LAYOFF, GameFlow.Phase.WORK],
	[GameFlow.Phase.LAYOFF, GameFlow.Phase.TITLE],
	# M3's adapter (ARCHITECTURE 19.5): an interview day or a review leaves WORK for INTERVIEW and comes back, or goes on
	# to the contract after a win; the contract leads back to WORK.
	[GameFlow.Phase.WORK, GameFlow.Phase.INTERVIEW],
	[GameFlow.Phase.WORK, GameFlow.Phase.OFFER],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.WORK],
	[GameFlow.Phase.OFFER, GameFlow.Phase.WORK],
]

const ILLEGAL: Array[Array] = [
	[GameFlow.Phase.TITLE, GameFlow.Phase.TITLE],
	[GameFlow.Phase.TITLE, GameFlow.Phase.PHASE2_STUB],
	[GameFlow.Phase.TITLE, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.INTRO, GameFlow.Phase.OFFER],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.OFFER],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.WORK],
	[GameFlow.Phase.WORK, GameFlow.Phase.WORK],
	[GameFlow.Phase.LAYOFF, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.LAYOFF, GameFlow.Phase.INTERVIEW],
	[GameFlow.Phase.INTRO, GameFlow.Phase.LAYOFF],
]

## The phases a run is live in: Phase 1's hunt, and the career run's work state and layoff scene.
const LIVE: Array[int] = [GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER, GameFlow.Phase.WORK, GameFlow.Phase.LAYOFF]
const ROUTER_PATH := "res://autoload/scene_router.gd"
const FEATURES_DIR := "res://features/"


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
		var live := phase in LIVE
		assert_eq(GameFlow.is_saved(phase), live, "is_saved(%s)" % GameFlow.Phase.find_key(phase))


func test_save_deleted_on_plan_b_and_after_hired() -> void:
	assert_true(GameFlow.deletes_save(GameFlow.Phase.JOB_HUNT, GameFlow.Phase.GAME_OVER))
	assert_true(GameFlow.deletes_save(GameFlow.Phase.OFFER, GameFlow.Phase.GAME_OVER), "declined on the grace day")
	assert_true(GameFlow.deletes_save(GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE))
	assert_true(GameFlow.deletes_save(GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT))
	assert_false(GameFlow.deletes_save(GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB), "killed on the Hired card: Continue still works")
	assert_false(GameFlow.deletes_save(GameFlow.Phase.JOB_HUNT, GameFlow.Phase.TITLE), "Quit to title keeps the run")
	assert_true(GameFlow.deletes_save(GameFlow.Phase.WORK, GameFlow.Phase.GAME_OVER), "an ending deletes the career save (KILL_TESTS 11)")
	assert_false(GameFlow.deletes_save(GameFlow.Phase.WORK, GameFlow.Phase.TITLE), "Quit to title keeps the career run")
	assert_false(GameFlow.deletes_save(GameFlow.Phase.WORK, GameFlow.Phase.LAYOFF), "the layoff scene is part of the run")


## GameState counts a finished run (settings meta run_count) exactly when change_phase() deletes the
## save. Replays the ROADMAP Step 6 kill test: Accept -> Hired card -> app killed (the last save is
## from OFFER) -> Continue -> the offer -> Accept -> New run. The run counts once, not on each Accept.
func test_a_hired_kill_counts_the_run_once() -> void:
	var paths: Dictionary = {
		"hired, killed, resumed, accepted again, New run": [
			[GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB], [GameFlow.Phase.TITLE, GameFlow.Phase.OFFER],
			[GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB], [GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT]],
		"hired, Title": [[GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB], [GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE]],
		"Plan B, Retry": [[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.GAME_OVER], [GameFlow.Phase.GAME_OVER, GameFlow.Phase.BACKGROUND_SELECT]],
		"grace-day Decline, Title": [[GameFlow.Phase.OFFER, GameFlow.Phase.GAME_OVER], [GameFlow.Phase.GAME_OVER, GameFlow.Phase.TITLE]],
	}
	for name: String in paths:
		var counted := 0
		for step: Array in paths[name]:
			assert_true(GameFlow.can_transition(step[0], step[1]), "%s: legal step" % name)
			if GameFlow.deletes_save(step[0], step[1]):
				counted += 1
		assert_eq(counted, 1, "%s: the run counts once" % name)
	assert_true(GameFlow.can_resume(GameFlow.Phase.OFFER), "Continue after a kill on the Hired card")


## The count lives in one place, next to the save deletion (read as text: tests never load autoloads).
func test_run_count_moves_only_with_the_save_deletion() -> void:
	var src := FileAccess.get_file_as_string("res://autoload/game_state.gd")
	assert_eq(RegEx.create_from_string("\\n\\s+_count_finished_run\\(\\)").search_all(src).size(), 1,
		"game_state.gd calls _count_finished_run() once")
	assert_true(RegEx.create_from_string(
		"if GameFlow\\.deletes_save\\(from, to\\):[^\\n]*\\n\\s+SaveIO\\.delete\\(\\)\\n\\s+_count_finished_run\\(\\)").search(src) != null,
		"right after change_phase() deletes the save")


func test_continue_only_resumes_live_runs() -> void:
	for phase: int in GameFlow.Phase.values():
		var live := phase in LIVE
		assert_eq(GameFlow.can_resume(phase), live, "can_resume(%s)" % GameFlow.Phase.find_key(phase))


func test_fresh_run_state_is_empty() -> void:  # retry() builds exactly this
	var r := RunState.new()
	assert_eq(r.phase, GameFlow.Phase.TITLE)
	assert_eq(r.day, 1)
	assert_eq(r.pity_count, 0)
	assert_true(r.applied.is_empty() and r.applications.is_empty() and r.blacklist.is_empty())
	assert_true(r.interview.is_empty() and r.offer.is_empty())


## SceneRouter.SCENES names one existing screen per phase, and every screen answers Back
## (ARCHITECTURE 5, 9). The router is read as text: tests never load autoload scripts.
func test_every_phase_has_a_screen_with_handle_back() -> void:
	var paths: Array[String] = []
	var regex := RegEx.create_from_string("\"(res://features/[^\"]+\\.tscn)\"")
	for m: RegExMatch in regex.search_all(FileAccess.get_file_as_string(ROUTER_PATH)):
		paths.append(m.get_string(1))
	assert_eq(paths.size(), GameFlow.Phase.size(), "SceneRouter.SCENES has one scene per phase")
	for path: String in paths:
		assert_true(ResourceLoader.exists(path), "%s exists" % path)
		var script_path := path.get_basename() + ".gd"
		assert_true(FileAccess.get_file_as_string(script_path).contains("func handle_back() -> bool:"),
			"%s implements handle_back()" % script_path)


## INV-01 / INV-02: screens only call GameState verbs. They never set the phase, call
## change_phase() or swap scenes; SceneRouter does that.
func test_screens_never_change_phase_or_scene() -> void:
	var scripts := _scripts_under(FEATURES_DIR)
	assert_gt(scripts.size(), GameFlow.Phase.size() - 1, "every screen has a script")
	var sets_phase := RegEx.create_from_string("\\.phase\\s*=[^=]")
	for path: String in scripts:
		var src := FileAccess.get_file_as_string(path)
		assert_false(src.contains("change_scene"), "%s calls change_scene_*()" % path)
		assert_false(src.contains("change_phase("), "%s calls change_phase()" % path)
		assert_true(sets_phase.search(src) == null, "%s assigns a phase" % path)


static func _scripts_under(dir: String) -> Array[String]:
	var out: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		out.append_array(_scripts_under(dir.path_join(sub)))
	return out
```

`test_save.gd`:

```gdscript
@tool
extends McpTestSuite
## RunState <-> JSON round trip (GDD 5.11). Never writes to user:// (in the editor that is the real save folder).

## RunState fields removed by DECISIONS D9 (lying and the CV screen).
const REMOVED_KEYS: PackedStringArray = ["lies_carried", "confessed", "cv_levels", "rescinded"]


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
	r.applications.append({"uid": 7, "tier": "mid", "reveal_day": 3, "p": 0.168, "knockout": false})
	r.interview = {"seed": "3141592653", "question_ids": ["kq_hash_map", "kq_left_join"]}
	var back := _round_trip(r)
	assert_eq(back.phase, GameFlow.Phase.INTERVIEW)
	assert_eq(back.background_id, "self_taught")
	assert_eq(back.stats["knw"], 60)
	assert_eq(back.gap_topics, r.gap_topics)
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


## DECISIONS D9 (2026-09-29): a save written before lying and the CV screen were removed still loads.
## Keys the RunState no longer has are ignored, and the next save drops them; an old checkpoint's
## probe_line is never read (its knowledge prompt 2 is asked).
func test_a_save_from_before_d9_still_loads() -> void:
	var old := RunState.new().to_dict()
	old["phase"] = GameFlow.Phase.INTERVIEW
	old["lies_carried"] = ["cv_intern_edu_lie"]
	old["confessed"] = ["co_nimbus|cv_intern_edu_lie"]
	old["cv_levels"] = {"edu": "lie", "exp": "polished", "proj": "honest"}
	old["rescinded"] = {"company_id": "co_nimbus", "template_id": "job_big_ai_engineer", "tier": "big", "mail_id": "mail_rescinded"}
	old["applications"] = [{"uid": 3, "tier": "big", "lies": ["cv_intern_edu_lie"], "status": "interview"}]
	old["interview"] = {"seed": "42", "question_ids": ["eq_a", "kq_1", "kq_2", "kq_3", "eq_b"],
		"warmup_id": "", "probe_line": "cv_intern_edu_lie"}
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(old)))
	assert_eq(back.phase, GameFlow.Phase.INTERVIEW)
	assert_eq(back.interview["question_ids"].size(), 5, "the checkpoint's 5 questions")
	assert_eq(back.applications[0]["status"], "interview")
	var saved := back.to_dict()
	for key: String in REMOVED_KEYS:
		assert_false(saved.has(key), "%s is dropped by the next save" % key)


## The career run shares the slot with Phase 1's save (ARCHITECTURE 19.4): version 2 with a sim is a career save, anything
## else that parses is a hunt save, and nothing is nothing. Pure string work: no file is written.
func test_the_slot_tells_hunt_and_career_saves_apart() -> void:
	assert_eq(SaveIO.kind_of({}), SaveIO.KIND_NONE)
	assert_eq(SaveIO.kind_of(RunState.new().to_dict()), SaveIO.KIND_HUNT, "Phase 1's save has no sim")
	assert_eq(SaveIO.kind_of({"version": 1, "phase": 3}), SaveIO.KIND_HUNT)
	assert_eq(SaveIO.kind_of({"version": 2, "phase": 8}), SaveIO.KIND_HUNT, "version 2 without a sim is not a career save")
	assert_eq(SaveIO.kind_of({"version": 2, "phase": 8, "sim": {}}), SaveIO.KIND_CAREER)
	var text := SaveIO.encode({"version": 2, "phase": 8, "sim": {"day": 5}})
	assert_eq(SaveIO.kind_of(SaveIO.decode(text)), SaveIO.KIND_CAREER, "through JSON and back")
	assert_eq(SaveIO.decode("{ this is not json"), {}, "garbage reads as no save")
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
## GDD 5.8.7 worked example (Intern vs Dana at Hierarchai) with the luck values fixed, plus Tired.

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
## GDD 5.9: salary, Dream vs Reality examples; the whole offer RunState.make_offer builds
## from the interview checkpoint (S10), its tip, the grace-day Decline, and the Accept that a kill on
## the Hired card replays (5.11). Pure: tiers and backgrounds from the .tres, the JSON read with
## FileAccess, saves through JSON strings, never user:// or an autoload (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
## One posting and one MVP company per tier (CONTENT.md 4, 5).
const POSTING := {"startup": "job_st_mobile_barista", "mid": "job_mid_backend", "big": "job_big_junior_swe"}
const COMPANY := {"startup": "co_synergai", "mid": "co_beigeware", "big": "co_nimbus"}

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "offer"


func suite_setup(_ctx: Dictionary) -> void:
	for id: String in TIER_IDS:
		tiers[id] = load("res://data/tiers/%s.tres" % id)
	for id: String in ["intern", "graduate", "self_taught"]:
		bgs[id] = load("res://data/backgrounds/%s.tres" % id)
	for file: String in ["postings", "companies", "cv_lines", "emails"]:
		content[file] = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/%s.json" % file))


func setup() -> void:
	cfg = BalanceConfig.new()


## A run of this background with a won interview's checkpoint at a tier (seed as start_interview
## writes it: a String).
func _won(bg_id: String, tier_id: String, interview_seed: String) -> RunState:
	var run := RunState.new()
	run.set_background(cfg, bgs[bg_id])
	run.interview = {
		"invite_uid": 5, "company_id": COMPANY[tier_id], "template_id": POSTING[tier_id], "tier": tier_id,
		"seed": interview_seed, "question_ids": [], "warmup_id": "", "tired": false,
	}
	return run


func _offer(bg_id: String, tier_id: String, interview_seed: String, composure: float = 80.0) -> Dictionary:
	var run := _won(bg_id, tier_id, interview_seed)
	return run.make_offer(cfg, tiers[tier_id], bgs[bg_id], content, composure)


func _tiers_of(id: String) -> Array:
	return ((content["emails"] as Dictionary)[id] as Dictionary).get("tiers", [])


## Every value, however deep, is plain JSON-able data: no Object, no StringName (INV-07).
func _assert_plain(value: Variant, where: String) -> void:
	match typeof(value):
		TYPE_DICTIONARY:
			for key: Variant in value:
				assert_eq(typeof(key), TYPE_STRING, "%s: key %s is a String" % [where, key])
				_assert_plain(value[key], "%s.%s" % [where, key])
		TYPE_ARRAY:
			for item: Variant in value:
				_assert_plain(item, where + "[]")
		_:
			assert_true(typeof(value) in [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL],
				"%s is plain data (type %d)" % [where, typeof(value)])


func test_salary_example() -> void:
	var startup := TierData.new()
	startup.salary_min_k = 50
	startup.salary_max_k = 70
	var intern := BackgroundData.new()
	intern.salary_mult = 1.10
	assert_eq(Odds.offer_salary(cfg, startup, intern, 96.925, 100.0), 71000)


func test_dream_score_examples() -> void:
	assert_eq(Odds.dream_score(cfg, 71000, 0, 20, 2, 13, 15), 68, "Intern at Hierarchai")
	assert_eq(Odds.dream_score(cfg, 126000, 4, 20, 2, 11, 15), 57, "Intern at OmniGlobal")
	assert_eq(Odds.dream_score(cfg, 72000, 2, 95, 1, 5, 12), 49, "Self-Taught at Beigeware")


## GDD S10 / 5.9: a Mid offer for the Graduate holds every contract field, as plain data.
func test_make_offer_builds_the_whole_contract() -> void:
	var run := _won("graduate", "mid", "123456789")
	var made := run.make_offer(cfg, tiers["mid"], bgs["graduate"], content, 80.0)
	assert_eq(made, run.offer, "returns a copy of run.offer")
	assert_eq(made["company_id"], "co_beigeware")
	assert_eq(made["template_id"], "job_mid_backend")
	assert_eq(made["tier"], "mid")
	assert_eq(made["job_title"], "Backend Developer", "the posting's title")
	assert_eq(made["salary"], Odds.offer_salary(cfg, tiers["mid"], bgs["graduate"], 80.0, 100.0), "GDD 5.9.2")
	assert_eq(made["salary"], 81000, "65k-90k at band 0.65 = 81,250, x1.00, rounded to $1,000")
	assert_eq(made["work_mode"], "offer_mode_mid")
	assert_eq(made["office_days"], 2)
	assert_eq(made["commute"], {"id": "offer_commute_office",
		"args": {"office_days": 2, "commute_min": 45, "hours": "3.0"}}, "the Graduate's 45 minutes")
	assert_eq((made["perks"] as Array).size(), RunState.OFFER_PERKS)
	assert_true(str(made["fine_print"]).begins_with("fp_"), "one fine-print id")
	assert_eq(made["equity_text"], "", "no equity off startups")
	_assert_plain(made, "offer")


## Two different perks and one fine print, all listed for the offer's tier (CONTENT.md 13.2-13.3).
func test_perks_and_fine_print_match_the_tier() -> void:
	for tier_id: String in TIER_IDS:
		for i: int in 25:
			var made := _offer("intern", tier_id, str(1000 + i * 7919))
			var perks: Array = made["perks"]
			assert_eq(perks.size(), 2, "%s: 2 perks" % tier_id)
			assert_ne(perks[0], perks[1], "%s: 2 different perks" % tier_id)
			for perk: Variant in perks:
				assert_true(str(perk).begins_with("perk_") and _tiers_of(str(perk)).has(tier_id),
					"%s: %s is a %s perk" % [tier_id, perk, tier_id])
			var fine := str(made["fine_print"])
			assert_true(fine.begins_with("fp_") and _tiers_of(fine).has(tier_id),
				"%s: %s is %s fine print" % [tier_id, fine, tier_id])


## REVIEW_QUEUE 3: the fine print never repeats a dealt perk (fp_<x> vs perk_<x>), so a startup
## paper never lists "Unlimited PTO*" as both a perk and the fine print.
func test_fine_print_never_repeats_a_perk() -> void:
	var emails: Dictionary = content["emails"]
	assert_true(emails.has("perk_unlimited_pto") and emails.has("fp_unlimited_pto"), "the pair this guards")
	assert_false(RunState.fine_print_pool(emails, "startup", ["perk_unlimited_pto", "perk_pingpong"]).has("fp_unlimited_pto"),
		"left out when its perk is dealt")
	assert_true(RunState.fine_print_pool(emails, "startup", ["perk_kombucha", "perk_pingpong"]).has("fp_unlimited_pto"),
		"still dealt when its perk is not")
	var problems: Array[String] = []
	var pto_papers := 0
	for i: int in 200:
		var made := _offer("intern", "startup", str(i * 7919 + 3))
		var perks: Array = made["perks"]
		if perks.has("perk_unlimited_pto"):
			pto_papers += 1
		if perks.has("perk_" + str(made["fine_print"]).trim_prefix("fp_")):
			problems.append("seed %d: %s with %s" % [i, made["fine_print"], perks])
	assert_gt(pto_papers, 0, "some papers dealt the PTO perk")
	assert_true(problems.is_empty(), "%d paper(s) repeat a perk:\n  %s" % [problems.size(), "\n  ".join(PackedStringArray(problems))])


## The contract is picked on an RNG seeded from the checkpoint: the same interview (a resume replays
## it) gives the same contract, different interviews vary, and no other RNG is involved.
func test_same_checkpoint_same_contract() -> void:
	for tier_id: String in TIER_IDS:
		assert_eq(_offer("graduate", tier_id, "987654321"), _offer("graduate", tier_id, "987654321"),
			"%s: rebuilt from the same checkpoint" % tier_id)
	var seen: Dictionary = {}
	for i: int in 30:
		var made := _offer("graduate", "big", str(i * 104729 + 1))
		seen[str(made["perks"]) + str(made["fine_print"])] = true
	assert_gt(seen.size(), 3, "30 interviews do not all get the same perks and fine print")
	var a := RunState.offer_rng("42")
	var b := RunState.offer_rng("42")
	assert_eq([a.randi(), a.randi()], [b.randi(), b.randi()], "offer_rng is deterministic")
	var iv := InterviewPlan.interview_rng("42")
	assert_ne(RunState.offer_rng("42").seed, iv.seed, "the offer's dice are not the interview's")


## GDD 7 and S10: a startup offer is fully remote (the remote commute line) and carries the joke equity.
func test_startup_offer_is_remote_with_equity() -> void:
	var made := _offer("intern", "startup", "31337", 96.925)
	assert_eq(made["job_title"], "Mobile Dev (Also Barista)")
	assert_eq(made["salary"], 71000, "GDD 5.9.2 example: $71,000 at Hierarchai")
	assert_eq(made["work_mode"], "offer_mode_startup")
	assert_eq(made["office_days"], 0)
	assert_eq(made["commute"], {"id": "offer_commute_remote", "args": {}})
	assert_eq(made["equity_text"], "offer_equity")
	var big := _offer("self_taught", "big", "31337")
	assert_eq(big["commute"]["args"], {"office_days": 4, "commute_min": 95, "hours": "12.7"},
		"GDD S10: 4 days x 95 min each way = 12.7 h a week")
	assert_eq(big["equity_text"], "")


## GDD S10: values wrap at 28 columns after the 12-column labels, the fine print in 4 lines at most,
## and the whole paper stays about 250 px tall (20 lines of 12 px + the panel's 14 px) at every tier.
func test_contract_fits_the_paper() -> void:
	var emails: Dictionary = content["emails"]
	var value_columns := 40 - 12
	for id: String in emails:
		if id.begins_with("fp_"):
			assert_true(UiText.word_wrap(str(emails[id]["text"]), value_columns).size() <= 4, "%s: 4 lines at most" % id)
		elif id.begins_with("perk_"):
			assert_true(UiText.word_wrap(str(emails[id]["text"]), value_columns).size() <= 2, "%s: 2 lines at most" % id)
	var companies: Dictionary = content["companies"]
	var postings: Dictionary = content["postings"]
	for tier_id: String in TIER_IDS:
		var title_lines := 0
		for company: String in companies:
			if str(companies[company]["tier"]) == tier_id:
				var title := str(emails["offer_title"]).format({"company": companies[company]["name"]})
				title_lines = maxi(title_lines, UiText.word_wrap(title, 40).size())
		var role_lines := 0
		for posting: String in postings:
			if postings[posting] is Dictionary and str(postings[posting]["tier"]) == tier_id:
				var role := str(emails["offer_role"]).format({"job_title": postings[posting]["title"]})
				role_lines = maxi(role_lines, UiText.word_wrap(role, 40).size())
		var perk_lines: Array[int] = []
		var fine_lines := 0
		for id: String in emails:
			if id.begins_with("perk_") and _tiers_of(id).has(tier_id):
				perk_lines.append(UiText.word_wrap(str(emails[id]["text"]), value_columns).size())
			elif id.begins_with("fp_") and _tiers_of(id).has(tier_id):
				fine_lines = maxi(fine_lines, UiText.word_wrap(str(emails[id]["text"]), value_columns).size())
		perk_lines.sort()
		# title + Dear + role + blank + salary (+ equity) + work mode + commute (2) + 2 perks + fine print + deadline
		var lines := title_lines + 1 + role_lines + 1 + 1 + (1 if tier_id == "startup" else 0) + 1 + 2 \
			+ perk_lines[-1] + perk_lines[-2] + fine_lines + 1
		assert_true(lines <= 20, "%s: the longest contract has %d lines" % [tier_id, lines])


func test_commute_hours() -> void:
	assert_eq(RunState.offer_commute(4, 95)["args"]["hours"], "12.7", "Self-Taught at a big corp")
	assert_eq(RunState.offer_commute(4, 20)["args"]["hours"], "2.7", "Intern at a big corp")
	assert_eq(RunState.offer_commute(2, 20)["args"]["hours"], "1.3", "Intern at a mid-size")
	assert_eq(RunState.offer_commute(0, 95)["id"], "offer_commute_remote", "no office days: remote")


func test_offer_survives_the_save() -> void:
	var run := _won("self_taught", "startup", "555")
	run.make_offer(cfg, tiers["startup"], bgs["self_taught"], content, 45.5)
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(back.offer, run.offer, "the whole contract round-trips")
	assert_eq(typeof(back.offer["salary"]), TYPE_INT, "the salary comes back as an int")
	assert_eq(typeof(back.offer["commute"]["args"]), TYPE_DICTIONARY)


## GDD 8.1 rule 2, 8.3: one tip on the offer. Startups: the equity lottery; others: total comp.
func test_offer_tip() -> void:
	for tier_id: String in TIER_IDS:
		var run := _won("graduate", tier_id, "77")
		run.make_offer(cfg, tiers[tier_id], bgs["graduate"], content, 60.0)
		assert_eq(HuntTips.offer(run), "tip_equity_lottery" if tier_id == "startup" else "tip_total_comp", tier_id)


## GDD 5.10: Decline is Plan B only on the grace day (rent at 0).
func test_decline_ends_the_run_only_at_zero_rent() -> void:
	var run := RunState.new()
	run.rent_days_left = 0
	assert_true(run.decline_ends_run(), "grace day: Decline ends the run")
	run.rent_days_left = 1
	assert_false(run.decline_ends_run(), "rent left: back to the hunt")


## GDD 5.11: a kill on the Hired card resumes at the offer (its save was written on entering OFFER,
## PHASE2_STUB is never saved). Accepting again hires with the same contract and the same Dream
## score (D9: no background check; hire() takes no RNG, so Accept cannot roll dice).
func test_accept_after_a_hired_kill_hires_the_same_job() -> void:
	for seed_value: int in range(1, 41):
		var run := _won("intern", "big", str(seed_value * 31))
		run.make_offer(cfg, tiers["big"], bgs["intern"], content, 70.0)
		run.interview = {}
		run.phase = GameFlow.Phase.OFFER
		var saved := JSON.stringify(run.to_dict())
		var flags: Array = content["companies"][COMPANY["big"]]["red_flags"]
		run.hire(cfg, bgs["intern"], flags)
		var back := RunState.from_dict(JSON.parse_string(saved))
		assert_eq(back.phase, GameFlow.Phase.OFFER, "Continue resumes at the offer")
		assert_eq(back.offer, run.offer, "the same contract")
		back.hire(cfg, bgs["intern"], flags)
		assert_eq(back.employment, run.employment, "seed %d: the same job" % seed_value)
		assert_eq(back.dream_score, run.dream_score, "seed %d: the same Dream score" % seed_value)
```

### 17.14 `core/interview_plan.gd` (Step 4)

Which questions one interview asks (GDD 5.8.2), the prompts a checkpoint plays, the interview and meter RNGs, and since the Step 7 review Dana's VS plate (`vs_plate`); the probe question went with D9. `GameState.start_interview()`, the interview scene and `VersusIntro` call it; `test_interview_plan` tests it.

```gdscript
@tool
class_name InterviewPlan
extends RefCounted
## Which questions one interview asks (GDD 5.8.2). GameState.start_interview picks them once and
## freezes them in the checkpoint, so a resume replays the same interview. Pure: the pools are
## parsed JSON (id -> entry), from Content.entries() in the game and from FileAccess in the tests.
## Tested by test_interview_plan (picking, the prompts and the dice a checkpoint replays, the VS plate).

## GDD S07: Dana's VS plate shows one joke stat and one special move (barks.json ids), in turn.
const VS_DANA_STATS: PackedStringArray = ["vs_dana_stat_1", "vs_dana_stat_2", "vs_dana_stat_3"]
const VS_DANA_MOVES: PackedStringArray = ["vs_dana_move_1", "vs_dana_move_2", "vs_dana_move_3"]


## GDD 5.8.2: the warm-up belongs to the first interview of the first run only.
static func warmup_due(run: RunState) -> bool:
	return run.first_run and run.interviews_taken == 0


## Dana's VS plate for this interview: {stat, move}, barks.json ids. Each list takes turns by how often
## you met her before (run.times_met_dana counts once an interview ends), without dice (INV-04), so a
## resumed interview shows the same lines.
static func vs_plate(run: RunState) -> Dictionary:
	return {
		"stat": VS_DANA_STATS[posmod(run.times_met_dana, VS_DANA_STATS.size())],
		"move": VS_DANA_MOVES[posmod(run.times_met_dana, VS_DANA_MOVES.size())],
	}


## Returns {question_ids, warmup_id}. question_ids holds one id per cfg.prompt_pattern slot, in prompt
## order. Only the tier's questions are used, never opener_only ones, and questions in `seen` only
## once the unseen ones run out (then the least recently seen first). The warm-up is one of the
## easiest remaining knowledge questions, or "" when with_warmup is false.
static func pick(cfg: BalanceConfig, tier_id: String, choice_pool: Dictionary, knowledge_pool: Dictionary,
		seen: Array[String], rng: RandomNumberGenerator, with_warmup: bool) -> Dictionary:
	var knowledge_ids := eligible(knowledge_pool, tier_id)
	var choice_picks := _draw(rng, eligible(choice_pool, tier_id), seen, cfg.prompt_pattern.count("choice"))
	var knowledge_picks := _draw(rng, knowledge_ids, seen, cfg.prompt_pattern.count("knowledge"))
	var picks: Dictionary = {"choice": choice_picks, "knowledge": knowledge_picks}
	var question_ids: Array[String] = []
	for kind: String in cfg.prompt_pattern:
		if not picks.has(kind):
			push_error("InterviewPlan: unknown prompt kind '%s' in prompt_pattern" % kind)
		elif not (picks[kind] as Array).is_empty():
			question_ids.append((picks[kind] as Array).pop_front())
	var warmup_id := ""
	if with_warmup:
		var remaining: Array[String] = []
		for id: String in knowledge_ids:
			if not question_ids.has(id):
				remaining.append(id)
		var warmup := _draw(rng, _easiest(knowledge_pool, remaining), seen, 1)
		if not warmup.is_empty():
			warmup_id = warmup[0]
	return {"question_ids": question_ids, "warmup_id": warmup_id}


## n ids from a pool with no tiers (the review's prompts, GDD 5.16): unseen ones in an order the RNG decides, then the
## least recently asked. The ids are sorted first, so the JSON key order never decides.
static func pick_ids(pool: Dictionary, seen: Array[String], rng: RandomNumberGenerator, n: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in pool:
		if not id.begins_with("_") and pool[id] is Dictionary:
			ids.append(id)
	ids.sort()
	return _draw(rng, ids, seen, n)


## The ids of one pool that a tier can ask, sorted so the picks never depend on the JSON key order.
static func eligible(pool: Dictionary, tier_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in pool:
		if id.begins_with("_") or not (pool[id] is Dictionary):  # "_" keys are metadata (ARCHITECTURE 6.3)
			continue
		var entry: Dictionary = pool[id]
		var tiers: Array = entry.get("tiers", [])
		if tiers.has(tier_id) and not bool(entry.get("opener_only", false)):
			ids.append(id)
	ids.sort()
	return ids


## The prompts a checkpoint plays, in order: one {kind, id} per question id, kind "choice" or
## "knowledge" (an old save's probe_line is never read: its knowledge prompt 2 is asked, DECISIONS D9).
static func prompts(question_ids: Array, choice_pool: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: Variant in question_ids:
		out.append({"kind": "choice" if choice_pool.has(str(id)) else "knowledge", "id": str(id)})
	return out


## The interview RNG (ARCHITECTURE 7.2): a fresh generator seeded from the checkpoint's seed, a
## String because 64-bit values don't survive JSON as numbers. The same seed replays the same dice.
static func interview_rng(seed_text: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_text.to_int()
	return rng


## A generator of its own for one Answer Meter (zone centre, pivot time, the pivot's new centre),
## seeded from exactly one roll of the interview RNG. The pivot rolls only if you tap after it, so
## on the interview RNG itself it would shift every later roll; this way a resume replays the later
## prompts' luck however early you tap (GDD 5.11).
static func meter_rng(interview: RandomNumberGenerator) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = interview.randi()
	return rng


## Moves each asked id to the end of `seen`, so `seen` stays ordered from least to most recently asked.
static func mark_seen(seen: Array[String], ids: Array) -> void:
	for id: String in ids:
		if id != "":
			seen.erase(id)
			seen.append(id)


## n ids: unseen ones in an order decided by the RNG, then (a dry pool) the least recently seen.
static func _draw(rng: RandomNumberGenerator, ids: Array[String], seen: Array[String], n: int) -> Array[String]:
	var fresh: Array[String] = []
	var stale: Array[String] = []
	for id: String in ids:
		if seen.has(id):
			stale.append(id)
		else:
			fresh.append(id)
	var out: Array[String] = []
	out.assign(Odds.pick(rng, fresh, n))
	if out.size() < n:
		stale.sort_custom(func(a: String, b: String) -> bool: return seen.find(a) < seen.find(b))
		out.append_array(stale.slice(0, n - out.size()))
	return out


static func _easiest(pool: Dictionary, ids: Array[String]) -> Array[String]:
	var lowest := -1
	for id: String in ids:
		var difficulty := int((pool[id] as Dictionary).get("difficulty", 0))
		if lowest < 0 or difficulty < lowest:
			lowest = difficulty
	var out: Array[String] = []
	for id: String in ids:
		if int((pool[id] as Dictionary).get("difficulty", 0)) == lowest:
			out.append(id)
	return out
```

### 17.15 `ui/components/ui_text.gd` (Step 4)

Pure string styling for labels and money (GDD 4.2 mockups): capitals on primary buttons, the "< " Back prefix, energy costs, text meters and odds bands, thousands separators; since Step 6 also word wrap as the content lint counts lines, and the offer contract's label column; since the Step 7 review `fill`, which `Content` uses to fill placeholders without doubling a period. A pure UI helper, not a rule class: scenes pass it text from `Content`. `test_ui_text` tests it.

```gdscript
@tool
class_name UiText
extends RefCounted
## How labels and money look on screen (GDD 4.2 mockups). Pure string helpers: scenes pass in text
## from Content.text(), so the words stay in the JSON (INV-15) and only the styling lives here.
## Agent default, please review (Step 4): CONTENT.md keeps each label in its normal case, and a
## PrimaryButton shows it in capitals, as the mockups do ([ CONTINUE ], [ NEW RUN ]). To drop the
## capitals, make primary() return its text unchanged.

const BACK_ARROW := "< "  # stands in for the back-arrow icon until the art pass


## Label for a PrimaryButton: "Continue" -> "CONTINUE".
static func primary(text: String) -> String:
	return text.to_upper()


## Label for the action bar's bottom-left Back slot: "Back" -> "< Back", "Title" -> "< Title".
static func back(text: String) -> String:
	return BACK_ARROW + text


## A button that costs energy shows the pips after its label, as the GDD S04 mockup does:
## ("APPLY", 1) -> "APPLY  1", ("TAILOR & APPLY", 2) -> "TAILOR & APPLY  2".
static func cost(text: String, pips: int) -> String:
	return "%s  %d" % [text, pips]


## A text meter, filled from the left: (3, 5) -> "[###--]". The Recruiter Radar and the odds bands.
static func meter(filled: int, total: int) -> String:
	var dots := clampi(filled, 0, maxi(total, 0))
	return "[%s%s]" % ["#".repeat(dots), "-".repeat(maxi(total, 0) - dots)]


## An odds band as dots plus a word (GDD 2.7, 5.6): band 3 of 5, "Possible" -> "[###--] Possible".
static func band(filled: int, word: String, total: int = 5) -> String:
	return "%s %s" % [meter(filled, total), word]


## A whole number with thousands separators: 1247 -> "1,247" (the card back's applicants).
static func count(amount: int) -> String:
	var digits := str(absi(amount))
	var groups := ""
	while digits.length() > 3:
		groups = "," + digits.right(3) + groups
		digits = digits.left(-3)
	return ("-" if amount < 0 else "") + digits + groups


## Whole dollars as the offer letter shows them: 71000 -> "$71,000".
static func money(amount: int) -> String:
	var grouped := count(absi(amount))
	return ("-" if amount < 0 else "") + "$" + grouped


## Thousands of in-game dollars (k$, GDD 5.15) with two decimals: 2.55 -> "$2.55k", -0.4 -> "-$0.40k".
static func money_k(amount: float) -> String:
	return ("-" if amount < -0.004 else "") + "$%.2fk" % absf(amount)


## Content text with its {placeholders} filled (String.format), except that a value ending in "."
## swallows a "." right after its placeholder, so a name that ends a sentence never doubles it:
## ("Welcome to {company}. Hi.", {"company": "Engagement Farms Inc."}) -> "Welcome to Engagement
## Farms Inc. Hi.". An ellipsis after a placeholder keeps its three dots.
static func fill(template: String, args: Dictionary) -> String:
	for key: Variant in args:
		if str(args[key]).ends_with("."):
			var tag := "{%s}" % key
			template = template.replace(tag + ".", tag)
	return template.format(args)


## Word wrap as an autowrapped Label does it, and as test_content_lint counts lines: a word moves to
## the next line when it would pass `columns`, a word longer than a whole line is cut, "\n" starts a
## line. monogram is monospaced, so columns are exact.
static func word_wrap(text: String, columns: int) -> PackedStringArray:
	var out := PackedStringArray()
	for paragraph: String in text.split("\n"):
		var line := ""
		for word: String in paragraph.split(" ", false):
			if line.is_empty():
				line = word
			elif line.length() + 1 + word.length() <= columns:
				line += " " + word
			else:
				out.append(line)
				line = word
			while line.length() > columns:
				out.append(line.left(columns))
				line = line.substr(columns)
		out.append(line)
	return out


## One field of the offer contract (GDD S10): the label in a column label_columns wide, the value
## wrapped in the columns left of the line, its wrapped lines indented under the first. An empty label
## continues the field above. ("Perks:", "Kombucha on tap", 12, 40) -> ["Perks:      Kombucha on tap"].
static func field(label: String, value: String, label_columns: int, columns: int) -> PackedStringArray:
	var out := PackedStringArray()
	var lines := word_wrap(value, columns - label_columns)
	for i: int in lines.size():
		out.append((label.rpad(label_columns) if i == 0 else " ".repeat(label_columns)) + lines[i])
	return out
```

### 17.16 `core/hunt_tips.gd` (Step 5)

Which Ducky tip the job hunt shows, and when (GDD 8.3); since Step 6 also the offer's tip and the Plan B card's; since the Step 7 review also the first-run coach marks (`coach`, `coach_invite`). Pure: it only reads the run; the hub records a once-per-run tip with `GameState.mark_tip_shown()` and a closed coach mark with `GameState.close_coach_mark()`. `test_hunt_tips` tests it, and `test_offer` / `test_endings` test `offer` and `plan_b`.

```gdscript
@tool
class_name HuntTips
extends RefCounted
## Which Ducky tip the job hunt shows, and when (GDD 8.3). A tip waits for a natural pause (8.1 rule 3):
## the night summary, the morning inbox, Study, and the offer that ends the hunt. Also the first run's
## coach marks (GDD 4.3).
## Pure: it only reads the run.
## GameState.mark_tip_shown() records a once-per-run tip in run.tips_shown; GameState.close_coach_mark()
## records a coach mark tapped closed in run.coach_closed.

const SPRAY_QUICK_APPLIES := 8   # GDD 8.3: "8 Quick Applies without an invite"
const REJECTION_TIP_EVERY := 10  # GDD 8.3: "first rejection email / every 10th rejection"
const COACH_SLEEP_PIPS := 2      # GDD 4.3: the Sleep coach mark at 2 energy or less...
const COACH_SLEEP_APPS := 4      # ...or after 4 applications
const COACH_INVITE := "coach_invite"  # the invite's mark, whichever line Ducky says (Research is SHOULD)
## An application only reaches these statuses after an invite arrived for it.
const INVITED_STATUSES: PackedStringArray = ["invited", "interview", "expired"]


## Mail's one tip (GDD S06, 8.1 rule 2, 8.3), under the rejection stack: the run's first knockout
## rejection -> tip_ats_knockouts; else its first rejection, or every 10th -> tip_rejection_numbers;
## "" for none. The run is read after the Sleep that built the report (its rejections are counted),
## so one report gives the same tip in the morning and in Mail later that day.
static func inbox(run: RunState, report: Dictionary) -> String:
	var rejections: Array = report.get("rejections", [])
	if rejections.is_empty():
		return ""
	var knockouts_now := 0
	for rejection: Variant in rejections:
		if rejection is Dictionary and not ((rejection as Dictionary).get("knockout", {}) as Dictionary).is_empty():
			knockouts_now += 1
	if knockouts_now > 0 and _knockout_rejections(run) == knockouts_now:
		return "tip_ats_knockouts"
	var after := run.total_rejections
	var before := after - rejections.size()
	var last_multiple := after - posmod(after, REJECTION_TIP_EVERY)
	if before <= 0 or (last_multiple >= REJECTION_TIP_EVERY and last_multiple > before):
		return "tip_rejection_numbers"
	return ""


## Tonight's tip on the lock screen, each once per run: the first referral used -> tip_referrals;
## 8 Quick Applies without an invite -> tip_tailor_over_spray; after a Tailor & Apply (every line sent
## as its honest Polished reframing) -> tip_projects_count when bg's honest CV fails "1+ years"
## (years_pass_honest: the Graduate, the Self-Taught), then tip_quantify_impact. "" for none.
static func night(run: RunState, bg: BackgroundData = null) -> String:
	if not run.tips_shown.has("tip_referrals"):
		for app: Dictionary in run.applications:
			if bool(app.get("referral", false)):
				return "tip_referrals"
	if not run.tips_shown.has("tip_tailor_over_spray") and not had_invite(run):
		var quick := 0
		for app: Dictionary in run.applications:
			if not bool(app.get("tailored", false)):
				quick += 1
		if quick >= SPRAY_QUICK_APPLIES:
			return "tip_tailor_over_spray"
	if _any_tailored(run):
		if bg != null and not bg.years_pass_honest and not run.tips_shown.has("tip_projects_count"):
			return "tip_projects_count"
		if not run.tips_shown.has("tip_quantify_impact"):
			return "tip_quantify_impact"
	return ""


## After a Study action: the first one this run -> tip_fundamentals (GDD 8.3).
static func studied(run: RunState) -> String:
	return "" if run.tips_shown.has("tip_fundamentals") else "tip_fundamentals"


## The Jobs screen's coach mark on day 1 of the first run (GDD 4.3): "coach_sleep" at COACH_SLEEP_PIPS
## energy or less or after COACH_SLEEP_APPS applications (over the empty deck too); else, with a card
## up, "coach_apply" until the first application, then "coach_flip" until a card was flipped (flipped)
## or tailored; "" for none, and never over the card's back. Each goes away when you do what it asks.
## One tapped closed (run.coach_closed) never comes back, and the mark after it still waits for its
## own rule: closing Apply doesn't bring Flip early.
static func coach(run: RunState, has_card: bool, card_back: bool, flipped: bool) -> String:
	if not run.first_run or run.day != 1 or (has_card and card_back):
		return ""
	var id := ""
	if run.energy <= COACH_SLEEP_PIPS or run.total_applications >= COACH_SLEEP_APPS:
		id = "coach_sleep"
	elif has_card and run.total_applications == 0:
		id = "coach_apply"
	elif has_card and not flipped and not _any_tailored(run):
		id = "coach_flip"
	return "" if run.coach_closed.has(id) else id


## Mail's coach mark (GDD 4.3 "Day 2 morning"): the first run's invites point at their GO NOW until the
## first interview, unless it was tapped closed.
static func coach_invite(run: RunState) -> bool:
	return run.first_run and run.interviews_taken == 0 and run.interview.is_empty() and not run.invites.is_empty() \
		and not run.coach_closed.has(COACH_INVITE)


## The offer's one tip (GDD S10, 8.1 rule 2, 8.3): a startup offer, which carries the joke equity ->
## tip_equity_lottery; any other -> tip_total_comp (its trigger: an offer with a commute).
static func offer(run: RunState) -> String:
	return "tip_equity_lottery" if str(run.offer.get("equity_text", "")) != "" else "tip_total_comp"


## The Plan B card's one tip (GDD S12, 8.1 rule 4: it matches the cause). No invite all run: nobody
## replied, and tailoring is what gets replies -> tip_tailor_over_spray. Invites but no job ->
## tip_rejection_numbers (many rejections are normal; keep going).
static func plan_b(run: RunState) -> String:
	return "tip_rejection_numbers" if had_invite(run) else "tip_tailor_over_spray"


## An invite arrived this run: one is waiting, an application got one (invited, taken or expired),
## or an interview was taken or is under way (a "saw your profile" invite has no application).
static func had_invite(run: RunState) -> bool:
	if not run.invites.is_empty() or run.interviews_taken > 0 or not run.interview.is_empty():
		return true
	for app: Dictionary in run.applications:
		if INVITED_STATUSES.has(str(app.get("status", ""))):
			return true
	return false


static func _knockout_rejections(run: RunState) -> int:
	var count := 0
	for app: Dictionary in run.applications:
		if str(app.get("status", "")) == "rejected" and bool(app.get("knockout", false)):
			count += 1
	return count


static func _any_tailored(run: RunState) -> bool:
	for app: Dictionary in run.applications:
		if bool(app.get("tailored", false)):
			return true
	return false
```

### 17.17 `features/intro/cutscene_plan.gd` (Step 6)

The intro's play order from `cutscene.json` (GDD S02, section 11.2) as plain data, and where each panel's picture pans. A pure helper like `UiText`, not a rule class; it lives with the intro because nothing else uses it. `intro.gd` passes it `Content.entries("cutscene")`; `test_intro` runs it on the real file.

```gdscript
@tool
class_name CutscenePlan
extends RefCounted
## The intro's play order from cutscene.json (GDD S02, ARCHITECTURE 11.2), as plain data. Pure, like
## UiText: the intro scene passes in Content.entries("cutscene"), so tests can run it on the file itself.

const STYLE_TITLE := "title"   # a caption that renders as the title card, not in the dialogue box


## The panels in "order" (ties by id): [{id, order, seconds, captions: [{speaker, text, style}]}].
## An entry without an "order" or without a caption with text is not a panel ("_" notes, plain strings).
static func panels(entries: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: Variant in entries:
		var entry: Variant = entries[id]
		if not (entry is Dictionary) or not (entry as Dictionary).has("order"):
			continue
		var captions: Array[Dictionary] = []
		for caption: Variant in (entry as Dictionary).get("captions", []):
			if caption is Dictionary and not str((caption as Dictionary).get("text", "")).is_empty():
				captions.append({
					"speaker": str(caption.get("speaker", "")),
					"text": str(caption["text"]),
					"style": str(caption.get("style", "")),
				})
		if captions.is_empty():
			continue
		out.append({"id": str(id), "order": int(entry["order"]), "seconds": float(entry.get("seconds", 0.0)),
			"captions": captions})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["order"] < b["order"] or (a["order"] == b["order"] and a["id"] < b["id"]))
	return out


## The whole intro's pan time in seconds (GDD S02 wants 40 or less).
static func total_seconds(plan: Array[Dictionary]) -> float:
	var total := 0.0
	for panel: Dictionary in plan:
		total += float(panel["seconds"])
	return total


## Where a panel's picture sits in the frame at the start and at the end of its "seconds": a picture
## wider than the frame pans sideways across its extra width, a taller one tilts down, one the frame's
## size stays still (GDD 2.6: 270x480, up to 480x480 for a pan, 270x720 for a tilt). Whole pixels.
static func pan_path(picture: Vector2, frame: Vector2) -> Array[Vector2]:
	var extra := (picture - frame).max(Vector2.ZERO).floor()
	return [Vector2.ZERO, -extra]
```

### 17.18 The career run's sim core: `core/sim_state.gd`, `sim_context.gd`, `work_odds.gd`, `event_plan.gd`, `sim.gd` (Step 14)

`core/sim_state.gd`:

```gdscript
@tool
class_name SimState
extends RefCounted
## The whole career as plain data (INV-07, GDD 5.14, ARCHITECTURE 19.2): numbers, strings, bools, Arrays and
## Dictionaries, never a Resource or a Node. Sim.step changes it and nothing else does. Money is in k$ (GDD 5.15).
## Levels are 0 junior, 1 mid, 2 senior; homes 0 shared room to 3 penthouse (WorkOdds). to_dict and from_dict walk
## the script variables below, so a new field is saved without touching them. Seeds and the RNG state travel as
## strings (INV-05). The save of record is to_save: Godot's JSON parser does not read every double back exactly (it can be a
## unit in the last place off), and one stray digit is enough to flip a threshold days of game time later, so to_save writes
## every float as its raw 64 bits in hex and from_save restores it exactly. to_dict keeps plain floats for tests and display.

const VERSION := 1
const FLOAT_TAG := "f:"

# ---------- the run ----------
var version: int = VERSION
var rng_seed: int = 0
var rng_state: int = 0
var bg_id: String = "intern"
var run_number: int = 1
var day: int = 0
var ended: bool = false
var ending: String = ""

# ---------- money, k$ ----------
var savings: float = 0.0
var pay_accrued: float = 0.0
var below_zero_days: int = 0
var living_cost: float = 1.2
var living_mult: float = 1.0
var home: int = 0
var rent: float = 0.9
var lease_day: int = 0

# ---------- the career ----------
var level: int = 0
var jobs_held: int = 0
var employed: bool = false
var unemployed_since: int = -1
var studies_this_spell: int = 0
var gap_scar_given: bool = false
var last_study_day: int = -1

# ---------- the job ----------
var job_company: String = ""
var job_archetype: String = ""
var job_salary: float = 0.0
var job_start: int = 0
var job_remote: bool = false
var job_clauses: Array = []
var job_flags: Array = []
var commute_burnout: float = 0.0
var coworkers: Array = []
var past_coworkers: Array = []

# ---------- work stats ----------
var hours: int = 3
var burnout: float = 0.0
var mo: float = 0.0
var skill: float = 0.0
var rust: float = 0.0
var codebase: float = 0.0
var quality: int = 1

# ---------- the ticket ----------
var ticket_size: int = 1
var ticket_kind: int = 0
var ticket_progress: float = 0.0
var ticket_start: int = 0
var ticket_deadline: int = 0
var tickets_shipped: int = 0
var tickets_on_time: int = 0
var push_back_used: bool = false

# ---------- temporary effects ----------
var speed_mod: float = 1.0
var speed_mod_until: int = -1
var hours_lock_until: int = -1
var last_incident_day: int = -9999

# ---------- the review ----------
var next_review: int = -1
var on_time_since_review: int = 0
var below_streak: int = 0
var rating_streak: int = 0
var pip_end: int = -1

# ---------- Scars and the forced leave ----------
var scar_short_tenure: int = 0
var scar_burnout_history: int = 0
var scar_bad_reference: int = 0
var scar_resume_gap: int = 0
var scar_corner_cutter: int = 0
var calm_days: int = 0
var forced_leaves: int = 0
var leave_end: int = -1

# ---------- events ----------
var event_last: Dictionary = {}
var queue: Array = []
var chains: Array = []
var warn_armed: Array = [true, true, true]
var layoff_known_day: int = -1

# ---------- the job hunt ----------
var board: Array = []
var board_day: int = -9999
var next_posting_id: int = 1
var applications: Array = []
var blacklist: Array = []

# ---------- the win ----------
var studio_hold: int = 0

# ---------- the Handbook ----------
var handbook: Array = []
var tips_seen: Array = []
var h_emergency: bool = false
var h_brag: bool = false
var h_take_call: bool = false
var h_overtime: bool = false

# ---------- bookkeeping ----------
var stats: Dictionary = {}
var log: Array = []


## The item the clock is waiting on (an event card, a review, a duel, an offer...), or {} when time can run.
func pending() -> Dictionary:
	return queue[0] if not queue.is_empty() else {}


func is_waiting() -> bool:
	return not queue.is_empty()


## The floor of the job you hold, or of the next one you could take: 1 to max_jobs.
func floor_n() -> int:
	return maxi(1, jobs_held)


func has_tip(tip_id: String) -> bool:
	return handbook.has(tip_id)


## Cache the Handbook's four Edge tips as bools, so the daily formulas never search the list.
func refresh_edges() -> void:
	h_emergency = handbook.has("tip_emergency_fund")
	h_brag = handbook.has("tip_brag_doc")
	h_take_call = handbook.has("tip_take_the_call")
	h_overtime = handbook.has("tip_overtime_loan")


func bump(key: String, by: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + by


## The exact save (O8): to_dict with every float as "f:" and 16 hex digits. Only ints stay JSON numbers, so a JSON round
## trip cannot change a value.
func to_save() -> Dictionary:
	return _encode(to_dict())


static func from_save(data: Dictionary) -> SimState:
	return from_dict(_decode(data))


## The same exact encoding for any plain-data value (WorkSession's saved UI state goes through it too).
static func encode_value(v: Variant) -> Variant:
	return _encode(v)


static func decode_value(v: Variant) -> Variant:
	return _decode(v)


static func _encode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0, v)
			return FLOAT_TAG + bytes.hex_encode()
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in v:
				out.append(_encode(item))
			return out
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key: Variant in v:
				out[key] = _encode(v[key])
			return out
	return v


static func _decode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_STRING:
			var text: String = v
			if text.length() == FLOAT_TAG.length() + 16 and text.begins_with(FLOAT_TAG):
				return text.substr(FLOAT_TAG.length()).hex_decode().decode_double(0)
			return text
		TYPE_FLOAT:
			return int(v)
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in v:
				out.append(_decode(item))
			return out
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key: Variant in v:
				out[key] = _decode(v[key])
			return out
	return v


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for prop: Dictionary in get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var key: String = prop["name"]
		var value: Variant = get(key)
		if key == "rng_seed" or key == "rng_state":
			out[key] = str(value)
		elif value is Array or value is Dictionary:
			out[key] = value.duplicate(true)
		else:
			out[key] = value
	return out


## Unknown keys are ignored and missing ones keep their defaults, so an old save still loads (like RunState).
## JSON gives floats back for every number: ints and bools are restored by each field's own type.
static func from_dict(data: Dictionary) -> SimState:
	var s := SimState.new()
	for prop: Dictionary in s.get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var key: String = prop["name"]
		if not data.has(key):
			continue
		var raw: Variant = data[key]
		match int(prop["type"]):
			TYPE_INT:
				s.set(key, int(str(raw)) if raw is String else int(raw))
			TYPE_FLOAT:
				s.set(key, float(raw))
			TYPE_BOOL:
				s.set(key, bool(raw))
			TYPE_STRING:
				s.set(key, str(raw))
			TYPE_ARRAY, TYPE_DICTIONARY:
				s.set(key, (raw as Variant).duplicate(true))
	s.refresh_edges()
	return s
```

`core/sim_context.gd`:

```gdscript
@tool
class_name SimContext
extends RefCounted
## What Sim.step reads but never changes (INV-08): the constants, the archetypes, the parsed event and coworker
## JSON, the Phase 1 data the duel request borrows, and the run's RNG. Build one with load_default() (tests, the
## harness: no autoloads, res:// files only) or by hand. The sim saves the RNG's seed and state in SimState and
## restores them at the start of every step, so one context can serve many runs in turn.

const WORK_CONFIG_PATH := "res://data/work/work_config.tres"
const ARCHETYPE_DIR := "res://data/archetypes/"
const BACKGROUND_DIR := "res://data/backgrounds/"
const TIER_DIR := "res://data/tiers/"
const EVENTS_PATH := "res://data/content/work_events.json"
const COWORKERS_PATH := "res://data/content/coworkers.json"
const BALANCE_PATH := "res://data/balance/balance_config.tres"
const CONTENT_DIR := "res://data/content/"
## The Phase 1 pools the adapter draws from (DuelAdapter): the interview's questions, the review's prompts, the
## contract's perks and fine print, and the companies' names. The sim never reads them.
const DUEL_CONTENT: PackedStringArray = ["questions_choice", "questions_knowledge", "questions_review", "emails", "companies"]

var cfg: WorkConfig
var archetypes: Dictionary = {}          # id -> ArchetypeData
var arch_ids: PackedStringArray = []     # sorted: the order rolls are made in
var events: Dictionary = {}              # evt id -> entry (work_events.json)
var coworker_defs: Dictionary = {}       # cw_* id -> entry (coworkers.json)
var coworker_pool: PackedStringArray = []
var bg: BackgroundData
var tiers: Dictionary = {}               # tier id -> TierData
var balance: BalanceConfig               # Phase 1's constants, which the duel and the contract still read
var content: Dictionary = {}             # DUEL_CONTENT file name -> parsed JSON
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var log_enabled: bool = true             # the run log; the harness turns it off for speed

var random_events: Array = []            # [{id, per_year, cooldown}], sorted by id
var chain_events: Array = []             # telegraphed events that start from a roll, sorted by id


static func load_default(bg_id: String = "intern") -> SimContext:
	var ctx := SimContext.new()
	ctx.cfg = load(WORK_CONFIG_PATH) as WorkConfig
	for file: String in ResourceLoader.list_directory(ARCHETYPE_DIR):
		if file.ends_with(".tres"):
			var arch := load(ARCHETYPE_DIR + file) as ArchetypeData
			ctx.archetypes[String(arch.id)] = arch
	ctx.bg = load(BACKGROUND_DIR + bg_id + ".tres") as BackgroundData
	for file: String in ResourceLoader.list_directory(TIER_DIR):
		if file.ends_with(".tres"):
			var tier := load(TIER_DIR + file) as TierData
			ctx.tiers[String(tier.id)] = tier
	ctx.balance = load(BALANCE_PATH) as BalanceConfig
	for file: String in DUEL_CONTENT:
		ctx.content[file] = _read_json(CONTENT_DIR + file + ".json")
	ctx.events = _read_json(EVENTS_PATH)
	var cw := _read_json(COWORKERS_PATH)
	ctx.coworker_pool = PackedStringArray(cw.get("_coworker_pool", []))
	for key: String in cw:
		if key.begins_with("cw_"):
			ctx.coworker_defs[key] = cw[key]
	ctx.build()
	return ctx


## Sort the archetype ids and pre-sort the events that roll, so no dictionary order ever decides a roll.
func build() -> void:
	arch_ids = PackedStringArray(archetypes.keys())
	arch_ids.sort()
	random_events.clear()
	chain_events.clear()
	var ids: Array = events.keys()
	ids.sort()
	for id: String in ids:
		if id.begins_with("_"):
			continue
		var evt: Dictionary = events[id]
		var trigger: Dictionary = evt.get("trigger", {})
		match String(trigger.get("kind", "")):
			"random":
				random_events.append({"id": id, "per_year": float(trigger.get("per_year", 0.0)), "cooldown": int(trigger.get("cooldown_days", 0))})
			"chain":
				chain_events.append({"id": id, "per_year": float(trigger.get("per_year", 0.0)), "cooldown": int(trigger.get("cooldown_days", 0))})


func archetype(id: String) -> ArchetypeData:
	return archetypes.get(id) as ArchetypeData


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
```

`core/work_odds.gd`:

```gdscript
@tool
class_name WorkOdds
extends RefCounted
## The career run's formulas (GDD 5.15-5.21) as static functions, like Odds. No state, no autoloads, no global
## RNG: anything random takes the run's RandomNumberGenerator. Tested by test_sim_rules, test_sim_review and
## test_sim_events. Levels, homes and ratings are indexes into these lists.

const LEVELS: PackedStringArray = ["junior", "mid", "senior"]
const HOMES: PackedStringArray = ["shared", "one_bed", "studio", "penthouse"]
const RATINGS: PackedStringArray = ["below", "meets", "exceeds"]
const JUNIOR := 0
const MID := 1
const SENIOR := 2
const BELOW := 0
const MEETS := 1
const EXCEEDS := 2
const QUALITY_CLEAN := 0
const QUALITY_BALANCED := 1
const QUALITY_FAST := 2


# ---------- floors and money (GDD 5.15, 6.1) ----------

## 1 + step x (floor - 1): the multiplier every floor-depth rule shares.
static func floor_mult(step: float, floor_n: int) -> float:
	return 1.0 + step * (floor_n - 1)


## An offer's salary in k$ a month: the level's base x the archetype's multiplier x the floor's raise x the Scars.
static func offer_salary(cfg: WorkConfig, arch: ArchetypeData, level: int, floor_n: int, gap_stacks: int) -> float:
	return cfg.salary_base_k[level] * arch.pay_mult * floor_mult(cfg.floor_salary_step, floor_n) * (1.0 - cfg.resume_gap_offer_cut * gap_stacks)


## Savings over one month of rent and living costs, in months (the chip turns red under runway_red_months).
static func runway_months(savings: float, rent: float, living: float) -> float:
	return savings / (rent + living)


## Starting savings in k$: the background's months of expenses in the Shared room, plus the Emergency fund edge.
static func start_savings(cfg: WorkConfig, bg: BackgroundData, emergency_edge: bool) -> float:
	var months := bg.start_savings_months + (cfg.edge_emergency_months if emergency_edge else 0.0)
	return months * (cfg.home_rent_k[cfg.start_home] + cfg.living_cost_k)


## Months of salary paid when a job ends in a layoff. options are rolled with equal odds; per_year is
## prorated by the days of tenure. first_job_max picks the largest option instead (run 1's Hierarchai: always 1).
static func severance_months(cfg: WorkConfig, arch: ArchetypeData, tenure_days: int, first_job_max: bool, rng: RandomNumberGenerator) -> float:
	var options: PackedFloat64Array = arch.severance_options
	var pick: float = 0.0
	if not options.is_empty():
		if first_job_max:
			pick = options[0]
			for o: float in options:
				pick = maxf(pick, o)
		else:
			pick = options[rng.randi_range(0, options.size() - 1)]
	return pick + arch.severance_per_year * float(tenure_days) / float(cfg.days_per_year)


# ---------- the daily formulas (GDD 5.16, 5.17) ----------

## Ticket progress per day in percent of a ticket: (100 / size) x Hours x Skill x Codebase x process x a
## Senior's calendar tax and quality bar x any speed change from an event.
static func ticket_rate(cfg: WorkConfig, size: int, notch: int, skill: float, codebase: float, arch: ArchetypeData, level: int, quality: int, speed_mod: float) -> float:
	var rate := 100.0 / cfg.ticket_size_days[size] * cfg.hours_speed[notch - 1]
	rate *= (1.0 + skill / cfg.skill_speed_div) * (1.0 - codebase / cfg.codebase_speed_div) * arch.ticket_speed * speed_mod
	if level >= SENIOR:
		rate *= cfg.calendar_tax
		if quality == QUALITY_CLEAN:
			rate *= cfg.quality_clean_speed
		elif quality == QUALITY_FAST:
			rate *= cfg.quality_fast_speed
	return rate


## Burnout change per day while you work, before the Burnout History floor: the Hours notch, minus the home's
## recovery, plus a heavy Codebase, a short runway and a commute. A negative notch value is rest and is never
## scaled; the Overtime edge trims only the notch-5 gain.
static func burnout_delta(cfg: WorkConfig, notch: int, home: int, codebase: float, runway: float, commute: float, overtime_edge: bool) -> float:
	var hours := cfg.hours_burnout[notch - 1]
	if overtime_edge and notch == cfg.hours_burnout.size() and hours > 0.0:
		hours *= cfg.edge_overtime_burnout_mult
	var d := hours - cfg.home_recovery[home] + commute
	if codebase >= cfg.codebase_burnout_min:
		d += cfg.codebase_burnout
	if runway < cfg.runway_red_months:
		d += cfg.low_runway_burnout
	return d


## Burnout change per day with no work (between jobs or on a forced leave). It is the same formula as working (D-04: one
## clock), minus what only a job has (a heavy Codebase, a commute): the Hours notch still sets how hard you push, the home
## still recovers you, and a thin runway still weighs on you.
static func idle_burnout_delta(cfg: WorkConfig, notch: int, home: int, runway: float) -> float:
	var d := cfg.hours_burnout[notch - 1] - cfg.home_recovery[home]
	if runway < cfg.runway_red_months:
		d += cfg.low_runway_burnout
	return d


## Manager Opinion change per day: the Hours notch, plus an archetype's utilization at notches 1-2.
static func mo_delta(cfg: WorkConfig, arch: ArchetypeData, notch: int) -> float:
	var d := cfg.hours_mo[notch - 1]
	if notch <= 2:
		d += arch.utilization_mo
	return d


## The Codebase's drift per day: the archetype's, plus a Senior's quality bar.
static func codebase_drift(cfg: WorkConfig, arch: ArchetypeData, level: int, quality: int) -> float:
	var d := arch.codebase_drift
	if level >= SENIOR:
		if quality == QUALITY_CLEAN:
			d += cfg.quality_clean_codebase
		elif quality == QUALITY_FAST:
			d += cfg.quality_fast_codebase
	return d


## p(incident per day): the Codebase's, times the floor's event frequency and any other multiplier (on-call,
## the Studio's final threat).
static func incident_p(cfg: WorkConfig, codebase: float, floor_n: int, mult: float) -> float:
	return (cfg.incident_base + cfg.incident_per_codebase * codebase) * floor_mult(cfg.floor_event_step, floor_n) * mult


## Days between incidents when each one starts a cooldown: the cooldown plus the mean wait of a daily roll.
static func incident_gap_days(cfg: WorkConfig, codebase: float, cooldown_days: int) -> float:
	return cooldown_days + 1.0 / incident_p(cfg, codebase, 1, 1.0)


# ---------- the review (GDD 5.16) ----------

## Your Evidence HP: a base, half your Manager Opinion, 5 per ticket shipped on time since the last review,
## and the Brag doc edge.
static func evidence(cfg: WorkConfig, mo: float, on_time_tickets: int, brag_edge: bool) -> float:
	var e := cfg.evidence_base + mo / cfg.evidence_mo_div + cfg.evidence_per_ticket * on_time_tickets
	if brag_edge:
		e += cfg.edge_brag_evidence
	return maxf(1.0, e)


## The rating from the Evidence you have left: under 25% of it is Below, over 70% Exceeds, else Meets.
static func rating(cfg: WorkConfig, evidence_total: float, evidence_left: float) -> int:
	var share := evidence_left / evidence_total
	if share < cfg.rating_below_max:
		return BELOW
	if share > cfg.rating_exceeds_min:
		return EXCEEDS
	return MEETS


## The stand-in for the review duel until M3 (A67): the manager's Calibration HP chips at your Evidence for
## review_standin_damage of itself, give or take review_standin_noise. Returns the Evidence you keep.
static func review_standin_left(cfg: WorkConfig, calibration: float, evidence_total: float, rng: RandomNumberGenerator) -> float:
	var damage := calibration * cfg.review_standin_damage * (1.0 + cfg.review_standin_noise * (rng.randf() * 2.0 - 1.0))
	return clampf(evidence_total - damage, 0.0, evidence_total)


## What the manager's Calibration lands on your Evidence in one round of the review duel (GDD 5.16, D-39, A94): the
## stand-in's damage spread over the review's prompts, times 0.4 for a good answer, 1.0 for an okay one (kind "neutral")
## and 1.8 for a joke (kind "bad"). Three okay answers cost exactly what the stand-in costs on average.
static func review_hit(cfg: WorkConfig, calibration: float, kind: String) -> float:
	var mult := cfg.review_hit_okay
	if kind == "good":
		mult = cfg.review_hit_good
	elif kind == "bad":
		mult = cfg.review_hit_joke
	return calibration * cfg.review_standin_damage / float(cfg.review_prompts) * mult


## The raise a rating earns, as a fraction of salary.
static func raise_for(cfg: WorkConfig, rating_id: int) -> float:
	if rating_id == EXCEEDS:
		return cfg.raise_exceeds
	if rating_id == MEETS:
		return cfg.raise_meets
	return 0.0


## True when this review promotes you: the archetype's rating, held for its streak (counting this review).
static func promotes(arch: ArchetypeData, rating_id: int, streak: int, level: int) -> bool:
	return level < SENIOR and rating_id >= arch.promotion_min_rating and streak >= arch.promotion_streak


# ---------- events (GDD 5.19) ----------

## The chance Burnout picks for you: 0 below auto_resolve_from, then (Burnout - 70) / 30, certain at 100.
static func auto_resolve_p(cfg: WorkConfig, burnout: float) -> float:
	if burnout < cfg.auto_resolve_from:
		return 0.0
	return clampf((burnout - cfg.auto_resolve_base) / cfg.auto_resolve_span, 0.0, 1.0)


## How many employees a resizing cuts: the archetype's share of the floor, at least layoff_min_cut.
static func layoff_cut_count(cfg: WorkConfig, arch: ArchetypeData, employees: int) -> int:
	return clampi(maxi(cfg.layoff_min_cut, roundi(arch.layoff_share * employees)), 0, employees)


## Which employees a resizing cuts (R-EVT-03): each one's chance is weighted layoff_salary_weight by salary rank (the
## highest salary the largest share, the lowest none) and layoff_luck_weight by chance (an equal share each), and
## `cuts` people are drawn from those weights without replacement. Manager Opinion is not an input (O1). Returns
## indexes into salaries, in the order they were drawn.
static func layoff_cuts(cfg: WorkConfig, salaries: Array, cuts: int, rng: RandomNumberGenerator) -> Array[int]:
	var n := salaries.size()
	var by_salary: Array[int] = []
	for i: int in n:
		by_salary.append(i)
	by_salary.sort_custom(func(a: int, b: int) -> bool:
		var sa: float = salaries[a]
		var sb: float = salaries[b]
		return sa < sb if sa != sb else a < b)
	var rank_total := maxf(1.0, n * (n - 1) / 2.0)
	var weight: Array[float] = []
	weight.resize(n)
	for rank: int in n:
		weight[by_salary[rank]] = cfg.layoff_salary_weight * rank / rank_total + cfg.layoff_luck_weight / n
	var out: Array[int] = []
	var left: Array[int] = []
	for i: int in n:
		left.append(i)
	for k: int in mini(cuts, n):
		var total := 0.0
		for i: int in left:
			total += weight[i]
		var r := rng.randf() * total
		var pick := left.size() - 1
		for j: int in left.size():
			r -= weight[left[j]]
			if r < 0.0:
				pick = j
				break
		out.append(left[pick])
		left.remove_at(pick)
	return out


## Daily odds of a random event: a per-year rate spread over the days, times the floor's event frequency and the
## Studio's final-threat weight.
static func random_event_p(cfg: WorkConfig, per_year: float, floor_n: int, threat_mult: float) -> float:
	return per_year / cfg.days_per_year * floor_mult(cfg.floor_event_step, floor_n) * threat_mult


# ---------- the job hunt (GDD 5.20) ----------

## f_level: 1.0 at your level, 0.5 one level up, 0.8 below.
static func level_factor(cfg: WorkConfig, posting_level: int, level: int) -> float:
	if posting_level > level:
		return cfg.callback_level_up
	if posting_level < level:
		return cfg.callback_level_down
	return cfg.callback_level_same


## p_callback = 0.35 x f_level x (1 - 0.15 per Short Tenure stack) x (1 + 0.1 per reference). e_handbook is 1.0
## in v1: no Edge tip touches it.
static func callback_p(cfg: WorkConfig, posting_level: int, level: int, short_tenure_stacks: int, references: int) -> float:
	return cfg.callback_base * level_factor(cfg, posting_level, level) \
		* (1.0 - cfg.callback_short_tenure_cut * short_tenure_stacks) * (1.0 + cfg.callback_reference_bonus * references)


## The 5-dot band of the callback odds (GDD 5.20, A90): 1 + the thresholds the odds reach. Shown as dots, never a percentage.
static func callback_dots(cfg: WorkConfig, p: float) -> int:
	var dots := 1
	for step: float in cfg.callback_band_steps:
		if p >= step:
			dots += 1
	return dots


## A month's pay in k$ as the yearly figure the board and the contract show (MC-10): whole dollars, rounded to $1,000.
static func yearly_salary(cfg: WorkConfig, monthly_k: float) -> int:
	return Odds.round_to(monthly_k * float(cfg.days_per_year) / float(cfg.days_per_month) * 1000.0, 1000)


# ---------- the duel's inputs (GDD 5.20, R-JOB-03) ----------

## Your Composure HP: the background's base, lowered by Burnout.
static func duel_composure(cfg: WorkConfig, base: float, burnout: float) -> float:
	return base * (1.0 - burnout / cfg.duel_composure_burnout_div)


## The Answer Meter's width multiplier: Skill widens it, Rust narrows it. The caller keeps the 0.06 floor (RC-25).
static func duel_zone_mult(cfg: WorkConfig, skill: float, rust: float) -> float:
	return (1.0 + skill / cfg.duel_zone_skill_div) * (1.0 - rust / cfg.duel_zone_rust_div)


## Dana's Doubt HP: the tier's base, raised by the floor.
static func duel_doubt(cfg: WorkConfig, base: float, floor_n: int) -> float:
	return base * floor_mult(cfg.floor_doubt_step, floor_n)


# ---------- the Studio (GDD 3.4) ----------

## How many of the five conditions hold: Senior, Remote, The Studio, Burnout at or below 30, and a runway of 6
## months at Studio rent.
static func studio_count(cfg: WorkConfig, level: int, remote: bool, home: int, burnout: float, savings: float, living: float) -> int:
	var n := 0
	if level >= SENIOR:
		n += 1
	if remote:
		n += 1
	if home == cfg.studio_home:
		n += 1
	if burnout <= cfg.studio_burnout_max:
		n += 1
	if savings / (cfg.home_rent_k[cfg.studio_home] + living) >= cfg.studio_runway_months:
		n += 1
	return n
```

`core/event_plan.gd`:

```gdscript
@tool
class_name EventPlan
extends RefCounted
## Which events can happen (GDD 5.19): tier, archetype, level, the "requires" conditions of work_events.json, and
## the calendar strip. Pure like WorkOdds: it reads a SimState and the SimContext, and changes nothing. The odds
## of a roll are WorkOdds'; the rolling itself is Sim's, in a fixed order.


## True when the event's archetype and level lists include yours and its own conditions hold.
static func eligible(ctx: SimContext, state: SimState, evt: Dictionary) -> bool:
	if state.employed:
		if not (evt.get("archetypes", []) as Array).has(state.job_archetype):
			return false
	if not (evt.get("levels", []) as Array).has(WorkOdds.LEVELS[state.level]):
		return false
	return requires_met(ctx, state, evt.get("requires", {}))


## Conditions of an event or of one choice. An empty dictionary always holds.
static func requires_met(ctx: SimContext, state: SimState, req: Dictionary) -> bool:
	for key: String in req:
		var want: Variant = req[key]
		match key:
			"employed":
				if state.employed != bool(want):
					return false
			"remote":
				if (state.employed and state.job_remote) != bool(want):
					return false
			"rto":
				if not state.employed:
					return false
				var arch := ctx.archetype(state.job_archetype)
				if (arch.rto_after_days >= 0 and state.day - state.job_start >= arch.rto_after_days) != bool(want):
					return false
			"home_min":
				if state.home < int(want):
					return false
			"tip":
				if not state.has_tip(String(want)):
					return false
			"clause":
				if not state.job_clauses.has(String(want)):
					return false
			"not_flag":
				if state.job_flags.has(String(want)):
					return false
			"deadline_or_incident_days":
				var n := int(want)
				var near_deadline := state.employed and state.ticket_deadline - state.day <= n and state.ticket_deadline >= state.day
				var after_incident := state.day - state.last_incident_day <= n
				if not (near_deadline or after_incident):
					return false
	return true


## The choices of an event that you can pick now, as the choice dictionaries.
static func available_choices(ctx: SimContext, state: SimState, evt: Dictionary) -> Array:
	var out: Array = []
	for choice: Dictionary in evt.get("choices", []):
		if requires_met(ctx, state, choice.get("requires", {})):
			out.append(choice)
	return out


## The weight of a random event today: the final threats get final_threat_mult while the Studio hold is filming.
static func threat_mult(ctx: SimContext, state: SimState, evt: Dictionary) -> float:
	if state.studio_hold > 0 and bool(evt.get("final_threat", false)):
		return ctx.cfg.final_threat_mult
	return 1.0


## What the calendar strip shows for the next `days` days (GDD 5.14): paydays, rent, the review, the lease, a
## ticket's deadline, a chain's fire day and an interview, as [{day, kind}] sorted by day.
static func calendar(ctx: SimContext, state: SimState, days: int) -> Array:
	var cfg := ctx.cfg
	var out: Array = []
	for d: int in range(state.day + 1, state.day + days + 1):
		if (d - cfg.payday) % cfg.days_per_month == 0 and state.employed:
			out.append({"day": d, "kind": "payday"})
		if (d - cfg.rent_day) % cfg.days_per_month == 0:
			out.append({"day": d, "kind": "rent"})
	if state.employed and state.next_review > state.day and state.next_review <= state.day + days:
		out.append({"day": state.next_review, "kind": "review"})
	var lease_due: int = state.lease_day + cfg.lease_days
	if lease_due > state.day and lease_due <= state.day + days:
		out.append({"day": lease_due, "kind": "lease"})
	if state.employed and state.ticket_deadline > state.day and state.ticket_deadline <= state.day + days:
		out.append({"day": state.ticket_deadline, "kind": "deadline"})
	for app: Dictionary in state.applications:
		var iv := int(app.get("interview", -1))
		if bool(app.get("callback", false)) and iv > state.day and iv <= state.day + days:
			out.append({"day": iv, "kind": "interview"})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return out
```

`core/sim.gd`:

```gdscript
@tool
class_name Sim
extends RefCounted
## The career run's rules as one deterministic step function (GDD 5.14-5.22, ARCHITECTURE 19.2). Sim.step(state,
## inputs, ctx) applies the inputs, then advances one day unless something waits for an answer (an event card, a
## review, a duel, an offer: state.queue). Pure like Odds: no nodes, no autoloads, no wall clock, no global RNG; every
## roll is on ctx.rng, restored from the state at the start of a step and saved back at its end, and the rolls
## happen in one fixed order, so a seed plus the inputs replays a run exactly. Numbers come from WorkConfig,
## ArchetypeData and the event JSON, never from this file (INV-09, INV-15), and no archetype is ever named here.
##
## One tick, in order: the calendar and money (day, rent, pay, living costs); the daily formulas (ticket, MO,
## Codebase, Burnout, Rust); the job hunt (replies, interviews); the review and the lease; the telegraphed chains;
## the rolls (incident, random events, chain starts); then the checks (forced leave, the PIP, Scars, the endings).

const IN_SET_HOURS := "set_hours"
const IN_CHOOSE := "choose"
const IN_REVIEW_RESULT := "review_result"
const IN_TICKET_PICK := "ticket_pick"
const IN_DUEL_RESULT := "duel_result"
const IN_ANSWER_OFFER := "answer_offer"
const IN_APPLY := "apply"
const IN_STUDY := "study"
const IN_MOVE_HOME := "move_home"
const IN_PUSH_BACK := "push_back"
const IN_SET_QUALITY := "set_quality"
const IN_ACK := "ack"

const EVT_RESIZING := "evt_e07_resizing"
const EVT_INCIDENT := "evt_e12_incident_prod"
const EVT_LIFESTYLE := "evt_e21_lifestyle_offer"
const EVT_RECRUITER := "evt_e18_recruiter_dm"
const EVT_REVIEW := "evt_e02_review"

const PICK_NAMES: PackedStringArray = ["feature", "bugfix", "paydown"]
const QUALITY_NAMES: PackedStringArray = ["clean", "balanced", "fast"]
const KIND_ASSIGNED := 0
const KIND_FEATURE := 1
const KIND_BUGFIX := 2
const KIND_PAYDOWN := 3


# ---------- a new run ----------

## Run 1 starts employed at the authored job with a guaranteed layoff on day 240 (GDD 3.3, P-06); later runs start
## between jobs with the board open. ctx.bg is the run's background. handbook is the collected tip ids.
static func new_run(ctx: SimContext, run_number: int, run_seed: int, handbook: Array = []) -> SimState:
	var cfg := ctx.cfg
	var s := SimState.new()
	s.rng_seed = run_seed
	ctx.rng.seed = run_seed
	s.bg_id = String(ctx.bg.id)
	s.run_number = run_number
	s.handbook = handbook.duplicate()
	s.refresh_edges()
	s.home = cfg.start_home
	s.rent = cfg.home_rent_k[s.home]
	s.living_cost = cfg.living_cost_k
	s.savings = WorkOdds.start_savings(cfg, ctx.bg, s.h_emergency)
	s.hours = cfg.hours_default
	s.unemployed_since = 0
	var events: Array = []
	if run_number == 1:
		var arch := ctx.archetype(cfg.run1_archetype)
		var posting := {
			"id": 0, "company": cfg.run1_company, "archetype": cfg.run1_archetype, "level": WorkOdds.JUNIOR, "floor": 1,
			"salary": WorkOdds.offer_salary(cfg, arch, WorkOdds.JUNIOR, 1, 0), "remote": cfg.run1_remote, "clauses": [],
		}
		_start_job(s, ctx, posting, events, true)
		s.pay_accrued = s.job_salary / cfg.days_per_month * cfg.run1_pay_days_accrued
	else:
		_refresh_board(s, ctx)
	s.rng_state = ctx.rng.state
	return s


# ---------- the step ----------

## Apply the inputs, then advance one day unless something is waiting. Returns what happened, as dictionaries with
## a "kind" (for the UI, the harness and the run log).
static func step(state: SimState, inputs: Array, ctx: SimContext) -> Array:
	var events: Array = []
	if state.ended:
		return events
	ctx.rng.seed = state.rng_seed
	ctx.rng.state = state.rng_state
	for input: Dictionary in inputs:
		_apply_input(state, ctx, input, events)
	if state.queue.is_empty() and not state.ended:
		_tick(state, ctx, events)
	state.rng_state = ctx.rng.state
	return events


## Apply the inputs and do not tick: how the work state changes the Hours or answers a card while the clock is paused
## (the clock driver ticks with step(state, [], ctx)). The run log stores the day each input was sent on, and replay()
## batches the inputs of a day with the tick that follows them, so a run played this way replays to the same state (O8).
static func apply_inputs(state: SimState, inputs: Array, ctx: SimContext) -> Array:
	var events: Array = []
	if state.ended:
		return events
	ctx.rng.seed = state.rng_seed
	ctx.rng.state = state.rng_state
	for input: Dictionary in inputs:
		_apply_input(state, ctx, input, events)
	state.rng_state = ctx.rng.state
	return events


## Replays a run from its log: the same seed and inputs give the same run (O8). Only the accepted inputs matter
## (SimState.log entries with "k" == "in", each with the day it was sent on); the days between them tick on their own.
## The run is replayed to until_day, or to the last day the log mentions.
static func replay(ctx: SimContext, run_number: int, run_seed: int, handbook: Array, log: Array, until_day: int = -1) -> SimState:
	var s := new_run(ctx, run_number, run_seed, handbook)
	var entries: Array = []
	var last_day := 0
	for entry: Dictionary in log:
		last_day = maxi(last_day, int(entry["d"]))
		if entry.get("k", "") == "in":
			entries.append(entry)
	var end_day := until_day if until_day >= 0 else last_day
	var i := 0
	while i < entries.size() and not s.ended:
		var day := int(entries[i]["d"])
		var batch: Array = []
		while i < entries.size() and int(entries[i]["d"]) == day:
			batch.append(entries[i]["i"])
			i += 1
		while s.day < day and s.queue.is_empty() and not s.ended:
			step(s, [], ctx)
		step(s, batch, ctx)
	while s.day < end_day and s.queue.is_empty() and not s.ended:
		step(s, [], ctx)
	return s


# ---------- inputs ----------

static func _apply_input(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> void:
	var kind: String = input.get("kind", "")
	var ok := false
	match kind:
		IN_SET_HOURS:
			ok = _in_set_hours(s, ctx, input)
		IN_CHOOSE:
			ok = _in_choose(s, ctx, input, events)
		IN_REVIEW_RESULT:
			ok = _in_review_result(s, ctx, input, events)
		IN_TICKET_PICK:
			ok = _in_ticket_pick(s, ctx, input)
		IN_DUEL_RESULT:
			ok = _in_duel_result(s, ctx, input, events)
		IN_ANSWER_OFFER:
			ok = _in_answer_offer(s, ctx, input, events)
		IN_APPLY:
			ok = _in_apply(s, ctx, input, events)
		IN_STUDY:
			ok = _in_study(s, ctx, events)
		IN_MOVE_HOME:
			ok = _in_move_home(s, ctx, input, events)
		IN_PUSH_BACK:
			ok = _in_push_back(s, ctx)
		IN_SET_QUALITY:
			ok = _in_set_quality(s, ctx, input)
		IN_ACK:
			ok = _in_ack(s)
	if ok:
		_log(s, ctx, "in", {"i": input})
	else:
		s.bump("rejected")
		events.append({"kind": "input_rejected", "input": kind})


static func _in_set_hours(s: SimState, ctx: SimContext, input: Dictionary) -> bool:
	if s.day <= s.hours_lock_until:
		return false
	var notch := clampi(int(input.get("notch", s.hours)), 1, ctx.cfg.hours_speed.size())
	if notch != s.hours:
		s.bump("hours_changes")
	s.hours = notch
	return true


static func _in_choose(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "event":
		return false
	var choice_id := String(input.get("choice", ""))
	if not (item["choices"] as Array).has(choice_id):
		return false
	s.queue.pop_front()
	_resolve_choice(s, ctx, String(item["id"]), choice_id, events)
	return true


static func _in_review_result(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "review":
		return false
	s.queue.pop_front()
	_resolve_review(s, ctx, item, float(input.get("evidence_left", 0.0)), events)
	return true


static func _in_ticket_pick(s: SimState, ctx: SimContext, input: Dictionary) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "ticket_pick":
		return false
	var pick := PICK_NAMES.find(String(input.get("pick", "")))
	if pick < 0:
		return false
	s.queue.pop_front()
	match pick:
		0:
			_new_ticket(s, ctx, KIND_FEATURE, ctx.rng.randi_range(1, 2))
		1:
			_new_ticket(s, ctx, KIND_BUGFIX, 0)
		2:
			_new_ticket(s, ctx, KIND_PAYDOWN, 1)
	return true


static func _in_duel_result(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "duel":
		return false
	s.queue.pop_front()
	_resolve_duel(s, ctx, item, bool(input.get("passed", false)), events)
	return true


static func _in_answer_offer(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "offer":
		return false
	s.queue.pop_front()
	var app_id := int(item["app"])
	var posting: Dictionary = item["posting"]
	_drop_application(s, app_id)
	if bool(input.get("accept", false)):
		if s.employed:
			_end_job(s, ctx, "quit", events, 0.0)
		if not s.ended:
			_start_job(s, ctx, posting, events, false)
	else:
		s.blacklist.append(String(posting["company"]))
		s.bump("declined")
		events.append({"kind": "offer_declined", "company": posting["company"]})
	return true


static func _in_apply(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var cfg := ctx.cfg
	if s.employed and s.jobs_held >= cfg.max_jobs:
		return false
	var idx := -1
	for i: int in s.board.size():
		if int(s.board[i]["id"]) == int(input.get("posting", -1)):
			idx = i
			break
	if idx < 0:
		return false
	var posting: Dictionary = s.board[idx]
	var p := WorkOdds.callback_p(cfg, int(posting["level"]), s.level, s.scar_short_tenure, _references(s, cfg))
	var callback := ctx.rng.randf() < p
	var reply := s.day + ctx.rng.randi_range(cfg.reply_days_min, cfg.reply_days_max)
	var interview := -1
	if callback:
		interview = reply + ctx.rng.randi_range(cfg.interview_days_min, cfg.interview_days_max)
	s.applications.append({"posting": posting, "applied": s.day, "reply": reply, "callback": callback, "interview": interview,
		"status": "wait", "duels_done": 0, "next_duel": -1})
	if s.employed:
		_add_burnout(s, cfg, cfg.apply_burnout_employed)
		s.bump("applies_employed")
		if ctx.rng.randf() < cfg.notice_p:
			_add_mo(s, cfg, cfg.notice_mo)
			events.append({"kind": "profile_noticed"})
	else:
		_add_burnout(s, cfg, cfg.apply_burnout_unemployed)
	s.bump("applies")
	s.board[idx] = _gen_posting(s, ctx)
	events.append({"kind": "application_sent", "company": posting["company"]})
	return true


static func _in_study(s: SimState, ctx: SimContext, events: Array) -> bool:
	var cfg := ctx.cfg
	if s.last_study_day == s.day:
		return false
	s.last_study_day = s.day
	_add_burnout(s, cfg, cfg.study_burnout)
	s.rust = clampf(s.rust + cfg.study_rust, 0.0, cfg.stat_max)
	s.skill = clampf(s.skill + cfg.study_skill, 0.0, cfg.stat_max)
	if not s.employed:
		s.studies_this_spell += 1
	s.bump("studies")
	events.append({"kind": "studied"})
	return true


static func _in_move_home(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var tier := int(input.get("tier", s.home))
	if tier == s.home or tier < 0 or tier >= ctx.cfg.home_rent_k.size():
		return false
	_move_home(s, ctx, tier, events)
	return true


static func _in_push_back(s: SimState, ctx: SimContext) -> bool:
	var cfg := ctx.cfg
	if not s.employed or s.level < WorkOdds.MID or s.push_back_used or s.ticket_progress >= 100.0:
		return false
	s.push_back_used = true
	s.ticket_deadline += roundi(cfg.ticket_size_days[s.ticket_size] * cfg.push_back_deadline)
	_add_mo(s, cfg, cfg.push_back_mo)
	return true


static func _in_set_quality(s: SimState, ctx: SimContext, input: Dictionary) -> bool:
	var bar := QUALITY_NAMES.find(String(input.get("bar", "")))
	if not s.employed or s.level < WorkOdds.SENIOR or bar < 0:
		return false
	s.quality = bar
	return true


static func _in_ack(s: SimState) -> bool:
	var item := s.pending()
	var kind := String(item.get("kind", ""))
	if kind != "layoff_scene" and kind != "forced_leave" and kind != "info":
		return false
	s.queue.pop_front()
	return true


# ---------- one day ----------

static func _tick(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	s.day += 1
	var day := s.day
	var arch: ArchetypeData = ctx.archetype(s.job_archetype) if s.employed else null
	var on_leave := s.employed and day <= s.leave_end

	_money(s, cfg, on_leave, events)

	var runway := WorkOdds.runway_months(s.savings, s.rent, s.living_cost * s.living_mult)
	if s.employed and not on_leave:
		var notch := s.hours
		var speed := s.speed_mod if day <= s.speed_mod_until else 1.0
		s.ticket_progress += WorkOdds.ticket_rate(cfg, s.ticket_size, notch, s.skill, s.codebase, arch, s.level, s.quality, speed)
		s.mo = clampf(s.mo + WorkOdds.mo_delta(cfg, arch, notch), cfg.mo_min, cfg.mo_max)
		s.codebase = clampf(s.codebase + WorkOdds.codebase_drift(cfg, arch, s.level, s.quality), 0.0, cfg.stat_max)
		_add_burnout(s, cfg, WorkOdds.burnout_delta(cfg, notch, s.home, s.codebase, runway, s.commute_burnout, s.h_overtime))
		if s.ticket_progress >= 100.0:
			_ship_ticket(s, ctx, events)
	else:
		_add_burnout(s, cfg, WorkOdds.idle_burnout_delta(cfg, s.hours, s.home, runway))
	s.rust = minf(cfg.stat_max, s.rust + cfg.rust_per_day)

	_hunt(s, ctx, events)
	if s.employed and not on_leave:
		if day >= s.next_review and s.next_review >= 0:
			_queue_review(s, ctx, arch, events)
		if day - s.lease_day >= cfg.lease_days:
			_present_event(s, ctx, "evt_e04_lease_renewal", events)
	elif not s.employed and day - s.lease_day >= cfg.lease_days:
		_present_event(s, ctx, "evt_e04_lease_renewal", events)
	if not s.chains.is_empty():
		_run_chains(s, ctx, events)
	_rolls(s, ctx, on_leave, events)
	_checks(s, ctx, on_leave, events)


static func _money(s: SimState, cfg: WorkConfig, on_leave: bool, events: Array) -> void:
	var day := s.day
	if day % cfg.living_cost_growth_days == 0:
		s.living_cost *= 1.0 + cfg.living_cost_growth
	if (day - cfg.rent_day) % cfg.days_per_month == 0:
		var bills := s.rent + s.living_cost * s.living_mult
		s.savings -= bills
		events.append({"kind": "rent", "amount": bills})
	if s.employed:
		s.pay_accrued += s.job_salary / cfg.days_per_month * (cfg.forced_leave_pay if on_leave else 1.0)
	if (day - cfg.payday) % cfg.days_per_month == 0 and s.pay_accrued > 0.0:
		s.savings += s.pay_accrued
		events.append({"kind": "payday", "amount": s.pay_accrued})
		s.pay_accrued = 0.0
	if s.savings < 0.0:
		s.below_zero_days += 1
	else:
		s.below_zero_days = 0


# ---------- tickets ----------

static func _new_ticket(s: SimState, ctx: SimContext, kind: int = KIND_ASSIGNED, size: int = -1) -> void:
	var cfg := ctx.cfg
	if size < 0:
		size = ctx.rng.randi_range(0, cfg.ticket_size_days.size() - 1)
	s.ticket_kind = kind
	s.ticket_size = size
	s.ticket_progress = 0.0
	s.ticket_start = s.day
	s.ticket_deadline = s.day + roundi(cfg.ticket_size_days[size] * cfg.ticket_deadline_mult)


static func _ship_ticket(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	var on_time := s.day <= s.ticket_deadline
	s.tickets_shipped += 1
	if on_time:
		s.tickets_on_time += 1
		s.on_time_since_review += 1
		_add_mo(s, cfg, cfg.mo_on_time)
	else:
		_add_mo(s, cfg, cfg.mo_late)
	s.skill = minf(cfg.stat_max, s.skill + cfg.skill_per_ticket)
	match s.ticket_kind:
		KIND_FEATURE:
			_add_mo(s, cfg, cfg.pick_feature_mo)
			s.codebase = clampf(s.codebase + cfg.pick_feature_codebase, 0.0, cfg.stat_max)
		KIND_BUGFIX:
			s.skill = clampf(s.skill + cfg.pick_bugfix_skill, 0.0, cfg.stat_max)
			s.codebase = clampf(s.codebase + cfg.pick_bugfix_codebase, 0.0, cfg.stat_max)
		KIND_PAYDOWN:
			_add_mo(s, cfg, cfg.pick_paydown_mo)
			s.codebase = clampf(s.codebase + cfg.pick_paydown_codebase, 0.0, cfg.stat_max)
	events.append({"kind": "ticket_shipped", "on_time": on_time, "size": s.ticket_size})
	if s.level >= WorkOdds.MID:
		s.ticket_progress = 0.0
		s.queue.append({"kind": "ticket_pick"})
	else:
		_new_ticket(s, ctx)


# ---------- stats ----------

static func _burnout_floor(s: SimState, cfg: WorkConfig) -> float:
	return cfg.burnout_history_floor * s.scar_burnout_history


static func _add_burnout(s: SimState, cfg: WorkConfig, delta: float) -> void:
	s.burnout = clampf(s.burnout + delta, _burnout_floor(s, cfg), cfg.burnout_max)


static func _add_mo(s: SimState, cfg: WorkConfig, delta: float) -> void:
	s.mo = clampf(s.mo + delta, cfg.mo_min, cfg.mo_max)


# ---------- events ----------

## Show an event: a card that waits for a choice, or a choice the Burnout makes for you (GDD 5.19). An event with
## no choices only happens (its effects are none today).
static func _present_event(s: SimState, ctx: SimContext, evt_id: String, events: Array) -> void:
	var evt: Dictionary = ctx.events.get(evt_id, {})
	if evt.is_empty():
		return
	s.event_last[evt_id] = s.day
	s.bump("events")
	var choices := EventPlan.available_choices(ctx, s, evt)
	if choices.is_empty():
		events.append({"kind": "event", "id": evt_id, "choices": []})
		return
	var ids: Array = []
	for choice: Dictionary in choices:
		ids.append(choice["id"])
	var exhausted: String = evt.get("exhausted_choice", "")
	if not exhausted.is_empty() and s.burnout >= ctx.cfg.auto_resolve_from:
		if ctx.rng.randf() < WorkOdds.auto_resolve_p(ctx.cfg, s.burnout):
			s.bump("auto_resolved")
			var pick := exhausted if ids.has(exhausted) else "none"
			events.append({"kind": "auto_resolved", "id": evt_id, "choice": pick})
			if pick != "none":
				_resolve_choice(s, ctx, evt_id, pick, events)
			return
	s.queue.append({"kind": "event", "id": evt_id, "choices": ids, "exhausted": exhausted})
	events.append({"kind": "event", "id": evt_id, "choices": ids})


static func _resolve_choice(s: SimState, ctx: SimContext, evt_id: String, choice_id: String, events: Array) -> void:
	var evt: Dictionary = ctx.events[evt_id]
	for choice: Dictionary in evt.get("choices", []):
		if choice["id"] == choice_id:
			_apply_effects(s, ctx, choice.get("effects", {}), events)
	var tip := String((evt.get("ducky", {}) as Dictionary).get("tip", "none"))
	if tip != "none" and not s.tips_seen.has(tip):
		s.tips_seen.append(tip)
		events.append({"kind": "tip", "id": tip, "event": evt_id})
	events.append({"kind": "event_resolved", "id": evt_id, "choice": choice_id})
	_log(s, ctx, "event", {"id": evt_id, "choice": choice_id})


## An event's effects, in one fixed order. Numbers come from the JSON; named actions are the few rules that are
## more than a number.
static func _apply_effects(s: SimState, ctx: SimContext, eff: Dictionary, events: Array) -> void:
	var cfg := ctx.cfg
	if eff.has("mo"):
		_add_mo(s, cfg, float(eff["mo"]))
	if eff.has("burnout"):
		_add_burnout(s, cfg, float(eff["burnout"]))
	if eff.has("codebase"):
		s.codebase = clampf(s.codebase + float(eff["codebase"]), 0.0, cfg.stat_max)
	if eff.has("skill"):
		s.skill = clampf(s.skill + float(eff["skill"]), 0.0, cfg.stat_max)
	if eff.has("rust"):
		s.rust = clampf(s.rust + float(eff["rust"]), 0.0, cfg.stat_max)
	if eff.has("savings"):
		s.savings += float(eff["savings"])
	if eff.has("living_mult"):
		s.living_mult = float(eff["living_mult"])
	if eff.has("commute_burnout"):
		s.commute_burnout = float(eff["commute_burnout"])
	if eff.has("speed_mod"):
		var sm: Dictionary = eff["speed_mod"]
		s.speed_mod = float(sm["mult"])
		s.speed_mod_until = s.day + int(sm["days"])
	if eff.has("hours_lock"):
		var hl: Dictionary = eff["hours_lock"]
		s.hours = int(hl["notch"])
		s.hours_lock_until = s.day + int(hl["days"])
	if eff.has("flags"):
		for flag: String in eff["flags"]:
			if not s.job_flags.has(flag):
				s.job_flags.append(flag)
	if eff.has("work_mode"):
		s.job_remote = String(eff["work_mode"]) == "remote"
	if eff.has("action"):
		_action(s, ctx, String(eff["action"]), events)


static func _action(s: SimState, ctx: SimContext, action: String, events: Array) -> void:
	var cfg := ctx.cfg
	match action:
		"lease_accept":
			s.rent *= 1.0 + cfg.lease_raise
			s.lease_day = s.day
		"lease_move_down":
			if s.home > 0:
				_move_home(s, ctx, s.home - 1, events)
		"home_upgrade":
			if s.home < cfg.home_rent_k.size() - 1:
				_move_home(s, ctx, s.home + 1, events)
		"board_early":
			_refresh_board(s, ctx)
		"ask_priya":
			var best := 0.0
			for cw: Dictionary in s.coworkers:
				best = maxf(best, float(cw["rapport"]))
			if best >= cfg.reference_rapport:
				for ch: Dictionary in s.chains:
					if ch["event"] == EVT_RESIZING:
						s.layoff_known_day = int(ch["fire_day"])
		"quit_job":
			_end_job(s, ctx, "quit", events, 0.0)
		"recruiter_call":
			_recruiter_application(s, ctx, events)


static func _move_home(s: SimState, ctx: SimContext, tier: int, events: Array) -> void:
	var cfg := ctx.cfg
	var new_rent := cfg.home_rent_k[tier]
	s.savings -= new_rent * cfg.move_cost_months
	s.home = tier
	s.rent = new_rent
	s.lease_day = s.day
	s.bump("moves")
	events.append({"kind": "moved", "home": tier})


# ---------- the chains: telegraphed events (GDD 5.19) ----------

static func _run_chains(s: SimState, ctx: SimContext, events: Array) -> void:
	var i := 0
	while i < s.chains.size():
		var ch: Dictionary = s.chains[i]
		for st: Dictionary in ch["stages"]:
			if int(st["day"]) == s.day:
				events.append({"kind": "rumor", "event": ch["event"], "text": st["text"]})
				if bool(st.get("prep", false)):
					_present_event(s, ctx, String(ch["event"]), events)
		if s.day == int(ch["fire_day"]):
			s.chains.remove_at(i)
			_chain_fires(s, ctx, ch, events)
			continue
		i += 1


static func _chain_fires(s: SimState, ctx: SimContext, ch: Dictionary, events: Array) -> void:
	var evt: Dictionary = ctx.events[ch["event"]]
	if String((evt.get("trigger", {}) as Dictionary).get("kind", "")) == "resizing":
		_resize(s, ctx, ch, events)
	else:
		_present_event(s, ctx, String(ch["event"]), events)


## A resizing (E07): run 1's cuts you for certain; later ones cut a share of the floor, picked by salary and luck
## and never by Manager Opinion (R-EVT-03, O1).
static func _resize(s: SimState, ctx: SimContext, ch: Dictionary, events: Array) -> void:
	var cfg := ctx.cfg
	var arch := ctx.archetype(s.job_archetype)
	s.living_mult = 1.0
	s.layoff_known_day = -1
	var cut_you := bool(ch.get("scripted", false))
	if not cut_you:
		var salaries: Array = [s.job_salary]
		for cw: Dictionary in s.coworkers:
			salaries.append(float(cw["salary"]))
		var cuts := WorkOdds.layoff_cut_count(cfg, arch, salaries.size())
		var picked := WorkOdds.layoff_cuts(cfg, salaries, cuts, ctx.rng)
		cut_you = picked.has(0)
		if not cut_you:
			var gone: Array[int] = []
			for idx: int in picked:
				gone.append(idx - 1)
			gone.sort()
			gone.reverse()
			for g: int in gone:
				s.past_coworkers.append({"id": s.coworkers[g]["id"], "rapport": s.coworkers[g]["rapport"]})
				s.coworkers.remove_at(g)
			s.bump("resizings_survived")
			events.append({"kind": "resizing_survived", "cuts": cuts})
			_schedule_resizing(s, ctx, arch, false)
			return
	var first_job := s.run_number == 1 and s.jobs_held == 1
	var months := WorkOdds.severance_months(cfg, arch, s.day - s.job_start, first_job, ctx.rng)
	var severance := months * s.job_salary   # k$: the scene shows it, and _end_job clears the salary
	s.bump("layoffs")
	_end_job(s, ctx, "layoff", events, months)
	if not s.ended:
		s.queue.append({"kind": "layoff_scene", "severance_months": months, "severance": severance})


## Plan the next resizing chain of this job: run 1's authored five signs and the fixed day, or a rumor 10-30 days
## ahead of a day rolled around the archetype's interval (shortened by the floor's event frequency).
static func _schedule_resizing(s: SimState, ctx: SimContext, arch: ArchetypeData, scripted: bool) -> void:
	var cfg := ctx.cfg
	var evt: Dictionary = ctx.events.get(EVT_RESIZING, {})
	if evt.is_empty():
		return
	var tel: Dictionary = evt.get("telegraph", {})
	if scripted:
		var stages: Array = []
		var signs: Array = tel.get("run1_signs", [])
		for i: int in signs.size():
			stages.append({"day": int(signs[i]["day"]), "text": signs[i]["text"], "prep": i + 1 == int(tel.get("prep_after_sign", 0))})
		s.chains.append({"event": EVT_RESIZING, "fire_day": int(tel["run1_fire_day"]), "stages": stages, "scripted": true})
		return
	if arch.layoff_interval_days <= 0:
		return
	var interval := arch.layoff_interval_days / WorkOdds.floor_mult(cfg.floor_event_step, s.floor_n())
	var fire := s.day + maxi(cfg.rumor_lead_days_max + 1, roundi(interval) + ctx.rng.randi_range(-arch.layoff_jitter_days, arch.layoff_jitter_days))
	var lead := ctx.rng.randi_range(cfg.rumor_lead_days_min, cfg.rumor_lead_days_max)
	s.chains.append({"event": EVT_RESIZING, "fire_day": fire, "scripted": false,
		"stages": [{"day": fire - lead, "text": tel.get("rumor", ""), "prep": true}]})


# ---------- rolls ----------

static func _rolls(s: SimState, ctx: SimContext, on_leave: bool, events: Array) -> void:
	if not s.employed or on_leave:
		_roll_random(s, ctx, events)
		return
	var cfg := ctx.cfg
	var inc: Dictionary = ctx.events.get(EVT_INCIDENT, {})
	if not inc.is_empty():
		var cooldown := int((inc["trigger"] as Dictionary).get("cooldown_days", 0))
		if s.day - s.last_incident_day >= cooldown:
			var p := WorkOdds.incident_p(cfg, s.codebase, s.floor_n(), EventPlan.threat_mult(ctx, s, inc))
			if ctx.rng.randf() < p:
				s.last_incident_day = s.day
				s.bump("incidents")
				_present_event(s, ctx, EVT_INCIDENT, events)
	_roll_random(s, ctx, events)
	for e: Dictionary in ctx.chain_events:
		var id: String = e["id"]
		if _has_chain(s, id) or s.day - int(s.event_last.get(id, -9999)) < int(e["cooldown"]):
			continue
		var evt: Dictionary = ctx.events[id]
		if not EventPlan.eligible(ctx, s, evt):
			continue
		var p2 := WorkOdds.random_event_p(cfg, float(e["per_year"]), s.floor_n(), EventPlan.threat_mult(ctx, s, evt))
		if ctx.rng.randf() < p2:
			s.event_last[id] = s.day
			var lead := ctx.rng.randi_range(cfg.rumor_lead_days_min, cfg.rumor_lead_days_max)
			var tel: Dictionary = evt.get("telegraph", {})
			s.chains.append({"event": id, "fire_day": s.day + lead, "scripted": false,
				"stages": [{"day": s.day + 1, "text": tel.get("rumor", ""), "prep": false}]})


static func _roll_random(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	for e: Dictionary in ctx.random_events:
		var id: String = e["id"]
		if s.day - int(s.event_last.get(id, -9999)) < int(e["cooldown"]):
			continue
		var evt: Dictionary = ctx.events[id]
		if not EventPlan.eligible(ctx, s, evt):
			continue
		var p := WorkOdds.random_event_p(cfg, float(e["per_year"]), s.floor_n(), EventPlan.threat_mult(ctx, s, evt))
		if ctx.rng.randf() < p:
			_present_event(s, ctx, id, events)


static func _has_chain(s: SimState, evt_id: String) -> bool:
	for ch: Dictionary in s.chains:
		if ch["event"] == evt_id:
			return true
	return false


# ---------- the review (GDD 5.16) ----------

static func _queue_review(s: SimState, ctx: SimContext, arch: ArchetypeData, events: Array) -> void:
	var cfg := ctx.cfg
	s.next_review = s.day + arch.review_cadence_days
	var evidence := WorkOdds.evidence(cfg, s.mo, s.on_time_since_review, s.h_brag)
	s.queue.append({"kind": "review", "evidence": evidence, "calibration": arch.calibration_hp})
	s.event_last[EVT_REVIEW] = s.day
	s.bump("reviews")
	events.append({"kind": "review", "evidence": evidence, "calibration": arch.calibration_hp})


static func _resolve_review(s: SimState, ctx: SimContext, item: Dictionary, evidence_left: float, events: Array) -> void:
	if not s.employed:
		return
	var cfg := ctx.cfg
	var arch := ctx.archetype(s.job_archetype)
	var evidence: float = item["evidence"]
	var rating := WorkOdds.rating(cfg, evidence, clampf(evidence_left, 0.0, evidence))
	s.below_streak = s.below_streak + 1 if rating == WorkOdds.BELOW else 0
	s.rating_streak = s.rating_streak + 1 if rating >= arch.promotion_min_rating else 0
	var raise := WorkOdds.raise_for(cfg, rating)
	s.job_salary *= 1.0 + raise
	var promoted := WorkOdds.promotes(arch, rating, s.rating_streak, s.level)
	if promoted:
		s.level += 1
		s.job_salary = maxf(s.job_salary, WorkOdds.offer_salary(cfg, arch, s.level, s.floor_n(), 0))
		s.rating_streak = 0
		s.bump("promotions")
	s.on_time_since_review = 0
	s.push_back_used = false
	if s.below_streak >= 2 and s.pip_end < 0:
		s.pip_end = s.day + cfg.pip_days
		events.append({"kind": "pip_started", "ends": s.pip_end})
	s.bump("rating_%s" % WorkOdds.RATINGS[rating])
	events.append({"kind": "review_result", "rating": rating, "raise": raise, "promoted": promoted})
	_log(s, ctx, "review", {"rating": rating, "promoted": promoted})
	var tip := String(((ctx.events[EVT_REVIEW] as Dictionary).get("ducky", {}) as Dictionary).get("tip", "none"))
	if tip != "none" and not s.tips_seen.has(tip):
		s.tips_seen.append(tip)
		events.append({"kind": "tip", "id": tip, "event": EVT_REVIEW})
	if (raise > 0.0 or promoted) and s.home < cfg.home_rent_k.size() - 1:
		_present_event(s, ctx, EVT_LIFESTYLE, events)


# ---------- the job hunt (GDD 5.20) ----------

static func _hunt(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	if s.day - s.board_day >= cfg.board_refresh_days:
		_refresh_board(s, ctx)
	var i := 0
	while i < s.applications.size():
		var app: Dictionary = s.applications[i]
		var status: String = app["status"]
		if status == "wait" and s.day >= int(app["reply"]):
			if bool(app["callback"]):
				app["status"] = "callback"
				events.append({"kind": "callback", "company": app["posting"]["company"], "interview": app["interview"]})
			else:
				s.applications.remove_at(i)
				events.append({"kind": "rejected", "company": app["posting"]["company"]})
				continue
		elif status == "callback" and s.day >= int(app["interview"]):
			_start_duel(s, ctx, app, events)
		elif status == "between" and s.day >= int(app["next_duel"]):
			_start_duel(s, ctx, app, events)
		i += 1


static func _start_duel(s: SimState, ctx: SimContext, app: Dictionary, events: Array) -> void:
	var cfg := ctx.cfg
	var posting: Dictionary = app["posting"]
	var arch := ctx.archetype(String(posting["archetype"]))
	var tier: TierData = ctx.tiers.get(String(arch.duel_tier)) as TierData
	var request := {
		"composure": WorkOdds.duel_composure(cfg, ctx.bg.composure_max, s.burnout),
		"meter_mult": WorkOdds.duel_zone_mult(cfg, s.skill, s.rust),
		"doubt_hp": WorkOdds.duel_doubt(cfg, tier.doubt_hp, int(posting["floor"])),
		"floor": int(posting["floor"]), "archetype": String(arch.id), "tier": String(arch.duel_tier),
		"unlocked_options": [], "rounds": cfg.review_prompts + 2,
	}
	app["status"] = "duel"
	s.queue.append({"kind": "duel", "app": int(posting["id"]), "index": int(app["duels_done"]), "of": arch.duels_per_offer, "request": request})
	s.bump("interviews")
	events.append({"kind": "interview", "company": posting["company"]})


static func _resolve_duel(s: SimState, ctx: SimContext, item: Dictionary, passed: bool, events: Array) -> void:
	var cfg := ctx.cfg
	s.rust = 0.0
	var app := _find_app(s, int(item["app"]))
	if app.is_empty():
		return
	if not passed:
		_drop_application(s, int(item["app"]))
		s.bump("interviews_failed")
		events.append({"kind": "interview_failed", "company": app["posting"]["company"]})
		return
	var done := int(app["duels_done"]) + 1
	app["duels_done"] = done
	if done >= int(item["of"]):
		app["status"] = "offer"
		s.queue.append({"kind": "offer", "app": int(item["app"]), "posting": app["posting"]})
		s.bump("offers")
		events.append({"kind": "offer", "company": app["posting"]["company"]})
	else:
		app["status"] = "between"
		app["next_duel"] = s.day + ctx.rng.randi_range(cfg.interview_days_min, cfg.interview_days_max)


static func _find_app(s: SimState, app_id: int) -> Dictionary:
	for app: Dictionary in s.applications:
		if int(app["posting"]["id"]) == app_id:
			return app
	return {}


## The application for a posting id ({} when it is gone): the adapter reads the posting a duel or an offer is about.
static func find_application(s: SimState, app_id: int) -> Dictionary:
	return _find_app(s, app_id)


static func _drop_application(s: SimState, app_id: int) -> void:
	for i: int in s.applications.size():
		if int(s.applications[i]["posting"]["id"]) == app_id:
			s.applications.remove_at(i)
			return


## E18: a recruiter's posting skips the board and the callback and goes straight to an interview 3-7 days out.
static func _recruiter_application(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	if s.employed and s.jobs_held >= cfg.max_jobs:
		return
	var posting := _gen_posting(s, ctx)
	var interview := s.day + ctx.rng.randi_range(cfg.interview_days_min, cfg.interview_days_max)
	s.applications.append({"posting": posting, "applied": s.day, "reply": s.day, "callback": true, "interview": interview,
		"status": "callback", "duels_done": 0, "next_duel": -1})
	events.append({"kind": "recruiter_posting", "company": posting["company"], "interview": interview})


## How many references you can give: each coworker, past or present, at Rapport 60 or more (the board's callback odds).
static func references(s: SimState, cfg: WorkConfig) -> int:
	return _references(s, cfg)


static func _references(s: SimState, cfg: WorkConfig) -> int:
	var n := 0
	for cw: Dictionary in s.coworkers:
		if float(cw["rapport"]) >= cfg.reference_rapport:
			n += 1
	for cw: Dictionary in s.past_coworkers:
		if float(cw["rapport"]) >= cfg.reference_rapport:
			n += 1
	return n


# ---------- the board ----------

static func _refresh_board(s: SimState, ctx: SimContext) -> void:
	var cfg := ctx.cfg
	s.board.clear()
	for i: int in cfg.board_size + (cfg.edge_take_call_postings if s.h_take_call else 0):
		s.board.append(_gen_posting(s, ctx))
	s.board_day = s.day


## One posting, with its rolls in a fixed order: archetype, level, remote, the three clauses, the company.
static func _gen_posting(s: SimState, ctx: SimContext) -> Dictionary:
	var cfg := ctx.cfg
	var total := 0.0
	for id: String in ctx.arch_ids:
		total += ctx.archetype(id).board_weight
	var r := ctx.rng.randf() * total
	var arch: ArchetypeData = ctx.archetype(ctx.arch_ids[ctx.arch_ids.size() - 1])
	for id: String in ctx.arch_ids:
		r -= ctx.archetype(id).board_weight
		if r < 0.0:
			arch = ctx.archetype(id)
			break
	var lr := ctx.rng.randf()
	var level := s.level
	if lr < cfg.posting_level_weights[0]:
		level = maxi(0, s.level - 1)
	elif lr >= 1.0 - cfg.posting_level_weights[2]:
		level = mini(WorkOdds.SENIOR, s.level + 1)
	var floor_n := mini(s.jobs_held + 1, cfg.max_jobs)
	var remote := ctx.rng.randf() < arch.remote_share
	var clauses: Array = []
	var in_writing := ctx.rng.randf() < cfg.clause_remote_in_writing_p
	var on_call := ctx.rng.randf() < cfg.clause_on_call_p
	var pto := ctx.rng.randf() < cfg.clause_unlimited_pto_p
	if remote and in_writing:
		clauses.append("remote_in_writing")
	if on_call:
		clauses.append("on_call")
	if pto:
		clauses.append("unlimited_pto")
	var company := ""
	var pool: PackedStringArray = arch.company_ids
	if not pool.is_empty():
		var start := ctx.rng.randi_range(0, pool.size() - 1)
		company = pool[start]
		for k: int in pool.size():
			var candidate := pool[(start + k) % pool.size()]
			if not s.blacklist.has(candidate) and candidate != s.job_company:   # nobody posts a job at the company you already work for
				company = candidate
				break
	var id_n := s.next_posting_id
	s.next_posting_id += 1
	return {"id": id_n, "company": company, "archetype": String(arch.id), "level": level, "floor": floor_n,
		"salary": WorkOdds.offer_salary(cfg, arch, level, floor_n, s.scar_resume_gap), "remote": remote,
		"clauses": clauses, "posted": s.day}


# ---------- jobs (GDD 3.3) ----------

static func _start_job(s: SimState, ctx: SimContext, posting: Dictionary, events: Array, scripted: bool) -> void:
	var cfg := ctx.cfg
	var arch := ctx.archetype(String(posting["archetype"]))
	s.jobs_held += 1
	s.employed = true
	s.unemployed_since = -1
	s.studies_this_spell = 0
	s.gap_scar_given = false
	s.job_company = String(posting["company"])
	s.job_archetype = String(arch.id)
	s.job_salary = float(posting["salary"])
	s.job_start = s.day
	s.job_remote = bool(posting["remote"])
	s.job_clauses = (posting.get("clauses", []) as Array).duplicate()
	s.job_flags = []
	s.commute_burnout = 0.0
	s.living_mult = 1.0
	s.leave_end = -1
	s.layoff_known_day = -1
	if int(posting["level"]) > s.level:
		s.level = int(posting["level"])
		events.append({"kind": "promoted_on_hire", "level": s.level})
	s.mo = 0.0
	if s.scar_bad_reference > 0:
		if _references(s, cfg) > 0:
			events.append({"kind": "reference_cleared"})
		else:
			s.mo = cfg.bad_reference_mo * s.scar_bad_reference
		s.scar_bad_reference = 0
	s.codebase = clampf(arch.codebase_start + cfg.corner_cutter_codebase * s.scar_corner_cutter, 0.0, cfg.stat_max)
	s.quality = WorkOdds.QUALITY_BALANCED
	s.next_review = s.day + arch.review_cadence_days
	s.on_time_since_review = 0
	s.below_streak = 0
	s.rating_streak = 0
	s.pip_end = -1
	s.push_back_used = false
	s.speed_mod_until = -1
	s.hours_lock_until = -1
	s.applications.clear()
	s.coworkers = _make_coworkers(s, ctx, arch, scripted)
	s.chains = []
	_schedule_resizing(s, ctx, arch, scripted and s.run_number == 1)
	_new_ticket(s, ctx)
	_refresh_board(s, ctx)
	s.bump("jobs")
	events.append({"kind": "job_started", "company": s.job_company, "archetype": s.job_archetype, "floor": s.jobs_held, "level": s.level})
	_log(s, ctx, "job", {"company": s.job_company, "floor": s.jobs_held})


## The people you work with: run 1's authored four, or floor_size - 1 generated ones with a level and a salary.
static func _make_coworkers(s: SimState, ctx: SimContext, arch: ArchetypeData, scripted: bool) -> Array:
	var cfg := ctx.cfg
	var out: Array = []
	if scripted and s.run_number == 1:
		var ids: Array = ctx.coworker_defs.keys()
		ids.sort()
		for id: String in ids:
			var def: Dictionary = ctx.coworker_defs[id]
			var lvl := WorkOdds.LEVELS.find(String(def["level"]))
			out.append({"id": id, "name": def["name"], "level": lvl, "salary": WorkOdds.offer_salary(cfg, arch, lvl, s.floor_n(), 0),
				"rapport": cfg.coworker_rapport_start})
		return out
	for i: int in maxi(0, arch.floor_size - 1):
		var r := ctx.rng.randf()
		var lvl := cfg.coworker_level_weights.size() - 1
		var acc := 0.0
		for k: int in cfg.coworker_level_weights.size():
			acc += cfg.coworker_level_weights[k]
			if r < acc:
				lvl = k
				break
		var noise := 1.0 + cfg.coworker_salary_noise * (ctx.rng.randf() * 2.0 - 1.0)
		out.append({"id": "cw_gen_%d" % i, "level": lvl,
			"salary": WorkOdds.offer_salary(cfg, arch, lvl, s.floor_n(), 0) * noise, "rapport": cfg.coworker_rapport_start})
	return out


## The job ends: reason is "layoff", "fired" or "quit". Accrued pay and severance are paid out, the Scars are
## handed out, a title-inflating archetype takes a level, and losing job max_jobs ends the run (D-16).
static func _end_job(s: SimState, ctx: SimContext, reason: String, events: Array, severance_months: float) -> void:
	if not s.employed:
		return
	var cfg := ctx.cfg
	var arch := ctx.archetype(s.job_archetype)
	var tenure := s.day - s.job_start
	var company := s.job_company
	s.savings += s.pay_accrued + severance_months * s.job_salary
	s.pay_accrued = 0.0
	if reason != "layoff" and tenure < cfg.short_tenure_days:
		s.scar_short_tenure = mini(s.scar_short_tenure + 1, cfg.scar_max_stacks)
	if reason == "fired" or (reason == "quit" and s.mo < cfg.bad_reference_quit_mo):
		s.scar_bad_reference = mini(s.scar_bad_reference + 1, cfg.scar_max_stacks)
	if s.level >= WorkOdds.SENIOR and s.codebase >= cfg.corner_cutter_leave_codebase:
		s.scar_corner_cutter = mini(s.scar_corner_cutter + 1, cfg.scar_max_stacks)
	for cw: Dictionary in s.coworkers:
		if float(cw["rapport"]) >= cfg.reference_rapport:
			s.past_coworkers.append({"id": cw["id"], "rapport": cw["rapport"]})
	s.level = maxi(0, s.level - arch.leave_level_drop)
	s.employed = false
	s.unemployed_since = s.day
	s.studies_this_spell = 0
	s.gap_scar_given = false
	s.job_company = ""
	s.job_archetype = ""
	s.job_salary = 0.0
	s.job_clauses = []
	s.job_flags = []
	s.commute_burnout = 0.0
	s.coworkers = []
	s.chains = []
	s.pip_end = -1
	s.leave_end = -1
	s.living_mult = 1.0
	s.ticket_progress = 0.0
	s.speed_mod_until = -1
	s.hours_lock_until = -1
	_drop_job_cards(s)
	s.bump("exit_%s" % reason)
	events.append({"kind": "job_ended", "reason": reason, "tenure": tenure, "severance_months": severance_months, "company": company})
	_log(s, ctx, "exit", {"reason": reason, "tenure": tenure})
	if s.jobs_held >= cfg.max_jobs:
		_end_run(s, ctx, "career_change", events)


## A review or a ticket pick belongs to the job that just ended: its card goes with it.
static func _drop_job_cards(s: SimState) -> void:
	var i := 0
	while i < s.queue.size():
		var kind := String((s.queue[i] as Dictionary).get("kind", ""))
		if kind == "review" or kind == "ticket_pick":
			s.queue.remove_at(i)
		else:
			i += 1


static func _end_run(s: SimState, ctx: SimContext, ending: String, events: Array) -> void:
	if s.ended:
		return
	s.ended = true
	s.ending = ending
	s.queue.clear()
	events.append({"kind": "ending", "ending": ending})
	_log(s, ctx, "ending", {"ending": ending})


# ---------- the checks ----------

static func _checks(s: SimState, ctx: SimContext, on_leave: bool, events: Array) -> void:
	var cfg := ctx.cfg
	var day := s.day
	if s.employed:
		if s.burnout >= cfg.burnout_max and not on_leave:
			_forced_leave(s, ctx, events)
		if s.pip_end >= 0 and day >= s.pip_end:
			s.pip_end = -1
			s.below_streak = 0
			if s.mo < cfg.pip_mo_min:
				_end_job(s, ctx, "fired", events, 0.0)
			else:
				events.append({"kind": "pip_cleared"})
		if s.employed and s.scar_short_tenure > 0 and day - s.job_start >= cfg.short_tenure_clear_days:
			s.scar_short_tenure = 0
		if s.employed and s.scar_corner_cutter > 0 and s.codebase < cfg.corner_cutter_clear_codebase:
			s.scar_corner_cutter = 0
	elif s.unemployed_since >= 0 and not s.gap_scar_given and day - s.unemployed_since > cfg.resume_gap_days:
		s.gap_scar_given = true
		if s.studies_this_spell < cfg.studies_prevent_gap:
			s.scar_resume_gap = mini(s.scar_resume_gap + 1, cfg.scar_max_stacks)
			events.append({"kind": "scar", "id": "resume_gap"})
	if s.burnout <= cfg.burnout_history_calm:
		s.calm_days += 1
		if s.scar_burnout_history > 0 and s.calm_days >= cfg.burnout_history_clear_days:
			s.scar_burnout_history -= 1
			s.calm_days = 0
	else:
		s.calm_days = 0
	for i: int in cfg.burnout_warnings.size():
		var at: float = cfg.burnout_warnings[i]
		if s.warn_armed[i] and s.burnout >= at:
			s.warn_armed[i] = false
			events.append({"kind": "burnout_warning", "level": i})
		elif not s.warn_armed[i] and s.burnout < at - cfg.burnout_warning_rearm:
			s.warn_armed[i] = true
	var hold_ok := s.employed and WorkOdds.studio_count(cfg, s.level, s.job_remote, s.home, s.burnout, s.savings, s.living_cost * s.living_mult) == 5
	if hold_ok:
		s.studio_hold += 1
		if s.studio_hold >= cfg.studio_days:
			_end_run(s, ctx, "studio", events)
			return
	elif s.studio_hold > 0:
		s.studio_hold = 0
		events.append({"kind": "studio_broken"})
	if s.ended:
		return
	if s.below_zero_days >= cfg.plan_b_days:
		_end_run(s, ctx, "plan_b", events)
	elif day >= cfg.legacy_day:
		_end_run(s, ctx, "legacy", events)


## Burnout hit 100: an interrupt, not an exit (GDD 3.3). The first costs a Burnout History Scar and 30 days at half
## pay with the job kept; the second ends the run.
static func _forced_leave(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	s.forced_leaves += 1
	s.bump("forced_leaves")
	if s.forced_leaves >= 2:
		_end_run(s, ctx, "burnout", events)
		return
	s.scar_burnout_history = mini(s.scar_burnout_history + 1, cfg.scar_max_stacks)
	s.leave_end = s.day + cfg.forced_leave_days
	s.ticket_deadline += cfg.forced_leave_days
	s.burnout = maxf(cfg.forced_leave_burnout, _burnout_floor(s, cfg))
	s.queue.append({"kind": "forced_leave", "days": cfg.forced_leave_days})
	events.append({"kind": "forced_leave"})


# ---------- the run log (RC-26) ----------

static func _log(s: SimState, ctx: SimContext, kind: String, data: Dictionary) -> void:
	if not ctx.log_enabled:
		return
	var entry := {"d": s.day, "k": kind}
	entry.merge(data)
	s.log.append(entry)
```

### 17.19 The work state's core: pure classes in core/ (Step 15)

`core/work_clock.gd`:

```gdscript
@tool
class_name WorkClock
extends RefCounted
## The work state's clock (GDD 5.14, DECISIONS D-01, D-13; INV-22): frame time in, whole days out. Pause is 0 days a
## second; 1x, 2x and 4x are WorkConfig.speeds (days per second). It never reads the wall clock: the scene hands it
## its frame delta, and only while nothing is open over the work state (a card, an app, Pause). It rules nothing;
## Sim.step does, one call per day.

## One hitch (a dropped frame, the editor stalling) must never fast-forward a month.
const MAX_DAYS_PER_FRAME := 4
const PAUSE := 0

## 0 is Pause; 1.. picks WorkConfig.speeds[speed - 1].
var speed: int = PAUSE
var _carry: float = 0.0


## The speed control's position count: Pause plus one per WorkConfig speed.
static func speed_count(cfg: WorkConfig) -> int:
	return cfg.speeds.size() + 1


## Days per second at this position (0 for Pause or an unknown position).
func days_per_second(cfg: WorkConfig) -> float:
	if speed <= PAUSE or speed > cfg.speeds.size():
		return 0.0
	return float(cfg.speeds[speed - 1])


func set_speed(position: int, cfg: WorkConfig) -> void:
	speed = clampi(position, PAUSE, cfg.speeds.size())
	_carry = 0.0


func is_running() -> bool:
	return speed > PAUSE


## The whole days to run for this frame. The fraction carries to the next frame, so 1x is one day a second on
## average whatever the frame rate; at most MAX_DAYS_PER_FRAME come out at once.
func advance(cfg: WorkConfig, delta: float) -> int:
	var rate := days_per_second(cfg)
	if rate <= 0.0 or delta <= 0.0:
		return 0
	_carry += delta * rate
	var whole := int(_carry)
	_carry -= float(whole)   # only the fraction carries: the days over the cap are dropped, not queued
	return mini(whole, MAX_DAYS_PER_FRAME)


## A card, an app or Pause opened: the half-built day is thrown away, so the clock restarts from zero when it comes back.
func hold() -> void:
	_carry = 0.0
```

`core/work_hud.gd`:

```gdscript
@tool
class_name WorkHud
extends RefCounted
## What the work state's top band shows, as numbers and text ids (GDD 5.16, 4.6): the four numbers (Runway, Burnout,
## Ticket, the Codebase's 10 LEDs), the Studio chip and the 60-day calendar strip. Pure, like WorkOdds: it reads a
## SimState and changes nothing, so the scene only draws what it is told (INV-03) and a test can check each number.

const LED_COUNT := 10
const LED_STEP := 10.0   # one LED turns red per 10 Codebase points

const CAL_IDS: Dictionary = {
	"payday": "ui_cal_payday", "rent": "ui_cal_rent", "review": "ui_cal_review",
	"interview": "ui_cal_interview", "deadline": "ui_cal_deadline", "lease": "ui_cal_lease",
}
const LEVEL_IDS: PackedStringArray = ["ui_level_junior", "ui_level_mid", "ui_level_senior"]
const HOME_IDS: PackedStringArray = ["ui_home_shared", "ui_home_one_bed", "ui_home_studio", "ui_home_penthouse"]


## Rent plus living costs for a month, in k$ (what the Runway chip divides by).
static func monthly_bills(s: SimState) -> float:
	return s.rent + s.living_cost * s.living_mult


## Months of bills the savings cover, never below zero.
static func runway_months(s: SimState) -> float:
	return maxf(0.0, WorkOdds.runway_months(s.savings, s.rent, s.living_cost * s.living_mult))


## The chip turns red under runway_red_months. The number always shows too, so colour is never the only signal.
static func runway_is_red(s: SimState, cfg: WorkConfig) -> bool:
	return runway_months(s) < cfg.runway_red_months


## "4.2": the {months} of ui_runway.
static func runway_text(s: SimState) -> String:
	return "%.1f" % runway_months(s)


## Burnout as a 0..1 bar fill.
static func burnout_frac(s: SimState, cfg: WorkConfig) -> float:
	return clampf(s.burnout / cfg.burnout_max, 0.0, 1.0)


## The server rack: how many of the 10 LEDs are red (one per 10 Codebase points).
static func codebase_red_leds(s: SimState) -> int:
	return clampi(floori(s.codebase / LED_STEP), 0, LED_COUNT)


## The ticket's progress as a 0..1 bar fill. Between jobs there is no ticket.
static func ticket_frac(s: SimState) -> float:
	if not s.employed:
		return 0.0
	return clampf(s.ticket_progress / 100.0, 0.0, 1.0)


## Days to the ticket's deadline; negative when it is late. 0 between jobs.
static func ticket_days_left(s: SimState) -> int:
	return s.ticket_deadline - s.day if s.employed else 0


static func ticket_is_late(s: SimState) -> bool:
	return s.employed and s.day > s.ticket_deadline


## How many of the Studio's five conditions hold now (the chip's "Studio 3/5").
static func studio_count(s: SimState, cfg: WorkConfig) -> int:
	return WorkOdds.studio_count(cfg, s.level, s.job_remote, s.home, s.burnout, s.savings, s.living_cost * s.living_mult)


static func hours_label_id(notch: int) -> String:
	return "ui_hours_%d" % clampi(notch, 1, 5)


static func level_label_id(level: int) -> String:
	return LEVEL_IDS[clampi(level, 0, LEVEL_IDS.size() - 1)]


static func home_label_id(home: int) -> String:
	return HOME_IDS[clampi(home, 0, HOME_IDS.size() - 1)]


## The speed control's label id for a position: 0 is Pause, then one per WorkConfig speed ("1x", "2x", "4x").
static func speed_label_id(position: int, cfg: WorkConfig) -> String:
	if position <= WorkClock.PAUSE or position > cfg.speeds.size():
		return "ui_speed_pause"
	return "ui_speed_%d" % cfg.speeds[position - 1]


## The calendar strip (GDD 5.14): what is coming in the next calendar_days days, as {offset, kind, label_id} with
## offset 1..calendar_days from today. Several things on one day stay as separate entries.
static func calendar(ctx: SimContext, s: SimState) -> Array:
	var out: Array = []
	for item: Dictionary in EventPlan.calendar(ctx, s, ctx.cfg.calendar_days):
		var kind: String = item["kind"]
		out.append({"offset": int(item["day"]) - s.day, "kind": kind, "label_id": String(CAL_IDS.get(kind, ""))})
	return out


## The next thing on the calendar (for a text line under the strip), or {} when the strip is empty.
static func next_on_calendar(ctx: SimContext, s: SimState) -> Dictionary:
	var items := calendar(ctx, s)
	return items[0] if not items.is_empty() else {}
```

`core/work_cards.gd`:

```gdscript
@tool
class_name WorkCards
extends RefCounted
## What the work state shows over the clock (GDD 4.6, 5.19; ARCHITECTURE 19.7), built from the sim's events and its
## queue as plain data. Pure, like WorkHud: the scene only draws these dictionaries and sends the player's answer back.
## A card carries ids and numbers, never text, so the words stay in the JSON (INV-15) and a test can check each one.
##
## Notices: something to read, with OK. The clock waits until it is dismissed (INV-22). Styles: info, warning and
##   ducky (a tip). Fields by what they name: "literal" (a line the data already carries, a rumor), "id" (a barks id),
##   "event" (a work_events entry), "tip", plus the numbers its text needs.
## Feed lines: one quiet line in the Body (payday, rent, a shipped ticket, a rumor), no pause.
## Head cards: the sim's queue head, which the player must answer: an event with choices, a review, a Mid's ticket
##   pick, the forced leave, an interview day (Start leads to the duel screen: DuelAdapter). The layoff scene is the
##   LAYOFF phase's, and an offer is answered on the contract screen.

const INFO := "info"
const WARNING := "warning"
const DUCKY := "ducky"

const K_EVENT := "event"
const K_REVIEW := "review"
const K_PICK := "ticket_pick"
const K_LEAVE := "forced_leave"
const K_DUEL := "duel"
const K_OFFER := "offer"

const BURNOUT_WARN_IDS: PackedStringArray = ["ui_burnout_warn_60", "ui_burnout_warn_70", "ui_burnout_warn_75"]
const FEED_MAX := 8


static func notice(style: String, fields: Dictionary) -> Dictionary:
	var out: Dictionary = {"kind": "notice", "style": style}
	out.merge(fields)
	return out


## The notices a step's (or an input's) events leave to read, in order.
static func notices_from(events: Array, s: SimState, ctx: SimContext) -> Array:
	var out: Array = []
	for e: Dictionary in events:
		match String(e.get("kind", "")):
			"rumor":
				out.append(notice(INFO, {"literal": String(e["text"])}))
			"burnout_warning":
				out.append(notice(WARNING, {"id": BURNOUT_WARN_IDS[clampi(int(e["level"]), 0, BURNOUT_WARN_IDS.size() - 1)]}))
			"auto_resolved":
				out.append(notice(WARNING, {"id": "ui_auto_resolved", "event": String(e["id"]), "choice": String(e["choice"])}))
			"review_result":
				out.append(notice(INFO, {
					"event": Sim.EVT_REVIEW, "rating": WorkOdds.RATINGS[int(e["rating"])],
					"raise_pct": roundi(float(e["raise"]) * 100.0), "promoted": bool(e["promoted"]), "level": s.level}))
			"pip_started":
				out.append(notice(WARNING, {"id": "ui_pip"}))
			"tip":
				out.append(notice(DUCKY, {"tip": String(e["id"])}))
			"resizing_survived":
				out.append(notice(INFO, {"id": "ui_resizing_survived", "n": int(e["cuts"])}))
			"callback":   # a reply with an interview day (GDD 5.20, A92): a notice; the day is on the calendar strip too
				out.append(notice(INFO, {"id": "ui_callback_notice", "company": String(e["company"]), "day": int(e["interview"])}))
			"recruiter_posting":
				out.append(notice(INFO, {"id": "ui_recruiter_posting", "company": String(e["company"]), "day": int(e["interview"])}))
			"profile_noticed":
				out.append(notice(WARNING, {"id": "ui_profile_noticed"}))
			"event":
				if (e.get("choices", []) as Array).is_empty():  # no choices: it only needs reading, if it pauses at all
					var evt: Dictionary = ctx.events.get(String(e["id"]), {})
					if bool(evt.get("pause", false)):
						out.append(notice(INFO, {"event": String(e["id"])}))
	return out


## The quiet lines a step's events leave in the Body: {day, file, id, field, args, literal} (a line is its literal text, or
## the text at file/id/field with its args).
static func feed_from(events: Array, s: SimState) -> Array:
	var out: Array = []
	for e: Dictionary in events:
		match String(e.get("kind", "")):
			"payday":
				out.append(line(s.day, "work_events", "evt_e01_payday", "text", {"money_k": float(e["amount"])}))
			"rent":
				out.append(line(s.day, "work_events", "evt_e01_payday", "text_rent", {"money_k": float(e["amount"])}))
			"ticket_shipped":
				out.append(line(s.day, "barks", "ui_feed_shipped" if bool(e["on_time"]) else "ui_feed_late", "", {}))
			"rumor":
				out.append({"day": s.day, "literal": String(e["text"])})
			"resizing_survived":
				out.append(line(s.day, "barks", "ui_resizing_survived", "", {"n": int(e["cuts"])}))
			"application_sent":
				out.append(line(s.day, "barks", "ui_applied_feed", "", {"company": String(e["company"])}))
			"rejected":
				out.append(line(s.day, "barks", "ui_rejected_feed", "", {"company": String(e["company"])}))
			"interview_failed":
				out.append(line(s.day, "barks", "ui_interview_failed_feed", "", {"company": String(e["company"])}))
			"offer_declined":
				out.append(line(s.day, "barks", "ui_offer_declined_feed", "", {"company": String(e["company"])}))
			"job_started":
				out.append(line(s.day, "barks", "ui_job_started_feed", "", {"company": String(e["company"])}))
			"studied":
				out.append(line(s.day, "barks", "ui_studied_feed", "", {}))
	return out


static func line(day: int, file: String, id: String, field: String, args: Dictionary) -> Dictionary:
	return {"day": day, "file": file, "id": id, "field": field, "args": args}


## The card the sim is waiting on, or {} when time can run (or when only the LAYOFF phase's scene is waiting).
static func head(s: SimState, ctx: SimContext) -> Dictionary:
	var item := s.pending()
	match String(item.get("kind", "")):
		"event":
			var evt_id := String(item["id"])
			return {"kind": K_EVENT, "event": evt_id, "choices": (item["choices"] as Array).duplicate(),
				"args": event_args(evt_id, s, ctx)}
		"review":
			return {"kind": K_REVIEW, "event": Sim.EVT_REVIEW}
		"ticket_pick":
			return {"kind": K_PICK, "choices": Array(Sim.PICK_NAMES)}
		"forced_leave":
			return {"kind": K_LEAVE, "days": int(item["days"])}
		"duel":
			var app := Sim.find_application(s, int(item["app"]))
			return {"kind": K_DUEL, "company": String((app.get("posting", {}) as Dictionary).get("company", "")),
				"index": int(item["index"]), "of": int(item["of"])}
		"offer":
			return {"kind": K_OFFER}
	return {}


## Numbers an event's text may name: {money} is what its first money choice costs, {home} the next home tier up.
static func event_args(evt_id: String, s: SimState, ctx: SimContext) -> Dictionary:
	var money := 0.0
	var evt: Dictionary = ctx.events.get(evt_id, {})
	for choice: Dictionary in evt.get("choices", []):
		var eff: Dictionary = choice.get("effects", {})
		if eff.has("savings"):
			money = absf(float(eff["savings"]))
			break
	return {"money_k": money, "home": mini(s.home + 1, ctx.cfg.home_rent_k.size() - 1)}


## True when the sim's queue head is the layoff scene (the LAYOFF phase shows it).
static func is_layoff_pending(s: SimState) -> bool:
	return String(s.pending().get("kind", "")) == "layoff_scene"
```

`core/work_session.gd`:

```gdscript
@tool
class_name WorkSession
extends RefCounted
## One career run as the work state plays it (ARCHITECTURE 19.4, 19.7): the sim's state and context, the clock, the
## notices the player has yet to read, the quiet feed in the Body and the first-run coach marks. Pure, like Sim: no
## nodes, no autoloads and no wall clock (INV-03, INV-21, INV-22), so a test can play a whole job through it and a save
## round trip is checkable. GameState owns one, saves it and changes phases; the scene shows it and calls GameState
## verbs, which land here.
##
## Every player answer goes through Sim.apply_inputs, which does not tick: time moves only when tick() is called,
## which the scene does once a day while nothing is open. tick() refuses while a notice or a card is waiting.

const SAVE_VERSION := 2
const REVIEW_SEED_MIX := 7919
const COACH_SPEED := "coach_speed"
const COACH_HOURS := "coach_hours"
const COACH_STUDIO := "coach_studio"
const COACH_HOURS_FROM_DAY := 1    # once the clock has started
const COACH_STUDIO_FROM_DAY := 8

var sim: SimState
var ctx: SimContext
var clock: WorkClock = WorkClock.new()
var notices: Array = []         # to read, in order; the clock waits for each
var feed: Array = []            # the Body's quiet lines, newest last
var player_name: String = ""
var first_run: bool = false     # the first coach marks teach a run that has not been played before
var coach_closed: Array = []
var seen_questions: Array[String] = []   # interview questions asked, least to most recently (InterviewPlan.mark_seen)
var seen_review: Array[String] = []      # review prompts asked, the same way
var duel_checkpoint: Dictionary = {}     # the interview or review being played ({} when none): Continue resumes it
var dana_met: int = 0                    # interviews finished: Dana's greeting and her VS plate turn on it
var dana_last_company: String = ""
var laid_off_company: String = ""        # the company that just laid you off, until the next interview greets you
var gap_topics: Array = []               # the Self-Taught's weak topics (D-26), rolled at the start of the run
var board_hint: bool = false             # the work state opens the board by itself next time (after the layoff scene)


static func start(context: SimContext, run_number: int, run_seed: int, handbook: Array, name: String, first: bool,
		topics: Array = []) -> WorkSession:
	var session := WorkSession.new()
	session.ctx = context
	session.sim = Sim.new_run(context, run_number, run_seed, handbook)
	session.player_name = name
	session.first_run = first
	session.gap_topics = topics.duplicate()
	return session


## What to_save wrote ({version, phase, sim, ui}). The context has to be the one built for the run's background.
static func from_save(data: Dictionary, context: SimContext) -> WorkSession:
	var session := WorkSession.new()
	session.ctx = context
	session.sim = SimState.from_save(data.get("sim", {}))
	var ui: Dictionary = SimState.decode_value(data.get("ui", {}))
	session.notices = (ui.get("notices", []) as Array).duplicate(true)
	session.feed = (ui.get("feed", []) as Array).duplicate(true)
	session.player_name = String(ui.get("name", ""))
	session.first_run = bool(ui.get("first_run", false))
	session.coach_closed = (ui.get("coach_closed", []) as Array).duplicate()
	session.seen_questions.assign(ui.get("seen_questions", []))
	session.seen_review.assign(ui.get("seen_review", []))
	session.duel_checkpoint = (ui.get("duel_checkpoint", {}) as Dictionary).duplicate(true)
	session.dana_met = int(ui.get("dana_met", 0))
	session.dana_last_company = String(ui.get("dana_last_company", ""))
	session.laid_off_company = String(ui.get("laid_off_company", ""))
	session.gap_topics = (ui.get("gap_topics", []) as Array).duplicate()
	return session


## The save of record for this run: the sim exactly (SimState.to_save) and the screen's own state, encoded the same way so
## a float cannot come back one digit off. The clock's speed is not saved: Continue always waits, paused (KILL_TESTS 6).
func to_save(phase: int) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"phase": phase,
		"sim": sim.to_save(),
		"ui": SimState.encode_value({
			"notices": notices.duplicate(true), "feed": feed.duplicate(true), "name": player_name,
			"first_run": first_run, "coach_closed": coach_closed.duplicate(),
			"seen_questions": seen_questions.duplicate(), "seen_review": seen_review.duplicate(),
			"duel_checkpoint": duel_checkpoint.duplicate(true), "dana_met": dana_met,
			"dana_last_company": dana_last_company, "laid_off_company": laid_off_company, "gap_topics": gap_topics.duplicate(),
		}),
	}


# ---------- what blocks the clock ----------

## Something is open over the work state: a notice to read, or a card the sim waits on. The clock does not run (INV-22).
func is_blocked() -> bool:
	return not notices.is_empty() or sim.is_waiting()


## The card on top: the first notice, else the sim's queue head ({} when the layoff scene or nothing is waiting).
func current_card() -> Dictionary:
	if not notices.is_empty():
		return notices[0]
	return WorkCards.head(sim, ctx)


## The layoff scene waits for the LAYOFF phase once the notices before it are read.
func wants_layoff_scene() -> bool:
	return notices.is_empty() and WorkCards.is_layoff_pending(sim)


func is_over() -> bool:
	return sim.ended


# ---------- time ----------

## One day. Does nothing while a notice or a card is open, or after an ending. Returns the sim's events.
func tick() -> Array:
	if is_blocked() or sim.ended:
		return []
	var events: Array = Sim.step(sim, [], ctx)
	_take(events)
	return events


## Apply one input without ticking. Returns the sim's events (an input_rejected one when it did not apply).
func apply(input: Dictionary) -> Array:
	var events: Array = Sim.apply_inputs(sim, [input], ctx)
	_take(events)
	return events


func _take(events: Array) -> void:
	notices.append_array(WorkCards.notices_from(events, sim, ctx))
	feed.append_array(WorkCards.feed_from(events, sim))
	while feed.size() > WorkCards.FEED_MAX:
		feed.pop_front()
	for e: Dictionary in events:
		if String(e.get("kind", "")) == "job_ended":
			laid_off_company = String(e.get("company", "")) if String(e.get("reason", "")) == "layoff" else ""


# ---------- the player's answers ----------

func set_hours(notch: int) -> Array:
	return apply({"kind": Sim.IN_SET_HOURS, "notch": notch})


func choose(choice_id: String) -> Array:
	return apply({"kind": Sim.IN_CHOOSE, "choice": choice_id})


func pick_ticket(pick: String) -> Array:
	return apply({"kind": Sim.IN_TICKET_PICK, "pick": pick})


## The layoff scene's or the forced leave's OK. After the layoff scene the board opens by itself (GDD 4.5, A92).
func acknowledge() -> Array:
	var was_layoff := WorkCards.is_layoff_pending(sim)
	var events := apply({"kind": Sim.IN_ACK})
	if was_layoff:
		board_hint = true
	return events


## True once after the layoff scene: the work state opens the DoomApply board.
func take_board_hint() -> bool:
	var hint := board_hint
	board_hint = false
	return hint


## Apply to a posting on the board (Burnout +3 employed, +2 unemployed; a reply in 3-10 days).
func apply_to(posting_id: int) -> Array:
	return apply({"kind": Sim.IN_APPLY, "posting": posting_id})


## Study, once a day: Burnout +4, Rust -20, Skill +1 (R-JOB-05).
func study() -> Array:
	return apply({"kind": Sim.IN_STUDY})


## M2's review: the stand-in of GDD 5.16 (A67) on its own dice, seeded from the run seed and the day, so the sim's stream
## is never touched. M3 replaces this with the 3-prompt duel.
func resolve_review() -> Array:
	var item := sim.pending()
	if String(item.get("kind", "")) != "review":
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.rng_seed ^ (sim.day * REVIEW_SEED_MIX)
	var left := WorkOdds.review_standin_left(ctx.cfg, float(item["calibration"]), float(item["evidence"]), rng)
	return apply({"kind": Sim.IN_REVIEW_RESULT, "evidence_left": left})


# ---------- the duel and the contract (the adapter, GDD 5.20; DuelAdapter) ----------

## True when the sim waits on an interview or a review the player plays on the duel screen.
func wants_duel() -> bool:
	return ["duel", "review"].has(String(sim.pending().get("kind", "")))


## The checkpoint of the duel the sim waits on, built once and kept ({} when none waits). It travels in the save, so a
## Continue in the middle of an interview replays the same questions and the same luck (A55, A89). The prompts it picked
## join the questions already asked.
func begin_duel() -> Dictionary:
	if not duel_checkpoint.is_empty():
		return duel_checkpoint
	var item := sim.pending()
	match String(item.get("kind", "")):
		"duel":
			var app := Sim.find_application(sim, int(item["app"]))
			if app.is_empty():
				return {}
			var history := {"seen": seen_questions, "first_run": first_run, "met": dana_met,
				"last_company": dana_last_company, "after_layoff": not laid_off_company.is_empty()}
			duel_checkpoint = DuelAdapter.interview_checkpoint(item, app["posting"], sim.rng_seed, ctx, history)
			InterviewPlan.mark_seen(seen_questions, (duel_checkpoint["question_ids"] as Array) + [duel_checkpoint["warmup_id"]])
		"review":
			duel_checkpoint = DuelAdapter.review_checkpoint(item, sim, ctx, seen_review)
			InterviewPlan.mark_seen(seen_review, duel_checkpoint["question_ids"] as Array)
	return duel_checkpoint


## The interview ended. A win leads to the contract (the sim queues the offer), a loss ends the application. Dana
## remembers you either way.
func finish_duel(passed: bool, composure_left: float) -> Array:
	var company := String(duel_checkpoint.get("company_id", ""))
	duel_checkpoint = {}
	dana_met += 1
	dana_last_company = company
	laid_off_company = ""
	return apply(DuelAdapter.duel_result_input(passed, composure_left))


## The review duel ended with this much of your Evidence left (GDD 5.16): the sim rates it, raises you, maybe promotes.
func finish_review(evidence_left: float) -> Array:
	duel_checkpoint = {}
	return apply(DuelAdapter.review_result_input(evidence_left))


## True when the sim waits on an answer to an offer.
func wants_offer() -> bool:
	return String(sim.pending().get("kind", "")) == "offer"


## The contract paper of the offer on the table ({} when there is none).
func offer_paper() -> Dictionary:
	var item := sim.pending()
	if String(item.get("kind", "")) != "offer":
		return {}
	return DuelAdapter.offer_paper(item["posting"], ctx, sim.rng_seed)


## Accept (a voluntary exit when you hold a job) or Decline (the company is blacklisted). The OfferResult of GDD 5.20 is
## DuelAdapter.offer_result(accept, paper), for a caller that wants it.
func answer_offer(accept: bool) -> Array:
	var events := apply(DuelAdapter.offer_input(accept))
	if not accept:
		board_hint = true   # a declined offer sends you back to the board (GDD 4.5)
	return events


## For the tests and the autoplay: the interview goes badly.
func fail_interview() -> Array:
	duel_checkpoint = {}
	return apply(DuelAdapter.duel_result_input(false, 0.0))


## For the tests and the autoplay: decline the offer.
func decline_offer() -> Array:
	return answer_offer(false)


## Answer whatever is open in the simplest way: read a notice, take an event's first choice (careful: the last one that
## is not a quit, which is usually the cheaper one), resolve the review, pick a Feature ticket, acknowledge, skip an
## interview, decline an offer. For tests, the debug quick start and autoplay.
func answer_simply(careful: bool = false) -> void:
	var card := current_card()
	match String(card.get("kind", "")):
		"notice":
			dismiss_notice()
		WorkCards.K_EVENT:
			choose(_pick_choice(card["choices"] as Array, careful))
		WorkCards.K_REVIEW:
			resolve_review()
		WorkCards.K_PICK:
			pick_ticket("feature")
		WorkCards.K_LEAVE:
			acknowledge()
		WorkCards.K_DUEL:
			fail_interview()
		WorkCards.K_OFFER:
			decline_offer()
		_:
			acknowledge()   # whatever else the sim waits on (the layoff scene belongs to the LAYOFF phase)


static func _pick_choice(choices: Array, careful: bool) -> String:
	if careful:
		for i: int in range(choices.size() - 1, -1, -1):
			if not String(choices[i]).contains("quit"):
				return String(choices[i])
	return String(choices[0])


## Play on, answering every card carefully on the quietest Hours, until the layoff scene is next (or the run ends). Run
## 1's is on day 240. For the debug quick start: a patient player at notch 3 burns out long before then.
func play_to_layoff(max_steps: int = 20000) -> void:
	set_hours(1)
	var steps := 0
	while not wants_layoff_scene() and not sim.ended and steps < max_steps:
		steps += 1
		if is_blocked():
			answer_simply(true)
		else:
			tick()


## OK on the first notice.
func dismiss_notice() -> void:
	if not notices.is_empty():
		notices.pop_front()
		clock.hold()


# ---------- the first-run coach marks (GDD 4.3, spec gap settled at M2's huddle) ----------

## The coach mark to show now, or "" for none: one at a time, in order, on the first run only, never over a card. A
## mark is done when you do what it asks (start the clock, move the Hours) or tap it closed (D11).
func coach_id() -> String:
	if not first_run or is_blocked():
		return ""
	var hours_moved := int(sim.stats.get("hours_changes", 0)) > 0
	if not coach_closed.has(COACH_SPEED) and sim.day == 0 and not clock.is_running():
		return COACH_SPEED
	if not coach_closed.has(COACH_HOURS) and not hours_moved and sim.day >= COACH_HOURS_FROM_DAY:
		return COACH_HOURS
	if not coach_closed.has(COACH_STUDIO) and sim.day >= COACH_STUDIO_FROM_DAY and (hours_moved or coach_closed.has(COACH_HOURS)):
		return COACH_STUDIO
	return ""


func close_coach(id: String) -> void:
	if not id.is_empty() and not coach_closed.has(id):
		coach_closed.append(id)
```

### 17.20 The work state's and the layoff scene's screens: features/work/ and features/layoff/ (Step 15)

`features/work/work.gd`:

```gdscript
extends Control
## The work state (GDD 4.5, 4.6, 5.14; ARCHITECTURE 19.7): the career run on one screen, the cheapest it can be. From the
## top: the information band (Day and what is next, the Studio chip, Runway, Burnout, the Ticket and the Codebase's
## 10 LEDs, the 60-day calendar strip), the Body (a grey box with the job and the latest news until M5's diorama), and
## the thumb band: the Hours notches, the dock and Back beside the speed control. Cards (events, reviews, notices) come up
## over it in the ModalLayer and stop the clock. Rules live in the sim: this scene shows `GameState.session` and calls
## GameState's career_* verbs (INV-01, INV-03). The clock is `_process`: whole days, only while nothing is open (INV-22).

const FEED_SHOWN := 5
const BURNOUT_COLOR := Color(0.99607843, 0.68235296, 0.20392157)        # the PrimaryButton amber
const DANGER_COLOR := Color(0.89411765, 0.23137255, 0.26666668)          # the warning red (late ticket, red runway)
const TICKET_COLOR := Color(0.16, 0.68, 1.0)
const PICK_LABELS: Dictionary = {"feature": "ui_pick_feature", "bugfix": "ui_pick_bugfix", "paydown": "ui_pick_paydown"}
const APP_STUB_ID := "app_stub"

var _hours_buttons: Array[Button] = []
var _speed_buttons: Array[Button] = []
var _shown_signature := ""       # what the card sheet shows now, so a refresh never reopens (and re-locks) it
var _shown_card: Dictionary = {}
var _stub_open := false          # a dock app's "not in this build" card is open
var _board_open := false         # the DoomApply board replaces the Body and the thumb band; the clock waits (INV-22)

@onready var _next_label: Label = %NextLabel
@onready var _studio_label: Label = %StudioLabel
@onready var _runway_label: Label = %RunwayLabel
@onready var _burnout_label: Label = %BurnoutLabel
@onready var _burnout_bar: HpBar = %BurnoutBar
@onready var _ticket_label: Label = %TicketLabel
@onready var _ticket_bar: HpBar = %TicketBar
@onready var _ticket_days: Label = %TicketDays
@onready var _codebase_label: Label = %CodebaseLabel
@onready var _rack: CodebaseRack = %Rack
@onready var _strip: CalendarStrip = %Strip
@onready var _job_label: Label = %JobLabel
@onready var _feed: Label = %Feed
@onready var _coach: CoachMark = %Coach
@onready var _hours_label: Label = %HoursLabel
@onready var _back_button: Button = %BackButton
@onready var _dock_buttons: Array[Button] = [%JobsDock, %HomeDock, %VideoDock, %DuckyDock]
@onready var _card: EventCard = %EventCard
@onready var _board: BoardPanel = %Board
@onready var _body: PanelContainer = %Body
@onready var _thumb_band: VBoxContainer = %ThumbBand
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	if OS.is_debug_build() and GameState.session == null:
		GameState.debug_career_quick_start(false)   # project_run mode="custom": a fresh run 1 on day 0
	var cfg := GameState.session.ctx.cfg
	_hours_buttons.assign([%Hours1, %Hours2, %Hours3, %Hours4, %Hours5])
	_speed_buttons.assign([%Speed0, %Speed1, %Speed2, %Speed3])
	_burnout_bar.max_value = cfg.burnout_max
	_burnout_bar.fill_color = BURNOUT_COLOR
	_ticket_bar.max_value = 100.0
	_ticket_bar.fill_color = TICKET_COLOR
	_burnout_label.text = Content.text("barks", "ui_burnout")
	_ticket_label.text = Content.text("barks", "ui_ticket")
	_codebase_label.text = Content.text("barks", "ui_codebase")
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	for dock_id: Array in [[0, "ui_tab_jobs"], [1, "ui_tab_home"], [2, "ui_tab_video"], [3, "ui_tab_ducky"]]:
		_dock_buttons[dock_id[0]].text = Content.text("barks", dock_id[1])
		_dock_buttons[dock_id[0]].pressed.connect(_open_board if dock_id[0] == 0 else _open_stub_app)
	var hours_group := ButtonGroup.new()
	for i: int in _hours_buttons.size():
		_hours_buttons[i].button_group = hours_group
		_hours_buttons[i].pressed.connect(_on_hours_pressed.bind(i + 1))
	var speed_group := ButtonGroup.new()
	for i: int in _speed_buttons.size():
		_speed_buttons[i].button_group = speed_group
		_speed_buttons[i].text = Content.text("barks", WorkHud.speed_label_id(i, cfg))
		_speed_buttons[i].pressed.connect(_on_speed_pressed.bind(i))
	_back_button.pressed.connect(Device.handle_back)
	_card.answered.connect(_on_card_answered)
	_coach.closed.connect(GameState.career_close_coach)
	_board.apply_pressed.connect(GameState.career_apply)
	_board.study_pressed.connect(GameState.career_study)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	GameState.run_changed.connect(_refresh)
	_refresh()
	if GameState.session.take_board_hint():   # after the layoff scene the board opens by itself (GDD 4.5)
		_open_board.call_deferred()


## The clock (D-01, D-13; INV-22): whole days, one `career_tick` each, only while nothing is open over the work state
## and the scene is not changing. A tick that opens a card or leaves for another phase ends the frame's days.
func _process(delta: float) -> void:
	var session := GameState.session
	if session == null or GameState.run.phase != GameFlow.Phase.WORK:
		return
	if session.is_blocked() or _card.is_open() or _stub_open or _board_open or _pause.is_open() or SceneRouter.busy:
		session.clock.hold()
		return
	for _day: int in session.clock.advance(session.ctx.cfg, delta):
		GameState.career_tick()
		if GameState.run.phase != GameFlow.Phase.WORK or session.is_blocked():
			break


## Back (the action bar's, Esc, Android): close a dock app's card or the board, resume from Pause, else open Pause. A
## card the player must answer stays; its "=" opens Pause too.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	if _stub_open:
		_close_stub_app()
		return true
	if _board_open:
		_close_board()
		return true
	GameState.save()   # opening Pause keeps the quiet days since the last save, in case the app is killed from here
	_pause.open()
	return true


# ---------- showing the run ----------

func _refresh() -> void:
	var session := GameState.session
	if session == null or GameState.run.phase != GameFlow.Phase.WORK:
		return
	var s := session.sim
	var ctx := session.ctx
	_refresh_top_band(s, ctx)
	_refresh_body(s)
	_refresh_controls(session)
	_refresh_card(session)
	_refresh_coach(session)
	if _board_open:
		_board.show_board(session)


func _refresh_top_band(s: SimState, ctx: SimContext) -> void:
	var cfg := ctx.cfg
	var next := WorkHud.next_on_calendar(ctx, s)
	if next.is_empty():
		_next_label.text = Content.text("barks", "ui_day", {"day": s.day})
	else:
		_next_label.text = Content.text("barks", "ui_next", {
			"day": s.day, "what": Content.text("barks", String(next["label_id"])), "days": int(next["offset"])})
	_studio_label.text = Content.text("barks", "ui_studio_chip", {"n": WorkHud.studio_count(s, cfg)})
	_runway_label.text = Content.text("barks", "ui_runway", {"months": WorkHud.runway_text(s)})
	_tint(_runway_label, DANGER_COLOR if WorkHud.runway_is_red(s, cfg) else Color.WHITE)
	_burnout_bar.value = s.burnout
	_burnout_bar.fill_color = DANGER_COLOR if s.burnout >= cfg.auto_resolve_from else BURNOUT_COLOR
	_ticket_bar.value = WorkHud.ticket_frac(s) * 100.0
	if s.employed:
		_ticket_days.text = "%dd" % WorkHud.ticket_days_left(s)
		_tint(_ticket_days, DANGER_COLOR if WorkHud.ticket_is_late(s) else Color.WHITE)
	else:
		_ticket_days.text = "-"
		_tint(_ticket_days, Color.WHITE)
	_rack.red = WorkHud.codebase_red_leds(s)
	_strip.set_items(WorkHud.calendar(ctx, s), cfg.calendar_days)


func _refresh_body(s: SimState) -> void:
	if s.employed:
		var company := Content.field("companies", s.job_company, "name")
		_job_label.text = Content.text("barks", "ui_job_line", {
			"level": Content.text("barks", WorkHud.level_label_id(s.level)), "company": company})
	else:
		_job_label.text = Content.text("barks", "ui_between_jobs")
	var lines: PackedStringArray = []
	var feed := GameState.session.feed
	for line: Dictionary in feed.slice(maxi(feed.size() - FEED_SHOWN, 0)):
		lines.append("D%d  %s" % [int(line["day"]), _feed_text(line)])
	_feed.text = "\n".join(lines)


func _refresh_controls(session: WorkSession) -> void:
	var s := session.sim
	_hours_label.text = "%s: %s" % [Content.text("barks", "ui_hours"), Content.text("barks", WorkHud.hours_label_id(s.hours))]
	var locked := s.day <= s.hours_lock_until
	for i: int in _hours_buttons.size():
		_hours_buttons[i].set_pressed_no_signal(i + 1 == s.hours)
		_hours_buttons[i].disabled = locked
	for i: int in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(i == session.clock.speed)


func _refresh_card(session: WorkSession) -> void:
	if _stub_open:
		return
	var card := session.current_card()
	if card.is_empty():
		_shown_signature = ""
		_shown_card = {}
		_card.hide_card()
		return
	var signature := JSON.stringify(card)
	if signature == _shown_signature and _card.is_open():
		return
	_shown_signature = signature
	_shown_card = card
	_card.show_card(_card_view(card))


func _refresh_coach(session: WorkSession) -> void:
	var id := "" if _stub_open or _board_open else session.coach_id()
	match id:
		WorkSession.COACH_SPEED:
			_coach.point(id, Content.text("barks", id), _speed_buttons[1])
		WorkSession.COACH_HOURS:
			_coach.point(id, Content.text("barks", id), _hours_buttons[2])
		WorkSession.COACH_STUDIO:
			_coach.point(id, Content.text("barks", id), null)
		_:
			_coach.clear()


# ---------- the player's controls ----------

func _on_hours_pressed(notch: int) -> void:
	GameState.career_set_hours(notch)


func _on_speed_pressed(position: int) -> void:
	GameState.career_set_speed(position)


## The DoomApply board (D-41): it takes the Body's and the thumb band's place, and the clock waits while it is open.
func _open_board() -> void:
	if _board_open or _stub_open or _card.is_open():
		return
	_board_open = true
	_body.hide()
	_thumb_band.hide()
	_board.show()
	_refresh()


func _close_board() -> void:
	_board_open = false
	_board.hide()
	_body.show()
	_thumb_band.show()
	_refresh()


func _open_stub_app() -> void:
	if _stub_open or _card.is_open():
		return
	_stub_open = true
	_card.show_card({"title": "", "text": Content.text("barks", "ui_app_stub"),
		"buttons": [{"id": APP_STUB_ID, "text": UiText.primary(Content.text("barks", "ui_ok")), "primary": true}]})


func _close_stub_app() -> void:
	_stub_open = false
	_card.hide_card()
	_refresh()


# ---------- cards ----------

## A card's button was pressed. The sheet closes first, so a next card that looks exactly like this one (two burnout
## warnings in a row) still opens fresh and re-arms its lock.
func _on_card_answered(button_id: String) -> void:
	if _stub_open:
		_close_stub_app()
		return
	var card := _shown_card
	_shown_signature = ""
	_shown_card = {}
	_card.hide_card()
	match String(card.get("kind", "")):
		"notice":
			GameState.career_dismiss_notice()
		WorkCards.K_EVENT:
			GameState.career_choose(button_id)
		WorkCards.K_REVIEW:
			GameState.career_begin_duel()
		WorkCards.K_PICK:
			GameState.career_pick_ticket(button_id)
		WorkCards.K_LEAVE:
			GameState.career_acknowledge()
		WorkCards.K_DUEL:
			GameState.career_begin_duel()
		WorkCards.K_OFFER:
			GameState.career_begin_offer()


## The words for a card: {title, text, buttons: [{id, text, primary}]}. Cards carry ids and numbers (WorkCards); the
## text comes from the JSON here.
func _card_view(card: Dictionary) -> Dictionary:
	var ok := [{"id": "ok", "text": UiText.primary(Content.text("barks", "ui_ok")), "primary": true}]
	match String(card.get("kind", "")):
		"notice":
			return _notice_view(card, ok)
		WorkCards.K_EVENT:
			return _event_view(card)
		WorkCards.K_REVIEW:
			return {"title": Content.text("barks", "ui_cal_review").to_upper(),
				"text": Content.field("work_events", String(card["event"]), "text"),
				"buttons": [{"id": "start", "text": UiText.primary(Content.text("barks", "ui_review_start")), "primary": true}]}
		WorkCards.K_PICK:
			var buttons: Array = []
			for pick: String in card["choices"]:
				var label := Content.text("barks", String(PICK_LABELS[pick]))
				if pick == "paydown":
					label = "%s - %s" % [label, Content.text("barks", "ui_pick_paydown_note")]
				buttons.append({"id": pick, "text": label, "primary": false})
			return {"title": "", "text": Content.text("barks", "ui_pick_prompt"), "buttons": buttons}
		WorkCards.K_LEAVE:
			return {"title": "", "text": Content.text("barks", "ui_forced_leave"), "buttons": ok}
		WorkCards.K_DUEL:
			return {"title": "", "text": Content.text("barks", "ui_interview_day", {
					"company": Content.field("companies", String(card["company"]), "name")}),
				"buttons": [{"id": "start", "text": UiText.primary(Content.text("barks", "ui_interview_start")), "primary": true}]}
		WorkCards.K_OFFER:
			return {"title": "", "text": Content.text("barks", "ui_offer_ready"), "buttons": ok}
	return {"title": "", "text": "", "buttons": ok}


func _notice_view(card: Dictionary, ok: Array) -> Dictionary:
	var style := String(card.get("style", WorkCards.INFO))
	if style == WorkCards.DUCKY:
		return {"title": Content.text("naming", "mascot"), "text": Content.field("tips", String(card["tip"]), "short"), "buttons": ok}
	var text := ""
	if card.has("literal"):
		text = tr(String(card["literal"]))
	elif String(card.get("id", "")) == "ui_auto_resolved":
		text = Content.text("barks", "ui_auto_resolved", {"choice": _choice_label(String(card["event"]), String(card["choice"]))})
	elif card.has("rating"):
		text = _review_result_text(card)
	elif card.has("id"):
		text = Content.text("barks", String(card["id"]), {"n": int(card.get("n", 0)),
			"company": _company_name(String(card.get("company", ""))), "day": int(card.get("day", 0))})
	elif card.has("event"):
		text = Content.field("work_events", String(card["event"]), "text")
	return {"title": "", "text": text, "buttons": ok}


func _event_view(card: Dictionary) -> Dictionary:
	var evt_id := String(card["event"])
	var args := _text_args(card.get("args", {}))
	var evt: Dictionary = Content.entry("work_events", evt_id)
	var buttons: Array = []
	for choice_id: String in card["choices"]:
		for choice: Dictionary in evt.get("choices", []):
			if String(choice["id"]) == choice_id:
				buttons.append({"id": choice_id, "text": UiText.fill(tr(String(choice["text"])), args), "primary": false})
	return {"title": "", "text": UiText.fill(tr(String(evt.get("text", evt_id))), args), "buttons": buttons}


func _review_result_text(card: Dictionary) -> String:
	var results: Dictionary = (Content.entry("work_events", String(card["event"])) as Dictionary).get("results", {})
	var text := UiText.fill(tr(String(results.get(String(card["rating"]), ""))), {"n": int(card["raise_pct"])})
	if bool(card.get("promoted", false)):
		text += "\n" + Content.text("barks", "ui_promoted", {"level": Content.text("barks", WorkHud.level_label_id(int(card["level"])))})
	return text


## A choice's label for the "Burnout picked: ..." line; "nothing" for an event that was skipped.
func _choice_label(evt_id: String, choice_id: String) -> String:
	var evt: Dictionary = Content.entry("work_events", evt_id)
	for choice: Dictionary in evt.get("choices", []):
		if String(choice["id"]) == choice_id:
			return tr(String(choice["text"]))
	return Content.text("barks", "ui_choice_none")


## The placeholders an event's text may use: {money} (k$) and {home} (the next tier up).
func _text_args(raw: Dictionary) -> Dictionary:
	return {
		"money": UiText.money_k(float(raw.get("money_k", 0.0))),
		"home": Content.text("barks", WorkHud.home_label_id(int(raw.get("home", 0)))),
		"coworker": "",
	}


func _feed_text(line: Dictionary) -> String:
	if line.has("literal"):
		return tr(String(line["literal"]))
	var args: Dictionary = line.get("args", {})
	var fill := {"money": UiText.money_k(float(args.get("money_k", 0.0))), "n": int(args.get("n", 0)),
		"company": _company_name(String(args.get("company", "")))}
	if String(line.get("field", "")).is_empty():
		return Content.text(String(line["file"]), String(line["id"]), fill)
	return Content.field(String(line["file"]), String(line["id"]), String(line["field"]), fill)


## A company's display name from its id ("" for none).
func _company_name(company_id: String) -> String:
	return Content.field("companies", company_id, "name") if not company_id.is_empty() else ""


func _tint(label: Label, color: Color) -> void:
	if color == Color.WHITE:
		label.remove_theme_color_override(&"font_color")
	else:
		label.add_theme_color_override(&"font_color", color)
```

`features/work/event_card.gd`:

```gdscript
class_name EventCard
extends Control
## The card over the work state (GDD 4.6, 5.19; ARCHITECTURE 19.7, 10.1): a sheet at the bottom of the screen with a
## text and at most three full-width 254x36 buttons, in the screen's ModalLayer. Its buttons wake 250 ms after it
## opens (GDD 2.8 rule 7), so the tap that closed the last card cannot answer this one. The dimmer behind it blocks
## every tap. It shows what it is told (show_card) and reports which button was pressed (`answered`); the screen
## decides what that means. The sheet's "=" opens Pause, so Back stays on the screen while a card is open (GDD 4.4).

signal answered(button_id: String)

const MENU_MARK := "="    # stands in for the menu icon until the art pass
const SLIDE_SEC := 0.14   # the sheet slides up into the thumb band (GDD 4.6; the camera's step-in is M5)
const SLIDE_PX := 36.0

var _fade: Tween
var _lock: Tween

@onready var _sheet: PanelContainer = %Sheet
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _buttons: VBoxContainer = %Buttons
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	_menu_button.text = MENU_MARK
	_menu_button.pressed.connect(Device.handle_back)


func is_open() -> bool:
	return visible


## view: {title: String, text: String, buttons: [{id: String, text: String, primary: bool}]}. An empty title hides the
## title line. The buttons are disabled for input_lock_ms.
func show_card(view: Dictionary) -> void:
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	var title := String(view.get("title", ""))
	_title.text = title
	_title.visible = not title.is_empty()
	_text.text = String(view.get("text", ""))
	for spec: Dictionary in view.get("buttons", []):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 36)
		button.focus_mode = Control.FOCUS_NONE
		button.text = String(spec["text"])
		if bool(spec.get("primary", false)):
			button.theme_type_variation = &"PrimaryButton"
		button.disabled = true
		button.pressed.connect(_on_pressed.bind(String(spec["id"])))
		_buttons.add_child(button)
	_sheet.modulate.a = 0.0   # hidden until the container has laid it out, then it slides up from below
	show()
	_start_lock()
	await get_tree().process_frame
	if visible:
		_slide_in()


func hide_card() -> void:
	hide()
	if _fade != null:
		_fade.kill()
	if _lock != null:
		_lock.kill()


## True while the lock is on: the screen and the tests can tell a card that is not yet answerable.
func is_locked() -> bool:
	for child: Node in _buttons.get_children():
		if child is Button and (child as Button).disabled:
			return true
	return false


## The labels of the buttons now showing (for the screen's checks and the tests).
func button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for child: Node in _buttons.get_children():
		if child is Button:
			out.append((child as Button).text)
	return out


func _on_pressed(button_id: String) -> void:
	_set_buttons_disabled(true)   # one answer per card: a double tap cannot answer twice
	answered.emit(button_id)


func _slide_in() -> void:
	if _fade != null:
		_fade.kill()
	var final_y := _sheet.position.y   # where the container put it
	_sheet.position.y = final_y + SLIDE_PX
	_sheet.modulate.a = 1.0
	_fade = create_tween()
	_fade.tween_property(_sheet, "position:y", final_y, SLIDE_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _start_lock() -> void:
	if _lock != null:
		_lock.kill()
	_lock = create_tween()
	_lock.tween_interval(Content.balance.input_lock_ms / 1000.0)
	_lock.tween_callback(_set_buttons_disabled.bind(false))


func _set_buttons_disabled(off: bool) -> void:
	for child: Node in _buttons.get_children():
		if child is Button:
			(child as Button).disabled = off
```

`features/work/codebase_rack.gd`:

```gdscript
@tool
class_name CodebaseRack
extends Control
## The Codebase as a server rack of 10 LEDs (GDD 5.16, R-STAT-01): one turns red per 10 points. Display only. Flat
## grey-box colors until M5's art pass. Green is never the only signal: the red ones fill from the left, so the count
## reads by position as well as by color.

const LED := Vector2(4, 8)
const GAP := 2
const GOOD_COLOR := Color(0.38, 0.78, 0.35)
const RED_COLOR := Color(0.89411765, 0.23137255, 0.26666668)

@export var red: int = 0:
	set(count):
		red = clampi(count, 0, WorkHud.LED_COUNT)
		queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	return Vector2(WorkHud.LED_COUNT * LED.x + (WorkHud.LED_COUNT - 1) * GAP, LED.y)


func _draw() -> void:
	var top := floorf((size.y - LED.y) * 0.5)
	for i: int in WorkHud.LED_COUNT:
		var color := RED_COLOR if i < red else GOOD_COLOR
		draw_rect(Rect2(Vector2(i * (LED.x + GAP), top), LED), color)
```

`features/work/calendar_strip.gd`:

```gdscript
@tool
class_name CalendarStrip
extends Control
## The calendar strip (GDD 5.14, 4.6): the next 60 days as a line with a tick for each thing coming: paydays, rent,
## the review, the lease, a ticket's deadline, an interview. Today is the left end. Information only. Each kind has
## its own tick height as well as its own color, so color is never the only signal (GDD 2.7). Flat grey-box look.

const HEIGHT := 12.0
const BASE_COLOR := Color(0.54509807, 0.60784316, 0.7058824)
const KINDS: Dictionary = {   # kind -> [tick height, color]
	"payday": [12.0, Color(0.38, 0.78, 0.35)],
	"rent": [6.0, Color(0.89411765, 0.23137255, 0.26666668)],
	"review": [12.0, Color(0.99607843, 0.68235296, 0.20392157)],
	"lease": [8.0, Color(0.74, 0.5, 0.9)],
	"deadline": [10.0, Color(1.0, 0.55, 0.2)],
	"interview": [12.0, Color(0.16, 0.68, 1.0)],
}

var _items: Array = []
var _days: int = 60


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, HEIGHT)


## items are WorkHud.calendar(): {offset, kind, label_id}; days is the strip's length (WorkConfig.calendar_days).
func set_items(items: Array, days: int) -> void:
	_items = items
	_days = maxi(days, 1)
	queue_redraw()


## The x of a tick: offset 1..days across the strip's width, whole pixels.
static func tick_x(offset: int, days: int, width: float) -> float:
	return floorf(clampf(float(offset) / float(maxi(days, 1)), 0.0, 1.0) * (width - 2.0))


func _draw() -> void:
	draw_rect(Rect2(0.0, HEIGHT - 2.0, size.x, 1.0), BASE_COLOR)
	for item: Dictionary in _items:
		var spec: Array = KINDS.get(String(item["kind"]), [6.0, BASE_COLOR])
		var h: float = spec[0]
		draw_rect(Rect2(tick_x(int(item["offset"]), _days, size.x), HEIGHT - 1.0 - h, 2.0, h), spec[1])
```

`features/layoff/layoff.gd`:

```gdscript
extends Control
## The layoff scene (GDD 5.19, D-22; ARCHITECTURE 19.7): "DANA VS YOU", and then no fight starts. Dana reads the
## euphemism, the severance appears, your access is revoked. Non-interactive: its four beats advance on taps like the
## intro's captions (no auto-advance: D12, A19, RC-34), Back opens Pause, and the last OK hands the sim its
## acknowledgement (GameState.career_acknowledge), which sends the run back to WORK. This is M2's plain version; M3
## gives it the VS intro's look and the hold-to-skip pill from the second viewing.

const BEATS := 4
const REVOKED_COLOR := Color(0.89411765, 0.23137255, 0.26666668)   # the warning red of the hub's rent line

var _beat := -1
var _locked := true     # the 250 ms input lock after each beat (GDD 2.8 rule 7)
var _leaving := false

@onready var _title: Label = %Title
@onready var _line: Label = %DanaLine
@onready var _line2: Label = %DanaLine2
@onready var _severance: Label = %Severance
@onready var _revoked: Label = %Revoked
@onready var _hint: Label = %Hint
@onready var _tap_pad: Control = %TapPad
@onready var _back_button: Button = %BackButton
@onready var _next_button: Button = %NextButton
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	if OS.is_debug_build() and GameState.session == null:
		GameState.debug_career_quick_start(true)   # project_run mode="custom": a run that has just been laid off
	var pending := GameState.session.sim.pending() if GameState.session != null else {}
	_title.text = Content.text("barks", "vs_layoff_title")
	_line.text = Content.text("barks", "bark_dana_layoff")
	_line2.text = Content.text("barks", "bark_dana_layoff_2")
	_severance.text = Content.text("barks", "ui_severance", {"money": UiText.money_k(float(pending.get("severance", 0.0)))})
	_revoked.text = Content.text("barks", "ui_access_revoked")
	_revoked.add_theme_color_override(&"font_color", REVOKED_COLOR)
	_hint.text = Content.text("barks", "ui_tap_to_continue")
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_back_button.pressed.connect(Device.handle_back)
	_next_button.pressed.connect(_advance)
	_tap_pad.gui_input.connect(_on_tap_input)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	for beat: Control in [_line2, _severance, _revoked]:
		beat.hide()
	_advance_to(0)


## Back opens Pause (RC-34); a second Back resumes.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	GameState.save()
	_pause.open()
	return true


## A tap anywhere advances, on release like a button.
func _on_tap_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton   # touches arrive as emulated mouse events
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_advance()


func _advance() -> void:
	if _locked or _leaving or _pause.is_open():
		return
	if _beat >= BEATS - 1:
		_leaving = true
		_next_button.disabled = true
		GameState.career_acknowledge()
		return
	_advance_to(_beat + 1)


func _advance_to(beat: int) -> void:
	_beat = beat
	match beat:
		1:
			_line2.show()
		2:
			_severance.show()
		3:
			_revoked.show()
	var last := beat >= BEATS - 1
	_next_button.text = UiText.primary(Content.text("barks", "ui_ok" if last else "ui_continue"))
	_hint.visible = not last
	_locked = true
	await get_tree().create_timer(Content.balance.input_lock_ms / 1000.0).timeout
	_locked = false
```

### 17.21 The adapter and the contract text: core/duel_adapter.gd and core/contract_text.gd (Step 16)

`core/duel_adapter.gd`:

```gdscript
@tool
class_name DuelAdapter
extends RefCounted
## The adapter between the career run's sim and the shipped duel and contract screens (GDD 5.20, ARCHITECTURE 19.5,
## R-JOB-06; DECISIONS A88, A89). The sim asks for an interview, a review or an answer to an offer through its queue;
## this class turns that queue item into plain data the Phase 1 screens already know how to play (the interview
## checkpoint, the contract paper) and turns what they report into the sim's inputs. Pure, like Sim: no nodes, no
## autoloads, and no draw from the sim's stream. Everything it rolls comes from local generators seeded from the run
## seed, the application (or the day) and the duel's index, so Continue replays the same questions and the same luck.
##
## Request and result shapes (plain dictionaries, INV-07; the field names are the sim's own):
##   DuelRequest  {composure, meter_mult, doubt_hp, floor, archetype, tier, unlocked_options, rounds}   (Sim._start_duel)
##   DuelResult   {passed, composure_left}
##   OfferRequest the posting {id, company, archetype, level, floor, salary, remote, clauses, posted} (the `offer` item)
##   OfferResult  {decision, final_salary, clauses}

const KIND_INTERVIEW := "interview"
const KIND_REVIEW := "review"
const GREET_FIRST := "first"                # the tier's greeting, then the background's opener
const GREET_AGAIN := "again"                # "Didn't I interview you at {last_company}?"
const GREET_AFTER_LAYOFF := "after_layoff"  # Dana laid you off, then met you again at the next company

const SALT_PICK := 7919
const SALT_INTERVIEW := 104729
const SALT_REVIEW := 1299709
const SALT_REVIEW_PICK := 15485863
const SALT_OFFER := 32452843
const OFFER_PERKS := 1                      # Phase 1's paper lists two perks; the career's adds a Clauses field and keeps to 20 lines
const ONSITE_DAYS := 5                      # a non-remote startup posting is in the office all week
const REMOTE_MODE := "offer_mode_remote"
const ONSITE_MODE := "offer_mode_onsite"
const MANAGER_AUTHORED := "cw_kev"          # run 1's manager (GDD 5.18)


## A seed as a String (64-bit values do not survive JSON as numbers: INV-05), the same for the same inputs.
static func seed_text(run_seed: int, salt: int, a: int, b: int) -> String:
	return str(("%d|%d|%d|%d" % [run_seed, salt, a, b]).hash())


# ---------- the interview ----------

## The interview checkpoint for the sim's `duel` queue item {app, index, of, request}, in the shape Phase 1's
## interview resumes from (RunState.interview) plus the career's numbers. history: {seen: Array[String], first_run,
## met (interviews finished), last_company, after_layoff}. The caller marks the picked ids as seen.
static func interview_checkpoint(item: Dictionary, posting: Dictionary, run_seed: int, ctx: SimContext, history: Dictionary) -> Dictionary:
	var request: Dictionary = item["request"]
	var app := int(item["app"])
	var index := int(item["index"])
	var tier_id := String(request["tier"])
	var seen: Array[String] = []
	seen.assign(history.get("seen", []))
	var first_run := bool(history.get("first_run", false))
	var met := int(history.get("met", 0))
	var with_warmup := first_run and met == 0     # InterviewPlan.warmup_due: the first interview of the first run
	var pick_rng := InterviewPlan.interview_rng(seed_text(run_seed, SALT_PICK, app, index))
	var plan := InterviewPlan.pick(ctx.balance, tier_id, ctx.content.get("questions_choice", {}),
		ctx.content.get("questions_knowledge", {}), seen, pick_rng, with_warmup)
	var greet := GREET_FIRST
	if bool(history.get("after_layoff", false)):
		greet = GREET_AFTER_LAYOFF
	elif met > 0 and not String(history.get("last_company", "")).is_empty():
		greet = GREET_AGAIN
	return {
		"kind": KIND_INTERVIEW, "invite_uid": -1, "company_id": String(posting["company"]), "template_id": "", "tier": tier_id,
		"seed": seed_text(run_seed, SALT_INTERVIEW, app, index), "tired": false,
		"question_ids": plan["question_ids"], "warmup_id": plan["warmup_id"],
		"composure": float(request["composure"]), "doubt_hp": float(request["doubt_hp"]), "meter_mult": float(request["meter_mult"]),
		"rounds": (plan["question_ids"] as Array).size(), "unlocked_options": (request.get("unlocked_options", []) as Array).duplicate(),
		"floor": int(request["floor"]), "archetype": String(request["archetype"]),
		"app": app, "index": index, "of": int(item["of"]),
		"greet": greet, "last_company": String(history.get("last_company", "")),
	}


## What the interview starts with. A Phase 1 checkpoint has none of the career's fields, so every number falls back to the
## .tres files it always read (tier.doubt_hp, bg.composure_max, a meter multiplier of 1): a hunt save still plays.
static func start_values(iv: Dictionary, tier: TierData, bg: BackgroundData) -> Dictionary:
	return {
		"composure": float(iv.get("composure", bg.composure_max)),
		"doubt": float(iv.get("doubt_hp", tier.doubt_hp)),
		"zone_mult": float(iv.get("meter_mult", 1.0)),
	}


## The Answer Meter's half-width: the stat score's NAILED IT width (plus the Graduate's textbook bonus) times the work
## state's multiplier (Skill widens it, Rust narrows it), never below the 0.06 floor (RC-25, GDD 5.20). S is untouched.
static func half_width(cfg: BalanceConfig, s: float, bonus: float, zone_mult: float) -> float:
	return maxf(cfg.zone_half_base, Odds.zone_half(cfg, s, bonus) * zone_mult)


# ---------- the review ----------

## The review checkpoint for the sim's `review` queue item {evidence, calibration}: three prompts from the review pool,
## the manager's name, and the two HP pools. `seen` is the review prompts asked before (least recently first).
static func review_checkpoint(item: Dictionary, s: SimState, ctx: SimContext, seen: Array) -> Dictionary:
	var arch := ctx.archetype(s.job_archetype)
	var seen_ids: Array[String] = []
	seen_ids.assign(seen)
	var pick_rng := InterviewPlan.interview_rng(seed_text(s.rng_seed, SALT_REVIEW_PICK, s.day, s.jobs_held))
	var ids := InterviewPlan.pick_ids(ctx.content.get("questions_review", {}), seen_ids, pick_rng, ctx.cfg.review_prompts)
	return {
		"kind": KIND_REVIEW, "invite_uid": -1, "company_id": s.job_company, "template_id": "", "tier": String(arch.duel_tier),
		"seed": seed_text(s.rng_seed, SALT_REVIEW, s.day, s.jobs_held), "tired": false,
		"question_ids": ids, "warmup_id": "", "rounds": ids.size(), "archetype": String(arch.id),
		"evidence": float(item["evidence"]), "calibration": float(item["calibration"]),
		"manager": manager_name(s, ctx),
		"hits": {
			"good": WorkOdds.review_hit(ctx.cfg, float(item["calibration"]), "good"),
			"neutral": WorkOdds.review_hit(ctx.cfg, float(item["calibration"]), "neutral"),
			"bad": WorkOdds.review_hit(ctx.cfg, float(item["calibration"]), "bad"),
		},
	}


## Your manager: Kev at Hierarchai (run 1's authored crew), else a name from the pool, the same for the whole job.
static func manager_name(s: SimState, ctx: SimContext) -> String:
	for cw: Dictionary in s.coworkers:
		if String(cw.get("id", "")) == MANAGER_AUTHORED:
			return String(cw.get("name", ""))
	var pool := ctx.coworker_pool
	if pool.is_empty():
		return ""
	return pool[posmod(("%d|%d" % [s.rng_seed, s.jobs_held]).hash(), pool.size())]


# ---------- the contract ----------

## The contract paper for an offer: the same shape RunState.make_offer builds for Phase 1's offer screen (ids into
## emails.json for every text, the posting's title as raw text, plain data), plus the posting's clauses and its level.
## The salary is the yearly figure (GDD 5.20, MC-10): the sim's is a month's pay in k$. The perks, the hidden clause
## (a fine-print joke from the duel tier's pool, revealed here) and the title come from the offer's own generator.
static func offer_paper(posting: Dictionary, ctx: SimContext, run_seed: int) -> Dictionary:
	var emails: Dictionary = ctx.content.get("emails", {})
	var arch := ctx.archetype(String(posting["archetype"]))
	var tier_id := String(arch.duel_tier)
	var tier := ctx.tiers.get(tier_id) as TierData
	var remote := bool(posting.get("remote", false))
	var office_days := 0
	if not remote:
		office_days = ONSITE_DAYS if tier_id == RunState.EQUITY_TIER else tier.office_days
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_text(run_seed, SALT_OFFER, int(posting["id"]), 0).to_int()
	var perks := Odds.pick(rng, _ids_with_prefix(emails, "perk_", tier_id), OFFER_PERKS)
	var fine_print := Odds.pick(rng, RunState.fine_print_pool(emails, tier_id, perks), 1)
	var level_title := String(emails.get("title_" + WorkOdds.LEVELS[int(posting["level"])], ""))
	return {
		"company_id": String(posting["company"]), "template_id": "", "tier": tier_id, "archetype": String(arch.id),
		"level": int(posting["level"]), "floor": int(posting.get("floor", 1)),
		"job_title": level_title + String(emails.get("title_suffix_" + String(arch.id), "")),
		"salary": WorkOdds.yearly_salary(ctx.cfg, float(posting["salary"])),
		"work_mode": REMOTE_MODE if remote else _mode_id(tier_id, office_days), "office_days": office_days,
		"commute": RunState.offer_commute(office_days, ctx.bg.commute_minutes),
		"perks": perks, "fine_print": str(fine_print[0]) if not fine_print.is_empty() else "",
		"clauses": (posting.get("clauses", []) as Array).duplicate(), "remote": remote,
		"equity_text": "offer_equity" if tier_id == RunState.EQUITY_TIER else "",
	}


static func _mode_id(tier_id: String, office_days: int) -> String:
	if office_days >= ONSITE_DAYS:
		return ONSITE_MODE
	return "offer_mode_" + tier_id


## The sorted ids starting with prefix whose "tiers" list this tier (perk_*, fp_* in emails.json).
static func _ids_with_prefix(emails: Dictionary, prefix: String, tier_id: String) -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in emails:
		var id := str(key)
		if id.begins_with(prefix) and emails[key] is Dictionary and ((emails[key] as Dictionary).get("tiers", []) as Array).has(tier_id):
			ids.append(id)
	ids.sort()
	return ids


# ---------- what the screens report, as the sim's inputs ----------

static func duel_result_input(passed: bool, composure_left: float) -> Dictionary:
	return {"kind": Sim.IN_DUEL_RESULT, "passed": passed, "composure_left": composure_left}


static func review_result_input(evidence_left: float) -> Dictionary:
	return {"kind": Sim.IN_REVIEW_RESULT, "evidence_left": evidence_left}


static func offer_input(accept: bool) -> Dictionary:
	return {"kind": Sim.IN_ANSWER_OFFER, "accept": accept}


## The OfferResult of GDD 5.20: no negotiation (D-27), so the final salary is the offered one.
static func offer_result(accept: bool, paper: Dictionary) -> Dictionary:
	return {"decision": "accept" if accept else "decline", "final_salary": int(paper.get("salary", 0)),
		"clauses": (paper.get("clauses", []) as Array).duplicate()}
```

`core/contract_text.gd`:

```gdscript
@tool
class_name ContractText
extends RefCounted
## The contract paper's lines (GDD S10, CONTENT 13.1), from the paper dictionary and the emails.json entries. Pure, so a
## test can measure the real paper: pre-wrapped at 40 columns by UiText.word_wrap and UiText.field, one field per line
## after a 12-character label, values wrapping at 28. The offer screen shows exactly these lines; the career run's paper
## (DuelAdapter.offer_paper) adds the Clauses field.

const COLUMNS := 40            # GDD 2.7: the 254 px paper holds 40 characters of monogram 16
const LABEL_COLUMNS := 12      # GDD S10: one field per line after a 12-character label column
const MAX_LINES := 20          # about a 250 px paper: 20 lines of 12 px plus the panel's margins


static func lines(paper: Dictionary, emails: Dictionary, company: String, player_name: String) -> PackedStringArray:
	var out := PackedStringArray()
	var commute: Dictionary = paper.get("commute", {})
	out += UiText.word_wrap(_text(emails, "offer_title", {"company": company}), COLUMNS)
	out += UiText.word_wrap(_text(emails, "offer_dear", {"player_name": player_name}), COLUMNS)
	out += UiText.word_wrap(_text(emails, "offer_role", {"job_title": str(paper.get("job_title", ""))}), COLUMNS)
	out.append("")
	out += _field(_text(emails, "offer_label_salary"),
		_text(emails, "offer_salary", {"salary": UiText.money(int(paper.get("salary", 0)))}))
	if str(paper.get("equity_text", "")) != "":
		out += _field(_text(emails, "offer_label_equity"), _text(emails, str(paper["equity_text"])))
	out += _field(_text(emails, "offer_label_mode"), _text(emails, str(paper.get("work_mode", ""))))
	out += _field(_text(emails, "offer_label_commute"), _text(emails, str(commute.get("id", "")), commute.get("args", {})))
	var label := _text(emails, "offer_label_perks")
	for perk: Variant in paper.get("perks", []):
		out += _field(label, _entry_text(emails, str(perk)))
		label = ""
	var clauses: Array = paper.get("clauses", [])
	if not clauses.is_empty():
		var parts := PackedStringArray()
		for clause: Variant in clauses:
			parts.append(_text(emails, "clause_" + str(clause)))
		out += _field(_text(emails, "offer_label_clauses"), " ".join(parts))
	out += _field(_text(emails, "offer_label_fine_print"), _entry_text(emails, str(paper.get("fine_print", ""))))
	out += UiText.word_wrap(_text(emails, "offer_deadline"), COLUMNS)
	return out


static func _field(label: String, value: String) -> PackedStringArray:
	return UiText.field(label, value, LABEL_COLUMNS, COLUMNS)


## A plain-string entry (offer_title, offer_dear, ...) with its {placeholders} filled.
static func _text(emails: Dictionary, id: String, args: Dictionary = {}) -> String:
	return UiText.fill(str(emails.get(id, "")), args)


## A perk or fine-print entry: {tiers, text}.
static func _entry_text(emails: Dictionary, id: String) -> String:
	var entry: Variant = emails.get(id, {})
	return str((entry as Dictionary).get("text", "")) if entry is Dictionary else str(entry)
```

### 17.22 The DoomApply board: core/work_board.gd and features/work/board_panel.gd (Step 16)

`core/work_board.gd`:

```gdscript
@tool
class_name WorkBoard
extends RefCounted
## What the DoomApply board shows (GDD 5.20, D-41, P-02), as plain data: the postings as nodes with their yearly pay,
## clauses and callback dots, the applications waiting on a reply, and whether you can apply or study. Pure, like
## WorkHud: it reads a SimState and changes nothing, so the board scene only draws what it is told (INV-03) and a test
## can check each number. A node carries ids and numbers, never text.


## The board's postings, in the sim's order, as {id, company, archetype, level, floor, salary (yearly, whole dollars),
## remote, clauses, dots (1-5)}. The dots are the callback odds' band (WorkOdds.callback_dots); the odds themselves are
## never shown (pillar 3).
static func nodes(s: SimState, ctx: SimContext) -> Array:
	var out: Array = []
	var refs := Sim.references(s, ctx.cfg)
	for p: Dictionary in s.board:
		var odds := WorkOdds.callback_p(ctx.cfg, int(p["level"]), s.level, s.scar_short_tenure, refs)
		out.append({
			"id": int(p["id"]), "company": String(p["company"]), "archetype": String(p["archetype"]), "level": int(p["level"]),
			"floor": int(p.get("floor", 1)), "salary": WorkOdds.yearly_salary(ctx.cfg, float(p["salary"])),
			"remote": bool(p.get("remote", false)), "clauses": (p.get("clauses", []) as Array).duplicate(),
			"dots": WorkOdds.callback_dots(ctx.cfg, odds),
		})
	return out


## The applications still in flight, soonest first: {company, kind ("reply" or "interview"), day}. A duel waiting on the
## screen or an offer waiting on the contract is not listed: those have a card of their own.
static func waiting(s: SimState) -> Array:
	var out: Array = []
	for app: Dictionary in s.applications:
		var company := String((app["posting"] as Dictionary).get("company", ""))
		match String(app.get("status", "")):
			"wait":
				out.append({"company": company, "kind": "reply", "day": int(app["reply"])})
			"callback":
				out.append({"company": company, "kind": "interview", "day": int(app["interview"])})
			"between":
				out.append({"company": company, "kind": "interview", "day": int(app["next_duel"])})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return out


## Applying is off only at job 5, where there is no next floor (D-16, A72).
static func can_apply(s: SimState, cfg: WorkConfig) -> bool:
	return not (s.employed and s.jobs_held >= cfg.max_jobs)


## The Burnout an application costs: more while you still hold a job to lose.
static func apply_burnout(s: SimState, cfg: WorkConfig) -> float:
	return cfg.apply_burnout_employed if s.employed else cfg.apply_burnout_unemployed


## Study is one a day.
static func can_study(s: SimState) -> bool:
	return s.last_study_day != s.day


## Days until the board's postings are replaced (0 on the day it refreshes).
static func days_to_refresh(s: SimState, cfg: WorkConfig) -> int:
	return maxi(0, cfg.board_refresh_days - (s.day - s.board_day))
```

`features/work/board_panel.gd`:

```gdscript
class_name BoardPanel
extends VBoxContainer
## The DoomApply board (GDD 5.20, 4.6; D-41, P-02): 3-5 postings stacked as nodes of a route, joined by a line, each with
## company, archetype, level, yearly pay, work mode, clauses and the callback band as 5 dots, never a percentage. Tap a
## node to select it; Apply (primary) and Study sit in the thumb band beside Back. It shows what WorkBoard computes and
## reports two presses (INV-03); the work screen turns them into GameState verbs. It replaces the Body and the Hours
## and dock rows while it is open, so the top band keeps showing Runway and Burnout while you apply.

signal apply_pressed(posting_id: int)
signal study_pressed

const ROUTE_X := 10.0                  # the line that joins the nodes runs along the left edge
const ROUTE_COLOR := Color(0.54509807, 0.60784316, 0.7058824, 1)
const NODE_MARGIN := 4.0               # the theme's buttons are 36 px tall for one line; a node holds three or four
const STATES: Array[StringName] = [&"normal", &"pressed", &"hover", &"hover_pressed", &"focus", &"disabled"]
const CLAUSE_IDS: Dictionary = {
	"on_call": "ui_clause_on_call", "remote_in_writing": "ui_clause_remote_in_writing", "unlimited_pto": "ui_clause_unlimited_pto",
}
const ARCHETYPE_IDS: Dictionary = {
	"startup": "ui_archetype_startup", "agency": "ui_archetype_agency", "megacorp": "ui_archetype_megacorp",
}

var _selected := -1                    # the posting id you tapped; -1 until one is
var _group := ButtonGroup.new()

@onready var _title: Label = %Title
@onready var _refresh: Label = %Refresh
@onready var _nodes: VBoxContainer = %Nodes
@onready var _waiting: Label = %Waiting
@onready var _study: Button = %StudyButton
@onready var _back: Button = %BackButton
@onready var _apply: Button = %ApplyButton


func _ready() -> void:
	_title.text = Content.text("naming", "app_jobs").to_upper()
	_back.text = UiText.back(Content.text("barks", "ui_back"))
	_apply.text = UiText.primary(Content.text("barks", "ui_apply"))
	_back.pressed.connect(Device.handle_back)
	_apply.pressed.connect(_on_apply_pressed)
	_study.pressed.connect(study_pressed.emit)
	_nodes.draw.connect(_draw_route)
	_nodes.sort_children.connect(_nodes.queue_redraw)


## Draws the board from the session's state: the nodes (the selection stays on its posting, else the first), the
## applications in flight and the two buttons' states.
func show_board(session: WorkSession) -> void:
	var s := session.sim
	var ctx := session.ctx
	var cfg := ctx.cfg
	var nodes := WorkBoard.nodes(s, ctx)
	var kept := false
	for node: Dictionary in nodes:
		if int(node["id"]) == _selected:
			kept = true
	if not kept:
		_selected = int(nodes[0]["id"]) if not nodes.is_empty() else -1
	_rebuild_nodes(nodes)
	var can_apply := WorkBoard.can_apply(s, cfg)
	_refresh.text = Content.text("barks", "ui_board_refresh", {"days": WorkBoard.days_to_refresh(s, cfg)})
	var waiting := _waiting_text(WorkBoard.waiting(s))
	if can_apply:
		_apply.text = UiText.primary(Content.text("barks", "ui_apply_cost", {"n": int(WorkBoard.apply_burnout(s, cfg))}))
	else:
		_apply.text = UiText.primary(Content.text("barks", "ui_apply"))
		waiting += "\n" + Content.text("barks", "ui_last_floor")
	_waiting.text = waiting
	var can_study := WorkBoard.can_study(s)
	_study.text = Content.text("barks", "ui_study", {"n": int(cfg.study_burnout)}) if can_study else Content.text("barks", "ui_study_done")
	_study.disabled = not can_study
	_apply.disabled = _selected < 0 or not can_apply


func selected_id() -> int:
	return _selected


## The text of one node's button: the company, what the job is and where, the clauses (when it has any), and the odds.
func node_text(node: Dictionary) -> String:
	var company := Content.field("companies", String(node["company"]), "name")
	var what := "%s  %s  %s/yr  %s" % [
		Content.text("barks", String(ARCHETYPE_IDS.get(node["archetype"], "ui_archetype_startup"))),
		Content.text("barks", WorkHud.level_label_id(int(node["level"]))),
		UiText.money(int(node["salary"])),
		Content.text("barks", "ui_mode_remote" if bool(node["remote"]) else "ui_mode_office")]
	var lines: Array = [company, what]
	var clauses := PackedStringArray()
	for clause: Variant in node["clauses"]:
		clauses.append(Content.text("barks", String(CLAUSE_IDS.get(clause, ""))))
	if not clauses.is_empty():
		lines.append("  ".join(clauses))
	var dots := int(node["dots"])
	lines.append("%s %s" % [Content.text("barks", "ui_callback"), UiText.band(dots, Content.text("barks", "ui_odds_%d" % dots))])
	return "\n".join(lines)


func _rebuild_nodes(nodes: Array) -> void:
	for child: Node in _nodes.get_children():
		_nodes.remove_child(child)
		child.queue_free()
	for node: Dictionary in nodes:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = _group
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.text = node_text(node)
		button.set_pressed_no_signal(int(node["id"]) == _selected)
		button.pressed.connect(_on_node_pressed.bind(int(node["id"])))
		_nodes.add_child(button)
		_compact(button)
	_nodes.queue_redraw()


## The theme's button style has margins for a one-line, 36 px button: a node's own copy keeps the look and trims them.
func _compact(button: Button) -> void:
	for state: StringName in STATES:
		var box := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if box == null:
			continue
		box.content_margin_top = NODE_MARGIN
		box.content_margin_bottom = NODE_MARGIN
		button.add_theme_stylebox_override(state, box)


func _waiting_text(waiting: Array) -> String:
	if waiting.is_empty():
		return Content.text("barks", "ui_board_nothing")
	var lines := PackedStringArray([Content.text("barks", "ui_board_waiting")])
	for item: Dictionary in waiting:
		var id := "ui_app_reply" if String(item["kind"]) == "reply" else "ui_app_interview"
		lines.append(Content.text("barks", id, {"company": Content.field("companies", String(item["company"]), "name"), "day": int(item["day"])}))
	return "\n".join(lines)


func _on_node_pressed(posting_id: int) -> void:
	_selected = posting_id
	_apply.disabled = false


func _on_apply_pressed() -> void:
	if _selected >= 0:
		apply_pressed.emit(_selected)


## The route: a line down the left edge from each node to the next.
func _draw_route() -> void:
	var buttons := _nodes.get_children()
	for i: int in buttons.size() - 1:
		var from: Control = buttons[i]
		var to: Control = buttons[i + 1]
		_nodes.draw_line(Vector2(ROUTE_X, from.position.y + from.size.y), Vector2(ROUTE_X, to.position.y), ROUTE_COLOR, 2.0)
```

---

## 18. Unverified items and pitfalls

### 18.1 Test these on the iPhone (Step 2 unless noted)

| # | Item | What to do if it's wrong |
|---|---|---|
| 1 | Does dragging a ScrollContainer fire a button release? Desktop (Step 2): STOP rows block the scroll; PASS rows scroll and never fire, so the lists use PASS (section 10.3 rule 7) | also ignore a release when the pointer moved more than the deadzone |
| 2 | The unit of `gui/common/default_scroll_deadzone` (assumed game px) | adjust the value until a flick scrolls and a tap taps |
| 3 | Whether `window_width/height_override` are ignored on iOS | if not, clear them in an `ios` feature override (and `android`, LATER) |
| 4 | Whether the letterbox uses `default_clear_color` | irrelevant with ≤ 3 px |
| 5 | Safe area on a real Dynamic Island: does Godot still report the 59 pt top and 34 pt bottom insets with the status bar and home indicator hidden? | preview with `debug_fake_insets = (0, 45, 0, 26)`; measure on the phone and update GDD 2.9 |
| 6 | Fonts on the iPhone at 4x: monogram's 16 px metrics (the 40-column budgets need a 6 px advance) and Press Start 2P's 8 px grid; glyph coverage for other languages. **Measured on desktop (Step 2): monogram 16 has a 6 px advance and a 13 px glyph height; Press Start 2P has an exact 8 px grid** (section 1.4). The theme's `line_spacing = -1` gives the 12 px line pitch (DECISIONS A3). Two-line buttons came out taller than planned (the lie probe's buttons rendered 124x47); Step 6's `ProbeButton` style trimmed their padding to fit 124x44 exactly, and was removed with the probe (DECISIONS D9; section 1.4 keeps the numbers). On the iPhone, check crispness at 4x and that the 12 px pitch reads well | pick a native size before building layouts; if the 12 px pitch reads cramped on the phone, revisit A3 and the GDD 2.7 budgets together |
| 7 | iOS haptics: is a 10 ms tap felt, and do haptics survive a background/resume? No entitlement is expected (unverified) | raise tap-level haptics to 20 ms, or add an amplitude parameter to `Device.haptic()` (GDD 9.3); keep the Settings toggle |
| 8 | That the JSON texts load in the exported iOS build (Step 5) | add `data/content/*.json` to the include filter |
| 9 | The 7-day Personal Team expiry: does reinstalling over the same bundle ID keep the save? | re-run from Xcode before every playtest; join the paid program before Step 13 |
| 10 | One-click deploy and remote debug with a Personal Team (Mac editor) | build and run from Xcode, and read Xcode's console |
| 11 | The name of Steam's "update only on launch" option (Windows PC) | find it; commit before any engine update. The Mac's zip never updates itself |
| 12 | `DisplayServer.virtual_keyboard_get_height()` unit on iOS (likely native px; Step 5, S03 name field). `Device.keyboard_height()` already assumes native px and divides by the scale, as `safe_insets()` does (section 17.8) | if it is points or game px, change only `keyboard_height()` |
| 13 | `game_manage input_mouse` coordinate space. Desktop (Step 2): window pixels, not game pixels, and a motion event must come before the press | test on one button first |
| 14 | The game embedded in the editor's Game tab (possible since 4.4): the window size is the tab's size, the 540x960 override may not apply, and `game_eval` resizes are ignored (seen in Step 1). Desktop-only | float or undock the game window to test exact sizes. The guard rule still holds at any size |
| 15 | (Android, LATER) `gradle_build/target_sdk` shows 36 in the preset; the 4.7.2 template already targets 36 | set it to 36 |
| 16 | (Android, LATER) Play's closed-testing rule for new personal accounts (12 testers x 14 days) | check the Play Console when you create the account |
| 17 | (Step 7 review) Coach notes: a tap on a Jobs coach note closes it without flipping or swiping the card under it, and in Mail a finger drag that starts on the invite coach note still scrolls the list. `game_manage` can't send a drag with a button held, so the drag is untested on desktop | if a drag closes the note, also ignore a release after a move past the deadzone in `DuckyNote` (it already should); if the card reacts, check the note's `mouse_filter` |
| 18 | (Step 7 review) The HP bars' 0.4 s white ghost reads as a drain, and the empty `#181425` stat blocks read on the `#262B44` panels at 4x | retime `HpBar.GHOST_SEC` (GDD 9.1) or change `StatBar.EMPTY_COLOR` to an outlined block like `PipBar` |

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
11. **`if difficulty == HARD` or `if archetype == ...` anywhere.** Difficulty, floor depth and archetype effects are only ever numbers and fields in the `.tres` data (`BackgroundData`, `WorkConfig`, `ArchetypeData`; DECISIONS A69, MC-22).
12. **Reordering the `Phase` enum**, which breaks saves. Only append.
13. **Loading anything but our own JSON or `settings.cfg` from `user://`.**
14. **Tests that touch autoloads or `user://`, lack `@tool`, or make zero assertions.**
15. **Engine or template drift.** A Steam update on the PC, or a different download on the Mac, means the two machines and the templates no longer match 4.7.2. Commit first and update both together.
16. **Testing only in the editor.** Fonts, the Dynamic Island, touch and performance only reveal themselves on the iPhone.

---

## 19. The career run's code (Run Spec v1; M1 built, M2-M6 planned)

**M1 (STEP-14, 2026-10-08) built 19.1-19.3 and 19.6, and the sim suites of 19.10; M2 (STEP-15) built 19.4 and 19.7 and their suites; 19.5 and 19.8 are still plans for M3 and M5.** The plan was written during the Run Spec v1 merge (2026-10-07); where the build differs, the text below says what was built. It follows every rule of sections 1-18 and every invariant. The built classes are in section 17 (17.5 for the two Resource classes, 17.18 for the sim core). The design is GDD 5.14-5.22.

### 19.1 The shape (Run Spec v1 section 13)

| Layer | What it is | Where (planned) |
|---|---|---|
| The sim core | a pure, deterministic step function, `step(state, inputs, seed) -> (state, events)`, with no scene tree, nodes, autoloads or wall clock | `core/` (19.2) |
| Content as data | events, archetypes, tips and every constant in data files: numbers in `.tres`, text and events in JSON (A54) | `data/` (19.3) |
| Presentation | reads the sim's state, draws the HUD and, from M5, the diorama, and sends inputs (the slider, choices, apps); it knows no rules | `features/work/` (19.7, 19.8) |
| The adapter | the shipped duel and contract modal behind one typed interface (R-JOB-06) | `GameState` + the interview checkpoint (19.5) |
| The run log | the seed plus every input and every outcome, not every tick (RC-26) | in the save (19.4, 19.6) |

- *Why this shape:* tuning to a 5-10% win rate needs thousands of runs, so the sim must run without the game's scenes; save, resume and "no time while closed" all reduce to serializing one state object. It is section 3's split one level up: the sim is the model, `GameState` the controller, the scenes the view.
- **"No engine calls"** in GDScript means no Node, SceneTree, autoload, `Time`, `OS` or file access inside the sim. Engine value types and `RandomNumberGenerator` are fine: they are deterministic and run headless (A-02), and section 7.2's RNG rules hold.

### 19.2 The sim core (M1, built)

Classes, all `@tool`, `class_name` and `RefCounted`, pure like section 3's (INV-03), in `core/` next to them (code in 17.18):

| Class | File | Holds |
|---|---|---|
| `SimState` | `core/sim_state.gd` | the whole career as plain data (INV-07): the day, savings and the pay accrued, level, the job (company, archetype, salary, start, work mode, clauses, flags, coworkers and their Rapport), the Hours notch, Burnout, MO, Skill, Rust, the Codebase, the ticket, the home tier and its lease, the review and the PIP, Scars, the event queue and the telegraphed chains, the board, applications and offers, the Studio hold, the Handbook, the RNG seed and state, the stats counters and the run log. `to_dict` / `from_dict` walk the script variables, so a new field is saved without touching them. **`to_save` / `from_save` are the save of record** (A75): every float becomes its raw 64 bits in hex, because Godot's JSON parser does not read every double back exactly and one stray unit in the last place flips a threshold days of game time later |
| `Sim` | `core/sim.gd` | `step(state, inputs, ctx) -> Array`: apply the inputs, then advance one day unless the queue holds a card; returns the sim events (dictionaries with a `kind`, for the UI, the harness and the log). Also `new_run`, `replay` and every rule (a choice, a review, a duel's result, an offer, a move) as static functions |
| `SimContext` | `core/sim_context.gd` | everything the sim reads and never changes (INV-08): the `WorkConfig`, the archetypes, the event and coworker JSON, the background and tiers the duel request borrows, and the run's RNG; `load_default()` builds one from `res://` for the tests and the harness |
| `WorkOdds` | `core/work_odds.gd` | the formulas of GDD 5.15-5.21 as static functions, like `Odds`: the salary table, the daily ticket, Burnout and MO changes, the incident odds, the callback odds, the review's Evidence, rating and stand-in, layoff selection, the auto-resolve chance, the floor multipliers, the duel's inputs, the Studio count |
| `EventPlan` | `core/event_plan.gd` | whether an event can happen (archetype, level and its `requires`), the choices on offer, the final-threat weight and the calendar strip's next 60 days |

**Inputs**, the only way a player or a bot changes the sim: `set_hours {notch}`, `choose {choice}`, `review_result {evidence_left}`, `ticket_pick {pick}`, `duel_result {passed, composure_left}`, `answer_offer {accept}`, `apply {posting}`, `study`, `move_home {tier}`, `push_back`, `set_quality {bar}` and `ack`. A plain Dictionary `{kind, ...}`; an accepted one goes into the run log with the day it was sent on, a refused one becomes an `input_rejected` event and a `rejected` stat. The speed control and pausing are presentation: they decide how often `step` runs, never what it does.

**The queue** is how the sim asks for an answer: `state.queue` holds `event` (a card: its choices and the exhausted one), `review` (your Evidence and the manager's Calibration), `ticket_pick`, `duel` (the DuelRequest of GDD 5.20: Composure, meter multiplier, Doubt HP, floor, tier), `offer`, `layoff_scene` and `forced_leave` items. While it is not empty `step` applies inputs but does not tick, and the matching input resolves the head. A review or ticket pick leaves the queue when its job ends.

**One tick** (GDD 5.14), in the order the code runs and the replay test checks:
1. The calendar and money: day + 1; living costs grow every 180 days; rent and living costs on day 1 of each month; pay accrues daily and is credited on day 25; the days below zero are counted.
2. The daily formulas: ticket progress (a shipped ticket: MO +5 or -5, Skill +2, the next ticket or a Mid's pick), MO, the Codebase's drift, Burnout (clamped between the Burnout History floor and 100; between jobs the same formula without the work-only terms), Rust.
3. The job hunt: the board refreshes every 14 days; replies, interviews and a MegaCorp's second duel come due.
4. The review (E02) and the lease (E04) come due.
5. The telegraphed chains: rumors, the prep card and the fire day (a resizing or the RTO memo).
6. The rolls, on the run RNG in a fixed order: the incident, the other random events (sorted by id), the chain starts. An event with choices rolls the Burnout auto-resolve first (GDD 5.19).
7. The checks: a forced leave, the PIP's end, Scar counters and clears, the Burnout warnings, the Studio hold, Plan B and the Legacy System day.

**Determinism:** one run RNG, seeded once per run (7.2). In memory `SimState` holds the seed and the state as ints; `step` restores `ctx.rng` from them first and stores the state back last, so one context serves many runs and a seed plus the inputs replays a run exactly (O8). Rolls happen only in rule code, in the fixed order above; the archetypes and events are sorted by id before anything rolls; no dictionary order decides anything.

### 19.3 Data files (M1)

| File | Class or shape | Holds | GDD 11.7 owner |
|---|---|---|---|
| `data/types/work_config.gd` + `data/work/work_config.tres` | `WorkConfig` (a `@tool` Resource) | the career run's global constants: the clock, money, Hours, the review, the controls, floors, events, the job hunt, Scars, the Handbook, the win | W |
| `data/types/archetype_data.gd` + `data/archetypes/<id>.tres` (3 files) | `ArchetypeData` | per archetype: `pay_mult`, `remote_share`, `review_cadence_days`, `promotion_rule`, `codebase_start`, `codebase_drift`, `ticket_speed`, `severance_months`, `utilization_mo`, `leave_level_drop`, `calibration_hp`, `duels_per_offer` and the layoff pattern. The ids are `startup`, `agency` and `megacorp` (MC-05, A68, D-34) | A |
| `data/content/work_events.json` | one object per event, keyed `evt_eNN_*` (A54) | E01-E26: tier, archetypes, levels, trigger, telegraph, pause, focus, the card text, choices with their effects, the exhausted choice, Ducky's joke, cause and tip, the diorama cue | E |
| `data/content/coworkers.json` | `cw_*` entries plus `coworker_pool` | Hierarchai's four coworkers and the name pool (CONTENT 16.1) | - |
| `tips.json`, `barks.json`, `endings.json`, `naming.json` (existing) | their shapes in 6.3 | the career run's tips, UI lines, endings and names (CONTENT 16) | - |

- Sections 6.1-6.3 hold: numbers in `.tres`, text in JSON keyed by id, loaded data never modified (INV-08), script defaults equal to the GDD 11.7 defaults, file name = the `id` field.
- INV-15's counts grew with M1: 11 `.tres` (7 + `work_config` and the three archetypes) and 18 JSON (16 + `work_events` and `coworkers`), and `Content` loads all 18 (M3 added `questions_review`: 19); the invariant and section 0.6 say so. The three archetype ids are `startup`, `agency` and `megacorp` (MC-05, A68), each with a `duel_tier` naming the Phase 1 tier its duel borrows.
- **An event's numbers live with it** (A54), as in Phase 1's `events.json`, and the system constants go to `WorkConfig`. A trigger that is a formula, like E12's incident odds, names a `WorkConfig` formula rather than carrying an expression string: `"trigger": {"kind": "incident", "cooldown_days": 5}`. The trigger kinds M1 reads are `monthly`, `review`, `lease`, `after_raise`, `chain` (a telegraphed event that starts from a roll), `resizing`, `random` and `incident`.

The Run Spec's E12 example as JSON, as built (GDD 5.19; its 20-day cooldown is 5 days: MC-23, A69):

```json
"evt_e12_incident_prod": {
  "tier": "random",
  "archetypes": ["startup", "agency", "megacorp"],
  "levels": ["junior", "mid", "senior"],
  "trigger": {"kind": "incident", "cooldown_days": 5},
  "requires": {"employed": true},
  "telegraph": {},
  "pause": true,
  "focus": "war_room",
  "text": "2 a.m. Prod is down. The alerts are loud. Whoever is on call is very quiet.",
  "choices": [
    {"id": "fix_it", "text": "Fix it yourself",
     "effects": {"mo": 10, "burnout": 15, "codebase": -5, "flags": ["owns_service"]}},
    {"id": "escalate", "text": "Wake whoever is on call", "requires": {"not_flag": "owns_service"}, "effects": {"mo": -3, "burnout": 2}}
  ],
  "exhausted_choice": "fix_it",
  "ducky": {
    "joke": "You fixed prod at 2 a.m. Prod now has your phone number.",
    "cause": "Whoever fixes it once becomes whoever fixes it always.",
    "tip": "tip_escalate"
  },
  "final_threat": true,
  "diorama": {"flash": "red_screens"}
}
```

- Section 6.3's rules shape it: explicit lists instead of the YAML's `[any]`, the texts inline like a question's answers (CONTENT 16.3's ids that extend an event id name a field of its entry), and JSON numbers wrapped in `int()` where they are counts. An empty telegraph is `{}` rather than null (proposed), so no reader needs a null check.
- **As built, an event may also carry:** `requires` (on the event or on a choice: `employed`, `remote`, `rto`, `home_min`, `tip`, `clause`, `not_flag`, `deadline_or_incident_days`), `results` (E02's three ratings, with `{n}` for the raise), `final_threat` (the Studio hold's 3x weight), a `text_rent` beside E01's text, and for a telegraphed event a `telegraph` with a `rumor` or, for run 1's resizing, `run1_signs` and `run1_fire_day`. A choice's `effects` use `mo`, `burnout`, `codebase`, `skill`, `rust`, `savings`, `living_mult`, `commute_burnout`, `speed_mod {mult, days}`, `hours_lock {notch, days}`, `flags`, `work_mode` and a named `action` (`lease_accept`, `lease_move_down`, `home_upgrade`, `board_early`, `ask_priya`, `quit_job`, `recruiter_call`). `exhausted_choice` names a choice, or is `"none"` for E07's prep. `ducky.joke` and `cause` exist only for E12 until M6; every event has a `ducky.tip`, a tip id or `"none"` (O7). `coworkers.json` holds `cw_*` entries (name, role, line, level) and `_coworker_pool`.
- `test_data_files` checks the new `.tres` against GDD 11.7, and `test_content_lint` checks every event's shape, its tips and its text budgets, and the coworkers (19.10).

### 19.4 Phases, save and meta (M2, built)

- **New phases are appended** to `GameFlow.Phase` (INV-10, 4.1): `WORK` (the work state, at a job or between jobs: one clock, D-04) and `LAYOFF` (the layoff scene). Both are live phases. The job interview and the review both use `INTERVIEW` (the request says which, 19.5; M3), and the career run's endings use `GAME_OVER` with an ending id (the Plan B card's layout, GDD S12). `PHASE2_STUB` stays in the enum, unused once the career run's Accept beat exists (MC-08, D-34; RC-04).
- **Transitions as built** (`test_flow`): TITLE -> INTRO (run 1, the first time), WORK (run 1 once the intro has been seen, and Continue), BACKGROUND_SELECT (runs 2 and later) or LAYOFF (Continue during the scene); INTRO -> WORK (run 1) or BACKGROUND_SELECT (a replayed intro); BACKGROUND_SELECT -> WORK; WORK -> LAYOFF, GAME_OVER or TITLE; LAYOFF -> WORK or TITLE; GAME_OVER -> TITLE or BACKGROUND_SELECT; and the quit-to-title rows of 4.1. M3 adds WORK -> INTERVIEW and OFFER -> WORK with the adapter.
- **Where New game goes** (A78): `GameState.start_new_game()` begins the career run (`career_flow`). Phase 1's hunt is reachable only through `start_hunt_game()`, the Title's debug-only "Old hunt" button, until M4 retires it (19.9). Continue resumes whichever run the slot holds.
- **The save** (A79): the same one slot (`user://save_v1.json`, temp file then rename: section 8). `SaveIO.kind_of()` tells a career save, `{version: 2, phase, sim, ui}`, from Phase 1's (`RunState.to_dict`, version 1). `sim` is **`SimState.to_save()`** (A75), the run log included: every float as its raw 64 bits in hex, because Godot's JSON parser does not read every double back exactly (`123456789.12345679` comes back one step off) and a save that differs in the last digit resumes into a different future. `ui` is the screen's own state through the same codec: the notices not yet read, the feed, the player's name, `first_run` and the closed coach marks. The clock's speed is not saved: Continue waits, paused (KILL_TESTS 6). `test_work_session` proves a round trip is bit for bit and lives the same days.
- **When it's written** (RC-35, GDD 5.11): only in the live phases; after every answer (each is a committed action), when a notice is dismissed, on a card, a payday, a rent, a shipped ticket or a job's end (`GameState.career_tick` decides), on entering a live phase, and on `APPLICATION_PAUSED`, `FOCUS_OUT` and `WM_CLOSE_REQUEST`. Not on every tick. It is deleted on entering `GAME_OVER`, where the run counts in `run_count` and the tips it showed join `meta.handbook`, as today.
- **No time while closed** (D-13, INV-22): the clock moves only in the `WORK` scene's `_process`, in whole days (`WorkClock`), and only while nothing is open over it: no notice or card (`WorkSession.is_blocked`), no dock app, no Pause, no scene change. `APPLICATION_PAUSED` and `FOCUS_OUT` set the speed to Pause. The sim never reads the wall clock.
- **Meta between runs**, in `settings.cfg`'s `[meta]` (section 8): `run_count` (exists) and `handbook` (the collected tip ids, merged when a run ends; M6 shows them). The proposed `endings_seen` and `studio_wins` wait for the milestones that use them; `last_background` exists. INV-11 holds: nothing but our JSON save and `settings.cfg` is read from `user://`.

### 19.5 The adapter (M3; R-JOB-06, GDD 5.20, 13.4)

Today `interview.gd` reads its three numbers itself (GDD 13.4): `_composure` from `_bg.composure_max`, `_doubt` from `_tier.doubt_hp`, and the meter's half-width from `Odds.zone_half(...)`. A-01 assumed they were inputs; they aren't. The plan:

- **DuelRequest -> the interview checkpoint.** `GameState` turns a DuelRequest into the checkpoint the interview already resumes from (section 8), adding `composure` (base x (1 - Burnout/200)), `doubt_hp` (base x (1 + 0.08 (floor - 1))), `zone_mult` ((1 + Skill/200) x (1 - Rust/200)), `rounds` and `unlocked_options`. `interview.gd` reads them from the checkpoint when they are there and from the `.tres` files when they aren't, so a Phase 1 checkpoint still plays as today.
- **The meter:** `half_width = maxf(cfg.zone_half_base, Odds.zone_half(cfg, s, bonus) * zone_mult)`, so the 0.06 floor clamps Rust (RC-25). S is unchanged, and so are knowledge P and the committee wheel, which keep reading the background's KNOWLEDGE, EXPERIENCE and NETWORK (D-26).
- **Rounds:** `cfg.prompt_pattern` is one fixed 5-prompt pattern today, so a request's `rounds` (5, or 3 for a review) needs the pattern to come from the request. The review's pattern and prompts are an M3 spec gap (GDD 5.16).
- **DuelResult** comes from `GameState.finish_interview(won, composure_left)`: `{passed, composure_left, dream_reality_delta}`, the last following MC-09 (settled, D-34).
- **OfferRequest -> the paper.** A career offer builder fills the same paper as `run.offer` (7.1) from the posting: company, role, salary (GDD 5.15, shown as the yearly figure: MC-10, D-34), work mode, the clauses where the fine print goes (the clause list is an M3 spec gap) and the hidden clause, revealed. `GameState.answer_offer(accept)` then yields `{decision, final_salary, clauses}`, with `final_salary` = the offered salary (no negotiation: D-27).
- The fields are plain-data Dictionaries in snake_case (A55, INV-07). `test_adapter` checks that a request's numbers reach the interview's start values (19.10).

### 19.6 The run log and the harness (M1, built; GDD 5.22, R-BAL, A56)

- **The run log** (RC-26): one entry per accepted input, `{d: day, k: "in", i: input}`, and per outcome (`job`, `exit`, `event`, `review`, `ending`). Not every tick: a tick is a pure function of the state, so the seed plus the inputs replays it. `Sim.replay(ctx, run_number, seed, handbook, log, until_day)` does exactly that, and `ctx.log_enabled = false` turns the log off for speed (the harness). It feeds exact bug replays, the debug report (MC-15) and the win video's captions (GDD 3.4).
- **The harness runs outside `test_run`** (A56): `tests/harness/run_harness.gd`, a `SceneTree` script with the loop in `HarnessRunner` (shared with the smoke test). Living under `tests/` keeps it out of every export, and `test_run` doesn't pick it up, because discovery is `tests/test_*.gd`, non-recursive (12.1). Like the tests, it loads the `.tres` with `load()` and the JSON with `FileAccess` (no autoloads).
- **The commands**, from the repo root (`tools/headless/lib.sh` copies the game into `$PROJ`; `GODOT` overrides the binary):

```bash
bash tools/headless/run_harness.sh bot=planner seeds=10000          # one bot: a RESULT line, then the JSON report
bash tools/headless/run_bots.sh seeds=10000 out=.project/evidence/STEP-14/<run>   # all five, in parallel, one copy each
python tools/headless/sweep.py --seeds 1000 "base=" "a=ticket_deadline_mult:1.3"  # compare configurations without editing a .tres
```

  The harness arguments are `bot`, `seeds`, `first`, `run` (1 starts employed at Hierarchai, 2 and later between jobs), `bg`, `handbook` (`none` or `full`), `out`, `set` (overrides: `field:value`, `arch.startup.pay_mult:0.9`, `bg.start_savings_months:1`, `evt.<id>.<path>:value`; the experiment never touches the repo), `trace=N` (one run's state every N days) and `dump=1` (one CSV line per run).
- **Bots** are classes in `tests/harness/bots/` with `inputs(state, ctx) -> Array`: `BotBase` answers whatever the clock waits on through hooks, `BotCareer` adds the job-hunting competence (the best posting by callback odds x the interview's pass probability x its worth, studying to keep a Resume Gap off, comparing an offer with the job you hold), and the Planner, Coaster, Grinder, Lifestyle and Random bots set the policies (A76). Each rolls on its own RNG seeded from the run seed, so a bot's dice never shift the sim's (the trick of `InterviewPlan.meter_rng`, 7.2).
- **Duels without a thumb:** `DuelModel` resolves an interview with the duel's own formulas (`Odds.knowledge_p`, `stat_score`, `zone_half`, `input_quality`, `answer_q`, the committee wheel), the real question pools and a modeled tap error of 75 ms, as GDD 5.12's bot did; it can also estimate a posting's pass probability, which the bots use. A review is `WorkOdds.review_standin_left` until M3 designs its prompts (GDD 5.16, A67).
- **The speed** (M1's exit): the Planner takes about 40 ms a run (about 7 minutes for 10,000 seeds in one process) and the others 3-10 ms, measured in the evidence run (`.project/evidence/STEP-14/`).
- **Before a tuning commit** (RC-32): the harness for every bot plus the test suites, headless; the report goes to `.project/evidence/STEP-NN/<run>/`.
- **The smoke test in `test_run`** is `tests/test_sim_smoke.gd`: 60 seeds per bot through `HarnessRunner`, asserting no crash, no refused input, known endings, determinism and the loose bands (the Coaster never wins, the Random bot rarely does).

### 19.7 The work state's UI (M2, built)

- **One scene,** `features/work/work.tscn`, the phone shell on section 10.1's skeleton. TopBand (information only): "Day N - what is next" and the Studio chip, the Runway chip, the Burnout bar, the Ticket bar with its days left and the Codebase's 10 LEDs, and the 60-day calendar strip. Body (it takes the extra height): a grey box with the job line and the last five feed lines, until M5's diorama. Then the first-run coach note, and the ThumbBand: the Hours label and five notches (34 px or more, like the S03 selector: A58), the dock (four 60x40 slots) and the action bar, Back at 80 px beside the speed control (Pause, 1x, 2x, 4x) in the primary's 168 px.
- **Cards** are the `EventCard` component in the ModalLayer (10.1): a sheet at the bottom with the card's text and at most three full-width 254x36 buttons that wake after the 250 ms lock (`input_lock_ms`, 10.3), over a dimmer that blocks every tap. Its "=" opens Pause, so Back stays on screen. A card carries ids and numbers, never text (`WorkCards`): the scene looks the words up in the JSON. **Notices** (a rumor, a burnout beat, the auto-resolve line, a review's result, a tip) have one OK. The sim's queue head is an event with its choices, a review, a Mid's ticket pick or the forced leave; an interview or an offer is M2's stub (the adapter is M3). The layoff scene is its own phase (`features/layoff/`: four taps, Back opens Pause).
- **The apps are cards for now:** the dock's four slots open "not in this build yet" and stop the clock, as a real app will (GDD 4.5).
- **The clock driver** is the scene's `_process`: `WorkClock.advance(cfg, delta)` gives whole days (at most four a frame) and each one is `GameState.career_tick()`, which steps the sim, refreshes the screen and saves what is worth keeping. A tick that opens a card, or leaves for another phase, ends the frame's days. Answers are `GameState.career_*` verbs (INV-01, INV-03), which apply one input without a tick (`Sim.apply_inputs`) and save.
- **The pure classes** (17.19): `WorkClock`, `WorkHud` (what the top band shows), `WorkCards` (notices, feed lines and the head card, from the sim's events and queue) and `WorkSession` (the run as the screen plays it: the sim, the clock, the notices, the feed, the coach marks and the exact save). `GameState.session` holds one. The screens' scripts are in 17.20.
- Every screen keeps an on-screen Back (section 9): the work state's opens Pause. The layoff scene follows RC-34: taps advance its beats and Back opens Pause; the hold-to-skip pill (11.2) comes with M3.

### 19.8 The diorama (M5; GDD 2.11)

- A `TileMapLayer` of 16x16 tiles (11.8), a column about three screens tall in the Body, with y-sorted characters. It scrolls like Mail's list, a ScrollContainer drag and never an action gesture (GDD 2.8 rule 5).
- Coworkers walk fixed waypoint lanes (desk, pantry, meeting room, exit) with no pathfinding (R-DIO-03): one list of points per lane.
- **Pause-and-zoom** (R-DIO-04): a `Camera2D` cuts between whole zoom steps (1x, 2x, 3x) on the event's focus location and never tweens through a fractional scale (1.3, RC-19); the nearest filter is already global (1.2).
- **State as sprite and tile swaps** (R-DIO-02): the view reads `SimState` (Burnout -> posture frames, the Codebase -> red LED pixels, headcount -> empty desks, an incident -> red monitors within 3 flashes per second, overtime -> the lamp, remote -> the home room) and has no rules of its own.
- The art follows INV-20: the shipped pixel grid and palette, existing tiles first, labeled placeholders on the same grid until the art exists, nothing commissioned.

### 19.9 What retires

Nothing retires until the career run replaces the Phase 1 flow (MC-01, D-33: that is what `v0.5-mvp` ships, after M4). Then:
- the hub's day loop, `features/job_hunt/` (the deck, Mail, the night screen, the Study panel as it is), with `RunState`'s day-loop fields and rules (the board, applications, Sleep and the morning reveal, the Radar, the day-2 guarantee), their `Odds` formulas and `HuntTips`' hunt tips;
- `features/phase2_stub/` (the Hired card as an ending), once the career run's Accept beat exists (MC-08, D-34); the enum value stays (INV-10);
- TierData's unused `meeting_load`, `layoff_risk` and `growth_mult` (RC-05).

D-27's negotiation code did not wait for MC-01: it left in its own commit on 2026-10-08 (ROADMAP 12, Step 14 task 6): `Odds.negotiate_p`, `Odds.negotiated_salary`, BalanceConfig's `nego_*` fields, the offer's `negotiated` flag, `test_offer`'s negotiation test and the unused strings (CONTENT 16.7). Section 17 was re-synced in that commit. Each retired file's block leaves section 17 in the same commit, through the usual sync.

### 19.10 Tests (M1: 126 tests in six suites; M2: 34 in four more, and 4 in suites that grew; the adapter's is M3)

| Suite | Tests | Covers |
|---|---|---|
| `test_sim_rules.gd` | 46 | GDD 5.14-5.17's formulas, a worked example each: ticket progress, Burnout per day, the idle Burnout, the incident odds and O5's formula, the salary table, the floor multipliers, severance, the callback formula, the duel's inputs; and through `Sim.step`: rent on day 1 and pay on day 25 (run 1 below zero for 24 days), a mid-month start paid for the days worked, moves and leases, tickets, a Mid's pick and push back, Hours notches, Study, applying, a MegaCorp's two duels, offers, Scars from leaving, level carry-over, and refused inputs |
| `test_sim_review.gd` | 14 | Evidence, the rating bands and their boundaries, the stand-in, each archetype's promotion rule, the cadence, the PIP and firing, the lifestyle offer after a raise, a layoff taking the review card with it, the Brag doc edge |
| `test_sim_events.gd` | 27 | the ten events' tiers and eligibility, their choices and effects, cooldowns, the auto-resolve chance and its warning beats, layoff selection with no MO input (O1), run 1's chain days (R-RUN-02) and its day-180 promotion, a generated chain, the prep choices, floor depth, and O5 (incidents at Codebase 80 against 20 through the sim; the spec's 20-day cooldown fails it) |
| `test_sim_endings.gd` | 19 | the Studio fires only with all five conditions held 90 days and resets to zero on a break (O6, Q-06); the final threats' weight; each hard loss's trigger; the forced leave; every Scar, its stack cap and its counterplay |
| `test_sim_replay.gd` | 11 | the same seed and inputs give the same run; a run replays from its log; a `to_save` round trip mid-run is bit for bit and lives the same days (O8); seeds and RNG states are strings (INV-05); the state is plain data (INV-07) |
| `test_sim_smoke.gd` | 8 | the harness's small version (19.6): 60 seeds per bot, clean and deterministic, the Coaster never wins |
| `test_data_files.gd`, `test_content_lint.gd` (grown) | 7, 36 | the new `.tres` equal GDD 11.7; in `work_events.json`, the ids, tiers, trigger kinds, the text budgets, ASCII, the banned brands, at most 3 choices, known requirements and effects, a tip or an explicit none for every event (O7), and every exhausted choice names one of its event's choices; the coworkers |
| `test_work_clock.gd` | 6 | Pause runs no day; 1x is a day a second whatever the frame rate; 2x and 4x follow `WorkConfig.speeds`; a hitch never fast-forwards a month; a card throws away the half-built day; the speed position is clamped |
| `test_work_hud.gd` | 6 | the top band's numbers: Runway in months and red under two, Burnout, the Codebase's 10 LEDs, the Ticket and its deadline, the Studio chip, the label ids and the calendar strip |
| `test_work_cards.gd` | 11 | the notices and feed lines the sim's events leave, the head card for each queue kind, the layoff scene not being a card, an event's `{money}` and `{home}`, and the severance a layoff card carries |
| `test_work_session.gd` | 11 | the clock waits paused; `tick()` refuses while a notice or a card is open (INV-22); answers never burn a day; a whole job plays through to the layoff on day 240 with its five signs and its review; the save round trip is exact and lives the same days (KILL_TESTS 6-8); a run played with inputs between ticks replays from its log; the review stand-in's own dice; the interview and offer stubs; the coach marks; the feed |
| `test_adapter.gd` (M3) | - | a DuelRequest's numbers reach the interview's start values; the 0.06 floor; a Phase 1 checkpoint still works |

`tests/sim_fixture.gd` (`SimFixture`) builds the context the sim suites share: the Run Spec's numbers (`WorkConfig.new()` and archetypes built by hand), so tuning the `.tres` never breaks a worked example.

All of them follow 12.1 and INV-12: `@tool`, `extends McpTestSuite`, at least one assertion, no autoloads, no `user://`.

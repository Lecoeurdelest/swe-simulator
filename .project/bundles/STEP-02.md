# Bundle: STEP-02 (Hello iPhone: the iOS debug build from the MacBook)

Snapshot: 2026-09-27, docs v1.1 (portrait, iPhone first; uncommitted on top of 6f40919). Spec: [ROADMAP Step 2](../../docs/ROADMAP.md), [ARCHITECTURE 13.1, 16, 18.1](../../docs/ARCHITECTURE.md).
State: `todo`, depends on STEP-01 (not done yet). Hours 5, timebox 6, plus 1-2 h of unattended downloads. Decisions: D1, D2, P1 (AD-11, AD-12, AD-13).
Replaces the 2026-09-26 Android bundle "Hello phone" (P1); its criteria AC-S02-1..7 are superseded, see the end of this file.

## Objective

The project runs on the developer's iPhone, built on the MacBook, plus a debug-only device-check screen that answers the questions no desk test can.

## Preconditions

- STEP-01 done, and its portrait commit pushed (the Mac clones or pulls it).
- The MacBook, the iPhone and a USB cable for it.
- Most of the step happens on the Mac. The device-check scene can be built on either machine: push, then pull on the other.

## Criteria (ROADMAP Step 2 Done-when)

| ID | Statement | Method | Replaces |
|---|---|---|---|
| AC-S02-8 | Opens on the iPhone in portrait and doesn't rotate | device | AC-S02-1 |
| AC-S02-9 | The readout shows the ARCHITECTURE 1.1 game size for the model (1179x2556 -> 294x639 integer) | device | AC-S02-2 |
| AC-S02-10 | The safe-area outline clears the Dynamic Island (or notch) and the home indicator: about 45 top / 26 bottom game px on an iPhone 15 or 16 | device | AC-S02-3 |
| AC-S02-11 | monogram and Press Start 2P are crisp at 4x | device | new |
| AC-S02-12 | One-handed, every thumb-band button is reachable; any that aren't are written down | device + written | new |
| AC-S02-13 | Dragging the list never fires a button; a deadzone of 6 feels right; the answer is written down | device + written | AC-S02-5 |
| AC-S02-14 | The 40 ms haptic is felt; whether 10 ms is felt is noted | device + written | AC-S02-6 |
| AC-S02-15 | Home and reopen: PAUSED and RESUMED counters went up, state intact; Control Center raises FOCUS_OUT; haptics still work after resuming | device | new |
| AC-S02-16 | A swipe up from the bottom edge needs two swipes to leave the game | device | new |
| AC-S02-17 | The on-screen Back counter goes up | device | AC-S02-4 |
| AC-S02-18 | You know where logs appear: Xcode's console, or Godot's Output panel with one-click deploy | manual | AC-S02-7 |
| AC-S02-19 | The install date is written down (7-day Personal Team expiry) | written | new |

## Toolchain (ARCHITECTURE 13.1)

| Need | Value |
|---|---|
| macOS | Godot 4.7 needs macOS 13+ on Apple silicon; Xcode sets the real floor (Xcode 27 needs macOS 26.6+) |
| Xcode | the version that supports the iPhone's iOS (iOS 27 needs Xcode 27) |
| Godot | exactly **4.7.2**, the universal zip from godotengine.org (never auto-updates) |
| Export templates | exactly **4.7.2.stable**, iOS |
| Apple account | a free Apple ID (Personal Team); the paid program only from Step 13 |

Personal Team limits: provisioning profiles expire 7 days after they're issued (the app stops launching; press Run in Xcode again), 3 devices, 10 App IDs per 7 days, 3 apps per device.

## Tasks (ROADMAP Step 2)

1. Developer: check the Mac (chip, macOS) and the iPhone (iOS) against the table. If the Mac can't run the Xcode the phone needs, stop.
2. Developer: Xcode from the App Store, license, Apple ID in Settings > Accounts, Manage Certificates > Apple Development.
3. Developer: Godot 4.7.2 zip into Applications; `git clone https://github.com/Lecoeurdelest/swe-simulator.git`; open, reimport; install the iOS export templates.
4. Developer (optional, recommended): godot-ai and Claude Code on the Mac (ARCHITECTURE 16: uv, local scope, Configure).
5. Developer: fonts into `res://ui/fonts/`: monogram (CC0), Press Start 2P (OFL) and its license as `OFL.txt`.
6. Developer: Team ID = the Organizational Unit of "Apple Development: <you>" in Keychain Access.
7. Developer, with Claude reading the checklist: the iOS preset (below).
8. Claude, on either machine: the device-check scene (below).
9. Developer: USB, Trust This Computer, then Developer Mode (the toggle appears only after Xcode has seen the phone).
10. Developer: Export Project into `builds/ios/`, open the `.xcodeproj`, Signing = Personal Team, Run (Cmd+R); trust the Apple ID in VPN & Device Management on first launch; optional one-click deploy; write down the install date.
11. Claude: record the results in ARCHITECTURE 18.1 (and GDD 2.9 if the insets differ); the developer commits and pushes.

## iOS preset (ARCHITECTURE 13.1 task 4)

Runnable ticked; `application/app_store_team_id` = the Team ID; `application/bundle_identifier` = `com.<you>.swesimulator` (pick once, never change); `export_method_debug` Development; `export_project_only` **on**; `min_ios_version` 15.0; `targeted_device_family` **0 = iPhone**; `icon_interpolation` **0 = Nearest neighbor**; storyboard custom bg color `Color(0.07, 0.07, 0.1)`, image scale Center; `accessible_from_files_app` off; capabilities and privacy at their defaults; exclude `addons/godot_ai/*, tests/*` (plus `features/dev/*` for release builds); include `ui/fonts/*.txt`. Orientation comes from `display/window/handheld/orientation = 1`, not the preset.

## Claude does

- `features/dev/device_check.tscn` (portrait, debug only), opened by a small "Device check" button on the title stub:
  - readout: window size, game size, stretch mode, `Device.safe_insets()`, `OS.get_name()`;
  - a 1 px outline of the SafeAreaMargin (island and home-indicator margins);
  - one line of monogram 16 and one of Press Start 2P 8/16, with the ARCHITECTURE 1.4 import settings;
  - a ScrollContainer with 20 buttons (36 px tall), plus "pressed" and "scrolled" counters;
  - Haptic 10 ms and Haptic 40 ms buttons (`Device.haptic()`);
  - counters for `APPLICATION_PAUSED`, `APPLICATION_RESUMED` and `APPLICATION_FOCUS_OUT`;
  - an on-screen Back button with a counter (its `handle_back()` returns true and counts).
- Reads the preset checklist with the developer, explains any export or Xcode error pasted, and updates ARCHITECTURE 18.1 (and GDD 2.9) with the results.

## Developer does

Every install, the Apple ID signing, the preset, the phone setup and pressing Run. The design huddle: D1 on real hardware (thumb reach to every thumb-band button, top HUD readable at arm's length).

## Outputs

- `features/dev/device_check.tscn` (and its script), the "Device check" button on `features/title/`.
- `export_presets.cfg` with the iOS preset (committed; credentials stay in `.godot/`).
- `ui/fonts/monogram/ttf/monogram.ttf` (the developer's layout), `ui/fonts/PressStart2P-Regular.ttf`, `ui/fonts/OFL.txt` and their `.import` files.
- ARCHITECTURE 18.1 results (#1 drag release, #2 deadzone unit, #3 window override on iOS, #5 safe area, #6 fonts, #7 haptics, #10 one-click deploy), GDD 2.9 if the insets differ.
- `builds/ios/` is git-ignored: never commit it.

## Out of scope

- Android export and Google Play (LATER, ARCHITECTURE 13.2).
- The paid Apple Developer Program and TestFlight (Step 13).
- `gui/theme/custom` and the UI kit (Step 3).

## Invariants

INV-02 (the device check opens through a debug-only path, never `change_scene_*()` from a gameplay scene: agree the approach before building), INV-14 (containers, SafeAreaMargin, hit areas at least 34x34), INV-17 (Godot 4.7.2 and 4.7.2 templates on the Mac too; commit before any engine update).

## Verification and evidence

- Every criterion is a device observation or a written note: the developer's confirmation goes into `.project/state.json`. godot-ai can't see the phone, so paste Xcode's console output; keep pasted logs or screenshots in `.project/evidence/STEP-02/<run>/`.
- On the PC, `test_run` stays 24/24 after the device-check scene is added.

## Stop conditions

- Past 6 hours: stop and paste the exact error.
- The Mac can't run the Xcode the iPhone's iOS needs (task 1).
- A doc edit beyond recording the device results needs the developer's approval.
- Never run installers through Claude on Windows (MSIX AppData virtualization); on the Mac the developer installs too.

## Superseded (2026-09-27, P1)

| Old ID | Old statement (Android, as in the 2026-09-26 bundle) | Replaced by |
|---|---|---|
| AC-S02-1 | Opens in landscape, both ways up | AC-S02-8 |
| AC-S02-2 | Readout shows the ARCHITECTURE 1.1 game size for the phone's screen (2400x1080 -> 600x270 integer) | AC-S02-9 |
| AC-S02-3 | Safe-area outline clears the camera cutout | AC-S02-10 |
| AC-S02-4 | Back doesn't quit: the counter goes up | AC-S02-17 |
| AC-S02-5 | "Does dragging the list fire a button?" answered; the deadzone feels right | AC-S02-13 |
| AC-S02-6 | Haptic button vibrates | AC-S02-14 |
| AC-S02-7 | Phone output appears in the editor (remote debug) | AC-S02-18 |

None were evaluated.

### The Mac's Android toolchain (observed 2026-09-26; ISSUE-01, now resolved: Android is LATER, ARCHITECTURE 13.2)

Kept verbatim from the 2026-09-26 bundle for when Android returns. The last row matters for iOS too: the Mac had no 4.7.2 export templates installed, so Step 2 task 3 installs the iOS ones.

| Need (ARCHITECTURE 13.1 v1.0) | Found |
|---|---|
| OpenJDK 17 | **no system JDK** (`java_home` finds none). Android Studio's bundled JBR exists, version unchecked |
| Platform-Tools >= 35 | present in `~/Library/Android/sdk/platform-tools` (not on PATH) |
| Build-Tools 35.0.1 | **missing** (35.0.0 and 36.0.0 present) |
| Platforms 35 and 36 | 36 present, **35 missing** |
| cmdline-tools, NDK 28.1.13356709, CMake 3.10.2.4988404 | **missing** |
| Export templates 4.7.2.stable | **not installed** |

The old bundle's Android preset notes (package `com.<you>.swesimulator`, arm64-v8a, immersive, vibrate, the same exclude and include filters, Runnable) are now in ARCHITECTURE 13.2.

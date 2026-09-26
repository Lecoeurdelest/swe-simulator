# Bundle: STEP-02 (Hello phone: the Android debug build)

Snapshot: 2026-09-26, docs at 64ed38f. Spec: [ROADMAP Step 2](../../docs/ROADMAP.md), [ARCHITECTURE 13.1, 18.1](../../docs/ARCHITECTURE.md).
State: `todo`, depends on STEP-01. Hours 5, timebox 6.

## Objective

The project runs on the developer's Android phone, plus a debug-only device-check screen that answers the questions no desk test can.

## Criteria

| ID | Statement | Method |
|---|---|---|
| AC-S02-1 | Opens in landscape, both ways up | device |
| AC-S02-2 | Readout shows the ARCHITECTURE 1.1 game size for the phone's screen (2400x1080 -> 600x270 integer) | device |
| AC-S02-3 | Safe-area outline clears the camera cutout | device |
| AC-S02-4 | Back doesn't quit: the counter goes up | device |
| AC-S02-5 | "Does dragging the list fire a button?" answered; the deadzone feels right | device + written |
| AC-S02-6 | Haptic button vibrates | device |
| AC-S02-7 | Phone output appears in the editor (remote debug) | device |

## Toolchain on this Mac (observed 2026-09-26; ISSUE-01: the docs assume Windows)

| Need (ARCHITECTURE 13.1) | Found |
|---|---|
| OpenJDK 17 | **no system JDK** (`java_home` finds none). Android Studio's bundled JBR exists, version unchecked |
| Platform-Tools >= 35 | present in `~/Library/Android/sdk/platform-tools` (not on PATH) |
| Build-Tools 35.0.1 | **missing** (35.0.0 and 36.0.0 present) |
| Platforms 35 and 36 | 36 present, **35 missing** |
| cmdline-tools, NDK 28.1.13356709, CMake 3.10.2.4988404 | **missing** |
| Export templates 4.7.2.stable | **not installed** |

The developer installs these (Android Studio's SDK Manager is easiest on macOS). The Android SDK path for Godot is `~/Library/Android/sdk`; the Java path is the JDK 17 home.

## Claude does

- `features/dev/device_check.tscn` (debug only), opened by a "Device check" button on the title stub: readout (window size, game size, stretch mode, `Device.safe_insets()`, OS name); 1 px SafeAreaMargin outline; ScrollContainer with 20 buttons (32 px) plus pressed/scrolled counters; Haptic button (`Device.haptic(40)`); Back counter (`handle_back()` returns true and counts).
- Explains any export error the developer pastes.
- Records results in ARCHITECTURE 18.1 (also ISSUE-02: `root.size` is ignored in the Game tab).

## Developer does

Every install, the export preset (package `com.<you>.swesimulator`, arm64-v8a, immersive, vibrate, exclude `addons/godot_ai/*, tests/*`, include `ui/fonts/*.txt`, Runnable), USB debugging on the phone, one-click deploy.

## Invariants

INV-02 (the device check opens through a verb or a debug-only path, never `change_scene_*()` from a gameplay scene: agree the approach before building), INV-14, INV-17.

## Stop conditions

- Past 6 hours: stop and paste the exact error.
- Any doc edit that replaces the Windows instructions needs the developer's approval (ISSUE-01).

# STEP-06 intro stage: the data-driven text-slide intro with hold-to-skip

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings.
ROADMAP Step 6 task 5, per ARCHITECTURE 9, 10.1-10.4, 11.2 and GDD S02, 2.5-2.8, 4.4; CONTENT.md 2.
Tests: `intro_test_run.txt` (224/224, 21 suites; 220/20 after the endings stage).

This stage started from the committed endings stage: no intro work had been written before the usage-limit break.

## What changed

| File | Change |
|---|---|
| `features/intro/cutscene_plan.gd` (new, `class_name CutscenePlan`, pure `@tool`, like `UiText`) | `panels(entries)`: the cutscene.json panels in `order` (ties by id), each `{id, order, seconds, captions: [{speaker, text, style}]}`; entries without an order or a caption with text are skipped. `total_seconds(plan)`. `pan_path(picture, frame)`: start and end position of a panel's picture, from its size (GDD 2.6): wider than the frame pans sideways, taller tilts down, frame-sized stays still; whole pixels. `STYLE_TITLE = "title"`. |
| `features/intro/hold_skip_pill.gd` (new, `class_name HoldSkipPill extends Button`) | "Hold to skip": `button_down` starts a 0.5 s hold (`HOLD_S`, GDD S02) while a ring fills (`draw_arc`, amber on a faint track, left of the right-aligned label); `button_up` before that empties it; `held` fires once. `cancel()` for focus loss. Mouse only (touch arrives as emulated mouse). |
| `features/intro/intro.gd` (rewritten) | The player. Panels from `CutscenePlan.panels(Content.entries("cutscene"))`. Each panel: a generated grey placeholder in the 270x480 frame (frame size read from Project Settings), panned by one sine in-out Tween over the panel's `seconds`. Captions typed at `BalanceConfig.typewriter_cps` (40) by tweening `visible_ratio`; a tap finishes the caption being typed, the next tap shows the next caption (then the next panel, then the end). A `title` caption hides the picture (smash to black) and the dialogue box, and slams the title card in (2x for 0.05 s, then 1x, 40 ms haptic). Every exit (the tap after the last caption, the pill's `held`, `handle_back()` for Esc / Android Back) goes through `_leave()` once, which calls `GameState.finish_intro()`. Focus out / app paused: the pan and typewriter tweens pause and a hold in progress is cancelled; focus in / resumed: they play on. |
| `features/intro/intro.tscn` (rebuilt on the ARCHITECTURE 10.1 skeleton, same uid) | Root (STOP: takes the taps nothing else takes) > Background (near-black 0.07/0.07/0.10) > Stage (CenterContainer) > Frame (270x480, clip) > Picture (TextureRect) · SafeArea > Column (254) > TopBand (debug-only panel readout) · Body (centred TitleCard: PanelContainer + HeaderLabel at Press Start 2P 24, line spacing 4, word wrap) · ThumbBand (separation 10): DialogueBox 254x72 (Panel + margins 7/4/7/4 + NameTab HeaderLabel + Line with `visible_characters_behavior = CHARS_AFTER_SHAPING`, so words never jump lines while typing) and ActionBar 34 px (alignment end): TapHintPanel (PanelContainer + "Tap to continue") and SkipPill 96x34 · ModalLayer. The stub's `[ < Back ]` and `SKIP` buttons are gone. |
| `tests/test_intro.gd` (new, suite `intro`, 4 tests) | See `intro_test_run.txt`. |

No content, GameState, SceneRouter, Device or doc file changed. `start_new_game()` (auto-play only while `intro_seen` is false), `replay_intro()` and `finish_intro()` (sets `intro_seen`) were already right.

## The screen (270x480)

- Frame 270x480 at (0, 0); on 294x639 it sits centred on the near-black at (12, 79), whole pixels, the picture clipped to it.
- Debug readout (debug builds only) in the top band: `intro_p3  caption 1/3`.
- Title card 254x94 at y 141 (3 lines: SOFTWARE / ENGINEER / SIMULATOR), the same place with and without the dialogue box.
- Dialogue box 254x72 at y 360-432 (GDD S02): name tab y 364-372, text 240 px = 40 columns from y 374, room for 4 lines.
- Action bar y 442-476: "Tap to continue" 104x34 on its own panel at x 8 (first caption only), the pill 96x34 at x 166-262 (GDD S02: 96x34, y 442-476, bottom-right).
- 294x639 with insets (0, 45, 0, 26): column x 20, readout y 45, box y 497-569 (over the panel's bottom 62 px), pill y 579-613 = 639 - 26.

## Verification

Runs 68-71 (`project_run` main). Input: real `input_mouse` taps (motion, press, release; window px = 2x game px) and real `input_key Escape`. game_eval was used for: state reads; resetting `intro_seen` to false before each skip test (so each skip had to set it again); `Engine.time_scale` 0.1 / 0.25 so a screenshot could catch a caption mid-typing and the ring mid-fill (restored to 1.0); the 0.2 s short press (injected press/release, because two tool calls can be more than 0.5 s apart); the focus-loss checks (`NOTIFICATION_APPLICATION_FOCUS_OUT/IN` sent through the tree, since focus events of the game embedded in the editor are unreliable, ISSUE-02); the same-frame exit guard; the 294x639 KEEP content scale with SafeArea fake insets (0, 45, 0, 26), restored to EXPAND 270x480.

| Check | Result | Detail |
|---|---|---|
| test_run all | pass | 224/224, 21 suites (`intro_test_run.txt`). |
| First New game auto-plays the intro | pass | Runs 68, 69, 71 with no `settings.cfg`: Title "Tap to start" (real tap) -> INTRO. |
| Full playthrough by taps | pass | Run 69: all 6 panels and 15 captions by real taps, in order: p1 (narration, 2), p2 (REMY, 3), p3 (REMY, 3; the 57-char line wraps at "That's / called efficiency."), p4 (narration, no name tab), p5 (2), p6 ("2026.", REMY, the title card, "How did you spend those four years?"). Each tap did exactly one thing: finished the line being typed, or showed the next caption. The tap after the last caption -> `finish_intro()` -> Background select; `settings.cfg` then held `intro_seen=true`, and no run save existed. |
| A tap finishes the caption, the next advances | pass | Run 69 at 0.1x: "Comm" on screen (typing, ratio 0.14); a real press on "Standup: 12 minutes. Pants: optional." at ratio 0.09 -> ratio 1.0, still caption 3/3; the next tap -> panel 3. |
| Title card | pass | Runs 69, 70: picture hidden (black), box hidden, card 254x94 with 3 lines, scale back to 1 with a centred pivot (127, 47). Run 69 showed the card jump from y 182 to y 141 when the last caption's box came back; fixed (the box now hides with modulate and keeps its place); run 70: y 141 on the title caption and on the last caption. |
| Pan | pass | p1's placeholder panned 0 -> -24 px over its 6 s; p2 at x -1 one second in, -7 later; the picture changes shade at every cut. |
| "Tap to continue" | pass | Run 71: shown on its panel (8, 442, 104x34) once caption 1 is typed; the first advancing tap hides it for good; the pill stays at (166, 442). |
| Short press does not skip | pass | Run 70, p1 caption 1: injected press held 182 ms -> ring 0.36, release -> 0, still INTRO on the same caption (the pill kept the press from counting as a caption tap). |
| Hold to skip, early | pass | Run 70, p1 caption 1, `intro_seen` reset to false: real press on the pill (screenshot: the ring filling), `held` -> BACKGROUND_SELECT, `intro_seen` true; release. Run 71, p1 caption 2: the same from a fresh first run. |
| Hold to skip, middle | pass | Run 70, p3 caption 1 while typing, at 0.25x: real press, screenshot with the ring part-filled (0.41), still INTRO; kept holding -> `held` -> BACKGROUND_SELECT, `intro_seen` true. |
| Hold to skip, late | pass | Run 70, p6 caption 4/4 (the last caption, under the title card): real press -> BACKGROUND_SELECT, `intro_seen` true. |
| Esc skips | pass | Run 70, p6 caption 3/4 (the title card), `intro_seen` false: real Escape -> Device.handle_back -> BACKGROUND_SELECT, `intro_seen` true. Again on p1 caption 1: Escape skipped; a second Escape that arrived after the fade acted as Background select's Back (-> Title), as ARCHITECTURE 9 says. |
| One exit only | pass | Run 70: `handle_back()` twice plus the pill's `held` in the same frame -> exactly 1 phase change, no error. |
| The next New game skips the intro | pass | Run 70 with `intro_seen=true`: Title tap -> BACKGROUND_SELECT directly. |
| Replay intro | pass | Run 70, seven times: Background select `< Title` (real tap) -> Title -> "Replay intro" (real tap, 8, 442, 86x34) -> INTRO from panel 1, with `intro_seen` already true. |
| Pauses on focus loss | pass | Run 70: typing ratio 0.040 stayed 0.040 for 1 s after FOCUS_OUT, 0.606 0.4 s after FOCUS_IN; p2's pan stayed at x -1 for 1.5 s unfocused, -7 after refocus; a hold at 0.485 dropped to 0 on FOCUS_OUT and did not skip in the next 0.6 s of holding. |
| Layout 294x639 + insets | pass | See "The screen" above; screenshot checked; restored to 270x480 (box 360-432, pill 442-476). |
| Game log | pass | Runs 68-71: 0 errors, 0 warnings (only the helper line and "Content: 3 backgrounds, 3 tiers, 16/16 JSON files"). Run 69 stopped once at a debugger break raised by my own game_eval (it read `_panel` on the Background select scene), not by the game. |
| Files on disk | pass | Only the 7 intro files above changed; LF endings; `intro.tscn` was reloaded into the editor from disk after every external write, and the save-before-run never rewrote it. |
| Cleanup | pass | `settings.cfg` deleted after runs 69, 70 and 71; no `save_v1.json`; `user://` holds only godot_ai_server.pid and the engine's folders. Project stopped; the editor is back on job_hunt.tscn. |

## Agent defaults, please review (W4)

1. **Tap to advance only, no auto-advance** (ARCHITECTURE 11.2, GDD S02 and ROADMAP "tap to advance" describe taps only). A panel's `seconds` is how long its picture pans; the pan then holds until the player taps on. The intro's length is the player's: the typing alone is about 11 s at 40 chars/s; the pans add up to 40 s. An auto-advancing version (the panel's seconds split across its captions) is the alternative.
2. **"Tap to continue" hint** (the existing `ui_tap_to_continue`) on its own small panel bottom-left, only after caption 1 is typed and until the first advancing tap, so a first-time player knows the captions wait for a tap.
3. **Pans and tilts only, no zoom.** A zoom scales the art by non-integer factors, which GDD 2.5 and ARCHITECTURE 1.3 forbid. The motion follows the picture's size (GDD 2.6: 480x480 pans sideways, 270x720 tilts down, 270x480 stays still). The grey-box placeholder is 294x480, so each panel drifts 24 px sideways (sine in-out), a checkerboard in 3 alternating greys so the motion and the cuts show.
4. **Title card:** the picture cuts to black and the caption box hides; "SOFTWARE ENGINEER SIMULATOR" in Press Start 2P 24 (3 lines) on a full-width panel in the middle band, dropped in at 2x for 0.05 s then 1x with a 40 ms haptic, like the ending stamps. It stays up under the last caption.
5. **Speaker names** in capitals in the amber name tab, as Dana's in the interview; narration shows no name tab.
6. **No on-screen Back button in the intro:** the pill is the screen's on-screen way out. A `[ < Back ]` that skips would be a one-tap skip next to a hold-to-skip. Esc (and Android Back, LATER) still skip.
7. **Focus loss** pauses and resumes without a "Ready?" overlay (nothing is lost, the intro waits for taps anyway); a hold in progress is cancelled.
8. The first picture shows under the fade-in; the first caption types after it, and taps before that do nothing. Taps act on the press, as the interview's dialogue does.
9. A hold keeps counting if the finger slides off the pill (the Button keeps the press until the release).
10. A missing or empty cutscene.json goes straight to Background select.

Not decided (developer's call): none of the huddle questions of Step 6 concern the intro.

## Content ids added (need developer sign-off)

None. The screen uses the existing `ui_skip_hold` and `ui_tap_to_continue` (the latter still awaits sign-off from the endings stage).

## You-do queue (W3, unchanged)

- Choose the fine-print jokes you like best (ROADMAP Step 6 You-do).
- Kill the app on your iPhone at the 5 moments and check Continue (device, P2).
- On the iPhone (P2): hold the pill with a real thumb; swipe to the app switcher or open Control Center mid-intro and check it pauses and resumes.

## Doc follow-ups for the Doc sync stage (not edited here)

- ARCHITECTURE 2: `features/intro/` now holds intro.tscn + intro.gd, cutscene_plan.gd (`CutscenePlan`, a pure helper like `UiText`) and hold_skip_pill.gd (`HoldSkipPill`); the note "The intro's DialogueBox is still to be built in Step 6" is done (it lives inside intro.tscn, not as a shared component).
- ARCHITECTURE 3 and invariants INV-03: list `CutscenePlan` next to `UiText` as a pure `@tool` helper.
- ARCHITECTURE 9 table: Intro loses focus -> pauses the pan and typewriter tweens and cancels a hold.
- ARCHITECTURE 11.2: as built (tap-only advance; the pan from the picture's size; no zoom; the title card; the hint; the 294x480 grey placeholder).
- ARCHITECTURE 12.2 and 17.13: `tests/test_intro.gd` (suite `intro`, 4 tests).
- Contradiction 1: GDD 2.5 says intro panels share the bottom-anchored portrait template; GDD 2.6 and ARCHITECTURE 11.2 say the panel sits centred on the near-black. Built centred (the more specific rules).
- Contradiction 2: ARCHITECTURE 11.2 says a panel "pans, tilts or zooms"; GDD 2.5 / ARCHITECTURE 1.3 forbid non-integer scaling. Built without zoom.

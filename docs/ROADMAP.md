# SWE Simulator: Roadmap to the MVP

| | |
|---|---|
| Version | 1.3, 2026-10-07: the career run (Run Spec v1, DECISIONS W8) added as section 12, its milestones M1-M6 tracked as STEP-14..STEP-19, with M1 the next step (W9); status notes on sections 2-3 and Steps 7-11, the art pipeline without commissioning (D-21), the career run's playtest gates (7) and risks 13-19 (8). 1.2, 2026-09-29 (portrait, iPhone first): the grey-box review cut CV editing and lying (D9) and suspended the "You do" exercises (W7) |
| For | You, a first-time game developer, building with Claude Code and godot-ai |
| Target | A **portrait** game for **your iPhone**, developed on the Windows PC and built on the MacBook. Android is LATER (`docs/DECISIONS.md` D1, P1) |
| What the game is | `docs/GDD.md` (design) and `docs/CONTENT.md` (every string) |
| How it's built | `docs/ARCHITECTURE.md` (engine settings, code structure, verified code skeletons) |

This is the step-by-step plan from an empty project to a mobile MVP. Every step has the same parts:

| Part | What it tells you |
|---|---|
| **Goal** | what exists when the step is done |
| **Best practice** | the game-dev habit the step teaches |
| **Tasks** | the work |
| **Claude and godot-ai do** | the parts Claude builds |
| **You do (to learn)** | small, deliberate tasks so you understand your own game. **Suspended since 2026-09-29 (`docs/DECISIONS.md` W7):** Claude builds those features too. What only you can do stays yours: installs, signing, anything on the iPhone, and your sign-offs |
| **Design huddle** | the design decisions we brainstorm in that step |
| **Done when** | checkboxes you can tick yourself |
| **Hours** | your hours, not Claude's |
| **Pitfalls** | what usually goes wrong |

---

## 1. How game development is structured

Studios move through the same phases whatever the size of the game. Here's how each maps onto this project:

| Phase | The question it answers | What a studio does | Here |
|---|---|---|---|
| **Pre-production** | What are we making, for whom, and why is it fun? | pitch, pillars, design doc, scope | **Done:** the GDD, CONTENT, this roadmap, and your decisions in `docs/DECISIONS.md` (Step 0) |
| **Foundation** | Can we build it and run it on the target device? | engine setup, pipelines, a build on the device | **Steps 1-2** (Step 1 done; Step 2 puts it on your iPhone) |
| **Prototype / grey-box** | Is the loop fun and understandable? | ugly, fast builds made of boxes and text | **Steps 3-7**: the whole loop in grey boxes on your iPhone, then Playtest #1 |
| **Vertical slice** | What does "finished" look like? | one part built to final quality | **Step 9**: the interview, fully drawn and polished |
| **Production** | Build everything else to that bar | art and content at scale | **Steps 8, 10, 11** |
| **Polish (alpha, beta)** | Does it feel good, and does it survive real phones? | juice, audio, bugs, performance | **Steps 12-13** |
| **Release / live** | Can players get it? What comes next? | store builds, updates | after the MVP: the App Store release (TestFlight already runs in Step 13), Android LATER, then **Phase 2: The Working Life** (since 2026-10-07 the career run, built as M1-M6: section 12) |

### Best practices you'll use at every step

1. **Find the fun with placeholders first.** A grey box costs a minute to change; finished art costs days. If the loop is boring in grey, art won't save it.
2. **Keep numbers in data, not code.**
   - Tuning lives in 7 `.tres` files you edit in the Inspector.
   - Text lives in JSON.
   - You should be able to rebalance the game without opening a script.
3. **Keep rules separate from presentation.** Formulas live in pure classes (`Odds`, `RunState`), which tests and a balance simulation can run. Scenes only display.
4. **Run it on the real phone early, then every week.** One-thumb reach, small text, the Dynamic Island and home indicator, touch and performance only reveal themselves on your iPhone.
5. **Commit small and often.** Every time something works, commit. When something breaks, it then costs you minutes, not days.
6. **Test automatically what a human shouldn't have to check.** That means the formulas, the save format, the flow rules and the content rules (text length, banned brand names).
7. **Playtest in silence.** Watch people play and don't explain. Where they hesitate is where the design fails.
8. **Cut scope early.** Everything is tagged MUST, SHOULD or LATER. A new idea replaces something; it never just adds.
9. **The vertical slice sets the bar.** Make one screen beautiful, then match everything else to it.
10. **Timebox, with the 2x rule.** If a task takes twice its estimate, stop, then cut it or simplify it.
11. **Keep a decision log.** Each decision is one line with a reason, in `docs/DECISIONS.md` (it holds D1-D12, P1-P3, C1-C4, W1-W9, the Run Spec's D-01..D-25, P-01..P-08 and Q-01..Q-07, your later design decisions D-26 onward, and the agent defaults A1 onward). It stops you from re-arguing the same thing in week 6.

---

## 2. The MVP

**In one sentence:** on an iPhone held upright in one hand, a player watches or skips the intro, picks a background, hunts for jobs in the DoomApply phone app until an interview invite lands, survives a fighting-game interview with Dana, and accepts or declines an offer. Every failure teaches a real career tip.

**Run Spec v1 status:** this is Phase 1's MVP, as the v0.1 grey-box built it. The career run (section 12) changes what the game is: which game `v0.5-mvp` ships is settled (MC-01, D-33): the career run. The Work loop listed as out of scope below is now the career run (W8).

**Out of scope for the MVP:**
- the Work loop (Phase 2), and walking characters
- cosmetics, typing (except the optional name), online features and monetization
- localization. All text is in JSON and goes through `tr()`, so it can be translated later.

### Definition of done (player-visible, from GDD 10.1)

- [ ] The game installs on your iPhone from Xcode, opens in portrait (it never rotates), and reaches the title quickly.
- [ ] **Intro:**
  - 6 panels with captions, 40 s or less.
  - **Hold-to-skip** (desktop Esc also skips).
  - It plays on the first run only. "Replay intro" is on the title.
- [ ] **Background select:** one full-width card at a time (3 stat bars, energy pips, rent runway, 1 perk and 1 flaw), a 3-button selector, and a name dice button.
- [ ] **Job hunt (the DoomApply phone app with a bottom dock):**
  - 6 new cards per day, at most 10 on the board. The card front shows the logo, title, 3 match tags, a joke and the odds band.
  - **Swipe right or APPLY** = Quick Apply (1 energy). **Flip** gives Tailor & Apply (2 energy).
  - Study (2 energy); the Intern's 2 referrals; Sleep.
  - Energy, rent and the Recruiter Radar are always visible.
- **CV screen:** cut on 2026-09-29 (D9). Your CV is your background's true CV; Tailor & Apply sends its honest Polished lines.
- [ ] **Morning inbox:** invites first, rejections as one stack, ghosts stay silent. The first run guarantees an invite on day 2.
- [ ] **Companies:** 6 companies (2 per tier) and 3 interview backgrounds. The tiers differ in odds, reply speed, Doubt HP, needle speed, question pool, salary and work mode.
- [ ] **VS intro:** a 2 s clip that then waits for a tap (D12), with a bust for each background and Dana in 3 outfits.
- [ ] **Interview:**
  - Composure and Doubt bars; 5 prompts; the Answer Meter. (The lie probe was cut: D9.)
  - Endings: K.O., the committee wheel, or rejection.
  - There is **always a tip plus the model answer** after a loss.
- [ ] **Offer modal:** role, **yearly** salary, work mode, commute preview, 2 perks and 1 fine-print joke. Accept, or Decline with a confirm.
- [ ] **Endings:** a Hired card with the Dream vs Reality score; a Plan B ending with one-tap Retry; a grace day when an invite is waiting.
- [ ] **Robustness:**
  - Autosave on every action and whenever the app loses focus. Killing the app never loses more than the current screen.
  - Every screen has an on-screen Back, because iOS has no Back button (Android Back is LATER).
  - Every control used more than once a day sits in the bottom 40%, within one thumb's reach.
- [ ] **Content minimums:** 15 knowledge questions, 10 ethics questions, 20 posting templates, 18 CV strings, 10 rejection lines, 15 tips (CONTENT.md has more), plus about 10 sound effects.
- [ ] **Technical:**
  - All tests are green: flow, save, odds, interview, offer, content lint and balance.
  - 60 fps on the oldest iPhone you can borrow; no crash in 10 runs in a row.
  - Every asset's license is recorded, and only parody names are used (the lint enforces it).

**Milestones:**
- `v0.1-greybox`, at the end of Step 6: playable, ugly and complete.
- `v0.5-mvp`, at the end of Step 13: good enough to hand to friends.

---

## 3. The plan at a glance

| Step | What | Your hours | Week (at 15-20 h/week) |
|---|---|---|---|
| 0 | Tools, decisions, reading (git and decisions done) | 3 | 1 |
| 1 | **Project foundation** (done 2026-09-26) | 3 | 1 |
| 2 | **Hello iPhone:** iOS debug build from the MacBook | 5 (timebox 6), plus 1-2 h of downloads | 1 |
| 3 | Stub flow through every screen, plus the UI kit | 8 | 2 |
| 4 | **Interview grey-box** (the riskiest fun first) | 14 | 2-3 |
| 5 | **Job-hunt grey-box** | 16 | 3 |
| 6 | Offer, endings, save/resume, Back, intro text slides | 10 | 4 |
| 7 | **Playtest #1**, tuning, balance simulation | 8 | 4 |
| 8 | SHOULD features, in GDD order (timeboxed) | 16 | 5 |
| 9 | Art style lock plus the vertical slice (the interview) | 20 (x2 if you draw it yourself) | 5-6 |
| 10 | Art production for the rest | 30 | 7-8 |
| 11 | Intro cutscene art | 12 | 8-9 |
| 12 | Audio, juice, accessibility, credits | 10 | 9 |
| 13 | **Playtest #2** and the release candidate | 10 | 10 |

That comes to about **67 hours to the grey-box** (about 4 weeks) and **about 165 hours to the MVP** (about 9-11 weeks). Full-time, halve both.

Art hours are the most uncertain. If you draw everything yourself, double Steps 9-11.

**2026-10-07: the career run (Run Spec v1) is merged into these docs, and M1 starts now** (DECISIONS W8, W9). M1, the career run's sim core, is tracked as STEP-14 and is the next step, ahead of the open Steps 7-13. Its milestones M1-M6 (STEP-14..STEP-19) are section 12:

| Step | Milestone | Your hours (estimate) |
|---|---|---|
| 14 | **M1: the sim core**, headless, with five bots (next: W9) | 3 |
| 15 | M2: the grey-box UI, no diorama; three outside players | 6 |
| 16 | M3: run 1 end to end | 6 |
| 17 | M4: all systems; the Planner wins 5-10% | 6 |
| 18 | M5: the pixel-art office diorama | 40 (you draw it: D-21) |
| 19 | M6: the Handbook, events to about 40, the Ducky pass, tuning | 12 |

Steps 7-13 follow the career run (MC-01, D-33; section 12). The record of the merge, with every conflict and how each was answered: `docs/merge-report.md`.

---

## 4. The steps

### Step 0: Tools, decisions and reading (about 3 h)

- **Goal:** Git works, the engine version is pinned, and every open design decision has your answer.
- **Best practice:** pre-production. Decide before you build, and pin your tools so they can't change under you.
- **Status:** git and the decisions are done (2026-09-26). The Steam setting and the reading are yours to finish.

**Tasks**
1. **Git: done.** Git works on the PC, and the GitHub repo `Lecoeurdelest/swe-simulator` (branch `main`) holds the foundation, committed and pushed. The Mac gets its copy with `git clone` in Step 2 (ARCHITECTURE 14.1).
2. **Pin Godot:**
   - In Steam, set Godot Engine to update only when you launch it. The exact option name is unverified; look under Properties > Updates.
   - On the Mac you'll use the godotengine.org 4.7.2 zip, which never updates itself (Step 2).
   - Never update the engine mid-step. Both machines and the export templates must match 4.7.2 exactly.
3. **Read** (about 2 h):
   - GDD section 0 (one page), 1.2 (the pillars), 2.8 (one-thumb touch rules), 4.1 (the flow) and 12 (the decisions).
   - Skim CONTENT.md to get the tone.
   - Godot docs, "Getting Started > Step by step": nodes and scenes, instancing, scripting, signals.
4. **Design huddle: done.** D1 is portrait only, D2 is 270x480, D3-D8 are the recommended defaults, and P1 is iPhone first. All are in `docs/DECISIONS.md`. The protagonist is **Alex** (re-rollable), and the interviewer is **Dana**.

**Claude and godot-ai do:** done. Claude explained each decision with its trade-off and wrote your answers into `docs/DECISIONS.md`, one line each with the reason.

**You do (to learn):** reread `docs/DECISIONS.md` and say each decision back in your own words, because you own the game's voice.

**Done when**
- [x] Git works, your name and email are set, and the repo is on GitHub.
- [ ] Steam won't update Godot behind your back.
- [x] `docs/DECISIONS.md` lists D1-D8 and P1, each with your answer and one line of why.

**Pitfalls**
- Running installers through Claude. Your setup note warns about MSIX AppData virtualization: files can land where other programs can't see them. Run installers yourself.
- Rewriting the GDD. It's done. The decision log is where you change your mind, one line at a time.

---

### Step 1: Project foundation (Claude: about 1 h of tool calls; you: about 3 h)

- **Goal:** a correctly configured, version-controlled project that boots to a title stub, with the core architecture and 24 passing tests.
- **Best practice:** decide resolution, folders, naming and architecture once, before any content. Commit the ignore files before the first commit. Have tests from day one.
- **Status: done (applied 2026-09-26, including the switch to portrait).** The title stub reads `window (540, 960)` / `game (270, 480) (integer)` with no runtime errors, and `test_run` passes 24/24. The tasks below are the record of what was done. The "You do (to learn)" tasks are still yours.

**Preconditions**
- Godot is open on this project **before** Claude starts.
- The editor is not playing.
- Step 0's Git is installed. If it isn't, do everything below except the commit.

**Tasks.** Claude runs these in this order. All code is in ARCHITECTURE section 17; copy it verbatim. (Section 17 now shows these files as they are at the end of Step 5; the Step 1 versions are in the `init` commit, 64ed38f.)

1. **Preflight.**
   - Run `editor_state`.
   - Run `project_manage op=settings_get key=display/window/stretch/mode`, which should return `"disabled"`.
2. **Project settings** (ARCHITECTURE 1.2). Use `project_manage op=settings_set`, one key per call:

   | Key | Value |
   |---|---|
   | `display/window/size/viewport_width` | 270 |
   | `display/window/size/viewport_height` | 480 |
   | `display/window/size/window_width_override` | 540 |
   | `display/window/size/window_height_override` | 960 |
   | `display/window/stretch/mode` | `"viewport"` |
   | `display/window/stretch/aspect` | `"expand"` |
   | `display/window/stretch/scale_mode` | `"integer"` |
   | `display/window/handheld/orientation` | 1 (`SCREEN_PORTRAIT`) |
   | `rendering/textures/canvas_textures/default_texture_filter` | 0 |
   | `rendering/2d/snap/snap_2d_transforms_to_pixel` | true |
   | `rendering/textures/vram_compression/import_etc2_astc` | true |
   | `input_devices/pointing/emulate_touch_from_mouse` | true |
   | `application/config/quit_on_go_back` | false |
   | `application/run/max_fps` | 60 |
   | `gui/common/default_scroll_deadzone` | 6 |
   | `application/boot_splash/use_filter` | false |
   | `application/boot_splash/bg_color` | `Color(0.07, 0.07, 0.1, 1)` |
   | `rendering/environment/defaults/default_clear_color` | `Color(0.07, 0.07, 0.1, 1)` |
   | `debug/gdscript/warnings/untyped_declaration` | 1 |
   | `application/config/version` | `"0.1.0"` |

   Then spot-check three of them with `settings_get`.
   - `settings_set` does no type coercion, so the two Colors go through a throwaway `@tool` test file (ARCHITECTURE 1.2).
   - Don't set `gui/theme/custom` yet (that's Step 3).
   - Don't set `application/run/main_scene` here (see task 7).
3. **Git files at the repo root:** `.gitignore` and `.gitattributes`, with the exact contents from ARCHITECTURE 14.2.
4. **Folders.**
   - Create:
     - `autoload/`, `core/`
     - `data/types/`, `data/balance/`, `data/backgrounds/`, `data/tiers/`, `data/content/`
     - `features/title/`, `features/intro/`, `features/background_select/`, `features/job_hunt/`, `features/interview/`, `features/offer/`, `features/phase2_stub/`, `features/game_over/`, `features/dev/`
     - `ui/theme/`, `ui/fonts/`, `ui/components/`
     - `art/shared/`, `audio/sfx/`, `audio/music/`
     - `tests/`, `art_src/`, `builds/`
   - Put an empty `.gitkeep` in every folder that stays empty after this step.
   - Put an empty **`.gdignore`** in `art_src/` and `builds/`.
5. **Scripts**, created in dependency order:
   1. `data/types/`: `tier_data.gd`, `background_data.gd`, `balance_config.gd`
   2. `core/`: `game_flow.gd`, `run_state.gd`, `save_io.gd`, `odds.gd`
   3. `ui/components/safe_area_margin.gd`
   4. `autoload/`: `content.gd`, `game_state.gd`, `device.gd`, `scene_router.gd`
   5. `features/title/title.gd`
   6. `tests/`: `test_flow.gd`, `test_save.gd`, `test_odds.gd`, `test_interview.gd`, `test_offer.gd`

   Then run **`filesystem_manage op=scan`**, so the new `class_name`s register.
6. **Autoloads.** Run `autoload_manage add` for **`Content`, `GameState`, `Device`, `SceneRouter`, in that order**, keeping `_mcp_game_helper` first. "Identifier not found" errors until all four exist are expected.
7. **Boot scene.**
   - Run `scene_manage create res://features/title/title.tscn` with a root **Control "Title"** (full-rect preset).
   - Add a child **Label "Info"** with `unique_name_in_owner = true` at position (8, 8).
   - Attach `title.gd`, then `scene_save`.
   - Then run **`project_manage set_main_scene res://features/title/title.tscn`**.
8. **Tests.** `test_run` should report **24 passed, 0 failed** (flow 6, save 3, odds 8, interview 4, offer 3).
   - If a suite doesn't load, read `load_errors` in the result, or run `logs_read source="editor"`.
9. **Run it.**
   - Run `project_run`, then `editor_screenshot source="game"`. The label should read `window (540, 960)`, `game (270, 480) (integer)` and `save file: false`.
     - If the editor runs the game embedded in its Game tab (possible since 4.4), the window size is the tab's size. The rule to check is then: game size = floor(window / s), where s = floor(min(W/270, H/480)). For a real 540x960 window, float or undock the game window from the Game tab's toolbar (exact option name in 4.7 unverified).
   - `logs_read source="game"` should show `Content: 0 backgrounds, 0 tiers, 0/16 JSON files` and no errors.
   - To see the guard grow the game area, drag the window to 588x1278: the label switches to `game (294, 639)`. The embedded Game tab ignores `game_eval` resizes (seen 2026-09-26), so a person drags the window edge.
   - Finally, `project_manage stop`.
10. **Commit and push** (you): done for the foundation. The portrait switch (2026-09-26) still needs its own commit:
    - `git add -A`
    - `git status`, and check that **no `.godot/` path** is listed
    - `git commit -m "chore: portrait 270x480, iPhone first"`, then `git push`

**Claude and godot-ai do:** tasks 1-9 (done), then show you the screenshot and the test summary.

**You do (to learn)**
- Open **Project > Project Settings** with Advanced Settings on. Find 5 of the keys above, and say out loud why each one matters.
- Read `core/game_flow.gd` and `core/run_state.gd` line by line, and ask Claude about anything unclear.
- Read `autoload/device.gd`: see how the guard reads 270x480 from Project Settings, and why that meant the portrait switch needed no code change in the math.
- Resize the running game window with your mouse and watch "game" change. Nothing stretches; you just see more or less.
- Make the portrait commit yourself, and push it.

**Design huddle:** none. This is plumbing.

**Done when**
- [x] F5 shows the title stub, reading `window (540, 960)` / `game (270, 480) (integer)`. If the game is embedded in the Game tab, it shows the size the ARCHITECTURE 1.1 rule predicts for that window.
- [ ] Resizing the window changes the game size, and nothing blurs or stretches.
- [x] `test_run` shows 24 passed.
- [x] The Output panel shows no errors.
- [ ] `git status` is clean, everything is pushed, and `.godot/` is not tracked.
- [ ] You can explain in one sentence each:
  - what an autoload is;
  - why only `change_phase()` changes the phase;
  - why the RNG state is saved as a string.

**Pitfalls**
- **Moving or renaming files in Windows Explorer or Finder** breaks references. Always use Godot's FileSystem dock.
- **Editing while the game runs:** godot-ai rejects edits during play. Stop first.
- **Skipping the scan:** forget `filesystem_manage op=scan` after a new `class_name` and you get "Could not find type".
- **Setting `gui/theme/custom` before the theme exists.**
- **Committing before `.gitignore` exists** puts `.godot/` in history forever.
- **Switching to the Mac with unpushed work.** Push first (section 10).

---

### Step 2: Hello iPhone, the iOS debug build from the MacBook (about 5 h; timebox 6 h)

- **Goal:** the project runs on your iPhone, plus a device-check screen that answers the questions no desk test can.
- **Best practice:** test on the target device early. Toolchain pain is cheapest in week 1.
- **Time:** about 5 h of your time, timebox 6 h, plus 1-2 h of unattended downloads (Xcode is large; the download time is unverified).

**Preconditions**
- The portrait commit from Step 1 is pushed.
- You have the MacBook, your iPhone and a USB cable for it.
- Most of this step happens on the Mac. The device-check scene can be built on either machine: push, then pull on the other.

**Tasks**
1. **Check the Mac and the phone** (you, 10 min). On the Mac: Apple menu > About This Mac (chip and macOS version). On the iPhone: Settings > General > About (iOS version). Compare them with the ARCHITECTURE 13.1 table: an iPhone on iOS 27 needs Xcode 27, which needs macOS Tahoe 26.6 or later. If the Mac can't run the Xcode your phone needs, stop and tell Claude.
2. **Xcode** (you): install it from the App Store, open it once and accept the license. In **Xcode > Settings > Accounts**, add your Apple ID (it shows as Personal Team), then **Manage Certificates... > + > Apple Development**.
3. **Godot on the Mac** (you):
   - Download the **4.7.2** universal zip and the export templates from godotengine.org. Use exactly 4.7.2, not a newer version, and move Godot to Applications.
   - Clone the repo (`git clone https://github.com/Lecoeurdelest/swe-simulator.git`; ARCHITECTURE 14.1), open `project.godot` and let it reimport. The first open is slow.
   - **Editor > Manage Export Templates**: install the iOS templates.
4. **godot-ai and Claude Code on the Mac** (you; optional, recommended): follow "Setting up godot-ai on the Mac" in ARCHITECTURE 16. Then start `claude` in the repo and say "We're on Step 2". It reads `.agent/AGENTS.md` (through the `.claude/CLAUDE.md` symlink), which points it at `docs/` and the plan tracking, so it knows the project.
5. **Fonts, early** (you download; Claude can't download files for you): **monogram** from datagoblin's itch.io page (CC0) and **Press Start 2P** (OFL) plus its license text saved as `OFL.txt`, all three in `res://ui/fonts/`. Moving this here from Step 3 lets the device check show real text.
6. **Team ID** (you): Keychain Access > login > My Certificates > "Apple Development: <you>" > copy the **Organizational Unit** (ARCHITECTURE 13.1, task 3).
7. **iOS preset** (you, with Claude reading the checklist). Use **Project > Export > Add... > iOS**, with the ARCHITECTURE 13.1 table:
   - the Team ID, and the bundle id `com.<you>.swesimulator` (pick it once, never change it)
   - `export_project_only` on, `targeted_device_family` iPhone, `icon_interpolation` Nearest neighbor
   - exclude `addons/godot_ai/*, tests/*`; include `ui/fonts/*.txt`
   - Runnable ticked
8. **Device check** (Claude, on either machine). Build `features/dev/device_check.tscn` (portrait, debug only), opened by a small "Device check" button on the title stub. It has:
   - a readout of the window size, game size, stretch mode, `Device.safe_insets()` and `OS.get_name()`;
   - a 1 px outline of the SafeAreaMargin, so you can see the island and home-indicator margins;
   - a line of monogram 16 and one of Press Start 2P 8/16, with the font import settings from ARCHITECTURE 1.4;
   - a **ScrollContainer with 20 buttons (36 px tall)**, with a "pressed" counter and a "scrolled" counter;
   - **Haptic 10 ms** and **Haptic 40 ms** buttons (`Device.haptic()`);
   - counters for `APPLICATION_PAUSED`, `APPLICATION_RESUMED` and `APPLICATION_FOCUS_OUT`;
   - an **on-screen Back** button with a counter (its `handle_back()` returns true and counts).
9. **Phone** (you):
   - Connect it by USB and accept **Trust This Computer**.
   - Once Xcode has seen the phone, turn on **Settings > Privacy & Security > Developer Mode**, restart, and confirm. The toggle doesn't appear before that.
10. **Build and run** (you):
    - **Project > Export > Export Project** into `builds/ios/`, open the `.xcodeproj` in Xcode, set Signing to your Personal Team, pick your iPhone and press Run (Cmd+R).
    - The first launch says "Untrusted Developer": **Settings > General > VPN & Device Management > your Apple ID > Trust**, then open it again.
    - Optional: try **one-click deploy** from the Mac editor, so errors from the phone appear in Godot's Output panel (unverified with a Personal Team).
    - **Write down the install date.** The build stops launching after 7 days; press Run in Xcode again.
11. **Record results** (Claude): update ARCHITECTURE 18.1 (and GDD 2.9 if the insets differ), then you commit and push.

**Claude and godot-ai do:** the device-check scene, reading the preset checklist with you, explaining any export or Xcode error you paste, and updating the docs with the results. godot-ai can't see the phone, so paste what Xcode's console shows.

**You do (to learn):** every install, the Apple ID signing, the preset, the phone setup and pressing Run. Seeing the game on your own iPhone is the milestone.

**Design huddle:** D1 (portrait) on real hardware. Hold the phone in one hand: can your thumb reach every button in the thumb band (the bottom 40%, GDD 2.8), including the far corner? Is the top HUD readable at arm's length?

**Done when**
- [ ] The app opens on your iPhone in portrait and doesn't rotate.
- [ ] The readout shows the game size ARCHITECTURE 1.1 predicts for your model. For example, 1179x2556 gives 294x639 integer.
- [ ] The safe-area outline clears the Dynamic Island (or notch) and the home indicator: about 45 top and 26 bottom game px on an iPhone 15 or 16.
- [ ] monogram and Press Start 2P are crisp at 4x.
- [ ] One-handed, every thumb-band button is reachable. You wrote down any that aren't.
- [ ] Dragging the list never fires a button, and a deadzone of 6 feels right. You wrote down the answer.
- [ ] The 40 ms haptic is felt. You noted whether 10 ms is.
- [ ] After going home and reopening, the PAUSED and RESUMED counters went up and the state is intact. Control Center raises FOCUS_OUT. Haptics still work after resuming.
- [ ] A swipe up from the bottom edge needs two swipes to leave the game.
- [ ] The on-screen Back counter goes up.
- [ ] You know where logs appear: Xcode's console, or Godot's Output panel with one-click deploy.
- [ ] You wrote down the install date (7-day expiry).

**Pitfalls**
- **Templates not matching 4.7.2** exactly, or a different Godot version on the Mac.
- **A Team ID that isn't the 10-character code:** export fails with a "JSON error".
- **A bundle ID someone else already registered:** change the `<you>` part once, before anything ships.
- **No Developer Mode toggle:** the phone hasn't been connected to Xcode yet.
- **"Untrusted Developer" on first launch:** trust your Apple ID in VPN & Device Management.
- **An iPhone on a newer iOS than your Xcode supports.**
- **Personal Team limits:** 3 apps per device, 10 App IDs per 7 days, and the 7-day expiry.
- **Steam auto-updating Godot on the PC**, so the two machines drift apart.
- **Past 6 hours:** stop, and paste the exact error to Claude.

---

### Step 3: Stub flow through every screen, plus the UI kit (about 8 h)

- **Goal:** you can tap through every screen and both endings on your iPhone. It's grey boxes and text, but the real navigation, save and Back rules are in place.
- **Best practice:** skeleton first, flesh later. One Theme makes everything consistent. Create data files before features need them.

**Tasks**
1. **Fonts:** already in `res://ui/fonts/` since Step 2. If not, download them now (you; Claude can't download files for you): monogram (CC0), Press Start 2P (OFL) and its `OFL.txt`.
2. **Font import and theme** (Claude).
   - Font import settings from ARCHITECTURE 1.4, then reimport.
   - Build `ui/theme/main_theme.tres` with `theme_manage`:
     - default font monogram 16;
     - Button minimum height 34 (the GDD 2.8 hit area); answer and action-bar buttons are 36;
     - type variations `PrimaryButton`, `DangerButton`, `PaperPanel` and `HeaderLabel`, all flat colors for now.
   - Then `settings_set gui/theme/custom res://ui/theme/main_theme.tres`.
3. **The 7 `.tres` data files** (Claude). Use `resource_manage create`, with the values in the ARCHITECTURE 6.2 tables.
4. **Components** (Claude):
   - `confirm_dialog.tscn`: a full-screen dimmer set to STOP, a PaperPanel and 2 buttons;
   - `pause_menu.tscn`: a bottom sheet with Quit to title on top and RESUME at the bottom; tapping outside = Resume (ARCHITECTURE 10.1);
   - `ducky_note.tscn`: a placeholder full-width tip note.
5. **The real Title** (Claude), minus the art:
   - tap anywhere to call `start_new_game()`;
   - `[ New game ]` above a full-width **CONTINUE** when a save exists;
   - Replay intro;
   - the version label;
   - "Quit?" on Back (Android and desktop only; never on iOS).
6. **Stub scenes** (Claude) for INTRO, BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER, PHASE2_STUB and GAME_OVER. Each shows its name, sits inside a SafeAreaMargin with the ARCHITECTURE 10.1 skeleton, implements `handle_back()` from ARCHITECTURE 9, has an on-screen Back (`[ < Back ]`, or `[=]` on the hunt) that calls `Device.handle_back()`, and has buttons that call the real verbs:
   - Intro: Skip calls `finish_intro()`.
   - Background select: 3 buttons call `choose_background(id, "Alex")`.
   - Hunt: "Fake invite (Mid)" calls `start_interview({...})`, "Study", "Sleep", "Rent runs out" calls `end_run_plan_b()`, and Pause.
   - Interview: "Win" calls `finish_interview(true, 70.0)`; "Lose" calls `finish_interview(false, 0.0)`.
   - Offer: Accept calls `answer_offer(true)`; Decline asks for confirmation, then calls `answer_offer(false)`.
   - Hired and Plan B: Title calls `quit_to_title()`; New run / Retry calls `retry()`.

**Claude and godot-ai do:** everything except downloading fonts. Then Claude clicks through the whole flow with `game_manage` input and takes screenshots.

**You do (to learn)** (superseded by the real screen in Step 5, A16; suspended, W7): build the **Background Select stub layout yourself** with Containers: inside the SafeArea, a 254 px wide VBoxContainer holding one PanelContainer card (it expands), an HBoxContainer of 3 selector buttons, and the `[ < Title ][ CHOOSE ]` action bar (80 + 168) at the bottom. Containers are the single most important Godot UI skill for this game.

**Design huddle**
- D5 (the fail state): now that Plan B is a real screen, is "one funny ending plus Retry" right?
- Is the name dice pool good?

**Done when**
- [ ] On the iPhone, you can go Title > Intro > Background select > Hunt > Interview > Offer > Hired > Title, and Hunt > Plan B > Retry, using one thumb.
- [ ] **Quit to title** mid-hunt makes **Continue** appear, and Continue resumes the hunt. After Plan B or after leaving the Hired card, Continue is gone.
- [ ] Every screen has an on-screen Back that does the right thing; desktop Esc does the same.
- [ ] Body text is monogram 16 and readable at arm's length. No hit area is smaller than 34x34 px.
- [ ] `test_run` is still green.

**Pitfalls**
- Placing Controls by absolute position instead of using containers.
- **A scene calling `change_scene_*()`**. That's forbidden: scenes call verbs, and SceneRouter changes scenes.
- An invisible full-screen Control that blocks taps. Check its `mouse_filter`.

---

### Step 4: Interview grey-box, the riskiest fun first (about 14 h)

- **Goal:** the interview is tense, readable and fair, and it runs on the real formulas.
- **Best practice:** prototype the core mechanic first. Make luck visible. Tune numbers, not code.

**Tasks**
1. **Content** (Claude). Convert these CONTENT.md sections into JSON:
   - `questions_choice`, `questions_knowledge`, `barks`, `companies`, `tiers`, `backgrounds`, `naming`
   - Use the shapes in ARCHITECTURE 6.3: explicit tier lists, ASCII only.
   - Start **`tests/test_content_lint.gd`**: parsing, ids, text budgets, banned brands, ASCII.
2. **Question picking** (Claude), in `start_interview`:
   - 2 choice and 3 knowledge questions from the tier's pools, minus the ones already seen this run.
   - On the first interview of the first run, add the warm-up question.
   - Store the ids in the checkpoint and mark them seen.
   - Put the picking in a pure helper and add a test.
3. **`versus_intro.tscn`** (Claude): grey shapes on an AnimationPlayer, 2 s, skippable after 1 s the first time (ARCHITECTURE 11.5). Since 2026-09-29 (D12) it holds its last frame and waits for a tap, and Dana's plate shows one joke stat and one move.
4. **`interview.tscn`** (Claude), per ARCHITECTURE 11.6 and GDD S08:
   - the stage band on top, with a tier background color and magenta 96 px bust placeholders;
   - the bars band, and a dialogue box with the typewriter, tap-to-finish and the `[II]` pause;
   - stacked 254x36 answer buttons in the thumb band, with the 250 ms lock;
   - the **Answer Meter** (ARCHITECTURE 17.11) in the meter row with zone labels, the tap pad under it, and the tap rule (`[II]` keeps its own taps);
   - the endings: K.O., committee wheel, rejection plus the Ducky card;
   - the ready overlay when the tree is paused, and the pause menu.
5. **Lie-probe UI** (Claude): Come clean / Bluff, using `Odds.bluff_p`. (Built, then cut on 2026-09-29: D9.)
6. **Debug tools** (Claude): an outcome panel, plus `debug_quick_start` with a fake checkpoint, so `project_run mode="custom"` opens the interview directly.

**Claude and godot-ai do:** all of the above. Then Claude plays 10 interviews through `game_manage` and `game_eval`, and reports the Doubt and Composure traces.

**You do (to learn)**
- Build **`hp_bar.tscn`** yourself: a ProgressBar, plus a second "ghost" bar that tweens down to the new value over 0.4 s. (Built by Claude on 2026-09-29: the exercises are suspended, W7.)
- Change `doubt_hp` in `data/tiers/mid.tres` in the Inspector, replay, and feel the difference. (Dropped: the exercises are suspended, W7.)

**Design huddle**
- **D3:** does the Answer Meter feel good? Check needle speed, zone width, and the PIVOT at startups.
- **D8, first look:** Doubt HP of 118 / 128 / 132, too easy or too hard?

**Done when**
- [ ] On the iPhone, interviews at the three tiers feel different: startup PIVOT, Big's fast needle.
- [ ] You can see your odds (the zone width) before the needle moves, your thumb never covers the needle, and Dana's reactions explain what happened.
- [ ] You've seen every outcome at least once: K.O., wheel win, wheel loss, Composure 0, and a rejection with a tip plus the model answer. (BUSTED was cut: D9.)
- [ ] Killing the app mid-interview (swipe it away in the app switcher), then Continue, replays the **same questions**.
- [ ] `test_run` is green, including `test_content_lint`.

**Pitfalls**
- Letting the thumb matter more than the stats. Keep the formula: Q = 0.75 S + 25 I.
- Answer buttons that aren't full width and 36 px tall, or a meter bar drawn where the thumb rests.
- Shuffling with `Array.shuffle()`. Use `Odds.shuffled` with the interview RNG.
- The tap that finishes the typewriter also picking an answer. That's what the 250 ms lock prevents.

---

### Step 5: Job-hunt grey-box (about 16 h)

- **Goal:** the hunt half of the loop is playable, a little funny, and reaches an invite by day 2 on the first run.
- **Best practice:** find the fun with a placeholder color code: magenta characters, blue interactables, grey backgrounds. Simulate with tests before you test with humans.

**Tasks**
1. **Content** (Claude): `postings`, `cv_lines`, `emails`, `tips` and `names` JSON. Extend the lint:
   - 9 CV lines per background (6 since D9: Honest and Polished only), with the honest flags matching the `.tres`;
   - the posting knockout counts;
   - the pool sizes.
2. **Rules on `RunState` and `Odds`** (Claude), each with a test:
   - **Board:** deal 6 cards per day (2 per tier), keep at most 10; applied template+company pairs never come back; unapplied ones can return as "Reposted".
   - **Tags sent:** Quick Apply sends the Honest lines, Tailor & Apply the Polished ones (the `cv_levels` setting was cut: D9).
   - **Applying:** Quick, Tailor or referral; knockouts; relevance; P_invite. (Recording the lies sent was cut: D9.)
   - **The morning reveal**, rolled **in send order on the reveal morning**:
     - a knockout rejects the next morning;
     - ghost postings stay silent;
     - the Radar invite (it counts only relevant, non-knockout applications);
     - the P roll;
     - the silent share, with silent applications turning into "ghosted" after 7 days;
     - invites are valid for 2 days.
   - **The day-2 guarantee** (first run only).
   - **Sleep:** one commit that produces `morning_report`.
   - **Plan B:** the check, plus the grace day.
3. **Background select, for real** (Claude), per ARCHITECTURE 11.3: one card built from data (stat bars, pips, runway, perk, flaw and the Self-Taught's gaps), the 3-button selector, the card swipe, and the name dice.
4. **`job_hunt.tscn`** (Claude), per ARCHITECTURE 11.4 and GDD S04-S06: your phone running DoomApply:
   - the HUD, the app header and the bottom dock (Jobs, Mail, Study, Sleep; the CV tab was cut: D9);
   - the deck with swipe and the `[=] SKIP APPLY` action row, and the card back;
   - the CV screen (Buzzwordsmith) (built, then cut on 2026-09-29: D9);
   - Mail (the morning inbox) with "Flip all", the lock-screen night summary, Study;
   - Ducky coach notes on the first run (GDD 4.3). Since 2026-09-29 (D11) a tap on the note closes it too.
5. **The real lie-probe trigger** (Claude), in `start_interview`, per GDD 5.8.5. (Built, then cut on 2026-09-29: D9.)

**Claude and godot-ai do:** all of the above. Then Claude simulates 30 taps on Apply and confirms an invite arrives by day 2.

**You do (to learn)**
- Write 5 posting jokes of your own (60 characters or less) into `postings.json`. The lint tells you if one is too long. (Dropped: the exercises are suspended, W7.)
- Build the 5-segment **`stat_bar`** component yourself. (Built by Claude on 2026-09-29: the exercises are suspended, W7.)
- Judge the one-thumb swipe feel on the iPhone.

**Design huddle**
- **D4** (lying depth), now that the CV screen exists. (Answered 2026-09-29: D9 cut the CV screen and lying.)
- **D6** (customization is the background plus the name dice).
- Is 6 cards a day the right pace?

**Done when**
- [ ] On a Medium first run, an invite arrives on the morning of day 2, after 3-5 minutes of play.
- [ ] Knockout rejections name the knockout, ghosts stay silent, and the Radar fills only with relevant applications.
- [ ] Wasting energy until rent runs out reaches Plan B, with a grace day when an invite is waiting.
- [ ] Killing the app right after Sleep (swipe it away in the app switcher), then Continue, shows the **same** morning.
- [ ] You laughed at least once.

**Pitfalls**
- Lists that eat or fire taps. Apply the Step 2 ScrollContainer result.
- More than about 30 words on a card.
- Rolling outcomes at send time instead of on the reveal morning.

---

### Step 6: Offer, endings, save/resume, Back, intro text slides (about 10 h)

- **Goal:** the full loop runs from start to finish, survives being killed, and every screen handles Back.
- **Best practice:** on mobile, robustness is a feature. Test the unhappy paths on purpose.

**Tasks**
1. **Content** (Claude): `endings` and `cutscene` JSON, plus the offer section of `emails.json` (perks, fine print, `offer_*`).
2. **The full offer and `offer.tscn`** (Claude).
   - `finish_interview` builds the whole offer:
     - the job title from the posting;
     - 2 perks and 1 fine-print joke for the tier, picked on the offer's own RNG, seeded from the interview checkpoint (ARCHITECTURE 7.2), so a resumed interview builds the same contract;
     - the equity text at startups.
   - `offer.tscn` is a paper contract with **Decline + confirm**, and **ACCEPT**.
3. **`phase2_stub.tscn`** (Claude): HIRED, the Dream vs Reality rows, `tip_written_offer`, and TO BE CONTINUED.
4. **`game_over.tscn`** (Claude): the Plan B text, the background line, the run stats and **Retry**.
5. **The intro as text slides** (Claude), driven by `cutscene.json`: typed captions, tap to advance, hold 0.5 s to skip, desktop Esc skips, and `intro_seen` is set.
6. **Pause sheet** on the hunt, interview and offer, and the on-screen Back and Back chain on every screen (ARCHITECTURE 9). Claude writes a kill-test checklist: [`docs/KILL_TESTS.md`](KILL_TESTS.md).

**Claude and godot-ai do:** all of the above, keeping the round-trip tests green.

**You do (to learn)**
- Choose the fine-print jokes you like best. (Dropped: the exercises are suspended, W7.)
- **Kill the app on your iPhone at 5 moments** (swipe it away in the app switcher: mid-hunt, right after Sleep, mid-interview, on the offer, on the Hired card) and check Continue each time. It's an iPhone check, so it stays yours under W7. [`docs/KILL_TESTS.md`](KILL_TESTS.md) has the steps, what each Continue should show, and a row for your results.

**Design huddle**
- **D7:** should Negotiate be the second SHOULD? (Answered 2026-10-07: Negotiate is removed, D-27.)
- Is the Dream vs Reality footer funny or smug? (Answered 2026-09-29: neither clear nor funny, so it was rewritten: C4.)

**Done when**
- [ ] 3 full runs on the iPhone (Easy, Medium, Hard) with no crash.
- [ ] All 5 kill tests resume correctly. A kill on the Hired card resumes at the offer; leaving the Hired card clears the save.
- [ ] The intro can be skipped at any moment and never auto-plays again.
- [ ] Tag **`v0.1-greybox`**.

**Pitfalls**
- Saving Node references.
- Forgetting to clear `morning_report` on "Start day".
- A Decline that doesn't blacklist the company.

---

### Step 7: Playtest #1, tuning and the balance sim (about 8 h)

**Run Spec v1 status:** settled (MC-01, D-33). Task 1 (Playtest #1) folds into the M2 gate (STEP-15, section 7), and task 3's Phase 1 balance sim is replaced by the career run's R-BAL harness (STEP-14, built), which takes ISSUE-09 with it. Tasks 2 (the Run Report screen) and 4 (tuning, and the D8 revisit) are decided at the M2 gate, with the career run's local run log (MC-15, D-34) as the report. What this step already did stays done: the developer's review of the v0.1 grey-box (PR #6).

- **Goal:** evidence that the loop is fun and fair, before you spend weeks on art.
- **Best practice:** playtest in silence, tune data rather than code, and automate the balance check.

**Tasks**
1. **Run Playtest #1** (you), following section 7, with 3-5 people on your iPhone. Re-run the build from Xcode the day before, so the 7-day signing can't expire mid-session.
2. **Run Report screen** (Claude), debug builds only. It shows:
   - time to the first interview and applications per interview;
   - pass/fail and the worst question;
   - run length;
   - whether the intro was skipped, and at which panel;
   - tips seen.
3. **Balance simulation** (Claude): port the GDD 5.12 bot into `tests/test_balance.gd` (ARCHITECTURE 12.4). Use 3 methods of about 1,000 runs each, and assert the bands. Since D9 the bot's Quick Apply sends the honest CV, so expect it to run a little harder than the GDD 5.12 table (ISSUE-09).
4. **Tuning** (Claude and you): tune the `.tres` files only, rerun the sim, and **decide D8**.

**Done when**
- [ ] 3 of 5 testers finish a loop without help.
- [ ] `test_balance` is green: the GDD 5.12 bands, or the new ones you chose for D8, written in `DECISIONS.md`.
- [ ] Each tester can name one career tip afterwards.
- [ ] You have a ranked fix list, and the top 3 are fixed.

**Pitfalls**
- Explaining the game while they play.
- Defending the design.
- Adding features instead of fixing confusion.

---

### Step 8: SHOULD features, in GDD 10.2 order (timebox 16 h)

**Run Spec v1 status:** settled (MC-01, D-33). The hunt's SHOULDs (tasks 1, 3, 5 and 8: Research, Network and the site tabs, the commute strip, the morning events and the Unicorn) are parked, and drag-to-sign (task 6) moves to M3 (STEP-16). Task 2 was removed (D-27). The rest of this step runs after M4, with Steps 9-12.

- **Goal:** the highest-value extras, in priority order, until the timebox runs out.
- **Best practice:** scope by priority and time, not by wish.

**Tasks.** Build in this order:
1. **Research** on the card back. It reveals ghosts, red flags and the real salary, and unlocks the insider "Why us?" answer. The balance and the teaching lean on it, so build it first and rerun the sim.
2. One-tap **Negotiate** (removed 2026-10-07, DECISIONS D-27: the contract modal stays Accept or Decline).
3. **Network** plus the 3 site tabs.
4. The static top-down **room hub** with 4 hotspots.
5. The Hard-mode **commute strip**.
6. **Drag-to-sign**. (The background-check screen for degree lies was cut with lying: D9.)
7. Parallax and idle animations. These overlap with Step 9, so do them there.
8. Morning event cards, plus the Unicorn posting.
9. The **Career Notebook**, plus **Settings**: Relaxed Timing, reduced motion, text speed, haptics and replay intro. Relaxed Timing is a single bool; pull it forward if a tester struggled with the needle.
10. Haptics and 2 music loops (with Step 12).
11. Dana's per-company lines and the "laid off too" gag.

Stop at the timebox. Anything unbuilt goes to the cut list (section 11).

**Done when**
- [ ] Research has shipped and been tested on the iPhone. (Negotiate was removed: D-27.)
- [ ] The sim has been rerun: GDD 5.12 predicts research pushes first-interview pass rates up by 10-15 points.
- [ ] The cut list is updated.

---

### Step 9: Art style lock and the vertical slice: the interview (about 20 h; double it if you draw it yourself)

**Run Spec v1 status:** no commissioned art (D-21): task 4's "draw, buy or commission" becomes draw or reuse, and buying a pack is Settled (MC-16, D-34): free or CC0 packs only unless you OK one. The art and release steps (9-13) come after M4 (MC-01, D-33).

- **Goal:** one screen at final quality. It becomes the reference for everything else.
- **Best practice:** the vertical slice sets the quality bar before production.

**Tasks**
1. Write the style guide and export a palette file (section 5).
2. Make the interview art:
   - the tier backgrounds (1 first, then 3) at 330x400, bottom-anchored at the desk line (the essential area is the bottom-centre 270x160);
   - the **Dana bust**: 3 outfits x 4 expressions, 96 px;
   - **3 player busts**;
   - the 9-slice panels and the bar art;
   - the final VS intro;
   - juice: hit-stop, shake, damage numbers;
   - about 5 sound effects.
3. **Claude:** imports, 9-slice setup, AnimationPlayer tracks, the hit-flash and palette-swap shaders, parallax.
4. **You:** draw, buy or commission (section 5), and judge what "feels right".

**Done when**
- [ ] A portrait screenshot of the interview could go on a store page.
- [ ] It runs at 60 fps on your iPhone.
- [ ] The palette and sizes are written in the style guide.

---

### Step 10: Art production for the rest (about 30 h)

**Run Spec v1 status:** the career run adds the office diorama and the home rooms at M5 (STEP-18, GDD 2.11), and D-21 applies here too (no commissioned art). It comes after M4 (MC-01, D-33).

- **Order, by time spent on screen:**
  1. the DoomApply skin (HUD, dock icons) and card art;
  2. 6 company logos (16x16) and the icons;
  3. the background-select portraits;
  4. the title screen;
  5. the offer paper;
  6. the 2 ending cards;
  7. the room hub, if you built it.
- **Rules:**
  - Placeholders set the size: every placeholder already has the final size and pivot, so swapping art never needs a code change.
  - The art naming convention is in ARCHITECTURE 2.

**Done when**
- [ ] No magenta or grey placeholders are left.
- [ ] You've done a pass at 270x480, 294x639 and 330x717, and a pass on the iPhone.

---

### Step 11: Intro cutscene art (about 12 h)

**Run Spec v1 status:** run 1 skips Background select, so the intro's last caption has to hand over to day 0: Settled (MC-11, D-34), a new last caption (CONTENT 16.6). The panels pan or tilt but never zoom (A19; "zooms" below predates A19).

- **The piece:** 6 portrait panels (270x480; up to 480x480 for a sideways pan, 270x720 for a tilt) from CONTENT.md section 2, as a motion comic: still panels, pans, tilts and zooms, 2-4 frame loops (a glowing phone screen, blinking), and typed captions. Keep the focal content in the top 350 px: captions cover the bottom.
- **The build:** the Step 6 slide system stays. You only swap in the art.
- **The audio cues** are in the CONTENT table.

**Done when**
- [ ] The intro is 40 s or less.
- [ ] Skip works at any moment.
- [ ] A tester who watched it all can tell you why the character wants a remote SWE job, and what went wrong by 2026.

---

### Step 12: Audio, juice, accessibility, credits (about 10 h)

- **Audio:**
  - about 10 sound effects (MUST, section 6);
  - 2 music loops (SHOULD);
  - buses: Master, Music (about -8 dB under SFX), SFX.
- **Juice:** button press scale, typewriter blips, and the REJECTED stamp (GDD 9.1).
- **Accessibility:** Reduced Motion, Relaxed Timing, text speed, and a haptics toggle.
- **The Credits screen:** every asset and its license, and the OFL text for Press Start 2P.
- **App icon and launch screen:** a 32 or 64 px pixel-art icon upscaled by a whole number to 1024x1024 for the iOS preset (icon interpolation Nearest neighbor), and the launch screen in the near-black splash color (ARCHITECTURE 13.1).
- **Performance:** a pass on the oldest iPhone you can borrow.

**Done when**
- [ ] Sound can be muted.
- [ ] 60 fps on the oldest iPhone you can borrow.
- [ ] Every screen passes the arm's-length squint test.
- [ ] Credits list every asset.

---

### Step 13: Playtest #2 and the release candidate (about 10 h)

- **Join the Apple Developer Program** (99 USD a year) at the start of this step, not before. TestFlight needs it; the free Personal Team can't reach other people's phones beyond the 3 devices you register yourself, and those builds expire every 7 days.
- **The TestFlight release candidate** (ARCHITECTURE 13.1):
  - create the app in App Store Connect with your bundle id `com.<you>.swesimulator`;
  - set the preset's `app_store_team_id` to the paid team, export, then archive in Xcode (Product > Archive) and upload. Uploads need Xcode 26+ with the iOS 26 SDK;
  - add testers in TestFlight. External testers need Apple's beta review first (unverified for 2026), so upload a few days before the playtest.
- **Playtest #2:** 5-8 people on **their own iPhones**, through TestFlight.
- **Fixing:** triage crashes and bugs, then do a last balance pass.
- **Android and Google Play stay LATER** (ARCHITECTURE 13.2). The **Android decision:** build it after the MVP, once you can test on an Android phone, or keep it LATER.

**Done when**
- [ ] Every item in the section 2 checklist is ticked.
- [ ] 10 clean runs on 3 different iPhones.
- [ ] Tag **`v0.5-mvp`**.

---

## 5. Art pipeline for a non-artist

### Style guide (from the reference image and GDD 2.5)

**The look**
- **The resolution is 270x480 (portrait), and 1 art pixel = 1 game pixel.** The reference is about 450 px wide natively, so match its density: big readable shapes, 2-4 shade ramps, and no noise textures.
- **Compose tall** (GDD 2.5): the reference's bands stack top to bottom, anchored to the screen bottom: sky (y 0-130), skyline (130-220), the character line (220-288), then foreground under the buttons (288-480). Crop the reference's width; never shrink it. Taller phones show more sky.
- **Palette:** one master palette of about 32 colors (Endesga 32 from Lospec is a good start), plus at most 8 UI and brand accents.
  - The mood of each tier comes from which ramps dominate:
    - **Big corp:** cool blue-greys and glass.
    - **Mid-size:** warm beige and fluorescent light.
    - **Startup:** purple and teal neon in a dark warehouse.
- **Light always comes from the upper left.**

**Drawing rules**
- **Outlines** are 1 px, in the darkest shade of the object's own hue (not pure black). Inner lines are one step lighter.
- **Dither only** the sky, clouds and large gradients, as the reference does.
- **Silhouettes:** every character reads from one dominant outfit color. The hoodie colors are Intern teal, Graduate maroon and Self-Taught mustard.
- **Sizes:**
  - full-body characters 40-48 px;
  - busts 96 px tall, at most 80 px wide;
  - interview backgrounds 330x400, bottom-anchored at the desk line;
  - intro panels 270x480 (up to 480x480 for pans, 270x720 for tilts);
  - ending illustrations 254x140;
  - logos and icons 16x16;
  - 9-slice panels with a 4 px border and 3 px padding.

### Tools

| Tool | Price | Notes |
|---|---|---|
| **Aseprite** | paid, about $20 | the standard for pixel animation and palettes |
| **LibreSprite** | free | an older fork of Aseprite |
| **Pixelorama** | free | made with Godot; good enough for everything here |

Keep sources in `art_src/` (Godot ignores that folder) and export PNGs into the feature's `art/` folder, using the ARCHITECTURE 2 names. Import is automatic: the filter is Nearest (global), compression Lossless, mipmaps off.

### Where the art comes from

**Run Spec v1 status (D-21, D-25):** no commissioned art. The hero pieces below are drawn by you or reused, so the "draw or commission" and "Commissioning" items no longer apply; buying a pack ("Props and UI frames (buy)") is Settled (MC-16, D-34): free or CC0 packs only unless you OK one. The career run's office diorama is drawn in this same style, from an asset list per milestone that marks what already exists (GDD 2.11, R-DIO-05; INV-20). Double every estimate, as below.

**Grey-box first**, then:
- **Hero pieces (draw or commission):**
  - the 3 player busts;
  - Dana (3 outfits x 4 expressions);
  - the 6 intro panels;
  - the 3 interview backgrounds.
- **Props and UI frames (buy):** from **one** itch.io pack family, then palette-map them to your palette. In Aseprite: Indexed mode with your palette, then touch up.
- **Licenses:**
  - **OK:** CC0; CC-BY (with credit); paid "commercial use" licenses.
  - **Avoid:** NC (non-commercial) and ND (no derivatives). Be careful with SA (share-alike).
  - Never use ripped sprites.
  - For each asset, add a line to `CREDITS.md` (name, author, URL, license, date) and keep a copy of the license in `docs/licenses/`.
- **AI-generated art: for reference and mood boards only, never shipped** (GDD 2.5).
  - It breaks the pixel grid and the palette, and drifts between poses.
  - Ownership is unclear.
  - Pixel-art players react badly to it.
- **Commissioning:**
  - Brief the artist with the style guide, the palette file, the reference image, exact sizes and frame counts, and the deliverables (`.aseprite` + PNG).
  - Ask for full commercial rights, including modification.
  - Pay in milestones.
  - Get 2-3 quotes; prices vary widely.
- **Satire rule:** no real logos, brands or real people's likenesses, even on a background poster.

**Double every art estimate you make.**

---

## 6. Audio pipeline

- **Sound effects (MUST, about 10, GDD 9.2):**
  - the effects: tap, apply whoosh, reject stamp, invite fanfare, hit, K.O. sting, VS slam, typewriter blip, error buzz (BUSTED's record scratch was cut with D9);
  - make them with **jsfxr** (sfxr.me), **ChipTone** or **Bfxr**; sounds you generate are yours;
  - export as 16-bit WAV into `audio/sfx/` or the feature's `sfx/` folder.
- **Music (SHOULD, 2 loops):**
  - a lo-fi hunt loop, with a minor-key variant at 3 rent days left, and a chiptune interview loop;
  - export as OGG with Loop enabled in the import settings;
  - make them in **BeepBox** (free, in the browser), or use CC0 tracks from OpenGameArt, or CC-BY music with credit;
  - **never** use commercial songs or "no copyright" YouTube rips.
- **In Godot:**
  - one `AudioStreamPlayer` per scene until an Audio autoload is needed (LATER);
  - buses Master, Music and SFX, with music about -8 dB under SFX;
  - mute toggles in Settings.

---

## 7. Playtesting plan

| When | Who | Build | Focus |
|---|---|---|---|
| Every step, from Step 2 | you | your iPhone (re-run from Xcode at least weekly: the build expires after 7 days) | does it work, can you read it, can one thumb reach it |
| **Playtest #1 (Step 7)**, folded into the M2 gate (D-33) | 3-5 people: 2 job seekers or students (the target audience), 1 non-gamer, 1 developer friend | grey-box, on your iPhone | Is the loop understandable, fair and funny? |
| Step 9 | 2 people | vertical slice | Is the art readable? Does the interview feel good? |
| **Playtest #2 (Step 13)** | 5-8 people | release candidate, on **their own iPhones** via TestFlight | readability, devices, crashes, balance |
| **The M2 gate (STEP-15)** | 3 outside players | the career run's grey box | Do they finish job 1, and can they say why they were laid off? (gates 1-2 below; Playtest #1 is folded in here: MC-01, D-33) |
| M5 (STEP-18) | 3+ playtesters | with the diorama | Do they mention the empty desk or the lamp unprompted? |
| **The M6 gates (STEP-19)** | 5+ playtesters | the full career run | all four gates below |

### The career run's playtest gates (Run Spec v1)

The device for these playtests is your call: the iPhone once the Mac is set up (P2), or the desktop build until then.

| Ask the player | Pass | If it fails |
|---|---|---|
| Could you have avoided the layoff? | "No, but I could have been readier" | make the five signs louder (R-RUN-02) |
| What did you do with the Hours slider? | moved it at least twice a job, with a reason | Junior is passive: raise the event density, or let events push the slider |
| What were you trying to get? | names The Studio or one of its conditions | the checklist isn't visible enough (R-WIN-07) |
| Where did you stop playing? | at natural breaks: payday, a review, a job change | add a soft stop point after big events |

**How to run a session**
- Give them the phone and say only: "It's a game about getting a tech job. Think out loud." Note which hand they hold it in.
- Then **stay quiet** and take notes.

**What to watch for**
- a pause longer than 3 seconds;
- a tap on something that isn't interactive;
- whether they read the text or skip it (the biggest risk in a text-heavy game);
- where they laugh (mark the jokes that land);
- whether they can say *why* they lost an interview;
- whether they notice that tailored applications get more replies;
- whether they skip the intro, and at which panel.

**Afterwards, ask 4 questions**
1. What was the funniest moment?
2. What was the most confusing moment?
3. Name one career tip you remember.
4. Would you replay with another background (1-5)?

**Using the results**
- Anything 2 or more testers hit is a **must-fix**.
- Fix confusion first, then balance, then content. Polish comes last.
- The balance sim runs before every playtest, so humans spend their time on feel, not on maths bugs.

---

## 8. Risk register

| # | Risk | Likelihood / impact | Mitigation | Early warning |
|---|---|---|---|---|
| 1 | **Scope creep** (Work loop, more mini-games, more companies) | High / High | The MVP checklist is the contract. New ideas go to `docs/ideas_parking_lot.md`; any addition replaces something | "While I'm here, let's also..." |
| 2 | **Text-heavy UI on small screens** | High / High | monogram 16 only, the 40-column text budgets and line caps in the lint. Hit areas at least 34 px. Test on the smallest iPhone you can borrow | Testers squint or skip text at Playtest #1 |
| 3 | **Art bottleneck and mismatched styles** | High / High | Grey-box first; one palette; the vertical slice; placeholders set the size; one pack family; commission only the hero art | Step 9 goes past 20 h, or two styles sit side by side |
| 4 | **Toolchain or engine drift** (Xcode and iOS updates, templates, Steam updates, two machines) | Medium / High | The iPhone build happens in week 1. Pin Godot 4.7.2 on both machines (the zip on the Mac). Commit before any update and update both machines together | An export error after an update, or the PC and Mac on different versions |
| 5 | **The interview feels random or unfair** | Medium / High | The zone width shows the odds; stats weigh 3x the thumb; the wheel shows its wedge; a tip and the model answer after every loss | Testers say "it's just luck" |
| 6 | **The hunt feels like a tedious clicker** | Medium / High | Energy caps each day; 6 cards a day; a joke on every card; the day-2 invite guarantee | Playtest #1 median time to the first interview is over 5 minutes |
| 7 | **The satire misfires** (punching down, real brands) | Medium / High | GDD 1.3 rules; parody names only (the lint enforces it); Dana is the competent one; diverse testers read every joke; a trademark search before release | Testers wince instead of laugh |
| 8 | **Code you don't understand** | Medium / High | Claude explains the why of every change in its step summary; you read every script Claude writes; tests for the rules; small commits. (The "you do" exercises are suspended: W7) | You can't explain what a script does |
| 9 | **Device-only surprises** (scroll taps, the Dynamic Island, one-thumb reach, haptics, performance) | Medium / Medium | The Step 2 device check; the iPhone build weekly; the unverified list in ARCHITECTURE 18.1 | A bug that "only happens on my phone" |
| 10 | **The Mac isn't at hand** (every iPhone build needs the MacBook) | Medium / High | Develop on the PC, build on the Mac at least weekly; push after every session; set up Godot, godot-ai and Claude on the Mac in Step 2 so work can continue there | No build on the phone for two weeks |
| 11 | **7-day signing:** Personal Team builds stop launching 7 days after install | Certain / Low | Write down the install date; re-run from Xcode before every playtest; paid program from Step 13 | "The app won't open" |
| 12 | **Apple's fee and review for testers** (TestFlight needs the 99 USD a year program; external testers need a beta review) | Certain / Medium | Join the program at the start of Step 13, not before; upload a few days before Playtest #2. Android and Play stay LATER | Playtest #2 is next week and nobody can install the game |
| 13 | **A Junior with one slider still feels passive** (the career run) | High | The M2 gate; about 25 events a year; events that push the slider | M2 players can't say why they moved the slider (gate 2) |
| 14 | **The Studio routing puzzle is opaque** | Medium | The checklist always visible (R-WIN-07); Ducky hints at a route after the first loss (no milestone yet: a spec gap, M6) | Players can't name The Studio or a condition (gate 3) |
| 15 | **Scars plus rising costs become a death spiral** | Medium | Counterplay for every Scar, a 3-stack cap, harness checks (each hard loss at least 10% of losses) | Harness losses pile up in jobs 2-3, or Scars sit at 3 stacks |
| 16 | **New pixel sprites outrun what you can draw** | Medium | Reuse existing tiles first; an asset list per milestone; labeled placeholders on the same grid (no commissioned art: D-21) | M5's asset list grows faster than its art; placeholders reach a playtest |
| 17 | **Burnout auto-resolve feels unfair** | Medium | Three warnings first; the card says the choice was made for you (R-EVT-02) | Players say "the game chose for me" without remembering a warning |
| 18 | **Layoffs and burnout are real, and the satire stings** | Low-medium | The joke is never on the player; Ducky's tip is always genuine (GDD 1.3) | Playtesters wince at the layoff scene instead of laughing |
| 19 | **The review duel's content cost** | Low | A 12-prompt pool in v1 (P-08) | The pool repeats within a run |

Rows 13-19 are the Run Spec's risks: its one "level" fills the likelihood / impact column, and the early warnings were drafted at the merge. Since D-21 there is no commissioned art, so risk 3's "commission only the hero art" no longer applies and risk 16 carries the drawing load; risk 1's "Work loop" is now the plan (section 12), and its creep risk moves into M1-M6.

---

## 9. Weekly cadence

| Week | Steps | You should have |
|---|---|---|
| 1 | 0, 1, 2 | the project on your iPhone, and the device questions answered |
| 2 | 3, then start 4 | tap-through of every screen; interview bars and choices |
| 3 | finish 4, then 5 | a playable interview; the hunt started |
| 4 | finish 5, then 6 and 7 | **`v0.1-greybox`**, and Playtest #1 done |
| 5-6 | 8, 9 | Research; the interview at final quality |
| 7-8 | 10 | the art in place |
| 9 | 11, 12 | the intro, audio and polish |
| 10 | 13 | **`v0.5-mvp`** |

**A normal week at 15-20 h**
- **Monday (30 min), plan:** pick the step, reread its "Done when", and list the design questions for the huddle.
- **Tuesday to Thursday, build:** 2-3 hour sessions, using the loop in section 10. Put a build on the iPhone at least once mid-week (on the Mac: pull, export, Run in Xcode).
- **Friday or the weekend, playtest and retro:**
  - Play it yourself, or with one other person.
  - Spend 30 minutes on a retro: what worked, what to cut.
  - Update `DECISIONS.md` and a short `docs/devlog.md`.
  - Tag a build if a step finished.

---

## 10. How we work together

### The session loop

1. **Start** by pulling, opening Godot with this project, then starting Claude. Say: "We're on Step N. Last time we finished X."
2. **Kickoff (2 min):** Claude restates the step's goal and its "Done when".
3. **Design huddle (5-10 min):** this is where we brainstorm.
   - Claude brings 2-3 options for each open question, each with a recommended default and the trade-off.
   - You decide.
   - Claude adds one line to `DECISIONS.md`.
   - Claude never changes a design decision silently.
4. **Build (Claude, with godot-ai):** in small increments. After each one Claude runs the game, takes a screenshot, reads the logs and runs the tests (ARCHITECTURE 16).
5. **Your turn:** play what Claude built and say how it feels. (The "You do" exercises are suspended since 2026-09-29, `DECISIONS.md` W7: Claude builds those features too. Installs, signing, iPhone checks and sign-offs stay yours.)
6. **Verify:** tests are green, you play it in the editor, and you play it on the iPhone at least weekly.
7. **Commit and push:** Claude commits on the step's branch and pushes (`DECISIONS.md` W1), for example `feat(interview): add doubt/composure bars`. You review and merge on GitHub, in step order.
8. **Wrap-up:** Claude lists the next tasks and any new cut-list items. You note what felt good and what felt bad.

### Ground rules

- **Who owns what:**
  - **You own** the design, the taste, the final say on every joke, and **the accuracy of every career tip** (GDD 8.1).
  - **Claude owns** the boilerplate, the wiring, the tests and keeping the docs true.
- **One step per session**, when possible. `.agent/AGENTS.md`, the docs, `DECISIONS.md` and the plan tracking (`project.yaml`, `.project/state.json`, `docs/task/README.md`) carry memory between sessions. `AGENTS.md` points every new session at them.
- **The 2x rule:** a task past twice its estimate stops, and gets cut or simplified.
- **Commit before risky operations:** before `script_patch` and before any engine update.
- **Report what Claude can't judge:** how it feels, whether it's readable on your phone, and whether it's funny to real people. Tell Claude after each session.

### Switching between the PC and the Mac

- **The repo carries the project context:** `.agent/AGENTS.md`, the docs, `DECISIONS.md`, this roadmap and the plan tracking. On Windows, `.claude/CLAUDE.md` is a one-line text file rather than a link unless git symlinks are enabled, so Claude Code there doesn't load `AGENTS.md` automatically; ask it to read `.agent/AGENTS.md` first. Claude's chat history and auto-memory stay on the machine where they were made, so on the other machine you start a new session in the repo and say "We're on Step N. Last time we finished X." (Copy the one memory note about the godot-ai setup by hand if you want it there.)
- **Push before you switch; pull after.** Unpushed work doesn't exist on the other machine.
- **Open Godot on the project before starting Claude**, so godot-ai connects. On the PC this is required; on the Mac it's a good habit.
- **Same engine on both:** Godot 4.7.2 exactly, and the same godot-ai (the addon lives in the repo).
- The PC is for everyday building with Claude; the Mac is for iPhone builds, and can host Claude sessions too. Remote Control can drive the PC session from another device, but the tools and files stay on the PC, so it can't build for iOS.

### Brainstorm menu (bring these to a huddle whenever you like)

These aren't blocking. They're good conversations for later steps:
- Dana's running gags. Which cameo lines land best?
- The tone of the Plan B ending: warm or bitter?
- Which 5 career tips matter most to you personally? They should be the ones players see first.
- **Phase 2 pitch:** what does the first work day look like, and which MVP state does it use? For example, `employment` and `commute_pips`. Your first ideas (small random events, a few minor career improvements, no cosmetics for now) are parked in `docs/ideas_parking_lot.md`; nothing is built until you decide. (Superseded on 2026-10-07: the Run Spec is the working life, W8; section 12.)
- **A post-MVP mini-game:** the take-home "CRUNCH!" mash, or a Buzzword Catch.

---

## 11. Cut list: what to drop first if you fall behind

**Drop from the top down:**

1. Dana's per-company lines, the video-call frame, per-company prop swaps.
2. Music loops (keep the SFX), and haptics.
3. Career Notebook. Keep the Relaxed Timing toggle; it's one bool.
4. Morning events and the Unicorn posting.
5. Parallax and idle animations; use static images.
6. Drag-to-sign. (The background-check screen already left with lying: D9.)
7. The commute strip; show the text "-4 energy" instead.
8. The top-down room hub; the DoomApply phone hub is enough.
9. Network and the site tabs.
10. Negotiate (already removed, D-27).
11. Research. It's the last SHOULD to drop, because the balance leans on it. If it's cut, try GDD D8 option (c), gentler Doubt HP, and rerun the sim.
12. *(MUST simplifications, only if desperate)* Build the intro from 2-3 illustrated slides plus text; use 1 recolored interview background for all 3 tiers; make the VS intro a static layout plus the slam.
13. Cut content down to the GDD minimums: 15 knowledge, 10 ethics, 20 postings, 15 tips.

**Parked on 2026-10-08 (D-33, MC-01):** items 4, 7, 9 and 11 above (the morning events and the Unicorn, the commute strip, Network and the site tabs, Research) are parked, not scheduled: the career run's board has no place for the hunt's satire (MC-07). Drag-to-sign (item 6) moves to M3.

**The career run's scope** is set (D-36; GDD 10.7): build every MUST and SHOULD; LATER is telemetry beyond a local run log. This list is Phase 1's.

**Never cut:**
- the full Hunt > Interview > Offer loop;
- difficulty effects at **every** stage;
- a tip after every failure;
- the Skip button;
- touch-sized, readable UI;
- saving on pause;
- running on your real iPhone;
- the parody-names-only rule.

---

## 12. The career run: M1-M6 (STEP-14..STEP-19)

Run Spec v1, the career run (GDD 0, 3.3-3.4, 5.14-5.22), is built in six milestones, tracked as STEP-14..STEP-19 (A53): task ids stay ROADMAP steps, nothing is renumbered, and the spec's M-ids stay in the titles. Its order: build the simulation first and headless, prove it with bots, then put the cheapest possible UI on it and playtest before drawing a single desk (GDD 10.7).

**M1 (STEP-14) was built first** (W9; built 2026-10-08, waiting for your review: see Step 14's status). It started ahead of Phase 1's open Steps 7-13, because it is headless PC work that needs neither the iPhone nor the Phase 1 hunt; it is the one exception to W2's gate, which still orders Steps 7-13 among themselves. Where STEP-15..19 sit against Steps 7-13 is settled (MC-01, D-33): Playtest #1 folds into the M2 gate, R-BAL replaces Step 7's Phase 1 balance sim, drag-to-sign moves to M3, the hunt's SHOULDs are parked, and the art and release steps (9-13) come after M4. Each step runs section 10's session loop and W1: its own branch, committed and pushed after each verified increment, merged by you on GitHub in step order.

| Step | Milestone | Branch (A53) | Depends on | Hours (estimates) |
|---|---|---|---|---|
| STEP-14 | M1: the sim core | `step-14-sim-core`, from `run-spec-v1-merge`, or from `main` once you've merged the merge's pull request (A61) | none (W9) | Claude about 20 h of tool calls; you about 3 h |
| STEP-15 | M2: the grey-box UI | `step-15-greybox-ui` | STEP-14 | Claude about 16 h; you about 6 h |
| STEP-16 | M3: run 1 end to end | `step-16-run-one` | STEP-15 | Claude about 20 h; you about 6 h |
| STEP-17 | M4: all systems | `step-17-all-systems` | STEP-16 | Claude about 20 h; you about 6 h |
| STEP-18 | M5: the office diorama | `step-18-diorama` | STEP-17 | Claude about 12 h; you about 40 h (you draw it: D-21) |
| STEP-19 | M6: content and tuning | `step-19-content-tuning` | STEP-18 | Claude about 16 h; you about 12 h |

The hours are estimates written at the merge; each step's kickoff revises them, and the 2x rule applies to Claude's hours too. The "You do" exercises stay suspended (W7): yours are the huddles' answers, the playtests, the art (M5), and the sign-offs on scope, tone and tips. The career run's scope tags are set (D-36; GDD 10.7): every MUST and SHOULD gets built.

### Step 14 (M1): the sim core, headless

- **Goal:** the whole career run's rules run headless, deterministic and fast, and five bots play it: 10,000 seeds in minutes, with the Planner within 5 points of its 5-10% band and winning at least 1% of seeds (A70).
- **Best practice:** simulate before you build screens. Balance is a property of the rules, and a harness finds a broken number in seconds, long before a playtest would.
- **Status:** built, merged and signed off. Built and verified headless on branch `step-14-sim-core` (2026-10-08, W9) and merged as PR #8 (`1e10c96`). All six tasks are done; D-27's cleanup is its own commit. The developer accepted the first tuning (D-29), the agent defaults A62-A76 (D-35) and the tone and tip sign-offs (D-37) on 2026-10-08; D-30 then doubled the starting savings (the harness showed the day-30 cliff of runs 2 and later) and MC-06 renamed the placeholder companies. The evidence (10,000 seeds per bot, the test totals) is in `.project/evidence/STEP-14/2026-10-08-r1/` (as built) and `2026-10-08-r2/` (after D-30 and MC-06). M2 (STEP-15) is built and waits for the playtest (Step 15).

**Tasks**
1. **Data** (Claude): `WorkConfig` and `ArchetypeData`, `@tool` Resources whose script defaults equal GDD 11.7; `data/work/work_config.tres` and the three `data/archetypes/*.tres` (ids per MC-05); the huddle's 10 events in `data/content/work_events.json` (A54; texts from CONTENT 16.3). `test_data_files` and `test_content_lint` grow to cover them (ARCHITECTURE 19.10).
2. **The sim core** (Claude): `SimState`, `Sim.step`, `WorkOdds` and `EventPlan` (ARCHITECTURE 19.2), covering every system so the bots can play whole careers: the clock and money (GDD 5.14-5.15), the work stats, the Codebase and the review (5.16, with a stand-in review until M3), the controls (5.17), archetypes and floor depth (5.18), events with the auto-resolve and layoff selection (5.19), the job hunt with the callback and duels resolved by formula (5.20), Scars and the Handbook's edges (5.21), the Studio hold and every ending (3.3, 3.4). Pure classes, no global RNG, plain-data state (INV-03, INV-04, INV-07).
3. **The tests** (Claude): `test_sim_rules`, `test_sim_review`, `test_sim_events`, `test_sim_endings`, `test_sim_replay` and `test_sim_smoke` (ARCHITECTURE 19.10), with the GDD's worked numbers.
4. **The harness and the five bots** (Claude): `tests/harness/run_harness.gd` and `tests/harness/bots/` (ARCHITECTURE 19.6), run headless on a copy of the repo (A56; the commands are in `.agent/AGENTS.md`). Every run's report goes to `.project/evidence/STEP-14/<run>/`.
5. **First tuning** (Claude, then you): tune `WorkConfig` and `ArchetypeData` only, until the Planner is within 5 points of its band, and write down what changed and why.
6. **D-27's cleanup** (Claude), as its own commit, since D-27 gave it to the next code change: remove `Odds.negotiate_p`, `Odds.negotiated_salary`, BalanceConfig's `nego_*` fields, the offer's `negotiated` flag, `test_offer`'s negotiation test and the unused strings (CONTENT 16.7), then sync GDD 11.6, ARCHITECTURE 6.2, 7.1 and 17, and `test_data_files`.
   **Done 2026-10-08**, in its own commit (`refactor(offer): remove negotiation code (D-27)`): the code, the six strings and the docs are synced, section 17's five changed blocks included; 216 tests pass headless, one fewer than before because the negotiation test went.

**Claude and godot-ai do:** all of the above. M1 needs no editor: the headless runner and `test_run` (or its headless twin) are enough.

**Design huddle** (W4: Claude takes the recommended defaults if you're away)
- Which 10 events M1 builds. Proposed: E01, E02, E04, E07, E08, E12, E18, E20, E21, E24, so every bot's strategy meets the event it is built around (the money pulse, the review, rent, the layoff, the remote threat, incidents, the recruiter, the emergency, lifestyle creep, overtime).
- The M1 spec gaps in `docs/merge-report.md`: the starting values, day 0, a promotion's salary, leases, severance, ticket deadlines and sizes, the random events' odds, exhausted choices, owning a service, E04 in the Shared room, and how the harness resolves duels.
- MC-23 (E12's cooldown against O5), MC-05 (the archetype ids), MC-04 (starting savings) and MC-22 (INV-09's wording).
- M1's exit also passes at 0% wins: add "and wins at least 1%"?

**Held 2026-10-08.** The developer answered "take the proposed defaults", so Claude logged them as agent defaults A62-A72 in `docs/DECISIONS.md`: the 10 events (A62), the M1 gaps (A63-A67), MC-04 and MC-05 (A68), MC-22 and MC-23 (A69), the 1% exit (A70), the committed headless runner (A71), and the M3 and M4 rules the bots need early (A72). All were "please review" and are accepted (D-35).

**Done when** (`project.yaml` gives each one an id, and lists M1's rule checks)
- [ ] 10,000 seeds per bot run headless in minutes (the time is recorded in the evidence).
- [ ] The Planner wins within 5 points of its 5-10% band and at least 1% of seeds (100 of 10,000: A70), and the other bots' numbers are recorded.
- [ ] The Coaster never wins, and its median loss comes before day 1,800 (O2).
- [ ] The objectives' sim tests pass: Manager Opinion has no effect on layoff selection (O1); incidents at Codebase 80 are at least 3x those at 20 (O5, once MC-23 settles E12's cooldown); the win fires only with all five conditions held 90 days (O6).
- [ ] The same seed and inputs replay the same run (`test_sim_replay`), and every suite passes, including each M1 rule check `project.yaml` lists.

**Pitfalls**
- A rule hiding in the harness or a bot instead of the sim: a bot only sends inputs.
- Dictionary order or the global RNG deciding a roll; the replay test catches both.
- Tuning by editing scripts instead of the `.tres` files (INV-15).
- Chasing the exact band at M1: "within 5 points" is M1's bar, and 5-10% is M4's.

### Step 15 (M2): the grey-box UI

- **Goal:** the career run on screen with the cheapest UI: the phone shell, the calendar strip, the four numbers, the Hours slider, event cards, the speed control, save and resume, and no diorama. Three outside players finish job 1 and can say why they were laid off.
- **Best practice:** answer the riskiest question first (is a Junior with one slider fun?), with boxes and text, before any art or content spend.
- **Status:** built and verified on the desktop on branch `step-15-greybox-ui` (2026-10-08): tasks 1-3 are done and task 4, the playtest, is yours (`docs/PLAYTEST_M2.md`). The evidence (387 tests in 30 suites, the desktop kill tests, 15 screenshots) is in `.project/evidence/STEP-15/2026-10-08-r1/`. Built on `step-14-signoff`: merge that branch first.

**Tasks**
1. **Phases and the save** (Claude): append `WORK` and `LAYOFF` (INV-10), with the transitions and save rules of ARCHITECTURE 19.4 (RC-35) and the `GameState` verbs the screen calls.
2. **`features/work/work.tscn`** (Claude), on the screen skeleton (ARCHITECTURE 10.1, 19.7; GDD 4.6): the top band, the Hours notches and the speed control in the thumb band, the dock, the event card (choices behind the 250 ms lock), the auto-resolve's warnings and its "Burnout picked" line, and an on-screen Back to Pause. Job 1 here is the sim's own: M1's events, with the resizing chain and the layoff as plain cards; M3 replaces them with run 1's authored content.
3. **Kill tests** (Claude on the desktop; you on the iPhone once it's set up): the career run's moments in `docs/KILL_TESTS.md` (O8).
4. **The M2 playtest** (you): three outside players, silent, as section 7 says; ask gates 1 and 2.

**Design huddle:** the career run's first-run coach marks and how often a recurring event's tip shows (both spec gaps); whether a drag along the Hours notches should also work (A58); MC-12 (Tired) and MC-15 (telemetry) are settled (D-34): Tired is retired, and a local run log plus a debug report is all the telemetry.

**Held 2026-10-08.** You asked for the next steps with the recommendations, so Claude took the defaults and logged them as A78-A87 in `docs/DECISIONS.md`: the entry points and Phase 1's hunt behind a debug button (A78), the save (A79), the clock (A80), cards and the feed (A81), the stand-ins until M3 and M4 (A82), what happens after the layoff and the endings (A83), the coach marks and an event's tip (A84), the layout (A85), the debug helpers (A86) and the new strings (A87: my drafts for your tone check). All are "please review". A drag along the notches stays out until the playtest.

**Built 2026-10-08.** Task 1: `WORK` and `LAYOFF` are appended, `SaveIO` tells a career save from Phase 1's, `GameState`'s `career_*` verbs drive a `WorkSession`, and `Sim.apply_inputs` answers a card without burning a day. Task 2: `features/work/` (the phone shell, the event card, the clock), `features/layoff/` (four taps), the career endings on the Plan B card, and the Title's debug-only "Old hunt". Task 3: the desktop kill tests (moments 6, 7, 8 and 11) pass, and a whole run played through `GameState`'s verbs went WORK, LAYOFF, WORK, GAME_OVER.

**Done when**
- [ ] Three outside players finish job 1 and can say why they were laid off.
- [ ] Killing the game mid-run, then Continue, restores the state of the last save (O8).
- [ ] Every control used more than once a day sits in the thumb band, and the Junior screen has exactly one continuous control (O3).
- [ ] The rest of M2's checks in `project.yaml` pass: the HUD, the event card, the auto-resolve's card, no time while closed.

**Pitfalls**
- Drawing the diorama now: M2 has none, on purpose.
- Letting the clock run under an open card or app (GDD 4.5).
- Explaining the game to the playtesters.

### Step 16 (M3): run 1 end to end

- **Goal:** run 1 playable from day 0 to the board: Hierarchai and its coworkers, the resizing chain, the review duel, the layoff scene, the DoomApply board and the adapter.
- **Best practice:** finish one vertical path before widening: run 1 is the tutorial, the story and the satire's thesis in one.

**Tasks**
1. **Run 1's content** (Claude): Hierarchai's four coworkers (`coworkers.json`), the five signs (R-RUN-02), run 1's beats (GDD 3.3: the review on day 180, Dana's invite around day 235, the layoff on day 240) and the intro's handover (MC-11).
2. **The review duel** (Claude): 3 prompts on the Dana duel UI with a manager portrait placeholder (P-08).
3. **The adapter** (Claude): DuelRequest and DuelResult, OfferRequest and OfferResult (ARCHITECTURE 19.5), with `test_adapter`.
4. **The layoff scene** (Claude): `features/layoff/` (GDD 5.19, RC-34).
5. **The DoomApply board** (Claude): postings as nodes, the callback band, apply and study, replies and interviews on the calendar strip (GDD 5.20).

**Design huddle:** the review's prompts, the clause list, the callback band's thresholds, E07's prep effects and run 1's work mode (spec gaps); MC-06, MC-08, MC-11, MC-19 and MC-20 are settled (D-34: Hierarchai for Pivotly, the HIRED! stamp as a beat, a new last intro caption, Decline still blacklists, reword the copy that names retired mechanics); the coworkers' and the layoff scene's tone is signed off for the drafts (D-37) and checked again once built.

**Held 2026-10-08.** You answered the four forks with the recommendations: the review is three choice prompts (D-39), Hierarchai's coworkers are a team row in the Body (D-40), the board is a column of nodes (D-41) and day 0 opens on one clip card (D-42). The rest took the recommended defaults and are logged as A88-A96 in `docs/DECISIONS.md`, all "please review": the adapter's shape (A88, A89), the callback band (A90), the clauses (A91), the hunt's flow (A92), the layoff scene (A93), the review's numbers (A94), drag-to-sign (A95) and the new wording (A96). Reading the Phase 1 code at the kickoff found three traps the plan did not name: the career save must cover INTERVIEW and OFFER (`save()` would write a hunt save over it), `WORK` has no transition to them yet, and a career `RunState` is bare (no stats, no rent days) until the adapter fills it.

**Done when**
- [ ] Run 1 plays from day 0 to the board, with the five signs before day 240.
- [ ] A won interview from the board reaches the contract modal through the adapter, and Accept starts job 2.
- [ ] You've signed off the tone of Hierarchai's coworkers and the layoff scene.
- [ ] The rest of M3's checks in `project.yaml` pass: the review duel, the board, the adapter's inputs, Accept or Decline.

### Step 17 (M4): all systems

- **Goal:** a full run playable with every system on screen: 3 archetypes, floor depth, the Mid and Senior controls, home tiers, Scars, the Studio hold and every ending. The Planner wins 5-10%.

**Tasks**
1. The archetypes on the board and at work (GDD 5.18, 7.1), floor depth (6.1) and the level carry-over (5.17).
2. The Mid and Senior controls (the ticket pick, push back, the quality bar, the calendar tax) on screen, at most 3 main actions per screen (pillar 2).
3. The Home app and lifestyle creep (5.15), ClikClok's checklist and the Filming bar (3.4), Scars (5.21) and every ending card (3.3).
4. Tune to R-BAL: the Planner at 5-10%, and the other bots' targets (GDD 5.22).

**Design huddle:** the M4 spec gaps (layoff numbers, the forced leave, removing Scars, references, MegaCorp's two duels, the job-5 board, the generated manager); MC-03, MC-09, MC-10, MC-13 and MC-14 are settled (D-32, D-34); M4 applies them.

**Done when**
- [ ] A full run is playable to every ending.
- [ ] The Planner wins 5-10% over 10,000 seeds.
- [ ] The other R-BAL holds pass: the median run, the ending mix, the Planner's promotion inside job 1, and the Grinder's, the Lifestyle bot's and the Random bot's targets (GDD 5.22).
- [ ] The rest of M4's checks in `project.yaml` pass: the Home app, the Mid and Senior controls, the archetypes, all 26 events, ClikClok's checklist.

### Step 18 (M5): the pixel-art office diorama

- **Goal:** the office diorama in the shipped pixel-art style, pause-and-zoom, and the win's ending video. Playtesters mention the empty desk or the lamp unprompted.
- **Best practice:** an asset list per milestone (R-DIO-05): reuse first, labeled placeholders on the same grid, and draw only what's missing.

**Tasks**
1. **The asset list** (Claude, then you): GDD 2.11's list checked against what exists, with the manager portrait and the walk cycle added (a spec gap), each with its size and frames.
2. **The diorama** (Claude): ARCHITECTURE 19.8: the tile column, the lanes, the state swaps, pause-and-zoom in whole steps.
3. **The art** (you): drawn to section 5's rules; no commissioned art (D-21), and CC0 packs only if they match the palette (paid packs: MC-16).
4. **The ending video** (Claude), assembled from the run log (GDD 3.4).

**Done when**
- [ ] Playtesters mention the empty desk or the lamp unprompted.
- [ ] Every new sprite matches the shipped pixel grid and palette, and nothing was commissioned (O9, INV-20).
- [ ] The rest of M5's checks in `project.yaml` pass: the state swaps, the lanes, the zoom, the asset list.

### Step 19 (M6): the Handbook, events to about 40, the Ducky pass, tuning

- **Goal:** the Handbook, events to about 40, a Ducky writing pass and tuning, until the playtest gates pass (section 7).

**Tasks**
1. The Handbook app (GDD 5.21, 8.5; MC-18), the unlocks and the ending gallery.
2. About 14 new events (none is written yet), each with a tip or an explicit none (O7).
3. The Ducky writing pass: the jokes and causes, the tips' `more` lines, the plain-language rule (C3, MC-17), and a rent tip for E04 if you want one (D-28).
4. Tuning with the harness, then the playtest gates.

**Done when**
- [ ] The playtest gates pass (section 7).
- [ ] You've signed off every tip (GDD 8.1).
- [ ] The content lint passes: every event has a tip or an explicit none.
- [ ] The rest of M6's checks in `project.yaml` pass: the Handbook, the run log's report.

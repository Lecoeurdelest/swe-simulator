# SWE Simulator: how to access and drive Godot (handoff, 2026-10-07)

A companion to `swe-simulator-handoff.md`. It covers the engine, the project layout, the tests, and the two ways to work with Godot: through the **godot-ai MCP** attached to the open editor, and **headless from the command line**. Everything below was checked against the repo at `main` = `dde5b99` on the Windows PC; the headless commands were run on 2026-10-07.

---

## 1. Quick facts

| Item | Value |
|---|---|
| Engine | **Godot 4.7.2-stable**. Windows PC: the Steam build, `godot --version` = `4.7.2.stable.steam.ed1daf0bf`. MacBook (not set up yet): the official godotengine.org zip of the same 4.7.2. Both machines must run the exact same version. |
| `project.godot` | `config_version=5`, `config/features=PackedStringArray("4.7")`, `config/name="SWE Simulator"`, `config/version="0.1.0"` |
| Language | **GDScript only**, typed (warning `gdscript/warnings/untyped_declaration=1`). **No C#**: no `.cs`, `.csproj` or `.sln` files, and no .NET build needed. |
| Renderer | `gl_compatibility` on desktop and mobile |
| Main scene | `res://features/title/title.tscn` |
| Autoloads (in order) | `_mcp_game_helper` (`res://addons/godot_ai/runtime/game_helper.gd`, the godot-ai runtime bridge), `Content`, `GameState`, `Device`, `SceneRouter` (all in `res://autoload/`) |
| Editor plugin | `res://addons/godot_ai/plugin.cfg`, "Godot AI" **v4.2.3** (committed in the repo) |
| Display | Viewport **270x480 portrait** (`window/handheld/orientation=1`), window override 540x960, stretch `viewport` + aspect `expand` + scale `integer` (plus a runtime `Device` scale guard), nearest filtering, 2D transforms snapped to pixels, max 60 fps, clear color `Color(0.07, 0.07, 0.1)` |
| Input | `pointing/emulate_touch_from_mouse=true`, `gui/common/default_scroll_deadzone=6`, `quit_on_go_back=false` |
| Theme | `gui/theme/custom="res://ui/theme/main_theme.tres"` (fonts: monogram 16 px for body text, Press Start 2P 8 px for headers, in `ui/fonts/`) |
| Saves | `user://save_v1.json` (the run) and `user://settings.cfg` (meta and options). `user://` is keyed by `config/name`, so **any copy of the project with the same name shares the same save folder** (on Windows: `%APPDATA%\Godot\app_userdata\SWE Simulator\`). |
| Repo | `D:\Code\swe-simulator`, GitHub `Lecoeurdelest/swe-simulator`. `.godot/` (the import cache) is git-ignored. |

## 2. Where Godot lives

- **Windows PC:** `C:\Program Files (x86)\Steam\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe`. This is the editor binary; it also runs headless. There is no separate `_console.exe` in the Steam build, but output still prints when it's run from Git Bash. Steam should be set to update Godot only on launch, so the engine can't drift. **Commit before any engine update and update both machines together.**
- **MacBook (planned, ROADMAP Step 2):** the godotengine.org zip of 4.7.2 (it never updates itself), plus the 4.7.2 iOS export templates and Xcode for the iPhone build.

## 3. Way 1: the godot-ai MCP (drives the open editor)

**How it's wired on the PC.** The MCP server `godot-ai` is registered at **local scope** in `~/.claude.json` for `D:/Code/swe-simulator`. It is a stdio bridge: `pythonw.exe` runs `uvx ... --from godot-ai==4.2.3 godot-ai attach --port 8000 --ws-port 9500`, the same command the addon's **Configure** button writes. The editor plugin runs the backend on port 8000 (HTTP) and 9500 (WebSocket).

**Start order (required on Windows):**
1. Pull the repo.
2. Open the project in the Godot editor.
3. Then start Claude.

Claude desktop is an MSIX (Store) app, so files it writes to `%LOCALAPPDATA%` are redirected to a private folder. The bridge authenticates with `%LOCALAPPDATA%\godot-ai\capabilities\http-8000.json`, and only an editor-started backend writes that file where the bridge can read it. If the bridge reports **PORT_OCCUPIED**, a stale backend is holding port 8000: close it, reopen Godot, restart Claude.

**Session loop** (ARCHITECTURE 16):
1. `editor_state`: the editor must be **ready and not playing**. Edits are rejected while the game plays, so run `project_manage op=stop` first.
2. Code: edit files on disk, or use `script_create` / `script_patch` (the response includes parse diagnostics). **Commit before `script_patch`** (it can't be undone). After a new or removed `class_name` or file, run `filesystem_manage op=scan`.
3. Scenes: `scene_manage`, `ui_manage build_layout`, `node_*`, `script_attach`, then `scene_save`. Changes stay in editor memory until saved.
4. Tests: `test_run` (all suites) or `test_run suite="odds"`; `test_manage results_get` for details; failures without a message are in `load_errors` or `logs_read source="editor"`.
5. Run: `project_run` with `mode="main"`, `"current"` or `"custom"` plus `scene="res://features/...tscn"`. **Always pass `autosave=false`** (see section 8).
6. Inspect:
   - `editor_screenshot source="game"`;
   - `logs_read source="game"` (and `source="editor"` for parse errors);
   - `game_manage get_ui_elements` / `get_scene_tree` / `get_node_info`;
   - `game_manage input_mouse` (WINDOW pixels = 2x game pixels, and a `motion` event before each `button` press);
   - `game_manage suspend` / `resume` to freeze a short animation;
   - `editor_manage game_eval` to run code in the game, e.g. `return GameState.run.to_dict()`.
7. `project_manage op=stop` when done.

**Running one feature scene alone.** Every feature scene starts with a debug quick start, so `project_run mode="custom"` works on its own:

```gdscript
func _ready() -> void:
	if OS.is_debug_build() and GameState.run.background_id == "":
		GameState.debug_quick_start("graduate", GameFlow.Phase.JOB_HUNT)  # the scene's own phase
```

`GameState.debug_quick_start(bg_id, phase, run_seed = 20260926)` builds a run in place without changing scenes. `GameState.debug_fake_invite(tier_id)` adds an invite. Quick-started runs are **not** first runs. To see first-run tutorials, press the debug-only **Reset first run** button on the Title (next to "Device check"), then New game.

**Other useful tools:**
- `project_manage settings_get` / `settings_set` (one key per call; it refuses `autoload/*`, `editor_plugins/*` and the main scene: use `autoload_manage` and `project_manage set_main_scene`).
- `api_manage get_class` for engine API questions.
- `theme_manage`, `resource_manage create` (only `@tool` classes), `animation_create` / `animation_manage`.
- `tileset_manage` / `tilemap_manage` (for a future top-down view).

**Setting it up on the MacBook (once):**
- Install `uv` (`brew install uv`) and the `claude` CLI.
- Open the project in Godot. In the Godot AI dock pick **Claude Code**, set the scope to **local**, and press **Configure**. The first server start downloads 60+ packages, so it's slow once.
- Check the connection with `editor_state`.
- **Never use the "project" scope:** it writes a `.mcp.json` with machine-specific paths that would break the other OS if committed.

## 4. Way 2: headless from the command line (no editor needed)

Headless runs use the editor binary with `--headless`. **Use a copy of the project, not the repo folder**, so the copy's `.godot` cache never fights the open editor and the run can't touch repo files. (Saves still go to the shared `user://` folder, section 1.)

Each command below was run on 2026-10-07, and the result follows the arrow:

```bash
GODOT="C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
P=<a copy of the repo without .git and .godot>

"$GODOT" --version                                          # -> 4.7.2.stable.steam.ed1daf0bf
"$GODOT" --headless --path "$P" --import                    # build the import cache and class_name table (first time ~10 s)
"$GODOT" --headless --path "$P" --script res://__run_all.gd # run every test suite -> RESULT passed=217 failed=0 total=217 suites=20
"$GODOT" --headless --path "$P" --script res://__run_all.gd -- suite=odds   # one suite -> passed=8
"$GODOT" --headless --path "$P" --script res://__check_all.gd               # load every .gd/.tscn -> CHECK files=85 failed=0
"$GODOT" --headless --path "$P" --quit-after 180            # boot the main scene for 180 frames: no errors
"$GODOT" --headless --path "$P" res://features/interview/interview.tscn --quit-after 300   # boot one scene
```

The `__run_all.gd` and `__check_all.gd` scripts, and a wrapper that makes the copy, are in the Appendix. Things to know:

- `--script` runs a `SceneTree` script as the main loop. **Autoloads exist only from the first frame on**, not in `_init()`. A script that loads game scripts using `GameState`, `Content` or `Device` must do its work in `_process()` on the first frame (see `__check_all.gd`), or those names fail to compile.
- The test runner reuses the addon's own `McpTestRunner`, so pass/fail rules are the same as godot-ai `test_run`.
- Headless runs in a fresh process each time, so they never suffer from the editor's stale preloads. They're safe to run in parallel if each run uses its own copy folder (`PROJ`).
- Headless is good for logic, loading and boot checks, not for visuals or input. Use the editor and the MCP for screenshots and taps.

## 5. Project layout

```
project.godot          engine settings (section 1)
addons/godot_ai/       the godot-ai editor plugin + runtime helper + McpTestSuite/McpTestRunner (committed; don't edit)
autoload/              4 singletons
  content.gd           Content: loads data/content/*.json, Content.text(file, id, args) / field(...), placeholders via UiText.fill
  game_state.gd        GameState: the ONLY API scenes call (verbs: start_new_game, choose_background, quick_apply,
                       tailor_apply, skip_card, study, sleep, start_day, start_interview, finish_interview,
                       answer_offer, close_coach_mark, reset_first_run, debug_quick_start, ...); owns `run: RunState`
  device.gd            Device: scale guard, safe area, haptics, layout_changed signal
  scene_router.gd      SceneRouter: phase -> scene swap with a fade curtain (SCENES map below)
core/                  pure rule classes (@tool, RefCounted, no nodes, fully tested)
  game_flow.gd         GameFlow: enum Phase (APPEND-ONLY), TRANSITIONS, SAVED_PHASES, deletes_save, can_resume
  run_state.gd         RunState: all run data + rules (board, apply, sleep/reveal, interview checkpoint, make_offer,
                       fine_print_pool, hire, dream score); to_dict/from_dict (plain data, unknown keys ignored)
  save_io.gd           SaveIO: user://save_v1.json (temp file + rename)
  odds.gd              Odds: every formula (invite odds, bands, knockouts, answer meter, committee, salary, dream)
  interview_plan.gd    InterviewPlan: question picks, warm-up, VS plate (Dana's stat/move by meeting count)
  hunt_tips.gd         HuntTips: which Ducky tip / coach mark shows when
data/
  types/               tier_data.gd, background_data.gd, balance_config.gd (Resource classes, @tool)
  tiers/               startup.tres, mid.tres, big.tres         (tuning numbers)
  backgrounds/         intern.tres, graduate.tres, self_taught.tres
  balance/             balance_config.tres
  content/             16 JSON files: naming, backgrounds, tiers, companies, postings, cv_lines, questions_choice,
                       questions_knowledge, barks, emails, tips, endings, events, cutscene, names, news
features/              one folder per screen: scene (.tscn) + its script(s)
  title/               title.tscn/.gd (main scene; debug row: Device check, Reset first run)
  intro/               intro.tscn/.gd, cutscene_plan.gd (pure), hold_skip_pill.gd
  background_select/   background_select.tscn/.gd, background_card.tscn/.gd, dice_button.gd
  job_hunt/            job_hunt.tscn/.gd (the DoomApply hub), job_card, invite_card, night_screen, coach_mark (.tscn/.gd),
                       mail_screen.gd, dock_button.gd
  interview/           interview.tscn/.gd, versus_intro.tscn/.gd, answer_meter.gd, committee_wheel.gd
  offer/               offer.tscn/.gd (the contract)
  phase2_stub/         phase2_stub.tscn/.gd (the Hired card: stamp + Dream vs Reality; Phase 2 starts here)
  game_over/           game_over.tscn/.gd (the Plan B ending)
  dev/                 device_check.tscn/.gd (debug-only overlay, loaded by path, never in release)
ui/
  components/          confirm_dialog, pause_menu, ducky_note, hp_bar, stat_bar, ending_art (.tscn/.gd);
                       pip_bar.gd, safe_area_margin.gd, ui_text.gd (UiText: text helpers, fill, money, word_wrap)
  theme/main_theme.tres  type variations: PrimaryButton, DangerButton, PaperPanel, HeaderLabel, SelectorButton,
                       DockButton, Chip, GoldPill
  fonts/               monogram (ttf), PressStart2P-Regular.ttf, OFL.txt (pico-8 subfolder has a .gdignore)
tests/                 20 test_*.gd suites (section 6)
art/ audio/            placeholders (.gitkeep) until the art and audio steps
art_src/ builds/       ignored by Godot (.gdignore); builds/* is git-ignored
docs/ .agent/ .project/ project.yaml   design docs, agent rules, plan tracking (not used by Godot)
```

**Scene map** (`autoload/scene_router.gd`, `SCENES`):

| Phase | Scene |
|---|---|
| TITLE | `res://features/title/title.tscn` |
| INTRO | `res://features/intro/intro.tscn` |
| BACKGROUND_SELECT | `res://features/background_select/background_select.tscn` |
| JOB_HUNT | `res://features/job_hunt/job_hunt.tscn` |
| INTERVIEW | `res://features/interview/interview.tscn` |
| OFFER | `res://features/offer/offer.tscn` |
| PHASE2_STUB | `res://features/phase2_stub/phase2_stub.tscn` |
| GAME_OVER | `res://features/game_over/game_over.tscn` |

**Code rules that affect how you edit** (`.agent/rules/invariants.md` has all 19):
- Scenes call only `GameState` verbs, and only `GameState.change_phase()` changes the phase. No `change_scene_*` in features.
- `GameFlow.Phase` is append-only: new phases go at the end.
- There is no global RNG; randomness comes from the seeded run, interview and offer RNGs.
- Player text lives in JSON (no strings in scripts), and tuning numbers live in `.tres`.
- Positions are whole pixels, and the portrait layout keeps the thumb band at the bottom (INV-19).
- Script files carry `.uid` sidecars (Godot 4.4+). Commit them with the script. Move or rename files only through Godot's FileSystem dock, or move the `.uid`/`.import` files along.
- `docs/ARCHITECTURE.md` section 17 holds **byte-exact copies** of 23 source files. After editing one of them, re-sync section 17.

## 6. Tests

- **Framework:** godot-ai's `McpTestSuite` (`addons/godot_ai/testing/test_suite.gd`), run by `McpTestRunner`.
- **Rules** (ARCHITECTURE 12.1):
  - Discovery is `res://tests/test_*.gd`, **non-recursive**.
  - Every test file is `@tool` and `extends McpTestSuite`, with a `suite_name()`. `test_*` methods run in alphabetical order.
  - A test with 0 assertions fails, and a script error aborts the test.
  - Helpers: `assert_true/false/eq/ne/gt/has_key/contains/is_error`, `skip`, `skip_suite`, `fail_setup`, `track`, `expect_script_error_containing`, plus `setup/teardown/suite_setup/suite_teardown`.
  - There is no `assert_lt` and no float tolerance: use `assert_true(absf(a - b) <= eps, msg)`.
- **Tests run in the editor process, with no autoloads** (INV-12). Test the pure `core/` classes and Resources. Build fixtures in code, read `.tres` with `load()` and JSON with `FileAccess`, and **never write to `user://`** (in the editor that's the real save folder).
- **Limits:** the whole `test_run` has a 300 s budget, and a single test blocking for 20 s or more can drop the MCP session.
- **Current suites (20 suites, 217 tests, all green on 2026-10-07):**
  - Flow and save: `flow`, `save`.
  - Formulas and data: `odds`, `data_files` (the `.tres` files must equal GDD section 11), `content_lint` (text budgets, ASCII, banned brands, placeholders).
  - Interview: `interview`, `interview_plan`, `ui_text`.
  - Job hunt: `hunt_board`, `hunt_apply`, `hunt_reveal`, `hunt_sleep`, `hunt_sim`, `hunt_edges`, `hunt_defaults`, `hunt_tips`.
  - Endings and UI: `offer`, `endings`, `bars`, `intro`.
  - `test_balance.gd` (the GDD 5.12 balance simulation) is planned for ROADMAP Step 7.
- **Where results go:** test output used as proof is saved under `.project/evidence/STEP-NN/<run>/` (see the plan-driven workflow in `.agent/AGENTS.md`).
- **When a tuned number changes**, update the `.tres`, GDD section 11 and `tests/test_data_files.gd` in the same commit.

## 7. Plan and doc checks around Godot work

```bash
python .project/render.py                                   # state.json -> docs/task/README.md
python .agent/skills/plan-driven-development/scripts/check_project.py validate project.yaml
python .agent/skills/plan-driven-development/scripts/check_project.py audit-preservation project.yaml --root .
python .agent/skills/plan-driven-development/scripts/check_project.py audit-task-status docs/task/README.md
```

On Windows use `python`, not `python3`, with `PYTHONIOENCODING=utf-8`. The only expected validator warning is "STEP-00: decision D4 is not accepted" (D4 was superseded by D9). Git works from Git Bash (it isn't on the PowerShell PATH), and there's no `gh` CLI on the PC.

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| A run overwrote a file you just edited, or text landed in the wrong file | **`project_run` defaults to `autosave=true`**, which saves open editor buffers, including **stale script tabs**, over disk edits. Always pass `autosave=false`, close script tabs you edited outside the editor, and check `git diff` after runs. This once wiped `title.gd` and wrote its text into `docs/CONTENT.md` (repaired before any commit). |
| `game_status="break"` right after `project_run` | A parse or load error at boot. Run `project_manage op=stop`, read `logs_read source="editor"` (boot errors only show there), fix it, relaunch. |
| Editor shows "Identifier not found: GameState/Content/Device" | Expected after autoloads are added through godot-ai, and it clears on an editor restart. The running game, `test_run` and headless runs are fine. |
| `test_run` passes old behaviour after a big edit | Preloaded scripts can stay stale in the editor. Confirm with the headless runner (a fresh process), or restart the editor. |
| `filesystem_manage op=remove` refused ("Cannot establish ownership through a linked entry") | Caused by the repo's git symlinks. Delete with `git rm` / `rm`, then `filesystem_manage op=scan`. |
| `settings_set` saved a Color or font with the wrong type | It does no type coercion. Write a throwaway `@tool extends McpTestSuite` that calls `ProjectSettings.set_setting(key, Color(...))` and `ProjectSettings.save()`, run it with `test_run`, then delete it. `theme_manage` can't set the default font or a variation's base type either: use the same trick. |
| Resizing the game window from `game_eval` does nothing | The game embedded in the editor's Game tab ignores `root.size` / `window_set_size`. Drag the window, or undock it. |
| Taps from `game_manage input_mouse` miss | Coordinates are window pixels (2x the 270x480 game), and each `button` press needs a `motion` event first. Real drags need `game_eval` (motion events carry no button mask). |
| Screenshots stop changing, or a scan hangs until timeout | Rare. Stop the game and relaunch; the editor recovers. A minimized game window also gives stale frames. |
| Bridge error PORT_OCCUPIED at Claude start | A stale godot-ai backend holds port 8000. Close it, open Godot first, then start Claude (section 3). |
| `.claude/CLAUDE.md` is a one-line text file | Windows symlinks are off. You need Developer Mode on and `git config --local core.symlinks true`, then re-checkout the 4 links. The PC has been fixed since 2026-09-27. |

---

## Appendix: headless runner files

Put these 3 files in one folder (the scratchpad works), then run `bash run_tests.sh` (all suites), `bash run_tests.sh odds` (one suite) or `bash run_tests.sh parse` (load check). `SRC` defaults to the repo, and `PROJ` is the copy folder; give each parallel run its own `PROJ`.

`run_tests.sh`:
```bash
#!/usr/bin/env bash
set -e
HL="$(cd "$(dirname "$0")" && pwd)"
SRC="${SRC:-D:/Code/swe-simulator}"
GODOT="C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
P="${PROJ:-$HL/proj}"
mkdir -p "$P"
for d in addons autoload core data features tests ui art audio; do
  rm -rf "$P/$d"; [ -d "$SRC/$d" ] && cp -r "$SRC/$d" "$P/$d"
done
cp "$SRC/project.godot" "$P/project.godot"
cp "$HL/run_all.gd" "$P/__run_all.gd"
cp "$HL/check_all.gd" "$P/__check_all.gd"
"$GODOT" --headless --path "$P" --import > "$P.import.log" 2>&1 || true
if [ "$1" = "parse" ]; then
  "$GODOT" --headless --path "$P" --script res://__check_all.gd 2>&1 | grep -v "^Godot Engine\|^$" | tail -80
  exit 0
fi
ARG=""; [ -n "$1" ] && ARG="suite=$1"
"$GODOT" --headless --path "$P" --script res://__run_all.gd -- $ARG 2>&1 | grep -v "^Godot Engine\|^$" | tail -80
```

`run_all.gd`:
```gdscript
extends SceneTree
## Headless runner: every res://tests/test_*.gd through McpTestRunner (same pass rule as godot-ai test_run).
func _init() -> void:
	var filter := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("suite="):
			filter = a.substr(6)
	var suites: Array = []
	var files: Array[String] = []
	for f: String in DirAccess.open("res://tests").get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f: String in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			print("LOAD_FAIL ", f)
			continue
		suites.append(script.new())
	var res: Dictionary = McpTestRunner.new().run_suites(suites, filter, "", {}, false)
	print("RESULT passed=%d failed=%d total=%d suites=%d ms=%d" % [res.passed, res.failed, res.total, res.suite_count, res.duration_ms])
	for fail: Dictionary in res.get("failures", []):
		print("FAIL ", fail.get("suite", ""), ".", fail.get("test", ""), ": ", str(fail.get("message", "")).replace("\n", " | "))
	quit()
```

`check_all.gd`:
```gdscript
extends SceneTree
## Loads every .gd and .tscn under the game folders; parse errors print as SCRIPT ERROR.
const ROOTS := ["res://autoload", "res://core", "res://data", "res://features", "res://ui", "res://tests"]
var bad := 0
var count := 0
var _started := false
func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true  # first frame: the autoloads exist now, so GameState/Content/Device resolve
	for r: String in ROOTS:
		_walk(r)
	print("CHECK files=%d failed=%d" % [count, bad])
	quit()
	return false
func _walk(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for sub: String in d.get_directories():
		_walk(path + "/" + sub)
	for f: String in d.get_files():
		var p := path + "/" + f
		if f.ends_with(".gd"):
			count += 1
			var s: GDScript = load(p)
			if s == null or not s.can_instantiate():
				bad += 1
				print("BAD_SCRIPT ", p)
		elif f.ends_with(".tscn"):
			count += 1
			var ps: PackedScene = load(p)
			if ps == null or not ps.can_instantiate():
				bad += 1
				print("BAD_SCENE ", p)
```

**ARCHITECTURE section 17 sync:** between the `## 17.` and `## 18.` headings, each ` ```gdscript ` block must equal its file byte for byte (the file without its single final newline). The sections map to these files:

| Section | File |
|---|---|
| 17.1 | `core/game_flow.gd` |
| 17.2 | `core/run_state.gd` |
| 17.3 | `core/save_io.gd` |
| 17.4 | `core/odds.gd` |
| 17.5 | `data/types/*.gd` (named in a backticked line before each block) |
| 17.6 | `autoload/content.gd` |
| 17.7 | `autoload/game_state.gd` |
| 17.8 | `autoload/device.gd` |
| 17.9 | `autoload/scene_router.gd` |
| 17.10 | `ui/components/safe_area_margin.gd` |
| 17.11 | `features/interview/answer_meter.gd` |
| 17.12 | `features/title/title.gd` |
| 17.13 | `tests/test_flow.gd`, `test_save.gd`, `test_odds.gd`, `test_interview.gd`, `test_offer.gd` |
| 17.14 | `core/interview_plan.gd` |
| 17.15 | `ui/components/ui_text.gd` |
| 17.16 | `core/hunt_tips.gd` |
| 17.17 | `features/intro/cutscene_plan.gd` |

A ~40-line Python script can compare the blocks with their files, or rewrite them from the files.

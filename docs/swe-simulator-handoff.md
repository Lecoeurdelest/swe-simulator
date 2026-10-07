# SWE Simulator: session handoff (written 2026-10-06)

Paste this at the start of the next conversation. It summarizes the previous sessions (2026-09-26 to 2026-09-29) so the next session can **start designing Phase 2 ("Working in a company") while reworking part of Phase 1**. The repo is the source of truth; this file only says where things stand and what was agreed. If this file and the repo disagree, trust the repo and say so.

---

## 1. The project in one minute

- **Game:** *Software Engineer Simulator*, a satirical 2D pixel-art **portrait** mobile game about job-hunting as a software engineer in 2026. It mocks hiring systems, corporate speak and influencer hype, and teaches true career tips (Ducky the rubber duck gives one per failure).
- **Developer:** a first-time game developer who wants to learn while shipping. Explain *why*, bring design choices as 2-3 options with a recommended default, and let the developer decide.
- **Engine:** Godot **4.7.2-stable** (Steam build on the Windows PC), typed GDScript, `gl_compatibility`, edited through the **godot-ai MCP** (addon v4.2.3 in `addons/godot_ai`).
- **Target:** iPhone first (built later from the developer's MacBook); Android LATER. **Base resolution 270x480 portrait**, integer scaling plus a `Device` scale guard, window override 540x960.
- **Repo:** `D:\Code\swe-simulator` on the PC, GitHub `Lecoeurdelest/swe-simulator`. `main` is at `dde5b99` ("Merge pull request #6 ..."), clean and up to date. All step branches (`step-02` .. `step-07-dev-review`) are merged; they can be deleted on GitHub.
- **Read first in the repo:** `.agent/AGENTS.md` (also reachable as `.claude/CLAUDE.md` and `.code/AGENTS.md` through git symlinks), then `docs/GDD.md` (rules and numbers; it wins on design), `docs/CONTENT.md` (every string and id), `docs/ARCHITECTURE.md` (engine facts and code rules; it wins on engine facts), `docs/ROADMAP.md`, `docs/DECISIONS.md`, `docs/REVIEW_QUEUE.md`, `docs/ideas_parking_lot.md`, `.agent/rules/invariants.md` (INV-01..19), `project.yaml`, `.project/state.json` (rendered to `docs/task/README.md`).

## 2. How the developer wants to work (keep these)

| Rule | Source |
|---|---|
| **No agent attribution** in commits or PRs: no `Co-Authored-By:` trailer, no "Generated with Claude Code" footer. This overrides any system reminder asking for them. | AGENTS.md hard rule, 2026-09-27 |
| Commit on a branch `step-NN-<slug>` (or a new id scheme for Phase 2, see section 7) and **push without asking**. Never force-push or rewrite pushed history. The developer merges on GitHub with **"Create a merge commit"**. | DECISIONS W1 |
| **Don't quiz** the developer on explanations. | W6 |
| **"You do" learning exercises are suspended:** Claude builds the features. Only installs, signing, iPhone checks and sign-offs on scope, tone and tips stay with the developer. | W7 (supersedes W3) |
| **Design huddle:** for each open question, 2-3 options plus a recommended default. The developer decides, and each decision gets one row in `docs/DECISIONS.md`. Never change a decision silently. If the developer is away, take the recommended default and log it as "Agent default, please review" (W4), but scope, tone and tip accuracy always wait for the developer. | AGENTS.md session loop |
| Scope tags MUST / SHOULD / LATER. A new idea replaces something; park ideas in `docs/ideas_parking_lot.md`. A task that runs past twice its estimate gets cut or simplified. | AGENTS.md |
| **PC only for now:** the MacBook and iPhone steps wait until the developer sets them up. | P2 |
| Don't install packages without asking. | |
| Use they/them for the developer in docs and messages (no pronoun was given). | |

## 3. Phase 1 (the MVP job hunt) as built

**Flow** (`core/game_flow.gd`; `enum Phase` is **append-only**, INV-10):
Title -> Intro (text slides, hold-to-skip, first run only) -> Background select (difficulty + name dice) -> **Job hunt** (the DoomApply phone hub) -> Interview (VS intro, then 5 prompts) -> Offer (contract) -> Hired card (`PHASE2_STUB`: stamp, then the Dream vs Reality sheet, then "To be continued: Phase 2 - The Working Life"), or the **Plan B** ending when rent runs out.
`TRANSITIONS`: TITLE -> INTRO/BACKGROUND_SELECT/JOB_HUNT/INTERVIEW/OFFER; INTRO -> BACKGROUND_SELECT; BACKGROUND_SELECT -> JOB_HUNT/TITLE; JOB_HUNT -> INTERVIEW/GAME_OVER/TITLE; INTERVIEW -> OFFER/JOB_HUNT/TITLE; OFFER -> PHASE2_STUB/JOB_HUNT/TITLE/GAME_OVER; PHASE2_STUB -> TITLE/BACKGROUND_SELECT; GAME_OVER -> TITLE/BACKGROUND_SELECT. Saved phases: JOB_HUNT, INTERVIEW, OFFER. The save is deleted on entering GAME_OVER and on leaving PHASE2_STUB, and `run_count` is counted right there (A18).

**Architecture:**
- Autoloads, in order: `_mcp_game_helper`, `Content` (JSON text), `GameState` (the only place scenes call: verbs), `Device`, `SceneRouter`.
- Pure rule classes in `core/`: `GameFlow`, `RunState` (all run data; `to_dict`/`from_dict`, plain data only), `SaveIO` (`user://save_v1.json`, temp + rename), `Odds` (every formula), `InterviewPlan`, `HuntTips`.
- UI helpers: `UiText` (incl. `UiText.fill`, which never prints ".." after a name ending in "."), `CutscenePlan`.
- Only `GameState.change_phase()` changes the phase.
- Tuning lives in 7 `.tres` files (`data/backgrounds/*`, `data/tiers/*`, `data/balance/balance_config.tres`, types in `data/types/`). Text lives in 16 JSON files in `data/content/`, read via `Content.text/field`.
- RNG: one seeded run RNG (seed and state saved as strings), an interview RNG from the checkpoint seed, and an offer RNG from `seed + "|offer"`. No global RNG (INV-04).
- Settings in `user://settings.cfg`: `intro_seen`, `run_count`, `last_background`, options.

**Backgrounds** (difficulty = character; changes every stage):

| | KNW/EXP/NET | Energy/day | Rent runway | Referrals | Radar N | Composure | Teamwork x | Salary x | Commute |
|---|---|---|---|---|---|---|---|---|---|
| Intern (Easy) | 50/40/45 | 9 | 15 days | 2 | 6 | 100 | 1.25 | 1.10 | 20 min |
| Graduate (Medium) | 55/15/15 | 8 | 12 | 0 | 8 | 100 | 1.0 | 1.00 | 45 min |
| Self-Taught (Hard) | 55/10/5 | 6 | 12 | 0 | 10 | 90 | 0.6 | 0.90 | 95 min |

**Company tiers:**

| | Invite base | Reply in | Doubt HP | Difficulty | Needle | Salary | Office days |
|---|---|---|---|---|---|---|---|
| Startup | 0.10 | 1 morning | 118 | 40 | 0.60 + "PIVOT!" jump | $50-70k + joke equity | 0 (remote) |
| Mid | 0.065 | 2 | 128 | 42 | 0.60 | $65-90k | 2 (hybrid) |
| Big | 0.03 | 3 | 132 | 44 | 0.75 | $95-125k | 4 |

TierData also holds **unused Phase 2 fields**: `meeting_load` 0.2/0.5/0.8, `layoff_risk` 0.3/0.1/0.2, `growth_mult` 1.5/1.0/0.8 (startup/mid/big).

**Job hunt (DoomApply hub):**
- The bottom dock has 4 slots: Jobs, Mail, Study, Sleep (A22).
- The Jobs deck deals 6 cards each morning. On a card: Skip, Quick Apply (1 pip, x0.6 odds, sends your honest CV), or flip it for **Tailor & Apply** (2 pips, x1.5; each CV line goes out as its honest "Polished" reframing, which can pass "1+ years" filters) and the referral toggle (x2.5, skips knockouts).
- Knockouts (degree, years) are the only auto-reject, and the email names the knockout.
- Ghost jobs never reply. The Recruiter Radar (pity counter) guarantees an invite after N relevant misses, and on the first run a day-2 guarantee gives an invite.
- Study costs 2 pips for KNOWLEDGE +5. Sleep ticks rent down by a day. Rent at 0 with no invite means Plan B; with an invite waiting you get one grace day.

**Interview:**
- A VS intro, then an HP duel: your Composure against Dana's Doubt.
- 5 prompts: `[choice, knowledge, knowledge, knowledge, choice]`.
- **Choice questions** are 3 buttons where the right answer is jokingly obvious.
- **Knowledge questions** use the one-tap **Answer Meter**: a needle and a NAILED IT zone whose width comes from your stats (stats decide about 75%, your tap about 25%).
- Outcomes: K.O. (Doubt reaches 0) leads to an offer. If Doubt ends at or below 15% of max, the Hiring Committee wheel decides. Otherwise it's a rejection with a Ducky tip and a model answer.
- Dana is competent, dry and fair, and keeps getting laid off and rehired elsewhere.

**Offer and endings:**
- Salary depends on how much Composure you kept. The contract shows work mode, commute, perks and fine print; a fine-print line never repeats a perk (`fine_print_pool`). Startup offers add equity "0.0001%".
- Accept leads to the Hired card. Decline blacklists the company and returns you to the hunt; on the grace day, Decline ends the run.
- **Dream vs Reality score** (out of 100, compared with the influencer Remy's video):
  - Salary: 40 points at $150k.
  - Days at home: 25.
  - Commute: 15.
  - Red flags: 10.
  - Rent days to spare: 10.
  - Grades: "All reality, no dream" / "Doable" / "Pretty good" / "Suspiciously close to the video".
- Negotiate and Research are SHOULD (not built yet; ROADMAP Step 8).

**Tests:** `tests/test_*.gd` (`@tool`, `extends McpTestSuite`; no autoloads or `user://` in tests, INV-12). **217 tests in 20 suites, all green**, and 85 scripts and scenes load. They run in the editor via godot-ai `test_run`, or headless (Appendix A).

## 4. What changed in the last working session (2026-09-29, PR #6, merged)

The developer reviewed the v0.1 grey-box and asked for 4 changes plus answers to the review queue. All were built, reviewed (36 findings, 22 confirmed and fixed) and merged:

1. **CV editing and lying removed (D9, supersedes D4).**
   - Gone: the CV screen, Lie variants, the lie probe (Come clean / Bluff / BUSTED), the degree background check and OFFER RESCINDED.
   - Your CV is your background's true CV; Tailor & Apply is the per-job polish.
   - No "Polish CV" button: no stat fits. KNOWLEDGE is what you know, EXPERIENCE is real work history, NETWORK is people, so raising one would be the lie again.
   - Old saves still load (removed keys are ignored, A23).
2. **Ducky coach marks close on a tap (D11).**
   - A small "x" hint; a closed mark stays closed (`RunState.coach_closed`, saved).
   - Doing the action still closes it.
   - The Offer screen's Ducky tip also fades in after the paper lands and closes on a tap (A47).
3. **Choice questions in plain language for non-tech players (C3).** 11 of the 14 were reworded, and the linked tips were simplified (A27, A49, A50). New tip: `tip_take_feedback`.
4. **VS intro waits for a tap (D12).**
   - It holds its last frame with a blinking "Tap to continue".
   - Dana shows one joke stat and one special move per interview (`vs_dana_move_1..3`, by `posmod(times_met_dana, 3)`).
   - Back acts like a tap. `vs_min_view_s` was removed.
5. **Hired card copy (C4):**
   - Header "YOUR JOB vs REMY'S VIDEO".
   - Footer "100 is the life in Remy's video. Nobody gets 100. Not even Remy."
   - Rows name Remy's number and show points out of the row maximum (A48).
6. **Real bars (W7):**
   - `HpBar` drains with a 0.4 s white ghost bar.
   - `StatBar` shows 5 blocks (7x7, amber `#FEAE34` on ink `#181425`), also on the VS plate.
7. **Copy:** REVIEW_QUEUE section 3 approved, plus 4 wording fixes (C2). Best Dream score per background is LATER (D10).
8. **Debug-only "Reset first run"** button on the Title, next to "Device check" (A51), so first-run coach marks can be replayed on this PC.
9. **Phase 2 is not scheduled (P3).** The developer hasn't chosen its mechanic. Ideas are parked; no cosmetic customization (D6 stands).

All agent defaults from that session are **A21-A51** in `docs/DECISIONS.md` ("Agent default, please review").

## 5. Open items waiting for the developer (`docs/REVIEW_QUEUE.md`)

- Skim the agent defaults A21-A51 (and A1-A20 if not done; A10, A11 and the lying parts of A9/A12/A13/A20 are void under D9).
- **A42, design question:** both HP bars fill left to right. Should Composure mirror so both anchor at the screen centre (fighting-game style)?
- **Q3, balance (ISSUE-09, open):**
  - The agent playtest ran harder than GDD 5.12: 1 K.O. and 4 committee wheels in 21 interviews, and the Medium and Hard first runs hit Plan B.
  - D9 makes it a little harder again: Quick Apply now sends the honest CV, so the Graduate and the Self-Taught fail "1+ years" filters unless they Tailor.
  - The GDD 5.12 simulation needs porting to `tests/test_balance.gd` and re-running (ROADMAP Step 7).
  - Tuning options from D8 (Doubt HP):
    - (a) current 118/128/132;
    - (b) +6;
    - (c) -8.
  - Other knobs: `base_invite`, `pity_n`, `committee_band`.
- **Q5:** should a quick flick also commit a swipe (A14)? Decide on the iPhone.
- **Copy sign-off:** the rewritten choice questions (CONTENT.md section 7), the Hired-card lines, the VS move lines and the reworded tips. Tip accuracy is the developer's call.
- **iPhone checklist (when the Mac and iPhone are set up):** ROADMAP Step 2 setup, the Title > Device check criteria, readability, the tiers' feel, the swipe feel, the coach-mark tap, the VS tap, the HP ghost feel, `docs/KILL_TESTS.md`, then tag `v0.1-greybox` on main.

**Task tracker** (`.project/state.json`):
- STEP-00 and 01: done.
- STEP-02: in_progress (device parts wait for the iPhone).
- STEP-03 to 06: verifying (developer-owned criteria left).
- STEP-07 (Playtest #1, tuning and balance sim): in_progress.
- STEP-08 to 13: todo.
- Issues: ISSUE-09 (balance) open; ISSUE-01 to 08 and ISSUE-10 (the v0.1 review) resolved.
- Task ids `STEP-00`..`STEP-13` are never renumbered.

## 6. Small known leftovers

- `features/intro/intro.gd:234`: a local `size` shadows `Control.size` (an editor warning from before the review, harmless).
- `DuckyNote.CLOSE_MARK := "x"` is a placeholder glyph in a script until the art pass (A34).
- `tip_teamwork_without_job` has no trigger in the MVP now (A49).
- GDD 5.12's simulation table predates D9; Step 7 must re-measure it.
- This PC's `user://save_v1.json` holds a test run, and `settings.cfg` has `run_count=0` from the Reset button. Tap New game for a clean run.

## 7. Phase 2: "Working in a company" (where to start)

**Status:** not designed, not scheduled (P3). The developer will choose the mechanic. Start with a **design huddle** before writing any code, and log each answer in DECISIONS.

**The developer's own direction so far** (`docs/ideas_parking_lot.md`):
- **Small random events** at the company, kept small: the company gets hacked; a coworker clicks a scam email; the company "resizes" (layoffs).
- **A few minor career improvements**, also kept small.
- **No cosmetic customization** for now (D6 stands).

**What the docs already commit to** (open to change in the huddle):
- **GDD 2.4:** the Work loop's top-down office with walking characters is LATER (every new viewpoint needs its own sprite set). A grey-box UI first fits the project's habits.
- **GDD 3.1, one shared Day Cycle:**
  - Work mode is commute -> standup -> tasks/meetings -> evening -> payday.
  - Being laid off, quitting, or a startup folding sends you back to the job HUNT with more EXPERIENCE.
  - HUNT and WORK share the morning, energy, commute, sleep and the rent/paycheck tick.
- **GDD 5.1 / 5.3:** EXPERIENCE grows only at work. Energy per day = 10 - commute pips, which becomes the work-day energy on office days.
- **GDD 6, difficulty matrix (Phase 2 row):**
  - Intern: energy 9, mentor events.
  - Graduate: energy 8, student-loan payday deductions.
  - Self-Taught: energy 6 on office days and 10 remote, lone-wolf teamwork events, fastest skill growth.
- **GDD 7, tier matrix (Phase 2 row):**
  - Startup: fast growth, overtime and pivot events, can fold.
  - Mid: legacy-code events, steady raises, a mentor.
  - Big: meetings drain energy, slow promotions, layoff waves.
- **GDD 10.4, hooks already stored in `RunState`:**
  - Character: `background_id`, `player_name`, `knw/exp/net`, `lone_wolf`, `gap_topics`.
  - Commute: `commute_pips/minutes`.
  - The job: `employment {company_id, tier, job_title, salary, work_mode, office_days, perks, red_flags, equity_text, negotiated}`.
  - Run state: `day`, `rent_days_left`, `dream_score`, `interviews_taken`, `times_met_dana`, `dana_last_company`, `blacklist`, `applied`, and the RNG seed and state.
  - Code hooks: TierData `meeting_load / layoff_risk / growth_mult`, `GameFlow.Phase` room for `WORK`, and a "laid off -> JOB_HUNT" entry point.
  - The lying hooks (`cv_levels`, `lies_carried`, imposter-debt tasks) were removed with D9.
- **Code facts to respect:**
  - Append new phases at the end of `GameFlow.Phase`.
  - Today the save is deleted when leaving `PHASE2_STUB`, and `run_count` counts there. Phase 2 must revisit `SAVED_PHASES`, `deletes_save` and that counting.
  - Content goes in JSON, numbers in `.tres`, rules in pure `core/` classes with tests, and scenes call only GameState verbs.

**Huddle questions to settle first** (suggested; bring options plus a recommended default for each):
1. Where Phase 2 sits in the ROADMAP relative to Step 7 (playtest), Step 8 (SHOULD features), the art steps 9-11, audio (12) and the release candidate (13), and how it's tracked. Never renumber `STEP-00..13`; propose new ids such as `STEP-14+` or a `P2-NN` prefix, plus a branch naming scheme.
2. The run shape: how long a work stint lasts, what ends it (laid off, fold, quit, promotion?), and win/lose conditions.
3. The core one-thumb daily action set, and how tasks resolve: reuse the Answer Meter, cards, or 3-choice questions?
4. Money: salary/paycheck against rent days (the hunt uses rent days, not cash).
5. Random events (hack, scam email, resizing): how often, how big, and what they cost or teach.
6. "Minor career improvements": which stat or perk grows, and how small.
7. Tone targets for workplace satire (punch up at employers and processes, never at struggling people; GDD 1.3).
8. Screens and viewpoint: a grey-box phone/desk UI now, top-down office LATER.
9. MUST / SHOULD / LATER for Phase 2, and what Phase 1 rework comes first.

**An optional draft exploration exists:** `phase2_draft_options.md`, attached alongside this file, with 3 design angles and a synthesis called "Probation". It was written on 2026-09-29 just before the developer paused Phase 2. **It is not a decision**; use it only as option input for the huddle. The developer's direction above wins.

**Reworking part of Phase 1:** the developer hasn't said which part yet. Ask which part, then follow the usual loop: huddle, a DECISIONS row, update the GDD/CONTENT first, then code + tests + doc sync.

## 8. Engineering checklist (lessons from the last sessions)

- **Session start:** open Godot on the project *before* Claude (Windows MSIX quirk), then `editor_state`: ready and not playing. Run `git switch main && git pull`.
- **Branch:** create a new one from `main`. Commit small increments and push. Write plain commit messages with no trailer.
- **After each increment:** run the game, take a screenshot (`editor_screenshot source="game"`), read `logs_read`, and run `test_run` (or the headless runner).
- **Always `project_run` with `autosave=false`.** In the last session an autosave with stale script tabs open overwrote `title.gd` and `docs/CONTENT.md`. It was caught and repaired before any commit, but check `git diff` after runs.
- `project_manage op=stop` before editing, and `filesystem_manage op=scan` after a new or removed `class_name` or file. `filesystem_manage op=remove` is refused in this repo; delete with `git rm`/`rm`, then scan.
- `game_manage input_mouse` uses **window** pixels (2x), with a `motion` event before each `button`. Use `game_manage suspend/resume` to catch a short animation.
- To see first-run coach marks on this PC, use the debug **Reset first run** button on the Title.
- **ARCHITECTURE section 17** holds byte-exact copies of 23 source files (game_flow, run_state, save_io, odds, the 3 data types, content, game_state, device, scene_router, safe_area_margin, answer_meter, title, interview_plan, ui_text, hunt_tips, cutscene_plan, and tests test_flow/test_save/test_odds/test_interview/test_offer). After changing any of them, re-sync (Appendix B).
- **Plan tracking:** run `python .project/render.py`, then the three validators: `python .agent/skills/plan-driven-development/scripts/check_project.py validate project.yaml`, `... audit-preservation project.yaml --root .`, and `... audit-task-status docs/task/README.md`. The only expected warning is "STEP-00: decision D4 is not accepted" (D4 was superseded by D9).
- **Windows tools:** git works from the Bash tool (not on the PowerShell PATH). There is no `gh` CLI, so PR status comes from the GitHub page. Use `python`, not `python3`, with `PYTHONIOENCODING=utf-8`.
- **Usage limits:** long multi-agent runs hit session limits twice. Prefer steps that commit often so nothing is lost.

---

## Appendix A: headless test runner (recreate in the scratchpad; not in the repo)

It runs every suite in a fresh Godot process on a copy of the repo, so it never touches the editor. It's safe to run in parallel if each run uses its own `PROJ`. Put the three files in one folder `HL` and run `bash run_tests.sh` (all suites), `bash run_tests.sh <suite_name>` (one suite) or `bash run_tests.sh parse` (load-check every script and scene). Expected today: `RESULT passed=217 failed=0` and `CHECK files=85 failed=0`.

`run_tests.sh`:
```bash
#!/usr/bin/env bash
set -e
HL="$(cd "$(dirname "$0")" && pwd)"
SRC="${SRC:-D:/Code/swe-simulator}"
GODOT="C:/Program Files (x86)/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
P="${PROJ:-$HL/proj}"   # use a unique PROJ per parallel run
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

`check_all.gd` (the walk runs on the first frame, after the autoloads exist, so names like `GameState` resolve):
```gdscript
extends SceneTree
const ROOTS := ["res://autoload", "res://core", "res://data", "res://features", "res://ui", "res://tests"]
var bad := 0
var count := 0
var _started := false
func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true
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

## Appendix B: ARCHITECTURE 17 sync check (recreate as needed)

The map from section to file: 17.1 `core/game_flow.gd`, 17.2 `core/run_state.gd`, 17.3 `core/save_io.gd`, 17.4 `core/odds.gd`, 17.5 `data/types/<name>.gd` (named in a backticked line before each block), 17.6 `autoload/content.gd`, 17.7 `autoload/game_state.gd`, 17.8 `autoload/device.gd`, 17.9 `autoload/scene_router.gd`, 17.10 `ui/components/safe_area_margin.gd`, 17.11 `features/interview/answer_meter.gd`, 17.12 `features/title/title.gd`, 17.13 `tests/<name>.gd` (named in a backticked line before each block), 17.14 `core/interview_plan.gd`, 17.15 `ui/components/ui_text.gd`, 17.16 `core/hunt_tips.gd`, 17.17 `features/intro/cutscene_plan.gd`.

How to check: between the `## 17.` and `## 18.` headings, each ` ```gdscript ` block must equal its file byte for byte (the file ends with exactly one newline; the block is the file without that last newline). To sync, rewrite every block from its file and print the sections that changed. A ~40-line Python script does both (it was `cmp17.py` / `sync17.py` in the old scratchpad); rewrite it from this description if it's gone.

Optional first task for the next session: ask the developer whether to commit these helpers into the repo (e.g. `tools/headless/` and `tools/arch17.py`), so they stop living in temporary folders.

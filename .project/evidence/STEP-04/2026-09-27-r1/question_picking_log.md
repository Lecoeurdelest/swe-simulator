# STEP-04 stage "question_picking": question picking, the warm-up and the frozen checkpoint (2026-09-27, Windows PC)

Godot 4.7.2-stable (steam) with the godot-ai MCP. The game ran embedded in the editor's Game tab: window 540x960, game 270x480, integer x2. Taps were real `game_manage input_mouse` events in window pixels (game px x2): a motion event, then press, then release at the control's centre. `game_eval` was used only to read state (`GameState.run`, `SaveIO.read()`, `Content.entry()`), for the lead's requested `debug_quick_start` + `start_interview` check (section 3), and for cleanup (section 4). No button was pressed by emitting `pressed` from `game_eval`.

Start state: the editor was ready and not playing; `test_run` 62/62 in 7 suites; editor log cursor 53 (only the known stale "Identifier not found" autoload errors); no `user://save_v1.json` and no `user://settings.cfg`.

## What was built

| File | What |
|---|---|
| `core/interview_plan.gd` (new, `@tool class_name InterviewPlan extends RefCounted`) | Pure static helpers. `pick(cfg, tier_id, choice_pool, knowledge_pool, seen, rng, with_warmup) -> {question_ids, warmup_id}`: one id per `cfg.prompt_pattern` slot in prompt order (choice, knowledge x3, choice), drawn with `Odds.pick` from the tier's questions (`tiers` list; `opener_only` excluded; `_` metadata keys skipped; ids sorted first so the JSON key order never matters). Unseen questions first; a dry pool falls back to the least recently seen ones. Rolls in a fixed order: choice, knowledge, then the warm-up. `warmup_due(run)` = `run.first_run and run.interviews_taken == 0`. `eligible(pool, tier_id)`. `mark_seen(seen, ids)` moves each asked id to the end of `seen`, so `seen` stays ordered least to most recently asked (what the fallback reads). |
| `autoload/game_state.gd` | `start_interview`: rolls `seed` from the run RNG first (as before), then `InterviewPlan.pick(...)` on the run RNG with `Content.entries("questions_choice" / "questions_knowledge")`, `run.seen_question_ids` and `warmup_due(run)`; the checkpoint gains `question_ids` (prompt order), `warmup_id` and keeps `probe_line: ""` (Step 5 rolls it); `mark_seen` adds the 5 ids plus the warm-up to `run.seen_question_ids` before `change_phase(INTERVIEW)` saves the checkpoint. |
| `tests/test_interview_plan.gd` (new, suite `interview_plan`) | 11 tests. Real pools read with FileAccess (never the Content autoload, INV-12); dry-pool cases on fixtures built in code. |

## 1. test_run

- After the helper and its tests: `interview_plan` 11/11.
- After the GameState change, and again after the game run: **73/73, 8 suites** (`question_picking_test_run.json`).
- `core/interview_plan.gd`'s second `script_create` returned a diagnostic "GDScript reload failed with error code 43" pointing at line 92 (past the end of the 92-line file), with no editor-log line. A throwaway `tests/test_zz_tmp_probe.gd` compiled the on-disk source fresh with `GDScript.reload()` (OK), confirmed the cached script's source equals the disk file and `can_instantiate()` is true; the probe was then deleted with `rm` + `filesystem_manage op=scan`. `InterviewPlan` is in `.godot/global_script_class_cache.cfg`.
- Editor log: one new line during the stage, `Compile Error: Identifier not found: Content` at `game_state.gd:129` (pre-existing `_init_run` code, re-reported when the scan reloaded the edited autoload): the known stale-autoload gotcha. Nothing new after the game run.

## 2. Game run (`project_run mode="main"`, run `r55186208-19`)

| # | Action (window px) | Observed | phase |
|---|---|---|---|
| 1 | Boot | Title, "Tap to start" | TITLE |
| 2 | Tap empty space (270,500) | Intro stub | INTRO |
| 3 | Tap SKIP (356,916) | Background select | BACKGROUND_SELECT |
| 4 | Tap THE GRADUATE (270,748) | Hunt stub: Day 1, Energy 8/8. Read: `first_run` true, `interviews_taken` 0, `seen_question_ids` [], `interview` {} | JOB_HUNT |
| 5 | Tap "Fake invite (Mid)" (270,748), i.e. `start_interview(FAKE_INVITE)` | Checkpoint: `question_ids` [eq_any_questions, kq_sql_injection (d2), kq_index_tradeoff (d2), kq_hash_map (d1), eq_weakness], `warmup_id` kq_star_conflict (difficulty 1, tiers startup/mid/big, not a prompt), seed "2466818061", `probe_line` "", tired false. `seen_question_ids` = the 5 ids + the warm-up. `SaveIO.read()`: phase INTERVIEW, the same `question_ids`, `warmup_id` and seen list, and `rng_state` equal to the live `str(rng.state)` | INTERVIEW |
| 6 | Tap `< Back` (96,916), then "Quit to title" (270,818) | Title with `[ New game ]` and CONTINUE | TITLE |
| 7 | Tap CONTINUE (270,836) | `continue_game()` loaded the save: the **same** `question_ids`, `warmup_id` and seed; `seen` still 6 ids (no re-pick); `rng.state` = the saved state; tree not paused | INTERVIEW |
| 8 | Tap Lose (270,832) | `interviews_taken` 1, `interview` {} | JOB_HUNT |
| 9 | Tap Sleep (420,916), then Fake invite (270,748) | Day 2. Second interview: [eq_impossible_deadline, kq_cache_first_fix, kq_idempotent, kq_recursion_base, eq_ai_takehome], `warmup_id` "" (not the first interview), **0 repeats** from interview 1; seen 11 ids, saved | INTERVIEW |

Screenshots (`editor_screenshot source="game"`, not savable as files): after steps 5 and 9 the Interview stub showed "INTERVIEW (STUB)", "co_beigeware (mid)", "job_mid_backend", `[ Lose ]` and `[ < Back ][ WIN ]`; the stage doesn't show the questions yet (the interview scene is a later stage).

Game log for the run: only the helper line and `Content: 3 backgrounds, 3 tiers, 16/16 JSON files`: **0 errors, 0 warnings**.

## 3. The lead's `game_eval` check

Twice in one eval: `GameState.debug_quick_start("graduate", GameFlow.Phase.JOB_HUNT)` (seed 20260926), then `GameState.start_interview({app_uid: 0, company_id: "co_beigeware", template_id: "job_mid_backend", tier: "mid"})`, 0.8 s apart.

- Both times: phase INTERVIEW, `question_ids` [eq_weakness, kq_index_tradeoff, kq_star_conflict, kq_learn_fast, eq_leaked_password], `warmup_id` kq_hash_map, seed "2109228122". Every id exists in `questions_choice` / `questions_knowledge` via `Content.entry`. `same_both_times: true`, so the same seed gives the same interview.

## 4. Cleanup

`game_eval`: `GameState.quit_to_title()` first (TITLE is never saved, so the close handler can't rewrite the save), then `SaveIO.delete()` and `DirAccess.remove_absolute("user://settings.cfg")` (err 0). `project_manage op=stop`. The user folder then held neither `save_v1.json` nor `settings.cfg`. `autoload/game_state.gd` still had the change on disk after the run's autosave (stale-buffer check).

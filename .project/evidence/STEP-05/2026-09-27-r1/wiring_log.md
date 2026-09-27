# STEP-05 wiring stage: GameState on the hunt rules, rule defaults, lie-probe trigger, degree check

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-05-hunt-greybox.
ROADMAP Step 5 task 2 (wiring) and task 5 (the real lie-probe trigger). Tests: `wiring_test_run.txt`.

## What changed

| File | Change |
|---|---|
| `autoload/game_state.gd` | Hunt verbs on the RunState rules (below); `_tiers()`, `_hunt_content()`, `_bg()` helpers; `_init_run` uses `run.set_background()` then deals the day-1 board; `start_interview` takes the invite, stores `invite["uid"]` as `invite_uid` and rolls the probe; `finish_interview` / `answer_offer` use `run.blacklist_company()`; Decline on the grace day ends in Plan B; Accept runs the degree background check; `preselect_background` = last background played |
| `core/run_state.gd` | `CV_LEVELS`, `REJECT_MAIL_PREFIX`, field `rescinded`; `set_cv_level()`, `roll_probe()`, `background_check_caught()`, `rescind_offer()`, `reject_mail_id()`; blacklist withdraws invites and silences pending applications; dry-deck fallback (`_free_pairs`, `_companies_of(..., mvp)`); ghost-free profile fallback; knockouts never fill the Radar even when silenced |
| `core/game_flow.gd` | OFFER -> GAME_OVER is legal (Decline on the grace day, GDD 5.10) |
| `features/job_hunt/job_hunt.gd` | Stub only: "Take first invite" starts an interview from the first real waiting invite (the old fake invite had no uid); Sleep = `sleep()` + `start_day()` (the stub has no inbox yet); status shows cards and invites |
| `tests/test_hunt_defaults.gd`, `tests/test_probe_trigger.gd` | New: 12 + 11 tests |
| `tests/test_flow.gd`, `test_hunt_board.gd`, `test_hunt_edges.gd`, `test_hunt_reveal.gd` | Fixture / coverage updates (see `wiring_test_run.txt`) |
| `docs/ARCHITECTURE.md` 4.1 + 17.1, `docs/GDD.md` 4.1 | The OFFER -> GAME_OVER transition (real contradiction with GDD 5.10, fixed) |

### GameState verbs (ARCHITECTURE 11.4 list, 17.7 structure kept)

- `quick_apply(card_uid) -> bool`, `tailor_apply(card_uid, use_referral) -> bool` (shared `_apply`), `skip_card(card_uid) -> bool`: each commits once; false and no save when refused.
- `set_cv_level(line, level) -> bool`: changes `cv_levels` and emits `run_changed`, no save; `commit_cv()`: the one save when the CV screen closes (ARCHITECTURE 8).
- `study()` kept as is.
- `sleep()`: `run.sleep(Content.balance, _tiers(), bg, _hunt_content(), rng)` then `_commit()`: exactly one save.
- `start_day()`: `run.start_day()` -> `end_run_plan_b()`, else `_commit()`.
- `start_interview(invite)`: tier + cost check, today's slot + energy check, `run.take_invite(uid)` (refused if gone), pay, then seed -> questions -> `run.roll_probe(...)` on the run RNG, checkpoint frozen with `invite_uid = invite["uid"]` and `probe_line`.
- `answer_offer(false)`: blacklist; rent 0 (grace day) -> `end_run_plan_b()`, else JOB_HUNT. `answer_offer(true)`: `run.background_check_caught(...)` -> `run.rescind_offer()` + JOB_HUNT, else Hired as before.

### Rule defaults (as the lead chose them)

- (a) A tier deals from its MVP companies while any MVP pair is free, then from its non-MVP companies. The whole deck is 58 pairs over all 9 companies (test deals and applies every one exactly once).
- (b) `blacklist_company(id)`: cards leave the board, waiting invites are removed with no mail (their applications end `expired`), pending applications reveal `silent` with no dice. A relevant silenced application fills the Radar like any silence; a knocked-out one never does (GDD 5.7). The day-2 guarantee skips blacklisted companies.
- (c) Plain rejection: `mail_id` = sorted `mail_reject_*` ids[uid mod count], stored in the report entry; no RNG draw.
- (d) The "saw your profile" fallback skips ghost cards; only-ghost startup cards means no guarantee invite.
- (e) Kept: ghost before Radar, the guarantee replacing a same-morning reveal, `passes_years` a boolean (test added).

### Agent defaults in this stage (please review)

- `preselect_background`: read from settings `[meta] last_background` at boot and written by `choose_background()`; `retry()` still sets it. The Graduate when empty (GDD S03 "the last background played is preselected").
- `rescinded` (new RunState field): holds the `mail_rescinded` notice for the hunt scene; the next Sleep clears it.
- A withdrawn invite's application ends `expired` (no new status, no mail).
- Probe order on the run RNG: interview seed, then questions, then the probe roll. The probe checks the application's recorded Lie lines in CV order and stops at the first hit (the checkpoint holds one `probe_line`).

## In-game verification

Three launches (`project_run` main): runs r72604717-35, r72698209-36, r72902644-37. `logs_read source=game`: 0 errors, 0 warnings in all three. Editor-side: only the known autoload "Identifier not found" family.

Real taps (`game_manage input_mouse`, motion then press/release, window px = 2x game px): Title tap-to-start, Background select THE GRADUATE, the stub's "Take first invite" (twice), Offer Decline + confirm Decline, Plan B RETRY, THE INTERN, Offer ACCEPT, the stub's Sleep, Title CONTINUE, Title New game. Desktop Esc skipped the intro.

Fell back to `game_eval` (the Step 5 deck, CV and Mail screens don't exist yet): the applies/skip/CV verbs, `GameState.sleep()` on its own (the stub's Sleep also presses Start day), `GameState.start_day()`, and setup only: `finish_interview(true, ...)` to reach the offers, rent 0 + grace used for the grace-day decline, one injected invite for the intern's Big application, and one read-only peek at a copy of the run RNG before Accept (no draw consumed).

### 1. New run as The Graduate (seed 1645877322)

Before the tap: `preselect_background` "", no `last_background`, Graduate button is the PrimaryButton. After CHOOSE: JOB_HUNT, day 1, energy 8/8, rent 12, first run, `last_background` = graduate, save written. Board = 6 cards, 2 per tier:
`1 job_st_founding|co_synergai`, `2 job_mid_fullstack|co_beigeware (ghost)`, `3 job_big_ai_engineer|co_nimbus`, `4 job_st_ai_generalist|co_synergai`, `5 job_mid_web_rescue|co_bytebistro (ghost)`, `6 job_big_junior_swe|co_omniglobal`.

### 2. The scripted day (game_eval, real verbs)

- `set_cv_level("hobbies","lie")` false; `set_cv_level("proj","lie")` true; `commit_cv()` -> the save holds `proj: lie`.
- `skip_card(5)` true -> deck `[1,2,3,4,6,5]`.
- `tailor_apply(1)`, `tailor_apply(4)` true (P 0.2587, 3/3 tags, lie recorded); `tailor_apply(6, true)` false (no referral token); `quick_apply(3)`, `quick_apply(6)` true (knockouts `knock_years` n=3 / n=5); `quick_apply(2)` true (ghost job); `quick_apply(999)` false. Energy 8 -> 1; the save has 5 applications.

### 3. Sleep -> morning_report (one save)

13 keys: board_new, day, expired, ghosted, grace_day, guarantee, invites, night, no_reply, plan_b, radar, rejections, rent_days_left. Day 2, energy 8, rent 11. A rolled startup invite for app 4 (invite uid 7). Rejections in send order: app 1 plain -> `mail_reject_02` (uid 1 mod 10 -> index 1), apps 3 and 6 -> `mail_knockout` with their knockout. The mid ghost (app 2) is still pending (2 mornings). Saved report == live report; saved `rng_state` == live (9211195833958023362).

```json
{"board_new":6,"day":2,"expired":[],"ghosted":[],"grace_day":false,"guarantee":"","invites":[{"app_uid":4,"company_id":"co_synergai","day_received":2,"kind":"rolled","mail_id":"mail_invite_startup","template_id":"job_st_ai_generalist","tier":"startup","uid":7}],"night":{"applied":5,"ghosted":0,"rejected":3,"rent_days_left":11},"no_reply":0,"plan_b":false,"radar":{"after":0,"before":0,"max":8},"rejections":[{"app_uid":1,"company_id":"co_synergai","knockout":{},"mail_id":"mail_reject_02","template_id":"job_st_founding","tier":"startup"},{"app_uid":3,"company_id":"co_nimbus","knockout":{"args":{"n":3},"id":"knock_years"},"mail_id":"mail_knockout","template_id":"job_big_ai_engineer","tier":"big"},{"app_uid":6,"company_id":"co_omniglobal","knockout":{"args":{"n":5},"id":"knock_years"},"mail_id":"mail_knockout","template_id":"job_big_junior_swe","tier":"big"}],"rent_days_left":11}
```

### 4. Kill after Sleep, relaunch, Continue

`project_manage op=stop` right after Sleep's save, `project_run`, real tap on CONTINUE -> JOB_HUNT day 2. The report string after Continue is byte-identical to the one before the kill and to the report inside the save file copied after the stop (`cmp` and a JSON re-dump); the RNG state is the same 9211195833958023362.

### 5. Start day, then GO NOW with a probe roll

`start_day()` cleared the report (live and saved). Real tap "Take first invite" -> INTERVIEW: checkpoint `invite_uid` 7 (the invite uid; the app uid is 4), energy 8 -> 5, Mail empty, app 4 `interview`, saved checkpoint == live. Probe: `""` (the Projects lie counts for ai_generalist via "ai", startup chance 0.30, the roll missed).

### 6. Decline on the grace day

Setup: `finish_interview(true, 80.0)` -> OFFER; rent 0, grace used. Real taps Decline -> confirm Decline -> GAME_OVER (the new OFFER -> GAME_OVER edge, no "Illegal phase change" error), save deleted, `run_count` 1, `co_synergai` blacklisted.

### 7. Retry keeps working

Real tap RETRY -> Background select, Graduate preselected. Real tap THE INTERN -> new run, `first_run` false, `last_background` = intern.

### 8. The real lie probe fires

Setup: Education and Experience set to Lie through the verbs, `quick_apply` on `3 job_big_frontend|co_omniglobal` (lies recorded: `cv_intern_edu_lie`, `cv_intern_exp_lie`; no knockout), one invite injected for it. Real tap "Take first invite": checkpoint `probe_line` = `cv_intern_edu_lie` (the degree claim, first in CV order; P = 1 - 0.4 x 0.4 = 0.84 at Big), saved. The interview's own trace: `IVSTART|tier=big|...|probe=cv_intern_edu_lie|ids=eq_weakness,kq_estimate,cv_intern_edu_lie,kq_star_conflict,eq_impossible_deadline` (knowledge prompt 2 `kq_sql_injection` replaced by the probe).

### 9. Degree background check on Accept

Setup: `finish_interview(true, 70.0)` (no confession) -> OFFER at co_omniglobal (Big, check 0.70). A read-only copy of the run RNG showed the next draw 0.527 (< 0.70), so no nudging was needed. Real tap ACCEPT -> JOB_HUNT, still day 1: offer `{}`, `rescinded` = `{company_id: co_omniglobal, template_id: job_big_frontend, tier: big, mail_id: mail_rescinded}` (also in the save), `co_omniglobal` blacklisted and off the board, no employment, `run_count` still 1. `Content.text("emails", "mail_rescinded")` = the CONTENT.md line. Real tap on the stub's Sleep -> day 2, `rescinded` cleared, report cleared.

### 10. Preselect survives a restart

Stop, relaunch, real tap New game -> Background select with THE INTERN as the PrimaryButton (`preselect_background` "intern", read from settings at boot).

### Cleanup

`SaveIO.delete()` and `DirAccess.remove_absolute("user://settings.cfg")` in the game, then stop. The user data folder has no `save_v1.json` and no `settings.cfg` (neither existed before this stage). The 10 edited source files hashed identical before and after the runs (no stale editor buffer wrote over them).

## Left for the Doc sync stage

- ARCHITECTURE 7.1: new RunState field `rescinded`.
- ARCHITECTURE 8: settings `[meta] last_background`.
- ARCHITECTURE 11.4 verb list: `commit_cv()`; 17.7 skeleton vs the wired GameState.
- GDD 5.9.4 says "if lying ships without [the SHOULD background-check screen], degree lies are only probed"; this stage implements the check without the screen, as instructed.
- DECISIONS rows for the lead's rule defaults (a)-(e) and the agent defaults above.

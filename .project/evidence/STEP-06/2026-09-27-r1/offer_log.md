# STEP-06 offer stage: the whole offer, the paper contract, and the Hired-card resume rule

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings.
ROADMAP Step 6 tasks 1-2 (the offer part) and the Done-when "a kill on the Hired card resumes at the offer; leaving the Hired card clears the save", per ARCHITECTURE 7.1, 7.2, 8, 9, 10, 11.7 and GDD S10, 5.9, 5.10, 5.11, 8.1, 8.3.
Tests: `offer_test_run.txt` (214/214, 19 suites; 200/19 before).

## What changed

| File | Change |
|---|---|
| `core/run_state.gd` | `make_offer(cfg, tier, bg, content, composure_left)` builds the whole offer from the interview checkpoint; static `offer_rng(seed)` (the checkpoint seed + "\|offer", hashed), static `offer_commute(office_days, commute_minutes)`, `decline_ends_run()` (rent at 0 = the grace day), `_tier_entries()`; consts `OFFER_PERKS` (2), `EQUITY_TIER` ("startup"), `OFFER_SEED_SALT`. The `offer` field comment lists the new shape. |
| `autoload/game_state.gd` | `finish_interview` calls `run.make_offer(...)` on a win (before the checkpoint is cleared). `answer_offer(false)` asks `run.decline_ends_run()`. **run_count fix:** `_count_finished_run()` moved out of `answer_offer(true)` and `end_run_plan_b()` into `change_phase()`, right after `SaveIO.delete()` when `GameFlow.deletes_save(from, to)`: a run counts once, when its save is deleted (Plan B, or leaving the Hired card). |
| `core/hunt_tips.gd` | `offer(run)`: the offer's one tip (startup with equity -> `tip_equity_lottery`, else `tip_total_comp`). |
| `ui/components/ui_text.gd` | `word_wrap(text, columns)` (the lint's line rule, returning the lines) and `field(label, value, label_columns, columns)` (the S10 label column). Named `word_wrap`, not `wrap`: `wrap()` is a GDScript global and shadowing it broke the class. |
| `features/offer/offer.tscn` + `offer.gd` | The S10 screen (below). |
| `data/content/emails.json`, `barks.json`, `docs/CONTENT.md` 13.1 and 10.1 | 11 new ids (below). |
| `tests/test_offer.gd` (10 new tests), `tests/test_flow.gd` (2), `tests/test_ui_text.gd` (2) | See `offer_test_run.txt`. |

### The offer (plain data, INV-07)

`run.offer = {company_id, template_id, tier, job_title, salary, work_mode, office_days, commute {id, args}, perks [2 ids], fine_print, equity_text, negotiated}`.
`job_title` is the posting's title as the JSON has it (the screen `tr()`s it); `work_mode` (`offer_mode_<tier>`), `commute.id` (`offer_commute_remote` / `offer_commute_office`), `perks` (`perk_*`), `fine_print` (`fp_*`) and `equity_text` (`offer_equity`, or "" off startups) are emails.json ids; `commute.args` = `{office_days, commute_min, hours}` with hours as one-decimal text ("12.7"). Salary is the existing `Odds.offer_salary`. Perks then fine print are picked with `Odds.pick` on `offer_rng(checkpoint seed)`: never the run RNG or the global RNG, so a replayed interview builds the same contract (checked in game: the same seed "1351991277" gave the same perks and fine print at Entangled Greens in run 60 and at Hierarchai in run 62).

### The screen (`offer.tscn`, 270x480)

```
Offer (Control, full rect)                          offer.gd
├─ Background (dark ColorRect)
├─ Stage (top-wide; bottom = the paper's resting top): TierBackground (tier color), PlayerBust (hoodie),
│    Desk, Dimmer (0.6), DanaBust (above the dimmer: "Dana stays visible")
├─ SafeArea > Column (254, separation 4)
│    StageSpacer (EXPAND_FILL) · Paper (PaperPanel 254) > Contract (RichTextLabel 240, fit_content,
│    line_separation -1 = the 12 px pitch, autowrap off: lines are pre-wrapped) · TipNote (DuckyNote) ·
│    DanaLine (hidden; Dana's Decline answer) · ThumbBand: BackRow [ < Back ] 80x36, ActionBar
│    [ Decline ] 80x36 + [ ACCEPT ] 168x36 (x 94-262)
└─ ModalLayer: PauseMenu, DeclineDialog (confirm_dialog)
```

Contract order (CONTENT.md 13.1 / S10): `offer_title` (company), `offer_dear`, `offer_role` (job title), a blank line, then one field per line after a 12-column label, values wrapped at 28 columns: Salary (`offer_salary`, yearly), Equity (startups only), Work mode, Commute (2 lines), Perks (2, the second under the first), Fine print (up to 4 lines), then `offer_deadline`. Worst case 19 lines = a 243 px paper (every tier checked by `test_contract_fits_the_paper`).

## Content ids added (all need developer sign-off)

| id | Text | Source |
|---|---|---|
| `offer_dear` | Dear {player_name}, | CONTENT.md 13.1 template |
| `offer_role` | We are thrilled (legally required wording) to offer you the role of {job_title}. | 13.1 template |
| `offer_label_salary` | Salary: | 13.1 template |
| `offer_label_mode` | Work mode: | 13.1 template |
| `offer_label_commute` | Commute: | 13.1 template |
| `offer_label_perks` | Perks: | 13.1 template |
| `offer_label_fine_print` | Fine print: | 13.1 template |
| `offer_deadline` | Please decide before you sleep. | 13.1 template, GDD S10 |
| `offer_label_equity` | Equity: | new label (no source) |
| `offer_equity` | 0.0001% | GDD 5.9.2 / 7 "0.0001% equity" |
| `ui_decline_confirm_grace` (barks) | Decline this offer? Rent is due today, so this ends the run. | new, functional (no source) |

## Agent defaults, please review (W4)

1. **Equity at startups is its own field** ("Equity: 0.0001%") under the salary. GDD 7 puts the joke equity with the startup salary; S10 has no Equity line, and `fp_equity` is only one of the startup fine-print picks, so it can show twice (field + fine print).
2. **One tip slot:** a startup offer shows `tip_equity_lottery`, every other offer `tip_total_comp` (its trigger is "offer with a commute"; startups are fully remote). `tip_negotiate` waits for Negotiate (SHOULD, D7, not built).
3. **Decline beat:** after the confirm, Dana's `bark_dana_decline` ("No worries! (Our ATS will remember this.)", GDD 5.9.4) replaces the tip; a tap, Back or 2.5 s moves on, and only then is `answer_offer(false)` called (a kill during her line leaves the offer open).
4. **Grace-day wording:** when `run.decline_ends_run()` (rent at 0), the confirm uses `ui_decline_confirm_grace`; otherwise `ui_decline_confirm`.
5. **Paper slide:** 0.3 s ease-out after the scene fade; ACCEPT and Decline stay disabled until it lands (the input lock). The stage's desk line follows the paper's resting top, so Dana sits right above the contract; at 270x480 only her lower 60-70 px show (the paper plus tip plus thumb band take 400-410 of 472 px), at 294x639 all of her shows.
6. **Back:** the on-screen `[ < Back ]` row (kept from the Step 3 stub) and Esc call `handle_back()`: confirm open -> cancel; Pause open -> resume; Dana's line -> move on; after Accept -> nothing; else open Pause. Back never declines.
7. **Perks show without a trailing period** (the S10 mockup has "Ping-pong table."); no string exists for it.
8. **run_count** now counts a run when its save is deleted (Plan B, leaving the Hired card), not on Accept. A run abandoned with New game (including one killed on the Hired card and never continued) is not counted, like any other abandoned run.
9. **Commute hours** keep one decimal, also when whole ("3.0 h a week").

## Verification

Runs: `r84835961-59` (project_run custom offer.tscn, smoke with an empty run), run 60 (main, run_token 60: Intern, Startup offer, Decline dialog, Pause, ACCEPT, Hired card, then killed), `r85000320-61` (main: Continue after the Hired-card kill, Graduate Mid decline, grace-day Decline, Retry, Self-Taught Big rescind), `r85360647-62` (custom offer.tscn: 294x639 layout probe, Esc/Pause).
Input: real `input_mouse` taps (motion, then press, then release; window px = 2x game px), `input_mouse` wheel_up to scroll the CV list, `input_key Escape`.
game_eval was used for: state reads and waits; fast-forwarding days 1-12 of the Graduate run with the same `GameState.sleep()` / `start_day()` verbs, then `GameState.debug_fake_invite("mid")` into Mail (so the real Sleep that followed produced a real grace day); run 62's setup (`debug_quick_start("self_taught", OFFER)`, a checkpoint, `run.make_offer(...)`, `reload_current_scene()`, content scale 294x639 KEEP + SafeArea fake insets (0,45,0,26), restored to EXPAND 270x480) and one Back there through `Device.handle_back()` (the Esc that opened Pause was a real key).

| Check | Result | Detail |
|---|---|---|
| test_run all | pass | 214/214, 19 suites (200/19 before). |
| Startup offer (DEBUG fake invite START + DBG K.O., real taps) | pass | Run 60, Intern: Entangled Greens (co_quantumleaf), "AI Generalist (Everything Engineer)", $72,000/year (K.O. at full Composure: band 0.75, 65k x 1.10 = 71.5k -> 72k), Equity 0.0001%, Fully remote, Commute "0 minutes. The influencer / was right about one thing.", Perks Unlimited PTO* (2 lines) + Ping-pong table, Fine print fp_equity (4 lines), deadline. Tip `tip_equity_lottery`. 19 lines, paper 254x243 at y 78, stage bottom 78, tip 69 px, `< Back` 80x36 at y 398, Decline 80x36 + ACCEPT 168x36 (x 94-262) at y 440. Contract text = `run.offer` field by field. |
| Mid offer | pass | Run 61, Graduate: Beigeware Financial (title wraps: "OFFER OF EMPLOYMENT - Beigeware" / "Financial"), "Backend Developer", $84,000 (65-90k at 0.75), "Hybrid: 2 office days a week" (exactly 28 columns), "2 days x 45 min each way = / 3.0 h a week", perk_banana + perk_pto20, fp_on_call; tip `tip_total_comp`. A second one at Lukewarm Express: perk_banana + perk_pizza, fp_salary_review. |
| Big offer | pass | Run 61, Self-Taught: Murkcloud, "AI Engineer (Junior)", $106,000 (95-125k at 0.75 x 0.90 = 105.75k), "Office: 4 days a week", "4 days x 95 min each way = / 12.7 h a week" (the GDD S10 example), perk_rsu + perk_insurance, fp_family; tip `tip_total_comp`. |
| Decline, normal day | pass | Run 61: Decline (real tap) -> "Decline this offer? Rent keeps ticking." -> DECLINE (real tap) -> Dana's line in the tip slot, buttons and `< Back` disabled -> after 2.5 s JOB_HUNT, same day (1), Beigeware blacklisted, save = JOB_HUNT with the blacklist, run_count unchanged. |
| Decline dialog Back, Pause | pass | Run 60: Esc with the dialog open cancelled it (dialog closed, no Pause, still OFFER); the on-screen `< Back` (real tap) opened Pause and paused the tree; RESUME (real tap) closed it. Run 62: Esc opened Pause; Back again resumed it. |
| Grace-day Decline wording | pass | Run 61: days 1-12 fast-forwarded, a Mid invite in Mail, then a real Sleep (confirm "You still have 8 energy") -> day 13, rent 0, `grace_day` true -> night -> Mail ("Your landlord gave you one more day. ONE.") -> GO NOW (real tap) -> DBG K.O. -> offer. Decline (real tap) -> "Decline this offer? Rent is due today, so this ends the run." -> DECLINE -> Dana's line -> a tap moved on -> GAME_OVER, save deleted, run_count 1 -> 2 once; RETRY (real tap) -> Background select, run_count still 2. |
| Kill on the Hired card -> Continue -> offer -> Accept | pass | Run 60: ACCEPT (real tap) -> Hired card (PHASE2_STUB); the save on disk stayed the OFFER one (phase 5, rng_state 6348759011955413342 = the live RNG state), run_count 0. Project stopped (kill). Run 61: CONTINUE (real tap) -> OFFER with the identical `run.offer` and contract text and the same RNG state; ACCEPT -> Hired card, run_count still 0; NEW RUN (real tap) -> Background select, save deleted, run_count 0 -> 1 (once). |
| Background check on Accept (A13) | pass | Run 61, Self-Taught: Education set to Lie on the CV screen (real taps, wheel scroll), Quick Apply to a Murkcloud card (real tap; the application carries cv_self_taught_edu_lie), DEBUG fake invite BIG (Murkcloud) -> K.O. -> ACCEPT: tier.background_check (0.70) rolled once on the run RNG (state -8946038949432016503 -> 4945992957029127235) and caught it -> JOB_HUNT, `run.rescinded` = mail_rescinded, Murkcloud blacklisted, run_count unchanged; Mail shows the rescind mail and `tip_honesty_checks`. The replay of this roll after a kill is covered by `test_accept_after_a_hired_kill_rolls_the_same_dice` (40 seeds, both outcomes). |
| Layout 294x639 + insets (0,45,0,26) | pass | Run 62: column at x 20, paper 254x243 at y 215 (stage bottom 215, Dana fully visible), tip at 462, `< Back` at 535, ACCEPT 168x36 at (106, 577), ending at 613 = 639 - 26. Screenshot checked. Restored. |
| Game log | pass | Runs 61 and 62: 0 errors, 0 warnings except, in 59 and 62, 4 "Content: missing" warnings from opening offer.tscn alone with an empty run (before run 62's reload). Run 61 lines: helper, Content, IVSTART/IVFORCE/IVRESULT. Run 60's lines were no longer retained when read; its project_run reported no errors, and every path it ran (offer, Pause, Decline dialog, Accept, Hired card) ran again cleanly in run 61. Editor: only the known "Identifier not found: GameState/Content" compile lines. |
| Files on disk | pass | Every changed file was compared with a scratch copy after the runs: identical (the editor never wrote a stale buffer back); `offer.tscn` was never opened in the editor. LF line endings. |
| Cleanup | pass | `save_v1.json` and `settings.cfg` (created by these runs; neither existed before) deleted; `user://` holds only godot_ai_server.pid and the engine's folders. Project stopped. |

## You-do queue (W3, unchanged)

- Choose the fine-print jokes you like best (ROADMAP Step 6 You-do).
- Kill the app on your iPhone at the 5 moments and check Continue (device, P2).

## Doc follow-ups for the Doc sync stage (not edited here)

- ARCHITECTURE 7.1: the offer's final shape (adds `commute {id, args}`; `work_mode`, `perks`, `fine_print`, `equity_text` are emails.json ids; `job_title` the posting's raw title); rule methods `make_offer`, `offer_rng`, `offer_commute`, `decline_ends_run`.
- ARCHITECTURE 7.2: the offer's own RNG (seeded from the interview seed + salt), next to the interview and meter RNGs.
- ARCHITECTURE 3: `HuntTips.offer`; `UiText.word_wrap` and `UiText.field` in the UiText list.
- ARCHITECTURE 8 / 17.7: `run_count` is counted in `change_phase()` with the save deletion (not on Accept); `answer_offer` uses `decline_ends_run()`; `finish_interview` calls `make_offer`.
- ARCHITECTURE 11.7: the built screen (Back row, tip rule, Dana's Decline beat, equity field, grace-day confirm); the RichTextLabel is 240 inside the 254 paper.
- ARCHITECTURE 17.2, 17.7 (and the UiText / HuntTips blocks): re-sync with the code.
- CONTENT.md 13.3 lists `fp_salary_review`'s tiers as "all"; the JSON (correctly, ARCHITECTURE 6.3) lists all three.
- `employment` still copies the offer only; the planned `red_flags` (GDD 10.4) is not added yet (the Hired card stage may want it).

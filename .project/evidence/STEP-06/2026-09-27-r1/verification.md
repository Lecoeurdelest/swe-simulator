# STEP-06 verifier stage: adversarial verification and agent playtest of v0.1 (grey-box)

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings. Game runs 79-84.
Scope: ROADMAP Step 6 (all 6 tasks and the Done-when) and the grey-box as a whole.
Companion files: `full_runs.md` (the three full runs), `test_run.json` (the final test run).

## Result

- **No code defect found; no project file changed in this stage.** Tests 225/225 in 21 suites (before and after). 0 crashes. The game logs read (runs 79, 82, 83, 84) hold info lines only, `project_run` reported no errors for every run (80 and 81 included), and the editor error cursor never moved.
- Full runs: Easy, Medium and Hard all reached the Hired card (Medium and Hard after a natural Plan B and RETRY).
- All 5 kill tests resume correctly, a kill on the Hired card resumes at the offer, leaving the Hired card clears the save, and run_count moves once per finished run.
- The intro skips at any moment (early, mid, late hold; Esc) and never auto-plays again; Replay intro works.
- The findings below are for the developer to review (balance, content pairing, one debug trace). None is a code defect.

## Method

- **Real input:** `game_manage input_mouse` (motion, press, release; window px = 2x game px) and `input_key Escape`.
- **Injected input:** for bulk play and for most Back checks, `game_eval` sent taps and Esc presses through `Input.parse_input_event`, so they took the real path: GUI routing, touch emulation, `Device._unhandled_input` -> `Device.handle_back()`. Bulk play used an in-memory driver node, and layout checks used an in-memory probe node. Both were injected with `game_eval` from the scratchpad and never written to the project. The driver's player is described in `full_runs.md`.
- **Reads:** state and hashes were read with `game_eval` (read-only): `FileAccess.get_md5("user://save_v1.json")`, `GameState.rng.state`, the live run. The save on disk after each kill was hashed with PowerShell `Get-FileHash` while the game was stopped.
- **Kill:** `project_manage op=stop` (desktop kill: no pause or close notification, so nothing is saved on the way out). **Resume:** `project_run`, then a real tap on CONTINUE (window 270,836).

## 1. Three full runs (run 79): pass

| Run | Background | End | Days | Applications | Interviews | Offer | Dream |
|---|---|---|---|---|---|---|---|
| 1 | Intern (Easy) | Hired | 6 | 23 | 4 (3 rejected, K.O.) | Entangled Greens $72,000 remote | 71 Pretty good |
| 2a | Graduate (Medium) | Plan B day 14 (grace day on 13) | 14 | 58 | 4 (all rejected) | - | - |
| 2b | Graduate, RETRY | Hired | 11 | 44 | 5 (4 rejected, wheel win) | Stealth Mode Inc. $65,000 remote | 64 Pretty good |
| 3a | Self-Taught (Hard), Education Lie | Plan B day 13 | 13 | 27 | 6 (wheel loss, come clean, BUSTED, 3 rejected) | - | - |
| 3b | Self-Taught, RETRY | Hired | 5 | 12 | 2 (rejected, wheel win) | Lukewarm Express $75,000 hybrid | 52 Doable |

Along the way, each checked against the GDD and CONTENT.md:
- the intro auto-plays only on the first New game;
- the first-run day-2 guarantee;
- the warm-up question;
- the Tired rule;
- the grace day (and "Rent due TOMORROW" / "Rent due today");
- the lie probe, both Come clean and BUSTED, and the blacklist after BUSTED;
- wheel odds;
- salaries, commute lines and tips on three offers;
- Dream rows equal to GDD 5.9.5;
- `hired_extra`;
- both Plan B cards' stats and tips;
- RETRY and NEW RUN preselect the background;
- run_count 0 -> 5, once per finished run.

Details are in `full_runs.md`.

## 2. The 5 kill tests (runs 79 -> 84): pass

The profile was already on run_count 5 (after the full runs). One Intern run covered all five moments.

| # | Moment | Before the kill | Save on disk after the kill | After CONTINUE (real tap) | Result |
|---|---|---|---|---|---|
| 1 | Mid-hunt (79 -> 80) | JOB_HUNT day 1, energy 7. Projects CV line set to Polished on the CV screen and committed by `< Back`. Two Quick Applies (job_st_mobile_barista\|co_quantumleaf, job_big_ai_engineer\|co_nimbus) and a Skip, all driver taps. Board uids [4,5,6,2]; rng 3112237948689050629; md5 b980eafb417c210b1463a71fe16e6471 | identical md5; phase 3, day 1, energy 7, 2 applications, board 4,5,6,2, proj polished, the same rng | the hub on Jobs: same day, energy, applications, board and top card (uid 4), CV and rng. The resume's own save wrote the same bytes (same md5) | pass |
| 2 | Right after Sleep (80 -> 81) | The moon and the confirm ("You still have 7 energy. Sleep anyway?"), driver taps. Night screen "Applied 2 - Rejected 1 - Ghosted 0 - Rent due in 14 days"; day 2, energy 9; morning_report md5 e1be6d30...; rng -2229974341709724509; save md5 f6c5f124f03c67b80aa84ef9c5384cbb | identical md5; phase 3, day 2, the same morning report | the night screen again with the identical summary (screenshot), the same report md5, day, energy, rng and save md5 | pass |
| 3 | Mid-interview (81 -> 82) | The driver played days 2-4, including two referrals (the night showed `tip_referrals` once). Day 4 invite ByteBistro (Mid, rolled) -> GO NOW (energy 9 -> 6). Prompt 1 answered good (Doubt 128 -> 115.5, the Intern's teamwork x1.25). Checkpoint seed 1837216627, ids eq_impossible_deadline, kq_binary_search, kq_failure_story, kq_deadlock, eq_ai_takehome; interviews_today 1; invites 0; rng -3288798299101063023; md5 58b6ece3aa958f98374300ee884bf803 | identical md5; phase 4, the same checkpoint | restarts from the VS intro with the identical IVSTART line (taken=0). Doubt 128 and Composure 100 again, prompt 1 not answered, energy 6 (not charged twice), interviews_today 1, the invite still gone, same rng and md5 | pass |
| 4 | On the offer (82 -> 83) | DBG, then K.O. (real taps). During the K.O. beat `[II]` was hidden and Esc did nothing. Taps -> offer: Lukewarm Express, "Data Analyst to Data Engineer", $92,000 (83.75k x 1.10), hybrid 2 days, 2 x 20 min = 1.3 h, pizza + 20 days PTO, fp_probation. Contract text md5 143b8f413d3ddc8621ba460b544ef002; checkpoint cleared; md5 923389b3619a582a723b5a0803b1828b | identical md5; phase 5, the same offer, empty checkpoint | the same offer and contract text md5, same rng and save md5. ACCEPT and Decline come on after the slide | pass |
| 5 | On the Hired card (83 -> 84) | ACCEPT (real) -> Hired: Dream 66 = 24.53 + 15 + 13.0 + 5 + 8.0 (rent 12/15). The save on disk stayed the OFFER one (md5 923389b3...); settings run_count 5 | identical md5; phase 5, dream_score -1 | the OFFER again with the same contract md5 and rng. ACCEPT (real) -> the same Dream 66 and red flag. Tap -> tally 66; `< Title` (real) -> Title without CONTINUE, save deleted, run_count **5 -> 6 (once)** | pass |

Game logs of runs 82-84: info lines only. Every `project_run` reported no errors. Runs 80 and 81's logs were not read (80's was no longer retained under the id I tried); the editor error cursor stayed at 150 throughout.

## 3. Intro (runs 79, 84): pass

| Check | How | Result |
|---|---|---|
| Auto-plays on the first New game only | Run 79, clean profile: Title tap (real) -> INTRO. Later Title taps (Runs 2a and 3b, the kill-test run, the Plan B setup) -> Background select directly | pass |
| Early hold | intro_seen reset to false (game_eval). Replay intro (real), then a real press on the pill about 1 s later (panel 1, caption 1) | Background select after 0.5 s, intro_seen false -> true |
| Mid hold | Run 79: panel 3, caption 1 while typing, real press | Background select, intro_seen true; the release over CHOOSE did nothing |
| Late hold | Replay intro (real), injected taps to panel 6 caption 4/4 (the title card, screenshot), real press | Background select |
| Short press | Injected press held 181 ms (ring 0.36), then release | no skip, same caption, `_leaving` false |
| Esc | Real Esc on panel 1 | Background select, intro_seen true |
| Replay intro | Title "Replay intro" (real, 3 times) | INTRO from panel 1 each time |
| Taps | Injected taps: each one finishes the caption being typed or shows the next caption, never both | pass |

## 4. Back walk, hit areas and layout (run 84): pass

**Back walk** (12 states; Esc injected via `Input.parse_input_event` unless marked real):

| # | State | Back | Result |
|---|---|---|---|
| 1 | Background select | real Esc -> Title | pass |
| 2 | Title, no save | Esc -> "Quit the game?"; Esc -> closed, still Title | pass |
| 3 | Hub, Jobs | Pause, tree paused; Esc -> resumed, tree running | pass |
| 4 | Hub, card back (a tap flipped it) | -> front | pass |
| 5 | Hub, Sleep confirm | cancelled, still day 1 | pass |
| 6 | Interview, dialogue (DEBUG fake MID invite) | Pause; Esc -> resumed | pass |
| 7 | Interview, K.O. beat | `[II]` hidden; Esc does nothing (no Pause, still INTERVIEW); taps move on to the offer | pass |
| 8 | Offer | Pause; Esc -> resumed, still OFFER | pass |
| 9 | Offer, Decline confirm ("Decline this offer? Rent keeps ticking.") | cancelled; no Pause; still OFFER | pass |
| 10 | Offer, Dana's "No worries! (Our ATS will remember this.)" | Decline committed: the hunt on day 1, Beigeware blacklisted | pass |
| 11 | Hired, beat 1 | -> beat 2; after the tally Esc -> Title (save deleted, run_count 6 -> 7). Also a real Esc in Run 3b | pass |
| 12 | Plan B (DEBUG "Rent runs out") | -> Title (counted 7 -> 8 on entering Plan B, not again) | pass |

**Hit areas at 270x480** (probe: visible buttons with `mouse_filter` not IGNORE; flags under 34 px, gaps under 4 px, outside the game rect):

| Screen | Targets (game px) |
|---|---|
| Background select | dice 34x34; selectors 80x40; `< Title` 80x36; CHOOSE 168x36 |
| Title | Replay intro 86x34 and Device check 86x34, 4 px apart |
| Quit dialog | 80x36 + 168x36 |
| Intro | pill 96x34 |
| Offer | `< Back` 80x36 at y 398; Decline 80x36 + ACCEPT 168x36 at y 440 (6 px gaps) |
| Decline dialog | 80x36 + 168x36 |
| Hired | 80x36 + 168x36 |
| Plan B | 80x36 + 168x36 |

Pause sheet and confirm dialog buttons are 36 px tall (.tscn). No real flag. The one flag (Replay intro next to the quit dialog's Quit, 0 px) is under the dialog's dimmer, so it is not a live neighbour.

**294x639 with fake insets (0,45,0,26)** (fractional KEEP content scale + `SafeAreaMargin.debug_fake_insets`; restored to 270x480 integer EXPAND after each; screenshots checked):

| Screen | Layout |
|---|---|
| Intro | frame 270x480 centred at (12,79); dialogue box 254x72 at y 497-569; pill 96x34 at y 579-613 = 639 - 26 |
| Offer | column x 20; paper 254x231 at y 227 = the stage's bottom (Dana fully visible); tip y 462; `< Back` y 535; Decline/ACCEPT y 577-613 |
| Hired beat 2 | art and sheet at y 45 (254x239); TBC 250-284; buttons y 577-613 |
| Plan B | art y 45; tip 302; stats 382; buttons y 577-613 |

No target under 34 px, no gap under 4 px, nothing outside the game rect.

## 5. Invariants, content lint, tests: pass

| Invariant | Evidence | Result |
|---|---|---|
| INV-01 | `change_phase(` and `.phase =` only in `autoload/game_state.gd` (plus the debug-only `debug_quick_start`) and tests; `test_screens_never_change_phase_or_scene` green | pass |
| INV-02 | `change_scene` only in `scene_router.gd`. Features preload components only; the title loads the debug overlay by path (A1) | pass |
| INV-04 | Gameplay draws only on passed RNGs (Odds, InterviewPlan, the meter RNG, the run RNG, `RunState.offer_rng`). `randi()` only in `GameState.new_run_seed()` (picking a seed). Background select's `_dice` is its own RNG for the cosmetic name dice | pass |
| INV-06 | `SaveIO.write` only in `GameState.save()` (guarded by `GameFlow.is_saved`); `SaveIO.delete` only in `change_phase()`. At runtime: after ACCEPT the disk save stayed the OFFER one (read 4 times: Runs 1, 2b, 3b and kill test 5); entering Plan B (3 times) and leaving the Hired card (5 times) deleted it; Title, Background select and the intro never wrote one | pass |
| INV-07 | A recursive scan of `run.to_dict()` on a live hunt found no StringName, Object, Vector2, Color or Callable, and every key is String or int. `test_long_runs_keep_plain_data_and_their_invariants` green | pass |
| INV-12 | All 21 test files are `@tool` + `extends McpTestSuite`; they read autoload scripts only as text; no `user://` | pass |
| INV-14 | Every Button of offer, intro, phase2_stub and game_over is under `SafeArea` (modals under their own). ScreenTouch/Drag only in `job_card.gd` and `background_card.gd`. The Hired scene's containers are IGNORE. Hit areas above | pass |
| INV-15 | New numbers are UI timings or fixed GDD rules not listed in GDD section 11 (Dream grade bands, 2 perks). The Dream weights, target and penalty come from BalanceConfig. Every player text goes through Content (the .tscn texts are editor placeholders replaced in `_ready`; debug-only English strings excepted) | pass |
| INV-19 | No hard-coded 270/480 in scripts (the intro and Device read Project Settings). Press Start 2P only at 16/24/32 (2x/3x/4x of 8); the stamps drop 2x -> 1x. Text sits on solid panels in every screenshot | pass |

Tests and lint:
- `test_content_lint`: 32/32 green.
- `test_run` (all): 225/225 in 21 suites, at the start and at the end (`test_run.json`).

## Adversarial areas probed (no defect)

- **Double inputs:**
  - The ending buttons' `_leaving` guards.
  - ACCEPT's `_answered` guard.
  - The probe buttons' 250 ms lock (`mouse_filter` IGNORE): early taps ignored, the third tap taken.
  - A hold released over CHOOSE after the scene change.
- **Pause/Back interplay** during the offer slide, the Decline dialog and Dana's line.
- **Esc during ending beats and the Hired tally.**
- **Replay intro with intro_seen already true;** the intro's short press and pill-vs-tap separation.
- **Continue into each saved phase:** OFFER after a Hired kill rolls no new dice and builds the same contract.
- **A re-sent lie probed again** at a company where you came clean.
- **Resolution changes** on the four new screens.
- **Stale buffers:** no project file changed on disk during the stage (checked by modification time).

## Findings for the developer (please review; not fixed, not code defects)

1. **Balance vs GDD 5.12** (for Step 7). The interview and invite formulas match the GDD, but play is much harder than the 5.12 table: 1 K.O. and 4 wheels in 21 interviews, Medium and Hard first runs ending in Plan B, 12-58 applications per run. Research (SHOULD) is not built yet, and the GDD calls it the strongest lever. Details in `full_runs.md`.
2. **Content pairing.** A startup contract can show the perk "Unlimited PTO*" and the fine print "Unlimited PTO*..." together (Run 1). This belongs with the You-do "choose the fine-print jokes you like best".
3. **Dana re-probes a confessed lie** if you send it to the same company again (by the rules; say if it should be excluded).
4. **Debug trace only.** After a startup PIVOT, `IVTRACE` `c=` shows the pre-jump zone centre.
5. **`docs/KILL_TESTS.md` suggestion.** Moment 4 needs a won interview. On a first Intern run that came naturally on day 6, but a harder run may hit Plan B first. The interview's DBG > K.O. (debug builds) gets there quickly, as the robustness and verifier stages did. Not edited here (not a contradiction); a candidate for the Doc sync stage.

## Deviations from the brief (all transparent, none affects a result)

- Bulk play used an injected driver node (taps via `Input.parse_input_event`) instead of one `game_eval` per tap. Most Back checks used injected Esc presses; real Esc was used for Background select, the intro skip and the Hired tally.
- The driver's meter aim tightened from +/-1.3 to +/-0.8 zone half-widths on Run 2a day 8, and it learned to re-aim after a PIVOT on Run 3a day 11. In Run 3a day 11, one needle ran out while I edited the driver between chunks.
- Medium and Hard reached Hired on a RETRY after a natural Plan B (the brief allows this for one run; it happened for two).
- Kill test 4's offer came from the debug panel's K.O. (as in the robustness stage). Kill test 3's interview came from a natural invite.

## Cleanup

- The game is stopped.
- `user://settings.cfg` (created by these runs: intro_seen, last_background, run_count 8) was deleted. No `save_v1.json` or `.tmp` is left; `user://` holds only godot_ai_server.pid and the engine's folders.
- No project file was changed; this stage only wrote this folder's `verification.md`, `full_runs.md` and `test_run.json`.

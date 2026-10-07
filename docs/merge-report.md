# Run Spec v1 merge report

**Status: IN PROGRESS.** Branch `run-spec-v1-merge` (pushed). Don't merge it yet: the GDD points at sections that are still to be written (see "What's left"). Last updated 2026-10-07, after your answers to MC-01 and MC-02 and the Negotiate removal.

Sources: `docs/run-spec-v1.md` (the spec, archived read-only; original sha256 `f64ea13ca5c739cef5ab4a68ae6cad3aefcac03f9856308fb95e2fbd3b5106af`), `docs/swe-simulator-handoff.md` and `docs/swe-simulator-godot-access.md` (both moved from the repo root, A59). `phase2_draft_options.md` wasn't available and wasn't used. No code or asset was changed.

## Start here (next session)

1. `git switch run-spec-v1-merge && git pull`. Godot isn't needed until M1 starts.
2. Read the original brief's rules, which still hold: **documentation only** until the merge is done; fold the spec into the existing docs (no appended file); keep the spec's ids (D-, P-, R-, E-, Q-); never resolve a conflict silently. The precedence rules are DECISIONS W8.
3. Apply the decisions already taken (next section) to everything still to be written.
4. Work through "What's left" in order, committing and pushing on this branch after each item (W1; plain commit messages, no attribution trailer).
5. When the merge is done: finish this report (final file-by-file table), run `python .project/render.py` and the 3 validators (expected warnings: only "STEP-00: decision D4 is not accepted" and "STEP-00: decision D7 is not accepted"), commit, push, and tell the developer the branch is ready for a pull request.
6. **Then M1 starts** (W9): STEP-14 on branch `step-14-sim-core` from this branch (A61), following its bundle `.project/bundles/STEP-14.md` (written in item 7 below).

## Decisions taken on 2026-10-07 (apply them everywhere)

| Id | Decision | Already applied to | Still to apply in |
|---|---|---|---|
| W9 | **M1 (STEP-14, the sim core) starts now**, ahead of Phase 1's open Steps 7-13: the one exception to W2's gate. The rest of MC-01 stays open (below). | DECISIONS; GDD 12; ROADMAP 3 (note); REVIEW_QUEUE (note); project.yaml convention; state.json (STEP-07 detail, ISSUE-11) | ROADMAP 12 (M1 = STEP-14 as the next step); project.yaml STEP-14..19 (STEP-14 `depends_on: []`, ready to start); the STEP-14 bundle; GDD 10.7 |
| D-26 | **Phase 1's KNOWLEDGE, EXPERIENCE and NETWORK stay at the background's starting values and only the duel uses them** (knowledge P, the committee wheel), for now. Study, callbacks and offers don't touch them; EXPERIENCE doesn't grow at work. (Was MC-02.) | DECISIONS; GDD 5.1 (status line, table, growth note), 12; project.yaml | GDD 5.16 (note under the hidden stats), 5.20 (R-JOB-03: "base" values), 13.4; ARCHITECTURE 19.5 (the adapter reads the background's stats unchanged) |
| D-27 | **Offer negotiation is removed** (supersedes D7): no one-tap Negotiate and no R-JOB-04 negotiation. The contract modal is Accept or Decline. | DECISIONS; GDD 0 (status line), 1.4, S10, 5.1, 5.9.3, 5.13, 6, 7, 8.2, 8.3, 10.2-10.4, 10.6, 11.6, 12; ROADMAP Steps 6 and 8, cadence, cut list; CONTENT 8.2, 10.1, 11, 13.1; ARCHITECTURE 7.1, 8, 11.7, 12.2; REVIEW_QUEUE; project.yaml (D7 superseded; SHOULD-02 and AC-S08-2 retired; STEP-06 and STEP-08 point at D-27); state.json | GDD 5.20: R-JOB-04 is "Accept or Decline" (no negotiation chance, no +8%); R-JOB-06's OfferResult is `{decision: accept or decline, final_salary, clauses[]}`; GDD 5.21: the Handbook has **4 Edge tips** (drop "Negotiate every offer"; the spec's "about 15% of total power" shrinks accordingly); GDD 11.7 has no `nego_*` rows; CONTENT 16 has no Negotiate edge; project.yaml's R-JOB-04, R-JOB-06 and R-HB-01 criteria say the same. Code to remove later (not in the merge): `Odds.negotiate_p`, `Odds.negotiated_salary`, BalanceConfig `nego_*`, the offer's `negotiated` flag, `test_offer`'s negotiation test, and the unused strings (`tip_negotiate`, `bark_dana_nego_win/lose`, `ui_negotiate`, `offer_equity_doubled`, `offer_signon`) |
| A60 | New design decisions continue the D- series (D-26 onward), not D13. | DECISIONS | AGENTS.md's decision ranges |
| A61 | STEP-14's branch `step-14-sim-core` starts from `run-spec-v1-merge` (from `main` if the merge PR is merged first). | DECISIONS | ROADMAP 12, the STEP-14 bundle |

## Done

| File | Change |
|---|---|
| `docs/run-spec-v1.md` | the spec, copied in with a 3-line "archived, read-only" header (the body is byte-identical) |
| `docs/DECISIONS.md` | an id-series legend; D-01..D-25; P-01..P-08 (accepted 2026-10-07 by your instruction); Q-01..Q-07 (Q-01/Q-02 answered from the repo, Q-03..Q-07 at the spec's defaults); W8 (the merge and its precedence rules; supersedes P3's "mechanic not chosen"); A52-A59 (merge defaults, please review); W9, D-26, D-27, A60, A61 (2026-10-07 answers) |
| `docs/GDD.md` | v2.0 header and reading guide; section 0 rewritten for the career run, Phase 1's one-pager kept; 1.1-1.4; 2.4-2.6; new 2.11 (office diorama, R-DIO-01..05); 3.1 (career loop diagram, Phase 1's kept), 3.2 (D-06 targets); new 3.3 (run structure, exits, endings) and 3.4 (The Studio, R-WIN-01..08); 4.1, S04, S11, S12 status lines; new 4.5 (career-run flow) and 4.6 (career-run screens); the D-26 and D-27 edits; section 12's "Decisions after the merge" |
| `docs/ROADMAP.md`, `docs/CONTENT.md`, `docs/ARCHITECTURE.md`, `docs/REVIEW_QUEUE.md` | only the D-27 edits and the W9 notes listed above |
| `project.yaml`, `.project/state.json`, `docs/task/README.md`, `.project/generated-manifest.json` | the D-26, D-27 and W9 changes; ISSUE-11 (this merge, open); re-rendered; the 3 validators pass |

## What's left (in this order)

1. **GDD:**
   - the section 5 map and a "Run Spec v1 status" line on 5.0 and 5.2-5.13 (5.1 is done);
   - new 5.14 clock (R-CLK), 5.15 money (R-ECO, R-ECO-05), 5.16 work stats (R-STAT-01..04, R-CB-02), 5.17 controls (R-CTL-01..04), 5.18 archetypes and floor depth (P-01, P-07, R-ARC-02, Pivotly's coworkers), 5.19 events (R-EVT-01..05, the E01-E26 table in ASCII, R-RUN-02, the layoff scene), 5.20 job hunt and adapter (R-JOB-01..06, **with D-27**), 5.21 Scars and Handbook (R-SCAR-01, R-HB-01, **4 Edge tips**), 5.22 harness (R-BAL, R-TEL-01);
   - a status line on 6 and new 6.1 (floor depth); a status line on 7 and new 7.1 (tiers and archetypes); 8.5 (Handbook) and 8.6 (event tips); 9.5 (career-run juice); status lines on 10.1-10.5 and new 10.7 (scope, M1-M6, W9); 11.7 (every spec number with a planned owner, **no nego rows**); at the end of 12, a summary of D-01..D-25 and P-01..P-08 above "Decisions after the merge"; new 13 (O1-O9, A-01..A-05 checked, Q-01..Q-07, 13.4 the duel's real stat names, a risks pointer, an open-conflicts pointer).
2. **CONTENT** v1.2: new section 16 (draft strings: names, the Hours labels, E01-E26 cards with `evt_eNN_*` ids and tip ids, ending lines, the layoff line, the Burnout warnings), plus notes in 1.1, 3, 14 and 15.
3. **ARCHITECTURE** v1.5: new section 19 (sim core, the `WorkConfig` and `ArchetypeData` data files, phases and save, the adapter with the Q-02 names and D-26, the run log, the harness, the diorama, what retires); pointers in 0, 4.1, 6.3, 11.8 and 12; section 17 stays as is (no code changed).
4. **ROADMAP** v1.3: new section 12 (STEP-14..19 = M1-M6, with STEP-14 next per W9); notes on Steps 7-11; the art pipeline (D-21); the playtest gates in 7; the spec's risks as rows 13-19 in 8; the decision ranges in 1.
5. REVIEW_QUEUE (rewrite: section 0 with the open MC items), ideas_parking_lot (the Phase 2 entry is picked up by the Run Spec), a KILL_TESTS note (O8), invariants INV-20 (the art rule) and possibly INV-21..23 (sim purity, no time while closed, one Junior control).
6. **`.agent/AGENTS.md` (= CLAUDE.md):** the precedence rules (W8), the art rule (GDD 2.5, 2.11; D-21, D-25), and the build, run and test commands from `docs/swe-simulator-godot-access.md` (the MCP loop with `autosave=false`, the headless commands and runner, the plan-tracking commands with `python` and `PYTHONIOENCODING=utf-8`); update the decision ranges and the task-id note (STEP-00..19).
7. project.yaml (the R-* requirements with criteria, the D-01..D-25 and P-01..P-08 decisions, STEP-14..19 with their milestones, a BASE-RUNSPEC baseline, the new docs as artifacts, the authority order); state.json (STEP-14..19; STEP-14 ready); bundles (update STEP-07's out-of-scope note, which still says Phase 2 is parked; write STEP-14's); render and validate.
8. Finish this report.

## The duel's real stat names (Q-02, from a read-only look at the code)

- **Composure** (your HP): `_composure` in `features/interview/interview.gd`, starts at `BackgroundData.composure_max` (100/100/90).
- **Doubt** (Dana's HP): `_doubt`, starts at `TierData.doubt_hp` (118/128/132).
- **Answer Meter width:** the NAILED IT half-width h = `Odds.zone_half(cfg, S, bonus)` = 0.06 + 0.12 S/100 (+ `textbook_zone_bonus`), passed to `AnswerMeter.start(cfg, speed, half_width, zone_jumps, relaxed, rng)`. S comes from KNOWLEDGE and EXPERIENCE via `Odds.knowledge_p` and `Odds.stat_score` (unchanged in the career run: D-26).
- Rounds: `BalanceConfig.prompt_pattern` (5). Result: `GameState.finish_interview(won, composure_left)`. Offer: `RunState.make_offer(...)` -> `run.offer`; `GameState.answer_offer(accept)`.
- **Which can be fed in:** none of the three is a parameter today (they're read from `.tres` and the run inside `interview.gd`); only h crosses an interface (`AnswerMeter.start`). A-01 is partly wrong: the adapter needs the interview checkpoint to carry the numbers. Note: scaling h changes only the tap window, not S (75% of Q).

## Conflicts resolved by your precedence rules or your own decisions (applied as the docs are written)

RC-01 the day loop, energy pips, rent countdown, grace day and Tired-from-pips: retired by D-04. RC-02 the duel and the contract modal kept behind the adapter. RC-03 CV tailoring retired (D-05; supersedes D9's Tailor part). RC-04 the Phase 1/Phase 2 framing (TO BE CONTINUED, P3) superseded; code ids like PHASE2_STUB stay. RC-05 earlier work-loop notes superseded (GDD 3.1's WORK line, 5.3, the 6/7 Phase 2 rows, 10.3, 10.4, TierData's meeting_load/layoff_risk/growth_mult, the parking lot, ROADMAP's "Phase 2 pitch"). RC-06 Plan B = savings below 0 for 30 days; the card kept (D-19). RC-07 money in k$ replaces "no cash stat". RC-08 salary from the level x archetype table, not Composure. RC-09 negotiation: first resolved to R-JOB-04's numbers, now **removed altogether by your D-27**. RC-10 pacing from D-06. RC-11 floor depth is the difficulty scalar (P-01). RC-12 run 1 fixed to The Intern (P-06). RC-13 the Phase 1 board model replaced by R-JOB-01/02. RC-14 Study per R-JOB-05. RC-15 the interview's inputs per R-JOB-03. RC-16 Phase 1's morning events replaced by the events system. RC-17 GDD 5.12's sim replaced by the R-BAL harness for the career run. RC-18 "events kept small" superseded by "events are the game". RC-19 pixel-art details follow the art docs (the zoom cuts between whole steps, the flash cap, the hoodie color). RC-20 Godot 4.7.2 and GDScript; the sim runs headless in Godot. RC-21 code conventions: JSON events with `evt_eNN_*` ids (A54), a snake_case adapter (A55), ASCII and American spelling (A57). RC-22 shipped UI conventions: the Hours slider as tappable notches (A58), the speed control in the thumb band, 5-dot odds bands, an on-screen Back. RC-23 existing characters (Dana, Remy, Ducky) kept as written. RC-24 the harness runs outside `test_run` (A56). RC-25 the meter's 0.06 half-width floor clamps Rust's narrowing (an input fact). RC-26 the run log stores inputs and outcomes, not every tick (small saves on iOS). RC-27 "reloaded without a rebuild" holds on desktop and in the harness, not on the phone build. RC-28 new phases are appended (INV-10). RC-29 **your D-21**: no commissioned art, superseding "draw or commission the hero pieces". RC-30 **your D-26**: Phase 1's stats only feed the duel (was MC-02).

## Open conflicts: proposed resolutions waiting for you

| ID | Conflict | Proposed |
|---|---|---|
| MC-01 (rest) | M1 starts now (W9). Still open: what happens to Steps 7-13 meanwhile, and which game `v0.5-mvp` ships | fold Playtest #1 into the M2 gate; replace Step 7's Phase 1 hunt sim with R-BAL (ISSUE-09 goes with it); keep drag-to-sign for M3 and park the hunt SHOULDs (Research, Network, site tabs, commute strip, morning events); the art and release steps after M4; `v0.5-mvp` = the career run |
| MC-03 | What a background changes in the work state | the duel's inputs, starting savings and commute (the Dream score) only |
| MC-04 | Starting savings (not in the spec) | the background's Phase 1 runway days as months of expenses (0.5 / 0.4 / 0.4) |
| MC-05 | Archetypes vs Phase 1 tiers | Startup = `startup`, Agency = `mid`, MegaCorp = `big`; ids unchanged |
| MC-06 | The placeholder company names (Pivotly, Outsourcery, Monolith) | use existing parody companies that fit: Hierarchai, Scope & Creep Digital, OmniGlobal Dynamics; otherwise a C1-style name check |
| MC-07 | Phase 1's hunt satire (ghost jobs, knockouts, the Radar, referrals, Research, the Unicorn) has no place on the new board | keep R-JOB-01/02 for M1-M4; consider ghost and knockout posting flags at M6 |
| MC-08 | What Accept shows now that the Hired card isn't an ending | keep the HIRED! stamp as a short beat; drop `end_tbc` |
| MC-09 | The career-long Dream vs Reality formula and `dream_reality_delta` | keep the 5 rows, rebased (runway months, clauses), scored per job |
| MC-10 | The salary scale (a Junior earns $29-45k a year vs Phase 1's $50-125k; Remy's $150k) and its display | the contract shows the yearly figure; rebase the Dream target |
| MC-11 | The intro ends on "How did you spend those four years?" but run 1 skips Background select | a new last caption that hands over to day 0 |
| MC-12 | Tired has no source without energy pips | retire it (Burnout already lowers Composure) |
| MC-13 | Commute has no daily rule (only E08's +0.3) | none in M1; the Dream score only |
| MC-14 | Work modes and office days for non-remote postings | Remote or not; Phase 1's office days per tier |
| MC-15 | Telemetry (R-TEL-01) vs a game that is offline and collects nothing | a local run log and a debug report only |
| MC-16 | Paid asset packs vs "no art budget" (D-21) | free/CC0 packs only unless you OK one |
| MC-17 | The plain-language rule (C3) for event cards and tips; tip overlaps (E15 ~ `tip_secrets`, E26 ~ `tip_blameless`) | apply C3 at the M6 writing pass; reuse the two existing tips |
| MC-18 | The Handbook vs the Career Notebook; which tips count (24 event tips vs Phase 1's 31) | the Handbook is the Notebook grown up; every tip that fires is collected, Phase 1's as Lore |
| MC-19 | Decline blacklists the company (the spec is silent) | keep |
| MC-20 | Copy that names retired mechanics ("decide before you sleep", "rent days to spare", "Rent's due.") | reword at M3 |
| MC-21 | **New with D-27:** does E04's lease negotiation (a rent event's choice: "Negotiate (tip): 30% chance of +5% instead", with the Option tip "Landlords negotiate too") go too? | keep it: it's an event choice about rent, not the offer's Negotiate. Remove it if "the Negotiation aspect" meant every negotiation |

**Spec gaps to settle at their milestone:** forced leave's length, pay and job (M4); `e_handbook` in the callback formula has no v1 edge (1.0); the review duel's prompt kinds and 12-prompt pool (M3); the hidden-clause list (M3); the manager portrait and the walk cycle missing from the asset list (M5); the "war_room" focus location (M5). Clarified while merging: home recovery is r = 0.10 / 0.25 / 0.35, subtracted (the spec's table shows the minus sign); "~10 scheduled events a year" counts events with choices; the Studio hold is shown as the Filming bar. (The gap about the negotiation cap went away with D-27.)

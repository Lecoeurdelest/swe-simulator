# Run Spec v1 merge report

**Status: IN PROGRESS (stopped at a usage limit, 2026-10-07).** Branch `run-spec-v1-merge`. Don't merge it yet: the GDD now points at sections that are still to be written (see "What's left").

Sources: `docs/run-spec-v1.md` (the spec, archived read-only; original sha256 `f64ea13ca5c739cef5ab4a68ae6cad3aefcac03f9856308fb95e2fbd3b5106af`), `docs/swe-simulator-handoff.md`, `docs/swe-simulator-godot-access.md` (both moved from the repo root, A59). `phase2_draft_options.md` wasn't available and wasn't used. No code or asset was changed.

## Done

| File | Change |
|---|---|
| `docs/run-spec-v1.md` | the spec, copied in with a 3-line "archived, read-only" header (the body is byte-identical) |
| `docs/DECISIONS.md` | an id-series legend; rows D-01..D-25, P-01..P-08 (accepted 2026-10-07 by your instruction), Q-01..Q-07 (Q-01/Q-02 answered from the repo, Q-03..Q-07 at the spec's defaults), W8 (the merge and its precedence rules; supersedes P3's "mechanic not chosen"), A52-A59 (merge agent defaults, please review) |
| `docs/GDD.md` | v2.0 header and reading guide (precedence rules, id series); section 0 rewritten for the career run, with Phase 1's one-pager kept; 1.1, 1.2, 1.3, 1.4 (new lessons table); 2.4, 2.5 (D-21: no commissioning), 2.6, new 2.11 (office diorama, R-DIO-01..05); 3.1 (career loop diagram, Phase 1 diagram kept), 3.2 (D-06 targets), new 3.3 (run structure, exits, endings), new 3.4 (The Studio, R-WIN-01..08); 4.1, S04, S11, S12 status lines; new 4.5 (career-run flow) and 4.6 (career-run screens) |

## What's left (next session)

1. **GDD:** the section 5 map and "Run Spec v1 status" lines on 5.0-5.13; new 5.14 clock (R-CLK), 5.15 money (R-ECO, R-ECO-05), 5.16 work stats (R-STAT-01..04, R-CB-02), 5.17 controls (R-CTL-01..04), 5.18 archetypes and floor depth (P-01, P-07, R-ARC-02, Pivotly's coworkers), 5.19 events (R-EVT-01..05, the E01-E26 table in ASCII, R-RUN-02, the layoff scene), 5.20 job hunt and adapter (R-JOB-01..06), 5.21 Scars and Handbook (R-SCAR-01, R-HB-01), 5.22 harness (R-BAL, R-TEL-01); 6 status + 6.1 floor depth; 7 status + 7.1 tier/archetype mapping; 8.5 Handbook, 8.6 event tips; 9.5 career-run juice; 10.1-10.6 status lines, new 10.7 (scope, M1-M6); 11.7 (every spec number with a planned owner); 12 (status on D3, D5, D7, D8, D9 + a Run Spec decisions summary); new 13 (O1-O9, A-01..A-05 checked, Q-01..Q-07, 13.4 the duel's real stat names, risks pointer, open conflicts pointer).
2. **CONTENT 16** (draft strings: names, Hours labels, E01-E26 cards with `evt_eNN_*` ids and tip ids, ending lines, layoff line, warnings), plus notes in 1.1, 3, 14, 15.
3. **ARCHITECTURE** v1.5: new section 19 (sim core, data files `WorkConfig`/`ArchetypeData`, phases and save, the adapter with Q-02 names, run log, harness, diorama, what retires); pointers in 0, 4.1, 6.3, 11.8, 12.
4. **ROADMAP** v1.3: new section 12 (STEP-14..19 = M1-M6), notes on Steps 7-11, art pipeline (D-21), playtest gates in 7, spec risks as rows 13-19 in 8.
5. REVIEW_QUEUE (new section 0), ideas_parking_lot (Phase 2 entry picked up), KILL_TESTS note, invariants INV-20 (art rule) and maybe INV-21..23.
6. **`.agent/AGENTS.md` (CLAUDE.md):** the precedence rules, the art rule, and the build/run/test commands from the Godot access doc.
7. project.yaml (R-* requirements, D-/P- decisions, STEP-14..19, baseline), state.json, bundles (STEP-07 update, STEP-14 new); `python .project/render.py` and the 3 validators.
8. Finish this report, then commit and push.

## The duel's real stat names (Q-02, from a read-only look at the code)

- **Composure** (your HP): `_composure` in `features/interview/interview.gd`, starts at `BackgroundData.composure_max` (100/100/90).
- **Doubt** (Dana's HP): `_doubt`, starts at `TierData.doubt_hp` (118/128/132).
- **Answer Meter width:** the NAILED IT half-width h = `Odds.zone_half(cfg, S, bonus)` = 0.06 + 0.12 S/100 (+ `textbook_zone_bonus`), passed to `AnswerMeter.start(cfg, speed, half_width, zone_jumps, relaxed, rng)`. S comes from KNOWLEDGE/EXPERIENCE via `Odds.knowledge_p` and `Odds.stat_score`.
- Rounds: `BalanceConfig.prompt_pattern` (5). Result: `GameState.finish_interview(won, composure_left)`. Offer: `RunState.make_offer(...)` -> `run.offer`; `GameState.answer_offer(accept)`; Negotiate isn't built.
- **Which can be fed in:** none of the three is a parameter today (read from `.tres` and the run inside `interview.gd`); only h crosses an interface (`AnswerMeter.start`). A-01 is partly wrong: the adapter needs the checkpoint to carry the numbers. Note: scaling h changes only the tap window, not S (75% of Q).

## Conflicts resolved by your precedence rules or your own decisions (applied as the docs are written)

RC-01 day loop, energy pips, rent countdown, grace day, Tired-from-pips: retired by D-04. RC-02 duel and contract modal kept behind the adapter. RC-03 CV tailoring retired (D-05; supersedes D9's Tailor part). RC-04 the Phase 1/Phase 2 framing (TO BE CONTINUED, P3) superseded; code ids like PHASE2_STUB stay. RC-05 earlier work-loop notes superseded (GDD 3.1 WORK line, 5.3, 6/7 Phase 2 rows, 10.3, 10.4, TierData meeting_load/layoff_risk/growth_mult, parking lot, ROADMAP "Phase 2 pitch"). RC-06 Plan B = savings below 0 for 30 days; the card kept (D-19). RC-07 money in k$ replaces "no cash stat". RC-08 salary from the level x archetype table, not Composure. RC-09 Negotiate numbers from R-JOB-04; D7's one tap, once, never rescinded kept. RC-10 pacing from D-06. RC-11 floor depth is the difficulty scalar (P-01). RC-12 run 1 fixed to the Intern (P-06). RC-13 the Phase 1 board model replaced by R-JOB-01/02. RC-14 Study per R-JOB-05. RC-15 interview inputs per R-JOB-03. RC-16 Phase 1 morning events replaced by the events system. RC-17 GDD 5.12 sim replaced by the R-BAL harness for the career run. RC-18 "events kept small" superseded by "events are the game". RC-19 pixel-art details follow the art docs (zoom cuts between whole steps, flash cap, hoodie color). RC-20 Godot 4.7.2 + GDScript; the sim runs headless in Godot. RC-21 code conventions: JSON events with `evt_eNN_*` ids (A54), snake_case adapter (A55), ASCII + American spelling (A57). RC-22 shipped UI conventions: Hours slider as tappable notches (A58), speed control in the thumb band, 5-dot odds bands, on-screen Back. RC-23 existing characters (Dana, Remy, Ducky) kept as written. RC-24 harness outside `test_run` (A56). RC-25 the meter's 0.06 half-width floor clamps Rust's narrowing (engine/input fact). RC-26 the run log stores inputs and outcomes, not every tick (small saves on iOS). RC-27 "reloaded without a rebuild" holds on desktop and in the harness, not on the phone build. RC-28 new phases appended (INV-10). RC-29 **your D-21**: no commissioned art, superseding "draw or commission the hero pieces".

## Open conflicts: proposed resolutions waiting for you

| ID | Conflict | Proposed |
|---|---|---|
| MC-01 | Where M1-M6 sit against Steps 7-13; whether the Phase 1 MVP (v0.5-mvp) ships first; W2's gate | start M1 next; fold Playtest #1 into the M2 gate; replace Step 7's hunt sim with R-BAL; keep Negotiate and drag-to-sign for M3, park the hunt SHOULDs; art and release steps after M4 |
| MC-02 | KNOWLEDGE / EXPERIENCE / NETWORK in the career run | fixed per background, used only inside the duel |
| MC-03 | What a background changes in the work state | duel inputs, starting savings, commute (Dream score) only |
| MC-04 | Starting savings (not in the spec) | the background's Phase 1 runway days as months of expenses (0.5 / 0.4 / 0.4) |
| MC-05 | Archetypes vs Phase 1 tiers | Startup = `startup`, Agency = `mid`, MegaCorp = `big`; ids unchanged |
| MC-06 | Placeholder company names (Pivotly, Outsourcery, Monolith) | use existing parody companies that fit: Hierarchai, Scope & Creep Digital, OmniGlobal Dynamics; else a C1-style name check |
| MC-07 | Phase 1 hunt satire (ghost jobs, knockouts, Radar, referrals, Research, Unicorn) has no place on the new board | keep R-JOB-01/02 for M1-M4; consider ghost/knockout posting flags at M6 |
| MC-08 | What Accept shows now that the Hired card isn't an ending | keep the HIRED! stamp as a short beat; drop `end_tbc` |
| MC-09 | The career-long Dream vs Reality formula and `dream_reality_delta` | keep the 5 rows, rebased (runway months, clauses), scored per job |
| MC-10 | Salary scale (a Junior earns $29-45k a year vs Phase 1's $50-125k; Remy's $150k) and display | contract shows the yearly figure; rebase the Dream target |
| MC-11 | The intro ends on "How did you spend those four years?" but run 1 skips Background select | a new last caption handing over to day 0 |
| MC-12 | Tired has no source without pips | retire it (Burnout already lowers Composure) |
| MC-13 | Commute has no daily rule (only E08's +0.3) | none in M1; Dream score only |
| MC-14 | Work modes and office days for non-remote postings | Remote or not; Phase 1 office days per tier |
| MC-15 | Telemetry (R-TEL-01) vs an offline game that collects nothing | local run log and a debug report only |
| MC-16 | Paid asset packs vs "no art budget" | free/CC0 packs only unless you OK one |
| MC-17 | Plain-language rule (C3) for event cards and tips; tip overlaps (E15 ~ `tip_secrets`, E26 ~ `tip_blameless`) | apply C3 at the M6 writing pass; reuse the two existing tips |
| MC-18 | Handbook vs the Career Notebook; which tips count (24 event tips vs Phase 1's 31) | the Handbook is the Notebook grown up; all tips collected, old ones as Lore |
| MC-19 | Decline blacklists the company (spec silent) | keep |
| MC-20 | Copy naming retired mechanics ("decide before you sleep", "rent days to spare", "Rent's due.") | reword at M3 |

**Spec gaps to settle at their milestone:** forced leave's length, pay and job (M4); `e_handbook` in the callback formula has no v1 edge (1.0); the review duel's prompt kinds and 12-prompt pool (M3); the negotiation cap with the +5% edge (M4); the hidden clause list (M3); the manager portrait and walk cycle missing from the asset list (M5); the "war_room" focus location (M5). Clarified while merging: home recovery is r = 0.10 / 0.25 / 0.35 subtracted (the spec's table shows the minus sign); "~10 scheduled events a year" counts events with choices; the Studio hold is shown as the Filming bar.

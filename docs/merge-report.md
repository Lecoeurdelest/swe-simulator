# Run Spec v1 merge report

**Status: DONE (the documentation merge), 2026-10-07.** Branch `run-spec-v1-merge` is pushed and ready for a pull request: https://github.com/Lecoeurdelest/swe-simulator/pull/new/run-spec-v1-merge. The Run Spec is folded into the existing docs and their sections, keeping its ids; every conflict is either resolved by your precedence rules or decisions (RC-01..RC-35) or waiting for you with a proposed resolution (MC-nn); every rule the spec leaves undefined is listed as a spec gap with a proposed default. **No code, scene, `.tres`, JSON or asset file changed.** What's still yours is listed at the end ("Your open questions") and in `docs/REVIEW_QUEUE.md` section 0.

Sources: `docs/run-spec-v1.md` (the spec, archived read-only; its body is byte-identical to the original, sha256 `f64ea13ca5c739cef5ab4a68ae6cad3aefcac03f9856308fb95e2fbd3b5106af`), `docs/swe-simulator-handoff.md` and `docs/swe-simulator-godot-access.md` (both moved from the repo root, A59). `phase2_draft_options.md` wasn't available and wasn't used. Precedence: DECISIONS W8.

## Start here (the next session)

1. `git switch run-spec-v1-merge && git pull` (or `git switch main && git pull` once you've merged the pull request).
2. **M1 (STEP-14), the career run's sim core, is next** (W9): branch `step-14-sim-core` from this branch, or from `main` after the merge (A61), and follow `.project/bundles/STEP-14.md`. M1 runs headless (the commands are in `.agent/AGENTS.md`).
3. M1's huddle settles the M1 spec gaps below and MC-04, MC-05, MC-22 and MC-23. If you're away, Claude takes the proposed defaults and logs them as agent defaults (W4); scope, tone and tips wait for you.
4. D-27's negotiation code goes with M1, the next code change (ROADMAP 12, Step 14 task 6).

## The decisions of 2026-10-07, and where they were applied

| Id | Decision | Applied in |
|---|---|---|
| W8 | The Run Spec is merged with precedence rules: the original docs win on pixel-art style, engine and language, code conventions, shipped UI conventions and existing characters; the Run Spec wins on game design and supersedes earlier work-loop notes | every doc; GDD's reading guide; `.agent/AGENTS.md`; `project.yaml`'s authority order |
| W9 | **M1 (STEP-14, the sim core) starts now**, ahead of Phase 1's open Steps 7-13: the one exception to W2's gate. The rest of MC-01 stays open | DECISIONS; GDD 10.5, 10.7, 12; ROADMAP 3, 12; REVIEW_QUEUE; `project.yaml` (convention, STEP-14 `depends_on: []`); `state.json` (STEP-14 ready); the STEP-14 bundle |
| D-26 | **Phase 1's KNOWLEDGE, EXPERIENCE and NETWORK stay at the background's starting values, and only the duel uses them** (was MC-02) | GDD 5.1, 5.8, 5.16, 5.20 ("base" values), 12, 13.4; ARCHITECTURE 19.5; `project.yaml` |
| D-27 | **Offer negotiation is removed** (supersedes D7): the contract modal is Accept or Decline | GDD 0, 1.4, S10, 5.1, 5.9, 5.13, 5.20 (R-JOB-04, the OfferResult), 5.21 (4 Edge tips), 6, 7, 8, 10, 11.6, 11.7 (no `nego_*` rows), 12; CONTENT 8.2, 10.1, 11, 13.1, 16.7; ARCHITECTURE 7.1, 8, 11.7, 12.2, 19.5, 19.9; ROADMAP Steps 6, 8 and 14 (the code cleanup); `project.yaml` (D7 superseded; SHOULD-02 and AC-S08-2 retired) |
| D-28 | **E04's lease negotiation is removed too** (was MC-21): accept the +10% or move down a tier; E04 has no tip | GDD 5.15, 5.19 (E04's row), 5.21 (23 tips, no E04 Option example), 8.6, 11.7, 12; CONTENT 16.3-16.4; the parking lot (a rent tip at M6); `project.yaml` |
| A60 | New design decisions continue the D- series (D-29 is next) | DECISIONS; `.agent/AGENTS.md` |
| A61 | STEP-14's branch `step-14-sim-core` starts from `run-spec-v1-merge` (from `main` if the merge is merged first) | ROADMAP 12; the STEP-14 bundle; `project.yaml` |

## What changed, file by file (both sessions)

| File | Changes |
|---|---|
| `docs/run-spec-v1.md` | new: the spec, archived read-only (a header above the byte-identical body); untouched since |
| `docs/swe-simulator-handoff.md`, `docs/swe-simulator-godot-access.md` | moved from the repo root, unchanged (A59) |
| `docs/DECISIONS.md` | the id-series legend; D-01..D-25; P-01..P-08 (accepted); Q-01..Q-07; W8; A52-A59; W9; D-26; D-27 (supersedes D7); D-28; A60; A61 |
| `docs/GDD.md` (2.0) | First session: the header and reading guide; section 0 for the career run (Phase 1's one-pager kept); 1.1-1.4; 2.4-2.6; new 2.11 (the diorama); 3.1-3.2; new 3.3 (run structure, exits, endings) and 3.4 (The Studio); status lines on 4.1, S04, S11, S12; new 4.5-4.6; 5.1; "Decisions after the merge" in 12. Second session: the section 5 map; status lines on 5.0, 5.2-5.13, 6, 7, 10.1-10.5, S03, S10 and 4.3; new 5.14 (the clock), 5.15 (money), 5.16 (work stats and the review), 5.17 (controls), 5.18 (archetypes, floor depth, Pivotly's coworkers), 5.19 (events, E01-E26, the resizing chain, the layoff scene), 5.20 (the job hunt and the adapter), 5.21 (Scars and the Handbook), 5.22 (the harness, telemetry); new 6.1, 7.1, 8.5, 8.6, 9.5, 10.7, 11.7; the D-01..D-25 / P-01..P-08 summary in 12; new 13 (O1-O9, A-01..A-05 checked, Q-01..Q-07, the duel's real stat names, the risk and open-conflict pointers) |
| `docs/CONTENT.md` (1.2) | First session: the D-27 notes (8.2, 10.1, 11, 13.1). Second session: new section 16 (draft strings: names, the work state's UI and Hours labels, the E01-E26 cards with `evt_eNN_*` ids and proposed exhausted choices, the 23 tips, the endings, the layoff scene and Dana's new lines, what happens to Phase 1's strings); notes in 1.1, 3, 14 and 15 |
| `docs/ARCHITECTURE.md` (1.5) | First session: the D-27 notes (7.1, 8, 11.7, 12.2). Second session: new section 19, planned and not built (the shape, the sim core, the data files with the E12 example as JSON, phases and save, the adapter, the run log and the harness, the UI, the diorama, what retires, the planned tests); pointers in 0, 4.1, 6.3, 11.8 and 12.4. Section 17 unchanged |
| `docs/ROADMAP.md` (1.3) | First session: D-27 in Steps 6 and 8 and the cut list; the W9 note in 3. Second session: new section 12 (STEP-14..19 = M1-M6, with branches, estimates, tasks, huddles, Done-when, pitfalls); status notes on 2, 3 and Steps 7-11; the art pipeline without commissioning (D-21); the career run's playtest gates and rows in 7; the spec's risks as rows 13-19 in 8; the decision ranges in 1; notes in 10 and 11 |
| `docs/REVIEW_QUEUE.md` | rewritten: section 0 (the merge: the pull request, the open MC items, the decisions to skim, what only you can set, M1's spec gaps), then what still waits from the Step 7 review |
| `docs/ideas_parking_lot.md` | the Phase 2 entry marked picked up by the Run Spec, with where each idea went; new entries: a rent tip for E04 (D-28), a CI job (RC-32) |
| `docs/KILL_TESTS.md` | the career run's planned kill moments 6-11 (O8) |
| `docs/merge-report.md` | this report |
| `.agent/AGENTS.md` (= `.claude/CLAUDE.md`) | the career run in the intro and M1 as the next step; the W8 precedence and id rules; the art rule (INV-20) and the string rule (A57); the build, run and test commands from the access doc (the MCP loop with `autosave=false`, the headless commands and runner, the harness, the plan-tracking commands with `python` and `PYTHONIOENCODING=utf-8`); the decision ranges; the task ids STEP-00..19 |
| `.agent/rules/invariants.md` | INV-20, the art rule. INV-21..23 are proposed to you, not added |
| `project.yaml` | First session: D-26, D-27 (D7 superseded; SHOULD-02 and AC-S08-2 retired), D-28, the W9 convention. Second session: the 44 R-* requirements with criteria (the milestones' Done-when items are AC-S14..AC-S19), REQ-CAREER-FLOW and REQ-CAREER-GATES, D-01..D-25, P-01..P-08, Q-01..Q-07 and AD-14, INV-20, the career run's planned components, BASE-RUNSPEC and BASE-DOCS-RUNSPEC, the new docs as artifacts, the W8 rule in the authority order, and the tasks STEP-14..STEP-19 |
| `.project/state.json` | ISSUE-11 (open until you merge and answer the MC items); STEP-07's and STEP-08's notes; STEP-14 `ready` with its criteria; STEP-15..19 `todo` |
| `.project/bundles/STEP-07.md`, `.project/bundles/STEP-14.md` | STEP-07's out-of-scope note (no longer "Phase 2 is parked"); the new STEP-14 bundle |
| `docs/task/README.md`, `.project/generated-manifest.json` | re-rendered |

Checked at the end: `python .project/render.py` and the three validators pass (the only warnings are the expected "STEP-00: decision D4 is not accepted." and "... D7 is not accepted."); every line added in this session is ASCII; nothing outside `docs/`, `.agent/`, `.project/` and `project.yaml` changed on the branch.

## Where each part of the spec went

| Run Spec v1 section | Merged into |
|---|---|
| 1 Summary | GDD 0, 1.1 |
| 2 Decision log (D-01..D-25, P-01..P-08) | DECISIONS; GDD 12 |
| 3 Run structure | GDD 3.1, 3.3, 4.5 |
| 4 Win condition: The Studio | GDD 3.4 |
| 5 Clock and economy | GDD 5.14, 5.15, 11.7 |
| 6 Stats | GDD 5.16 |
| 7 Controls and promotion | GDD 5.17 |
| 8 Company archetypes | GDD 5.18, 6.1, 7.1; CONTENT 16.1 |
| 9 Events | GDD 5.19, 8.6; CONTENT 16.3; ARCHITECTURE 19.3 |
| 10 Job hunt | GDD 5.20; ARCHITECTURE 19.5 |
| 11 Scars and the Handbook | GDD 5.21, 8.5; CONTENT 16.4 |
| 12 Office diorama | GDD 2.4-2.6, 2.11, 9.5; ARCHITECTURE 19.8; INV-20 |
| 13 Realization plan | GDD 5.22, 10.7; ARCHITECTURE 19; ROADMAP 7, 12 |
| 14 Traceability | GDD 13.1; `project.yaml` |
| 15 Assumptions, risks, open questions | GDD 13.2-13.5; ROADMAP 8 (rows 13-19); DECISIONS Q-01..Q-07 |

## The duel's real stat names (Q-02, from a read-only look at the code)

Also in GDD 13.4; the adapter's plan is ARCHITECTURE 19.5.

- **Composure** (your HP): `_composure` in `features/interview/interview.gd`, starts at `BackgroundData.composure_max` (100/100/90).
- **Doubt** (Dana's HP): `_doubt`, starts at `TierData.doubt_hp` (118/128/132).
- **Answer Meter width:** the NAILED IT half-width h = `Odds.zone_half(cfg, S, bonus)` = 0.06 + 0.12 S/100 (+ `textbook_zone_bonus`), passed to `AnswerMeter.start(cfg, speed, half_width, zone_jumps, relaxed, rng)`. S comes from KNOWLEDGE and EXPERIENCE via `Odds.knowledge_p` and `Odds.stat_score` (unchanged in the career run: D-26).
- Rounds: `BalanceConfig.prompt_pattern` (5). Result: `GameState.finish_interview(won, composure_left)`. Offer: `RunState.make_offer(...)` -> `run.offer`; `GameState.answer_offer(accept)`.
- **Which can be fed in:** none of the three is a parameter today (they're read from `.tres` and the run inside `interview.gd`); only h crosses an interface (`AnswerMeter.start`). A-01 is partly wrong: the adapter needs the interview checkpoint to carry the numbers. Scaling h changes only the tap window, not S (75% of Q).

## Conflicts resolved by your precedence rules or your own decisions (RC-01..RC-35)

| ID | Conflict | Resolved by | Resolution, and where |
|---|---|---|---|
| RC-01 | Phase 1's day loop, energy pips, rent countdown, grace day and Tired-from-pips vs the one macro clock | D-04 (design wins) | retired when the career run is built (GDD 5.3, 5.10, 5.14) |
| RC-02 | The shipped duel and contract modal vs the new systems | W8 (the retirements are intended; the duel stays) | kept behind the adapter (R-JOB-06; GDD 5.20; ARCHITECTURE 19.5) |
| RC-03 | Tailor & Apply (D9 kept it) vs no CV | D-05 | CV tailoring retired (GDD 5.4) |
| RC-04 | The Phase 1/Phase 2 framing (TO BE CONTINUED, P3) | W8 | superseded; code ids like `PHASE2_STUB` stay (code conventions) |
| RC-05 | Earlier work-loop notes (GDD 3.1's WORK line, 5.3, 6's and 7's Phase 2 rows, 10.3, 10.4, TierData's unused fields, the parking lot, ROADMAP's "Phase 2 pitch") | W8 (the spec supersedes them) | superseded, each marked where it sits |
| RC-06 | Plan B when rent runs out vs the runway loss | D-19, design | savings below zero for 30 days; the card kept (GDD 5.10, 3.3) |
| RC-07 | "No cash stat" (GDD 5.1) | design | money in k$ (GDD 5.15) |
| RC-08 | Salary from Composure (GDD 5.9.2) | design | the level x archetype table and floor depth (GDD 5.15) |
| RC-09 | Phase 1's Negotiate vs R-JOB-04's | first design, then **your D-27** | all negotiation removed |
| RC-10 | Phase 1's pacing targets | D-06 | the career run's targets (GDD 3.2) |
| RC-11 | Background as the difficulty vs floor depth | P-01 | floor depth is the scalar (GDD 5.18, 6.1) |
| RC-12 | Background select on every run vs run 1 | P-06 | run 1 is The Intern (GDD 5.2) |
| RC-13 | Phase 1's board model | R-JOB-01/02 | replaced by the DoomApply board (GDD 5.6, 5.20) |
| RC-14 | Study as KNOWLEDGE +5 | R-JOB-05 | Skill +1, Rust -20 (GDD 5.20) |
| RC-15 | The interview's inputs from the `.tres` | R-JOB-03 | fed from the work state (GDD 5.20) |
| RC-16 | Phase 1's morning events | design | replaced by the events system (GDD 5.19) |
| RC-17 | GDD 5.12's simulation | design | the R-BAL harness for the career run (GDD 5.22) |
| RC-18 | "Events kept small" (the parking lot) | design | events are the game (GDD 5.19) |
| RC-19 | The spec's pixel-art details (smooth zoom, flashing, the player's look) | W8 (art docs win) | zoom cuts between whole steps, the 3-flashes-per-second cap, the hoodie color (GDD 2.11) |
| RC-20 | "Godot engine", language unstated | W8 (engine wins) | Godot 4.7.2 and GDScript; the sim runs headless in Godot (Q-01) |
| RC-21 | YAML events, camelCase fields, the spec's typography | W8 (code conventions win) | JSON events with `evt_eNN_*` ids (A54), a snake_case adapter (A55), ASCII and American spelling (A57) |
| RC-22 | A drag slider and the spec's layout | W8 (shipped UI conventions win) | the Hours slider as tappable notches (A58), the speed control in the thumb band, 5-dot odds bands, an on-screen Back |
| RC-23 | The spec's cast vs existing characters | W8 (existing characters win) | Dana, Remy and Ducky kept as written (GDD 1.3, 5.18) |
| RC-24 | The harness in `test_run` | W8 (tooling facts) | it runs headless outside `test_run` (A56) |
| RC-25 | Rust narrowing the meter without limit | an engine and code fact | the meter's 0.06 half-width floor clamps it (GDD 5.20) |
| RC-26 | A run log of every tick | engine facts (small saves on iOS) | inputs and outcomes only (ARCHITECTURE 19.6) |
| RC-27 | "Reloaded without a rebuild" | engine facts | holds on desktop and in the harness, not on the phone build |
| RC-28 | New phases | INV-10 | appended to `GameFlow.Phase` (ARCHITECTURE 19.4) |
| RC-29 | "Draw or commission the hero pieces" | **your D-21** | no commissioned art (GDD 2.5; ROADMAP 5; INV-20) |
| RC-30 | Phase 1's stats in the career run (was MC-02) | **your D-26** | they only feed the duel |
| RC-31 | E04's lease negotiation (was MC-21) | **your D-28** | removed; E04 has no tip |
| RC-32 | The spec's "CI" vs a repo with none | W8 (tooling facts) | the harness and the content lint run with the headless runner before every tuning commit (GDD 5.22) |
| RC-33 | A run-ending choice (quit or accept another offer during job 5) vs "one mis-tap never wipes the run" | W8 (shipped UI conventions) | it asks for a confirm that says so, like the grace-day Decline (GDD 5.10; CONTENT 16.2) |
| RC-34 | The layoff scene "skippable after the first time" vs an on-screen Back everywhere and no auto-advance | W8 (shipped UI conventions: GDD 4.4, D12, A19) | taps advance its beats, Back opens Pause, a hold-to-skip pill from the second viewing (GDD 5.19) |
| RC-35 | Saving at every event and on backgrounding vs saving after every committed action | W8 (code conventions) | both: every event, every input, entering a live phase, pause, focus out and close (GDD 5.11, 5.14; ARCHITECTURE 19.4) |

## Open conflicts: proposed resolutions waiting for you

The docs mark each one **Open (MC-nn)** where it matters. MC-02 and MC-21 are answered (D-26, D-28).

| ID | Conflict | Proposed |
|---|---|---|
| MC-01 (rest) | M1 starts now (W9). Still open: what happens to Steps 7-13 meanwhile, and which game `v0.5-mvp` ships | fold Playtest #1 into the M2 gate; replace Step 7's Phase 1 hunt sim with R-BAL (ISSUE-09 goes with it); keep drag-to-sign for M3 and park the hunt SHOULDs (Research, Network, site tabs, commute strip, morning events); the art and release steps after M4; `v0.5-mvp` = the career run |
| MC-03 | What a background changes in the work state | the duel's inputs, starting savings and commute (the Dream score) only |
| MC-04 | Starting savings (not in the spec) | the background's Phase 1 runway days as months of expenses (0.5 / 0.4 / 0.4). A caution found while merging: the first rent and living costs (2.1 k$ in the Shared room) fall due on day 1, so a run that starts between jobs with 0.84 k$ is below zero at once and reaches Plan B around day 31 unless a first salary lands; run 1 (employed) dips for 24 days and recovers on day 25. Let the M1 harness compare a few starting amounts before you pick |
| MC-05 | Archetypes vs Phase 1 tiers | Startup = `startup`, Agency = `mid`, MegaCorp = `big`; ids unchanged. Note: only one of the three mid-size companies, Scope & Creep Digital, is an agency (GDD 7.1) |
| MC-06 | The placeholder company names (Pivotly, Outsourcery, Monolith) | use existing parody companies that fit: Hierarchai, Scope & Creep Digital, OmniGlobal Dynamics; otherwise a C1-style name check |
| MC-07 | Phase 1's hunt satire (ghost jobs, knockouts, the Radar, referrals, Research, the Unicorn) has no place on the new board | keep R-JOB-01/02 for M1-M4; consider ghost and knockout posting flags at M6 |
| MC-08 | What Accept shows now that the Hired card isn't an ending | keep the HIRED! stamp as a short beat; drop `end_tbc` |
| MC-09 | The career-long Dream vs Reality formula and `dream_reality_delta` | keep the 5 rows, rebased (runway months, clauses), scored per job |
| MC-10 | The salary scale (a Junior earns $29-45k a year vs Phase 1's $50-125k; Remy's $150k) and its display | the contract shows the yearly figure; rebase the Dream target |
| MC-11 | The intro ends on "How did you spend those four years?" but run 1 skips Background select | a new last caption that hands over to day 0 (a draft is in CONTENT 16.6) |
| MC-12 | Tired has no source without energy pips | retire it (Burnout already lowers Composure) |
| MC-13 | Commute has no daily rule (only E08's +0.3) | none in M1; the Dream score only |
| MC-14 | Work modes and office days for non-remote postings | Remote or not; Phase 1's office days per tier |
| MC-15 | Telemetry (R-TEL-01) vs a game that is offline and collects nothing | a local run log and a debug report only |
| MC-16 | Paid asset packs vs "no art budget" (D-21) | free/CC0 packs only unless you OK one |
| MC-17 | The plain-language rule (C3) for event cards and tips; tip overlaps (E15 ~ `tip_secrets`, E26 ~ `tip_blameless`) | apply C3 at the M6 writing pass; reuse the two existing tips |
| MC-18 | The Handbook vs the Career Notebook; which tips count (23 event tips since D-28 vs Phase 1's 31) | the Handbook is the Notebook grown up; every tip that fires is collected, Phase 1's as Lore |
| MC-19 | Decline blacklists the company (the spec is silent) | keep |
| MC-20 | Copy that names retired mechanics ("decide before you sleep", "rent days to spare", "Rent's due.") | reword at M3 |
| MC-22 | INV-09 says difficulty is "only numbers from `BackgroundData`", but the career run's difficulty scalar is floor depth (P-01, a `WorkConfig` number) and its archetypes have their own rules (Agency utilization, MegaCorp's two Exceeds) | widen INV-09: difficulty, floor and archetype effects are only numbers and fields in the `.tres` data (`BackgroundData`, `WorkConfig`, `ArchetypeData`), never an `if difficulty == ...` or `if archetype == ...` branch |
| MC-23 | Inside the spec: E12's 20-day cooldown (R-EVT-04's example) stretches R-CB-02's incident gaps from about 20 / 71 days to about 40 / 91 at Codebase 80 / 20, so O5's test ("at least 3x as many incidents at 80 as at 20") fails at about 2.3x | shorten E12's cooldown to 5 days (about 3.1x) or drop it (about 3.6x); the M1 harness confirms O5 |

## Spec gaps: rules the Run Spec leaves undefined, to settle at their milestone

Each is marked "a spec gap" where the docs meet it. The proposed defaults are suggestions for that milestone's huddle (W4), not decisions.

| Gap | Where | Milestone | Proposed default |
|---|---|---|---|
| Starting Skill, MO, Rapport and Burnout | GDD 5.16 | M1 | Skill 0; MO 0 (a Bad Reference sets -20); Rapport 50; Burnout 0 |
| How the days line up with months | GDD 5.15 | M1 | day 0 is the start and day 1 the first day of month 1, so the first rent and living costs are due on day 1 and the first salary on day 25 |
| A partial first month's salary (a job that starts mid-month) | GDD 5.15 | M1 | prorated by the days worked |
| How a promotion inside a job changes your salary | GDD 5.15 | M1 | the new level's table value at this job's floor, or the current salary if that is higher |
| Whether a move starts a new lease at the tier's list price | GDD 5.15 | M1 | yes, with the 360-day lease restarting on the move-in day |
| How a Startup's 0-1 month severance is picked; whether MegaCorp's "2 months per 360 days" is prorated | GDD 5.15 | M1 | rolled 0, 0.5 or 1 month with equal odds; prorated by the days of tenure |
| A ticket's deadline; the size mix of a Junior's assigned tickets | GDD 5.16 | M1 | the deadline is the baseline size in days from the ticket's start; S, M and L equally often (E03's volunteer makes the next one L) |
| The trigger odds and cooldowns of the random events other than E12 | GDD 5.19 | M1 | an even share of "about 12 a year" among the eligible ones, then the harness tunes them |
| The exhausted choice of the events whose row has no "exh." | GDD 5.19, CONTENT 16.3 | M1 (its 10 events), M6 (the rest) | the passive or people-pleasing choice CONTENT 16.3 marks "proposed" |
| What owning a service means (E12's `owns_service` flag) | GDD 5.19 | M1 | later E12s at this job lose "Escalate" ("Prod now has your phone number") |
| E04 in the Shared room, with no tier below | GDD 5.19 | M1 | the card shows the raise with one button |
| How the harness resolves duels: interviews (bots can't tap) and reviews (no prompts until M3) | GDD 5.16, 5.22 | M1 | interviews: the duel's own formulas with a modeled tap error, as GDD 5.12's bot did; reviews: a stand-in rating from Evidence against Calibration |
| Which 10 events M1 builds | GDD 10.7, ROADMAP 12 | M1 (STEP-14's huddle) | E01, E02, E04, E07, E08, E12, E18, E20, E21, E24: each bot's strategy meets the event it is built around |
| M1's exit "the Planner within 5 points of its band" also passes at 0% wins | GDD 10.7, ROADMAP 12 | M1 | add "and wins at least 1% (100 of 10,000 seeds)" |
| The career run's first-run coach marks (Phase 1's teach the hunt) | GDD 4.3 | M2 | Ducky notes on day 0 for the Hours slider, the speed control and the Studio chip, closing on a tap (D11) |
| How often a recurring event shows its tip | GDD 8.5 | M2 | the first time it resolves in a run (A15's once-per-run rule), never twice in a row |
| The review duel's prompt kinds, how its prompts deal damage, what emptying the Calibration bar means, and its 12-prompt pool | GDD 5.16 | M3 | design at M3 on the Dana duel UI (P-08) |
| The clause list (visible and hidden) and what each clause does | GDD 5.20, S10 | M3 | on-call (E06), remote in writing (E08's push back), "unlimited PTO" (a joke clause); the hidden one from Phase 1's fine-print pool |
| The callback odds' 5-dot thresholds (Phase 1's would call nearly every posting Good, as A11 found for bluffs) | GDD 5.20 | M3 | five equal steps over 0-50%: 10 / 20 / 30 / 40% |
| Whether more than one offer can be on the table | GDD 5.20 | M3 | one at a time, as Phase 1's 5.9.1 |
| What E07's three prep choices do (update your profile, ask Priya, cut spending) | GDD 5.19 | M3 | the board opens early with the next floor's postings; at Rapport 60+ Priya puts the layoff date on the calendar strip; living costs x0.8 until the scene |
| How often an on-call week comes (E06) | GDD 5.19 | M3 | one week in six while the contract has the clause |
| Run 1's work mode at Pivotly | GDD 3.3, 5.18 | M3 | onsite: run 1 is the office's story (Minh's desk, the lamp, the coffee machine) |
| The day-0 influencer clip | GDD 3.3 | M3 (with MC-11) | a short ClikClok clip in the phone shell that names the five Studio conditions |
| How many a resizing cuts, and whose salaries you're ranked against; the archetypes' layoff frequencies | GDD 5.18, 5.19 | M4 | about 20% of the floor at a Startup, 15% at an Agency, 10% at a MegaCorp, ranked against your coworkers' salaries; MegaCorp yearly, Startup about every 9 months, Agency after a client churn |
| What "a Startup after funding" means for E08 | GDD 5.19 | M4 | a Startup can roll E08 only after your first 360 days there |
| Forced leave's length, pay and what happens to the job | GDD 5.21 | M4 | 30 days at half pay, the job kept, the clock running |
| Short Tenure's "removed": every stack or one; whether Burnout History's 120 days must be in a row | GDD 5.21 | M4 | every stack; in a row |
| What counts as a reference | GDD 5.20 | M4 | each coworker, past or present, at Rapport 60+ |
| MegaCorp's two duels: does the second start with full Composure, and how far apart are they | GDD 5.20 | M4 | full Composure each time, the second 3-7 days after the first |
| What DoomApply offers during job 5 (there is no next floor, D-16) | GDD 5.20 | M4 | the board stays readable, applying is off, and a line says this is the last floor |
| Who your manager is at a generated company | GDD 5.18 | M4 | a coworker from the name pool, palette-swapped |
| "Event frequency" in R-ARC-02: which events floor depth speeds up | GDD 5.18, 6.1 | M4 | the random events and the telegraphed chains; scheduled events keep their cadence (the merge's reading) |
| The manager portrait and the walk cycle are missing from the asset list | GDD 2.11 | M5 | add them to M5's asset list |
| The "war_room" focus location (E12's example) has no room in the floor plan | GDD 2.11 | M5 | the meeting room |
| Which kind (Option or Lore) each unclassified tip is; which tips unlock duel answers (R-JOB-03's "extra answer options") | GDD 5.21, 8.6 | M6 | Lore until M6 decides |
| `e_handbook` in the callback formula has no v1 edge | GDD 5.20 | M6 | 1.0 |
| What happens to an unmerged PR (E16); how long a mentorship lasts (E23) | GDD 5.19 | M6 | the ticket ships 5 days later; until either of you leaves |
| Ducky's route hint after the first loss (the mitigation of ROADMAP risk 14) has no milestone | ROADMAP 8 | M6 | write it in M6's Ducky pass |

**Clarified while merging (readings, not decisions):** home recovery is r = 0.10 / 0.25 / 0.35, subtracted (the spec's table shows the minus sign); "~10 scheduled events a year" counts events with choices; the Studio hold is shown as the Filming bar; E14's "ticket -20%" is the current ticket's progress (E20 and E25 say "speed" when they mean speed); the Resume Gap's "-10% per stack" follows R-JOB-02's stack pattern, (1 - 0.10 n); the diorama's vertical scroll is content scrolling like Mail's list, not a gesture action (GDD 2.8 rule 5). (The gap about the negotiation cap went away with D-27.)

## Your open questions

1. **The open conflicts** (the table above), each with a proposed resolution: MC-01 (the rest), MC-03..MC-20, MC-22 and MC-23. M1 needs four first: MC-04 (starting savings, with the day-31 caution), MC-05 (the archetype ids), MC-22 (INV-09's wording) and MC-23 (E12's cooldown against O5).
2. **Scope tags for the career run** (W4; GDD 10.7). A starting point: MUST = M1-M4 plus the Handbook (D-08's "something persists" needs it); SHOULD = M5 (the diorama, pause-and-zoom, the ending video), the events beyond the first 26, the Ducky writing pass; LATER = telemetry beyond a local run log (MC-15).
3. **Tone sign-off** on the drafts in CONTENT 16: Pivotly's coworkers, the event cards, the burnout warnings, the endings (especially the Burnout ending's line, "You took the leave. You didn't come back."), and Dana's layoff lines.
4. **Tip accuracy** for the 23 event tips (CONTENT 16.4): the Run Spec's own lines, made ASCII and American.
5. **Three proposed invariants:** INV-21 (the sim core is pure and deterministic), INV-22 (no time passes while the app is closed), INV-23 (a Junior has exactly one continuous control). The wording is in `docs/REVIEW_QUEUE.md` 0.4. Add them?
6. **The headless test runner:** commit it into the repo (for example `tools/headless/`) at the start of M1, so it stops living in a temporary folder?
7. **M1's huddle:** which 10 events (proposed above), whether M1's exit should also need at least 1% Planner wins, and the other M1 spec gaps.
8. **Skim** the merge's agent defaults A52-A61 and the new RC-32..RC-35.

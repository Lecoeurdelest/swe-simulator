# Review queue: what's waiting for you

Rewritten on 2026-10-07 at the end of the Run Spec v1 merge. Section 0 is new; sections 1-6 carry over what was still waiting from the Step 7 review (2026-09-29). Tick items off here, or delete the file when you're done.

## 0. The Run Spec v1 merge (2026-10-07)

The Run Spec, the career run, is folded into the docs on branch `run-spec-v1-merge` (DECISIONS W8): GDD 2.0 (sections 0-4, the new 5.14-5.22, 6.1, 7.1, 8.5-8.6, 9.5, 10.7, 11.7 and 13), CONTENT 1.2 (section 16: draft strings), ARCHITECTURE 1.5 (section 19: the code plan, nothing built), ROADMAP 1.3 (section 12: M1-M6 as STEP-14..STEP-19), DECISIONS, the agent rules (`.agent/AGENTS.md`, INV-20) and the tracking. No code, scene, `.tres`, JSON or asset changed. `docs/merge-report.md` is the record: where every part of the spec went, every conflict and how it was resolved.

### 0.1 Merge the branch (5 minutes)

Open the pull request at https://github.com/Lecoeurdelest/swe-simulator/pull/new/run-spec-v1-merge, look it over, and merge it with **"Create a merge commit"**. M1 then starts on `step-14-sim-core` (A61; from `main` if you merge first).

### 0.2 Your open conflicts

Each has a proposed resolution in `docs/merge-report.md`, and the docs mark it **Open (MC-nn)** wherever it matters. Nothing below is decided.

| ID | The question | Proposed |
|---|---|---|
| MC-01 (the rest) | What happens to Steps 7-13 while M1-M6 run, and which game `v0.5-mvp` ships | fold Playtest #1 into the M2 gate; the R-BAL harness replaces Step 7's Phase 1 sim (ISSUE-09 goes with it); keep drag-to-sign for M3 and park the other hunt SHOULDs; the art and release steps after M4; `v0.5-mvp` = the career run |
| MC-03 | What a background changes in the career run | the duel's inputs, starting savings and the commute (the Dream score) only |
| MC-04 | Starting savings (not in the spec) | the Phase 1 runway days as months of expenses (0.5 / 0.4 / 0.4). A caution: the first rent is due on day 1, so a run that starts between jobs would be below zero at once and reach Plan B around day 31 unless a first salary lands; let the harness test it before you pick |
| MC-05 | The three archetypes vs Phase 1's three tiers | Startup = `startup`, Agency = `mid`, MegaCorp = `big`, ids unchanged |
| MC-06 | The placeholder company names (Pivotly, Outsourcery, Monolith) | reuse Hierarchai, Scope & Creep Digital and OmniGlobal Dynamics; otherwise a trademark check on new names (C1) |
| MC-07 | Phase 1's hunt satire (ghost jobs, knockouts, the Radar, referrals, Research) on the new board | keep the Run Spec's board for M1-M4; consider ghost and knockout flags on postings at M6 |
| MC-08 | What Accept shows, now that the Hired card isn't an ending | keep the HIRED! stamp as a short beat; drop `end_tbc` |
| MC-09 | The career-long Dream vs Reality score | keep the 5 rows, rebased (runway months, clauses), scored per job |
| MC-10 | The salary scale (k$ a month, a Junior at $29-45k a year) and its display | the contract shows the yearly figure; rebase the Dream target |
| MC-11 | The intro ends on "How did you spend those four years?", but run 1 skips Background select | a new last caption that hands over to day 0 (draft in CONTENT 16.6) |
| MC-12 | Tired has no source without energy pips | retire it: Burnout already lowers Composure |
| MC-13 | The commute has no daily rule | none in M1; the Dream score only |
| MC-14 | Work modes and office days for postings that aren't remote | remote or not; Phase 1's office days per tier |
| MC-15 | Telemetry vs a game that is offline and collects nothing | a local run log and a debug report only |
| MC-16 | Paid asset packs vs "no art budget" (D-21) | free or CC0 packs only, unless you OK one |
| MC-17 | The plain-language rule (C3) for event cards and tips; two tip overlaps | apply C3 at M6's writing pass; reuse `tip_secrets` (E15) and `tip_blameless` (E26) |
| MC-18 | The Handbook vs the Career Notebook; which tips count | the Handbook is the Notebook grown up; every tip that fires is collected, Phase 1's as Lore |
| MC-19 | Does Decline still blacklist the company? | keep |
| MC-20 | Copy that names retired mechanics ("decide before you sleep", "Rent's due.") | reword at M3 |
| MC-22 | INV-09 says difficulty is "only numbers from BackgroundData", but floor depth and the archetypes' rules are new difficulty data | widen INV-09 to all the `.tres` data, with no branch on a difficulty or archetype label |
| MC-23 | E12's 20-day cooldown makes O5's test fail (2.3x instead of 3x) | shorten the cooldown to 5 days, or drop it |

(MC-02 and MC-21 are answered: D-26 and D-28.)

### 0.3 Decisions to skim

- **The merge's agent defaults A52-A61** (`docs/DECISIONS.md`): where the spec went, M1-M6 as STEP-14..19, events as JSON with `evt_eNN_*` ids, a snake_case adapter, the harness outside `test_run`, ASCII and American spelling, the Hours slider as five notches, the moved handoff docs, the D- series continuing at D-26, STEP-14's branch.
- **RC-01..RC-35** (`docs/merge-report.md`): the conflicts resolved by your precedence rules or your own decisions. RC-32..RC-35 are new: "CI" means the headless runner (the repo has none); a choice that ends the run asks first; the layoff scene's beats advance on taps and Back opens Pause; the save triggers are the spec's and Phase 1's together.

### 0.4 Only you can set these

- **Scope tags for the career run** (W4; GDD 10.7). A starting point to react to: MUST = M1-M4 plus the Handbook (D-08's "something persists" needs it); SHOULD = M5 (the diorama, pause-and-zoom, the ending video), the events beyond the first 26, the Ducky writing pass; LATER = telemetry beyond a local run log (MC-15).
- **Tone sign-off** on the drafts in CONTENT 16: Pivotly's coworkers, the event cards, the burnout warnings (GDD 1.3: the employer is the joke, never the person's health), the endings (is the Burnout ending's "You took the leave. You didn't come back." the right tone?), and Dana's layoff lines.
- **Tip accuracy** for the 23 event tips (CONTENT 16.4; GDD 8.1). They are the Run Spec's own lines, made ASCII and American.
- **Three proposed invariants** (`.agent/rules/invariants.md` has INV-20, the art rule, which you asked for):
  - INV-21: the career run's sim core is a pure, deterministic step function with no Node, SceneTree, autoload, wall clock or file access, only the run's seeded RNG; the same seed and inputs replay the same run (ARCHITECTURE 19.1-19.2).
  - INV-22: no time passes while the app is closed: the clock moves only in the work state with no card, app or modal open, and the sim never reads the wall clock (D-13).
  - INV-23: a Junior's screen has exactly one continuous control, the Hours slider (D-14, O3).
- **The headless test runner** lives in a temporary folder each session (the handoff's Appendix A). M1's harness leans on it (A56): shall Claude commit it into the repo (for example `tools/headless/`) at the start of M1?

### 0.5 Spec gaps for M1's huddle

The rules the Run Spec leaves undefined are listed in `docs/merge-report.md`, each with its milestone and a proposed default. M1's (STEP-14): the starting values (Skill, MO, Rapport, Burnout), the day numbering and a partial first month's salary, a promotion's salary, leases and moves, severance, ticket deadlines and sizes, the random events' odds, the exhausted choices, owning a service (E12), E04 in the Shared room, how the harness resolves duels, which 10 events M1 builds, and whether M1's exit should also need at least 1% Planner wins. If you're away, Claude takes the proposed defaults and logs them as agent defaults (W4).

## 1. The Step 7 review (merged)

Pull request #6 (`step-07-dev-review`) was merged into `main` (dde5b99): CV editing and lying removed (D9), coach marks that close on a tap (D11), the VS screen that waits for your tap (D12), plainer choice questions and Hired-card copy (C3, C4), and the real HP and stat bars (W7), plus the review fix pass (A47-A51). 217 tests passed in 20 suites. You can delete the merged step branches on GitHub.

## 2. Decisions to review from the Step 7 review (`docs/DECISIONS.md`)

| ID | In short |
|---|---|
| D9 | CV editing and lying removed (supersedes D4). No "Polish CV" button: no stat fits, and Tailor & Apply already is the per-job polish. |
| D10 | Best Dream score per background is LATER. |
| D11 | Coach marks close on a tap (a small "x" shows it). |
| D12 | The VS intro waits for a tap; Dana shows one joke stat and one special move. |
| C2 | The review queue's copy approved, and its 4 wording issues fixed. |
| C3 | The 14 choice questions checked for plain language (11 reworded, 3 already plain). |
| C4 | New Hired-card header, row labels, lowest grade and footer. |
| W7 | "You do" exercises suspended; Claude builds those features (supersedes W3). Installs, signing, iPhone checks and sign-offs stay yours. |
| P3 | Phase 2 wasn't scheduled until you chose its mechanic. Superseded on 2026-10-07: the Run Spec is that mechanic (W8). |
| A21-A51 | The agent defaults of the review: the CV removal's details, copy details, coach marks, the VS intro, the bars, and the review fix pass (the offer's Ducky tip, "18.9/40" rows, `tip_take_feedback`, a debug "Reset first run"). |

A1-A20 from the first run are still there if you haven't skimmed them. A10, A11 and the lying parts of A9, A12, A13 and A20 are void under D9.

**Questions only you can answer:**

| # | Question | Current behaviour |
|---|---|---|
| A42 | Should the Composure bar be mirrored, so both HP bars grow from the screen center like a fighting game? | Both fill left to right. The career run's duel uses the same bars. |
| Q3 | Balance (ISSUE-09): the agent playtest ran harder than GDD 5.12, and D9 makes it a little harder again. | Unchanged. MC-01 proposes replacing Step 7's Phase 1 sim with the career run's R-BAL harness, which would take ISSUE-09 with it. |
| Q5 | Should a swipe also commit on a quick flick? (A14) | Distance only, 67.5 px. Decide after feeling it on the iPhone. |

## 3. Phase 1 copy to sign off (`docs/CONTENT.md`)

- **Choice questions** (section 7, C3): all 14 read plainly for someone outside tech. The right answer should still be jokingly obvious, and the wrong ones the joke.
- **Hired card** (section 14, C4): the header "YOUR JOB vs REMY'S VIDEO", the rows naming Remy's numbers, grade 1 "All reality, no dream", the footer "100 is the life in Remy's video. Nobody gets 100. Not even Remy." (What the career run does with the Hired card is MC-08.)
- **VS screen** (section 8.3, D12): one special move per interview, in turn.
- **Reworded tips** (section 11; tip accuracy is yours): `tip_small_changes`, `tip_blameless`, `tip_secrets`, `tip_teamwork_without_job`, `tip_star_stories`, the new `tip_take_feedback`, `tip_ask_questions`.

## 4. Your "You do" exercises

Suspended (W7): Claude builds the features. Installs, signing, the iPhone checks and your sign-offs stay yours.

## 5. iPhone checklist (when the Mac and iPhone are ready)

1. **ROADMAP Step 2, the setup:** Xcode, Godot 4.7.2 and its iOS templates on the Mac, the Team ID, the iOS preset, Developer Mode, Run. Write down the install date (7-day expiry).
2. **Title > Device check:** record AC-S02-8..19, including drag-vs-tap with "Rows STOP" and "Rows PASS" and whether the 10 ms haptic can be felt.
3. **Steps 3-7 on the phone:** one-thumb reach and readability (A3's 12 px line pitch), the tiers' feel in interviews, the swipe (A14, Q5), the coach marks' tap and Mail's scroll (ARCHITECTURE 18.1 #17), the VS intro's tap, the offer's Ducky tip, the HP bars' ghost (18.1 #18), 3 full runs with no crash, the 5 kills in `docs/KILL_TESTS.md`, the intro skip.
4. **Then tag the grey-box on `main`:** `git tag v0.1-greybox`, then `git push origin v0.1-greybox` (AC-S06-4).
5. **Later, the career run's kills** (moments 6-11 in `docs/KILL_TESTS.md`), once M2 builds the work state.

## 6. What's next

- **M1 (STEP-14), the career run's sim core,** is the next step (W9): headless PC work on `step-14-sim-core`, with five bots and the harness (ROADMAP 12; its bundle is `.project/bundles/STEP-14.md`). Its huddle needs your answers to 0.5, or Claude takes the defaults (W4).
- **Steps 7-13 wait for MC-01.** Step 7 (Playtest #1) needs people and the iPhone (P2); Step 8's SHOULDs and the art steps are parked or reordered under MC-01's proposal.
- Every step's status is in `docs/task/README.md`, and the evidence for everything Claude verified is in `.project/evidence/`.

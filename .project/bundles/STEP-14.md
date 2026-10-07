# Bundle: STEP-14 (M1: the sim core, headless)

Snapshot: 2026-10-07, branch `run-spec-v1-merge` at the end of the Run Spec v1 merge (docs only: no code changed since `dde5b99`). Docs: GDD 2.0, CONTENT 1.2, ARCHITECTURE 1.5, ROADMAP 1.3, DECISIONS up to D-28 and A61. Spec: [ROADMAP 12, Step 14](../../docs/ROADMAP.md), [GDD 3.3-3.4, 5.14-5.22, 10.7, 11.7, 13](../../docs/GDD.md), [ARCHITECTURE 19](../../docs/ARCHITECTURE.md), [CONTENT 16.3-16.4](../../docs/CONTENT.md), the spec gaps and open conflicts in [docs/merge-report.md](../../docs/merge-report.md).
State: `ready`. No dependency: M1 starts ahead of Phase 1's open Steps 7-13 (W9). Branch `step-14-sim-core` from `run-spec-v1-merge`, or from `main` once the merge's pull request is merged (A61). Estimates: Claude about 20 h of tool calls, the developer about 3 h. Tests today: 217/217 in 20 suites (Phase 1's).

## Objective

The whole career run's rules, headless: a pure, deterministic step function over a plain-data state (ARCHITECTURE 19.2), its constants in `.tres` (GDD 11.7), the huddle's 10 events in JSON, and five bots in a headless harness (GDD 5.22, ARCHITECTURE 19.6). The bots play whole careers, so every system of GDD 5.14-5.22 is in the sim from the start; M2-M4 put them on screen. Exit (GDD 10.7): 10,000 seeds per bot run in minutes, and the Planner wins within 5 points of its 5-10% band.

## Out of scope

- Any screen, scene or new phase: M2 (STEP-15). `GameFlow.Phase` doesn't change yet.
- Events beyond the huddle's 10 (M4 and M6), and the review duel's prompts (M3; the harness resolves reviews with a stand-in model).
- Phase 1's code, except what the duel resolver reads (`Odds`, `InterviewPlan`) and D-27's cleanup (task 6).
- Deciding an open MC item. The ones M1 needs (MC-04, MC-05, MC-22, MC-23) are the developer's; if they're away, W4's recommended default applies, logged in `docs/DECISIONS.md` as an agent default and listed in the step summary. Scope, tone and tip accuracy always wait.

## Requirements and criteria

| ID | Statement | Method | Owner | Status |
|---|---|---|---|---|
| AC-S14-1 | 10,000 seeds per bot run headless in minutes; the time is in the evidence (R-BAL) | behavioral_test | agent | pending |
| AC-S14-2 | The Planner wins within 5 points of its 5-10% band; the other bots' numbers recorded (R-BAL-01) | behavioral_test | agent | pending |
| AC-S14-3 | The same seed and inputs replay the same run; every suite passes (R-CLK) | behavioral_test | agent | pending |
| AC-S14-4 | MO has no effect on layoff selection (O1, R-EVT-03) | behavioral_test | agent | pending |
| AC-S14-5 | Incidents at Codebase 80 at least 3x those at 20 (O5, R-CB-02), once MC-23 settles E12's cooldown | behavioral_test | agent | pending |
| AC-S14-6 | The win fires only with all five conditions held 90 days; a break resets the hold (O6, R-WIN-06) | behavioral_test | agent | pending |
| AC-S14-7 | The Coaster never wins; its median loss comes before day 1,800 (O2, R-BAL-02) | behavioral_test | agent | pending |
| AC-ECO-1, AC-ECO05-1 | money flow and home tiers (GDD 5.15) | behavioral_test | agent | pending |
| AC-STAT02-1, AC-STAT03-1, AC-STAT04-1 | hidden values, the daily formulas, the review's numbers (GDD 5.16) | behavioral_test | agent | pending |
| AC-CTL01-1, AC-CTL04-1 | the Hours notches; level carry-over (GDD 5.17) | behavioral_test | agent | pending |
| AC-ARC02-1 | floor depth's multipliers (GDD 5.18, 6.1) | behavioral_test | agent | pending |
| AC-EVT01-1, AC-EVT02-1, AC-EVT04-1 | the event tiers, the auto-resolve, the event schema's lint (GDD 5.19) | behavioral_test | agent | pending |
| AC-JOB02-1, AC-JOB05-1 | the callback formula; Study (GDD 5.20) | behavioral_test | agent | pending |
| AC-SCAR01-1 | the Scars (GDD 5.21) | behavioral_test | agent | pending |
| AC-WIN01-1..AC-WIN05-1, AC-WIN08-1 | the Studio's five conditions; the final threats' weight (GDD 3.4) | behavioral_test | agent | pending |

The full statements are in `project.yaml`.

## Decisions

AD-14 (the architecture), D-01, D-04, D-06, D-08..D-13, D-15..D-18, D-20, D-23, D-24 (the career run's rules), D-26 (Phase 1's stats only feed the duel), D-27 (no negotiation), D-28 (E04 without negotiation), P-01, P-03..P-07, Q-01, Q-02, Q-06. Workflow: W1 (commit and push per increment), W4 (agent defaults while the developer is away), W7, W9 (M1 now). Merge defaults to keep in mind: A53 (task ids), A54 (JSON events, `evt_eNN_*`), A55 (snake_case adapter fields), A56 (the harness outside `test_run`), A57 (ASCII, American spelling), A61 (this branch).

## Design huddle

Bring each with a recommended default (the proposals are in `docs/merge-report.md`'s spec-gap table and its MC table):
1. **Which 10 events:** proposed E01, E02, E04, E07, E08, E12, E18, E20, E21, E24, so each bot's strategy meets the event it is built around.
2. **The M1 spec gaps:** starting Skill, MO, Rapport and Burnout; the day numbering and a partial first month's salary; a promotion's salary; leases and moves; severance; ticket deadlines and sizes; the random events' odds; the exhausted choices; owning a service (E12); E04 in the Shared room; how the harness resolves duels.
3. **MC-04** (starting savings: note the day-31 Plan B caution), **MC-05** (the archetype ids), **MC-22** (INV-09's wording) and **MC-23** (E12's cooldown against O5).
4. **M1's exit at 0%:** add "and the Planner wins at least 1%"?
5. **The headless runner:** commit it into the repo (for example `tools/headless/`) instead of recreating it each session?

## Tasks (ROADMAP 12, Step 14)

1. **Data** (Claude): `WorkConfig` and `ArchetypeData` (`@tool` Resources; script defaults = GDD 11.7), `data/work/work_config.tres`, the three `data/archetypes/*.tres`, the 10 events in `data/content/work_events.json` (texts from CONTENT 16.3). Grow `test_data_files` and `test_content_lint`.
2. **The sim core** (Claude): `SimState`, `Sim.step`, `WorkOdds`, `EventPlan` (ARCHITECTURE 19.2), every system of GDD 5.14-5.22, 3.3 and 3.4, with the tick order of 19.2.
3. **The tests** (Claude): `test_sim_rules`, `test_sim_review`, `test_sim_events`, `test_sim_endings`, `test_sim_replay`, `test_sim_smoke` (ARCHITECTURE 19.10), with the GDD's worked numbers.
4. **The harness and the five bots** (Claude): `tests/harness/run_harness.gd`, `tests/harness/bots/` (ARCHITECTURE 19.6), run headless on a copy of the repo (`.agent/AGENTS.md`). Reports to `.project/evidence/STEP-14/<run>/`.
5. **First tuning** (Claude, then the developer): `WorkConfig` and `ArchetypeData` only, until the Planner is within 5 points of its band; record what changed and why.
6. **D-27's cleanup** (Claude), its own commit: remove `Odds.negotiate_p`, `Odds.negotiated_salary`, BalanceConfig's `nego_*`, the offer's `negotiated` flag, `test_offer`'s negotiation test and the unused strings (CONTENT 16.7); sync GDD 11.6, ARCHITECTURE 6.2, 7.1 and 17, and `test_data_files`.

## Files and symbols

- **New:** `core/sim_state.gd`, `core/sim.gd`, `core/work_odds.gd`, `core/event_plan.gd`; `data/types/work_config.gd`, `data/types/archetype_data.gd`; `data/work/work_config.tres`; `data/archetypes/*.tres`; `data/content/work_events.json`; `tests/harness/run_harness.gd`, `tests/harness/bots/*.gd`; `tests/test_sim_rules.gd`, `test_sim_review.gd`, `test_sim_events.gd`, `test_sim_endings.gd`, `test_sim_replay.gd`, `test_sim_smoke.gd`.
- **Read:** `core/odds.gd` (`knowledge_p`, `stat_score`, `zone_half`, `answer_q`, the committee wheel), `core/interview_plan.gd` (question picking for the duel resolver), `data/content/questions_*.json`, `data/tiers/*.tres`, `data/backgrounds/*.tres`, `data/balance/balance_config.tres`.
- **Change, with the doc sync:** `tests/test_data_files.gd`, `tests/test_content_lint.gd`; for task 6, `core/odds.gd`, `core/run_state.gd`, `data/types/balance_config.gd`, `data/balance/balance_config.tres`, `tests/test_offer.gd`, `data/content/{tips,barks,emails}.json`, and the ARCHITECTURE 17 blocks of every changed file.
- After a new `class_name`: `filesystem_manage op=scan`, or a headless `--import` on the copy.

## Invariants

INV-03 (rules in pure classes), INV-04 (no global RNG: the sim and each bot roll on their own seeded RNGs), INV-05 (seeds and states as strings), INV-07 (plain-data state), INV-08 (loaded `.tres` never modified), INV-09 (difficulty only as data; its wording is MC-22), INV-12 (tests are `@tool` McpTestSuites without autoloads or `user://`; the harness follows the same rule), INV-15 (numbers in `.tres`, text in JSON; its file counts grow with this step), INV-16, INV-17, INV-20 (no art here). Proposed and not yet accepted: INV-21 (sim purity), INV-22 (no time while closed), INV-23 (one Junior control).

## Verification

- The headless runner (`.agent/AGENTS.md`): every suite (the new `test_sim_*` and Phase 1's 217) and the load check; the harness for each bot. Save the reports under `.project/evidence/STEP-14/<run>/`.
- ARCHITECTURE section 17 stays byte-exact for every changed file.
- `python .project/render.py`, then the three `check_project.py` validators (expected warnings: only D4 and D7 on STEP-00).

## Stop conditions

- The 2x rule: at about 40 h of Claude's time, stop and cut (for example, the Planner and the Coaster first, the other three bots later).
- A balance result that needs a rule change beyond numbers: bring options to the developer (W4); never change a rule silently.
- An open MC item that blocks a rule (MC-23 for O5, MC-04 for the starting savings): take W4's recommended default, log it as an agent default, and list it in the step summary.

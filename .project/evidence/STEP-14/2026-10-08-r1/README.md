# STEP-14 evidence, 2026-10-08, run r1

What this folder proves (ROADMAP 12, Step 14 Done-when; `project.yaml` AC-S14-1 .. AC-S14-7 and the rule checks):

| File | What it is |
|---|---|
| `planner.json`, `coaster.json`, `grinder.json`, `lifestyle.json`, `random.json` | the harness report for each bot: 10,000 seeds (1..10000), the Intern, run 1 (employed at Pivotly), no Handbook, the shipped data (`data/work/work_config.tres` after the first tuning, DECISIONS A74) |
| `tests.txt` | the headless test run (347 passed, 26 suites), the load check (109 files) and the ARCHITECTURE section 17 sync (30 blocks), with the per-suite counts |
| `extras/` | further runs of the Planner (and the Coaster): run 2 (between jobs), the full Handbook, the Graduate and the Self-Taught, 2,000 seeds each |

Commands (from the repo root, on the Windows PC; Godot 4.7.2):

```bash
bash tools/headless/run_bots.sh seeds=10000 out=D:/Code/swe-simulator/.project/evidence/STEP-14/2026-10-08-r1
bash tools/headless/run_tests.sh            # all suites
bash tools/headless/run_tests.sh parse      # load every .gd and .tscn
python tools/headless/sync_arch17.py .      # ARCHITECTURE section 17 byte-exact
```

Code state: the harness and the data are commit `e9e072d` on `step-14-sim-core` (the documentation commits after it change no code).

## The five bots, 10,000 seeds each

| Bot | Wins | Median day | Endings | ms a run |
|---|---|---|---|---|
| Planner | 1,108 (11.08%) | 810 | Plan B 8,249; Studio 1,108; Legacy System 556; Burnout 87 | 40.8 |
| Coaster | 0 | 390 | Plan B 10,000 | 9.4 |
| Grinder | 0 | 97 | Burnout 10,000 | 3.0 |
| Lifestyle | 0 | 330 | Plan B 9,947; Burnout 53 | 11.1 |
| Random | 0 | 150 | Burnout 5,073; Plan B 4,927 | 4.9 |

**Speed (AC-S14-1):** all five bots ran in parallel, one process each, in 419 seconds; the Planner alone took 408 s (40.8 ms a run), the others 30-111 s. No bot refused an input (`rejected_inputs` 0) and no run hit the step guard.

**The Planner (AC-S14-2):** 11.08% is within 5 points of the 5-10% band and above the 1% floor (DECISIONS A70). 64% of its seeds reach Mid inside job 1 (D-23 asks for 60% or more).

**The Coaster (AC-S14-7, O2):** never wins; its median loss is day 390, long before day 1,800.

## Extras (2,000 seeds each)

| Run | Wins | Median day | Note |
|---|---|---|---|
| Planner, run 2 (starts between jobs) | 7.10% | 30 | 91% end in Plan B on day 30: starting savings of 1.05 k$ against 2.1 k$ of bills on day 1 (MC-04) |
| Planner, full Handbook (the four Edge tips and the remote-in-writing Option) | 22.75% | 870 | double the empty-Handbook rate (D-18 intends "about 15% of total power") |
| Planner, the Graduate | 0.80% | 390 | Phase 1's stats make the duel much harder (D-26, MC-03) |
| Planner, the Self-Taught | 0.00% | 390 | the same, more so |
| Coaster, run 2 | 0% | 30 | Plan B on day 30 |

## Not met yet (left for M4, DECISIONS A74)

- A median run of 1,100-1,400 days: the Planner's is 810.
- Each hard-loss ending at 10% or more of the losses: the Planner's losses are 92% Plan B, 6% Legacy System, 1% Burnout and 0% Career Change (across all bots Burnout is common).
- About 27% of Planner runs die at the first hunt after run 1's day-240 layoff.
- M1 has 10 of the 26 events, so its late game is gentler than the finished game's will be.

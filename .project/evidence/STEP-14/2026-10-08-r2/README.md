# STEP-14 evidence, 2026-10-08, run r2

The rerun after the developer's sign-off (DECISIONS D-29..D-38). Two data changes came with it: D-30 doubled the starting savings (`BackgroundData.start_savings_months` 1.0 for the Intern, 0.8 for the Graduate and the Self-Taught; was 0.5 / 0.4 / 0.4) and MC-06 replaced the Run Spec's placeholder companies with Phase 1's (data and ids only). `../2026-10-08-r1/` is the as-built evidence and stays as history.

| File | What it is |
|---|---|
| `planner.json`, `coaster.json`, `grinder.json`, `lifestyle.json`, `random.json` | the harness report for each bot: 10,000 seeds (1..10000), the Intern, run 1 (employed at Hierarchai, once the placeholder Pivotly), no Handbook, the shipped data (`data/work/work_config.tres` after the first tuning, DECISIONS A74, accepted by D-29) |
| `tests.txt` | the headless test run (349 passed, 26 suites), the load check (109 files) and the ARCHITECTURE section 17 sync (30 blocks), with the per-suite counts |
| `extras/` | further runs of the Planner (and the Coaster): run 2 (between jobs), the full Handbook, the Graduate and the Self-Taught, 2,000 seeds each |

Commands (from the repo root, on the Windows PC; Godot 4.7.2):

```bash
bash tools/headless/run_bots.sh seeds=10000 out=D:/Code/swe-simulator/.project/evidence/STEP-14/2026-10-08-r2
bash tools/headless/run_harness.sh bot=planner seeds=2000 run=2 out=<dir>     # the extras: run=2, handbook=full, bg=graduate, bg=self_taught
bash tools/headless/run_tests.sh            # all suites
bash tools/headless/run_tests.sh parse      # load every .gd and .tscn
python tools/headless/sync_arch17.py .      # ARCHITECTURE section 17 byte-exact
```

Code state: branch `step-14-signoff`, the commit that adds this folder (the sim core and the harness are unchanged since `e9e072d`; only data, tests and docs changed).

**The rename changes nothing.** After MC-06 the Planner's 10,000 seeds (and the other four bots) were rerun on the renamed data, and every report field except the timings is identical to the first r2 run (wins, endings, medians, jobs, the Mid share, the early-loss share, the per-run stats).

## The five bots, 10,000 seeds each

| Bot | Wins | Median day | Endings | ms a run |
|---|---|---|---|---|
| Planner | 1,279 (12.79%) | 861 | Plan B 8,100; Studio 1,279; Legacy System 568; Burnout 53 | 35.2 |
| Coaster | 0 (0.00%) | 420 | Plan B 10,000 | 8.4 |
| Grinder | 0 (0.00%) | 97 | Burnout 10,000 | 2.5 |
| Lifestyle | 0 (0.00%) | 360 | Plan B 9,936; Burnout 64 | 11.1 |
| Random | 0 (0.00%) | 160 | Burnout 5,340; Plan B 4,660 | 4.4 |

**Speed (AC-S14-1):** all five bots ran in parallel, one process each; the longest, the Planner, took 352 s (35 ms a run), the others 25-112 s. No bot refused an input (`rejected_inputs` 0) and no run hit the step guard.

**The Planner (AC-S14-2):** 12.79% is within 5 points of the 5-10% band and above the 1% floor (DECISIONS A70). 74% of its seeds reach Mid inside job 1 (D-23 asks for 60% or more). The first run (r1, before D-30) had 11.08% and 64%.

**The Coaster (AC-S14-7, O2):** never wins; its median loss is day 420, long before day 1,800.

## What D-30 changed, run 1 against r1

| Bot | r1 wins | r2 wins | r1 median | r2 median |
|---|---|---|---|---|
| Planner | 11.08% | 12.79% | 810 | 861 |
| Coaster | 0% | 0% | 390 | 420 |
| Grinder | 0% | 0% | 97 | 97 |
| Lifestyle | 0% | 0% | 330 | 360 |
| Random | 0% | 0% | 150 | 160 |

The share of Planner runs ending by day 400 (the first hunt after run 1's day-240 layoff) fell from 27% to 11%. Every M1 target still holds (GDD 5.22).

## Extras (2,000 seeds each)

| Run | Wins | Median day | Note |
|---|---|---|---|
| Planner, run 2 (starts between jobs) | 17.50% | 720 | at the old 0.5 months 91% ended in Plan B on day 30 (r1: 7.10% wins, median day 30): D-30 removed the cliff |
| Planner, full Handbook (the four Edge tips and the remote-in-writing Option) | 25.35% | 858 | double the empty-Handbook rate again (D-18 intends about 15% of total power); left for M6 (D-31) |
| Planner, the Graduate | 0.80% | 420 | Phase 1's stats make the duel much harder (D-26, MC-03); revisited at M4 (D-32) |
| Planner, the Self-Taught | 0.10% | 420 | the same, more so |
| Coaster, run 2 | 0.00% | 60 | Plan B on day 60 (r1: day 30), the month of savings gone |

## Not met yet (left for M4, DECISIONS A74, D-29)

- A median run of 1,100-1,400 days: the Planner's is 861.
- Each hard-loss ending at 10% or more of the losses: the Planner's losses are 92.9% Plan B, 6.5% Legacy System, 0.6% Burnout and 0% Career Change (across all bots Burnout is common).
- M1 has 10 of the 26 events, so its late game is gentler than the finished game's will be.

# Tracking agent log (2026-09-29)

Role: review the two docs agents' uncommitted edits lightly, finish the plan tracking, and commit. No editor tools and no screenshots were used, and no code or test file changed.

## Checks run

| Check | Result | File |
|---|---|---|
| Headless suite (every `tests/test_*.gd`, fresh Godot process) | `RESULT passed=217 failed=0 total=217 suites=20` | `test_run.txt` |
| `content_lint` alone | `RESULT passed=33 failed=0 total=33 suites=1` | `test_run.txt` |
| Parse check (every .gd/.tscn under autoload, core, data, features, ui, tests) | `CHECK files=85 failed=0` | `tracking_parse.txt` |
| ARCHITECTURE 17 vs the files (`cmp17.py`) | 23 of 23 blocks SAME | `tracking_cmp17.txt` |
| `check_project.py validate project.yaml` | valid; 1 expected warning: STEP-00 still lists D4, now superseded by D9 | (console) |
| `check_project.py audit-preservation project.yaml --root .` | valid (10 artifacts, including the new ART-PARKING) | (console) |
| `check_project.py audit-task-status docs/task/README.md` | valid (14 tasks) | (console) |

## Docs review (the docs agents' diffs)

- **Headings:** a script compared every heading in the 9 edited files with `HEAD`. None was lost. The only renames are the ones the docs agents reported: GDD 5.4 "CV", 5.8.5 and 11.5 marked "(removed 2026-09-29, DECISIONS D9)", and 5.9.4 "Accept, Decline". New: ARCHITECTURE 10.5 and the parking lot's 3 headings.
- **Tables:** the same script checked every Markdown table outside code fences for rows whose column count differs from the header. None found.
- **Stale lying text:** a grep for lie, probe, bluff, BUSTED, rescind, background check, confess, `cv_levels`, `lies_carried`, Come clean, CV screen, ProbeButton, `vs_min_view_s`, `try_skip` and `vs_dana_moves` across GDD, CONTENT, ARCHITECTURE, ROADMAP, KILL_TESTS, AGENTS, invariants and the bundles found only removal notes, history, or unrelated words (e.g. "applying" contains "lying", and `tip_blameless` says "not a confession"). The only lie data left in ARCHITECTURE is inside the 17.13 `test_save.gd` block, which tests that an old save with those keys still loads.
- **Small fixes made here:**
  - ROADMAP Steps 4-6 "You do" lines: every line had the same note, "(suspended, W7: Claude built hp_bar and stat_bar; the rest dropped)". Now the hp_bar and stat_bar lines say "Built by Claude on 2026-09-29" and the other three say "Dropped".
  - ARCHITECTURE 8 (Kill tests): "the ROADMAP Step 6 You-do" became "the ROADMAP Step 6 iPhone check (still the developer's under DECISIONS W7)", to match KILL_TESTS.md.
  - ARCHITECTURE 14.1: the `.claude/skills` note still said this PC has `core.symlinks=false`. It now lists the 4 symlinks and says the PC was fixed on 2026-09-27 (ISSUE-04), as `.agent/AGENTS.md` does.

## Tracking changes

- `docs/REVIEW_QUEUE.md` was rewritten for the review state:
  - one PR `step-07-dev-review` -> `main`;
  - D9-D12, C2-C4, W7 and A21-A46 in one table;
  - open questions A42, Q3, Q5 and a new Q6 (the offer paper's tip note);
  - the new copy to sign off;
  - You-do suspended;
  - the iPhone checks for the coach-mark tap, the VS tap and the HP ghost;
  - next steps: Playtest #1 and the balance re-sim; Phase 2 parked.
- `.project/state.json`:
  - AC-S04-5 went needs_revalidation (its evidence named the deleted lie_probe suite) and then pass with `test_run.txt`.
  - The notes of the developer-owned criteria that describe removed mechanics were updated: AC-S04-3, AC-S04-4, AC-S05-1, AC-S05-2, AC-S06-1, AC-S06-2 and AC-S06-4.
  - STEP-03 to STEP-06 details were updated.
  - STEP-07 is `in_progress` under W2, with AC-S07-1..4 pending.
  - ISSUE-09's summary was updated for D9. ISSUE-10 (design_change, resolved) was added.
- `project.yaml`:
  - D4 is superseded by D9. D9-D12 and C2-C4 were added.
  - MUST-07 and AC-DOD-05 are retired, and AC-DOD-05 left STEP-13's acceptance list.
  - Statements were updated for AC-S04-3, AC-DOD-08, AC-DOD-09, AC-DOD-15, AC-DOD-16 and SHOULD-06.
  - The W3 convention was replaced by W7.
  - Added: the BASE-DOCS-REVIEW baseline, ART-PARKING, and the parking lot and review queue in CMP-DOCS.
  - STEP-04 to STEP-07 got amendments and decision ids.
- `docs/task/README.md` and `.project/generated-manifest.json` were re-rendered with `.project/render.py`.

Follow-up (review fix pass, 2026-09-29): REVIEW_QUEUE Q6 (the offer's tip note over the Fine print) was the 0.3 s paper slide-in, not an overlap at rest. The probe numbers and the fix (DECISIONS A47) are in `fix_log.md`.

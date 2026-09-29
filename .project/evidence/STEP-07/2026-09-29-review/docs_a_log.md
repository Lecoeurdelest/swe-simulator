# Docs agent A: GDD, CONTENT, ROADMAP and friends after the grey-box review (2026-09-29)

Scope: the docs half that describes the game (not ARCHITECTURE or DECISIONS, which docs agent B owns). No editor tools were used and nothing was committed; the tracking agent commits.

## What changed

- `docs/GDD.md` (v1.1 -> v1.2): CV editing and lying removed everywhere (0, 1.4, 2.7, 2.8, 3.1, 4.1, S03, S04, S05 marked removed, S08, S10, S11, 5.0-5.4, 5.6-5.8.5, 5.9.4-5.9.5, 5.11-5.13, 6, 7, 8.1, 8.3, 9.1-9.3, 10.1-10.6, 11.4, 11.5 marked removed, 12); coach marks close on a tap (4.3, D11); the VS intro waits for a tap and shows one stat and one move (S07, 3.2, 4.4, 11.4, D12); HpBar ghost bar described as built (S08, 9.1); new Hired-card header, rows, grade 1 and footer (S11, 5.9.5, C4); decisions D9-D12 added and D4 marked superseded (12).
- `docs/CONTENT.md` (v1.0 -> v1.1): section 7 replaced by the verified plain-language draft (C3); section 6 without Lie lines; removed ids gone; `vs_dana_move_1..3` in, `vs_dana_moves` out; reworded tips; new Hired-card strings; Graduate perk and flaw; fine-print dedupe rule; review-queue copy marked approved (C2).
- `docs/ROADMAP.md` (v1.1 -> v1.2): cut notes on the lie/CV tasks, the You-do lines marked suspended (W7), section 10 on W7 and W1, cut list and audio list.
- `docs/KILL_TESTS.md`, `.agent/AGENTS.md`, `.agent/rules/invariants.md` (INV-14), `.project/bundles/STEP-00.md`: CV/lie references and the You-do rule updated.
- `docs/ideas_parking_lot.md`: new. Phase 2 ideas (not decided) and the best Dream score per background (LATER, D10).

## How it was verified

- `docs_a_content_check.txt`: three scripts compare CONTENT.md with `data/content/*.json`.
  - Every content id the doc names exists in the JSON, and every top-level JSON id is named in the doc (0 either way).
  - 558 fields match exactly: every table row (barks, endings, news, emails, perks, fine print, tips with triggers, CV lines with tags and gates, naming), every background and company bullet, and every knowledge and choice question block.
  - The drafted section 7 contains all 14 blocks rendered from the current `questions_choice.json`, so it wasn't regenerated.
- A grep over GDD, CONTENT, ROADMAP, KILL_TESTS, AGENTS, invariants, bundles and the parking lot for lie, probe, bluff, BUSTED, rescind, background check, confess, `cv_levels`, `lies_carried`, Buzzwordsmith, Come clean, CV screen and Very Famous: every hit is a removal or cut note, or unrelated wording ("applying", "confession" in `tip_blameless`).
- Headless run after the edits (docs don't change code; this is the tree's state): `docs_a_test_run.txt` RESULT passed=217 failed=0 total=217 suites=20; `docs_a_parse.txt` CHECK files=85 failed=0.
- `check_project.py validate`, `audit-preservation` and `audit-task-status`: all "valid", no errors or warnings.
- No screenshots: this slice changes documents only.

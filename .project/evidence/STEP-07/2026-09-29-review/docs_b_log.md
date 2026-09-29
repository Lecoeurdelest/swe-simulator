# Docs B slice: ARCHITECTURE and DECISIONS after the Step 7 review (2026-09-29)

Branch `step-07-dev-review`, on top of 8aaae75. Docs only: no code, scene or data file changed, and no editor tools were used.

## What changed

- `docs/ARCHITECTURE.md` v1.3 -> v1.4. The prose now matches d8db453 (D9), 5c0f968 (copy), e255e6f and 501def5 (coach marks, VS intro) and 8aaae75 (bars). Removed features keep their place with "(removed 2026-09-29, DECISIONS D9)" and what replaced them.
- Section 17 re-synced with `sync17.py`: 12 blocks were stale (17.2, 17.4, 17.5 tier_data and balance_config, 17.6, 17.7, 17.13 test_save, test_interview and test_offer, 17.14, 17.15, 17.16). `cmp17.py` now prints SAME for all 23 blocks (`docs_b_cmp17.txt`).
- `docs/DECISIONS.md`: rows D9-D12, C2-C4, W7 and A21-A46 appended. No old row was rewritten.

## Verified

- Headless tests on the current tree: `RESULT passed=217 failed=0 total=217 suites=20` (`docs_b_test_run.txt`).
- Parse check: `CHECK files=85 failed=0` (`docs_b_parse.txt`).
- Per-suite test counts in ARCHITECTURE 12.2 come from counting `func test_` in each `tests/test_*.gd`. They sum to 217.
- The removed and new API names were checked against the source: `RunState` fields and methods, `GameState` verbs, `HuntTips.coach` / `coach_invite`, `InterviewPlan.vs_plate`, `VersusIntro.tap`, `CoachMark`, `HpBar`, `StatBar`, `DuckyNote.closable` and `UiText.fill`.
- No screenshots: this slice changed no screen.

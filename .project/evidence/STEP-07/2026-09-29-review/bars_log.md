# Bars: HP ghost bar and 5-segment stat bars (2026-09-29, branch step-07-dev-review)

The developer suspended the "You do" exercises, so the two W3 placeholders were built properly:
`ui/components/hp_bar.gd/.tscn` (ROADMAP Step 4 You-do) and `ui/components/stat_bar.gd/.tscn` (ROADMAP Step 5 You-do).

## Tests

- Headless, fresh process: `RESULT passed=217 failed=0 total=217 suites=20` (`bars_test_run.txt`); before this change 212/212 in 19 suites.
- Parse: `CHECK files=85 failed=0` (`bars_parse.txt`).
- Editor `test_run`: 217/217 in 20 suites; `suite=bars` verbose: 5/5 (32 assertions). The bars are `@tool`, so the editor-side runner can build them.
- New suite `bars` (`tests/test_bars.gd`, 5 tests): segments = value / 20 rounded (0..100 and clamps), StatBar minimum size 39x13 and mouse-ignore, `HpBar.fill_px` whole pixels (full, half, rounding, a 1 px sliver above 0, clamps, max 0), the interview start settling with no ghost (max 80 / 100 / 120), and the settled ghost following drops, rises, clamps and a new max.

## Layout measurements (game, `get_ui_elements`)

| Where | Before | After |
|---|---|---|
| S03 card (Graduate) | Card 254x240; Stats grid 240x39; each bar a 42x13 Label "[###--]" | Card 254x240; Stats grid 240x39; each bar a 39x13 StatBar at x 81 |
| Study app, KNOWLEDGE row | row 13 tall (Label "[###--]" 42 wide) | row 13 tall; bar 39x13 at (145, 364), row still centred |
| VS intro, player plate | PlayerStats Label 170x37 at y 335, row 96 tall | PlayerStats GridContainer 170x37 at y 335 (v_separation -1 keeps the 12 px pitch), bars at x 151 = the old "[" column; row 96 tall |

Pixel dump of the S03 screenshot: the 7x7 blocks sit on rows 4-10 of the 13 px line, exactly the monogram capitals of "KNOWLEDGE" beside them, 1 px gaps, amber #feae34 filled and #181425 empty on the #262b44 card.

## Screenshots

- `bars_s03_graduate.png`: Graduate card: KNOWLEDGE 3, EXPERIENCE 1, NETWORK 1 segments (55 / 15 / 15).
- `bars_s03_intern.png`: Intern card: 3 / 2 / 2 (50, 40, 45: 2.5 rounds up to 3).
- `bars_s03_self_taught.png`: Self-Taught card: 3 / 1 / 0 (55, 10, 5): a stat of 5 shows five dark slots.
- `bars_study_knw55.png` and `bars_study_knw70.png`: the hub's Study app (BigOhNo) KNOWLEDGE bar at 55 (3 segments), then after three studies at 70 (4 segments); energy 8 -> 2.
- `bars_vs_plate.png`: the VS intro held on its last frame: ALEX / THE THEORIST, then KNOWLEDGE / EXPERIENCE / NETWORK labels with 3 / 1 / 1 segment bars in one aligned column.
- `bars_hp_start_full.png`: the interview after the VS intro: both bars full (122x8 at x 8 and x 140, y 19), no white anywhere, although Doubt's max is 128 (the default value is 100): setting max_value then value never animates.
- `bars_hp_doubt_ghost_tail.png`: caught with `game_manage suspend` after a good choice answer (Doubt 128 -> 118): red fill to x 252, a 1 px white ghost at x 252, dark slot to x 261 (the tail of the drain; the MCP round trip is about 0.35 s).
- `bars_hp_doubt_ghost_knowledge.png` then `bars_hp_doubt_settled_next_frame.png`: after a CLOSE knowledge answer (Doubt 118 -> 93.41, fill 112 -> 89 px): the ghost's last pixel, then one `next_frame` later settled with no white.
- `bars_hp_ghost_frozen_by_tree_pause.png`: a throwaway probe scene (deleted, never committed) paused the tree 0.21 s into a 128 -> 0 hit: 88 px of white ghost frozen over the empty bar. `bars_ghost_probe_log.txt` has the per-frame log: 122, 121, 119, 116, 111, 104, 97, 88 px, unchanged for the 6 s pause, then 77, 65, 52, 37, 21, 3, 0: drained at 0.425 s game time (the first frame after 0.4 s), whole pixels only; a rise jumps; a second hit mid-drain starts from the ghost's current place (126.35); a new max_value settles it.

## Logs

- Game logs clean in every run (background select, job hunt, interview, probe): only the helper line, the Content line and the IVSTART / IVTRACE / IVFORCE / IVRESULT debug lines.
- Editor log: one pre-existing warning, not from this change (`core/run_state.gd:344`, parameter `commute_minutes` shadows a member).

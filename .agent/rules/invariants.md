# Global invariants

Every task keeps these. Each one restates a rule from the docs; the source wins if the wording differs.

| ID | Rule | Source |
|---|---|---|
| INV-01 | Only `GameState.change_phase()` changes the phase. Scenes call verbs; `SceneRouter` loads the scene. | ARCHITECTURE 4.2 |
| INV-02 | Scenes never call `change_scene_*()` and never load other scenes. | ARCHITECTURE 4.2, 5 |
| INV-03 | Rules live in the pure `@tool` classes (`GameFlow`, `RunState`, `SaveIO`, `Odds`) and take `cfg`/`tier`/`bg`/`rng` as arguments. Scenes only display state and call `GameState` verbs. | ARCHITECTURE 3 |
| INV-04 | No global RNG in gameplay: no `randf()`, `randi()`, `Array.shuffle()`, `pick_random()`. Use the run RNG or the interview RNG (`Odds.roll/pick/shuffled`). | ARCHITECTURE 7.2, 17.4, 18.2 #10 |
| INV-05 | 64-bit seeds and RNG states travel as strings in the save. | ARCHITECTURE 0.7, 8 |
| INV-06 | The save is written only while the run is live (`JOB_HUNT`, `INTERVIEW`, `OFFER`): after every committed action, on entering those phases, and on pause / focus out / close. Written via temp file + rename. Deleted on entering `GAME_OVER` and on leaving `PHASE2_STUB`. | ARCHITECTURE 8; GDD 5.11 |
| INV-07 | `RunState` holds plain data only (String/int/float/bool, Array, Dictionary). Never a Resource, Node or StringName. | ARCHITECTURE 17.2 |
| INV-08 | Never modify a loaded `.tres` at runtime; copy values into `RunState`. | ARCHITECTURE 18.2 #1 |
| INV-09 | No `if difficulty == HARD` anywhere; difficulty is only numbers from `BackgroundData`. | ARCHITECTURE 18.2 #11 |
| INV-10 | The `Phase` enum is append-only. | ARCHITECTURE 4.1, 18.2 #12 |
| INV-11 | Load nothing from `user://` except our own JSON save and `settings.cfg`; never `.tres`/`.res`. | ARCHITECTURE 8, 18.2 #13 |
| INV-12 | Tests are `@tool`, `extends McpTestSuite`, make at least one assertion, and never touch autoloads or `user://`. | ARCHITECTURE 12.1, 18.2 #14 |
| INV-13 | Parody names only, ASCII only, text within the GDD 2.7 budgets; `test_content_lint` enforces it. | GDD 1.3; ARCHITECTURE 12.3 |
| INV-14 | Layout with containers, never absolute positions. Every tappable thing sits inside a `SafeAreaMargin`. Buttons are at least 32 px. Non-blocking overlays use `mouse_filter = IGNORE`. | ARCHITECTURE 10, 18.2 #4-#6 |
| INV-15 | Tuning numbers live in the 7 `.tres` files and text in the 16 JSON files (through `tr()`); no gameplay numbers or strings in scripts. | ARCHITECTURE 0.6; ROADMAP 1 |
| INV-16 | Autoload scripts have no `class_name`. | ARCHITECTURE 3, 18.2 #2 |
| INV-17 | Engine pinned to Godot 4.7.2 with matching templates. Commit before any engine update and before any godot-ai `script_patch`. | ARCHITECTURE 14.3, 18.2 #15 |
| INV-18 | Every failure shows the joke, then the cause, then exactly one true tip. Stats decide about 75% of an outcome, input about 25% (Q = 0.75 S + 25 I). | GDD 1.2 pillars 3-4; ROADMAP Step 4 pitfalls |

@tool
extends McpTestSuite
## Determinism and saving (GDD 5.13, 5.14; ARCHITECTURE 19.2, 19.4, 19.6; O8, R-CLK): the same seed and inputs replay the
## same run, a run replays from its log, a save taken mid-run resumes to the same future, seeds and RNG states travel as
## strings (INV-05) and the state is plain data (INV-07). Uses the shipped data (SimContext.load_default) and the Planner
## as a source of realistic inputs.

const SEED := 20261008


func suite_name() -> String:
	return "sim_replay"


## Play `days` days with the Planner and return the state. The context is the shipped data with the run log on.
func _play(c: SimContext, run_number: int, seed_n: int, days: int) -> SimState:
	var duel := DuelModel.load_default()
	var bot := BotPlanner.new()
	var s := Sim.new_run(c, run_number, seed_n)
	bot.start_run(c, duel, seed_n ^ 0x5DEECE66D)
	var target := s.day + days
	while s.day < target and not s.ended:
		Sim.step(s, bot.inputs(s, c), c)
	return s


func _json(s: SimState) -> String:
	return JSON.stringify(s.to_dict(), "", true, true)


## The state as the same JSON a save reload gives back: every number a float, so 1 and 1.0 compare equal.
func _norm(s: SimState) -> String:
	return JSON.stringify(JSON.parse_string(_json(s)), "", true, true)


func test_the_same_seed_gives_the_same_new_run() -> void:
	var c := SimContext.load_default()
	for run_number: int in [1, 2]:
		assert_eq(_json(Sim.new_run(c, run_number, SEED)), _json(Sim.new_run(c, run_number, SEED)), "run %d" % run_number)
	assert_ne(_json(Sim.new_run(c, 2, SEED)), _json(Sim.new_run(c, 2, SEED + 1)), "another seed, another board")


func test_the_same_seed_and_inputs_replay_the_same_career() -> void:  # R-CLK, AC-S14-3
	var c := SimContext.load_default()
	for run_number: int in [1, 2]:
		var a := _play(c, run_number, SEED, 700)
		var b := _play(c, run_number, SEED, 700)
		assert_eq(_json(a), _json(b), "run %d: two plays of one seed end identically" % run_number)
		if run_number == 1:
			assert_true(a.day > 100, "and they really played (day %d)" % a.day)


func test_different_seeds_play_differently() -> void:
	var c := SimContext.load_default()
	var a := _play(c, 1, SEED, 400)
	var b := _play(c, 1, SEED + 7, 400)
	assert_ne(_json(a), _json(b))


func test_a_run_replays_from_its_log() -> void:  # RC-26: the seed plus the inputs, not every tick
	var c := SimContext.load_default()
	var a := _play(c, 1, SEED, 600)
	assert_gt(a.log.size(), 5, "the run logged its inputs and outcomes")
	var inputs := a.log.filter(func(e: Dictionary) -> bool: return e["k"] == "in")
	assert_gt(inputs.size(), 5)
	var b := Sim.replay(c, 1, SEED, [], a.log, a.day)
	assert_eq(_norm(b), _norm(a), "the replay ends in the same state, log and all")
	var ended := _play(c, 1, SEED, 5000)
	assert_true(ended.ended, "a whole career, to its ending")
	var again := Sim.replay(c, 1, SEED, [], ended.log)
	assert_eq(_norm(again), _norm(ended), "a finished run replays from its log alone: the ending's day is in it")


func test_a_save_taken_mid_run_resumes_to_the_same_future() -> void:  # O8: kill the app, restore, identical
	var c := SimContext.load_default()
	c.log_enabled = false
	for run_number: int in [1, 2]:
		var a := _play(c, run_number, SEED + run_number, 300)
		var b := SimState.from_save(JSON.parse_string(JSON.stringify(a.to_save())))
		assert_eq(_json(b), _json(a), "run %d: the restored state is bit for bit the saved one" % run_number)
		assert_true(a.to_dict() == b.to_dict(), "and equal as plain data")
		for i: int in 500:
			var inputs: Array = SimFixture.answer(a) if a.is_waiting() else []
			Sim.step(a, inputs, c)
			Sim.step(b, inputs, c)
			if a.ended:
				break
		assert_eq(_json(b), _json(a), "run %d: both live the same next days to the same state" % run_number)


func test_a_plain_json_number_save_is_close_but_the_save_of_record_is_exact() -> void:  # why SimState.to_save exists
	var c := SimContext.load_default()
	c.log_enabled = false
	var a := _play(c, 1, SEED, 330)
	var plain := SimState.from_dict(JSON.parse_string(JSON.stringify(a.to_dict(), "", true, true)))
	for key: String in ["savings", "burnout", "mo", "skill", "rust", "codebase", "ticket_progress", "job_salary", "pay_accrued"]:
		assert_true(absf(float(plain.get(key)) - float(a.get(key))) < 1.0e-9, "%s survives a plain JSON save to within 1e-9" % key)
	var exact := SimState.from_save(JSON.parse_string(JSON.stringify(a.to_save())))
	for key: String in ["savings", "burnout", "mo", "skill", "rust", "codebase", "ticket_progress", "job_salary", "pay_accrued"]:
		assert_true(float(exact.get(key)) == float(a.get(key)), "%s survives to_save exactly" % key)


func test_a_save_taken_while_a_card_waits_resumes_the_card() -> void:
	var c := SimContext.load_default()
	c.log_enabled = false
	var s := Sim.new_run(c, 1, SEED)
	var guard := 0
	while not s.is_waiting() and guard < 400:
		Sim.step(s, [], c)
		guard += 1
	assert_true(s.is_waiting(), "some card came up")
	var b := SimState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict(), "", true, true)))
	assert_eq(b.pending().get("kind", ""), s.pending().get("kind", ""))
	assert_eq(JSON.stringify(b.pending()), JSON.stringify(s.pending()))
	var events := Sim.step(b, SimFixture.answer(b), c)
	assert_eq(SimFixture.count(events, "input_rejected"), 0, "the restored card can be answered")


func test_seeds_and_rng_states_travel_as_strings() -> void:  # INV-05
	var c := SimContext.load_default()
	var s := _play(c, 1, SEED, 50)
	var d := s.to_dict()
	assert_true(d["rng_seed"] is String and d["rng_state"] is String, "strings in the save")
	assert_eq(d["rng_seed"], str(SEED))
	assert_true(int(d["rng_state"]) != 0)
	var back := SimState.from_dict(JSON.parse_string(JSON.stringify(d, "", true, true)))
	assert_eq(back.rng_seed, SEED)
	assert_eq(back.rng_state, s.rng_state, "a 64-bit state survives JSON because it is a string")


func test_the_state_is_plain_data() -> void:  # INV-07: String, int, float, bool, Array, Dictionary; never a Resource or a Node
	var c := SimContext.load_default()
	var s := _play(c, 1, SEED, 500)
	var bad: Array[String] = []
	_walk(s.to_dict(), "state", bad)
	assert_true(bad.is_empty(), "non-plain values: %s" % ", ".join(PackedStringArray(bad)))


func _walk(value: Variant, path: String, bad: Array[String]) -> void:
	match typeof(value):
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING:
			return
		TYPE_ARRAY:
			for i: int in (value as Array).size():
				_walk((value as Array)[i], "%s[%d]" % [path, i], bad)
		TYPE_DICTIONARY:
			for k: Variant in (value as Dictionary):
				if typeof(k) != TYPE_STRING:
					bad.append("%s has a %s key" % [path, type_string(typeof(k))])
				_walk((value as Dictionary)[k], "%s.%s" % [path, str(k)], bad)
		_:
			bad.append("%s is a %s" % [path, type_string(typeof(value))])


func test_unknown_keys_are_ignored_and_missing_ones_default() -> void:  # like RunState: an old save still loads
	var s := SimState.from_dict({"day": 12, "savings": 3.5, "from_the_future": [1, 2, 3]})
	assert_eq(s.day, 12)
	assert_eq(s.savings, 3.5)
	assert_eq(s.hours, 3, "a key the save lacks keeps its default")


func test_the_clock_never_reads_the_wall_clock() -> void:  # D-13, INV-22 (proposed): no time while the app is closed
	var c := SimContext.load_default()
	var a := Sim.new_run(c, 1, SEED)
	for i: int in 30:
		Sim.step(a, [], c)
	var json_before := _json(a)
	OS.delay_msec(30)   # real time passes; nothing may change
	assert_eq(_json(a), json_before, "the state moves only when Sim.step is called")

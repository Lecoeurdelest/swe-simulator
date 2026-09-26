@tool
extends McpTestSuite
## RunState <-> JSON round trip (GDD 5.11). Never writes to user:// (in the editor that is the real save folder).

func suite_name() -> String:
	return "save"


func _round_trip(r: RunState) -> RunState:
	return RunState.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))


func test_round_trip_keeps_every_kind_of_field() -> void:
	var r := RunState.new()
	r.phase = GameFlow.Phase.INTERVIEW
	r.background_id = "self_taught"
	r.stats["knw"] = 60
	r.gap_topics.assign(["web", "security"])
	r.cv_levels["exp"] = "lie"
	r.applications.append({"uid": 7, "tier": "mid", "reveal_day": 3, "p": 0.168, "knockout": false})
	r.interview = {"seed": "3141592653", "question_ids": ["kq_hash_map", "kq_left_join"]}
	var back := _round_trip(r)
	assert_eq(back.phase, GameFlow.Phase.INTERVIEW)
	assert_eq(back.background_id, "self_taught")
	assert_eq(back.stats["knw"], 60)
	assert_eq(back.gap_topics, r.gap_topics)
	assert_eq(back.cv_levels["exp"], "lie")
	assert_eq(typeof(back.applications[0]["reveal_day"]), TYPE_INT, "whole JSON numbers come back as ints")
	assert_eq(back.applications[0]["p"], 0.168)
	assert_eq(back.interview["question_ids"], ["kq_hash_map", "kq_left_join"])


func test_64bit_rng_state_survives_json() -> void:
	var r := RunState.new()
	r.rng_state = str(9007199254740993)  # 2^53 + 1: a JSON number would corrupt it
	var back := _round_trip(r)
	assert_eq(back.rng_state.to_int(), 9007199254740993)
	r.rng_state = str(-4611686018427387905)
	assert_eq(_round_trip(r).rng_state.to_int(), -4611686018427387905, "negative states too")


func test_seed_then_state_replays_the_same_dice() -> void:
	var a := RandomNumberGenerator.new()
	a.seed = 20260926
	for _i: int in 5:
		a.randi()
	var saved_seed := str(a.seed)
	var saved_state := str(a.state)
	var expected := [a.randi(), a.randi(), a.randi()]
	var b := RandomNumberGenerator.new()
	b.seed = saved_seed.to_int()    # seed first: setting seed resets state
	b.state = saved_state.to_int()
	assert_eq([b.randi(), b.randi(), b.randi()], expected)

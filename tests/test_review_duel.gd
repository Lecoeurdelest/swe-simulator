@tool
extends McpTestSuite
## The review duel (GDD 5.16; DECISIONS D-39, A94): three choice prompts, the manager's Calibration landing on your
## Evidence by how well you answered, and the rating from the Evidence left. The numbers are worked examples on the Run
## Spec's constants (WorkConfig.new()), so tuning the .tres never breaks them. Editor-side: no autoloads, no user://.

var c: SimContext = SimFixture.ctx(true)


func suite_name() -> String:
	return "review_duel"


func _near(a: float, b: float, eps: float, msg: String = "") -> void:
	assert_true(absf(a - b) <= eps, "%s: %f vs %f" % [msg, a, b])


## Evidence 50 against a Calibration of 60, as at a Startup with MO 0 and no on-time tickets; each kind in order.
func _left(evidence: float, kinds: Array) -> float:
	var left := evidence
	for kind: String in kinds:
		left -= WorkOdds.review_hit(c.cfg, 60.0, kind)
	return maxf(left, 0.0)


func test_a_rounds_hit_is_the_stand_ins_damage_spread_over_the_prompts() -> void:
	_near(WorkOdds.review_hit(c.cfg, 60.0, "neutral"), 60.0 * c.cfg.review_standin_damage / 3.0, 0.0001, "an okay answer takes all of the chip")
	_near(WorkOdds.review_hit(c.cfg, 60.0, "good"), 60.0 * c.cfg.review_standin_damage / 3.0 * 0.4, 0.0001, "a good one 0.4 of it")
	_near(WorkOdds.review_hit(c.cfg, 60.0, "bad"), 60.0 * c.cfg.review_standin_damage / 3.0 * 1.8, 0.0001, "a joke 1.8")
	_near(WorkOdds.review_hit(c.cfg, 80.0, "neutral"), 80.0 * c.cfg.review_standin_damage / 3.0, 0.0001, "a MegaCorp's Calibration hits harder")


func test_three_okay_answers_cost_exactly_what_the_stand_in_costs() -> void:  # A94
	var total := 0.0
	for i: int in 3:
		total += WorkOdds.review_hit(c.cfg, 60.0, "neutral")
	_near(total, 60.0 * c.cfg.review_standin_damage, 0.0001, "the stand-in's mean damage")


func test_the_rating_follows_the_answers() -> void:  # GDD 5.16's 25 / 70 % bands
	var e := 50.0
	assert_eq(WorkOdds.rating(c.cfg, e, _left(e, ["good", "good", "good"])), WorkOdds.EXCEEDS, "three good answers: over 70% left")
	assert_eq(WorkOdds.rating(c.cfg, e, _left(e, ["good", "good", "neutral"])), WorkOdds.MEETS)
	assert_eq(WorkOdds.rating(c.cfg, e, _left(e, ["neutral", "neutral", "neutral"])), WorkOdds.MEETS)
	assert_eq(WorkOdds.rating(c.cfg, e, _left(e, ["bad", "bad", "neutral"])), WorkOdds.BELOW, "two jokes and an okay: under 25%")
	assert_eq(WorkOdds.rating(c.cfg, e, _left(e, ["bad", "bad", "bad"])), WorkOdds.BELOW)
	assert_eq(WorkOdds.rating(c.cfg, 70.0, _left(70.0, ["good", "good", "neutral"])), WorkOdds.EXCEEDS, "a better record needs less: Evidence 70")
	assert_eq(WorkOdds.rating(c.cfg, 30.0, _left(30.0, ["good", "neutral", "neutral"])), WorkOdds.BELOW, "a worse record needs more: Evidence 30")


func test_the_review_checkpoint_carries_the_pools_and_the_cost_of_each_answer() -> void:
	var s := Sim.new_run(c, 1, 4)
	var item := {"kind": "review", "evidence": 55.0, "calibration": 60.0}
	var cp := DuelAdapter.review_checkpoint(item, s, c, [])
	assert_eq(cp["kind"], DuelAdapter.KIND_REVIEW)
	assert_eq((cp["question_ids"] as Array).size(), 3, "three prompts")
	assert_eq(cp["rounds"], 3)
	assert_eq(cp["manager"], "Kev", "Hierarchai's manager (GDD 5.18)")
	_near(float(cp["evidence"]), 55.0, 0.0001)
	_near(float(cp["calibration"]), 60.0, 0.0001)
	_near(float(cp["hits"]["neutral"]), WorkOdds.review_hit(c.cfg, 60.0, "neutral"), 0.0001)
	_near(float(cp["hits"]["good"]), WorkOdds.review_hit(c.cfg, 60.0, "good"), 0.0001)
	_near(float(cp["hits"]["bad"]), WorkOdds.review_hit(c.cfg, 60.0, "bad"), 0.0001)
	assert_true(cp["seed"] is String, "seeds are strings (INV-05)")
	var pool: Dictionary = c.content["questions_review"]
	for id: Variant in cp["question_ids"]:
		assert_true(pool.has(str(id)), "%s is in the review pool" % id)
	assert_eq(cp, DuelAdapter.review_checkpoint(item, s, c, []), "rebuilt from the same inputs: Continue replays it")


func test_a_review_does_not_repeat_the_prompts_you_were_just_asked() -> void:
	var s := Sim.new_run(c, 1, 4)
	var item := {"kind": "review", "evidence": 55.0, "calibration": 60.0}
	var first := DuelAdapter.review_checkpoint(item, s, c, [])
	s.day += 180
	var second := DuelAdapter.review_checkpoint(item, s, c, first["question_ids"])
	for id: Variant in second["question_ids"]:
		assert_false((first["question_ids"] as Array).has(id), "%s was asked last time" % id)


func test_the_manager_is_kev_at_hierarchai_and_a_name_from_the_pool_elsewhere() -> void:
	var s := Sim.new_run(c, 1, 4)
	assert_eq(DuelAdapter.manager_name(s, c), "Kev")
	s.coworkers = [{"id": "cw_gen_0", "level": 1, "salary": 3.0, "rapport": 50.0}]
	s.jobs_held = 2
	var name := DuelAdapter.manager_name(s, c)
	assert_true(c.coworker_pool.has(name), "a generated manager comes from the name pool: %s" % name)
	assert_eq(DuelAdapter.manager_name(s, c), name, "the same for the whole job")


func test_a_finished_review_rates_you_and_clears_the_checkpoint() -> void:  # AC-STAT04-2
	var session := WorkSession.start(c, 1, 4, [], "Alex", false)
	session.sim.queue.append({"kind": "review", "evidence": 50.0, "calibration": 60.0})
	assert_true(session.wants_duel(), "a review waits on the duel screen")
	var checkpoint := session.begin_duel()
	assert_eq(checkpoint["kind"], DuelAdapter.KIND_REVIEW)
	assert_eq(session.seen_review.size(), 3, "the prompts asked join the review's own pool of seen ones")
	assert_eq(session.seen_questions.size(), 0, "and not the interview's")
	var saved := JSON.new()
	assert_eq(saved.parse(SaveIO.encode(session.to_save(GameFlow.Phase.INTERVIEW))), OK)
	assert_eq(WorkSession.from_save(saved.data, c).duel_checkpoint, checkpoint, "Continue in the middle of a review resumes it")
	var left := _left(50.0, ["good", "good", "good"])
	session.finish_review(left)
	assert_true(session.duel_checkpoint.is_empty())
	assert_ne(session.sim.pending().get("kind", ""), "review", "the review is answered (a raise then opens the lifestyle offer)")
	assert_eq(session.notices[0]["rating"], "exceeds", "three good answers: Exceeds")
	assert_eq(session.sim.stats.get("rating_exceeds", 0), 1)

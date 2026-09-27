@tool
extends McpTestSuite
## Question picking (GDD 5.8.2) in InterviewPlan. The real pools are read with FileAccess, never
## through the Content autoload (INV-12); the dry-pool cases use small fixtures built in code.

const CHOICE_PATH := "res://data/content/questions_choice.json"
const KNOWLEDGE_PATH := "res://data/content/questions_knowledge.json"
const TIERS: PackedStringArray = ["startup", "mid", "big"]
const SEEDS := 40

var cfg: BalanceConfig
var choice: Dictionary = {}
var knowledge: Dictionary = {}


func suite_name() -> String:
	return "interview_plan"


func suite_setup(_ctx: Dictionary) -> void:
	choice = _load(CHOICE_PATH)
	knowledge = _load(KNOWLEDGE_PATH)


func setup() -> void:
	cfg = BalanceConfig.new()  # prompt_pattern = choice, knowledge x3, choice (GDD 11.4)


func _load(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _pick(tier: String, seen: Array[String], rng: RandomNumberGenerator, warmup: bool) -> Dictionary:
	return InterviewPlan.pick(cfg, tier, choice, knowledge, seen, rng, warmup)


## One interview of a run: pick, then mark everything asked as seen (what GameState does).
func _interview(tier: String, seen: Array[String], rng: RandomNumberGenerator, warmup: bool) -> Array[String]:
	var plan := _pick(tier, seen, rng, warmup)
	var asked: Array[String] = []
	asked.assign(plan["question_ids"])
	if plan["warmup_id"] != "":
		asked.append(plan["warmup_id"])
	InterviewPlan.mark_seen(seen, asked)
	return asked


func _report(problems: Array[String]) -> void:
	assert_true(problems.is_empty(), "%d problem(s):\n  %s" % [problems.size(), "\n  ".join(PackedStringArray(problems))])


func _entry(tiers: Array, difficulty: int = 1, opener_only: bool = false) -> Dictionary:
	return {"tiers": tiers, "difficulty": difficulty, "opener_only": opener_only}


func test_pools_loaded() -> void:
	assert_gt(choice.size(), 0, "questions_choice.json parsed")
	assert_gt(knowledge.size(), 0, "questions_knowledge.json parsed")


func test_prompt_order_and_tier_filtering() -> void:
	var problems: Array[String] = []
	for tier: String in TIERS:
		for s: int in SEEDS:
			var seen: Array[String] = []
			var ids: Array = _pick(tier, seen, _rng(s + 1), false)["question_ids"]
			if ids.size() != cfg.prompt_pattern.size():
				problems.append("%s seed %d: %d ids" % [tier, s, ids.size()])
				continue
			for i: int in ids.size():
				var id: String = ids[i]
				var pool: Dictionary = choice if cfg.prompt_pattern[i] == "choice" else knowledge
				if not pool.has(id):
					problems.append("%s seed %d: slot %d (%s) got %s" % [tier, s, i, cfg.prompt_pattern[i], id])
				elif not (pool[id]["tiers"] as Array).has(tier):
					problems.append("%s seed %d: %s is not a %s question" % [tier, s, id, tier])
				if ids.count(id) > 1:
					problems.append("%s seed %d: %s twice in one interview" % [tier, s, id])
	_report(problems)


func test_eligible_filters_by_tier_list() -> void:
	var pool := {
		"_meta": {"tiers": ["mid"]}, "q_b": _entry(["big", "mid"]), "q_a": _entry(["mid"]),
		"q_s": _entry(["startup"]), "q_open": _entry(["mid"], 1, true), "q_text": "not an entry",
	}
	assert_eq(InterviewPlan.eligible(pool, "mid"), ["q_a", "q_b"] as Array[String], "mid: sorted, no metadata or opener")
	assert_eq(InterviewPlan.eligible(pool, "startup"), ["q_s"] as Array[String])
	assert_eq(InterviewPlan.eligible(pool, "big"), ["q_b"] as Array[String])
	assert_eq(InterviewPlan.eligible(choice, "startup").has("eq_rto"), false, "eq_rto is Big only")
	assert_eq(InterviewPlan.eligible(knowledge, "startup").has("kq_two_sum"), false, "kq_two_sum is Mid/Big only")


func test_opener_only_never_picked() -> void:
	for tier: String in TIERS:
		assert_false(InterviewPlan.eligible(choice, tier).has("eq_why_us"), "eq_why_us eligible at " + tier)
	var seen_ids: Array[String] = []
	var rng := _rng(7)
	for s: int in SEEDS:
		seen_ids.append_array(_interview(TIERS[s % 3], [] as Array[String], rng, true))
	assert_false(seen_ids.has("eq_why_us"), "eq_why_us picked")
	# Even a dry pool never falls back to an opener_only question.
	var pool := {"eq_open": _entry(["mid"], 1, true), "eq_a": _entry(["mid"]), "eq_b": _entry(["mid"])}
	var seen: Array[String] = ["eq_b", "eq_a"]
	var plan := InterviewPlan.pick(cfg, "mid", pool, {}, seen, _rng(1), false)
	assert_eq(plan["question_ids"], ["eq_b", "eq_a"] as Array[String], "fallback skips opener_only")


func test_no_repeats_across_consecutive_interviews() -> void:
	var runs: Array = [
		["startup", "startup", "startup", "startup", "startup"],
		["mid", "mid", "mid", "mid", "mid"],
		["big", "big", "big", "big", "big"],
		["startup", "mid", "big", "mid", "startup"],
	]
	var problems: Array[String] = []
	for tiers: Array in runs:
		for s: int in SEEDS:
			var rng := _rng(1000 + s)
			var seen: Array[String] = []
			var asked_before: Array[String] = []
			for n: int in tiers.size():
				for id: String in _interview(tiers[n], seen, rng, n == 0):
					if asked_before.has(id):
						problems.append("%s seed %d: %s repeated in interview %d" % [tiers, s, id, n + 1])
					asked_before.append(id)
			if seen.size() != asked_before.size():
				problems.append("%s seed %d: seen has %d ids for %d asked" % [tiers, s, seen.size(), asked_before.size()])
	_report(problems)


func test_warmup_only_on_first_interview_of_first_run() -> void:
	var run := RunState.new()
	assert_true(InterviewPlan.warmup_due(run), "fresh first run")
	run.interviews_taken = 1
	assert_false(InterviewPlan.warmup_due(run), "second interview of the first run")
	run.interviews_taken = 0
	run.first_run = false
	assert_false(InterviewPlan.warmup_due(run), "first interview of a later run")
	for tier: String in TIERS:
		assert_eq(_pick(tier, [] as Array[String], _rng(3), false)["warmup_id"], "", "no warm-up unless asked: " + tier)


func test_warmup_is_an_unpicked_difficulty_1_question() -> void:
	var problems: Array[String] = []
	for tier: String in TIERS:
		for s: int in SEEDS:
			var plan := _pick(tier, [] as Array[String], _rng(500 + s), true)
			var w: String = plan["warmup_id"]
			if not knowledge.has(w):
				problems.append("%s seed %d: warm-up '%s' is not a knowledge question" % [tier, s, w])
				continue
			if int(knowledge[w]["difficulty"]) != 1:
				problems.append("%s seed %d: warm-up %s has difficulty %s" % [tier, s, w, knowledge[w]["difficulty"]])
			if not (knowledge[w]["tiers"] as Array).has(tier):
				problems.append("%s seed %d: warm-up %s is not a %s question" % [tier, s, w, tier])
			if (plan["question_ids"] as Array).has(w):
				problems.append("%s seed %d: warm-up %s is also a prompt" % [tier, s, w])
	_report(problems)


func test_warmup_leaves_the_real_picks_unchanged() -> void:
	for tier: String in TIERS:
		var with_warmup := _pick(tier, [] as Array[String], _rng(42), true)
		var without := _pick(tier, [] as Array[String], _rng(42), false)
		assert_eq(with_warmup["question_ids"], without["question_ids"], "the warm-up is drawn last: " + tier)


func test_same_seed_same_picks() -> void:
	var distinct: Array = []
	for s: int in 10:
		var seen_a: Array[String] = ["kq_hash_map", "eq_friday_deploy"]
		var seen_b: Array[String] = ["kq_hash_map", "eq_friday_deploy"]
		var rng_a := _rng(900 + s)
		var rng_b := _rng(900 + s)
		var a := _pick("mid", seen_a, rng_a, true)
		var b := _pick("mid", seen_b, rng_b, true)
		assert_eq(a, b, "seed %d" % (900 + s))
		assert_eq(rng_a.state, rng_b.state, "same number of rolls, seed %d" % (900 + s))
		if not distinct.has(a):
			distinct.append(a)
	assert_gt(distinct.size(), 1, "different seeds give different interviews")


func test_dry_pool_falls_back_to_least_recently_seen() -> void:
	var choice_pool := {"eq_a": _entry(["mid"]), "eq_b": _entry(["mid"]), "eq_c": _entry(["mid"])}
	var knowledge_pool := {
		"kq_1": _entry(["mid"]), "kq_2": _entry(["mid"]), "kq_3": _entry(["mid"]), "kq_4": _entry(["mid"]),
	}
	# Every choice question seen: the two seen longest ago come back, oldest first.
	# One knowledge question unseen: it comes first, then the two seen longest ago.
	var seen: Array[String] = ["eq_c", "kq_3", "eq_a", "kq_1", "eq_b", "kq_2"]
	var plan := InterviewPlan.pick(cfg, "mid", choice_pool, knowledge_pool, seen, _rng(11), false)
	assert_eq(plan["question_ids"], ["eq_c", "kq_4", "kq_3", "kq_1", "eq_a"] as Array[String])
	InterviewPlan.mark_seen(seen, plan["question_ids"])
	assert_eq(seen, ["eq_b", "kq_2", "eq_c", "kq_4", "kq_3", "kq_1", "eq_a"] as Array[String], "asked ids move to the end")
	# The next interview draws the ones now seen longest ago.
	var next := InterviewPlan.pick(cfg, "mid", choice_pool, knowledge_pool, seen, _rng(12), false)
	assert_eq(next["question_ids"], ["eq_b", "kq_2", "kq_4", "kq_3", "eq_c"] as Array[String])


func test_tiny_pool_returns_what_it_has() -> void:
	var one_choice := {"eq_only": _entry(["startup"])}
	var knowledge_pool := {"kq_hard": _entry(["startup"], 3), "kq_mid": _entry(["startup"], 2)}
	var plan := InterviewPlan.pick(cfg, "startup", one_choice, knowledge_pool, [] as Array[String], _rng(5), true)
	var ids: Array = plan["question_ids"]
	assert_eq(ids.size(), 3, "1 choice + 2 knowledge")
	assert_eq(ids[0], "eq_only")
	assert_eq(plan["warmup_id"], "", "no knowledge question left for a warm-up")
	# The easiest remaining question is the warm-up, even without a difficulty-1 one.
	knowledge_pool["kq_easy"] = _entry(["startup"], 2)
	knowledge_pool["kq_hardest"] = _entry(["startup"], 3)
	knowledge_pool["kq_other"] = _entry(["startup"], 3)
	var bigger := InterviewPlan.pick(cfg, "startup", one_choice, knowledge_pool, [] as Array[String], _rng(5), true)
	var w: String = bigger["warmup_id"]
	assert_ne(w, "", "a warm-up exists")
	assert_false((bigger["question_ids"] as Array).has(w), "the warm-up is not also a prompt")
	var remaining_difficulties: Array[int] = []
	for id: String in knowledge_pool:
		if not (bigger["question_ids"] as Array).has(id):
			remaining_difficulties.append(int(knowledge_pool[id]["difficulty"]))
	assert_eq(int(knowledge_pool[w]["difficulty"]), remaining_difficulties.min(), "the warm-up is the easiest left")

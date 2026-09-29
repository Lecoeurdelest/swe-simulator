@tool
extends McpTestSuite
## GDD 5.9.5, S11, S12: the Dream vs Reality rows the Hired card tallies (Odds.dream_breakdown, whose
## rounded sum is Odds.dream_score) and its grade, the job RunState.hire() records, and the Plan B
## card's tip and texts. Pure: the .tres and the JSON read with FileAccess, never user:// or an
## autoload (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
const BG_IDS: PackedStringArray = ["intern", "graduate", "self_taught"]

var cfg: BalanceConfig
var bgs: Dictionary = {}
var tiers: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "endings"


func suite_setup(_ctx: Dictionary) -> void:
	for id: String in BG_IDS:
		bgs[id] = load("res://data/backgrounds/%s.tres" % id)
	for id: String in TIER_IDS:
		tiers[id] = load("res://data/tiers/%s.tres" % id)
	for file: String in ["postings", "companies", "cv_lines", "emails", "endings", "backgrounds", "tips"]:
		content[file] = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/%s.json" % file))


func setup() -> void:
	cfg = BalanceConfig.new()


func _sum(parts: Array[float]) -> float:
	var total := 0.0
	for part: float in parts:
		total += part
	return total


## GDD 5.9.5's three worked examples, row by row (one decimal, as the GDD and the card show them),
## with their grades: 68 "Pretty good", 57 and 49 "Doable".
func test_breakdown_matches_the_gdd_examples() -> void:
	var examples := [
		{"name": "Intern at Hierarchai", "args": [71000, 0, 20, 2, 13, 15], "rows": [18.9, 25.0, 15.0, 0.0, 8.7], "score": 68, "grade": 3},
		{"name": "Intern at OmniGlobal", "args": [126000, 4, 20, 2, 11, 15], "rows": [33.6, 5.0, 11.0, 0.0, 7.3], "score": 57, "grade": 2},
		{"name": "Self-Taught at Beigeware", "args": [72000, 2, 95, 1, 5, 12], "rows": [19.2, 15.0, 5.5, 5.0, 4.2], "score": 49, "grade": 2},
	]
	for example: Dictionary in examples:
		var a: Array = example["args"]
		var parts := Odds.dream_breakdown(cfg, a[0], a[1], a[2], a[3], a[4], a[5])
		assert_eq(parts.size(), Odds.DREAM_ROWS.size(), "one part per row")
		for i: int in parts.size():
			assert_eq("%.1f" % parts[i], "%.1f" % float(example["rows"][i]), "%s: %s" % [example["name"], Odds.DREAM_ROWS[i]])
		assert_eq(roundi(_sum(parts)), example["score"], "%s: the rounded sum" % example["name"])
		assert_eq(Odds.dream_score(cfg, a[0], a[1], a[2], a[3], a[4], a[5]), example["score"], "%s: dream_score" % example["name"])
		assert_eq(Odds.dream_grade(example["score"]), example["grade"], "%s: the grade" % example["name"])


## Over a sweep of offers the rounded sum of the rows is dream_score, and every row stays between 0
## and its weight (GDD 11.6: 40 / 25 / 15 / 10 / 10).
func test_breakdown_always_rounds_to_the_score() -> void:
	var weights := [cfg.dream_w_salary, cfg.dream_w_remote, cfg.dream_w_commute, cfg.dream_w_flags, cfg.dream_w_runway]
	var checked := 0
	var mismatches: Array[String] = []
	for salary: int in [0, 45000, 71000, 84000, 106000, 150000, 190000]:
		for office_days: int in range(0, 6):
			for commute: int in [0, 20, 45, 95]:
				for flags: int in range(0, 4):
					for runway: int in [12, 15]:
						for rent: int in range(0, runway + 1):
							var parts := Odds.dream_breakdown(cfg, salary, office_days, commute, flags, rent, runway)
							var score := Odds.dream_score(cfg, salary, office_days, commute, flags, rent, runway)
							checked += 1
							if roundi(_sum(parts)) != score:
								mismatches.append("sum %s" % [[salary, office_days, commute, flags, rent, runway]])
							for i: int in parts.size():
								if parts[i] < 0.0 or parts[i] > weights[i] + 0.0001:
									mismatches.append("row %d %s" % [i, [salary, office_days, commute, flags, rent, runway]])
	assert_gt(checked, 10000, "the sweep ran")
	assert_true(mismatches.is_empty(), "every offer: rows within their weights, rounded sum = dream_score; first misses: %s" % [mismatches.slice(0, 5)])


## GDD 5.9.5: <40 Reality, 40-59 Doable, 60-79 Pretty good, 80+ Suspiciously close to the video.
func test_grade_bands() -> void:
	var expected := {0: 1, 39: 1, 40: 2, 59: 2, 60: 3, 79: 3, 80: 4, 100: 4}
	for score: int in expected:
		assert_eq(Odds.dream_grade(score), expected[score], "score %d" % score)
	var endings: Dictionary = content["endings"]
	for grade: int in range(1, 5):
		assert_has_key(endings, "end_dream_grade_%d" % grade)
	for row: String in Odds.DREAM_ROWS:
		assert_has_key(endings, "end_dream_row_" + row)


## GDD 5.9.4-5.9.5, 10.4: Accept makes the offer the job, adds the company's red flags, and scores it;
## the card's rows come from the same numbers, and it all stays plain data through a save.
func test_hire_records_the_job_and_its_score() -> void:
	var run := RunState.new()
	run.set_background(cfg, bgs["self_taught"])
	run.interview = {"invite_uid": 5, "company_id": "co_beigeware", "template_id": "job_mid_backend",
		"tier": "mid", "seed": "42", "question_ids": [], "warmup_id": "", "tired": false}
	run.make_offer(cfg, tiers["mid"], bgs["self_taught"], content, 30.0)
	run.rent_days_left = 5
	var offer := run.offer.duplicate(true)
	var flags: Array = content["companies"]["co_beigeware"]["red_flags"]
	run.hire(cfg, bgs["self_taught"], flags)
	assert_eq(run.offer, offer, "the offer is left as it was")
	for key: String in offer:
		assert_eq(run.employment[key], offer[key], "employment keeps the offer's " + key)
	assert_eq(run.employment["red_flags"], flags, "GDD 10.4: the company's red flags")
	assert_eq(run.dream_score, Odds.dream_score(cfg, offer["salary"], 2, 95, flags.size(), 5, 12), "scored at Accept")
	var parts := run.dream_breakdown(cfg, bgs["self_taught"])
	assert_eq(roundi(_sum(parts)), run.dream_score, "the card's rows add up to the score")
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(back.employment, run.employment, "plain data (INV-07)")
	assert_eq(back.dream_breakdown(cfg, bgs["self_taught"]), parts, "the same rows after a round trip")


## Every tier has its hired line, and the texts both ending cards show exist.
func test_ending_texts_exist() -> void:
	var endings: Dictionary = content["endings"]
	for tier_id: String in TIER_IDS:
		assert_has_key(endings, "end_hired_" + tier_id)
	for id: String in ["end_hired_title", "end_dream_header", "end_dream_footer", "end_tbc",
			"end_plan_b_title", "end_plan_b", "end_plan_b_final", "end_stats"]:
		assert_has_key(endings, id)
	for placeholder: String in ["{day}", "{n}", "{i}", "{r}"]:
		assert_contains(str(endings["end_stats"]), placeholder)
	for bg_id: String in BG_IDS:
		assert_true(str(content["backgrounds"][bg_id].get("plan_b_line", "")) != "", bg_id + " has a Plan B line")
	for tip_id: String in ["tip_written_offer", "tip_tailor_over_spray", "tip_rejection_numbers"]:
		assert_has_key(content["tips"], tip_id)


## GDD S12, 8.1 rule 4: the Plan B tip matches the cause. No invite all run -> tailoring; invites
## that led nowhere -> many rejections are normal.
func test_plan_b_tip_matches_the_cause() -> void:
	var run := RunState.new()
	assert_eq(HuntTips.plan_b(run), "tip_tailor_over_spray", "nobody replied")
	run.applications.append({"uid": 1, "status": "rejected", "tailored": false})
	assert_eq(HuntTips.plan_b(run), "tip_tailor_over_spray", "only rejections")
	run.applications.append({"uid": 2, "status": "expired", "tailored": true})
	assert_eq(HuntTips.plan_b(run), "tip_rejection_numbers", "an invite came and went")
	var interviewed := RunState.new()
	interviewed.interviews_taken = 2
	assert_eq(HuntTips.plan_b(interviewed), "tip_rejection_numbers", "interviews without a job")

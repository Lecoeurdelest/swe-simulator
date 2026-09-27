@tool
extends McpTestSuite
## The lie probe (GDD 5.8.5): the bluff odds band on the Bluff button, the degree-claim weight, and what
## Come clean and BUSTED leave in the run. Pure: BalanceConfig/TierData defaults, no autoloads (INV-12).

var cfg: BalanceConfig
var mid: TierData


func suite_name() -> String:
	return "lie_probe"


func setup() -> void:
	cfg = BalanceConfig.new()
	mid = TierData.new()  # defaults are Mid (bluff_detect 0.05)
	mid.id = &"mid"


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


func test_degree_claim_weighs_more() -> void:
	_near(Odds.bluff_p(cfg, mid, 50, 40, true), 0.35, 0.001, "Intern, degree claim: 0.10 below a normal lie")
	_near(Odds.bluff_p(cfg, mid, 0, 0, true), cfg.bluff_min, 0.0001, "clamped at bluff_min")
	_near(Odds.bluff_p(cfg, mid, 100, 100, false), cfg.bluff_max, 0.0001, "clamped at bluff_max")


func test_bluff_band_words() -> void:
	assert_eq(Odds.bluff_band(cfg, cfg.bluff_min), 1, "10%: Long shot")
	assert_eq(Odds.bluff_band(cfg, 0.325), 2, "Self-Taught at Mid: Unlikely")
	assert_eq(Odds.bluff_band(cfg, 0.35), 2, "Graduate at Mid: Unlikely")
	assert_eq(Odds.bluff_band(cfg, 0.45), 3, "Intern at Mid (GDD 5.8.5 example): Possible")
	assert_eq(Odds.bluff_band(cfg, 0.60), 4, "Decent")
	assert_eq(Odds.bluff_band(cfg, cfg.bluff_max), 5, "the cap: Good")
	var last := 1
	for i: int in 71:
		var band := Odds.bluff_band(cfg, 0.10 + i / 100.0)
		assert_true(band >= last and band <= 5, "band %d at %d%% (never falls as the odds rise)" % [band, 10 + i])
		last = band


func test_coming_clean_beats_bluffing_on_average() -> void:
	var p := Odds.bluff_p(cfg, mid, 50, 40, false)
	var bluff_doubt := p * cfg.bluff_win_doubt + (1.0 - p) * cfg.busted_doubt
	_near(bluff_doubt, 4.25, 0.001, "GDD 5.8.5: bluffing moves Doubt by about +4.3 on average")
	assert_gt(bluff_doubt, cfg.come_clean_doubt, "coming clean (-5) is the better play on average")


func test_come_clean_marks_the_line_confessed_for_that_company() -> void:
	var run := RunState.new()
	run.lies_carried.assign(["cv_intern_edu_lie", "cv_intern_proj_lie"])
	run.settle_probe("co_hierarchai", "cv_intern_edu_lie", true, false)
	assert_eq(run.confessed, ["co_hierarchai|cv_intern_edu_lie"] as Array[String], "company|line")
	assert_eq(run.lies_carried, ["cv_intern_proj_lie"] as Array[String], "no longer carried")
	run.settle_probe("co_hierarchai", "cv_intern_edu_lie", true, false)
	assert_eq(run.confessed.size(), 1, "confessing twice records it once")


func test_busted_and_bluff_win_leave_no_confession() -> void:
	var run := RunState.new()
	run.lies_carried.assign(["cv_intern_exp_lie"])
	run.settle_probe("co_beigeware", "cv_intern_exp_lie", false, false)
	assert_true(run.confessed.is_empty(), "a bluff that holds confesses nothing")
	assert_eq(run.lies_carried, ["cv_intern_exp_lie"] as Array[String], "and you still carry the lie")
	run.settle_probe("co_beigeware", "cv_intern_exp_lie", false, true)
	assert_true(run.confessed.is_empty(), "BUSTED is not a confession")
	assert_true(run.lies_carried.is_empty(), "a busted lie is no longer carried")
	run.settle_probe("co_beigeware", "", true, false)
	assert_true(run.confessed.is_empty(), "no probe, nothing to settle")

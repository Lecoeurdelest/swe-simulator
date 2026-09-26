@tool
extends McpTestSuite
## GDD 5.8.7 worked example (Intern vs Dana at Hierarchai) with the luck values fixed, plus bluff and Tired.

var cfg: BalanceConfig
var startup: TierData
var mid: TierData
var intern: BackgroundData


func suite_name() -> String:
	return "interview"


func setup() -> void:
	cfg = BalanceConfig.new()
	startup = TierData.new()
	startup.id = &"startup"
	startup.doubt_hp = 118
	startup.tier_difficulty = 40
	mid = TierData.new()  # defaults are Mid
	mid.id = &"mid"
	intern = BackgroundData.new()
	intern.start_knw = 50
	intern.start_exp = 40
	intern.start_net = 45
	intern.teamwork_mult = 1.25
	intern.teamwork_mult_after_network = 1.25
	intern.startup_exp_bonus = 0


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.3f, got %.3f" % [what, expected, actual])


func test_worked_example_5_8_7() -> void:
	var doubt := float(startup.doubt_hp)
	var composure := 100.0
	# 1. eq_credit_theft (teamwork), Intern exclusive good answer
	doubt += Odds.ethics_doubt_delta(cfg, &"good", true, Odds.teamwork_mult(intern, false))
	_near(doubt, 105.5, 0.01, "after prompt 1")
	# 2. kq_hash_map: difficulty 1, not weak, luck +3, PERFECT
	var p := Odds.knowledge_p(cfg, startup, intern, 50, 40, true, false)
	_near(p, 47.0, 0.001, "P tech")
	var s := Odds.stat_score(cfg, startup, p, 1, 3.0)
	_near(s, 61.4, 0.01, "S")
	_near(Odds.zone_half(cfg, s), 0.134, 0.001, "h")
	var q := Odds.answer_q(cfg, s, cfg.input_perfect)
	_near(q, 71.05, 0.01, "Q")
	assert_eq(Odds.spoken_grade(cfg, q), &"green")
	doubt += Odds.knowledge_doubt_delta(cfg, q)
	_near(doubt, 68.56, 0.01, "after prompt 2")
	# 3. kq_deadlock: difficulty 3, weak_for intern, luck -5, GOOD
	s = Odds.stat_score(cfg, startup, Odds.knowledge_p(cfg, startup, intern, 50, 40, true, true), 3, -5.0)
	_near(s, 35.9, 0.01, "S weak")
	q = Odds.answer_q(cfg, s, cfg.input_good)
	assert_eq(Odds.spoken_grade(cfg, q), &"yellow")
	doubt += Odds.knowledge_doubt_delta(cfg, q)
	composure -= Odds.knowledge_composure_loss(cfg, q)
	_near(composure, 96.93, 0.01, "composure after prompt 3")
	# 4. kq_estimate: behavioral, difficulty 2, luck +6, GOOD
	s = Odds.stat_score(cfg, startup, Odds.knowledge_p(cfg, startup, intern, 50, 40, false, false), 2, 6.0)
	_near(s, 58.1, 0.01, "S behavioral")
	doubt += Odds.knowledge_doubt_delta(cfg, Odds.answer_q(cfg, s, cfg.input_good))
	# 5. eq_any_questions, good (not teamwork)
	doubt += Odds.ethics_doubt_delta(cfg, &"good", false, 1.0)
	_near(doubt, 13.1, 0.05, "Doubt after 5 prompts (GDD rounds to 13.2)")
	# 6. committee wheel
	assert_true(Odds.committee_eligible(cfg, doubt, startup.doubt_hp))
	_near(Odds.committee_win_p(cfg, doubt, startup.doubt_hp, 45), 0.68, 0.01, "wheel P_win")


func test_bluff_odds_by_background_at_mid() -> void:
	_near(Odds.bluff_p(cfg, mid, 50, 40, false), 0.45, 0.001, "Intern")
	_near(Odds.bluff_p(cfg, mid, 55, 15, false), 0.35, 0.001, "Graduate")
	_near(Odds.bluff_p(cfg, mid, 55, 10, false), 0.325, 0.001, "Self-Taught")


func test_tired_rule() -> void:
	assert_true(Odds.is_tired(cfg, 6 - 3 - 1), "Self-Taught in person: 6 - 3 - 1 = 2 pips left")
	assert_false(Odds.is_tired(cfg, 9 - 3))
	_near(Odds.needle_speed(cfg, mid, true), 0.69, 0.0001, "Tired needle")


func test_input_quality_bands() -> void:
	assert_eq(Odds.input_quality(cfg, 0.50, 0.50, 0.1), cfg.input_perfect)
	assert_eq(Odds.input_quality(cfg, 0.58, 0.50, 0.1), cfg.input_good)
	assert_eq(Odds.input_quality(cfg, 0.65, 0.50, 0.1), cfg.input_close)
	assert_eq(Odds.input_quality(cfg, 0.90, 0.50, 0.1), cfg.input_miss)

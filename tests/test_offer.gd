@tool
extends McpTestSuite
## GDD 5.9: salary, negotiation, Dream vs Reality examples.

var cfg: BalanceConfig


func suite_name() -> String:
	return "offer"


func setup() -> void:
	cfg = BalanceConfig.new()


func test_salary_example() -> void:
	var startup := TierData.new()
	startup.salary_min_k = 50
	startup.salary_max_k = 70
	var intern := BackgroundData.new()
	intern.salary_mult = 1.10
	assert_eq(Odds.offer_salary(cfg, startup, intern, 96.925, 100.0), 71000)


func test_negotiation_odds() -> void:
	assert_true(absf(Odds.negotiate_p(cfg, 45, false) - 0.775) < 0.0001, "Intern")
	assert_true(absf(Odds.negotiate_p(cfg, 15, false) - 0.625) < 0.0001, "Graduate")
	assert_true(absf(Odds.negotiate_p(cfg, 45, true) - 0.85) < 0.0001, "capped at 85%")


func test_dream_score_examples() -> void:
	assert_eq(Odds.dream_score(cfg, 71000, 0, 20, 2, 13, 15), 68, "Intern at Hierarchai")
	assert_eq(Odds.dream_score(cfg, 126000, 4, 20, 2, 11, 15), 57, "Intern at OmniGlobal")
	assert_eq(Odds.dream_score(cfg, 72000, 2, 95, 1, 5, 12), 49, "Self-Taught at Beigeware")

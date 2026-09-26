@tool
extends McpTestSuite
## Job-hunt formulas (GDD 5.6). Fixtures are built in code, so tuning the .tres files never breaks these;
## BalanceConfig.new() carries the GDD section 11 defaults.

var cfg: BalanceConfig


func suite_name() -> String:
	return "odds"


func setup() -> void:
	cfg = BalanceConfig.new()


func _tier(id: StringName, base_invite: float) -> TierData:
	var t := TierData.new()
	t.id = id
	t.base_invite = base_invite
	return t


func _bg(big: float, mid: float, startup: float) -> BackgroundData:
	var b := BackgroundData.new()
	b.invite_mult_big = big
	b.invite_mult_mid = mid
	b.invite_mult_startup = startup
	return b


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


func test_example_1_graduate_mid_backend_tailored() -> void:
	var p := Odds.p_invite(cfg, _tier(&"mid", 0.065), _bg(1.2, 1.0, 1.0), 3, true, 15, false)
	_near(p, 0.168, 0.0005, "Graduate, Mid, Tailor, M = 3/3")
	assert_eq(Odds.odds_band(cfg, p), 4, "16.8% shows as [####-] Decent")


func test_example_2_self_taught_startup_quick_vs_tailored() -> void:
	var tier := _tier(&"startup", 0.10)
	var bg := _bg(1.0, 1.0, 1.3)
	_near(Odds.p_invite(cfg, tier, bg, 3, false, 5, false), 0.123, 0.0005, "Quick Apply")
	_near(Odds.p_invite(cfg, tier, bg, 3, true, 5, false), 0.307, 0.0005, "Tailor & Apply")


func test_example_3_intern_big_referral() -> void:
	_near(Odds.p_invite(cfg, _tier(&"big", 0.03), _bg(1.0, 1.0, 0.8), 2, true, 45, true), 0.190, 0.0005, "Intern, Big, referral")


func test_p_invite_is_clamped() -> void:
	_near(Odds.p_invite(cfg, _tier(&"startup", 0.10), _bg(1.0, 1.0, 1.3), 3, true, 80, true), cfg.p_invite_max, 0.0001, "cap")
	_near(Odds.p_invite(cfg, _tier(&"big", 0.03), _bg(1.0, 1.0, 1.0), 0, false, 0, false), cfg.p_invite_min, 0.0001, "floor")


func test_odds_bands() -> void:
	assert_eq(Odds.odds_band(cfg, 0.02), 1, "Long shot")
	assert_eq(Odds.odds_band(cfg, 0.05), 2, "Unlikely")
	assert_eq(Odds.odds_band(cfg, 0.10), 3, "Possible")
	assert_eq(Odds.odds_band(cfg, 0.15), 4, "Decent")
	assert_eq(Odds.odds_band(cfg, 0.30), 5, "Good")


func test_knockouts() -> void:
	# Graduate, Mid "Backend Developer" (1+ years): Honest Experience fails, Polished passes.
	assert_true(Odds.is_knockout(false, 1, true, false, false), "Quick Apply with Honest TA line")
	assert_false(Odds.is_knockout(false, 1, true, true, false), "Tailor sends Polished: passes")
	# Self-Taught vs a degree-required Big posting: knocked out unless a referral is used.
	assert_true(Odds.is_knockout(true, 0, false, true, false))
	assert_false(Odds.is_knockout(true, 5, false, false, true), "a referral skips knockouts")


func test_relevance_needs_two_matching_tags() -> void:
	var tags_sent := PackedStringArray(["java", "python", "sql", "git"])
	assert_eq(Odds.tag_hits(PackedStringArray(["java", "sql", "apis"]), tags_sent), 2)
	assert_true(Odds.is_relevant(cfg, 2))
	assert_false(Odds.is_relevant(cfg, 1))


func test_same_seed_same_rolls() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 42
	b.seed = 42
	var ra: Array[bool] = []
	var rb: Array[bool] = []
	for _i: int in 50:
		ra.append(Odds.roll(a, 0.3))
		rb.append(Odds.roll(b, 0.3))
	assert_eq(ra, rb)
	assert_eq(Odds.pick(a, ["x", "y", "z"], 2), Odds.pick(b, ["x", "y", "z"], 2))

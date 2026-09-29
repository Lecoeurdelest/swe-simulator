@tool
extends McpTestSuite
## Smoke simulation of day 1 -> the morning of day 2 on a Medium (Graduate) first run, driving the real
## RunState rules (ROADMAP Step 5 Done-when: "an invite arrives on the morning of day 2").
## In deck order, the bot tailors when 2+ tags match and Quick Applies otherwise (like the GDD 5.12 bot).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
const RUNS := 200
const BUDGET_MS := 5000

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_sim"


func suite_setup(_ctx: Dictionary) -> void:
	for id: String in TIER_IDS:
		tiers[id] = load("res://data/tiers/%s.tres" % id)
	for id: String in ["intern", "graduate", "self_taught"]:
		bgs[id] = load("res://data/backgrounds/%s.tres" % id)
	for file: String in ["postings", "companies", "cv_lines"]:
		content[file] = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/%s.json" % file))


func setup() -> void:
	cfg = BalanceConfig.new()


## Day 1 of a fresh first run, then Sleep. Returns the morning-of-day-2 report.
func _first_morning(bg_id: String, seed_value: int, max_apps: int) -> Dictionary:
	var bg: BackgroundData = bgs[bg_id]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var run := RunState.new()
	run.set_background(cfg, bg)
	run.first_run = true
	run.deal_board(cfg, tiers, content, rng)
	var sent := 0
	while not run.board.is_empty() and run.energy >= cfg.cost_quick_apply and sent < max_apps:
		var card: Dictionary = run.board[0]
		var odds := run.card_odds(cfg, tiers, bg, content, card)
		var tailor := int(odds["tailored"]["hits"]) >= 2 and run.energy >= cfg.cost_tailor_apply
		if run.apply_card(cfg, tiers, bg, content, int(card["uid"]), tailor, false).is_empty():
			break
		sent += 1
	return run.sleep(cfg, tiers, bg, content, rng)


func test_medium_first_run_always_has_an_invite_on_the_morning_of_day_2() -> void:
	var started := Time.get_ticks_msec()
	var with_invite := 0
	var rolled := 0
	var guaranteed := 0
	for seed_value: int in range(1, RUNS + 1):
		var report := _first_morning("graduate", seed_value, 99)  # spends all 8 energy: 4+ applications
		if not (report["invites"] as Array).is_empty():
			with_invite += 1
		if report["guarantee"] == "":
			rolled += 1
		else:
			guaranteed += 1
	var elapsed := Time.get_ticks_msec() - started
	assert_eq(with_invite, RUNS, "the day-2 guarantee: 100% of first runs")
	assert_gt(rolled, 0, "some invites are rolled or Radar ones (%d)" % rolled)
	assert_gt(guaranteed, 0, "some need the guarantee (%d)" % guaranteed)
	assert_true(elapsed < BUDGET_MS, "%d runs took %d ms" % [RUNS, elapsed])


func test_two_applications_on_day_1_are_below_the_guarantee() -> void:
	for seed_value: int in range(1, 51):
		var report := _first_morning("graduate", seed_value, 2)
		assert_eq(report["guarantee"], "", "2 < day2_guarantee_min_apps: no guarantee (seed %d)" % seed_value)

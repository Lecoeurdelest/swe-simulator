@tool
extends McpTestSuite
## The harness's small version inside test_run (ARCHITECTURE 19.6, DECISIONS A56): a few dozen careers per bot through
## HarnessRunner, asserting only what must always hold: no crash, no run left hanging, no input the sim refused,
## every ending a known one, determinism, and the loose bands the GDD gives the weaker bots. The real balance numbers
## (10,000 seeds, the Planner's band) come from tools/headless/run_bots.sh, not from here.

const SEEDS := 60
const ENDINGS: PackedStringArray = ["studio", "plan_b", "burnout", "career_change", "legacy"]

var _ctx: SimContext
var _duel: DuelModel


func suite_name() -> String:
	return "sim_smoke"


func suite_setup(_ctx_arg: Dictionary) -> void:
	_ctx = SimContext.load_default()
	_ctx.log_enabled = false
	_duel = DuelModel.load_default()


func _play(bot_name: String, run_number: int = 1) -> Dictionary:
	return HarnessRunner.play(bot_name, HarnessRunner.make_bot(bot_name), _ctx, _duel, 1, SEEDS, run_number, [])


func _check_clean(report: Dictionary) -> void:
	var bot: String = report["bot"]
	assert_eq(report["guard_hits"], 0, "%s: every run reached an ending" % bot)
	assert_eq(report["rejected_inputs"], 0, "%s: the sim refused none of its inputs" % bot)
	for ending: String in report["endings"]:
		assert_true(ending in ENDINGS, "%s: '%s' is a known ending" % [bot, ending])
	assert_true(int(report["p90_day"]) <= 2160, "%s: no run outlasts the Legacy System day" % bot)
	assert_eq(int(report["runs"]), SEEDS)


func test_the_planner_plays_clean_careers() -> void:
	var report := _play("planner")
	_check_clean(report)
	assert_true(float(report["jobs_mean"]) >= 1.0, "it holds at least the first job")


func test_the_coaster_never_wins_and_loses_early() -> void:  # O2, AC-S14-7: no wins, a median loss before day 1,800
	var report := _play("coaster")
	_check_clean(report)
	assert_eq(report["wins"], 0, "standing still never wins")
	assert_true(int(report["median_loss_day"]) < 1800, "median loss on day %d" % report["median_loss_day"])


func test_the_grinder_plays_clean_careers() -> void:
	var report := _play("grinder")
	_check_clean(report)
	assert_true(float(report["win_rate"]) < 0.10, "a Grinder rarely wins (loose band: the target is under 2%)")


func test_the_lifestyle_bot_plays_clean_careers() -> void:
	_check_clean(_play("lifestyle"))


func test_the_random_bot_plays_clean_careers_and_rarely_wins() -> void:
	var report := _play("random")
	_check_clean(report)
	assert_true(float(report["win_rate"]) < 0.05, "a Random bot barely ever wins (loose band: the target is under 1%)")


func test_a_career_that_starts_between_jobs_plays_clean_too() -> void:  # run 2: the board is open from day 0
	for bot_name: String in ["planner", "grinder"]:
		_check_clean(_play(bot_name, 2))


func test_two_plays_of_the_same_seeds_report_the_same_numbers() -> void:  # R-CLK, determinism through the whole harness
	for bot_name: String in ["planner", "random"]:
		var a := _play(bot_name)
		var b := _play(bot_name)
		for key: String in ["wins", "endings", "median_day", "p10_day", "p90_day", "jobs_mean", "stats_per_run", "level_at_end"]:
			assert_eq(JSON.stringify(a[key]), JSON.stringify(b[key]), "%s: %s" % [bot_name, key])


func test_the_harness_reports_its_speed() -> void:  # AC-S14-1: the time per run goes in the evidence
	var report := _play("planner")
	assert_true(float(report["ms_per_run"]) > 0.0)
	assert_true(float(report["ms_per_run"]) < 200.0, "%.1f ms a run: 10,000 seeds would take %.0f s" % [report["ms_per_run"], float(report["ms_per_run"]) * 10.0])

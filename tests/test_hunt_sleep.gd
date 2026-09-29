@tool
extends McpTestSuite
## Sleep as ONE committed action (ARCHITECTURE 7.1): night tick + morning reveal + board refill in
## morning_report, the report surviving a save, kill-after-Sleep replays, Plan B and the grace day
## (GDD 5.10). Saves go through JSON strings only, never user:// (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
const REPORT_KEYS: PackedStringArray = [
	"day", "night", "invites", "rejections", "no_reply", "ghosted", "expired", "radar",
	"guarantee", "board_new", "grace_day", "plan_b", "rent_days_left",
]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_sleep"


func suite_setup(_ctx: Dictionary) -> void:
	for id: String in TIER_IDS:
		tiers[id] = load("res://data/tiers/%s.tres" % id)
	for id: String in ["intern", "graduate", "self_taught"]:
		bgs[id] = load("res://data/backgrounds/%s.tres" % id)
	for file: String in ["postings", "companies", "cv_lines"]:
		content[file] = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/%s.json" % file))


func setup() -> void:
	cfg = BalanceConfig.new()


func _run(bg_id: String) -> RunState:
	var run := RunState.new()
	run.set_background(cfg, bgs[bg_id])
	run.first_run = false
	return run


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _sleep(run: RunState, rng: RandomNumberGenerator) -> Dictionary:
	return run.sleep(cfg, tiers, bgs[run.background_id], content, rng)


## Deck order: Tailor & Apply when 2+ tags match, else Quick Apply, until max_apps are sent.
func _apply_some(run: RunState, max_apps: int) -> void:
	var bg: BackgroundData = bgs[run.background_id]
	for _i: int in max_apps:
		if run.board.is_empty():
			return
		var card: Dictionary = run.board[0]
		var odds := run.card_odds(cfg, tiers, bg, content, card)
		var tailor := int(odds["tailored"]["hits"]) >= 2 and run.energy >= cfg.cost_tailor_apply
		run.apply_card(cfg, tiers, bg, content, int(card["uid"]), tailor, false)


## An application sent today with a chosen P, as apply_card would record it.
func _app(run: RunState, tier_id: String, p: float, knockout: bool = false, ghost: bool = false) -> Dictionary:
	var app := {
		"uid": run.new_uid(), "template_id": "job_mid_backend", "company_id": "co_beigeware",
		"tier": tier_id, "day_sent": run.day,
		"reveal_day": Odds.reply_day(cfg, tiers[tier_id], run.day, knockout),
		"p": p, "hits": 2, "relevant": true, "knockout": knockout,
		"knockout_reason": {"id": "knock_years", "args": {"n": 1}} if knockout else {},
		"is_ghost": ghost, "referral": false, "tailored": true, "status": "pending",
	}
	run.applications.append(app)
	return app


## What GameState._commit() writes: the run, with the RNG state stored as a string (INV-05).
func _save(run: RunState, rng: RandomNumberGenerator) -> String:
	run.rng_seed = str(rng.seed)
	run.rng_state = str(rng.state)
	return JSON.stringify(run.to_dict(), "\t")


## What GameState.continue_game() does: from_dict, then the seed, then the state.
func _load(json: String) -> Array:
	var run := RunState.from_dict(JSON.parse_string(json))
	var rng := RandomNumberGenerator.new()
	rng.seed = run.rng_seed.to_int()
	rng.state = run.rng_state.to_int()
	return [run, rng]


func test_sleep_is_one_action_night_tick_plus_morning() -> void:
	var run := _run("graduate")
	var rng := _rng(21)
	run.deal_board(cfg, tiers, content, rng)
	_apply_some(run, 2)
	run.interviews_today = 1
	var report := _sleep(run, rng)
	assert_eq(run.day, 2)
	assert_eq(run.rent_days_left, 11)
	assert_eq(run.energy, 8, "10 - 2 commute pips")
	assert_eq(run.interviews_today, 0)
	assert_eq(run.morning_report, report, "stored on the run")
	for key: String in REPORT_KEYS:
		assert_has_key(report, key)
	assert_eq(report["day"], 2)
	assert_eq(report["board_new"], 6)
	assert_eq(run.board.size(), 10, "4 left + 6 new")
	assert_eq(report["night"], {"applied": 2, "rejected": (report["rejections"] as Array).size(),
		"ghosted": 0, "rent_days_left": 11})
	assert_false(report["plan_b"])


func test_the_step1_form_is_the_night_tick_alone() -> void:
	var run := _run("graduate")
	run.energy = 0
	assert_eq(run.sleep(cfg), {})
	assert_eq([run.day, run.rent_days_left, run.energy], [2, 11, 8])
	assert_true(run.morning_report.is_empty(), "no reveal without tiers, bg, content and rng")


func test_the_report_survives_a_save() -> void:
	var run := _run("graduate")
	var rng := _rng(22)
	run.deal_board(cfg, tiers, content, rng)
	_app(run, "startup", 1.0)
	_app(run, "mid", 0.5, true)
	_app(run, "startup", 1.0, false, true)
	var report := _sleep(run, rng)
	assert_eq((report["invites"] as Array).size(), 1)
	assert_eq((report["rejections"] as Array).size(), 1)
	assert_eq(report["no_reply"], 1)
	var back: RunState = _load(_save(run, rng))[0]
	assert_eq(back.morning_report, report, "the same morning after a reload")
	assert_eq(typeof(back.morning_report["day"]), TYPE_INT, "ints stay ints")
	assert_eq(typeof(back.morning_report["rejections"][0]["knockout"]["args"]["n"]), TYPE_INT)
	assert_eq(back.invites, run.invites)


func test_a_kill_after_sleep_shows_the_same_morning() -> void:
	var run := _run("graduate")
	run.first_run = true
	var rng := _rng(23)
	run.deal_board(cfg, tiers, content, rng)
	_apply_some(run, 4)
	var before_sleep := _save(run, rng)
	var report := _sleep(run, rng)
	var after_sleep := _save(run, rng)
	# Killed after Sleep's commit: Continue shows the stored morning.
	var resumed: RunState = _load(after_sleep)[0]
	assert_eq(resumed.morning_report, report)
	# Killed before the commit landed: Continue reloads the evening and Sleep replays the same dice.
	var evening: Array = _load(before_sleep)
	var replayed: RunState = evening[0]
	assert_eq(replayed.sleep(cfg, tiers, bgs["graduate"], content, evening[1]), report, "the same reveal, never a re-roll")
	assert_eq(_save(replayed, evening[1]), after_sleep, "the whole run matches")


func test_plan_b_when_rent_runs_out_with_no_invite() -> void:
	var run := _run("graduate")
	run.rent_days_left = 1
	var report := _sleep(run, _rng(24))
	assert_eq(run.rent_days_left, 0)
	assert_true(report["plan_b"])
	assert_false(report["grace_day"])
	assert_eq(report["rent_days_left"], 0)


func test_a_waiting_invite_buys_one_grace_day() -> void:
	var run := _run("graduate")
	run.rent_days_left = 1
	run.invites.append({"uid": run.new_uid(), "app_uid": 99, "company_id": "co_beigeware", "template_id": "job_mid_qa",
		"tier": "mid", "day_received": run.day, "kind": "rolled", "mail_id": "mail_invite_mid"})
	var report := _sleep(run, _rng(25))
	assert_true(report["grace_day"], "Your landlord gave you one more day. ONE.")
	assert_false(report["plan_b"])
	assert_true(run.grace_used)
	report = _sleep(run, _rng(25))
	assert_true(report["plan_b"], "only one grace day per run")


func test_an_invite_arriving_that_morning_also_buys_the_grace_day() -> void:
	var run := _run("graduate")
	run.rent_days_left = 1
	_app(run, "startup", 1.0)
	var report := _sleep(run, _rng(26))
	assert_eq((report["invites"] as Array).size(), 1, "the inbox still reveals")
	assert_true(report["grace_day"])
	assert_false(report["plan_b"])


func test_no_grace_day_for_an_expired_invite_or_when_switched_off() -> void:
	var run := _run("graduate")
	run.day = 5
	run.rent_days_left = 1
	run.invites.append({"uid": run.new_uid(), "app_uid": 99, "company_id": "co_beigeware", "template_id": "job_mid_qa",
		"tier": "mid", "day_received": 4, "kind": "rolled", "mail_id": "mail_invite_mid"})
	var report := _sleep(run, _rng(27))
	assert_eq((report["expired"] as Array).size(), 1, "the invite expired this morning")
	assert_true(report["plan_b"])
	var no_grace := _run("graduate")
	cfg.grace_day = false
	no_grace.rent_days_left = 1
	_app(no_grace, "startup", 1.0)
	assert_true(_sleep(no_grace, _rng(27))["plan_b"])


func test_start_day_clears_the_report_and_says_when_it_is_plan_b() -> void:
	var run := _run("graduate")
	_sleep(run, _rng(28))
	assert_false(run.morning_report.is_empty())
	assert_false(run.start_day())
	assert_true(run.morning_report.is_empty())
	run.rent_days_left = 1
	_sleep(run, _rng(28))
	assert_true(run.start_day(), "GameState ends the run after this inbox")


func test_take_invite_removes_it_from_mail() -> void:
	var run := _run("graduate")
	var app := _app(run, "startup", 1.0)
	var report := _sleep(run, _rng(29))
	var invite: Dictionary = report["invites"][0]
	assert_true(run.take_invite(-1).is_empty(), "unknown invite")
	assert_eq(run.take_invite(int(invite["uid"])), invite)
	assert_true(run.invites.is_empty())
	assert_eq(app["status"], "interview")

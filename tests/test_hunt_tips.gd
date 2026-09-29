@tool
extends McpTestSuite
## Where the job hunt's Ducky tips and first-run coach marks fire (GDD 8.3, 4.3, S04, S06) through
## HuntTips, and the plain-data fields the hub's apps read: day_mail (Mail after Start day), tips_shown
## (once-per-run tips) and coach_closed (coach marks tapped closed).
## Pure: fixtures are built in code, saves go through JSON strings, never user:// (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_tips"


func suite_setup(_ctx: Dictionary) -> void:
	for id: String in TIER_IDS:
		tiers[id] = load("res://data/tiers/%s.tres" % id)
	for id: String in ["intern", "graduate", "self_taught"]:
		bgs[id] = load("res://data/backgrounds/%s.tres" % id)
	for file: String in ["postings", "companies", "cv_lines", "emails"]:
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


## An application sent today, as apply_card records it, with the reveal forced by p (1.0 = invite,
## 0.0 = no invite) and a knockout when asked.
func _app(run: RunState, tier_id: String, p: float, knockout: bool = false, tailored: bool = true, referral: bool = false) -> Dictionary:
	var app := {
		"uid": run.new_uid(), "template_id": "job_mid_backend", "company_id": "co_beigeware",
		"tier": tier_id, "day_sent": run.day,
		"reveal_day": Odds.reply_day(cfg, tiers[tier_id], run.day, knockout),
		"p": p, "hits": 2, "relevant": true, "knockout": knockout,
		"knockout_reason": {"id": "knock_years", "args": {"n": 1}} if knockout else {},
		"is_ghost": false, "referral": referral, "tailored": tailored, "status": "pending",
	}
	run.applications.append(app)
	return app


## A morning whose rejections are the given applications, already revealed as rejected (the state
## Sleep leaves behind), so the inbox tip can be read off the report.
func _rejected_morning(run: RunState, knockouts: Array) -> Dictionary:
	var rejections: Array = []
	for knockout: bool in knockouts:
		var app := _app(run, "startup", 0.0, knockout)
		app["status"] = "rejected"
		run.total_rejections += 1
		rejections.append({"app_uid": app["uid"], "company_id": app["company_id"], "template_id": app["template_id"],
			"tier": "startup", "knockout": app["knockout_reason"], "mail_id": "mail_knockout" if knockout else "mail_reject_01"})
	return {"day": run.day, "rejections": rejections}


func test_first_knockout_rejection_shows_the_ats_tip() -> void:
	var run := _run("graduate")
	assert_eq(HuntTips.inbox(run, {"rejections": []}), "", "no rejection, no tip")
	var report := _rejected_morning(run, [false, true])
	assert_eq(HuntTips.inbox(run, report), "tip_ats_knockouts", "first rejection ever, one of them a knockout")
	assert_eq(HuntTips.inbox(run, report), "tip_ats_knockouts", "the same report gives the same tip (Mail later that day)")
	var next := _rejected_morning(run, [true])
	assert_eq(HuntTips.inbox(run, next), "", "the second knockout morning: no tip")


func test_first_plain_rejection_and_every_tenth_show_the_numbers_tip() -> void:
	var run := _run("graduate")
	assert_eq(HuntTips.inbox(run, _rejected_morning(run, [false])), "tip_rejection_numbers", "the first rejection")
	for i: int in 7:
		assert_eq(HuntTips.inbox(run, _rejected_morning(run, [false])), "", "rejection %d" % (i + 2))
	assert_eq(HuntTips.inbox(run, _rejected_morning(run, [false, false, false])), "tip_rejection_numbers",
		"8 -> 11 crosses the 10th")
	assert_eq(HuntTips.inbox(run, _rejected_morning(run, [false])), "", "the 12th")


func test_a_first_knockout_after_plain_rejections_still_teaches_knockouts() -> void:
	var run := _run("self_taught")
	_rejected_morning(run, [false, false])
	assert_eq(HuntTips.inbox(run, _rejected_morning(run, [true])), "tip_ats_knockouts")


func test_the_real_morning_reveal_feeds_the_inbox_tip() -> void:
	var run := _run("graduate")
	_app(run, "startup", 0.5, true)
	var report := _sleep(run, _rng(31))
	assert_eq((report["rejections"] as Array).size(), 1, "a knockout rejects the next morning")
	assert_eq(HuntTips.inbox(run, report), "tip_ats_knockouts")


func test_night_tip_first_referral_once() -> void:
	var run := _run("intern")
	assert_eq(HuntTips.night(run), "", "nothing sent yet")
	_app(run, "big", 0.2, false, true, true)
	assert_eq(HuntTips.night(run), "tip_referrals")
	run.tips_shown.append("tip_referrals")
	assert_eq(HuntTips.night(run), "tip_quantify_impact", "once per run; the next night, the Tailor & Apply tip")


func test_night_tip_eight_quick_applies_without_an_invite() -> void:
	var run := _run("graduate")
	run.tips_shown.append("tip_quantify_impact")  # the Tailor & Apply tip has its own test
	for i: int in HuntTips.SPRAY_QUICK_APPLIES - 1:
		_app(run, "mid", 0.05, false, false)
	_app(run, "mid", 0.1, false, true)
	assert_eq(HuntTips.night(run), "", "7 Quick + 1 tailored")
	_app(run, "mid", 0.05, false, false)
	assert_eq(HuntTips.night(run), "tip_tailor_over_spray", "the 8th Quick Apply")
	run.applications[0]["status"] = "invited"
	assert_eq(HuntTips.night(run), "", "not once an invite has arrived")
	run.applications[0]["status"] = "pending"
	run.tips_shown.append("tip_tailor_over_spray")
	assert_eq(HuntTips.night(run), "", "once per run")


func test_had_invite_counts_every_trace_of_one() -> void:
	var run := _run("graduate")
	assert_false(HuntTips.had_invite(run))
	var app := _app(run, "startup", 1.0)
	for status: String in ["invited", "interview", "expired"]:
		app["status"] = status
		assert_true(HuntTips.had_invite(run), status)
	app["status"] = "rejected"
	assert_false(HuntTips.had_invite(run))
	run.interviews_taken = 1
	assert_true(HuntTips.had_invite(run), "a profile invite has no application")


## D9: the CV screen is gone, so its two tips come after the first Tailor & Apply, on the lock screen.
## A background whose honest CV fails "1+ years" (years_pass_honest) first learns that projects count.
func test_night_tip_after_a_tailor_and_apply() -> void:
	for bg_id: String in ["intern", "graduate", "self_taught"]:
		var run := _run(bg_id)
		var bg: BackgroundData = bgs[bg_id]
		_app(run, "mid", 0.05, false, false)
		assert_eq(HuntTips.night(run, bg), "", bg_id + ": a Quick Apply alone")
		_app(run, "mid", 0.1, false, true)
		if bg.years_pass_honest:
			assert_eq(HuntTips.night(run, bg), "tip_quantify_impact", bg_id)
		else:
			assert_eq(HuntTips.night(run, bg), "tip_projects_count", bg_id)
			run.tips_shown.append("tip_projects_count")
			assert_eq(HuntTips.night(run, bg), "tip_quantify_impact", bg_id + ": the next night")
		run.tips_shown.append("tip_quantify_impact")
		assert_eq(HuntTips.night(run, bg), "", bg_id + ": each once per run")


func test_first_study_tip_once() -> void:
	var run := _run("graduate")
	assert_eq(HuntTips.studied(run), "tip_fundamentals")
	run.tips_shown.assign(["tip_fundamentals"])
	assert_eq(HuntTips.studied(run), "")


## GDD 4.3 on day 1 of the first run: Apply, then Flip after the first application until a card is
## flipped or tailored, then Sleep at 2 energy or less or after 4 applications. Never over the card's
## back, never on another day or run.
func test_coach_marks_follow_the_first_day() -> void:
	var run := _run("graduate")
	run.first_run = true
	assert_eq(HuntTips.coach(run, true, false, false), "coach_apply", "the deck opens")
	assert_eq(HuntTips.coach(run, true, true, false), "", "never over the card's back")
	assert_eq(HuntTips.coach(run, false, false, false), "", "no card, and Sleep isn't due")
	_app(run, "mid", 0.1, false, false)
	run.total_applications = 1
	assert_eq(HuntTips.coach(run, true, false, false), "coach_flip", "after the first application")
	assert_eq(HuntTips.coach(run, true, false, true), "", "a card was flipped")
	_app(run, "mid", 0.1, false, true)
	assert_eq(HuntTips.coach(run, true, false, false), "", "a Tailor & Apply counts as flipping")
	run.energy = HuntTips.COACH_SLEEP_PIPS
	assert_eq(HuntTips.coach(run, true, false, true), "coach_sleep", "2 energy left")
	assert_eq(HuntTips.coach(run, false, false, true), "coach_sleep", "over the empty deck too")
	run.energy = 8
	run.total_applications = HuntTips.COACH_SLEEP_APPS
	assert_eq(HuntTips.coach(run, true, false, true), "coach_sleep", "4 applications")
	run.day = 2
	assert_eq(HuntTips.coach(run, true, false, true), "", "day 1 only")
	run.day = 1
	run.first_run = false
	assert_eq(HuntTips.coach(run, true, false, true), "", "the first run only")


## A tap closes a coach mark for the run (run.coach_closed); the next mark still waits for its own rule.
func test_a_coach_mark_tapped_closed_stays_closed() -> void:
	var run := _run("graduate")
	run.first_run = true
	run.coach_closed.append("coach_apply")
	assert_eq(HuntTips.coach(run, true, false, false), "", "Apply closed: Flip doesn't show early")
	_app(run, "mid", 0.1, false, false)
	run.total_applications = 1
	assert_eq(HuntTips.coach(run, true, false, false), "coach_flip", "Flip after the first application")
	run.coach_closed.append("coach_flip")
	assert_eq(HuntTips.coach(run, true, false, false), "")
	run.energy = 1
	assert_eq(HuntTips.coach(run, true, false, false), "coach_sleep", "Sleep when its rule says so")
	run.coach_closed.append("coach_sleep")
	assert_eq(HuntTips.coach(run, true, false, false), "")


func test_invite_coach_mark_until_the_first_interview() -> void:
	var run := _run("graduate")
	run.first_run = true
	assert_false(HuntTips.coach_invite(run), "no invite waiting")
	run.invites.append({"uid": run.new_uid(), "app_uid": -1, "company_id": "co_beigeware", "template_id": "job_mid_qa",
		"tier": "mid", "day_received": 2, "kind": "guarantee", "mail_id": "mail_invite_mid"})
	assert_true(HuntTips.coach_invite(run))
	run.coach_closed.append(HuntTips.COACH_INVITE)
	assert_false(HuntTips.coach_invite(run), "tapped closed")
	run.coach_closed.clear()
	run.interviews_taken = 1
	assert_false(HuntTips.coach_invite(run), "after the first interview")
	run.interviews_taken = 0
	run.first_run = false
	assert_false(HuntTips.coach_invite(run), "the first run only")


func test_start_day_keeps_the_mail_until_the_next_sleep() -> void:
	var run := _run("graduate")
	run.day = 5
	run.invites.append({"uid": run.new_uid(), "app_uid": 99, "company_id": "co_beigeware", "template_id": "job_mid_qa",
		"tier": "mid", "day_received": 4, "kind": "rolled", "mail_id": "mail_invite_mid"})
	var report := _sleep(run, _rng(32))
	assert_eq((report["expired"] as Array).size(), 1, "an expiry notice this morning")
	assert_true(run.day_mail.is_empty(), "nothing kept while the morning is pending")
	assert_false(run.start_day())
	assert_eq(run.day_mail, report, "Mail keeps the day's mail after Start day")
	assert_true(run.morning_report.is_empty())
	_sleep(run, _rng(33))
	assert_true(run.day_mail.is_empty(), "the next Sleep clears it")


func test_new_fields_survive_a_save() -> void:
	var run := _run("graduate")
	_app(run, "startup", 1.0)
	_sleep(run, _rng(34))
	run.start_day()
	run.tips_shown.append("tip_quantify_impact")
	run.coach_closed.append("coach_apply")
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(back.day_mail, run.day_mail)
	assert_eq(back.tips_shown, run.tips_shown)
	assert_eq(back.tips_shown.get_typed_builtin(), TYPE_STRING, "still Array[String]")
	assert_eq(back.coach_closed, run.coach_closed, "a closed coach mark stays closed after Continue")
	assert_eq(back.coach_closed.get_typed_builtin(), TYPE_STRING, "still Array[String]")
	var old_save := run.to_dict()
	old_save.erase("day_mail")
	old_save.erase("tips_shown")
	old_save.erase("coach_closed")
	var older := RunState.from_dict(JSON.parse_string(JSON.stringify(old_save)))
	assert_true(older.day_mail.is_empty() and older.tips_shown.is_empty() and older.coach_closed.is_empty(),
		"a save from before these fields loads with defaults")

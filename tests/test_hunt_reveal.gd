@tool
extends McpTestSuite
## The morning reveal (GDD 5.7): rolled on the reveal morning in send order, knockouts, ghost jobs,
## silence and ghosting, the Recruiter Radar, invite expiry and the first-run day-2 guarantee.
## Applications with a chosen P are written by hand (p = 0 never invites, p = 1 always does);
## test_hunt_apply covers how the real apply path fills them in.

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_reveal"


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


## An application sent today with a chosen P, as apply_card would record it.
func _app(run: RunState, tier_id: String, p: float, relevant: bool = true, knockout: bool = false, ghost: bool = false) -> Dictionary:
	var app := {
		"uid": run.new_uid(), "template_id": "job_test", "company_id": "co_test_%d" % run.next_uid,
		"tier": tier_id, "day_sent": run.day,
		"reveal_day": Odds.reply_day(cfg, tiers[tier_id], run.day, knockout),
		"p": p, "hits": 2 if relevant else 1, "relevant": relevant, "knockout": knockout,
		"knockout_reason": {"id": "knock_degree", "args": {}} if knockout else {},
		"is_ghost": ghost, "referral": false, "tailored": true, "lies": [], "status": "pending",
	}
	run.applications.append(app)
	return app


func _sleep(run: RunState, rng: RandomNumberGenerator, tier_set: Dictionary = {}) -> Dictionary:
	return run.sleep(cfg, tier_set if not tier_set.is_empty() else tiers, bgs[run.background_id], content, rng)


## tiers, with startup's silent_share replaced (a duplicate: loaded Resources are never modified).
func _tiers_with_startup_silent_share(share: float) -> Dictionary:
	var startup: TierData = (tiers["startup"] as TierData).duplicate()
	startup.silent_share = share
	var out := tiers.duplicate()
	out["startup"] = startup
	return out


func _uids(entries: Array, key: String) -> Array[int]:
	var out: Array[int] = []
	for e: Dictionary in entries:
		out.append(int(e[key]))
	return out


## What the reveal must do, replayed by hand: P roll, then the silent roll, in the given order.
func _expected_statuses(apps: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var out := {}
	var silent_share := (tiers["startup"] as TierData).silent_share
	for app: Dictionary in apps:
		if Odds.roll(rng, app["p"]):
			out[app["uid"]] = "invited"
		elif Odds.roll(rng, silent_share):
			out[app["uid"]] = "silent"
		else:
			out[app["uid"]] = "rejected"
	return out


func test_outcomes_are_rolled_on_the_reveal_morning_in_send_order() -> void:
	var run := _run("graduate")
	var sent: Array[Dictionary] = []
	for p: float in [0.5, 0.3, 0.7, 0.5, 0.2, 0.9, 0.4]:
		sent.append(_app(run, "startup", p, false))  # not relevant: the Radar stays out of it
	var mid := _app(run, "mid", 1.0)
	var report := _sleep(run, _rng(20260927))
	var actual := {}
	for app: Dictionary in sent:
		actual[app["uid"]] = app["status"]
	assert_eq(actual, _expected_statuses(sent, _rng(20260927)), "the run RNG, in send order")
	var reversed: Array[Dictionary] = []
	for i: int in range(sent.size() - 1, -1, -1):
		reversed.append(sent[i])
	assert_ne(actual, _expected_statuses(reversed, _rng(20260927)), "this seed tells the orders apart")
	assert_eq(mid["status"], "pending", "a Mid reply waits for its own morning")
	var invited: Array[int] = []
	var rejected: Array[int] = []
	for app: Dictionary in sent:
		if app["status"] == "invited":
			invited.append(int(app["uid"]))
		elif app["status"] == "rejected":
			rejected.append(int(app["uid"]))
	assert_eq(_uids(report["invites"], "app_uid"), invited, "invites listed in send order")
	assert_eq(_uids(report["rejections"], "app_uid"), rejected, "rejections listed in send order")
	assert_eq(report["no_reply"], sent.size() - invited.size() - rejected.size())


func test_a_knockout_rejects_the_next_morning_whatever_the_tier() -> void:
	var run := _run("graduate")
	var app := _app(run, "big", 1.0, true, true)
	assert_eq(app["reveal_day"], 2, "3:07 AM, not in 3 mornings")
	var report := _sleep(run, _rng(1))
	assert_eq(app["status"], "rejected", "even at p = 1")
	var rejection: Dictionary = report["rejections"][0]
	assert_eq(rejection["knockout"], {"id": "knock_degree", "args": {}})
	assert_eq(rejection["mail_id"], "mail_knockout")
	assert_true((report["invites"] as Array).is_empty())


func test_the_radar_ignores_knockouts() -> void:
	var run := _run("graduate")
	run.pity_count = 3
	_app(run, "startup", 0.0, true, true)
	_app(run, "big", 0.0, true, true)
	var report := _sleep(run, _rng(2))
	assert_eq(run.pity_count, 3, "a knockout is the CV's fault: it never fills the Radar")
	assert_eq(report["radar"], {"before": 3, "after": 3, "max": 8})
	# Radar full: a relevant knockout is still just rejected; the next relevant application gets the invite.
	var full := _run("graduate")
	full.pity_count = 8
	var knocked := _app(full, "startup", 0.0, true, true)
	var next := _app(full, "startup", 0.0)
	var morning := _sleep(full, _rng(2))
	assert_eq(knocked["status"], "rejected")
	assert_eq(next["status"], "invited")
	assert_eq((morning["invites"][0] as Dictionary)["kind"], "radar")


func test_the_radar_counts_only_relevant_applications() -> void:
	var run := _run("graduate")
	_app(run, "startup", 0.0, false)
	_app(run, "startup", 0.0, false)
	_app(run, "startup", 0.0, true)
	var report := _sleep(run, _rng(3))
	assert_eq(run.pity_count, 1, "1 relevant non-invite; 2 irrelevant ones don't count")
	assert_eq(report["radar"], {"before": 0, "after": 1, "max": 8})


func test_a_full_radar_guarantees_the_next_relevant_invite() -> void:
	for bg_id: String in ["intern", "graduate", "self_taught"]:
		var run := _run(bg_id)
		var bg: BackgroundData = bgs[bg_id]
		run.pity_count = bg.pity_n
		var irrelevant := _app(run, "startup", 0.0, false)
		var relevant := _app(run, "startup", 0.0, true)
		var report := _sleep(run, _rng(4))
		assert_ne(irrelevant["status"], "invited", "%s: an irrelevant application never gets the Radar invite" % bg_id)
		assert_eq(relevant["status"], "invited", "%s: N = %d" % [bg_id, bg.pity_n])
		var invite: Dictionary = report["invites"][0]
		assert_eq([invite["kind"], invite["mail_id"]], ["radar", "mail_invite_radar"])
		assert_eq(run.pity_count, 0, "any invite empties the Radar")
	var almost := _run("graduate")
	almost.pity_count = 7
	_app(almost, "startup", 0.0)
	_sleep(almost, _rng(4))
	assert_eq(almost.pity_count, 8, "7 + 1: full from the next morning")


func test_ghost_jobs_never_reply_but_count_for_the_radar() -> void:
	var run := _run("graduate")
	var ghost := _app(run, "startup", 1.0, true, false, true)
	var report := _sleep(run, _rng(5))
	assert_eq(ghost["status"], "silent", "nothing, even at p = 1")
	assert_eq(report["no_reply"], 1)
	assert_true((report["invites"] as Array).is_empty() and (report["rejections"] as Array).is_empty())
	assert_eq(run.pity_count, 1, "relevant, no invite")
	for _night: int in 5:
		report = _sleep(run, _rng(5))
		assert_true((report["ghosted"] as Array).is_empty(), "not yet ghosted on day %d" % run.day)
	report = _sleep(run, _rng(5))
	assert_eq(run.day, 8)
	assert_eq(ghost["status"], "ghosted")
	assert_eq(report["ghosted"], [{"app_uid": ghost["uid"], "company_id": ghost["company_id"],
		"template_id": "job_test", "tier": "startup", "days": 7}])
	assert_eq((report["night"] as Dictionary)["ghosted"], 1, "the lock-screen summary counts it")


func test_silent_applications_turn_ghosted_seven_days_after_sending() -> void:
	var quiet := _tiers_with_startup_silent_share(1.0)
	var run := _run("graduate")
	run.rent_days_left = 30
	var app := _app(run, "startup", 0.0, false)
	var report := _sleep(run, _rng(6), quiet)
	assert_eq(app["status"], "silent")
	assert_eq(report["no_reply"], 1)
	for _night: int in 5:
		_sleep(run, _rng(6), quiet)
		assert_eq(app["status"], "silent")
	report = _sleep(run, _rng(6), quiet)
	assert_eq(app["status"], "ghosted", "day 8 = sent on day 1 + 7")
	assert_eq(_uids(report["ghosted"], "app_uid"), [int(app["uid"])])
	_sleep(run, _rng(6), quiet)
	assert_eq(app["status"], "ghosted", "ghosted once, for good")


func test_invites_are_valid_the_day_they_arrive_and_the_next() -> void:
	var run := _run("graduate")
	var app := _app(run, "startup", 1.0)
	var report := _sleep(run, _rng(7))
	var invite: Dictionary = report["invites"][0]
	assert_eq([invite["app_uid"], invite["kind"], invite["mail_id"], invite["day_received"]],
		[app["uid"], "rolled", "mail_invite_startup", 2])
	assert_eq(run.invites.size(), 1)
	report = _sleep(run, _rng(7))
	assert_eq(run.invites.size(), 1, "still valid on day 3")
	assert_true((report["expired"] as Array).is_empty())
	report = _sleep(run, _rng(7))
	assert_true(run.invites.is_empty(), "gone on day 4")
	assert_eq(report["expired"], [{"invite_uid": invite["uid"], "app_uid": app["uid"], "company_id": app["company_id"],
		"template_id": "job_test", "tier": "startup", "mail_id": "mail_invite_expired"}], "filled internally. It always was.")
	assert_eq(app["status"], "expired")


func test_day2_guarantee_on_the_first_run_only() -> void:
	for first_run: bool in [true, false]:
		var run := _run("graduate")
		run.first_run = first_run
		run.pity_count = 5
		var low := _app(run, "mid", 0.05)
		var best := _app(run, "mid", 0.09)
		var other := _app(run, "mid", 0.07)
		var report := _sleep(run, _rng(8))
		var morning_invites: Array = report["invites"]
		if not first_run:
			assert_true(morning_invites.is_empty(), "later runs get no guarantee")
			assert_eq(report["guarantee"], "")
			continue
		assert_eq(morning_invites.size(), 1)
		var invite: Dictionary = morning_invites[0]
		assert_eq([invite["app_uid"], invite["kind"], invite["mail_id"]], [best["uid"], "guarantee", "mail_invite_guarantee"],
			"the best day-1 application, revealed a day early")
		assert_eq(report["guarantee"], "guarantee")
		assert_eq(report["radar"], {"before": 5, "after": 0, "max": 8}, "the guarantee resets the Radar")
		assert_eq(best["status"], "invited")
		# Its normal reveal morning skips it; the others reveal as usual.
		report = _sleep(run, _rng(8))
		assert_ne(low["status"], "pending")
		assert_ne(other["status"], "pending")
		assert_false(_uids(report["rejections"], "app_uid").has(int(best["uid"])))
		assert_false(_uids(report["invites"], "app_uid").has(int(best["uid"])))


func test_day2_guarantee_needs_three_day1_applications() -> void:
	var run := _run("graduate")
	run.first_run = true
	_app(run, "mid", 0.05)
	_app(run, "mid", 0.09)
	var report := _sleep(run, _rng(9))
	assert_true((report["invites"] as Array).is_empty(), "2 < day2_guarantee_min_apps")


func test_day2_guarantee_skips_ghost_jobs_and_knockouts() -> void:
	var run := _run("graduate")
	run.first_run = true
	_app(run, "mid", 0.5, true, false, true)
	_app(run, "mid", 0.5, true, true)
	var eligible := _app(run, "mid", 0.02)
	var report := _sleep(run, _rng(10))
	assert_eq(_uids(report["invites"], "app_uid"), [int(eligible["uid"])])


func test_day2_guarantee_can_turn_this_mornings_non_reply_into_the_invite() -> void:
	var run := _run("graduate")
	run.first_run = true
	var a := _app(run, "startup", 1e-9)
	var b := _app(run, "startup", 3e-9)
	var c := _app(run, "startup", 2e-9)
	var report := _sleep(run, _rng(11))
	assert_eq(_uids(report["invites"], "app_uid"), [int(b["uid"])], "highest P wins")
	assert_eq(b["status"], "invited")
	assert_false(_uids(report["rejections"], "app_uid").has(int(b["uid"])), "no rejection email for it")
	assert_eq((report["rejections"] as Array).size() + int(report["no_reply"]), 2, "a and c revealed as usual")
	assert_ne(a["status"], "pending")
	assert_ne(c["status"], "pending")


func test_day2_guarantee_falls_back_to_the_best_startup_card() -> void:
	var run := _run("graduate")
	run.first_run = true
	var rng := _rng(12)
	run.deal_board(cfg, tiers, content, rng)
	for _i: int in 3:
		_app(run, "mid", 0.3, true, true)
	var report := _sleep(run, rng)
	assert_eq(report["guarantee"], "profile")
	var invites_now: Array = report["invites"]
	assert_eq(invites_now.size(), 1)
	var invite: Dictionary = invites_now[0]
	assert_eq([invite["kind"], invite["mail_id"], invite["tier"]], ["profile", "mail_invite_guarantee", "startup"])
	var pair := RunState.pair_key(invite["template_id"], invite["company_id"])
	assert_true(run.applied.has(pair), "never dealt again")
	var chosen := run.card_odds(cfg, tiers, bgs["graduate"], content,
		{"tier": "startup", "template_id": invite["template_id"], "company_id": invite["company_id"]})
	for card: Dictionary in run.board:
		assert_ne(int(card["uid"]), int(invite["app_uid"]), "the card left the board")
		if card["tier"] == "startup" and not card["is_ghost"]:
			var odds := run.card_odds(cfg, tiers, bgs["graduate"], content, card)
			assert_true(float(chosen["tailored"]["p"]) >= float(odds["tailored"]["p"]), "the highest-odds startup")


## Every text id the hunt rules put in a report or on a card exists in the content files. The ids are
## read from the rule scripts as text, so a new or renamed id can't slip past this test.
func test_the_content_ids_the_rules_emit_exist() -> void:
	var emails: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/emails.json"))
	var postings: Dictionary = content["postings"]
	var literal := RegEx.create_from_string("\"((mail|knock)_[a-z_]+)\"(?!\\s*:)")  # values, not keys like "mail_id":
	var found := 0
	for path: String in ["res://core/run_state.gd", "res://core/odds.gd"]:
		for m: RegExMatch in literal.search_all(FileAccess.get_file_as_string(path)):
			var id := m.get_string(1)
			if id == "mail_invite_":  # the prefix: + a tier id (rolled) or + "radar" / "guarantee"
				for suffix: String in ["startup", "mid", "big", "radar", "guarantee"]:
					assert_has_key(emails, id + suffix)
			elif id == "mail_reject_":  # the prefix of the plain rejection lines (RunState.reject_mail_id)
				assert_gt(emails.keys().filter(func(k: Variant) -> bool: return str(k).begins_with(id)).size(), 1,
					"more than one plain rejection line")
			elif id.begins_with("mail_"):
				assert_has_key(emails, id)
			else:
				assert_has_key(postings, id)
			found += 1
	assert_gt(found, 5, "the rules name their mail and knockout ids")
	assert_has_key(postings, "card_knockout", "the chip text that wraps knock_*")

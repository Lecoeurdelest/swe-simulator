@tool
extends McpTestSuite
## Step 5 hunt rule defaults (agent defaults, please review): a dry MVP deck falls back to the tier's
## other companies; a blacklist withdraws that company's waiting invites and silences its pending
## applications; a plain rejection's email is picked from the application uid, without dice; the
## first-run "saw your profile" fallback never uses a ghost job; passes_years stays a boolean.
## Also the CV level setter. Loads the real .tres and JSON with load() / FileAccess, never the
## Content autoload (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_defaults"


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


func _sleep(run: RunState, rng: RandomNumberGenerator, tier_set: Dictionary = {}, files: Dictionary = {}) -> Dictionary:
	return run.sleep(cfg, tier_set if not tier_set.is_empty() else tiers, bgs[run.background_id],
		files if not files.is_empty() else content, rng)


func _card(run: RunState, template_id: String, company_id: String, is_ghost: bool) -> int:
	var uid := run.new_uid()
	run.board.push_front({
		"uid": uid, "template_id": template_id, "company_id": company_id, "tier": content["postings"][template_id]["tier"],
		"posted_days_ago": 3, "applicants": 50, "is_ghost": is_ghost, "reposted": false,
	})
	return uid


## An application sent today with a chosen P, as apply_card would record it.
func _app(run: RunState, tier_id: String, p: float, company_id: String, relevant: bool = true, knockout: bool = false) -> Dictionary:
	var app := {
		"uid": run.new_uid(), "template_id": "job_test", "company_id": company_id,
		"tier": tier_id, "day_sent": run.day,
		"reveal_day": Odds.reply_day(cfg, tiers[tier_id], run.day, knockout),
		"p": p, "hits": 2 if relevant else 1, "relevant": relevant, "knockout": knockout,
		"knockout_reason": {"id": "knock_degree", "args": {}} if knockout else {},
		"is_ghost": false, "referral": false, "tailored": true, "lies": [], "status": "pending",
	}
	run.applications.append(app)
	return app


func _tiers_with(tier_id: String, field: String, value: Variant) -> Dictionary:
	var copy: TierData = (tiers[tier_id] as TierData).duplicate()
	copy.set(field, value)
	var out := tiers.duplicate()
	out[tier_id] = copy
	return out


## Every pair a tier can deal from all of its companies (mvp_only: its MVP companies only).
func _tier_pairs(tier_id: String, mvp_only: bool = false) -> Array[String]:
	var pairs: Array[String] = []
	var postings: Dictionary = content["postings"]
	var companies: Dictionary = content["companies"]
	for template_id: Variant in postings:
		var posting: Variant = postings[template_id]
		if not (posting is Dictionary) or posting["tier"] != tier_id or posting["should"]:
			continue
		for company_id: Variant in companies:
			var company: Dictionary = companies[company_id]
			if company["tier"] == tier_id and (company["mvp"] or not mvp_only) and posting["company"] in ["any", company_id]:
				pairs.append(RunState.pair_key(str(template_id), str(company_id)))
	return pairs


func _uids(entries: Array, key: String) -> Array[int]:
	var out: Array[int] = []
	for e: Dictionary in entries:
		out.append(int(e[key]))
	return out


func _reject_ids() -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in content["emails"]:
		if str(key).begins_with("mail_reject_"):
			ids.append(str(key))
	ids.sort()
	return ids


# ---------- (a) the deck never starves ----------

func test_a_dry_mvp_deck_deals_the_tiers_other_company() -> void:
	var run := _run("graduate")
	run.applied.append_array(_tier_pairs("startup", true))
	assert_eq(run.deal_board(cfg, tiers, content, _rng(1)), 6, "still 2 cards per tier")
	var startup := 0
	for card: Dictionary in run.board:
		if card["tier"] == "startup":
			startup += 1
			assert_eq(card["company_id"], "co_stealth", "the MVP startups are used up: the non-MVP one steps in")
			assert_false(run.applied.has(RunState.pair_key(card["template_id"], card["company_id"])))
	assert_eq(startup, 2)


func test_mvp_companies_deal_first_while_they_have_a_free_pair() -> void:
	var run := _run("graduate")
	var left := _tier_pairs("startup", true)[3]
	for pair: String in _tier_pairs("startup", true):
		if pair != left:
			run.applied.append(pair)
	for seed_value: int in range(1, 11):
		run.board.clear()
		run.deal_board(cfg, tiers, content, _rng(seed_value))
		var startup_pairs: Array[String] = []
		for card: Dictionary in run.board:
			if card["tier"] == "startup":
				startup_pairs.append(RunState.pair_key(card["template_id"], card["company_id"]))
		assert_eq(startup_pairs.size(), 2)
		assert_true(startup_pairs.has(left), "seed %d: the last free MVP pair is dealt first" % seed_value)
		for pair: String in startup_pairs:
			assert_true(pair == left or pair.ends_with("|co_stealth"), "seed %d: %s" % [seed_value, pair])


func test_the_deck_holds_about_60_pairs_across_all_9_companies() -> void:
	var expected: Array[String] = []
	for tier_id: String in TIER_IDS:
		expected.append_array(_tier_pairs(tier_id))
	assert_true(expected.size() >= 50 and expected.size() <= 70, "GDD 5.6: about 60 combinations (%d)" % expected.size())
	var run := _run("intern")
	var rng := _rng(2)
	var dry_mornings := 0
	for _morning: int in 40:
		if run.deal_board(cfg, tiers, content, rng) == 0:
			dry_mornings += 1
		while not run.board.is_empty():
			run.energy = cfg.energy_max
			assert_false(run.apply_card(cfg, tiers, bgs["intern"], content, int(run.board[0]["uid"]), false, false).is_empty())
	var applied: Array[String] = run.applied.duplicate()
	applied.sort()
	expected.sort()
	assert_eq(applied, expected, "every pair of every company was dealt exactly once")
	var companies: Dictionary = {}
	for pair: String in applied:
		companies[pair.get_slice("|", 1)] = true
	assert_eq(companies.size(), 9, "all 9 companies")
	assert_gt(dry_mornings, 0, "only then does the deck run dry")


# ---------- (b) blacklisting ----------

func test_blacklisting_withdraws_that_companys_waiting_invites_silently() -> void:
	var run := _run("graduate")
	var gone := _app(run, "startup", 1.0, "co_synergai")
	var kept := _app(run, "startup", 1.0, "co_quantumleaf")
	_sleep(run, _rng(3))
	assert_eq(_uids(run.invites, "app_uid"), [int(gone["uid"]), int(kept["uid"])])
	var withdrawn: Dictionary = run.invites[0]
	run.blacklist_company("co_synergai")
	assert_eq(_uids(run.invites, "app_uid"), [int(kept["uid"])], "only the other company's invite waits")
	assert_eq(gone["status"], "expired")
	assert_eq(kept["status"], "invited")
	assert_true(run.take_invite(int(withdrawn["uid"])).is_empty(), "a withdrawn invite can't be taken")
	var report := _sleep(run, _rng(4))
	assert_true((report["expired"] as Array).is_empty(), "no 'filled internally' mail: it just vanished")
	assert_eq(run.invites.size(), 1, "the other invite is still valid on day 3")


func test_pending_applications_to_a_blacklisted_company_reveal_silent_without_dice() -> void:
	var quiet := _tiers_with("startup", "silent_share", 0.0)
	for seed_value: int in range(1, 30):
		var plain := _run("graduate")
		var target_plain := _app(plain, "startup", 0.4, "co_quantumleaf", false)
		_sleep(plain, _rng(seed_value), quiet)
		var run := _run("graduate")
		var sure := _app(run, "startup", 1.0, "co_synergai")
		var knocked := _app(run, "startup", 1.0, "co_synergai", true, true)
		var target := _app(run, "startup", 0.4, "co_quantumleaf", false)
		run.blacklist_company("co_synergai")
		var report := _sleep(run, _rng(seed_value), quiet)
		assert_eq([sure["status"], knocked["status"]], ["silent", "silent"], "even at p = 1, and no 3:07 AM knockout mail")
		assert_eq(target["status"], target_plain["status"], "seed %d: they used no dice" % seed_value)
		assert_false(_uids(report["invites"], "app_uid").has(int(sure["uid"])))
		assert_false(_uids(report["rejections"], "app_uid").has(int(knocked["uid"])))
		# Send order: the relevant silence adds 1, the knockout never counts, then the target's invite
		# (if it rolled one) empties the Radar.
		assert_eq(run.pity_count, 0 if target["status"] == "invited" else 1,
			"seed %d: a relevant silence fills the Radar like any silence; a knockout never does" % seed_value)


func test_a_full_radar_waits_for_the_next_relevant_application_to_a_live_company() -> void:
	var run := _run("intern")  # N = 6
	run.pity_count = 6
	var dead := _app(run, "startup", 0.0, "co_synergai")
	var live := _app(run, "startup", 0.0, "co_quantumleaf")
	run.blacklist_company("co_synergai")
	var report := _sleep(run, _rng(5))
	assert_eq(dead["status"], "silent", "never a Radar invite from a blacklisted company")
	assert_eq(live["status"], "invited")
	assert_eq((report["invites"][0] as Dictionary)["kind"], "radar")


func test_the_day2_guarantee_never_picks_a_blacklisted_company() -> void:
	var run := _run("graduate")
	run.first_run = true
	var best := _app(run, "mid", 0.3, "co_beigeware")
	var next := _app(run, "mid", 0.2, "co_bytebistro")
	_app(run, "mid", 0.1, "co_bytebistro")
	run.blacklist_company("co_beigeware")
	var report := _sleep(run, _rng(6))
	assert_eq(report["guarantee"], "guarantee")
	assert_eq(_uids(report["invites"], "app_uid"), [int(next["uid"])])
	assert_eq(best["status"], "pending", "a Mid reply still waits for its own morning")


# ---------- (c) the plain rejection email ----------

func test_a_plain_rejection_mail_is_picked_by_the_application_uid() -> void:
	var ids := _reject_ids()
	assert_eq(ids.size(), 10, "CONTENT.md mail_reject_01 .. 10")
	var loud := _tiers_with("startup", "silent_share", 0.0)
	var run := _run("graduate")
	for _i: int in 12:
		_app(run, "startup", 0.0, "co_synergai", false)  # irrelevant: the Radar never fires here
	var knocked := _app(run, "startup", 0.0, "co_synergai", false, true)
	var report := _sleep(run, _rng(7), loud)
	var used: Dictionary = {}
	for rejection: Dictionary in report["rejections"]:
		var uid := int(rejection["app_uid"])
		if uid == int(knocked["uid"]):
			assert_eq(rejection["mail_id"], "mail_knockout", "a knockout names its knockout")
			continue
		assert_eq(rejection["mail_id"], ids[uid % ids.size()], "uid %d" % uid)
		used[rejection["mail_id"]] = true
	assert_eq((report["rejections"] as Array).size(), 13)
	assert_eq(used.size(), 10, "12 uids in a row use every line")
	assert_eq(RunState.reject_mail_id({}, 5), "", "no emails.json: no line")


func test_the_rejection_mail_uses_no_dice_and_survives_a_kill() -> void:
	var loud := _tiers_with("startup", "silent_share", 0.0)
	var without_mail: Dictionary = {"postings": content["postings"], "companies": content["companies"], "cv_lines": content["cv_lines"]}
	var a := _run("graduate")
	var b := _run("graduate")
	for run: RunState in [a, b]:
		for _i: int in 5:
			_app(run, "startup", 0.3, "co_synergai")
	var rng_a := _rng(8)
	var rng_b := _rng(8)
	var evening := JSON.stringify(a.to_dict())
	var report := _sleep(a, rng_a, loud)
	_sleep(b, rng_b, loud, without_mail)
	assert_eq(rng_a.state, rng_b.state, "picking the lines rolled nothing")
	var replayed := RunState.from_dict(JSON.parse_string(evening))
	assert_eq(_sleep(replayed, _rng(8), loud), report, "a replayed Sleep shows the same lines")
	var resumed := RunState.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_eq(resumed.morning_report, report, "Continue after the kill shows the same lines")


# ---------- (d) the profile fallback ----------

func test_the_profile_fallback_never_uses_a_ghost_job() -> void:
	var run := _run("graduate")
	run.first_run = true
	run.pity_count = 3
	run.applied.append_array(_tier_pairs("startup"))  # the morning deal adds no startup card
	_card(run, "job_st_founding", "co_synergai", true)
	_card(run, "job_st_ai_generalist", "co_quantumleaf", true)
	for _i: int in 3:
		_app(run, "mid", 0.3, "co_beigeware", true, true)  # knockouts: no eligible application
	var report := _sleep(run, _rng(9))
	assert_eq(report["guarantee"], "", "only ghost startup cards: no guarantee invite (rare)")
	assert_true((report["invites"] as Array).is_empty())
	assert_eq(run.pity_count, 3, "no invite, nothing to reset")
	# One real startup card among the ghosts gets the invite, even with lower odds.
	var again := _run("graduate")
	again.first_run = true
	again.applied.append_array(_tier_pairs("startup"))
	_card(again, "job_st_founding", "co_synergai", true)
	var real := _card(again, "job_st_mobile_barista", "co_quantumleaf", false)
	for _i: int in 3:
		_app(again, "mid", 0.3, "co_beigeware", true, true)
	report = _sleep(again, _rng(9))
	assert_eq(report["guarantee"], "profile")
	assert_eq(_uids(report["invites"], "app_uid"), [real])


# ---------- (e) kept as is, and the CV setter ----------

func test_passes_years_stays_a_boolean() -> void:
	var run := _run("graduate")
	for level: String in RunState.CV_LEVELS:
		run.cv_levels["exp"] = level
		for tailored: bool in [false, true]:
			var sent := run.cv_sent(content["cv_lines"], tailored)
			assert_eq(typeof(sent["passes_years"]), TYPE_BOOL, "%s tailored=%s" % [level, tailored])
			assert_eq(typeof(sent["degree"]), TYPE_BOOL)


func test_set_cv_level_takes_only_known_lines_and_levels() -> void:
	var run := _run("self_taught")
	assert_true(run.set_cv_level("edu", "lie"))
	assert_eq(run.cv_levels["edu"], "lie")
	assert_true(run.set_cv_level("exp", "polished"))
	assert_false(run.set_cv_level("hobbies", "lie"), "unknown line")
	assert_false(run.set_cv_level("proj", "exaggerated"), "unknown level")
	assert_eq(run.cv_levels, {"edu": "lie", "exp": "polished", "proj": "honest"})
	assert_true(run.cv_sent(content["cv_lines"], false)["degree"], "the fake degree now passes degree knockouts")

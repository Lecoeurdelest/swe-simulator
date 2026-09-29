@tool
extends McpTestSuite
## Job-hunt edge cases and invariants (verifier pass): exact-cost energy, double applies, empty and
## blacklisted tiers, Radar sequencing inside one morning, send order across tiers, RNG use by the
## reveal, invite expiry on the last valid day, rent at 0, plain data and determinism over long runs.
## Loads the real .tres and JSON with load() / FileAccess, never the Content autoload (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
const STATUSES: PackedStringArray = ["pending", "invited", "rejected", "silent", "ghosted", "interview", "expired"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_edges"


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


func _sleep(run: RunState, rng: RandomNumberGenerator, tier_set: Dictionary = {}) -> Dictionary:
	return run.sleep(cfg, tier_set if not tier_set.is_empty() else tiers, bgs[run.background_id], content, rng)


func _card(run: RunState, template_id: String, company_id: String, is_ghost: bool = false) -> int:
	var posting: Dictionary = content["postings"][template_id]
	var uid := run.new_uid()
	run.board.push_front({
		"uid": uid, "template_id": template_id, "company_id": company_id, "tier": posting["tier"],
		"posted_days_ago": 3, "applicants": 200, "is_ghost": is_ghost, "reposted": false,
	})
	return uid


## An application sent today with a chosen P, as apply_card would record it.
func _app(run: RunState, tier_id: String, p: float, relevant: bool = true, knockout: bool = false, ghost: bool = false) -> Dictionary:
	var app := {
		"uid": run.new_uid(), "template_id": "job_test", "company_id": "co_test",
		"tier": tier_id, "day_sent": run.day,
		"reveal_day": Odds.reply_day(cfg, tiers[tier_id], run.day, knockout),
		"p": p, "hits": 2 if relevant else 1, "relevant": relevant, "knockout": knockout,
		"knockout_reason": {"id": "knock_degree", "args": {}} if knockout else {},
		"is_ghost": ghost, "referral": false, "tailored": true, "status": "pending",
	}
	run.applications.append(app)
	return app


func _tiers_with(tier_id: String, field: String, value: Variant) -> Dictionary:
	var copy: TierData = (tiers[tier_id] as TierData).duplicate()
	copy.set(field, value)
	var out := tiers.duplicate()
	out[tier_id] = copy
	return out


func _pairs_on_board(run: RunState) -> Array[String]:
	var pairs: Array[String] = []
	for card: Dictionary in run.board:
		pairs.append(RunState.pair_key(card["template_id"], card["company_id"]))
	return pairs


## Every leaf of a saved run is plain data: String, int, float, bool, Array, Dictionary with String keys.
func _plain_problems(v: Variant, path: String, out: Array[String]) -> void:
	match typeof(v):
		TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			return
		TYPE_ARRAY:
			var arr: Array = v
			for i: int in arr.size():
				_plain_problems(arr[i], "%s[%d]" % [path, i], out)
		TYPE_DICTIONARY:
			var d: Dictionary = v
			for k: Variant in d:
				if typeof(k) != TYPE_STRING:
					out.append("%s key %s is %s" % [path, str(k), type_string(typeof(k))])
				_plain_problems(d[k], "%s.%s" % [path, str(k)], out)
		_:
			out.append("%s is %s" % [path, type_string(typeof(v))])


## Same values AND the same Variant types at every leaf (1 != 1.0 here).
func _type_mismatches(a: Variant, b: Variant, path: String, out: Array[String]) -> void:
	if typeof(a) != typeof(b):
		out.append("%s: %s vs %s" % [path, type_string(typeof(a)), type_string(typeof(b))])
		return
	match typeof(a):
		TYPE_ARRAY:
			var aa: Array = a
			var bb: Array = b
			if aa.size() != bb.size():
				out.append("%s: size %d vs %d" % [path, aa.size(), bb.size()])
				return
			for i: int in aa.size():
				_type_mismatches(aa[i], bb[i], "%s[%d]" % [path, i], out)
		TYPE_DICTIONARY:
			var da: Dictionary = a
			var db: Dictionary = b
			var ka := da.keys()
			var kb := db.keys()
			ka.sort()
			kb.sort()
			if ka != kb:  # JSON.stringify sorts keys, so only the key set must match
				out.append("%s: keys %s vs %s" % [path, str(ka), str(kb)])
				return
			for k: Variant in da:
				_type_mismatches(da[k], db[k], "%s.%s" % [path, str(k)], out)
		_:
			if a != b:
				out.append("%s: %s vs %s" % [path, str(a), str(b)])


## A scripted day: take the first invite when energy allows (blacklisting that company every 5th
## day, as a decline would), skip up to 3 cards whose uid is a multiple of 3, then
## tailor 2+ tag matches (with a token on Mid/Big) and quick-apply the rest. Then Sleep, Start day.
func _play_day(run: RunState, rng: RandomNumberGenerator) -> void:
	var bg: BackgroundData = bgs[run.background_id]
	if not run.invites.is_empty() and run.interviews_today < cfg.max_interviews_per_day \
			and run.energy >= cfg.cost_interview:
		var invite := run.take_invite(int(run.invites[0]["uid"]))
		run.spend_energy(cfg.cost_interview)
		run.interviews_today += 1
		if run.day % 5 == 0:
			run.blacklist_company(str(invite["company_id"]))
	var guard := 0
	while not run.board.is_empty() and run.energy >= cfg.cost_quick_apply and guard < 20:
		guard += 1
		var card: Dictionary = run.board[0]
		if int(card["uid"]) % 3 == 0 and guard < 4:
			run.skip_card(int(card["uid"]))
			continue
		var odds := run.card_odds(cfg, tiers, bg, content, card)
		var tailor := int(odds["tailored"]["hits"]) >= 2 and run.energy >= cfg.cost_tailor_apply
		var referral: bool = tailor and run.referral_tokens > 0 and card["tier"] != "startup"
		if run.apply_card(cfg, tiers, bg, content, int(card["uid"]), tailor, referral).is_empty():
			break
	_sleep(run, rng)
	run.start_day()


# ---------- energy and applying ----------

func test_energy_exactly_equal_to_the_cost_is_enough() -> void:
	var run := _run("graduate")
	run.energy = cfg.cost_tailor_apply
	assert_false(run.apply_card(cfg, tiers, bgs["graduate"], content, _card(run, "job_mid_qa", "co_beigeware"), true, false).is_empty())
	assert_eq(run.energy, 0)
	run.energy = cfg.cost_quick_apply
	assert_false(run.apply_card(cfg, tiers, bgs["graduate"], content, _card(run, "job_mid_mobile", "co_beigeware"), false, false).is_empty())
	assert_eq(run.energy, 0, "pips never go negative")
	assert_true(run.apply_card(cfg, tiers, bgs["graduate"], content, _card(run, "job_mid_platform", "co_beigeware"), false, false).is_empty())
	assert_eq(run.energy, 0)


func test_applying_twice_to_the_same_card_sends_one_application() -> void:
	var run := _run("intern")
	var uid := _card(run, "job_big_data_analyst", "co_nimbus")
	var first := run.apply_card(cfg, tiers, bgs["intern"], content, uid, true, true)
	assert_false(first.is_empty())
	var energy_after := run.energy
	assert_true(run.apply_card(cfg, tiers, bgs["intern"], content, uid, true, true).is_empty(), "the card is gone")
	assert_true(run.apply_card(cfg, tiers, bgs["intern"], content, uid, false, false).is_empty())
	assert_eq(run.energy, energy_after, "nothing paid twice")
	assert_eq(run.referral_tokens, 1, "one token used, not two")
	assert_eq(run.applications.size(), 1)
	assert_eq(run.total_applications, 1)
	assert_eq(run.applied, ["job_big_data_analyst|co_nimbus"])


func test_a_blacklisted_companys_card_is_gone_at_once_and_cannot_be_applied_to() -> void:
	var run := _run("graduate")
	var uid := _card(run, "job_mid_qa", "co_beigeware")
	var other := _card(run, "job_mid_qa", "co_bytebistro")
	run.blacklist_company("co_beigeware")
	assert_true(run.blacklist.has("co_beigeware"))
	assert_eq(run.board.size(), 1, "its card left the board the same day")
	assert_eq(int(run.board[0]["uid"]), other)
	assert_true(run.apply_card(cfg, tiers, bgs["graduate"], content, uid, false, false).is_empty())
	run.board.push_front({"uid": 999, "template_id": "job_mid_mobile", "company_id": "co_beigeware", "tier": "mid",
		"posted_days_ago": 1, "applicants": 150, "is_ghost": false, "reposted": false})
	assert_true(run.apply_card(cfg, tiers, bgs["graduate"], content, 999, false, false).is_empty(),
		"a card of a blacklisted company is never applied to")
	assert_eq(run.energy, 8)
	run.blacklist_company("co_beigeware")
	assert_eq(run.blacklist.count("co_beigeware"), 1, "listed once")


# ---------- the board ----------

func test_a_tier_with_no_free_pairs_deals_nothing_for_that_tier() -> void:
	var run := _run("graduate")
	var postings: Dictionary = content["postings"]
	for template_id: Variant in postings:
		var posting: Variant = postings[template_id]
		if posting is Dictionary and posting["tier"] == "startup":
			for company_id: String in ["co_synergai", "co_quantumleaf", "co_stealth"]:
				run.applied.append(RunState.pair_key(str(template_id), company_id))
	var rng := _rng(31)
	assert_eq(run.deal_board(cfg, tiers, content, rng), 4, "2 mid + 2 big; the startup slots stay empty")
	for card: Dictionary in run.board:
		assert_ne(card["tier"], "startup")
	# The first-run guarantee's fallback then has no startup card: no invite, no crash, Radar kept.
	var first := _run("graduate")
	first.first_run = true
	first.applied = run.applied.duplicate()
	first.pity_count = 2
	for _i: int in 3:
		_app(first, "mid", 0.3, true, true)
	var report := _sleep(first, rng)
	assert_eq(report["guarantee"], "")
	assert_true((report["invites"] as Array).is_empty())
	assert_eq(first.pity_count, 2, "no invite, so nothing to reset")


func test_a_tier_whose_companies_are_all_blacklisted_deals_nothing() -> void:
	var run := _run("graduate")
	var rng := _rng(32)
	run.deal_board(cfg, tiers, content, rng)
	run.blacklist.append_array(["co_omniglobal", "co_nimbus", "co_adverse"])
	for _morning: int in 5:
		run.deal_board(cfg, tiers, content, rng)
		for card: Dictionary in run.board:
			assert_ne(card["tier"], "big", "no Big company left")
	run.blacklist.append_array(["co_beigeware", "co_bytebistro", "co_pixelpivot", "co_synergai", "co_quantumleaf", "co_stealth"])
	assert_eq(run.deal_board(cfg, tiers, content, rng), 0)
	assert_true(run.board.is_empty(), "every card left")


func test_the_board_stays_unique_capped_and_clean_over_many_mornings() -> void:
	var run := _run("self_taught")
	var rng := _rng(33)
	var reposted := 0
	for morning: int in 60:
		run.deal_board(cfg, tiers, content, rng)
		assert_true(run.board.size() <= cfg.board_max)
		var pairs := _pairs_on_board(run)
		for pair: String in pairs:
			assert_eq(pairs.count(pair), 1, "%s shows once (morning %d)" % [pair, morning])
			assert_false(run.applied.has(pair))
		for card: Dictionary in run.board:
			if card["reposted"]:
				reposted += 1
				assert_true(run.dropped.has(RunState.pair_key(card["template_id"], card["company_id"])))
		if morning % 2 == 0 and not run.board.is_empty():
			var card: Dictionary = run.board[run.board.size() - 1]
			run.energy = 10
			run.apply_card(cfg, tiers, bgs["self_taught"], content, int(card["uid"]), false, false)
	assert_gt(reposted, 0, "dropped pairs come back reposted")


func test_ghost_rates_and_ranges_follow_the_tier_numbers() -> void:
	var run := _run("graduate")
	var rng := _rng(34)
	var cards := {"startup": 0, "mid": 0, "big": 0}
	var ghosts := {"startup": 0, "mid": 0, "big": 0}
	var posted_seen := {}
	for _morning: int in 1500:
		run.board.clear()
		run.deal_board(cfg, tiers, content, rng)
		for card: Dictionary in run.board:
			if card["template_id"] == "job_big_future_talent":
				assert_true(card["is_ghost"])
				continue
			var t: String = card["tier"]
			cards[t] = int(cards[t]) + 1
			if card["is_ghost"]:
				ghosts[t] = int(ghosts[t]) + 1
			else:
				posted_seen["%s:%d" % [t, int(card["posted_days_ago"])]] = true
	for t: String in TIER_IDS:
		var rate := float(ghosts[t]) / float(cards[t])
		var expected := (tiers[t] as TierData).ghost_job_rate
		assert_true(absf(rate - expected) < 0.03, "%s ghost rate %.3f vs %.2f" % [t, rate, expected])
		var tier: TierData = tiers[t]
		assert_true(posted_seen.has("%s:%d" % [t, tier.posted_days_min]), "%s reaches its minimum posted days" % t)
		assert_true(posted_seen.has("%s:%d" % [t, tier.posted_days_max]), "%s reaches its maximum posted days" % t)


# ---------- the reveal ----------

func test_reveal_frequencies_follow_p_and_silent_share() -> void:
	var run := _run("graduate")
	for _i: int in 4000:
		_app(run, "big", 0.25, false)
	_sleep(run, _rng(35))
	_sleep(run, _rng(36))
	var report := _sleep(run, _rng(37))
	var invited := 0
	var silent := 0
	var rejected := 0
	for app: Dictionary in run.applications:
		match app["status"]:
			"invited":
				invited += 1
			"silent":
				silent += 1
			"rejected":
				rejected += 1
	assert_eq(invited + silent + rejected, 4000, "all revealed on day 4 (Big: 3 mornings)")
	assert_eq((report["invites"] as Array).size(), invited)
	assert_true(absf(invited / 4000.0 - 0.25) < 0.03, "invite rate %.3f" % (invited / 4000.0))
	var share := silent / float(silent + rejected)
	assert_true(absf(share - (tiers["big"] as TierData).silent_share) < 0.03, "silent share %.3f" % share)


func test_the_radar_fills_and_fires_in_send_order_within_one_morning() -> void:
	var run := _run("graduate")  # N = 8
	run.pity_count = 7
	var a := _app(run, "startup", 0.0)
	var b := _app(run, "startup", 0.0)
	var c := _app(run, "startup", 0.0)
	var report := _sleep(run, _rng(38))
	assert_ne(a["status"], "invited", "a: 7 -> 8, no invite yet")
	assert_eq(b["status"], "invited", "b: the Radar is full -> guaranteed invite")
	assert_ne(c["status"], "invited", "c: 0 -> 1")
	assert_eq((report["invites"][0] as Dictionary)["kind"], "radar")
	assert_eq(run.pity_count, 1)
	assert_eq(report["radar"], {"before": 7, "after": 1, "max": 8})


func test_a_full_radar_skips_ghost_jobs_and_waits_for_a_real_relevant_one() -> void:
	var run := _run("intern")  # N = 6
	run.pity_count = 6
	var ghost := _app(run, "startup", 0.0, true, false, true)
	var irrelevant := _app(run, "startup", 0.0, false)
	var real := _app(run, "startup", 0.0, true)
	_sleep(run, _rng(39))
	assert_eq(ghost["status"], "silent", "a ghost job never replies, Radar or not")
	assert_ne(irrelevant["status"], "invited")
	assert_eq(real["status"], "invited")
	assert_eq(run.pity_count, 0)


func test_any_invite_resets_the_radar_even_an_irrelevant_one() -> void:
	var run := _run("graduate")
	run.pity_count = 5
	var app := _app(run, "startup", 1.0, false)
	_sleep(run, _rng(40))
	assert_eq(app["status"], "invited")
	assert_eq(run.pity_count, 0)


func test_the_radar_stops_at_n() -> void:
	var run := _run("intern")
	for _i: int in 20:
		_app(run, "startup", 0.0)
	var report := _sleep(run, _rng(41))
	var radar_invites := 0
	for invite: Dictionary in report["invites"]:
		if invite["kind"] == "radar":
			radar_invites += 1
	assert_eq(radar_invites, 2, "6 misses, the 7th is the Radar invite; 6 more, the 14th; 6 more")
	assert_eq(run.pity_count, 6)
	assert_eq((report["radar"] as Dictionary)["after"], 6)


func test_reveal_is_in_send_order_across_tiers_on_the_same_morning() -> void:
	# Big sent on day 1 and a startup sent on day 3 both reveal on day 4: the Big one rolls first.
	var quiet := _tiers_with("big", "silent_share", 0.0)
	quiet["startup"] = (quiet["startup"] as TierData).duplicate()
	(quiet["startup"] as TierData).silent_share = 0.0
	for seed_value: int in range(1, 40):
		var run := _run("graduate")
		run.rent_days_left = 30
		var big := _app(run, "big", 0.5, false)
		_sleep(run, _rng(1000 + seed_value), quiet)
		_sleep(run, _rng(2000 + seed_value), quiet)
		var startup := _app(run, "startup", 0.5, false)
		_sleep(run, _rng(seed_value), quiet)
		var replay := _rng(seed_value)
		var expect_big := "invited" if Odds.roll(replay, 0.5) else "rejected"
		if expect_big == "rejected":
			Odds.roll(replay, 0.0)
		var expect_startup := "invited" if Odds.roll(replay, 0.5) else "rejected"
		assert_eq([big["status"], startup["status"]], [expect_big, expect_startup], "seed %d" % seed_value)


func test_knockouts_ghosts_and_radar_invites_use_no_dice() -> void:
	for seed_value: int in range(1, 30):
		var plain := _run("graduate")
		var target_plain := _app(plain, "startup", 0.4, false)
		_sleep(plain, _rng(seed_value))
		var busy := _run("graduate")
		busy.pity_count = 8
		_app(busy, "startup", 0.4, true, true)          # knockout
		_app(busy, "startup", 0.4, true, false, true)   # ghost job
		_app(busy, "startup", 0.0, true)                # Radar invite
		var target_busy := _app(busy, "startup", 0.4, false)
		_sleep(busy, _rng(seed_value))
		assert_eq(target_busy["status"], target_plain["status"], "seed %d: the same dice for the rolled one" % seed_value)


func test_a_knockout_is_rejected_next_morning_even_at_big_and_never_dealt_again() -> void:
	var run := _run("self_taught")
	var rng := _rng(42)
	var uid := _card(run, "job_big_ai_engineer", "co_nimbus")
	var app := run.apply_card(cfg, tiers, bgs["self_taught"], content, uid, false, false)
	assert_eq(app["knockout_reason"], {"id": "knock_degree", "args": {}}, "degree first when both fail")
	assert_eq(app["reveal_day"], 2)
	var report := _sleep(run, rng)
	assert_eq(_app_status(run, uid), "rejected")
	assert_eq((report["rejections"][0] as Dictionary)["mail_id"], "mail_knockout")
	assert_eq(run.pity_count, 0)
	for _morning: int in 20:
		run.deal_board(cfg, tiers, content, rng)
		assert_false(_pairs_on_board(run).has("job_big_ai_engineer|co_nimbus"))


func _app_status(run: RunState, uid: int) -> String:
	for app: Dictionary in run.applications:
		if int(app["uid"]) == uid:
			return app["status"]
	return ""


# ---------- invites, rent and the guarantee ----------

func test_sleeping_on_an_invites_last_valid_day_expires_it() -> void:
	var run := _run("graduate")
	var app := _app(run, "startup", 1.0)
	_sleep(run, _rng(43))                 # day 2: it arrives
	var invite: Dictionary = run.invites[0]
	var report := _sleep(run, _rng(44))   # day 3: its last valid day
	assert_eq(run.invites.size(), 1)
	assert_true((report["expired"] as Array).is_empty())
	report = _sleep(run, _rng(45))        # day 4: filled internally
	assert_true(run.invites.is_empty())
	assert_eq(_uids(report["expired"], "invite_uid"), [int(invite["uid"])])
	assert_eq(app["status"], "expired")
	assert_true(run.take_invite(int(invite["uid"])).is_empty(), "an expired invite can't be taken")


func test_rent_1_to_0_with_an_invite_arriving_gives_one_day_then_plan_b() -> void:
	var run := _run("graduate")
	run.rent_days_left = 1
	_app(run, "startup", 1.0)
	var report := _sleep(run, _rng(46))
	assert_eq(run.rent_days_left, 0)
	assert_true(report["grace_day"])
	assert_false(report["plan_b"])
	assert_false(run.start_day())
	# The invite is still valid tomorrow, but the landlord said ONE day.
	report = _sleep(run, _rng(47))
	assert_eq(run.invites.size(), 1, "still valid on its second day")
	assert_eq(run.rent_days_left, 0, "rent never goes negative")
	assert_false(report["grace_day"])
	assert_true(report["plan_b"])
	assert_true(run.start_day())


func test_rent_already_at_0_with_grace_used_ends_even_when_an_invite_arrives() -> void:
	var run := _run("graduate")
	run.rent_days_left = 0
	run.grace_used = true
	_app(run, "startup", 1.0)
	var report := _sleep(run, _rng(48))
	assert_eq((report["invites"] as Array).size(), 1, "the inbox still reveals")
	assert_true(report["plan_b"])


func test_the_day2_guarantee_never_fires_on_a_later_morning() -> void:
	var run := _run("graduate")
	run.first_run = true
	_sleep(run, _rng(49))  # day 1 with no applications
	for _i: int in 4:
		_app(run, "startup", 0.0, false)
	var report := _sleep(run, _rng(50))
	assert_eq(run.day, 3)
	assert_eq(report["guarantee"], "", "only the morning of day 2")


func test_the_day2_guarantee_is_not_needed_when_an_invite_was_rolled() -> void:
	var run := _run("graduate")
	run.first_run = true
	run.pity_count = 3
	var lucky := _app(run, "startup", 1.0, false)
	_app(run, "mid", 0.5)
	_app(run, "mid", 0.5)
	var report := _sleep(run, _rng(51))
	assert_eq(report["guarantee"], "")
	assert_eq(_uids(report["invites"], "app_uid"), [int(lucky["uid"])])
	assert_eq(run.pity_count, 0, "the rolled invite reset it")


func test_the_profile_fallback_resets_the_radar() -> void:
	var run := _run("graduate")
	run.first_run = true
	run.pity_count = 4
	var rng := _rng(52)
	run.deal_board(cfg, tiers, content, rng)
	for _i: int in 3:
		_app(run, "big", 0.3, true, false, true)  # ghost jobs: not eligible
	var report := _sleep(run, rng)
	assert_eq(report["guarantee"], "profile")
	assert_eq(run.pity_count, 0)
	assert_eq((report["radar"] as Dictionary)["after"], 0)


func test_the_profile_fallback_does_not_depend_on_deck_order() -> void:
	var chosen: Array[int] = []
	for skip_first: bool in [false, true]:
		var run := _run("graduate")
		run.first_run = true
		# Every other startup pair is used up (co_stealth's too, or the dry-deck fallback deals it).
		for template_id: String in ["job_st_founding", "job_st_fullstack_ninja", "job_st_ai_generalist", "job_st_growth",
				"job_st_mobile_barista", "job_st_stealth_swe"]:
			for company_id: String in ["co_synergai", "co_quantumleaf", "co_stealth"]:
				if template_id != "job_st_mobile_barista" or company_id == "co_stealth":
					run.applied.append(RunState.pair_key(template_id, company_id))
		var older := _card(run, "job_st_mobile_barista", "co_synergai")
		var newer := _card(run, "job_st_mobile_barista", "co_quantumleaf")  # same P: a tie
		if skip_first:
			run.skip_card(int(run.board[0]["uid"]))
		for _i: int in 3:
			_app(run, "mid", 0.3, true, true)
		var report := _sleep(run, _rng(53))
		assert_eq(report["guarantee"], "profile")
		chosen.append(int((report["invites"][0] as Dictionary)["app_uid"]))
		assert_true(chosen[-1] == older or chosen[-1] == newer)
	assert_eq(chosen[0], chosen[1], "a skip (not saved) never changes the replayed morning")


func test_a_full_radar_never_climbs_past_n() -> void:
	var run := _run("intern")
	run.pity_count = 6
	_app(run, "startup", 0.0, true, false, true)
	var report := _sleep(run, _rng(54))
	assert_eq(run.pity_count, 6, "a relevant ghost job at a full Radar: still 6 / 6")
	assert_eq(report["radar"], {"before": 6, "after": 6, "max": 6})


func _uids(entries: Array, key: String) -> Array[int]:
	var out: Array[int] = []
	for e: Dictionary in entries:
		out.append(int(e[key]))
	return out


# ---------- plain data and determinism ----------

func test_long_runs_keep_plain_data_and_their_invariants() -> void:
	for bg_id: String in ["intern", "graduate", "self_taught"]:
		var run := _run(bg_id)
		run.first_run = true
		run.rent_days_left = 40
		var rng := _rng(60)
		run.deal_board(cfg, tiers, content, rng)
		for _day: int in 30:
			_play_day(run, rng)
			assert_true(run.pity_count >= 0 and run.pity_count <= (bgs[bg_id] as BackgroundData).pity_n)
			assert_eq(run.energy, cfg.energy_max - run.commute_pips)
			assert_true(run.board.size() <= cfg.board_max)
			for card: Dictionary in run.board:
				assert_false(run.blacklist.has(str(card["company_id"])), "%s: blacklisted card on day %d" % [bg_id, run.day])
			for invite: Dictionary in run.invites:
				assert_true(run.day - int(invite["day_received"]) < cfg.invite_valid_days, "only valid invites wait")
			for app: Dictionary in run.applications:
				assert_true(STATUSES.has(app["status"]), "status %s" % app["status"])
				if app["status"] == "pending":
					assert_true(int(app["reveal_day"]) > run.day, "nothing overdue")
		var problems: Array[String] = []
		_plain_problems(run.to_dict(), "run", problems)
		assert_eq(problems, [] as Array[String], "%s: plain data only %s" % [bg_id, str(problems.slice(0, 5))])
		var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
		var mismatches: Array[String] = []
		_type_mismatches(run.to_dict(), back.to_dict(), "run", mismatches)
		assert_eq(mismatches, [] as Array[String], "%s: ints stay ints, floats stay floats %s" % [bg_id, str(mismatches.slice(0, 5))])


func test_same_seed_same_actions_same_run_with_or_without_nightly_saves() -> void:
	var a := _run("graduate")
	a.first_run = true
	var rng_a := _rng(2027)
	a.deal_board(cfg, tiers, content, rng_a)
	var b := _run("graduate")
	b.first_run = true
	var rng_b := _rng(2027)
	b.deal_board(cfg, tiers, content, rng_b)
	for _day: int in 12:
		_play_day(a, rng_a)
		_play_day(b, rng_b)
		# b is saved and reloaded every night, the way Continue would.
		b.rng_seed = str(rng_b.seed)
		b.rng_state = str(rng_b.state)
		b = RunState.from_dict(JSON.parse_string(JSON.stringify(b.to_dict())))
		rng_b = RandomNumberGenerator.new()
		rng_b.seed = b.rng_seed.to_int()
		rng_b.state = b.rng_state.to_int()
	a.rng_seed = str(rng_a.seed)
	a.rng_state = str(rng_a.state)
	var mismatches: Array[String] = []
	_type_mismatches(a.to_dict(), b.to_dict(), "run", mismatches)
	assert_eq(mismatches, [] as Array[String], "bit for bit, frozen P included %s" % str(mismatches.slice(0, 5)))
	assert_eq(rng_a.state, rng_b.state)
	assert_gt(a.applications.size(), 10, "the bot really played")

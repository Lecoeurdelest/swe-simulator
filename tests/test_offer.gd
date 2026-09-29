@tool
extends McpTestSuite
## GDD 5.9: salary, negotiation, Dream vs Reality examples; the whole offer RunState.make_offer builds
## from the interview checkpoint (S10), its tip, the grace-day Decline, and the Accept that a kill on
## the Hired card replays (5.11). Pure: tiers and backgrounds from the .tres, the JSON read with
## FileAccess, saves through JSON strings, never user:// or an autoload (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
## One posting and one MVP company per tier (CONTENT.md 4, 5).
const POSTING := {"startup": "job_st_mobile_barista", "mid": "job_mid_backend", "big": "job_big_junior_swe"}
const COMPANY := {"startup": "co_synergai", "mid": "co_beigeware", "big": "co_nimbus"}

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "offer"


func suite_setup(_ctx: Dictionary) -> void:
	for id: String in TIER_IDS:
		tiers[id] = load("res://data/tiers/%s.tres" % id)
	for id: String in ["intern", "graduate", "self_taught"]:
		bgs[id] = load("res://data/backgrounds/%s.tres" % id)
	for file: String in ["postings", "companies", "cv_lines", "emails"]:
		content[file] = JSON.parse_string(FileAccess.get_file_as_string("res://data/content/%s.json" % file))


func setup() -> void:
	cfg = BalanceConfig.new()


## A run of this background with a won interview's checkpoint at a tier (seed as start_interview
## writes it: a String).
func _won(bg_id: String, tier_id: String, interview_seed: String) -> RunState:
	var run := RunState.new()
	run.set_background(cfg, bgs[bg_id])
	run.interview = {
		"invite_uid": 5, "company_id": COMPANY[tier_id], "template_id": POSTING[tier_id], "tier": tier_id,
		"seed": interview_seed, "question_ids": [], "warmup_id": "", "tired": false,
	}
	return run


func _offer(bg_id: String, tier_id: String, interview_seed: String, composure: float = 80.0) -> Dictionary:
	var run := _won(bg_id, tier_id, interview_seed)
	return run.make_offer(cfg, tiers[tier_id], bgs[bg_id], content, composure)


func _tiers_of(id: String) -> Array:
	return ((content["emails"] as Dictionary)[id] as Dictionary).get("tiers", [])


## Every value, however deep, is plain JSON-able data: no Object, no StringName (INV-07).
func _assert_plain(value: Variant, where: String) -> void:
	match typeof(value):
		TYPE_DICTIONARY:
			for key: Variant in value:
				assert_eq(typeof(key), TYPE_STRING, "%s: key %s is a String" % [where, key])
				_assert_plain(value[key], "%s.%s" % [where, key])
		TYPE_ARRAY:
			for item: Variant in value:
				_assert_plain(item, where + "[]")
		_:
			assert_true(typeof(value) in [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL],
				"%s is plain data (type %d)" % [where, typeof(value)])


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


## GDD S10 / 5.9: a Mid offer for the Graduate holds every contract field, as plain data.
func test_make_offer_builds_the_whole_contract() -> void:
	var run := _won("graduate", "mid", "123456789")
	var made := run.make_offer(cfg, tiers["mid"], bgs["graduate"], content, 80.0)
	assert_eq(made, run.offer, "returns a copy of run.offer")
	assert_eq(made["company_id"], "co_beigeware")
	assert_eq(made["template_id"], "job_mid_backend")
	assert_eq(made["tier"], "mid")
	assert_eq(made["job_title"], "Backend Developer", "the posting's title")
	assert_eq(made["salary"], Odds.offer_salary(cfg, tiers["mid"], bgs["graduate"], 80.0, 100.0), "GDD 5.9.2")
	assert_eq(made["salary"], 81000, "65k-90k at band 0.65 = 81,250, x1.00, rounded to $1,000")
	assert_eq(made["work_mode"], "offer_mode_mid")
	assert_eq(made["office_days"], 2)
	assert_eq(made["commute"], {"id": "offer_commute_office",
		"args": {"office_days": 2, "commute_min": 45, "hours": "3.0"}}, "the Graduate's 45 minutes")
	assert_eq((made["perks"] as Array).size(), RunState.OFFER_PERKS)
	assert_true(str(made["fine_print"]).begins_with("fp_"), "one fine-print id")
	assert_eq(made["equity_text"], "", "no equity off startups")
	assert_eq(made["negotiated"], false)
	_assert_plain(made, "offer")


## Two different perks and one fine print, all listed for the offer's tier (CONTENT.md 13.2-13.3).
func test_perks_and_fine_print_match_the_tier() -> void:
	for tier_id: String in TIER_IDS:
		for i: int in 25:
			var made := _offer("intern", tier_id, str(1000 + i * 7919))
			var perks: Array = made["perks"]
			assert_eq(perks.size(), 2, "%s: 2 perks" % tier_id)
			assert_ne(perks[0], perks[1], "%s: 2 different perks" % tier_id)
			for perk: Variant in perks:
				assert_true(str(perk).begins_with("perk_") and _tiers_of(str(perk)).has(tier_id),
					"%s: %s is a %s perk" % [tier_id, perk, tier_id])
			var fine := str(made["fine_print"])
			assert_true(fine.begins_with("fp_") and _tiers_of(fine).has(tier_id),
				"%s: %s is %s fine print" % [tier_id, fine, tier_id])


## REVIEW_QUEUE 3: the fine print never repeats a dealt perk (fp_<x> vs perk_<x>), so a startup
## paper never lists "Unlimited PTO*" as both a perk and the fine print.
func test_fine_print_never_repeats_a_perk() -> void:
	var emails: Dictionary = content["emails"]
	assert_true(emails.has("perk_unlimited_pto") and emails.has("fp_unlimited_pto"), "the pair this guards")
	assert_false(RunState.fine_print_pool(emails, "startup", ["perk_unlimited_pto", "perk_pingpong"]).has("fp_unlimited_pto"),
		"left out when its perk is dealt")
	assert_true(RunState.fine_print_pool(emails, "startup", ["perk_kombucha", "perk_pingpong"]).has("fp_unlimited_pto"),
		"still dealt when its perk is not")
	var problems: Array[String] = []
	var pto_papers := 0
	for i: int in 200:
		var made := _offer("intern", "startup", str(i * 7919 + 3))
		var perks: Array = made["perks"]
		if perks.has("perk_unlimited_pto"):
			pto_papers += 1
		if perks.has("perk_" + str(made["fine_print"]).trim_prefix("fp_")):
			problems.append("seed %d: %s with %s" % [i, made["fine_print"], perks])
	assert_gt(pto_papers, 0, "some papers dealt the PTO perk")
	assert_true(problems.is_empty(), "%d paper(s) repeat a perk:\n  %s" % [problems.size(), "\n  ".join(PackedStringArray(problems))])


## The contract is picked on an RNG seeded from the checkpoint: the same interview (a resume replays
## it) gives the same contract, different interviews vary, and no other RNG is involved.
func test_same_checkpoint_same_contract() -> void:
	for tier_id: String in TIER_IDS:
		assert_eq(_offer("graduate", tier_id, "987654321"), _offer("graduate", tier_id, "987654321"),
			"%s: rebuilt from the same checkpoint" % tier_id)
	var seen: Dictionary = {}
	for i: int in 30:
		var made := _offer("graduate", "big", str(i * 104729 + 1))
		seen[str(made["perks"]) + str(made["fine_print"])] = true
	assert_gt(seen.size(), 3, "30 interviews do not all get the same perks and fine print")
	var a := RunState.offer_rng("42")
	var b := RunState.offer_rng("42")
	assert_eq([a.randi(), a.randi()], [b.randi(), b.randi()], "offer_rng is deterministic")
	var iv := InterviewPlan.interview_rng("42")
	assert_ne(RunState.offer_rng("42").seed, iv.seed, "the offer's dice are not the interview's")


## GDD 7 and S10: a startup offer is fully remote (the remote commute line) and carries the joke equity.
func test_startup_offer_is_remote_with_equity() -> void:
	var made := _offer("intern", "startup", "31337", 96.925)
	assert_eq(made["job_title"], "Mobile Dev (Also Barista)")
	assert_eq(made["salary"], 71000, "GDD 5.9.2 example: $71,000 at Hierarchai")
	assert_eq(made["work_mode"], "offer_mode_startup")
	assert_eq(made["office_days"], 0)
	assert_eq(made["commute"], {"id": "offer_commute_remote", "args": {}})
	assert_eq(made["equity_text"], "offer_equity")
	var big := _offer("self_taught", "big", "31337")
	assert_eq(big["commute"]["args"], {"office_days": 4, "commute_min": 95, "hours": "12.7"},
		"GDD S10: 4 days x 95 min each way = 12.7 h a week")
	assert_eq(big["equity_text"], "")


## GDD S10: values wrap at 28 columns after the 12-column labels, the fine print in 4 lines at most,
## and the whole paper stays about 250 px tall (20 lines of 12 px + the panel's 14 px) at every tier.
func test_contract_fits_the_paper() -> void:
	var emails: Dictionary = content["emails"]
	var value_columns := 40 - 12
	for id: String in emails:
		if id.begins_with("fp_"):
			assert_true(UiText.word_wrap(str(emails[id]["text"]), value_columns).size() <= 4, "%s: 4 lines at most" % id)
		elif id.begins_with("perk_"):
			assert_true(UiText.word_wrap(str(emails[id]["text"]), value_columns).size() <= 2, "%s: 2 lines at most" % id)
	var companies: Dictionary = content["companies"]
	var postings: Dictionary = content["postings"]
	for tier_id: String in TIER_IDS:
		var title_lines := 0
		for company: String in companies:
			if str(companies[company]["tier"]) == tier_id:
				var title := str(emails["offer_title"]).format({"company": companies[company]["name"]})
				title_lines = maxi(title_lines, UiText.word_wrap(title, 40).size())
		var role_lines := 0
		for posting: String in postings:
			if postings[posting] is Dictionary and str(postings[posting]["tier"]) == tier_id:
				var role := str(emails["offer_role"]).format({"job_title": postings[posting]["title"]})
				role_lines = maxi(role_lines, UiText.word_wrap(role, 40).size())
		var perk_lines: Array[int] = []
		var fine_lines := 0
		for id: String in emails:
			if id.begins_with("perk_") and _tiers_of(id).has(tier_id):
				perk_lines.append(UiText.word_wrap(str(emails[id]["text"]), value_columns).size())
			elif id.begins_with("fp_") and _tiers_of(id).has(tier_id):
				fine_lines = maxi(fine_lines, UiText.word_wrap(str(emails[id]["text"]), value_columns).size())
		perk_lines.sort()
		# title + Dear + role + blank + salary (+ equity) + work mode + commute (2) + 2 perks + fine print + deadline
		var lines := title_lines + 1 + role_lines + 1 + 1 + (1 if tier_id == "startup" else 0) + 1 + 2 \
			+ perk_lines[-1] + perk_lines[-2] + fine_lines + 1
		assert_true(lines <= 20, "%s: the longest contract has %d lines" % [tier_id, lines])


func test_commute_hours() -> void:
	assert_eq(RunState.offer_commute(4, 95)["args"]["hours"], "12.7", "Self-Taught at a big corp")
	assert_eq(RunState.offer_commute(4, 20)["args"]["hours"], "2.7", "Intern at a big corp")
	assert_eq(RunState.offer_commute(2, 20)["args"]["hours"], "1.3", "Intern at a mid-size")
	assert_eq(RunState.offer_commute(0, 95)["id"], "offer_commute_remote", "no office days: remote")


func test_offer_survives_the_save() -> void:
	var run := _won("self_taught", "startup", "555")
	run.make_offer(cfg, tiers["startup"], bgs["self_taught"], content, 45.5)
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(back.offer, run.offer, "the whole contract round-trips")
	assert_eq(typeof(back.offer["salary"]), TYPE_INT, "the salary comes back as an int")
	assert_eq(typeof(back.offer["commute"]["args"]), TYPE_DICTIONARY)


## GDD 8.1 rule 2, 8.3: one tip on the offer. Startups: the equity lottery; others: total comp.
func test_offer_tip() -> void:
	for tier_id: String in TIER_IDS:
		var run := _won("graduate", tier_id, "77")
		run.make_offer(cfg, tiers[tier_id], bgs["graduate"], content, 60.0)
		assert_eq(HuntTips.offer(run), "tip_equity_lottery" if tier_id == "startup" else "tip_total_comp", tier_id)


## GDD 5.10: Decline is Plan B only on the grace day (rent at 0).
func test_decline_ends_the_run_only_at_zero_rent() -> void:
	var run := RunState.new()
	run.rent_days_left = 0
	assert_true(run.decline_ends_run(), "grace day: Decline ends the run")
	run.rent_days_left = 1
	assert_false(run.decline_ends_run(), "rent left: back to the hunt")


## GDD 5.11: a kill on the Hired card resumes at the offer (its save was written on entering OFFER,
## PHASE2_STUB is never saved). Accepting again hires with the same contract and the same Dream
## score, and Accept rolls no dice (D9: no background check), so the run RNG never moves.
func test_accept_after_a_hired_kill_hires_the_same_job() -> void:
	for seed_value: int in range(1, 41):
		var run := _won("intern", "big", str(seed_value * 31))
		run.make_offer(cfg, tiers["big"], bgs["intern"], content, 70.0)
		run.interview = {}
		run.phase = GameFlow.Phase.OFFER
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		rng.randi()
		run.rng_seed = str(seed_value)
		run.rng_state = str(rng.state)  # what GameState.save() writes on entering OFFER
		var saved := JSON.stringify(run.to_dict())
		var flags: Array = content["companies"][COMPANY["big"]]["red_flags"]
		run.hire(cfg, bgs["intern"], flags)
		var back := RunState.from_dict(JSON.parse_string(saved))
		assert_eq(back.phase, GameFlow.Phase.OFFER, "Continue resumes at the offer")
		assert_eq(back.offer, run.offer, "the same contract")
		back.hire(cfg, bgs["intern"], flags)
		assert_eq(back.employment, run.employment, "seed %d: the same job" % seed_value)
		assert_eq(back.dream_score, run.dream_score, "seed %d: the same Dream score" % seed_value)
		assert_eq(back.rng_state, str(rng.state), "seed %d: Accept rolls no dice" % seed_value)

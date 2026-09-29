@tool
extends McpTestSuite
## Applying (GDD 5.4, 5.6) through the real RunState path: the tags and gates actually sent, knockouts,
## relevance, P_invite, referrals, energy. The GDD 5.6 worked examples run end to end here.
## Loads the real .tres and JSON with load() / FileAccess, never the Content autoload (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_apply"


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


## Puts one known card on top of the board and returns its uid.
func _card(run: RunState, template_id: String, company_id: String, is_ghost: bool = false) -> int:
	var posting: Dictionary = content["postings"][template_id]
	var uid := run.new_uid()
	run.board.push_front({
		"uid": uid, "template_id": template_id, "company_id": company_id, "tier": posting["tier"],
		"posted_days_ago": 3, "applicants": 200, "is_ghost": is_ghost, "reposted": false,
	})
	return uid


func _apply(run: RunState, uid: int, tailored: bool, referral: bool = false) -> Dictionary:
	return run.apply_card(cfg, tiers, bgs[run.background_id], content, uid, tailored, referral)


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


func test_quick_sends_the_honest_cv_and_tailor_the_polished_one() -> void:
	var cv: Dictionary = content["cv_lines"]
	var graduate := _run("graduate")
	var honest := graduate.cv_sent(cv, false)
	assert_eq(honest["tags"], ["java", "python", "sql", "git"], "Graduate honest: 4 tags")
	assert_eq(honest["line_ids"], ["cv_graduate_edu_honest", "cv_graduate_exp_honest", "cv_graduate_proj_honest"])
	var tailored := graduate.cv_sent(cv, true)
	assert_eq(tailored["tags"], ["java", "data", "python", "agile", "sql", "git", "apis"], "Tailor sends every line Polished: +3 tags")
	assert_eq((_run("intern").cv_sent(cv, false)["tags"] as Array).size(), 5, "Intern honest: 5 tags")
	assert_eq((_run("self_taught").cv_sent(cv, false)["tags"] as Array).size(), 6, "Self-Taught honest: 6 tags")
	assert_eq(tailored["line_ids"], ["cv_graduate_edu_polished", "cv_graduate_exp_polished", "cv_graduate_proj_polished"])


func test_gates_come_from_the_lines_sent() -> void:
	var cv: Dictionary = content["cv_lines"]
	var graduate := _run("graduate")
	assert_true(graduate.cv_sent(cv, false)["degree"], "the Diploma")
	assert_false(graduate.cv_sent(cv, false)["passes_years"], "TA work isn't 1+ years")
	assert_true(graduate.cv_sent(cv, true)["passes_years"], "Polished Experience passes the years knockout")
	assert_true(_run("intern").cv_sent(cv, false)["passes_years"], "the Intern's honest line passes")
	var self_taught := _run("self_taught")
	assert_false(self_taught.cv_sent(cv, false)["degree"], "no degree")
	assert_false(self_taught.cv_sent(cv, true)["degree"], "no degree, even tailored: only a referral skips a degree knockout")


func test_example_1_quick_apply_is_knocked_out_and_rejected_next_morning() -> void:
	var run := _run("graduate")
	var uid := _card(run, "job_mid_backend", "co_beigeware")
	var app := _apply(run, uid, false)
	assert_true(app["knockout"], "Honest TA line fails 1+ years")
	assert_eq(app["knockout_reason"], {"id": "knock_years", "args": {"n": 1}})
	assert_eq(app["reveal_day"], 2, "a knockout replies the next morning (a Mid reply takes 2)")
	assert_eq(run.energy, 8 - cfg.cost_quick_apply)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var report := run.sleep(cfg, tiers, bgs["graduate"], content, rng)
	assert_eq((report["rejections"] as Array).size(), 1)
	var rejection: Dictionary = report["rejections"][0]
	assert_eq(rejection["app_uid"], uid)
	assert_eq(rejection["mail_id"], "mail_knockout")
	assert_eq(rejection["knockout"], {"id": "knock_years", "args": {"n": 1}}, "the email names the knockout")
	assert_eq(run.total_rejections, 1)


func test_example_1_tailor_and_apply_is_16_8_percent() -> void:
	var run := _run("graduate")
	var app := _apply(run, _card(run, "job_mid_backend", "co_beigeware"), true)
	assert_false(app["knockout"], "the Polished Experience line passes 1+ years")
	assert_eq(app["hits"], 3, "APIs now matches: M = 3/3")
	assert_true(app["relevant"])
	_near(app["p"], 0.168, 0.0005, "Graduate, Mid, Tailor, M = 3/3")
	assert_eq(Odds.odds_band(cfg, app["p"]), 4, "[####-] Decent")
	assert_eq(app["reveal_day"], 3, "Mid replies in 2 mornings")
	assert_eq(run.energy, 8 - cfg.cost_tailor_apply)


func test_example_2_self_taught_startup_quick_12_3_tailored_30_7() -> void:
	var run := _run("self_taught")
	var quick := _apply(run, _card(run, "job_st_mobile_barista", "co_synergai"), false)
	var tailored := _apply(run, _card(run, "job_st_mobile_barista", "co_quantumleaf"), true)
	assert_eq(quick["hits"], 3, "honest tags already match 3/3")
	_near(quick["p"], 0.123, 0.0005, "Quick Apply")
	_near(tailored["p"], 0.307, 0.0005, "Tailor & Apply")
	assert_eq(quick["reveal_day"], 2, "startups reply the next morning")
	assert_eq(run.energy, 6 - 1 - 2)


func test_example_3_intern_referral_is_19_percent_and_skips_knockouts() -> void:
	var run := _run("intern")
	assert_eq(run.referral_tokens, 2)
	var app := _apply(run, _card(run, "job_big_junior_swe", "co_omniglobal"), true, true)
	assert_eq(app["hits"], 2, "Testing and Agile: M = 2/3")
	_near(app["p"], 0.190, 0.0005, "Intern, Big, referral")
	assert_false(app["knockout"], "a human reads it: no knockouts")
	assert_true(app["referral"])
	assert_eq(run.referral_tokens, 1, "one token used")
	assert_eq(run.energy, 9 - cfg.cost_tailor_apply, "a referral costs no extra energy")


func test_referral_skips_a_degree_knockout() -> void:
	var run := _run("self_taught")
	var without := _apply(run, _card(run, "job_big_cloud_associate", "co_nimbus"), true)
	assert_eq(without["knockout_reason"], {"id": "knock_degree", "args": {}})
	run.referral_tokens = 1
	var with_referral := _apply(run, _card(run, "job_big_cloud_associate", "co_omniglobal"), true, true)
	assert_false(with_referral["knockout"])
	assert_eq(with_referral["knockout_reason"], {})
	assert_eq(with_referral["reveal_day"], 1 + (tiers["big"] as TierData).reply_delay_days)


func test_a_referral_needs_a_token_and_every_apply_needs_energy() -> void:
	var run := _run("graduate")
	var uid := _card(run, "job_mid_qa", "co_bytebistro")
	assert_true(_apply(run, uid, true, true).is_empty(), "the Graduate has no referral tokens")
	assert_eq(run.energy, 8, "nothing was paid")
	run.energy = 1
	assert_true(_apply(run, uid, true).is_empty(), "Tailor costs 2")
	assert_eq(run.board.size(), 1, "the card stays")
	assert_false(_apply(run, uid, false).is_empty(), "Quick costs 1")
	assert_eq(run.energy, 0)
	assert_true(_apply(run, uid, false).is_empty(), "the card is gone")


func test_the_application_record() -> void:
	var run := _run("graduate")
	run.day = 4
	var uid := _card(run, "job_st_growth", "co_synergai", true)
	var app := _apply(run, uid, true)
	assert_eq(app["uid"], uid, "the application keeps the card's uid")
	assert_eq([app["template_id"], app["company_id"], app["tier"]], ["job_st_growth", "co_synergai", "startup"])
	assert_eq(app["day_sent"], 4)
	assert_eq(app["reveal_day"], 5)
	assert_true(app["is_ghost"], "the hidden ghost flag travels with it")
	assert_true(app["tailored"])
	assert_false(app["referral"])
	assert_eq(app["status"], "pending", "outcomes are rolled on the reveal morning, not now")
	assert_eq(run.applications, [app])
	assert_true(run.applied.has("job_st_growth|co_synergai"))
	assert_true(run.board.is_empty(), "applied cards leave the deck")
	assert_eq(run.total_applications, 1)


## D9: nothing you send is a lie, so an application records none and the run carries none.
func test_an_application_records_no_lies() -> void:
	var run := _run("graduate")
	var quick := _apply(run, _card(run, "job_mid_qa", "co_beigeware"), false)
	var tailored := _apply(run, _card(run, "job_mid_platform", "co_beigeware"), true)
	for app: Dictionary in [quick, tailored]:
		assert_false(app.has("lies"))
	for key: String in ["quick", "tailored", "referral"]:
		var quote: Dictionary = run.card_odds(cfg, tiers, bgs["graduate"], content,
			{"uid": 99, "template_id": "job_mid_backend", "company_id": "co_beigeware", "tier": "mid"})[key]
		assert_false(quote.has("lies"), key)
	assert_false(run.to_dict().has("lies_carried"))


func test_card_odds_bands_and_knockout_chip() -> void:
	var run := _run("graduate")
	var uid := _card(run, "job_mid_backend", "co_beigeware")
	var odds := run.card_odds(cfg, tiers, bgs["graduate"], content, run.board[0])
	assert_eq(odds["tags"], [{"tag": "java", "hit": true}, {"tag": "sql", "hit": true}, {"tag": "apis", "hit": false}])
	var quick: Dictionary = odds["quick"]
	var tailored: Dictionary = odds["tailored"]
	var referral: Dictionary = odds["referral"]
	assert_eq(quick["band"], 2, "front: [##---] Unlikely")
	assert_eq(quick["knockout"], {"id": "knock_years", "args": {"n": 1}}, "front: the red knockout chip")
	assert_eq(tailored["band"], 4, "back: [####-] Decent")
	assert_eq(tailored["knockout"], {}, "tailoring clears the chip")
	_near(referral["p"], 0.42, 0.001, "tailored x2.5")
	assert_eq(referral["band"], 5)
	assert_eq(run.board[0]["uid"], uid, "showing odds changes nothing")
	assert_eq(run.energy, 8)

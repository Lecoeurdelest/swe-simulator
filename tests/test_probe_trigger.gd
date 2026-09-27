@tool
extends McpTestSuite
## GDD 5.8.5 lie-probe trigger (RunState.roll_probe, rolled by GameState.start_interview before the
## checkpoint is frozen) and the GDD 5.9.4 degree background check on Accept
## (RunState.background_check_caught, rescind_offer). The real cv_lines and postings; the Content
## autoload is never touched (INV-12).

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "probe_trigger"


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
	return run


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## A tier with one number changed (never modify the loaded .tres, INV-08).
func _tier(tier_id: String, field: String, value: Variant) -> TierData:
	var copy: TierData = (tiers[tier_id] as TierData).duplicate()
	copy.set(field, value)
	return copy


## An application to template_id at company_id that sent these Lie lines; returns its uid.
func _sent(run: RunState, template_id: String, company_id: String, lies: Array) -> int:
	var uid := run.new_uid()
	var sent_lies: Array[String] = []
	sent_lies.assign(lies)
	run.applications.append({
		"uid": uid, "template_id": template_id, "company_id": company_id,
		"tier": content["postings"][template_id]["tier"], "day_sent": run.day, "reveal_day": run.day + 1,
		"p": 0.1, "hits": 2, "relevant": true, "knockout": false, "knockout_reason": {},
		"is_ghost": false, "referral": false, "tailored": true, "lies": sent_lies, "status": "interview",
	})
	return uid


# ---------- the lie probe (GDD 5.8.5) ----------

func test_no_lie_sent_means_no_probe_and_no_dice() -> void:
	var run := _run("graduate")
	var uid := _sent(run, "job_mid_backend", "co_beigeware", [])
	var rng := _rng(1)
	var before := rng.state
	assert_eq(run.roll_probe(cfg, _tier("mid", "lie_probe_chance", 1.0), content, uid, rng), "")
	assert_eq(rng.state, before)
	assert_eq(run.roll_probe(cfg, _tier("mid", "lie_probe_chance", 1.0), content, 999, rng), "",
		"no application (a 'saw your profile' invite): nothing was sent, so nothing to probe")
	assert_eq(rng.state, before)


func test_a_lie_counts_only_when_it_shares_a_tag_with_the_posting() -> void:
	var run := _run("graduate")
	var sure := _tier("mid", "lie_probe_chance", 1.0)
	# The Graduate's Experience lie (python, agile, testing) vs Mobile (mobile, apis, git): no overlap.
	var off_topic := _sent(run, "job_mid_mobile", "co_beigeware", ["cv_graduate_exp_lie"])
	var rng := _rng(2)
	var before := rng.state
	assert_eq(run.roll_probe(cfg, sure, content, off_topic, rng), "", "Dana doesn't ask about what the job doesn't need")
	assert_eq(rng.state, before, "no roll for a line that doesn't count")
	# The Projects lie (sql, git, apis, ai) vs Backend (java, sql, apis): it counts.
	var on_topic := _sent(run, "job_mid_backend", "co_beigeware", ["cv_graduate_proj_lie"])
	assert_eq(run.roll_probe(cfg, sure, content, on_topic, rng), "cv_graduate_proj_lie")


func test_a_degree_claim_always_counts() -> void:
	var run := _run("intern")
	# "M.Sc. AI, Very Famous University" (python, data, ai) shares nothing with Mobile (mobile, apis, git).
	var uid := _sent(run, "job_mid_mobile", "co_beigeware", ["cv_intern_edu_lie"])
	assert_eq(run.roll_probe(cfg, _tier("mid", "lie_probe_chance", 1.0), content, uid, _rng(3)), "cv_intern_edu_lie")


func test_one_probe_at_most_the_first_counting_line_in_cv_order() -> void:
	var run := _run("intern")
	var uid := _sent(run, "job_mid_backend", "co_beigeware", ["cv_intern_edu_lie", "cv_intern_exp_lie", "cv_intern_proj_lie"])
	var rng := _rng(4)
	var one_roll := _rng(4)
	Odds.roll(one_roll, 1.0)
	assert_eq(run.roll_probe(cfg, _tier("mid", "lie_probe_chance", 1.0), content, uid, rng), "cv_intern_edu_lie")
	assert_eq(rng.state, one_roll.state, "it stops rolling at the first hit")
	# The first line missing its roll hands the probe to the next counting line.
	var never_first := 0
	for seed_value: int in range(1, 200):
		var line := run.roll_probe(cfg, tiers["mid"], content, uid, _rng(seed_value))
		assert_true(line in ["", "cv_intern_edu_lie", "cv_intern_exp_lie"], "Projects (git, cloud, mobile) never counts at Backend")
		if line == "cv_intern_exp_lie":
			never_first += 1
	assert_gt(never_first, 0, "the Experience lie gets probed when the degree claim's roll misses")


func test_zero_chance_or_zero_max_probes_never_probes() -> void:
	var run := _run("intern")
	var uid := _sent(run, "job_big_ai_engineer", "co_nimbus", ["cv_intern_edu_lie", "cv_intern_exp_lie"])
	for seed_value: int in range(1, 50):
		assert_eq(run.roll_probe(cfg, _tier("big", "lie_probe_chance", 0.0), content, uid, _rng(seed_value)), "")
	cfg.max_probes_per_interview = 0
	var rng := _rng(5)
	var before := rng.state
	assert_eq(run.roll_probe(cfg, _tier("big", "lie_probe_chance", 1.0), content, uid, rng), "")
	assert_eq(rng.state, before, "probes off: no dice")


func test_the_probe_rate_follows_the_tier_chance_and_replays() -> void:
	var run := _run("graduate")
	var uid := _sent(run, "job_mid_backend", "co_beigeware", ["cv_graduate_proj_lie"])  # one counting line
	for tier_id: String in TIER_IDS:
		var tier: TierData = tiers[tier_id]
		var probed := 0
		for seed_value: int in range(1, 4001):
			if run.roll_probe(cfg, tier, content, uid, _rng(seed_value)) != "":
				probed += 1
		var rate := probed / 4000.0
		assert_true(absf(rate - tier.lie_probe_chance) < 0.03, "%s: %.3f vs %.2f" % [tier_id, rate, tier.lie_probe_chance])
	assert_eq(run.roll_probe(cfg, tiers["big"], content, uid, _rng(77)), run.roll_probe(cfg, tiers["big"], content, uid, _rng(77)),
		"the same run RNG state, the same probe (a resume never re-rolls it: it is frozen in the checkpoint)")


func test_the_lies_recorded_by_apply_card_are_the_ones_probed() -> void:
	var run := _run("intern")
	run.cv_levels["edu"] = "lie"
	var uid := run.new_uid()
	run.board.append({"uid": uid, "template_id": "job_mid_mobile", "company_id": "co_beigeware", "tier": "mid",
		"posted_days_ago": 2, "applicants": 200, "is_ghost": false, "reposted": false})
	var app := run.apply_card(cfg, tiers, bgs["intern"], content, uid, true, false)
	assert_eq(app["lies"], ["cv_intern_edu_lie"])
	assert_eq(run.roll_probe(cfg, _tier("mid", "lie_probe_chance", 1.0), content, uid, _rng(6)), "cv_intern_edu_lie")


# ---------- the degree background check (GDD 5.9.4) ----------

func test_no_degree_claim_means_no_check_and_no_dice() -> void:
	var run := _run("graduate")
	# "B.Sc. in 2 years while working full-time" is a Lie, but the degree is real: no degree claim.
	_sent(run, "job_big_ai_engineer", "co_nimbus", ["cv_graduate_edu_lie", "cv_graduate_exp_lie"])
	var rng := _rng(7)
	var before := rng.state
	assert_false(run.background_check_caught(_tier("big", "background_check", 1.0), content, "co_nimbus", rng))
	assert_eq(rng.state, before)


func test_an_unconfessed_degree_claim_rolls_the_tier_chance_once() -> void:
	var run := _run("intern")
	_sent(run, "job_big_ai_engineer", "co_nimbus", ["cv_intern_edu_lie"])
	_sent(run, "job_big_data_analyst", "co_nimbus", ["cv_intern_edu_lie"])  # sent twice: still one check
	for tier_id: String in TIER_IDS:
		var tier: TierData = tiers[tier_id]
		var caught := 0
		for seed_value: int in range(1, 4001):
			if run.background_check_caught(tier, content, "co_nimbus", _rng(seed_value)):
				caught += 1
		var rate := caught / 4000.0
		assert_true(absf(rate - tier.background_check) < 0.03, "%s: %.3f vs %.2f" % [tier_id, rate, tier.background_check])
	var rng := _rng(8)
	var one_roll := _rng(8)
	Odds.roll(one_roll, 0.5)
	run.background_check_caught(tiers["big"], content, "co_nimbus", rng)
	assert_eq(rng.state, one_roll.state, "one roll, however many times the lie was sent")


func test_a_confessed_degree_claim_or_another_companys_lie_is_never_checked() -> void:
	var run := _run("self_taught")
	_sent(run, "job_big_cloud_associate", "co_omniglobal", ["cv_self_taught_edu_lie"])
	_sent(run, "job_big_ai_engineer", "co_nimbus", ["cv_self_taught_edu_lie"])
	run.settle_probe("co_nimbus", "cv_self_taught_edu_lie", true, false)  # came clean to Dana at Nimbus
	var sure := _tier("big", "background_check", 1.0)
	var rng := _rng(9)
	var before := rng.state
	assert_false(run.background_check_caught(sure, content, "co_nimbus", rng), "confessed here: no check")
	assert_false(run.background_check_caught(sure, content, "co_adverse", rng), "never lied to this company")
	assert_eq(rng.state, before)
	assert_true(run.background_check_caught(sure, content, "co_omniglobal", rng), "the confession was for Nimbus only")


func test_a_rescinded_offer_blacklists_and_keeps_its_mail_until_sleep() -> void:
	var run := _run("intern")
	run.offer = {"company_id": "co_nimbus", "template_id": "job_big_ai_engineer", "tier": "big", "salary": 110000,
		"office_days": 4, "negotiated": false}
	var other := _sent(run, "job_big_data_analyst", "co_nimbus", [])
	run.invites.append({"uid": run.new_uid(), "app_uid": other, "company_id": "co_nimbus", "template_id": "job_big_data_analyst",
		"tier": "big", "day_received": run.day, "kind": "rolled", "mail_id": "mail_invite_big"})
	run.board.append({"uid": run.new_uid(), "template_id": "job_big_frontend", "company_id": "co_nimbus", "tier": "big",
		"posted_days_ago": 4, "applicants": 2000, "is_ghost": false, "reposted": false})
	run.rescind_offer()
	assert_true(run.offer.is_empty())
	assert_eq(run.rescinded, {"company_id": "co_nimbus", "template_id": "job_big_ai_engineer", "tier": "big", "mail_id": "mail_rescinded"})
	assert_has_key(content["emails"], "mail_rescinded")
	assert_true(run.blacklist.has("co_nimbus"))
	assert_true(run.invites.is_empty(), "its other invite is withdrawn")
	assert_true(run.board.is_empty(), "its cards leave the board")
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(run.to_dict())))
	assert_eq(back.rescinded, run.rescinded, "a kill keeps the mail")
	run.sleep(cfg)
	assert_true(run.rescinded.is_empty(), "the next Sleep clears it")

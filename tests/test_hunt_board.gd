@tool
extends McpTestSuite
## Job-hunt board rules (GDD 5.6): the morning deal, the 10-card cap, applied pairs, reposts.
## Loads the real .tres and JSON with load() / FileAccess, never the Content autoload (INV-12).
## test_data_files pins the .tres to the GDD defaults. Never modify a loaded Resource: duplicate() it.

const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]

var cfg: BalanceConfig
var tiers: Dictionary = {}
var bgs: Dictionary = {}
var content: Dictionary = {}


func suite_name() -> String:
	return "hunt_board"


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


## Every template+company pair the MVP board can deal for a tier.
func _mvp_pairs(tier_id: String) -> Array[String]:
	return _tier_pairs(tier_id, true)


## Every pair a tier can deal: its MVP companies' (mvp_only), or all of its companies' (once the MVP
## pairs run dry, the deck falls back to the tier's other companies).
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


func _pairs_on_board(run: RunState) -> Array[String]:
	var pairs: Array[String] = []
	for card: Dictionary in run.board:
		pairs.append(RunState.pair_key(card["template_id"], card["company_id"]))
	return pairs


func test_deal_six_cards_two_per_tier() -> void:
	var run := _run("graduate")
	assert_eq(run.deal_board(cfg, tiers, content, _rng(1)), 6)
	var per_tier := {"startup": 0, "mid": 0, "big": 0}
	var uids: Array[int] = []
	for card: Dictionary in run.board:
		per_tier[card["tier"]] = int(per_tier[card["tier"]]) + 1
		assert_false(uids.has(int(card["uid"])), "card uids are unique")
		uids.append(int(card["uid"]))
		assert_eq(typeof(card["posted_days_ago"]), TYPE_INT, "ints stay ints")
		assert_false(card["reposted"], "nothing has dropped off yet")
	assert_eq(per_tier, {"startup": 2, "mid": 2, "big": 2})


func test_cards_come_from_mvp_companies_of_the_tier_and_skip_should_templates() -> void:
	var postings: Dictionary = content["postings"]
	var companies: Dictionary = content["companies"]
	var run := _run("graduate")
	var rng := _rng(7)
	for _morning: int in 30:
		run.deal_board(cfg, tiers, content, rng)
		for card: Dictionary in run.board:
			var posting: Dictionary = postings[card["template_id"]]
			var company: Dictionary = companies[card["company_id"]]
			assert_true(company["mvp"], "%s is an MVP company" % card["company_id"])
			assert_eq(company["tier"], card["tier"], "company tier")
			assert_eq(posting["tier"], card["tier"], "template tier")
			assert_false(posting["should"], "the Unicorn is SHOULD: never dealt")
			assert_ne(card["template_id"], "job_st_stealth_swe", "Stealth Mode Inc. is not an MVP company")


func test_card_rolls_stay_in_their_ranges() -> void:
	var run := _run("graduate")
	var rng := _rng(11)
	var ghosts := 0
	for _morning: int in 40:
		run.board.clear()
		run.deal_board(cfg, tiers, content, rng)
		for card: Dictionary in run.board:
			var tier: TierData = tiers[card["tier"]]
			var posted: int = card["posted_days_ago"]
			var applicants: int = card["applicants"]
			if card["is_ghost"]:
				ghosts += 1
				assert_true(posted >= cfg.ghost_posted_days_min and posted <= cfg.ghost_posted_days_max, "ghost posted %d" % posted)
			else:
				assert_true(posted >= tier.posted_days_min and posted <= tier.posted_days_max, "posted %d" % posted)
			assert_true(applicants >= tier.applicants_min and applicants <= tier.applicants_max, "applicants %d" % applicants)
			if card["template_id"] == "job_big_future_talent":
				assert_true(card["is_ghost"], "\"ghost\": \"always\" is always a ghost job")
	assert_gt(ghosts, 0, "some ghost jobs in 240 cards")


func test_board_keeps_ten_cards_new_ones_on_top_and_the_oldest_drop_off() -> void:
	var run := _run("graduate")
	var rng := _rng(3)
	run.deal_board(cfg, tiers, content, rng)
	var first_uids: Array[int] = []
	for card: Dictionary in run.board:
		first_uids.append(int(card["uid"]))
	var oldest_pairs: Array[String] = _pairs_on_board(run).slice(0, 2)
	assert_eq(run.deal_board(cfg, tiers, content, rng), 6)
	assert_eq(run.board.size(), cfg.board_max, "6 + 6 = 12, capped at 10")
	for i: int in 6:
		assert_false(first_uids.has(int(run.board[i]["uid"])), "this morning's cards are on top")
	var uids_now: Array[int] = []
	for card: Dictionary in run.board:
		uids_now.append(int(card["uid"]))
	assert_false(uids_now.has(first_uids[0]) or uids_now.has(first_uids[1]), "the 2 oldest dropped off")
	assert_true(uids_now.has(first_uids[2]), "the rest stay")
	for pair: String in oldest_pairs:
		assert_true(run.dropped.has(pair), "%s is remembered for a repost" % pair)


func test_applied_pairs_are_never_dealt_again() -> void:
	var run := _run("graduate")
	var rng := _rng(5)
	var left := _mvp_pairs("startup")[4]
	for pair: String in _tier_pairs("startup"):  # the non-MVP company's too, or the dry-deck fallback deals them
		if pair != left:
			run.applied.append(pair)
	for _morning: int in 20:
		run.board.clear()
		assert_eq(run.deal_board(cfg, tiers, content, rng), 5, "only one startup pair is left")
		for card: Dictionary in run.board:
			var pair := RunState.pair_key(card["template_id"], card["company_id"])
			assert_false(run.applied.has(pair), "%s was applied to" % pair)
			if card["tier"] == "startup":
				assert_eq(pair, left)
	# Through the real apply path, too: the applied pair is gone for good.
	var energy_run := _run("graduate")
	energy_run.deal_board(cfg, tiers, content, rng)
	var card: Dictionary = energy_run.board[0]
	var applied_pair := RunState.pair_key(card["template_id"], card["company_id"])
	assert_false(energy_run.apply_card(cfg, tiers, bgs["graduate"], content, int(card["uid"]), false, false).is_empty())
	for _morning: int in 30:
		energy_run.board.clear()
		energy_run.deal_board(cfg, tiers, content, rng)
		assert_false(_pairs_on_board(energy_run).has(applied_pair), "applied pair dealt again")


func test_pairs_that_dropped_off_unapplied_come_back_reposted() -> void:
	var run := _run("graduate")
	var rng := _rng(9)
	var left := _mvp_pairs("startup")[0]
	for pair: String in _tier_pairs("startup"):  # the non-MVP company's too, or the dry-deck fallback deals them
		if pair != left:
			run.applied.append(pair)
	run.deal_board(cfg, tiers, content, rng)
	assert_true(_pairs_on_board(run).has(left), "dealt the first morning")
	var guard := 0
	while not run.dropped.has(left) and guard < 10:
		run.deal_board(cfg, tiers, content, rng)
		guard += 1
	assert_true(run.dropped.has(left), "it aged off the board unapplied")
	assert_false(_pairs_on_board(run).has(left))
	run.deal_board(cfg, tiers, content, rng)
	var back: Dictionary = {}
	for card: Dictionary in run.board:
		if RunState.pair_key(card["template_id"], card["company_id"]) == left:
			back = card
	assert_false(back.is_empty(), "the only free startup pair returns")
	assert_true(back.get("reposted", false), "labelled Reposted")


func test_blacklisted_companies_leave_the_board_and_tiers_never_run_dry() -> void:
	var run := _run("graduate")
	var rng := _rng(13)
	run.deal_board(cfg, tiers, content, rng)
	run.blacklist.append("co_beigeware")
	for _morning: int in 10:
		run.deal_board(cfg, tiers, content, rng)
		for card: Dictionary in run.board:
			assert_ne(card["company_id"], "co_beigeware", "declined companies stop appearing")
	# Both MVP startups blacklisted: the tier falls back to its other company (and its pinned template).
	run.blacklist.append_array(["co_synergai", "co_quantumleaf"])
	var saw_stealth_template := false
	for _morning: int in 10:
		run.board.clear()
		run.deal_board(cfg, tiers, content, rng)
		for card: Dictionary in run.board:
			if card["tier"] == "startup":
				assert_eq(card["company_id"], "co_stealth")
				saw_stealth_template = saw_stealth_template or card["template_id"] == "job_st_stealth_swe"
	assert_true(saw_stealth_template, "the pinned template deals once its company is enabled")


func test_same_seed_same_board() -> void:
	var a := _run("self_taught")
	var b := _run("self_taught")
	var rng_a := _rng(2026)
	var rng_b := _rng(2026)
	for _morning: int in 3:
		a.deal_board(cfg, tiers, content, rng_a)
		b.deal_board(cfg, tiers, content, rng_b)
	assert_eq(a.board, b.board)
	assert_eq(a.dropped, b.dropped)


func test_skip_moves_the_card_to_the_back() -> void:
	var run := _run("graduate")
	run.deal_board(cfg, tiers, content, _rng(4))
	var top: int = run.board[0]["uid"]
	assert_true(run.skip_card(top))
	assert_eq(int(run.board[-1]["uid"]), top)
	assert_eq(run.board.size(), 6)
	assert_false(run.skip_card(-1), "unknown card")


func test_cards_age_overnight() -> void:
	var run := _run("graduate")
	run.deal_board(cfg, tiers, content, _rng(6))
	var before: int = run.board[0]["posted_days_ago"]
	run.sleep(cfg)
	assert_eq(int(run.board[0]["posted_days_ago"]), before + 1)

@tool
extends McpTestSuite
## The adapter between the career run's sim and the shipped duel and contract screens (ARCHITECTURE 19.5; GDD 5.20,
## R-JOB-06; DECISIONS A88, A89): a DuelRequest's numbers reach the interview's start values, the meter keeps its floor,
## a Phase 1 checkpoint still plays, the interview replays from its seed, the contract paper comes from the posting and
## fits, and a won interview leads to an offer whose Accept starts the next job. Editor-side: no autoloads, no user://.

const RUN_SEED := 4242


func suite_name() -> String:
	return "adapter"


func _near(a: float, b: float, eps: float, msg: String = "") -> void:
	assert_true(absf(a - b) <= eps, "%s: %f vs %f" % [msg, a, b])


func _history(seen: Array = [], first_run: bool = false, met: int = 0, last_company: String = "", after_layoff: bool = false) -> Dictionary:
	return {"seen": seen, "first_run": first_run, "met": met, "last_company": last_company, "after_layoff": after_layoff}


## A between-jobs state with an interview due tomorrow at a posting of this archetype and floor; steps once, so the sim
## has queued the duel.
func _duel_state(c: SimContext, archetype: String, floor_n: int, id: int, burnout: float = 0.0, skill: float = 0.0, rust: float = 0.0) -> SimState:
	var s := Sim.new_run(c, 2, 4)
	s.savings = 500.0
	s.burnout = burnout
	s.skill = skill
	s.rust = rust
	var posting := SimFixture.posting(c, archetype, 0, floor_n, false, id)
	s.applications.append({"posting": posting, "applied": 0, "reply": 0, "callback": true, "interview": 1, "status": "callback",
		"duels_done": 0, "next_duel": -1})
	Sim.step(s, [], c)
	return s


func test_the_work_states_numbers_reach_the_interview() -> void:  # AC-JOB03-1, R-JOB-03
	var c := SimFixture.ctx(true)
	var s := _duel_state(c, "startup", 2, 77, 40.0, 20.0, 20.0)
	var item := s.pending()
	assert_eq(item.get("kind", ""), "duel", "the interview day pauses the clock")
	var posting: Dictionary = Sim.find_application(s, 77)["posting"]
	var cp := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history())
	var tier: TierData = c.tiers["startup"]
	var start := DuelAdapter.start_values(cp, tier, c.bg)
	_near(start["composure"], WorkOdds.duel_composure(c.cfg, c.bg.composure_max, s.burnout), 0.0001, "Composure: the base lowered by Burnout")
	_near(start["doubt"], WorkOdds.duel_doubt(c.cfg, tier.doubt_hp, 2), 0.0001, "Doubt HP: the tier's base raised by the floor")
	_near(start["zone_mult"], WorkOdds.duel_zone_mult(c.cfg, s.skill, s.rust), 0.0001, "the meter: widened by Skill, narrowed by Rust")
	assert_true(float(start["composure"]) < c.bg.composure_max, "Burnout 40 costs Composure")
	assert_true(float(start["doubt"]) > tier.doubt_hp, "floor 2 is harder to get into")
	assert_eq(cp["rounds"], 5, "an interview is five rounds")
	assert_eq(cp["kind"], DuelAdapter.KIND_INTERVIEW)
	assert_eq(cp["company_id"], posting["company"])
	assert_eq(cp["tier"], "startup")


func test_knowledge_and_the_wheel_keep_the_backgrounds_stats() -> void:  # D-26
	var c := SimFixture.ctx(true)
	var run := RunState.new()
	run.set_background(c.balance, c.bg)
	assert_eq(run.stat("knw"), c.bg.start_knw, "KNOWLEDGE stays at the background's starting value")
	assert_eq(run.stat("exp"), c.bg.start_exp)
	assert_eq(run.stat("net"), c.bg.start_net)


func test_the_meter_never_gets_narrower_than_its_floor() -> void:  # RC-25, GDD 5.20
	var cfg := BalanceConfig.new()
	_near(DuelAdapter.half_width(cfg, 50.0, 0.0, 1.0), 0.12, 0.0001, "S 50: 0.06 + 0.12 x 0.5")
	_near(DuelAdapter.half_width(cfg, 50.0, 0.0, 1.2), 0.144, 0.0001, "Skill widens it")
	_near(DuelAdapter.half_width(cfg, 50.0, 0.04, 1.0), 0.16, 0.0001, "the Graduate's textbook bonus still adds")
	_near(DuelAdapter.half_width(cfg, 50.0, 0.0, 0.2), cfg.zone_half_base, 0.0001, "Rust cannot squeeze it under 0.06")
	_near(DuelAdapter.half_width(cfg, 5.0, 0.0, 0.5), cfg.zone_half_base, 0.0001, "nor can a weak stat score")


func test_a_phase_1_checkpoint_still_plays() -> void:  # ARCHITECTURE 19.5
	var c := SimFixture.ctx(true)
	var old := {"invite_uid": 3, "company_id": "co_synergai", "template_id": "x", "tier": "mid", "seed": "9", "tired": false,
		"question_ids": ["a", "b"], "warmup_id": ""}
	var tier: TierData = c.tiers["mid"]
	var start := DuelAdapter.start_values(old, tier, c.bg)
	assert_eq(start["composure"], float(c.bg.composure_max), "no career fields: the background's Composure")
	assert_eq(start["doubt"], float(tier.doubt_hp), "the tier's Doubt")
	assert_eq(start["zone_mult"], 1.0, "and the meter as it was")


func test_the_checkpoint_follows_the_prompt_pattern_and_never_repeats_a_question() -> void:
	var c := SimFixture.ctx(true)
	var s := _duel_state(c, "startup", 1, 77)
	var item := s.pending()
	var posting: Dictionary = Sim.find_application(s, 77)["posting"]
	var first := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history())
	var choice_pool: Dictionary = c.content["questions_choice"]
	var kinds: Array = []
	for prompt: Dictionary in InterviewPlan.prompts(first["question_ids"], choice_pool):
		kinds.append(prompt["kind"])
	assert_eq(kinds, Array(c.balance.prompt_pattern), "choice, knowledge, knowledge, knowledge, choice")
	var asked: Array = (first["question_ids"] as Array).duplicate()
	var again := item.duplicate(true)
	again["app"] = 78
	var second := DuelAdapter.interview_checkpoint(again, posting, s.rng_seed, c, _history(asked, false, 1, "co_synergai"))
	for id: Variant in second["question_ids"]:
		assert_false(asked.has(id), "no question repeats within a run: %s" % id)


func test_the_same_inputs_replay_the_same_interview() -> void:  # A89: Continue replays the luck
	var c := SimFixture.ctx(true)
	var s := _duel_state(c, "startup", 1, 77)
	var item := s.pending()
	var posting: Dictionary = Sim.find_application(s, 77)["posting"]
	var a := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history())
	var b := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history())
	assert_eq(a, b, "rebuilt from the same inputs")
	assert_true(a["seed"] is String, "seeds are strings (INV-05)")
	var other := item.duplicate(true)
	other["app"] = 78
	assert_ne(DuelAdapter.interview_checkpoint(other, posting, s.rng_seed, c, _history())["seed"], a["seed"], "another application, another seed")
	var second_duel := item.duplicate(true)
	second_duel["index"] = 1
	assert_ne(DuelAdapter.interview_checkpoint(second_duel, posting, s.rng_seed, c, _history())["seed"], a["seed"], "a MegaCorp's second duel too")
	assert_ne(DuelAdapter.interview_checkpoint(item, posting, s.rng_seed + 1, c, _history())["seed"], a["seed"], "and another run")


func test_the_warmup_and_the_greeting_follow_who_has_met_dana() -> void:  # GDD 5.8.2, CONTENT 16.6
	var c := SimFixture.ctx(true)
	var s := _duel_state(c, "startup", 1, 77)
	var item := s.pending()
	var posting: Dictionary = Sim.find_application(s, 77)["posting"]
	var first := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history([], true, 0))
	assert_ne(first["warmup_id"], "", "the first interview of the first run adds the practice question")
	assert_eq(first["greet"], DuelAdapter.GREET_FIRST)
	var later := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history([], true, 1, "co_synergai"))
	assert_eq(later["warmup_id"], "", "never twice")
	assert_eq(later["greet"], DuelAdapter.GREET_AGAIN, "Didn't I interview you at...")
	assert_eq(later["last_company"], "co_synergai")
	var laid_off := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history([], false, 0, "co_synergai", true))
	assert_eq(laid_off["greet"], DuelAdapter.GREET_AFTER_LAYOFF, "Dana laid you off, then met you again")
	var not_first_run := DuelAdapter.interview_checkpoint(item, posting, s.rng_seed, c, _history([], false, 0))
	assert_eq(not_first_run["warmup_id"], "", "no warm-up after the first run")


func test_the_contract_comes_from_the_posting() -> void:  # R-JOB-04, MC-10
	var c := SimFixture.ctx(true)
	var posting := SimFixture.posting(c, "startup", 0, 2, false, 51)
	posting["clauses"] = ["on_call", "unlimited_pto"]
	var paper := DuelAdapter.offer_paper(posting, c, RUN_SEED)
	assert_eq(paper["company_id"], posting["company"])
	assert_eq(paper["salary"], Odds.round_to(float(posting["salary"]) * 12.0 * 1000.0, 1000), "the yearly figure (a month's pay x 12)")
	assert_eq(paper["clauses"], ["on_call", "unlimited_pto"], "the posting's visible clauses")
	assert_eq(paper["equity_text"], "offer_equity", "a startup's joke equity")
	assert_eq(paper["work_mode"], DuelAdapter.ONSITE_MODE, "a non-remote startup is in the office all week")
	assert_eq(paper["office_days"], 5)
	assert_eq((paper["perks"] as Array).size(), DuelAdapter.OFFER_PERKS)
	assert_true(str(paper["fine_print"]).begins_with("fp_"), "the hidden clause, a fine-print joke, is revealed on the paper")
	assert_ne(str(paper["job_title"]), "", "the role has a title")
	assert_eq(paper, DuelAdapter.offer_paper(posting, c, RUN_SEED), "rebuilt from the same inputs: a resume shows the same paper")
	var remote := DuelAdapter.offer_paper(SimFixture.posting(c, "startup", 0, 1, true, 52), c, RUN_SEED)
	assert_eq(remote["work_mode"], DuelAdapter.REMOTE_MODE)
	assert_eq(remote["commute"]["id"], "offer_commute_remote")
	var big := DuelAdapter.offer_paper(SimFixture.posting(c, "megacorp", 0, 1, false, 53), c, RUN_SEED)
	assert_eq(big["work_mode"], "offer_mode_big", "a MegaCorp posting keeps Phase 1's office days")
	assert_eq(big["equity_text"], "", "no joke equity outside startups")
	var result := DuelAdapter.offer_result(true, paper)
	assert_eq(result["decision"], "accept")
	assert_eq(result["final_salary"], paper["salary"], "no negotiation: the final salary is the offered one (D-27)")
	assert_eq(result["clauses"], paper["clauses"])
	assert_eq(DuelAdapter.offer_result(false, paper)["decision"], "decline")


func test_every_career_contract_fits_the_paper() -> void:  # GDD S10: about 20 lines
	var c := SimFixture.ctx(true)
	var emails: Dictionary = c.content["emails"]
	var clause_sets: Array = [[], ["on_call"], ["remote_in_writing"], ["on_call", "unlimited_pto"], ["remote_in_writing", "on_call", "unlimited_pto"]]
	var worst := 0
	var id := 100
	for archetype: String in ["startup", "agency", "megacorp"]:
		var company := _longest_company(c, String(c.archetype(archetype).duel_tier))
		for level: int in 3:
			for remote: bool in [false, true]:
				for clauses: Array in clause_sets:
					for i: int in 6:
						id += 1
						var posting := SimFixture.posting(c, archetype, level, 1 + i % 3, remote, id)
						posting["clauses"] = clauses
						var paper := DuelAdapter.offer_paper(posting, c, RUN_SEED + i)
						var lines := ContractText.lines(paper, emails, company, "Alex")
						worst = maxi(worst, lines.size())
						assert_true(lines.size() <= ContractText.MAX_LINES, "%s level %d remote %s %s: %d lines" % [archetype, level, remote, clauses, lines.size()])
	assert_true(worst >= 12, "the check really measures papers (the longest has %d lines)" % worst)


## The longest real company name of a tier: the title line wraps at 40 columns.
func _longest_company(c: SimContext, tier_id: String) -> String:
	var longest := ""
	var companies: Dictionary = c.content["companies"]
	for key: String in companies:
		if companies[key] is Dictionary and str(companies[key].get("tier", "")) == tier_id:
			var name := str(companies[key].get("name", ""))
			if name.length() > longest.length():
				longest = name
	return longest


func test_a_won_interview_leads_to_an_offer_and_accept_starts_the_job() -> void:  # AC-S16-2, AC-JOB04-1
	var c := SimFixture.ctx(true)
	var session := WorkSession.start(c, 2, 4, [], "Alex", true)
	session.sim.savings = 500.0
	var posting := SimFixture.posting(c, "startup", 0, 1, false, 77)
	session.sim.applications.append({"posting": posting, "applied": 0, "reply": 0, "callback": true, "interview": 1, "status": "callback",
		"duels_done": 0, "next_duel": -1})
	session.tick()
	assert_true(session.wants_duel(), "the interview day waits for the duel")
	var checkpoint := session.begin_duel()
	assert_eq(session.begin_duel(), checkpoint, "begun once: asking again returns the same checkpoint")
	var asked := session.seen_questions.size()
	assert_eq(asked, (checkpoint["question_ids"] as Array).size() + 1, "the questions and the warm-up join the questions asked")
	var saved := session.to_save(GameFlow.Phase.INTERVIEW)
	var json := JSON.new()
	assert_eq(json.parse(SaveIO.encode(saved)), OK, "the save is JSON")
	var resumed := WorkSession.from_save(json.data, c)
	assert_eq(resumed.duel_checkpoint, checkpoint, "Continue in the middle of an interview resumes the same one, bit for bit")
	assert_eq(resumed.seen_questions, session.seen_questions)
	session.finish_duel(true, 50.0)
	assert_true(session.duel_checkpoint.is_empty(), "the checkpoint is cleared")
	assert_eq(session.dana_met, 1)
	assert_eq(session.dana_last_company, posting["company"], "Dana remembers where you interviewed")
	assert_true(session.wants_offer(), "a won interview leads to the contract")
	var paper := session.offer_paper()
	assert_eq(paper["company_id"], posting["company"])
	session.answer_offer(true)
	assert_true(session.sim.employed, "Accept starts the job")
	assert_eq(session.sim.jobs_held, 1)
	assert_false(session.sim.is_waiting(), "and frees the clock")


func test_a_lost_interview_ends_the_application_and_a_layoff_changes_the_greeting() -> void:
	var c := SimFixture.ctx(true)
	var session := WorkSession.start(c, 2, 4, [], "Alex", false)
	session.sim.savings = 500.0
	session.laid_off_company = "co_synergai"
	var posting := SimFixture.posting(c, "startup", 0, 1, false, 77)
	session.sim.applications.append({"posting": posting, "applied": 0, "reply": 0, "callback": true, "interview": 1, "status": "callback",
		"duels_done": 0, "next_duel": -1})
	session.tick()
	var checkpoint := session.begin_duel()
	assert_eq(checkpoint["greet"], DuelAdapter.GREET_AFTER_LAYOFF, "the first interview after a layoff")
	session.finish_duel(false, 0.0)
	assert_false(session.wants_offer(), "a lost interview leaves no offer")
	assert_eq(session.sim.applications.size(), 0, "and the application is gone")
	assert_eq(session.laid_off_company, "", "Dana has met you since")

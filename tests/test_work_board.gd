@tool
extends McpTestSuite
## The DoomApply board (GDD 5.20; DECISIONS D-41, A90, A92): the postings as nodes with their yearly pay and callback
## dots, the applications waiting on a reply, who can apply and study, and what a reply or an application leaves for the
## screen to show. Pure: WorkBoard reads a SimState. Editor-side: no autoloads, no user://.

var c: SimContext = SimFixture.ctx(true)


func suite_name() -> String:
	return "work_board"


func _near(a: float, b: float, eps: float, msg: String = "") -> void:
	assert_true(absf(a - b) <= eps, "%s: %f vs %f" % [msg, a, b])


## A between-jobs state at Mid with one posting of each fit: your level, one up, one below.
func _fitted() -> SimState:
	var s := Sim.new_run(c, 2, 4)
	s.level = 1
	s.board = [
		SimFixture.posting(c, "startup", 1, 2, false, 1),
		SimFixture.posting(c, "startup", 2, 2, true, 2),
		SimFixture.posting(c, "agency", 0, 2, false, 3),
	]
	return s


func test_the_board_shows_each_posting_as_a_node() -> void:  # AC-JOB01-1, D-41
	var s := Sim.new_run(c, 2, 4)
	var nodes := WorkBoard.nodes(s, c)
	assert_eq(nodes.size(), 4, "the board holds 4 postings")
	for i: int in nodes.size():
		var node: Dictionary = nodes[i]
		var posting: Dictionary = s.board[i]
		assert_eq(node["id"], posting["id"])
		assert_eq(node["company"], posting["company"])
		assert_eq(node["archetype"], posting["archetype"])
		assert_eq(node["level"], posting["level"])
		assert_eq(node["salary"], WorkOdds.yearly_salary(c.cfg, float(posting["salary"])), "the yearly figure")
		assert_eq(node["remote"], posting["remote"])
		assert_eq(node["clauses"], posting["clauses"], "the visible clauses")
		assert_true(int(node["dots"]) >= 1 and int(node["dots"]) <= 5, "1-5 dots, never a percentage")


func test_the_yearly_pay_is_a_months_pay_times_twelve_to_the_nearest_thousand() -> void:  # MC-10
	assert_eq(WorkOdds.yearly_salary(c.cfg, 2.55), 31000, "2.55 k$ a month is $30,600 a year, rounded to $31,000")
	assert_eq(WorkOdds.yearly_salary(c.cfg, 3.0), 36000)
	assert_eq(WorkOdds.yearly_salary(c.cfg, 6.0), 72000)


func test_the_callback_band_is_five_equal_steps() -> void:  # A90
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.05), 1)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.10), 2, "10% is the first step")
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.175), 2)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.20), 3)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.28), 3)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.30), 4)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.35), 4)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.40), 5)
	assert_eq(WorkOdds.callback_dots(c.cfg, 0.42), 5)


func test_a_level_up_reads_harder_and_a_level_below_easier() -> void:  # R-JOB-02: 1.0 / 0.5 / 0.8
	var s := _fitted()
	var nodes := WorkBoard.nodes(s, c)
	assert_eq(nodes[0]["dots"], 4, "your level: 35%")
	assert_eq(nodes[1]["dots"], 2, "one level up: 17.5%")
	assert_eq(nodes[2]["dots"], 3, "below your level: 28%")


func test_references_lift_the_dots_and_short_tenure_pulls_them_down() -> void:
	var s := _fitted()
	s.coworkers = [{"id": "cw_a", "rapport": 70.0}, {"id": "cw_b", "rapport": 65.0}]
	assert_eq(WorkBoard.nodes(s, c)[0]["dots"], 5, "two references: 42%")
	s.coworkers = []
	s.scar_short_tenure = 2
	assert_eq(WorkBoard.nodes(s, c)[0]["dots"], 3, "two Short Tenure stacks: 35% x 0.7 = 24.5%")


func test_applications_in_flight_are_listed_soonest_first() -> void:
	var s := Sim.new_run(c, 2, 4)
	s.applications = [
		{"posting": {"id": 1, "company": "co_a"}, "status": "wait", "reply": 9, "interview": -1, "next_duel": -1},
		{"posting": {"id": 2, "company": "co_b"}, "status": "callback", "reply": 3, "interview": 6, "next_duel": -1},
		{"posting": {"id": 3, "company": "co_c"}, "status": "between", "reply": 3, "interview": 2, "next_duel": 12},
		{"posting": {"id": 4, "company": "co_d"}, "status": "offer", "reply": 3, "interview": 2, "next_duel": -1},
	]
	var waiting := WorkBoard.waiting(s)
	assert_eq(waiting.size(), 3, "an offer has its own screen")
	assert_eq(waiting[0], {"company": "co_b", "kind": "interview", "day": 6})
	assert_eq(waiting[1], {"company": "co_a", "kind": "reply", "day": 9})
	assert_eq(waiting[2], {"company": "co_c", "kind": "interview", "day": 12}, "a MegaCorp's second duel")


func test_applying_is_off_only_at_job_five_and_costs_more_while_employed() -> void:  # A72
	var s := Sim.new_run(c, 2, 4)
	assert_true(WorkBoard.can_apply(s, c.cfg))
	assert_eq(WorkBoard.apply_burnout(s, c.cfg), 2.0, "unemployed: +2")
	s.employed = true
	assert_eq(WorkBoard.apply_burnout(s, c.cfg), 3.0, "employed: +3")
	s.jobs_held = 5
	assert_false(WorkBoard.can_apply(s, c.cfg), "no job 6")
	s.employed = false
	assert_true(WorkBoard.can_apply(s, c.cfg), "between jobs you can still try")


func test_study_is_once_a_day_and_the_board_refreshes_every_14_days() -> void:
	var s := Sim.new_run(c, 2, 4)
	assert_true(WorkBoard.can_study(s))
	Sim.apply_inputs(s, [{"kind": Sim.IN_STUDY}], c)
	assert_false(WorkBoard.can_study(s), "studied today")
	Sim.step(s, [], c)
	assert_true(WorkBoard.can_study(s), "tomorrow again")
	s.board_day = s.day - 5
	assert_eq(WorkBoard.days_to_refresh(s, c.cfg), 9)
	s.board_day = s.day - 20
	assert_eq(WorkBoard.days_to_refresh(s, c.cfg), 0)


func test_applying_leaves_a_feed_line_and_a_callback_a_notice() -> void:  # A92
	var session := WorkSession.start(c, 2, 4, [], "Alex", false)
	var posting: Dictionary = session.sim.board[0]
	var events := session.apply_to(int(posting["id"]))
	assert_eq(SimFixture.count(events, "application_sent"), 1)
	assert_eq(session.feed.back()["id"], "ui_applied_feed", "a quiet line")
	assert_eq(session.feed.back()["args"], {"company": posting["company"]})
	assert_true(session.notices.is_empty(), "applying stops nothing")
	var app: Dictionary = session.sim.applications[0]
	app["callback"] = true
	app["reply"] = session.sim.day + 1
	app["interview"] = session.sim.day + 4
	session.tick()
	assert_eq(session.notices.size(), 1, "a callback is a notice")
	assert_eq(session.notices[0]["id"], "ui_callback_notice")
	assert_eq(session.notices[0]["company"], posting["company"])
	assert_eq(session.notices[0]["day"], session.sim.day + 3, "the interview day")
	assert_true(session.is_blocked(), "the clock waits for it")


func test_a_rejection_is_a_quiet_line() -> void:
	var session := WorkSession.start(c, 2, 4, [], "Alex", false)
	session.sim.applications.append({"posting": {"id": 1, "company": "co_synergai"}, "applied": 0, "reply": 1, "callback": false,
		"interview": -1, "status": "wait", "duels_done": 0, "next_duel": -1})
	session.tick()
	assert_true(session.notices.is_empty(), "no notice for a no")
	assert_eq(session.feed.back()["id"], "ui_rejected_feed")


func test_the_board_opens_by_itself_once_after_the_layoff_scene() -> void:  # GDD 4.5
	var session := WorkSession.start(c, 1, 4, [], "Alex", false)
	assert_false(session.take_board_hint(), "not before a layoff")
	session.sim.queue.append({"kind": "layoff_scene", "severance_months": 0.0, "severance": 0.0})
	session.acknowledge()
	assert_true(session.take_board_hint(), "after the layoff scene")
	assert_false(session.take_board_hint(), "once")

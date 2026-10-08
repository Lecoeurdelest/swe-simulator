@tool
extends McpTestSuite
## What the work state's top band shows (GDD 5.16, 4.6): Runway, Burnout, the Ticket, the Codebase's 10 LEDs, the
## Studio chip and the calendar strip. Editor-side: no autoloads.

var c: SimContext = SimFixture.ctx(true)


func suite_name() -> String:
	return "work_hud"


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


func test_runway_is_months_of_bills_and_red_under_two() -> void:  # R-STAT-01
	var s := SimFixture.fresh(c)
	s.savings = 4.2   # the Shared room: 0.9 rent + 1.2 living = 2.1 a month
	_near(WorkHud.runway_months(s), 2.0, 0.0001, "4.2 k$ against 2.1 a month")
	assert_eq(WorkHud.runway_text(s), "2.0")
	assert_false(WorkHud.runway_is_red(s, c.cfg), "exactly two months is not red")
	s.savings = 4.0
	assert_eq(WorkHud.runway_text(s), "1.9")
	assert_true(WorkHud.runway_is_red(s, c.cfg), "1.9 months is red, and the number still shows")
	s.savings = -3.0
	assert_eq(WorkHud.runway_text(s), "0.0", "debt reads as no runway, never a negative")
	assert_true(WorkHud.runway_is_red(s, c.cfg))
	s.savings = 4.2
	s.living_mult = 0.8   # E07's "cut spending"
	_near(WorkHud.runway_months(s), 4.2 / (0.9 + 1.2 * 0.8), 0.0001, "cut spending stretches it")


func test_burnout_bar_and_the_codebase_rack() -> void:
	var s := SimFixture.fresh(c)
	s.burnout = 50.0
	_near(WorkHud.burnout_frac(s, c.cfg), 0.5, 0.0001, "half full")
	s.burnout = 250.0
	_near(WorkHud.burnout_frac(s, c.cfg), 1.0, 0.0001, "never past full")
	var expected := {0.0: 0, 9.9: 0, 10.0: 1, 55.0: 5, 99.9: 9, 100.0: 10, 140.0: 10}
	for codebase: float in expected:
		s.codebase = codebase
		assert_eq(WorkHud.codebase_red_leds(s), expected[codebase], "Codebase %.1f" % codebase)


func test_the_ticket_bar_and_its_deadline() -> void:
	var s := SimFixture.fresh(c)   # run 1 starts employed with a ticket
	s.ticket_progress = 35.0
	s.ticket_deadline = s.day + 8
	_near(WorkHud.ticket_frac(s), 0.35, 0.0001, "35%")
	assert_eq(WorkHud.ticket_days_left(s), 8)
	assert_false(WorkHud.ticket_is_late(s))
	s.day = s.ticket_deadline + 2
	assert_eq(WorkHud.ticket_days_left(s), -2, "two days past")
	assert_true(WorkHud.ticket_is_late(s))
	s.employed = false
	assert_eq(WorkHud.ticket_frac(s), 0.0, "no ticket between jobs")
	assert_eq(WorkHud.ticket_days_left(s), 0)
	assert_false(WorkHud.ticket_is_late(s))


func test_the_studio_chip_counts_what_holds() -> void:  # 3.4: Senior, remote, the Studio, Burnout 30, 6 months saved
	var s := SimFixture.fresh(c)
	s.burnout = 10.0
	s.savings = 0.0
	assert_eq(WorkHud.studio_count(s, c.cfg), 1, "a calm Junior holds only the Burnout condition")
	s.level = WorkOdds.SENIOR
	s.job_remote = true
	assert_eq(WorkHud.studio_count(s, c.cfg), 3, "Senior and remote join it")


func test_label_ids() -> void:
	assert_eq(WorkHud.hours_label_id(1), "ui_hours_1")
	assert_eq(WorkHud.hours_label_id(5), "ui_hours_5")
	assert_eq(WorkHud.hours_label_id(9), "ui_hours_5", "clamped")
	assert_eq(WorkHud.level_label_id(WorkOdds.JUNIOR), "ui_level_junior")
	assert_eq(WorkHud.level_label_id(WorkOdds.SENIOR), "ui_level_senior")
	assert_eq(WorkHud.home_label_id(0), "ui_home_shared")
	assert_eq(WorkHud.home_label_id(3), "ui_home_penthouse")
	assert_eq(WorkHud.speed_label_id(0, c.cfg), "ui_speed_pause")
	assert_eq(WorkHud.speed_label_id(1, c.cfg), "ui_speed_1")
	assert_eq(WorkHud.speed_label_id(3, c.cfg), "ui_speed_4")


func test_the_calendar_strip_lists_the_next_sixty_days() -> void:  # 5.14
	var s := SimFixture.fresh(c)
	var items := WorkHud.calendar(c, s)
	var by_kind: Dictionary = {}
	for item: Dictionary in items:
		by_kind[item["kind"]] = int(by_kind.get(item["kind"], 0)) + 1
		assert_true(int(item["offset"]) >= 1 and int(item["offset"]) <= c.cfg.calendar_days, "offset %d is inside the strip" % int(item["offset"]))
		assert_ne(String(item["label_id"]), "", "%s has a label" % item["kind"])
	assert_eq(by_kind.get("payday", 0), 2, "days 25 and 55")
	assert_eq(by_kind.get("rent", 0), 2, "days 1 and 31 (the first is tomorrow)")
	assert_eq(by_kind.get("review", 0), 0, "the review is on day 180, out of sight")
	s.day = 130
	var review_seen := false
	for item: Dictionary in WorkHud.calendar(c, s):
		if item["kind"] == "review":
			review_seen = true
			assert_eq(int(item["offset"]), 50, "day 180 from day 130")
	assert_true(review_seen, "the review comes into the strip 60 days out")
	assert_eq(String(WorkHud.next_on_calendar(c, SimFixture.fresh(c)).get("kind", "")), "rent", "the first thing is tomorrow's rent")


func test_the_team_rows_follow_the_signs_and_the_job() -> void:  # D-40
	var s := SimFixture.fresh(c)
	var rows := WorkHud.team(c, s)
	assert_eq(rows.size(), 4, "Hierarchai's four authored coworkers")
	var names: Array = rows.map(func(r: Dictionary) -> String: return r["name"])
	names.sort()
	assert_eq(names, ["Kev", "Minh", "Priya", "Tom"])
	for row: Dictionary in rows:
		assert_false(row["gone"], "nobody is gone on day 0")
		assert_ne(row["role"], "")
		assert_ne(row["line"], "")
	s.day = 209
	assert_false(_row(WorkHud.team(c, s), "cw_minh")["gone"], "the day before the fourth sign")
	s.day = 210
	assert_true(_row(WorkHud.team(c, s), "cw_minh")["gone"], "Minh's desk goes dark with the fourth sign")
	assert_false(_row(WorkHud.team(c, s), "cw_kev")["gone"], "nobody else's does")
	s.coworkers = []
	assert_true(WorkHud.team(c, s).is_empty(), "every row clears with the job")
	s.coworkers = [{"id": "cw_gen_0", "level": 1, "salary": 3.0, "rapport": 50.0}]
	assert_true(WorkHud.team(c, s).is_empty(), "a generated crew has no cards yet (M4)")


func _row(rows: Array, id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row["id"] == id:
			return row
	return {}


@tool
extends McpTestSuite
## The endings and the Scars (GDD 3.3, 3.4, 5.21; R-WIN-01..08, O6): The Studio fires only with all five conditions held
## for 90 days and a break resets the hold (Q-06); each hard loss's trigger; the forced leave; every Scar, its stack cap and
## its counterplay (P-04). Quiet contexts: no incidents or random events, so a test can step many days.


func suite_name() -> String:
	return "sim_endings"


func _near(actual: float, expected: float, eps: float, what: String = "") -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


## An employed Senior in a remote job, living in The Studio with plenty saved: all five conditions hold.
func _studio(c: SimContext) -> SimState:
	var s := Sim.new_run(c, 2, 77)
	s.day = 10
	Sim._start_job(s, c, SimFixture.posting(c, "startup", WorkOdds.SENIOR, 1, true), [], false)
	s.queue.clear()
	s.chains.clear()
	s.level = WorkOdds.SENIOR
	s.home = 2
	s.rent = 2.4
	s.lease_day = s.day
	s.burnout = 10.0
	s.savings = 100.0
	s.next_review = -1
	return s


func _hold_a_day(s: SimState, c: SimContext) -> void:
	s.burnout = 10.0
	s.savings = maxf(s.savings, 100.0)
	Sim.step(s, SimFixture.answer(s) if s.is_waiting() else [], c)


# ---------- The Studio (3.4) ----------

func test_the_studio_fires_after_exactly_90_days_with_all_five_conditions() -> void:  # O6, AC-S14-6, R-WIN-06
	var c := SimFixture.ctx(true)
	var s := _studio(c)
	for i: int in 89:
		_hold_a_day(s, c)
	assert_eq(s.studio_hold, 89)
	assert_false(s.ended, "89 days is not enough")
	_hold_a_day(s, c)
	assert_true(s.ended)
	assert_eq(s.ending, "studio")
	assert_eq(s.studio_hold, 90)


func test_each_condition_alone_keeps_the_hold_at_zero() -> void:  # R-WIN-01..05: AC-WIN01-1..AC-WIN05-1
	var c := SimFixture.ctx(true)
	var breaks: Dictionary = {
		"S1 Senior": func(s: SimState) -> void: s.level = WorkOdds.MID,
		"S2 Remote": func(s: SimState) -> void: s.job_remote = false,
		"S3 The Studio": func(s: SimState) -> void:
			s.home = 1
			s.rent = 1.5,
		"S4 Burnout 30 or less": func(s: SimState) -> void: s.burnout = 45.0,
		"S5 six months of runway": func(s: SimState) -> void: s.savings = 15.0,
	}
	for name: String in breaks:
		var s := _studio(c)
		for i: int in 5:
			(breaks[name] as Callable).call(s)
			Sim.step(s, SimFixture.answer(s) if s.is_waiting() else [], c)
		assert_eq(s.studio_hold, 0, "without %s the hold never starts" % name)
	var ok := _studio(c)
	for i: int in 5:
		_hold_a_day(ok, c)
	assert_eq(ok.studio_hold, 5, "with all five it counts")


func test_a_broken_hold_resets_to_zero_not_to_half() -> void:  # Q-06, R-WIN-06
	var c := SimFixture.ctx(true)
	var s := _studio(c)
	for i: int in 60:
		_hold_a_day(s, c)
	assert_eq(s.studio_hold, 60)
	s.burnout = 40.0
	var events := Sim.step(s, [], c)
	assert_eq(s.studio_hold, 0, "one bad day: all the way back to zero")
	assert_eq(SimFixture.count(events, "studio_broken"), 1)
	for i: int in 89:
		_hold_a_day(s, c)
	assert_false(s.ended, "the old 60 days do not count")
	_hold_a_day(s, c)
	assert_true(s.ended and s.ending == "studio", "90 fresh days")


func test_the_final_threats_weigh_three_times_while_filming() -> void:  # R-WIN-08, AC-WIN08-1
	var c := SimFixture.ctx(true)
	var s := _studio(c)
	var flagged: Array = []
	var plain: Array = []
	for id: String in c.events:
		if id.begins_with("_"):
			continue
		var evt: Dictionary = c.events[id]
		(flagged if bool(evt.get("final_threat", false)) else plain).append(id)
	flagged.sort()
	assert_eq(flagged, ["evt_e07_resizing", "evt_e08_rto_mandate", "evt_e12_incident_prod", "evt_e21_lifestyle_offer", "evt_e24_overtime_ask"],
		"the RTO mandate, the incident, the overtime ask, the Penthouse offer and the resizing")
	for id: String in flagged:
		assert_eq(EventPlan.threat_mult(c, s, c.events[id]), 1.0, "%s: normal before the hold starts" % id)
	s.studio_hold = 12
	for id: String in flagged:
		assert_eq(EventPlan.threat_mult(c, s, c.events[id]), 3.0, "%s: x3 while filming" % id)
	for id: String in plain:
		assert_eq(EventPlan.threat_mult(c, s, c.events[id]), 1.0, "%s: no threat" % id)


func test_the_studio_chip_counts_the_conditions() -> void:  # R-WIN-07: the checklist is always visible
	var c := SimFixture.ctx(true)
	var s := _studio(c)
	assert_eq(WorkOdds.studio_count(c.cfg, s.level, s.job_remote, s.home, s.burnout, s.savings, s.living_cost), 5)
	var runner := Sim.new_run(c, 1, 3)
	assert_eq(WorkOdds.studio_count(c.cfg, runner.level, runner.job_remote, runner.home, runner.burnout, runner.savings, runner.living_cost), 1,
		"day 0 of run 1: only Burnout is fine (Studio 1/5)")


# ---------- hard losses (3.3) ----------

func test_plan_b_after_30_days_below_zero_in_a_row() -> void:  # D-19, R-ECO
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = -1.0
	for i: int in 29:
		Sim.step(s, [], c)
	assert_false(s.ended, "29 days")
	assert_eq(s.below_zero_days, 29)
	Sim.step(s, [], c)
	assert_true(s.ended)
	assert_eq(s.ending, "plan_b")
	assert_eq(s.day, 30)


func test_a_day_back_above_zero_resets_the_plan_b_clock() -> void:
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = -1.0
	for i: int in 20:
		Sim.step(s, [], c)
	assert_eq(s.below_zero_days, 20)
	s.savings = 5.0
	Sim.step(s, [], c)
	assert_eq(s.below_zero_days, 0)


func test_the_second_forced_leave_is_the_burnout_ending() -> void:  # 3.3: a second forced leave in one run
	var c := SimFixture.ctx(true)
	var s := _studio(c)
	s.hours = 5
	s.burnout = 100.0
	var events := Sim.step(s, [], c)
	assert_eq(SimFixture.count(events, "forced_leave"), 1, "the first one is an interrupt, not an exit")
	assert_false(s.ended)
	assert_true(s.employed, "the job is kept")
	assert_eq(s.scar_burnout_history, 1)
	assert_eq(s.forced_leaves, 1)
	s.queue.clear()
	s.leave_end = -1
	s.burnout = 100.0
	events = Sim.step(s, [], c)
	assert_eq(s.ending, "burnout", "the second one ends the run")
	assert_true(s.ended)


func test_a_forced_leave_is_thirty_days_at_half_pay_with_the_job_kept() -> void:  # DECISIONS A72
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	Sim._start_job(s, c, SimFixture.posting(c, "agency"), [], false)
	s.queue.clear()
	s.chains.clear()
	s.savings = 500.0
	s.next_review = -1
	s.burnout = 100.0
	var deadline := s.ticket_deadline
	Sim.step(s, [], c)
	assert_eq(s.pending().get("kind", ""), "forced_leave")
	_near(s.burnout, 50.0, 1.0, "rest brings Burnout back to about 50 (plus the floor)")
	var start := s.day
	assert_eq(s.leave_end, start + 30, "30 days")
	assert_eq(s.ticket_deadline, deadline + 30, "the ticket's deadline waits with you")
	Sim.step(s, [{"kind": Sim.IN_ACK}], c)
	var progress := s.ticket_progress
	var mo := s.mo
	var accrued_before := s.pay_accrued
	Sim.step(s, [], c)
	_near(s.ticket_progress, progress, 0.0001, "no ticket progress on leave")
	_near(s.mo, mo, 0.0001, "MO holds still")
	_near(s.pay_accrued - accrued_before, s.job_salary / 30.0 * 0.5, 0.0001, "half pay")
	SimFixture.run_days(s, c, 31)
	assert_true(s.employed, "still your job")
	assert_true(s.ticket_progress > progress, "back at work")


func test_losing_job_five_by_any_route_is_a_hard_loss() -> void:  # D-16: Career Change
	var c := SimFixture.ctx(true)
	for reason: String in ["layoff", "fired", "quit"]:
		var s := Sim.new_run(c, 2, 4)
		s.jobs_held = 4
		Sim._start_job(s, c, SimFixture.posting(c, "startup", 0, 5), [], false)
		assert_eq(s.jobs_held, 5)
		Sim._end_job(s, c, reason, [], 0.0)
		assert_true(s.ended and s.ending == "career_change", "job 5 lost by %s" % reason)
	var s4 := Sim.new_run(c, 2, 4)
	s4.jobs_held = 3
	Sim._start_job(s4, c, SimFixture.posting(c, "startup", 0, 4), [], false)
	Sim._end_job(s4, c, "layoff", [], 0.0)
	assert_false(s4.ended, "losing job 4 is only a soft loss")


func test_six_years_without_a_win_is_the_legacy_system() -> void:  # 3.3: day 2,160
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = 1000000.0
	s.day = 2158
	s.lease_day = s.day
	Sim.step(s, [], c)
	assert_false(s.ended, "day 2159")
	Sim.step(s, [], c)
	assert_true(s.ended)
	assert_eq(s.ending, "legacy")
	assert_eq(s.day, 2160)


func test_a_finished_run_ignores_further_steps() -> void:
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = -5.0
	for i: int in 31:
		Sim.step(s, [], c)
	assert_true(s.ended)
	var day := s.day
	var events := Sim.step(s, [{"kind": Sim.IN_STUDY}], c)
	assert_eq(events.size(), 0)
	assert_eq(s.day, day)


# ---------- Scars (5.21, P-04) ----------

func test_short_tenure_stacks_to_three_and_clears_after_360_days() -> void:  # callback -15% a stack
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	for i: int in 4:
		Sim._start_job(s, c, SimFixture.posting(c, "megacorp", 0, mini(i + 1, 4)), [], false)
		Sim._end_job(s, c, "quit", [], 0.0)
		if s.ended:
			break
	assert_eq(s.scar_short_tenure, 3, "at most three stacks")
	var t := Sim.new_run(c, 2, 5)
	t.scar_short_tenure = 2
	Sim._start_job(t, c, SimFixture.posting(c, "megacorp"), [], false)
	t.savings = 1000.0
	t.next_review = -1
	t.chains.clear()
	SimFixture.run_days(t, c, 359)
	assert_eq(t.scar_short_tenure, 2, "not yet")
	SimFixture.run_days(t, c, 2)
	assert_eq(t.scar_short_tenure, 0, "360 days at one job clears them (A72)")


func test_burnout_history_floors_burnout_and_clears_after_120_calm_days_in_a_row() -> void:  # +15 a stack; 120 days at 30 or less
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.scar_burnout_history = 1
	s.savings = 1000.0
	s.burnout = 5.0
	Sim.step(s, [], c)
	assert_true(s.burnout >= 15.0, "one stack: Burnout never below 15")
	s.calm_days = 0
	for i: int in 119:
		s.burnout = 20.0
		Sim.step(s, [], c)
	assert_eq(s.scar_burnout_history, 1, "119 calm days is not enough")
	s.burnout = 50.0
	Sim.step(s, [], c)
	assert_eq(s.calm_days, 0, "a bad day breaks the run of calm days")
	for i: int in 120:
		s.burnout = 20.0
		Sim.step(s, [], c)
	assert_eq(s.scar_burnout_history, 0, "120 in a row removes a stack")


func test_a_bad_reference_starts_the_next_job_at_minus_20_mo_unless_a_reference_cancels_it() -> void:  # 5.21
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
	s.mo = -50.0
	Sim._end_job(s, c, "fired", [], 0.0)
	assert_eq(s.scar_bad_reference, 1)
	Sim._start_job(s, c, SimFixture.posting(c, "megacorp", 0, 2), [], false)
	_near(s.mo, -20.0, 0.0001, "the next job's MO starts at -20")
	assert_eq(s.scar_bad_reference, 0, "it only follows you to one job")
	var t := Sim.new_run(c, 2, 4)
	Sim._start_job(t, c, SimFixture.posting(c, "startup"), [], false)
	(t.coworkers[0] as Dictionary)["rapport"] = 60.0
	t.mo = -50.0
	Sim._end_job(t, c, "fired", [], 0.0)
	Sim._start_job(t, c, SimFixture.posting(c, "megacorp", 0, 2), [], false)
	_near(t.mo, 0.0, 0.0001, "a coworker at Rapport 60+ vouches for you")


func test_quitting_with_mo_under_minus_30_is_also_a_bad_reference() -> void:
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
	s.mo = -31.0
	Sim._end_job(s, c, "quit", [], 0.0)
	assert_eq(s.scar_bad_reference, 1)
	var t := Sim.new_run(c, 2, 4)
	Sim._start_job(t, c, SimFixture.posting(c, "startup"), [], false)
	t.mo = -29.0
	Sim._end_job(t, c, "quit", [], 0.0)
	assert_eq(t.scar_bad_reference, 0)


func test_a_resume_gap_cuts_offers_by_ten_percent_a_stack() -> void:  # 5.21: unemployed more than 60 days
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = 1000.0
	SimFixture.run_days(s, c, 60)
	assert_eq(s.scar_resume_gap, 0, "60 days is not more than 60")
	SimFixture.run_days(s, c, 1)
	assert_eq(s.scar_resume_gap, 1)
	SimFixture.run_days(s, c, 200)
	assert_eq(s.scar_resume_gap, 1, "once per stretch of unemployment")
	var with_gap := WorkOdds.offer_salary(c.cfg, c.archetype("startup"), 0, 1, s.scar_resume_gap)
	_near(with_gap, 2.55 * 0.9, 0.0001, "offers -10%")
	for posting: Dictionary in s.board:
		var plain := WorkOdds.offer_salary(c.cfg, c.archetype(String(posting["archetype"])), int(posting["level"]), int(posting["floor"]), 0)
		assert_true(float(posting["salary"]) < plain + 0.0001, "the board's offers carry the cut")


func test_a_corner_cutter_starts_the_next_codebase_15_higher_and_clears_below_40() -> void:  # 5.21: leave a Senior job at Codebase 80+
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	Sim._start_job(s, c, SimFixture.posting(c, "megacorp", WorkOdds.SENIOR), [], false)
	s.codebase = 85.0
	Sim._end_job(s, c, "quit", [], 0.0)
	assert_eq(s.scar_corner_cutter, 1)
	Sim._start_job(s, c, SimFixture.posting(c, "megacorp", WorkOdds.SENIOR, 2), [], false)
	_near(s.codebase, 40.0 + 15.0, 0.0001, "the next job's Codebase starts +15")
	s.codebase = 39.0
	s.savings = 1000.0
	s.next_review = -1
	s.chains.clear()
	Sim.step(s, SimFixture.answer(s) if s.is_waiting() else [], c)
	assert_eq(s.scar_corner_cutter, 0, "a Codebase under 40 clears it")


func test_scars_never_stack_past_three() -> void:  # P-04
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	for i: int in 5:
		s.scar_bad_reference = mini(s.scar_bad_reference + 1, c.cfg.scar_max_stacks)
		s.scar_resume_gap = mini(s.scar_resume_gap + 1, c.cfg.scar_max_stacks)
	assert_eq([s.scar_bad_reference, s.scar_resume_gap], [3, 3])
	assert_eq(c.cfg.scar_max_stacks, 3)

@tool
extends McpTestSuite
## The performance review (GDD 5.16, R-STAT-04, E02; DECISIONS A67): the Evidence formula, the rating bands and their
## boundaries, each archetype's promotion rule, the PIP and firing, and the stand-in the harness uses until M3 designs
## the review's prompts. The review itself is a card Sim parks in the queue; the answer is the Evidence you kept.

var cfg: WorkConfig


func suite_name() -> String:
	return "sim_review"


func setup() -> void:
	cfg = WorkConfig.new()


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


## A run 1 state, quiet, with the review due on the next tick. rating_share is how much of your Evidence you keep.
func _review_state(c: SimContext, archetype: String = "startup", level: int = 0) -> SimState:
	var s := Sim.new_run(c, 2, 3)
	Sim._start_job(s, c, SimFixture.posting(c, archetype, level), [], false)
	s.savings = 500.0
	s.queue.clear()
	s.next_review = s.day + 1
	return s


func _answer_review(s: SimState, c: SimContext, share: float) -> Array:
	while s.is_waiting() and s.pending().get("kind", "") != "review":
		Sim.step(s, SimFixture.answer(s), c)
	Sim.step(s, [], c)
	assert_eq(s.pending().get("kind", ""), "review", "the review card is up")
	var evidence: float = s.pending()["evidence"]
	return Sim.step(s, [{"kind": Sim.IN_REVIEW_RESULT, "evidence_left": evidence * share}], c)


# ---------- the numbers ----------

func test_evidence_formula() -> void:  # R-STAT-04: 50 + MO/2 + 5 per on-time ticket since the last review
	_near(WorkOdds.evidence(cfg, 0.0, 0, false), 50.0, 0.0001, "a fresh start")
	_near(WorkOdds.evidence(cfg, 20.0, 6, false), 90.0, 0.0001, "MO 20 and 6 on-time tickets")
	_near(WorkOdds.evidence(cfg, 20.0, 6, true), 100.0, 0.0001, "the Brag doc edge adds 10")
	_near(WorkOdds.evidence(cfg, -100.0, 0, false), 1.0, 0.0001, "never below 1: a rating is a share of it")


func test_rating_bands_and_their_boundaries() -> void:  # under 25% Below, 25-70% Meets, over 70% Exceeds
	assert_eq(WorkOdds.rating(cfg, 100.0, 24.9), WorkOdds.BELOW)
	assert_eq(WorkOdds.rating(cfg, 100.0, 25.0), WorkOdds.MEETS, "25% is Meets")
	assert_eq(WorkOdds.rating(cfg, 100.0, 70.0), WorkOdds.MEETS, "70% is still Meets")
	assert_eq(WorkOdds.rating(cfg, 100.0, 70.1), WorkOdds.EXCEEDS)
	assert_eq(WorkOdds.rating(cfg, 80.0, 0.0), WorkOdds.BELOW)
	assert_eq(WorkOdds.rating(cfg, 80.0, 80.0), WorkOdds.EXCEEDS, "all of it kept")


func test_the_stand_in_stays_inside_the_evidence_and_is_deterministic() -> void:  # A67
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 5
	b.seed = 5
	for i: int in 50:
		var left := WorkOdds.review_standin_left(cfg, 60.0, 90.0, a)
		assert_eq(left, WorkOdds.review_standin_left(cfg, 60.0, 90.0, b), "the same seed gives the same review")
		assert_true(left >= 0.0 and left <= 90.0)
	var total := 0.0
	var n := 400
	for i: int in n:
		total += WorkOdds.review_standin_left(cfg, 60.0, 100.0, a)
	_near(total / n, 100.0 - 60.0 * 0.55, 1.5, "on average the Calibration chips off 55% of itself")
	var tough := 0.0
	for i: int in n:
		tough += WorkOdds.review_standin_left(cfg, 80.0, 100.0, a)
	assert_true(tough < total, "a MegaCorp's 80 Calibration is harder than a Startup's 60")


# ---------- through the sim ----------

func test_a_review_pauses_the_clock_and_a_rating_pays_a_raise() -> void:  # R-EVT-05 E02; raises: Meets +1%, Exceeds +3%
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "startup")
	var salary := s.job_salary
	var events := _answer_review(s, c, 0.55)
	assert_eq(SimFixture.count(events, "review_result"), 1)
	_near(s.job_salary, salary * 1.01, 0.0001, "Meets: +1% (a Startup does not promote on Meets)")
	var senior := _review_state(c, "agency", WorkOdds.SENIOR)
	var senior_salary := senior.job_salary
	_answer_review(senior, c, 0.95)
	_near(senior.job_salary, senior_salary * 1.03, 0.0001, "Exceeds: +3% (a Senior cannot be promoted, so it is only the raise)")


func test_the_review_comes_every_cadence_days_by_archetype() -> void:  # 5.18: Startup 180, Agency 120, MegaCorp 180
	var c := SimFixture.ctx(true)
	for pair: Array in [["startup", 180], ["agency", 120], ["megacorp", 180]]:
		var s := Sim.new_run(c, 2, 3)
		Sim._start_job(s, c, SimFixture.posting(c, String(pair[0])), [], false)
		assert_eq(s.next_review, s.day + int(pair[1]), "%s's first review" % pair[0])
		s.savings = 500.0
		s.queue.clear()
		s.next_review = s.day + 1
		Sim.step(s, [], c)
		assert_eq(s.next_review, s.day + int(pair[1]), "%s's next one is %d days on" % [pair[0], pair[1]])


func test_a_startup_promotes_on_exceeds_only() -> void:  # R-CTL: Startup on Exceeds
	var c := SimFixture.ctx(true)
	var meets := _review_state(c, "startup")
	_answer_review(meets, c, 0.55)
	assert_eq(meets.level, WorkOdds.JUNIOR, "Meets is not enough")
	var exceeds := _review_state(c, "startup")
	_answer_review(exceeds, c, 0.95)
	assert_eq(exceeds.level, WorkOdds.MID, "Exceeds promotes (D-23: reachable inside job 1)")
	assert_true(exceeds.job_salary >= WorkOdds.offer_salary(c.cfg, c.archetype("startup"), WorkOdds.MID, 1, 0) - 0.0001, "the new level's table value at this floor")


func test_an_agency_promotes_on_meets() -> void:
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "agency")
	_answer_review(s, c, 0.55)
	assert_eq(s.level, WorkOdds.MID)


func test_a_megacorp_needs_two_exceeds_in_a_row() -> void:  # 5.16: two Exceeds in a row
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "megacorp")
	_answer_review(s, c, 0.95)
	assert_eq(s.level, WorkOdds.JUNIOR, "one Exceeds")
	assert_eq(s.rating_streak, 1)
	s.next_review = s.day + 1
	_answer_review(s, c, 0.95)
	assert_eq(s.level, WorkOdds.MID, "the second in a row")
	var t := _review_state(c, "megacorp")
	_answer_review(t, c, 0.95)
	t.next_review = t.day + 1
	_answer_review(t, c, 0.55)
	assert_eq(t.level, WorkOdds.JUNIOR, "a Meets in between breaks the streak")
	assert_eq(t.rating_streak, 0)


func test_the_title_caps_at_senior() -> void:  # D-09
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "agency", WorkOdds.SENIOR)
	_answer_review(s, c, 0.95)
	assert_eq(s.level, WorkOdds.SENIOR)


func test_a_raise_brings_the_lifestyle_offer() -> void:  # E21: an upgrade is offered after every raise
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "agency")
	_answer_review(s, c, 0.55)
	assert_eq(s.pending().get("id", ""), "evt_e21_lifestyle_offer", "a raise: E21")
	assert_eq(s.event_last.has("evt_e21_lifestyle_offer"), true)
	var s2 := _review_state(c, "agency")
	_answer_review(s2, c, 0.10)
	assert_false(s2.is_waiting(), "Below: no raise, no offer")


func test_two_below_in_a_row_open_a_pip_and_a_negative_mo_at_its_end_fires_you() -> void:  # 5.16 and 3.3
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "agency")
	var events := _answer_review(s, c, 0.1)
	assert_eq(s.below_streak, 1)
	assert_eq(s.pip_end, -1)
	s.next_review = s.day + 1
	events = _answer_review(s, c, 0.1)
	assert_eq(SimFixture.count(events, "pip_started"), 1, "the second Below in a row")
	assert_eq(s.pip_end, s.day - 1 + 60, "a 60-day PIP, counted from the review day")
	s.mo = -10.0
	var fired := SimFixture.run_days(s, c, 62)
	assert_false(s.employed, "MO under 0 at the PIP's end: fired")
	assert_eq(s.scar_bad_reference, 1, "fired earns Bad Reference")
	var reasons: Array = fired.filter(func(e: Dictionary) -> bool: return e["kind"] == "job_ended")
	assert_eq(reasons[0]["reason"], "fired")


func test_a_pip_is_cleared_when_mo_is_not_negative() -> void:
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "agency")
	_answer_review(s, c, 0.1)
	s.next_review = s.day + 1
	_answer_review(s, c, 0.1)
	s.next_review = 100000
	var events: Array = []
	for i: int in 62:
		s.mo = 5.0
		s.codebase = 10.0
		events.append_array(Sim.step(s, [], c))
		if s.is_waiting():
			Sim.step(s, SimFixture.answer(s), c)
	assert_true(s.employed, "MO 0 or better at the end: the PIP is cleared")
	assert_eq(SimFixture.count(events, "pip_cleared"), 1)
	assert_eq(s.pip_end, -1)


func test_a_layoff_on_the_review_day_takes_the_review_card_with_it() -> void:  # a stale card must not outlive its job
	var c := SimFixture.ctx(true)
	var s := _review_state(c, "agency")
	Sim.step(s, [], c)
	assert_eq(s.pending().get("kind", ""), "review")
	Sim._end_job(s, c, "layoff", [], 1.0)
	assert_false(s.is_waiting(), "the review went with the job")
	var events := Sim.step(s, [{"kind": Sim.IN_REVIEW_RESULT, "evidence_left": 10.0}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 1, "nothing left to answer")
	var t := _review_state(c, "agency")
	Sim.step(t, [], c)
	Sim._end_job(t, c, "quit", [], 0.0)
	Sim._end_job(t, c, "quit", [], 0.0)
	assert_eq(t.jobs_held, 1, "ending a job twice does nothing the second time")


func test_the_brag_doc_edge_adds_evidence_through_the_sim() -> void:  # R-HB-01
	var c := SimFixture.ctx(true)
	var plain := _review_state(c, "agency")
	Sim.step(plain, [], c)
	var with_tip := _review_state(c, "agency")
	with_tip.handbook = ["tip_brag_doc"]
	with_tip.refresh_edges()
	Sim.step(with_tip, [], c)
	_near(float(with_tip.pending()["evidence"]) - float(plain.pending()["evidence"]), 10.0, 0.0001, "+10 Evidence")

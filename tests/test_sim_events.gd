@tool
extends McpTestSuite
## The event system (GDD 5.19, R-EVT-01..05, R-RUN-02; DECISIONS A62, A66, A69, A72): which events can happen, the effects
## of M1's ten, cooldowns, the Burnout auto-resolve and its warning beats, run 1's authored chain, layoff selection
## (O1: Manager Opinion is not an input) and O5 (incidents scale with the Codebase).

const E12 := "evt_e12_incident_prod"


func suite_name() -> String:
	return "sim_events"


func _near(actual: float, expected: float, eps: float, what: String = "") -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


## A quiet employed state at an archetype, started by hand on day 100.
func _job(c: SimContext, archetype: String = "startup", remote: bool = false) -> SimState:
	var s := Sim.new_run(c, 2, 21)
	s.day = 100
	Sim._start_job(s, c, SimFixture.posting(c, archetype, 0, 1, remote), [], false)
	s.savings = 500.0
	s.queue.clear()
	s.chains.clear()
	return s


func _present(s: SimState, c: SimContext, id: String) -> Array:
	var events: Array = []
	Sim._present_event(s, c, id, events)
	return events


func _choose(s: SimState, c: SimContext, choice: String) -> Array:
	return Sim.step(s, [{"kind": Sim.IN_CHOOSE, "choice": choice}], c)


# ---------- the data's tiers and eligibility (R-EVT-01) ----------

func test_the_ten_events_and_their_tiers() -> void:  # A62, AC-EVT01-1
	var c := SimFixture.ctx(true)
	var by_tier: Dictionary = {"scheduled": [], "telegraphed": [], "random": []}
	for id: String in c.events:
		if not id.begins_with("_"):
			(by_tier[(c.events[id] as Dictionary)["tier"]] as Array).append(id.substr(0, 7))
	for tier: String in by_tier:
		(by_tier[tier] as Array).sort()
	assert_eq(by_tier["scheduled"], ["evt_e01", "evt_e02", "evt_e04", "evt_e21"], "monthly, the review, the lease, after a raise")
	assert_eq(by_tier["telegraphed"], ["evt_e07", "evt_e08"], "a resizing and the return-to-office memo")
	assert_eq(by_tier["random"], ["evt_e12", "evt_e18", "evt_e20", "evt_e24"], "an incident, a recruiter, a laptop, an overtime ask")


func test_the_rto_memo_needs_a_remote_job_and_an_archetype_that_allows_it() -> void:  # E08; A72: a Startup after 360 days
	var c := SimFixture.ctx(true)
	var evt: Dictionary = c.events["evt_e08_rto_mandate"]
	var s := _job(c, "startup", false)
	assert_false(EventPlan.eligible(c, s, evt), "an onsite job has no remote to take back")
	s = _job(c, "startup", true)
	assert_false(EventPlan.eligible(c, s, evt), "a Startup's memo comes after your first 360 days")
	s.day = s.job_start + 360
	assert_true(EventPlan.eligible(c, s, evt), "after 360 days")
	s = _job(c, "megacorp", true)
	assert_true(EventPlan.eligible(c, s, evt), "a MegaCorp from the first day")
	s = _job(c, "agency", true)
	s.day = s.job_start + 999
	assert_false(EventPlan.eligible(c, s, evt), "an Agency never")


func test_the_overtime_ask_needs_a_deadline_or_an_incident_close_by() -> void:  # E24: a deadline in 3 days, or an incident
	var c := SimFixture.ctx(true)
	var evt: Dictionary = c.events["evt_e24_overtime_ask"]
	var s := _job(c)
	s.ticket_deadline = s.day + 10
	assert_false(EventPlan.eligible(c, s, evt), "a deadline 10 days off")
	s.ticket_deadline = s.day + 3
	assert_true(EventPlan.eligible(c, s, evt), "a deadline in 3 days")
	s.ticket_deadline = s.day + 10
	s.last_incident_day = s.day - 2
	assert_true(EventPlan.eligible(c, s, evt), "or an incident 2 days ago")


func test_choices_follow_their_requirements() -> void:  # R-EVT-04, A66
	var c := SimFixture.ctx(true)
	var e12: Dictionary = c.events[E12]
	var s := _job(c)
	assert_eq(EventPlan.available_choices(c, s, e12).size(), 2, "fix it or escalate")
	s.job_flags.append("owns_service")
	assert_eq(EventPlan.available_choices(c, s, e12).size(), 1, "once you own the service, Escalate is gone (A66)")
	var e04: Dictionary = c.events["evt_e04_lease_renewal"]
	assert_eq(EventPlan.available_choices(c, s, e04).size(), 1, "the Shared room has no tier below")
	s.home = 1
	assert_eq(EventPlan.available_choices(c, s, e04).size(), 2, "a One-bed can move down")
	var e08: Dictionary = c.events["evt_e08_rto_mandate"]
	assert_eq(EventPlan.available_choices(c, s, e08).size(), 2, "comply or quit")
	s.handbook = ["tip_remote_in_writing"]
	assert_eq(EventPlan.available_choices(c, s, e08).size(), 2, "the tip alone is not enough: the contract needs the clause too")
	s.job_clauses = ["remote_in_writing"]
	assert_eq(EventPlan.available_choices(c, s, e08).size(), 3, "the tip and the clause unlock Push back")


# ---------- the effects of M1's events ----------

func test_an_incident_you_fix_costs_burnout_and_makes_you_the_owner() -> void:  # E12
	var c := SimFixture.ctx(true)
	var s := _job(c)
	s.codebase = 40.0
	var events := _present(s, c, E12)
	assert_eq(s.pending().get("id", ""), E12)
	events = _choose(s, c, "fix_it")
	assert_eq(SimFixture.count(events, "tip"), 1, "Ducky's tip follows the choice")
	assert_true(s.mo >= 9.9 and s.burnout > 14.0 and s.codebase < 36.0, "MO +10, Burnout +15, Codebase -5 (and a day's change)")
	assert_true(s.job_flags.has("owns_service"))
	_present(s, c, E12)
	assert_eq(s.pending()["choices"], ["fix_it"], "the second incident has one button")


func test_escalating_costs_mo_but_little_burnout() -> void:  # E12
	var c := SimFixture.ctx(true)
	var s := _job(c)
	_present(s, c, E12)
	_choose(s, c, "escalate")
	assert_true(s.mo < -2.0 and s.burnout < 4.0, "MO -3, Burnout +2")
	assert_false(s.job_flags.has("owns_service"))


func test_the_laptop_dies() -> void:  # E20: pay 1.2 k$ or limp for 30 days at x0.8
	var c := SimFixture.ctx(true)
	var s := _job(c)
	var before := s.savings
	_present(s, c, "evt_e20_laptop_dies")
	_choose(s, c, "pay")
	_near(s.savings, before - 1.2, 0.0001, "a new laptop")
	var t := _job(c)
	_present(t, c, "evt_e20_laptop_dies")
	_choose(t, c, "limp")
	assert_eq(t.speed_mod_until, t.day + 29, "30 days from the choice (the day then ticks)")
	_near(t.speed_mod, 0.8, 0.0001)
	var slow := t.ticket_progress
	Sim.step(t, [], c)
	var gained := t.ticket_progress - slow
	t.speed_mod_until = -1
	var before_tick := t.ticket_progress
	Sim.step(t, [], c)
	assert_true(gained < t.ticket_progress - before_tick, "a limping laptop is slower than a healthy one")


func test_the_lifestyle_offer_moves_you_up_a_tier() -> void:  # E21
	var c := SimFixture.ctx(true)
	var s := _job(c)
	var before := s.savings
	_present(s, c, "evt_e21_lifestyle_offer")
	_choose(s, c, "upgrade")
	assert_eq(s.home, 1)
	assert_true(s.savings < before - 1.4, "one month of the One-bed's rent")


func test_overtime_locks_the_hours_for_five_days() -> void:  # E24: Hours locked at 5 for 5 days, MO +4
	var c := SimFixture.ctx(true)
	var s := _job(c)
	_present(s, c, "evt_e24_overtime_ask")
	_choose(s, c, "stay_late")
	assert_eq(s.hours, 5)
	assert_true(s.mo >= 3.9, "MO +4")
	var events := Sim.step(s, [{"kind": Sim.IN_SET_HOURS, "notch": 1}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 1, "locked")
	assert_eq(s.hours, 5)
	SimFixture.run_days(s, c, 6)
	events = Sim.step(s, [{"kind": Sim.IN_SET_HOURS, "notch": 1}], c)
	assert_eq(s.hours, 1, "free again after the lock")


func test_the_recruiter_call_books_an_interview() -> void:  # E18: a posting that skips to the interview
	var c := SimFixture.ctx(true)
	var s := _job(c)
	_present(s, c, "evt_e18_recruiter_dm")
	var events := _choose(s, c, "take_call")
	assert_eq(SimFixture.count(events, "recruiter_posting"), 1)
	var app: Dictionary = s.applications[0]
	assert_true(bool(app["callback"]) and app["status"] == "callback", "no callback to wait for")
	assert_true(int(app["interview"]) - s.day >= 2 and int(app["interview"]) - s.day <= 7, "an interview 3-7 days out")


func test_the_rto_memo_choices() -> void:  # E08: Comply (onsite, +0.3 Burnout a day), Push back (MO -15, keep remote), Quit
	var c := SimFixture.ctx(true)
	var s := _job(c, "megacorp", true)
	s.handbook = ["tip_remote_in_writing"]
	s.job_clauses = ["remote_in_writing"]
	_present(s, c, "evt_e08_rto_mandate")
	_choose(s, c, "push_back")
	assert_true(s.job_remote, "kept remote")
	assert_true(s.mo < -14.0, "MO -15")
	var t := _job(c, "megacorp", true)
	_present(t, c, "evt_e08_rto_mandate")
	_choose(t, c, "comply")
	assert_false(t.job_remote, "back to the office")
	_near(t.commute_burnout, 0.3, 0.0001)
	var u := _job(c, "megacorp", true)
	_present(u, c, "evt_e08_rto_mandate")
	_choose(u, c, "quit")
	assert_false(u.employed, "a voluntary exit")


func test_the_lease_card_accepts_the_raise() -> void:  # E04 (D-28: no negotiation)
	var c := SimFixture.ctx(true)
	var s := _job(c)
	s.home = 1
	s.rent = 1.5
	_present(s, c, "evt_e04_lease_renewal")
	_choose(s, c, "accept")
	_near(s.rent, 1.65, 0.0001)
	assert_eq(s.lease_day, s.day - 1, "a new year's lease")


# ---------- cooldowns and rolls ----------

func test_e12s_cooldown_is_five_days() -> void:  # A69 / MC-23
	var c := SimFixture.ctx()
	var cooldown := int(((c.events[E12] as Dictionary)["trigger"] as Dictionary)["cooldown_days"])
	assert_eq(cooldown, 5, "5 days, not the spec's 20")
	c.random_events.clear()
	c.chain_events.clear()
	var s := _job(c)
	s.codebase = 100.0
	s.last_incident_day = s.day
	var fired := 0
	for i: int in 4:
		s.codebase = 100.0
		fired += SimFixture.count(Sim.step(s, [], c), "event")
		if s.is_waiting():
			Sim.step(s, SimFixture.answer(s), c)
	assert_eq(int(s.stats.get("incidents", 0)), 0, "no incident rolls inside the cooldown")


# ---------- the Burnout auto-resolve (R-EVT-02) ----------

func test_burnout_makes_the_choice_for_you_with_the_odds_the_gdd_gives() -> void:  # (Burnout - 70) / 30 from 75
	var c := SimFixture.ctx(true)
	for case: Array in [[74.0, 0.0], [90.0, 20.0 / 30.0], [100.0, 1.0]]:
		var autos := 0
		var n := 300
		for i: int in n:
			var s := Sim.new_run(c, 2, 1000 + i)
			s.day = 100
			Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
			s.queue.clear()
			s.burnout = float(case[0])
			var events := _present(s, c, E12)
			if SimFixture.count(events, "auto_resolved") == 1:
				autos += 1
				assert_true(s.job_flags.has("owns_service"), "it takes the exhausted choice: Fix it")
				assert_false(s.is_waiting(), "no card is left waiting")
			else:
				assert_true(s.is_waiting(), "otherwise the card waits")
		var share := float(autos) / n
		assert_true(absf(share - float(case[1])) < 0.08, "Burnout %.0f: %.2f auto-resolved, expected about %.2f" % [case[0], share, case[1]])


func test_an_event_without_an_exhausted_choice_is_never_auto_resolved() -> void:  # the review's duel; payday
	var c := SimFixture.ctx(true)
	var s := _job(c)
	s.burnout = 100.0
	_present(s, c, "evt_e01_payday")
	assert_false(s.is_waiting(), "a notification, nothing to decide")
	assert_eq(int(s.stats.get("auto_resolved", 0)), 0)


func test_the_three_warning_beats() -> void:  # R-EVT-02: as Burnout first crosses 60, 70 and 75
	var c := SimFixture.ctx(true)
	var s := _job(c)
	var seen: Array = []
	for level: Array in [[59.0, 0], [60.5, 1], [70.5, 2], [75.5, 3]]:
		s.burnout = float(level[0])
		for e: Dictionary in Sim.step(s, [], c):
			if e["kind"] == "burnout_warning":
				seen.append(e["level"])
		assert_eq(seen.size(), int(level[1]), "after Burnout %.1f" % level[0])
	assert_eq(seen, [0, 1, 2], "once each, in order")
	s.burnout = 30.0
	Sim.step(s, [], c)
	s.burnout = 60.5
	var again := Sim.step(s, [], c).filter(func(e: Dictionary) -> bool: return e["kind"] == "burnout_warning")
	assert_eq(again.size(), 1, "re-armed once Burnout has fallen well below")


# ---------- layoffs (R-EVT-03, P-03, O1) ----------

func test_layoff_cut_counts() -> void:  # DECISIONS A72: about 20% / 15% / 10% of the floor
	var cfg := WorkConfig.new()
	assert_eq(WorkOdds.layoff_cut_count(cfg, SimFixture.startup(), 8), 2)
	assert_eq(WorkOdds.layoff_cut_count(cfg, SimFixture.agency(), 12), 2)
	assert_eq(WorkOdds.layoff_cut_count(cfg, SimFixture.megacorp(), 24), 2)
	assert_eq(WorkOdds.layoff_cut_count(cfg, SimFixture.megacorp(), 3), 1, "at least one")
	assert_eq(WorkOdds.layoff_cut_count(cfg, SimFixture.startup(), 1), 1, "never more than the floor holds")


func test_a_resizing_cuts_the_highest_paid_most_often_and_never_looks_at_mo() -> void:  # P-03: 80% salary rank, 20% luck
	var cfg := WorkConfig.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var salaries: Array = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5]
	var hits: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
	for i: int in 3000:
		var cut := WorkOdds.layoff_cuts(cfg, salaries, 2, rng)
		assert_eq(cut.size(), 2)
		for idx: int in cut:
			hits[idx] += 1
	assert_true(hits[7] > hits[0] * 4, "the highest salary (%d cuts) is cut far more than the lowest (%d)" % [hits[7], hits[0]])
	assert_true(hits[0] > 0, "luck still matters: even the cheapest can go (%d times)" % hits[0])
	var order: Array[int] = []
	for i: int in 8:
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return hits[a] < hits[b])
	assert_eq(order, [0, 1, 2, 3, 4, 5, 6, 7] as Array[int], "the odds rise with the salary rank")


func test_manager_opinion_has_no_effect_on_who_is_laid_off() -> void:  # O1, AC-S14-4: the same seed, any MO, the same outcome
	var c := SimFixture.ctx(true)
	var differing := 0
	for seed_n: int in 60:
		var outcomes: Array = []
		for mo: float in [-100.0, 0.0, 100.0]:
			var s := Sim.new_run(c, 2, 500 + seed_n)
			s.day = 100
			Sim._start_job(s, c, SimFixture.posting(c, "startup", WorkOdds.SENIOR), [], false)
			s.queue.clear()
			s.mo = mo
			s.job_salary = 6.0
			var salaries_before: Array = []
			for cw: Dictionary in s.coworkers:
				salaries_before.append(cw["salary"])
			Sim._resize(s, c, {"event": Sim.EVT_RESIZING, "scripted": false}, [])
			var left: Array = []
			for cw: Dictionary in s.coworkers:
				left.append(cw["id"])
			outcomes.append([s.employed, left])
		if outcomes[0] != outcomes[1] or outcomes[1] != outcomes[2]:
			differing += 1
	assert_eq(differing, 0, "MO -100, 0 and 100 laid off the same people on every seed")


func test_a_survived_resizing_removes_the_cut_coworkers_and_schedules_the_next() -> void:  # DECISIONS A72
	var c := SimFixture.ctx(true)
	var survived := 0
	for seed_n: int in 80:
		var s := Sim.new_run(c, 2, 700 + seed_n)
		s.day = 100
		Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
		s.queue.clear()
		var before := s.coworkers.size()
		s.chains.clear()
		Sim._resize(s, c, {"event": Sim.EVT_RESIZING, "scripted": false}, [])
		if s.employed:
			survived += 1
			assert_eq(s.coworkers.size(), before - 2, "two desks went dark")
			assert_eq(s.chains.size(), 1, "the next resizing is already on the calendar")
			assert_eq(int(s.stats.get("resizings_survived", 0)), 1)
		else:
			assert_eq(s.pending().get("kind", ""), "layoff_scene", "the scene follows a layoff")
	assert_true(survived > 40, "a Junior is cheap, so most resizings spare you (%d of 80)" % survived)


# ---------- run 1's authored chain (R-RUN-02, D-22, D-23) ----------

func test_run_ones_resizing_chain_has_five_signs_and_a_layoff_on_day_240() -> void:
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 1, 3)
	assert_eq(s.chains.size(), 1, "the chain is planned on day 0")
	assert_eq(int((s.chains[0] as Dictionary)["fire_day"]), 240)
	var sign_days: Array = []
	var prep_day := -1
	var ended_day := -1
	var severance := -1.0
	while s.day < 245 and not s.ended:
		s.burnout = 0.0   # a burnt-out you would have the prep card answered for you (R-EVT-02)
		var inputs: Array = SimFixture.answer(s) if s.is_waiting() else []
		for e: Dictionary in Sim.step(s, inputs, c):
			if e["kind"] == "rumor":
				sign_days.append(s.day)
			elif e["kind"] == "job_ended" and ended_day < 0:
				ended_day = s.day
				severance = float(e["severance_months"])
		if s.pending().get("id", "") == "evt_e07_resizing" and prep_day < 0:
			prep_day = s.day
	assert_eq(sign_days, [150, 165, 190, 210, 235], "five readable signs before the scene")
	assert_eq(prep_day, 190, "the prep card comes with the third sign (it showed on day %d)" % prep_day)
	assert_eq(ended_day, 240, "guaranteed on day 240")
	_near(severance, 1.0, 0.0001, "run 1's severance is always a month")
	assert_false(s.employed)
	assert_eq(int(s.stats.get("layoffs", 0)), 1)


func test_run_one_reaches_the_review_and_a_promotion_before_the_layoff() -> void:  # D-23, 3.3: day 180
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 1, 3)
	var review_day := -1
	while s.day < 239 and review_day < 0:
		s.burnout = 0.0
		var inputs: Array = SimFixture.answer(s) if s.is_waiting() else []
		if s.pending().get("kind", "") == "review":
			review_day = s.day
			inputs = [{"kind": Sim.IN_REVIEW_RESULT, "evidence_left": float(s.pending()["evidence"]) * 0.95}]
		Sim.step(s, inputs, c)
	assert_eq(review_day, 180, "the first review is day 180")
	assert_eq(s.level, WorkOdds.MID, "an Exceeds promotes a Startup Junior (D-23)")


func test_a_generated_chain_has_a_rumor_10_to_30_days_ahead_and_a_prep_card() -> void:  # R-EVT-01
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 31)
	Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
	var chain: Dictionary = s.chains[0]
	var fire := int(chain["fire_day"])
	var rumor_day := int((chain["stages"] as Array)[0]["day"])
	assert_true(fire - rumor_day >= 10 and fire - rumor_day <= 30, "the rumor leads by %d days" % (fire - rumor_day))
	assert_true(fire - s.day >= 210 and fire - s.day <= 330, "a Startup resizes about every 9 months (270 +/- 60)")
	assert_true(bool((chain["stages"] as Array)[0]["prep"]), "the prep card shows with the rumor")


func test_the_prep_choices() -> void:  # DECISIONS A72: update your profile, ask Priya, cut spending
	var c := SimFixture.ctx(true)
	var s := _job(c)
	s.board_day = s.day - 3
	_present(s, c, Sim.EVT_RESIZING)
	assert_eq((s.pending()["choices"] as Array).size(), 3)
	_choose(s, c, "update_profile")
	assert_eq(s.board_day, s.day - 1, "the board opened early with fresh postings")
	var t := _job(c)
	_present(t, c, Sim.EVT_RESIZING)
	_choose(t, c, "cut_spending")
	_near(t.living_mult, 0.8, 0.0001, "living costs x0.8 until the scene")
	var u := _job(c)
	u.chains.append({"event": Sim.EVT_RESIZING, "fire_day": u.day + 20, "stages": [], "scripted": false})
	for cw: Dictionary in u.coworkers:
		cw["rapport"] = 60.0
	var fire := u.day + 20
	_present(u, c, Sim.EVT_RESIZING)
	_choose(u, c, "ask_priya")
	assert_eq(u.layoff_known_day, fire, "a coworker at Rapport 60+ tells you the date")
	var v := _job(c)
	v.chains.append({"event": Sim.EVT_RESIZING, "fire_day": v.day + 20, "stages": [], "scripted": false})
	_present(v, c, Sim.EVT_RESIZING)
	_choose(v, c, "ask_priya")
	assert_eq(v.layoff_known_day, -1, "at Rapport 50 nobody tells you anything")


# ---------- floor depth (R-ARC-02) ----------

func test_floor_depth_speeds_up_random_events_but_not_the_review() -> void:  # 5.18: scheduled events keep their cadence
	var cfg := WorkConfig.new()
	_near(WorkOdds.random_event_p(cfg, 3.6, 1, 1.0), 0.01, 0.000001, "3.6 a year over 360 days")
	_near(WorkOdds.random_event_p(cfg, 3.6, 2, 1.0), 0.0115, 0.000001, "x1.15 on floor 2")
	_near(WorkOdds.random_event_p(cfg, 3.6, 5, 3.0), 0.01 * 1.6 * 3.0, 0.000001, "floor 5 while the Studio films")
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	Sim._start_job(s, c, SimFixture.posting(c, "startup", 0, 4), [], false)
	assert_eq(s.next_review, s.day + 180, "the review's cadence does not change with the floor")


# ---------- O5: incidents scale with the Codebase ----------

func _incidents(c: SimContext, codebase: float, seed_n: int, days: int) -> int:
	var s := Sim.new_run(c, 2, seed_n)
	Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
	s.savings = 1000000.0
	s.next_review = -1
	for i: int in days:
		s.codebase = codebase
		s.burnout = 0.0
		s.queue.clear()
		Sim.step(s, [], c)
	return int(s.stats.get("incidents", 0))


func _o5_context(cooldown: int) -> SimContext:
	var c := SimFixture.ctx(false)
	c.random_events.clear()
	c.chain_events.clear()
	(c.archetypes["startup"] as ArchetypeData).layoff_interval_days = 0
	((c.events[E12] as Dictionary)["trigger"] as Dictionary)["cooldown_days"] = cooldown
	return c


func test_incidents_at_codebase_80_are_at_least_three_times_those_at_20() -> void:  # O5, AC-S14-5, R-CB-02, MC-23
	var c := _o5_context(5)
	var low := 0
	var high := 0
	for seed_n: int in 150:
		low += _incidents(c, 20.0, 5000 + seed_n, 720)
		high += _incidents(c, 80.0, 5000 + seed_n, 720)
	var ratio := float(high) / float(low)
	assert_true(ratio >= 2.85 and ratio <= 3.4, "Codebase 80 vs 20: %d vs %d incidents, %.2fx (the formula says 3.06x with a 5-day cooldown)" % [high, low, ratio])


func test_the_specs_twenty_day_cooldown_would_fail_o5() -> void:  # MC-23: about 2.3x
	var c := _o5_context(20)
	var low := 0
	var high := 0
	for seed_n: int in 150:
		low += _incidents(c, 20.0, 5000 + seed_n, 720)
		high += _incidents(c, 80.0, 5000 + seed_n, 720)
	var ratio := float(high) / float(low)
	assert_true(ratio < 2.7, "with 20 days: %d vs %d, %.2fx" % [high, low, ratio])

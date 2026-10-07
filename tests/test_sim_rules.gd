@tool
extends McpTestSuite
## The career run's formulas and money rules (GDD 5.14-5.17, 5.20; DECISIONS A63-A65), a worked example each. Fixtures use
## the Run Spec's numbers (WorkConfig.new(), the archetypes built in SimFixture), so tuning the .tres never breaks them.
## Pure: res:// files only, no autoloads, no user:// (INV-12).

var cfg: WorkConfig
var startup: ArchetypeData
var agency: ArchetypeData
var megacorp: ArchetypeData


func suite_name() -> String:
	return "sim_rules"


func setup() -> void:
	cfg = WorkConfig.new()
	startup = SimFixture.startup()
	agency = SimFixture.agency()
	megacorp = SimFixture.megacorp()


func _near(actual: float, expected: float, eps: float, what: String) -> void:
	assert_true(absf(actual - expected) <= eps, "%s: expected %.4f, got %.4f" % [what, expected, actual])


# ---------- the daily formulas (5.16, 5.17) ----------

func test_ticket_rate_examples() -> void:  # R-STAT-03: (100 / size) x Hours x Skill x Codebase x process
	var j := WorkOdds.JUNIOR
	_near(WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, startup, j, 1, 1.0), 4.5, 0.0001, "M ticket, notch 3, Codebase 20: 100/20 x 0.9")
	_near(WorkOdds.ticket_rate(cfg, 0, 3, 0.0, 20.0, startup, j, 1, 1.0), 9.0, 0.0001, "S ticket")
	_near(WorkOdds.ticket_rate(cfg, 2, 3, 0.0, 20.0, startup, j, 1, 1.0), 100.0 / 35.0 * 0.9, 0.0001, "L ticket")
	_near(WorkOdds.ticket_rate(cfg, 1, 5, 40.0, 0.0, startup, j, 1, 1.0), 9.0, 0.0001, "notch 5 x1.5, Skill 40 x1.2")
	_near(WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, megacorp, j, 1, 1.0), 4.5 * 0.67, 0.0001, "a MegaCorp's process x0.67")
	_near(WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, startup, j, 1, 0.8), 3.6, 0.0001, "a laptop that limps: x0.8")


func test_senior_speed_modifiers() -> void:  # R-CTL-03: calendar tax x0.85; Clean x0.85; Fast x1.2
	var s := WorkOdds.SENIOR
	var balanced := WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, startup, s, WorkOdds.QUALITY_BALANCED, 1.0)
	_near(balanced, 4.5 * 0.85, 0.0001, "Senior, Balanced")
	_near(WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, startup, s, WorkOdds.QUALITY_CLEAN, 1.0), 4.5 * 0.85 * 0.85, 0.0001, "Senior, Clean")
	_near(WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, startup, s, WorkOdds.QUALITY_FAST, 1.0), 4.5 * 0.85 * 1.2, 0.0001, "Senior, Fast")
	_near(WorkOdds.ticket_rate(cfg, 1, 3, 0.0, 20.0, startup, WorkOdds.MID, WorkOdds.QUALITY_FAST, 1.0), 4.5, 0.0001, "a Mid has no quality bar and no calendar tax")


func test_burnout_per_day() -> void:  # R-STAT-03: l[h] - r[home] + 0.2 [C >= 70] + 0.4 [runway < 2] + commute
	_near(WorkOdds.burnout_delta(cfg, 3, 0, 20.0, 5.0, 0.0, false), 0.1, 0.0001, "notch 3 in the Shared room")
	_near(WorkOdds.burnout_delta(cfg, 1, 1, 20.0, 5.0, 0.0, false), -0.7, 0.0001, "notch 1 in a One-bed: -0.6 - 0.10")
	_near(WorkOdds.burnout_delta(cfg, 5, 2, 20.0, 5.0, 0.0, false), 0.75, 0.0001, "notch 5 in The Studio: 1.0 - 0.25")
	_near(WorkOdds.burnout_delta(cfg, 5, 2, 70.0, 5.0, 0.0, false), 0.95, 0.0001, "a heavy Codebase (70+) adds 0.2")
	_near(WorkOdds.burnout_delta(cfg, 5, 2, 20.0, 1.5, 0.0, false), 1.15, 0.0001, "a runway under 2 months adds 0.4")
	_near(WorkOdds.burnout_delta(cfg, 5, 2, 20.0, 5.0, 0.3, false), 1.05, 0.0001, "an RTO commute adds 0.3")


func test_overtime_edge_trims_only_the_notch_5_gain() -> void:  # R-HB-01: Burnout gain at notch 5 is 10% lower
	_near(WorkOdds.burnout_delta(cfg, 5, 2, 20.0, 5.0, 0.0, true), 0.9 - 0.25, 0.0001, "notch 5 with the edge")
	_near(WorkOdds.burnout_delta(cfg, 4, 2, 20.0, 5.0, 0.0, true), 0.5 - 0.25, 0.0001, "notch 4 is untouched")
	_near(WorkOdds.burnout_delta(cfg, 1, 2, 20.0, 5.0, 0.0, true), -0.6 - 0.25, 0.0001, "rest is never scaled")


func test_idle_burnout_uses_the_hours_notch_but_no_work_terms() -> void:  # DECISIONS A73: D-04's one clock; the slider still decides how hard you push
	_near(WorkOdds.idle_burnout_delta(cfg, 3, 0, 5.0), 0.1, 0.0001, "notch 3 in the Shared room, comfortable")
	_near(WorkOdds.idle_burnout_delta(cfg, 1, 0, 5.0), -0.6, 0.0001, "notch 1 is rest")
	_near(WorkOdds.idle_burnout_delta(cfg, 1, 0, 1.0), -0.2, 0.0001, "...with a runway under 2 months on your mind")
	_near(WorkOdds.idle_burnout_delta(cfg, 3, 2, 5.0), 0.1 - 0.25, 0.0001, "The Studio recovers you")
	_near(WorkOdds.idle_burnout_delta(cfg, 5, 3, 5.0), 1.0 - 0.35, 0.0001, "hustle culture at The Penthouse")


func test_mo_per_day_and_utilization() -> void:  # R-STAT-03; the Agency's utilization at notches 1-2
	var table: Array[float] = [-0.15, -0.05, 0.0, 0.05, 0.10]
	for i: int in 5:
		_near(WorkOdds.mo_delta(cfg, startup, i + 1), table[i], 0.0001, "Startup notch %d" % (i + 1))
	_near(WorkOdds.mo_delta(cfg, agency, 1), -0.15 - 0.2, 0.0001, "Agency notch 1: utilization -0.2")
	_near(WorkOdds.mo_delta(cfg, agency, 2), -0.05 - 0.2, 0.0001, "Agency notch 2")
	_near(WorkOdds.mo_delta(cfg, agency, 3), 0.0, 0.0001, "Agency notch 3: no utilization")


func test_codebase_drift() -> void:  # 5.16: by archetype, plus a Senior's quality bar
	_near(WorkOdds.codebase_drift(cfg, startup, WorkOdds.JUNIOR, 2), 0.08, 0.0001, "a Junior has no quality bar")
	_near(WorkOdds.codebase_drift(cfg, startup, WorkOdds.SENIOR, WorkOdds.QUALITY_CLEAN), 0.08 - 0.05, 0.0001, "Clean")
	_near(WorkOdds.codebase_drift(cfg, startup, WorkOdds.SENIOR, WorkOdds.QUALITY_FAST), 0.08 + 0.12, 0.0001, "Fast")
	_near(WorkOdds.codebase_drift(cfg, megacorp, WorkOdds.SENIOR, WorkOdds.QUALITY_BALANCED), 0.04, 0.0001, "Balanced, MegaCorp")


func test_incident_odds_and_gaps() -> void:  # R-CB-02: p = 0.002 + 0.0006 C: one in 71 / 32 / 20 days
	_near(WorkOdds.incident_p(cfg, 20.0, 1, 1.0), 0.014, 0.000001, "Codebase 20")
	_near(WorkOdds.incident_p(cfg, 50.0, 1, 1.0), 0.032, 0.000001, "Codebase 50")
	_near(WorkOdds.incident_p(cfg, 80.0, 1, 1.0), 0.050, 0.000001, "Codebase 80")
	_near(WorkOdds.incident_p(cfg, 20.0, 3, 3.0), 0.014 * 1.3 * 3.0, 0.000001, "floor 3 (x1.30) while the Studio films (x3)")
	# GDD 5.16 and MC-23: a 20-day cooldown stretches the gaps to about 91 / 51 / 40 days and fails O5 at 2.3x; 5 days passes at 3.1x
	_near(WorkOdds.incident_gap_days(cfg, 20.0, 20), 91.4, 0.1, "20-day cooldown, Codebase 20")
	_near(WorkOdds.incident_gap_days(cfg, 80.0, 20), 40.0, 0.01, "20-day cooldown, Codebase 80")
	assert_true(WorkOdds.incident_gap_days(cfg, 20.0, 20) / WorkOdds.incident_gap_days(cfg, 80.0, 20) < 3.0, "20 days fails O5's 3x")
	assert_true(WorkOdds.incident_gap_days(cfg, 20.0, 5) / WorkOdds.incident_gap_days(cfg, 80.0, 5) >= 3.0, "5 days passes O5's 3x (A69)")


# ---------- money (5.15) ----------

func test_offer_salary_table() -> void:  # 5.15: the level's base x the archetype's multiplier
	var want: Dictionary = {"startup": [2.55, 3.57, 5.10], "agency": [2.40, 3.36, 4.80], "megacorp": [3.75, 5.25, 7.50]}
	var arch: Dictionary = {"startup": startup, "agency": agency, "megacorp": megacorp}
	for id: String in want:
		for level: int in 3:
			_near(WorkOdds.offer_salary(cfg, arch[id], level, 1, 0), (want[id] as Array)[level], 0.0001, "%s %s" % [id, WorkOdds.LEVELS[level]])


func test_offer_salary_floor_and_resume_gap() -> void:  # R-ARC-02 +4% a floor; the Resume Gap takes 10% per stack
	_near(WorkOdds.offer_salary(cfg, agency, WorkOdds.SENIOR, 3, 0), 6.0 * 0.8 * 1.08, 0.0001, "Senior Agency on floor 3")
	_near(WorkOdds.offer_salary(cfg, agency, WorkOdds.SENIOR, 3, 2), 6.0 * 0.8 * 1.08 * 0.8, 0.0001, "two Resume Gap stacks")
	_near(WorkOdds.offer_salary(cfg, startup, WorkOdds.JUNIOR, 5, 0), 3.0 * 0.85 * 1.16, 0.0001, "floor 5: x1.16")


func test_floor_multipliers() -> void:  # 6.1's table
	var events: Array[float] = [1.0, 1.15, 1.30, 1.45, 1.60]
	var salary: Array[float] = [1.0, 1.04, 1.08, 1.12, 1.16]
	for n: int in 5:
		_near(WorkOdds.floor_mult(cfg.floor_event_step, n + 1), events[n], 0.0001, "event frequency, floor %d" % (n + 1))
		_near(WorkOdds.floor_mult(cfg.floor_salary_step, n + 1), salary[n], 0.0001, "offer salary, floor %d" % (n + 1))
	_near(WorkOdds.duel_doubt(cfg, 118.0, 2), 127.44, 0.001, "Doubt HP, Startup, floor 2")
	_near(WorkOdds.duel_doubt(cfg, 128.0, 3), 148.48, 0.001, "Doubt HP, Mid-size, floor 3")
	_near(WorkOdds.duel_doubt(cfg, 132.0, 5), 174.24, 0.001, "Doubt HP, Big corp, floor 5")


func test_start_savings_and_runway() -> void:  # DECISIONS A68, D-30: months of the Shared room's bills (0.9 + 1.2 = 2.1 k$)
	var intern := load("res://data/backgrounds/intern.tres") as BackgroundData
	var grad := load("res://data/backgrounds/graduate.tres") as BackgroundData
	_near(WorkOdds.start_savings(cfg, intern, false), 2.1, 0.0001, "the Intern: 1 month")
	_near(WorkOdds.start_savings(cfg, grad, false), 1.68, 0.0001, "the Graduate: 0.8 months")
	_near(WorkOdds.start_savings(cfg, grad, true), 1.68 + 2.1, 0.0001, "the Emergency fund edge adds a month")
	_near(WorkOdds.runway_months(4.2, 0.9, 1.2), 2.0, 0.0001, "4.2 k$ against 2.1 k$ a month")


func test_severance_rules() -> void:  # 5.15 and DECISIONS A64
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	_near(WorkOdds.severance_months(cfg, startup, 240, true, rng), 1.0, 0.0001, "run 1's Startup layoff is always 1 month")
	var seen: Dictionary = {}
	for i: int in 60:
		seen[WorkOdds.severance_months(cfg, startup, 100, false, rng)] = true
	assert_eq(seen.keys().size(), 3, "a Startup rolls 0, 0.5 or 1 with equal odds, and all three come up")
	for v: float in seen:
		assert_true(v == 0.0 or v == 0.5 or v == 1.0, "%.2f is one of the three" % v)
	_near(WorkOdds.severance_months(cfg, agency, 40, false, rng), 0.5, 0.0001, "an Agency pays half a month")
	_near(WorkOdds.severance_months(cfg, megacorp, 180, false, rng), 1.0, 0.0001, "a MegaCorp: 2 months a year, prorated: 180 days is 1")
	_near(WorkOdds.severance_months(cfg, megacorp, 720, false, rng), 4.0, 0.0001, "two years is 4 months")
	_near(WorkOdds.severance_months(cfg, megacorp, 0, false, rng), 0.0, 0.0001, "day one is nothing")


func test_raises_and_promotion_rules() -> void:  # 5.15 raises; 5.16 promotion per archetype
	_near(WorkOdds.raise_for(cfg, WorkOdds.EXCEEDS), 0.03, 0.0001, "Exceeds")
	_near(WorkOdds.raise_for(cfg, WorkOdds.MEETS), 0.01, 0.0001, "Meets")
	_near(WorkOdds.raise_for(cfg, WorkOdds.BELOW), 0.0, 0.0001, "Below")
	assert_true(WorkOdds.promotes(startup, WorkOdds.EXCEEDS, 1, 0), "a Startup promotes on Exceeds")
	assert_false(WorkOdds.promotes(startup, WorkOdds.MEETS, 0, 0), "...not on Meets")
	assert_true(WorkOdds.promotes(agency, WorkOdds.MEETS, 1, 0), "an Agency promotes on Meets or better")
	assert_false(WorkOdds.promotes(megacorp, WorkOdds.EXCEEDS, 1, 0), "a MegaCorp wants two Exceeds in a row")
	assert_true(WorkOdds.promotes(megacorp, WorkOdds.EXCEEDS, 2, 0), "...and promotes on the second")
	assert_false(WorkOdds.promotes(agency, WorkOdds.EXCEEDS, 5, WorkOdds.SENIOR), "the title caps at Senior (D-09)")


# ---------- the job hunt (5.20) ----------

func test_callback_formula() -> void:  # R-JOB-02: 0.35 x f_level x (1 - 0.15 n_short) x (1 + 0.1 n_refs)
	_near(WorkOdds.callback_p(cfg, 0, 0, 0, 0), 0.35, 0.0001, "at your level")
	_near(WorkOdds.callback_p(cfg, 1, 0, 0, 0), 0.175, 0.0001, "one level up: half")
	_near(WorkOdds.callback_p(cfg, 0, 1, 0, 0), 0.28, 0.0001, "below your level: x0.8")
	_near(WorkOdds.callback_p(cfg, 0, 0, 2, 0), 0.35 * 0.7, 0.0001, "two Short Tenure stacks")
	_near(WorkOdds.callback_p(cfg, 0, 0, 0, 2), 0.35 * 1.2, 0.0001, "two references")


func test_duel_inputs() -> void:  # R-JOB-03: Composure x (1 - Burnout/200); the meter x (1 + Skill/200) x (1 - Rust/200)
	_near(WorkOdds.duel_composure(cfg, 100.0, 40.0), 80.0, 0.0001, "Burnout 40 costs a fifth of Composure")
	_near(WorkOdds.duel_composure(cfg, 90.0, 0.0), 90.0, 0.0001, "no Burnout, the Self-Taught's 90")
	_near(WorkOdds.duel_zone_mult(cfg, 100.0, 0.0), 1.5, 0.0001, "Skill 100 widens the zone by half")
	_near(WorkOdds.duel_zone_mult(cfg, 0.0, 40.0), 0.8, 0.0001, "Rust 40 narrows it by a fifth")
	_near(WorkOdds.duel_zone_mult(cfg, 0.0, 0.0), 1.0, 0.0001, "a fresh start changes nothing")


func test_auto_resolve_chance() -> void:  # R-EVT-02: (Burnout - 70) / 30 from 75
	_near(WorkOdds.auto_resolve_p(cfg, 74.9), 0.0, 0.0001, "below 75")
	_near(WorkOdds.auto_resolve_p(cfg, 75.0), 5.0 / 30.0, 0.0001, "at 75")
	_near(WorkOdds.auto_resolve_p(cfg, 85.0), 0.5, 0.0001, "at 85")
	_near(WorkOdds.auto_resolve_p(cfg, 100.0), 1.0, 0.0001, "certain at 100")


func test_studio_conditions_count() -> void:  # 3.4: Senior, Remote, The Studio, Burnout <= 30, runway >= 6 months at Studio rent
	var all := WorkOdds.studio_count(cfg, 2, true, 2, 30.0, 22.0, 1.2)
	assert_eq(all, 5, "all five hold: Burnout 30 counts, 22 k$ / (2.4 + 1.2) is 6.1 months")
	assert_eq(WorkOdds.studio_count(cfg, 1, true, 2, 30.0, 22.0, 1.2), 4, "a Mid is not Senior")
	assert_eq(WorkOdds.studio_count(cfg, 2, false, 2, 30.0, 22.0, 1.2), 4, "an onsite job is not Remote")
	assert_eq(WorkOdds.studio_count(cfg, 2, true, 1, 30.0, 22.0, 1.2), 4, "a One-bed is not The Studio")
	assert_eq(WorkOdds.studio_count(cfg, 2, true, 2, 30.1, 22.0, 1.2), 4, "Burnout 30.1 is too high")
	assert_eq(WorkOdds.studio_count(cfg, 2, true, 2, 30.0, 21.5, 1.2), 4, "21.5 k$ is under 6 months at Studio rent")


# ---------- through Sim.step: the clock and the money ----------

func test_run_one_starts_as_the_spec_says() -> void:  # R-STAT-02 / DECISIONS A63
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	assert_eq(s.day, 0, "day 0 is the start")
	assert_true(s.employed, "run 1 starts employed (D-02)")
	assert_eq(s.job_archetype, "startup", "at the Startup")
	assert_eq(s.job_company, "co_synergai", "Hierarchai")
	assert_false(s.job_remote, "onsite (A72)")
	assert_eq([s.skill, s.mo, s.burnout, s.rust], [0.0, 0.0, 0.0, 0.0], "Skill, MO, Burnout and Rust start at 0")
	assert_eq(s.coworkers.size(), 4, "Hierarchai's four authored coworkers")
	for cw: Dictionary in s.coworkers:
		assert_eq(float(cw["rapport"]), 50.0, "%s starts at Rapport 50" % cw["id"])
	_near(s.savings, 2.1, 0.0001, "the Intern's starting savings: one month (D-30)")
	_near(s.job_salary, 2.55, 0.0001, "a Startup Junior")
	assert_eq([s.home, s.hours, s.level], [0, 3, 0], "Shared room, notch 3, Junior")
	assert_eq(s.next_review, 180, "the first review is day 180")


func test_rent_on_day_one_and_pay_on_day_25() -> void:  # R-ECO; D-30: the Intern's month of savings pays day 1's bills exactly
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	var events: Array = Sim.step(s, [], c)
	assert_eq(s.day, 1)
	_near(s.savings, 0.0, 0.0001, "rent 0.9 and living costs 1.2 are due on day 1 and use the whole month of savings")
	assert_eq(SimFixture.count(events, "rent"), 1)
	SimFixture.run_days(s, c, 23)
	assert_eq(s.day, 24)
	assert_eq(s.below_zero_days, 0, "exactly zero is not below zero")
	events = Sim.step(s, [], c)
	assert_eq(s.day, 25)
	assert_eq(SimFixture.count(events, "payday"), 1)
	_near(s.savings, 2.55, 0.0001, "day 25 pays a full month (run 1 starts with 5 days accrued)")


func test_a_thin_purse_is_below_zero_until_payday() -> void:  # R-ECO; the merge report's caution (MC-04) with the old half month
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.savings = 1.05
	Sim.step(s, [], c)
	_near(s.savings, 1.05 - 2.1, 0.0001, "day 1's bills overdraw a thin purse")
	SimFixture.run_days(s, c, 23)
	assert_eq(s.day, 24)
	assert_eq(s.below_zero_days, 24, "below zero for 24 days in a row")
	_near(s.savings, -1.05, 0.0001, "no salary yet")
	var events: Array = Sim.step(s, [], c)
	assert_eq(s.day, 25)
	assert_eq(SimFixture.count(events, "payday"), 1)
	_near(s.savings, -1.05 + 2.55, 0.0001, "day 25 pays a full month")
	assert_eq(s.below_zero_days, 0, "the count resets")


func test_living_costs_grow_every_180_days() -> void:  # R-ECO: +6% every 180 days
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	SimFixture.run_days(s, c, 179)
	_near(s.living_cost, 1.2, 0.0001, "unchanged on day 179")
	SimFixture.run_days(s, c, 1)
	_near(s.living_cost, 1.2 * 1.06, 0.0001, "+6% on day 180")


func test_a_mid_month_start_is_paid_for_the_days_worked() -> void:  # DECISIONS A63: pay accrues daily, each payday pays the days since the last
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 5)
	s.day = 40
	var posting := SimFixture.posting(c, "startup")
	Sim._start_job(s, c, posting, [], false)
	var events := SimFixture.run_days(s, c, 15)
	assert_eq(s.day, 55)
	var paid: Array = events.filter(func(e: Dictionary) -> bool: return e["kind"] == "payday")
	assert_eq(paid.size(), 1, "day 55 is the first payday")
	_near(float(paid[0]["amount"]), 2.55 * 15.0 / 30.0, 0.0001, "15 days worked is half a month")


func test_a_layoff_pays_the_accrued_pay_and_the_severance() -> void:  # DECISIONS A63
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 5)
	Sim._start_job(s, c, SimFixture.posting(c, "megacorp"), [], false)
	SimFixture.run_days(s, c, 10)
	var salary := s.job_salary
	var before := s.savings
	var accrued := s.pay_accrued
	Sim._end_job(s, c, "layoff", [], 2.0)
	_near(s.savings, before + accrued + 2.0 * salary, 0.0001, "accrued pay and 2 months of salary")
	assert_false(s.employed)
	assert_eq(s.unemployed_since, s.day)


func test_fired_and_quit_pay_no_severance() -> void:  # 5.15: fired or quit: none
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 5)
	Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
	SimFixture.run_days(s, c, 5)
	var before := s.savings + s.pay_accrued
	Sim._end_job(s, c, "fired", [], 0.0)
	_near(s.savings, before, 0.0001, "only the accrued pay")


# ---------- home tiers and leases (5.15, E04, E21) ----------

func test_moving_costs_a_month_of_the_new_rent_and_restarts_the_lease() -> void:  # DECISIONS A64
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	SimFixture.run_days(s, c, 10)
	var before := s.savings
	var events := Sim.step(s, [{"kind": Sim.IN_MOVE_HOME, "tier": 2}], c)
	assert_eq(SimFixture.count(events, "moved"), 1)
	assert_eq(s.home, 2)
	_near(s.rent, 2.4, 0.0001, "The Studio's list price")
	_near(s.savings, before - 2.4, 0.0001, "one month of the new rent")
	assert_eq(s.lease_day, 10, "the lease restarts on the move-in day")


func test_lease_renewal_adds_ten_percent_or_moves_down() -> void:  # D-28: no negotiation
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.home = 1
	s.rent = 1.5
	s.lease_day = 0
	Sim._action(s, c, "lease_accept", [])
	_near(s.rent, 1.65, 0.0001, "+10%")
	s.lease_day = 0
	Sim._action(s, c, "lease_move_down", [])
	assert_eq(s.home, 0)
	_near(s.rent, 0.9, 0.0001, "back to the Shared room's list price: no raise on a new lease")
	assert_eq(s.lease_day, s.day, "a new lease")


func test_the_lease_event_comes_due_after_360_days() -> void:  # R-ECO: the yearly lease; E04 has one button in the Shared room (A66)
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.employed = false
	s.job_archetype = ""
	s.queue.clear()
	s.chains.clear()
	s.day = 359
	Sim.step(s, [], c)
	assert_eq(s.pending().get("id", ""), "evt_e04_lease_renewal", "the lease card shows on day 360")
	assert_eq(s.pending()["choices"], ["accept"], "no tier below the Shared room: one button")


# ---------- tickets and the controls (5.16, 5.17) ----------

func test_a_late_ticket_costs_mo_and_an_on_time_one_earns_it() -> void:  # R-STAT-03: MO +5 on time, -5 late; Skill +2
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.ticket_progress = 99.9
	s.ticket_deadline = s.day + 5
	Sim.step(s, [], c)
	assert_eq(s.tickets_on_time, 1)
	assert_eq(s.on_time_since_review, 1)
	assert_true(s.mo > 4.0, "MO +5")
	_near(s.skill, 2.0, 0.0001, "Skill +2 per ticket")
	var mo_before := s.mo
	s.ticket_progress = 99.9
	s.ticket_deadline = s.day - 1
	Sim.step(s, [], c)
	assert_eq(s.tickets_on_time, 1, "the second one was late")
	assert_true(s.mo < mo_before - 4.0, "MO -5")


func test_deadlines_are_the_baseline_size_in_days() -> void:  # DECISIONS A65
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	for size: int in 3:
		Sim._new_ticket(s, c, 0, size)
		assert_eq(s.ticket_deadline - s.ticket_start, [10, 20, 35][size], "size %d" % size)
	c.cfg.ticket_deadline_mult = 1.5
	Sim._new_ticket(s, c, 0, 1)
	assert_eq(s.ticket_deadline - s.ticket_start, 30, "ticket_deadline_mult stretches it")


func test_a_junior_gets_all_three_sizes() -> void:  # DECISIONS A65: S, M and L equally often
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	var seen: Dictionary = {}
	for i: int in 90:
		Sim._new_ticket(s, c)
		seen[s.ticket_size] = int(seen.get(s.ticket_size, 0)) + 1
	assert_eq(seen.keys().size(), 3)
	for k: int in seen:
		assert_true(int(seen[k]) > 15, "size %d came up %d times of 90" % [k, seen[k]])


func test_a_mid_picks_the_next_ticket() -> void:  # R-CTL-02: Feature (M or L; MO +6, Codebase +3), Bugfix (S; Skill +3, Codebase -2), Pay-down (M; Codebase -15)
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.level = WorkOdds.MID
	s.ticket_progress = 99.9
	s.ticket_deadline = s.day + 9
	Sim.step(s, [], c)
	assert_eq(s.pending().get("kind", ""), "ticket_pick", "a Mid chooses when a ticket ships")
	var cb := s.codebase
	var events := Sim.step(s, [{"kind": Sim.IN_TICKET_PICK, "pick": "paydown"}], c)
	assert_eq(s.ticket_kind, Sim.KIND_PAYDOWN)
	assert_eq(s.ticket_size, 1, "Pay-down is an M")
	s.ticket_progress = 99.9
	s.ticket_deadline = s.day + 9
	Sim.step(s, [], c)
	assert_true(s.codebase < cb - 14.0, "Pay-down: Codebase -15 when it ships")
	assert_eq(SimFixture.count(events, "input_rejected"), 0)


func test_push_back_extends_the_deadline_once_per_review_cycle() -> void:  # R-CTL-02: +30% for MO -3
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.level = WorkOdds.MID
	s.ticket_progress = 50.0
	Sim._new_ticket(s, c, 0, 1)
	s.ticket_progress = 50.0
	var deadline := s.ticket_deadline
	var mo := s.mo
	Sim.step(s, [{"kind": Sim.IN_PUSH_BACK}], c)
	assert_eq(s.ticket_deadline, deadline + 6, "20 days x 0.30")
	assert_true(s.mo < mo - 2.9, "MO -3")
	var events := Sim.step(s, [{"kind": Sim.IN_PUSH_BACK}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 1, "a second one in the same cycle is refused")


func test_a_junior_cannot_push_back_or_set_a_quality_bar() -> void:  # D-14: a Junior has exactly one control
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	var events := Sim.step(s, [{"kind": Sim.IN_PUSH_BACK}, {"kind": Sim.IN_SET_QUALITY, "bar": "fast"}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 2)
	assert_eq(s.quality, 1)


func test_a_senior_sets_the_quality_bar() -> void:  # R-CTL-03
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.level = WorkOdds.SENIOR
	Sim.step(s, [{"kind": Sim.IN_SET_QUALITY, "bar": "fast"}], c)
	assert_eq(s.quality, WorkOdds.QUALITY_FAST)


# ---------- Hours (R-CTL-01) ----------

func test_each_hours_notch_moves_the_ticket_burnout_and_mo() -> void:  # 5.17's table, through the sim
	var c := SimFixture.ctx(true)
	var speeds: Array[float] = [0.6, 0.8, 1.0, 1.25, 1.5]
	var burnout: Array[float] = [-0.6, -0.3, 0.1, 0.5, 1.0]
	for notch: int in range(1, 6):
		var s := SimFixture.fresh(c)
		s.savings = 100.0
		s.burnout = 50.0
		s.codebase = 0.0
		Sim.step(s, [{"kind": Sim.IN_SET_HOURS, "notch": notch}], c)
		assert_eq(s.hours, notch)
		_near(s.ticket_progress, 100.0 / [10, 20, 35][s.ticket_size] * speeds[notch - 1], 0.0001, "ticket speed at notch %d" % notch)
		_near(s.burnout, 50.0 + burnout[notch - 1], 0.0001, "Burnout at notch %d" % notch)


func test_the_hours_slider_is_a_clamped_input() -> void:
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	Sim.step(s, [{"kind": Sim.IN_SET_HOURS, "notch": 9}], c)
	assert_eq(s.hours, 5, "clamped to notch 5")
	Sim.step(s, [{"kind": Sim.IN_SET_HOURS, "notch": -2}], c)
	assert_eq(s.hours, 1)


func test_burnout_never_drops_below_the_burnout_history_floor() -> void:  # 5.21: +15 per stack
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.scar_burnout_history = 2
	s.burnout = 31.0
	s.savings = 100.0
	Sim.step(s, [{"kind": Sim.IN_SET_HOURS, "notch": 1}], c)
	Sim.step(s, [], c)
	assert_true(s.burnout >= 30.0 - 0.0001, "two stacks hold Burnout at 30 or more (31 - 0.6 - 0.6 stays above the floor of 30)")
	s.burnout = 30.2
	Sim.step(s, [], c)
	_near(s.burnout, 30.0, 0.0001, "clamped at the floor")


# ---------- the job hunt through the sim (5.20) ----------

func test_study_costs_burnout_and_raises_skill() -> void:  # R-JOB-05: Burnout +4, Rust -20, Skill +1
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.rust = 30.0
	var bo := s.burnout
	Sim.step(s, [{"kind": Sim.IN_STUDY}], c)
	_near(s.skill, 1.0, 0.0001, "Skill +1")
	_near(s.rust, 30.0 - 20.0 + 0.1, 0.0001, "Rust -20 (and +0.1 for the day)")
	assert_true(s.burnout > bo + 3.0, "Burnout +4 (less the day's own change)")
	var events := Sim.step(s, [{"kind": Sim.IN_STUDY}, {"kind": Sim.IN_STUDY}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 1, "only one Study a day (DECISIONS A73)")


func test_three_studies_while_unemployed_prevent_the_resume_gap() -> void:  # R-SCAR-01
	var c := SimFixture.ctx(true)
	for studies: int in [2, 3]:
		var s := Sim.new_run(c, 2, 9)
		s.savings = 500.0
		for i: int in studies:
			Sim.step(s, [{"kind": Sim.IN_STUDY}], c)
		SimFixture.run_days(s, c, 70)
		assert_eq(s.scar_resume_gap, 1 if studies < 3 else 0, "%d studies" % studies)


func test_applying_costs_burnout_and_a_reply_takes_3_to_10_days() -> void:  # R-JOB-01
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = 500.0
	assert_eq(s.board.size(), 4, "the board holds 4 postings")
	var posting: Dictionary = s.board[0]
	var bo := s.burnout
	var events := Sim.step(s, [{"kind": Sim.IN_APPLY, "posting": posting["id"]}], c)
	assert_eq(SimFixture.count(events, "application_sent"), 1)
	assert_eq(s.applications.size(), 1)
	var app: Dictionary = s.applications[0]
	assert_true(int(app["reply"]) - int(app["applied"]) >= 3 and int(app["reply"]) - int(app["applied"]) <= 10, "reply in 3-10 days")
	assert_eq(s.board.size(), 4, "the applied posting is replaced, so the board stays full")
	assert_true(s.burnout > bo + 1.0, "Burnout +2 while unemployed")


func test_you_cannot_apply_during_job_five() -> void:  # DECISIONS A72: no next floor
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	s.jobs_held = 5
	var events := Sim.step(s, [{"kind": Sim.IN_APPLY, "posting": (s.board[0] as Dictionary)["id"]}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 1)
	assert_eq(s.applications.size(), 0)


func test_an_interview_resets_rust_and_a_megacorp_takes_two_duels() -> void:  # R-JOB-03, A72
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = 500.0
	s.rust = 25.0
	var posting := SimFixture.posting(c, "megacorp", 0, 2, false, 77)
	s.applications.append({"posting": posting, "applied": 0, "reply": 0, "callback": true, "interview": 1, "status": "callback", "duels_done": 0, "next_duel": -1})
	Sim.step(s, [], c)
	var item := s.pending()
	assert_eq(item.get("kind", ""), "duel", "the interview day pauses the clock")
	assert_eq(item["of"], 2, "a MegaCorp posting takes two duels")
	var req: Dictionary = item["request"]
	assert_eq(req["tier"], "big")
	assert_eq(req["floor"], 2)
	_near(float(req["doubt_hp"]), 132.0 * 1.08, 0.001, "Doubt HP is raised by the floor")
	var day_of_duel := s.day
	Sim.step(s, [{"kind": Sim.IN_DUEL_RESULT, "passed": true, "composure_left": 60.0}], c)
	_near(s.rust, 0.1, 0.0001, "Rust is 0 after an interview, plus the day that then ticks")
	assert_eq(s.applications[0]["status"], "between", "the second duel comes 3-7 days later")
	assert_false(s.is_waiting(), "no offer yet")
	var next_day: int = s.applications[0]["next_duel"]
	assert_true(next_day - day_of_duel >= 3 and next_day - day_of_duel <= 7, "3-7 days after the first duel: day %d, next %d" % [day_of_duel, next_day])
	for i: int in 8:
		if s.is_waiting():
			break
		Sim.step(s, [], c)
	var again := s.pending()
	assert_eq(again.get("kind", ""), "duel", "the second duel starts 3-7 days after the first")
	assert_eq(int(again["index"]), 1, "it is the second one")
	_near(float((again["request"] as Dictionary)["composure"]), WorkOdds.duel_composure(c.cfg, 100.0, s.burnout), 0.0001, "at full Composure for your Burnout: nothing carries over from the first duel")
	Sim.step(s, [{"kind": Sim.IN_DUEL_RESULT, "passed": true, "composure_left": 60.0}], c)
	assert_eq(s.pending().get("kind", ""), "offer", "both won: an offer")


func test_accepting_an_offer_starts_the_job_and_declining_blacklists() -> void:  # D-27, MC-19
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.savings = 500.0
	var posting := SimFixture.posting(c, "agency", 0, 1, false, 51)
	s.queue.append({"kind": "offer", "app": 51, "posting": posting})
	Sim.step(s, [{"kind": Sim.IN_ANSWER_OFFER, "accept": true}], c)
	assert_true(s.employed)
	assert_eq(s.job_archetype, "agency")
	assert_eq(s.jobs_held, 1)
	s.queue.append({"kind": "offer", "app": 52, "posting": SimFixture.posting(c, "startup", 0, 2, false, 52)})
	s.employed = false
	Sim.step(s, [{"kind": Sim.IN_ANSWER_OFFER, "accept": false}], c)
	assert_true(s.blacklist.has("co_test"), "a declined offer's company is blacklisted for the run")


func test_leaving_a_job_early_earns_a_short_tenure_scar_but_a_layoff_does_not() -> void:  # R-SCAR-01
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	Sim._start_job(s, c, SimFixture.posting(c, "startup"), [], false)
	SimFixture.run_days(s, c, 100)
	Sim._end_job(s, c, "layoff", [], 0.0)
	assert_eq(s.scar_short_tenure, 0, "a layoff is not your fault")
	Sim._start_job(s, c, SimFixture.posting(c, "startup", 0, 2), [], false)
	SimFixture.run_days(s, c, 100)
	Sim._end_job(s, c, "quit", [], 0.0)
	assert_eq(s.scar_short_tenure, 1, "quitting before day 180")


func test_leaving_an_agency_drops_a_level_and_hiring_one_up_promotes_you() -> void:  # R-CTL-04
	var c := SimFixture.ctx(true)
	var s := Sim.new_run(c, 2, 4)
	s.level = WorkOdds.MID
	Sim._start_job(s, c, SimFixture.posting(c, "agency", WorkOdds.MID), [], false)
	Sim._end_job(s, c, "quit", [], 0.0)
	assert_eq(s.level, WorkOdds.JUNIOR, "title inflation: leaving an Agency costs a level")
	Sim._start_job(s, c, SimFixture.posting(c, "megacorp", WorkOdds.MID, 2), [], false)
	assert_eq(s.level, WorkOdds.MID, "hired a level up: promoted on hire")
	Sim._end_job(s, c, "quit", [], 0.0)
	assert_eq(s.level, WorkOdds.MID, "a MegaCorp keeps your level")
	s.level = WorkOdds.JUNIOR
	Sim._start_job(s, c, SimFixture.posting(c, "agency"), [], false)
	Sim._end_job(s, c, "quit", [], 0.0)
	assert_eq(s.level, WorkOdds.JUNIOR, "never below Junior")


func test_inputs_that_make_no_sense_are_refused_not_fatal() -> void:
	var c := SimFixture.ctx(true)
	var s := SimFixture.fresh(c)
	var events := Sim.step(s, [{"kind": "dance"}, {"kind": Sim.IN_CHOOSE, "choice": "x"}, {"kind": Sim.IN_ANSWER_OFFER, "accept": true},
		{"kind": Sim.IN_MOVE_HOME, "tier": 0}, {"kind": Sim.IN_APPLY, "posting": -5}], c)
	assert_eq(SimFixture.count(events, "input_rejected"), 5)
	assert_eq(s.stats.get("rejected", 0), 5)

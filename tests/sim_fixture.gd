@tool
class_name SimFixture
extends RefCounted
## Shared helpers for the test_sim_* suites (not a suite itself: the runner only loads tests/test_*.gd). Builds a
## SimContext that uses the Run Spec numbers (WorkConfig.new() and the three archetypes built by hand), so a tuned
## .tres never breaks a worked example (the same idea as test_odds building BalanceConfig.new()); the integration
## suites that want the shipped data call SimContext.load_default() themselves.


## The Run Spec's numbers, the shipped events and coworkers. quiet = no incidents and no random events, so a test
## can step many days without a card interrupting it.
static func ctx(quiet: bool = false, bg_id: String = "intern") -> SimContext:
	var c := SimContext.load_default(bg_id)
	c.cfg = WorkConfig.new()
	c.archetypes = {"startup": startup(), "agency": agency(), "megacorp": megacorp()}
	c.build()
	if quiet:
		c.cfg.incident_base = 0.0
		c.cfg.incident_per_codebase = 0.0
		c.random_events.clear()
		c.chain_events.clear()
	return c


static func startup() -> ArchetypeData:
	var a := ArchetypeData.new()
	a.id = &"startup"
	a.duel_tier = &"startup"
	a.remote_share = 0.60
	a.company_ids = PackedStringArray(["co_synergai", "co_quantumleaf"])
	a.pay_mult = 0.85
	a.severance_options = PackedFloat64Array([0.0, 0.5, 1.0])
	a.leave_level_drop = 0
	a.codebase_start = 20.0
	a.codebase_drift = 0.08
	a.utilization_mo = 0.0
	a.floor_size = 8
	a.review_cadence_days = 180
	a.calibration_hp = 60.0
	a.promotion_min_rating = 2
	a.layoff_share = 0.20
	a.layoff_interval_days = 270
	a.rto_after_days = 360
	return a


static func agency() -> ArchetypeData:
	var a := ArchetypeData.new()
	a.id = &"agency"
	a.company_ids = PackedStringArray(["co_pixelpivot", "co_beigeware"])
	return a


static func megacorp() -> ArchetypeData:
	var a := ArchetypeData.new()
	a.id = &"megacorp"
	a.duel_tier = &"big"
	a.duels_per_offer = 2
	a.remote_share = 0.25
	a.company_ids = PackedStringArray(["co_omniglobal", "co_nimbus"])
	a.pay_mult = 1.25
	a.severance_options = PackedFloat64Array([0.0])
	a.severance_per_year = 2.0
	a.leave_level_drop = 0
	a.codebase_start = 40.0
	a.codebase_drift = 0.04
	a.ticket_speed = 0.67
	a.utilization_mo = 0.0
	a.floor_size = 24
	a.review_cadence_days = 180
	a.calibration_hp = 80.0
	a.promotion_min_rating = 2
	a.promotion_streak = 2
	a.layoff_share = 0.10
	a.layoff_interval_days = 360
	a.rto_after_days = 0
	return a


## A posting dictionary as Sim builds them, for tests that start a job by hand.
static func posting(c: SimContext, archetype: String, level: int = 0, floor_n: int = 1, remote: bool = false, id: int = 900) -> Dictionary:
	return {"id": id, "company": "co_test", "archetype": archetype, "level": level, "floor": floor_n,
		"salary": WorkOdds.offer_salary(c.cfg, c.archetype(archetype), level, floor_n, 0), "remote": remote, "clauses": [], "posted": 0}


## Answer whatever the clock waits on in the simplest way: an event's exhausted (else first) choice, a review at 55%
## of your Evidence (Meets), the Feature ticket, a duel passed, an offer declined, an acknowledgement.
static func answer(s: SimState) -> Array:
	var item := s.pending()
	match String(item.get("kind", "")):
		"event":
			var ids: Array = item["choices"]
			var ex := String(item.get("exhausted", ""))
			return [{"kind": Sim.IN_CHOOSE, "choice": ex if ids.has(ex) else ids[0]}]
		"review":
			return [{"kind": Sim.IN_REVIEW_RESULT, "evidence_left": float(item["evidence"]) * 0.55}]
		"ticket_pick":
			return [{"kind": Sim.IN_TICKET_PICK, "pick": "feature"}]
		"duel":
			return [{"kind": Sim.IN_DUEL_RESULT, "passed": true, "composure_left": 50.0}]
		"offer":
			return [{"kind": Sim.IN_ANSWER_OFFER, "accept": false}]
	return [{"kind": Sim.IN_ACK}]


## Advance n days, answering every card on the way. Returns every sim event (the "kind" of each is what tests count).
static func run_days(s: SimState, c: SimContext, n: int) -> Array:
	var all: Array = []
	var target := s.day + n
	var guard := 0
	while s.day < target and not s.ended and guard < n * 20 + 100:
		var inputs: Array = answer(s) if s.is_waiting() else []
		all.append_array(Sim.step(s, inputs, c))
		guard += 1
	return all


## How many events of this kind a list holds.
static func count(events: Array, kind: String) -> int:
	var n := 0
	for e: Dictionary in events:
		if e["kind"] == kind:
			n += 1
	return n


## A run 1 state with the clock paused on a quiet day: no cards waiting.
static func fresh(c: SimContext, run_number: int = 1, run_seed: int = 7) -> SimState:
	return Sim.new_run(c, run_number, run_seed)

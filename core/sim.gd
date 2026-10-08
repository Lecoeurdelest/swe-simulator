@tool
class_name Sim
extends RefCounted
## The career run's rules as one deterministic step function (GDD 5.14-5.22, ARCHITECTURE 19.2). Sim.step(state,
## inputs, ctx) applies the inputs, then advances one day unless something waits for an answer (an event card, a
## review, a duel, an offer: state.queue). Pure like Odds: no nodes, no autoloads, no wall clock, no global RNG; every
## roll is on ctx.rng, restored from the state at the start of a step and saved back at its end, and the rolls
## happen in one fixed order, so a seed plus the inputs replays a run exactly. Numbers come from WorkConfig,
## ArchetypeData and the event JSON, never from this file (INV-09, INV-15), and no archetype is ever named here.
##
## One tick, in order: the calendar and money (day, rent, pay, living costs); the daily formulas (ticket, MO,
## Codebase, Burnout, Rust); the job hunt (replies, interviews); the review and the lease; the telegraphed chains;
## the rolls (incident, random events, chain starts); then the checks (forced leave, the PIP, Scars, the endings).

const IN_SET_HOURS := "set_hours"
const IN_CHOOSE := "choose"
const IN_REVIEW_RESULT := "review_result"
const IN_TICKET_PICK := "ticket_pick"
const IN_DUEL_RESULT := "duel_result"
const IN_ANSWER_OFFER := "answer_offer"
const IN_APPLY := "apply"
const IN_STUDY := "study"
const IN_MOVE_HOME := "move_home"
const IN_PUSH_BACK := "push_back"
const IN_SET_QUALITY := "set_quality"
const IN_ACK := "ack"

const EVT_RESIZING := "evt_e07_resizing"
const EVT_INCIDENT := "evt_e12_incident_prod"
const EVT_LIFESTYLE := "evt_e21_lifestyle_offer"
const EVT_RECRUITER := "evt_e18_recruiter_dm"
const EVT_REVIEW := "evt_e02_review"

const PICK_NAMES: PackedStringArray = ["feature", "bugfix", "paydown"]
const QUALITY_NAMES: PackedStringArray = ["clean", "balanced", "fast"]
const KIND_ASSIGNED := 0
const KIND_FEATURE := 1
const KIND_BUGFIX := 2
const KIND_PAYDOWN := 3


# ---------- a new run ----------

## Run 1 starts employed at the authored job with a guaranteed layoff on day 240 (GDD 3.3, P-06); later runs start
## between jobs with the board open. ctx.bg is the run's background. handbook is the collected tip ids.
static func new_run(ctx: SimContext, run_number: int, run_seed: int, handbook: Array = []) -> SimState:
	var cfg := ctx.cfg
	var s := SimState.new()
	s.rng_seed = run_seed
	ctx.rng.seed = run_seed
	s.bg_id = String(ctx.bg.id)
	s.run_number = run_number
	s.handbook = handbook.duplicate()
	s.refresh_edges()
	s.home = cfg.start_home
	s.rent = cfg.home_rent_k[s.home]
	s.living_cost = cfg.living_cost_k
	s.savings = WorkOdds.start_savings(cfg, ctx.bg, s.h_emergency)
	s.hours = cfg.hours_default
	s.unemployed_since = 0
	var events: Array = []
	if run_number == 1:
		var arch := ctx.archetype(cfg.run1_archetype)
		var posting := {
			"id": 0, "company": cfg.run1_company, "archetype": cfg.run1_archetype, "level": WorkOdds.JUNIOR, "floor": 1,
			"salary": WorkOdds.offer_salary(cfg, arch, WorkOdds.JUNIOR, 1, 0), "remote": cfg.run1_remote, "clauses": [],
		}
		_start_job(s, ctx, posting, events, true)
		s.pay_accrued = s.job_salary / cfg.days_per_month * cfg.run1_pay_days_accrued
	else:
		_refresh_board(s, ctx)
	s.rng_state = ctx.rng.state
	return s


# ---------- the step ----------

## Apply the inputs, then advance one day unless something is waiting. Returns what happened, as dictionaries with
## a "kind" (for the UI, the harness and the run log).
static func step(state: SimState, inputs: Array, ctx: SimContext) -> Array:
	var events: Array = []
	if state.ended:
		return events
	ctx.rng.seed = state.rng_seed
	ctx.rng.state = state.rng_state
	for input: Dictionary in inputs:
		_apply_input(state, ctx, input, events)
	if state.queue.is_empty() and not state.ended:
		_tick(state, ctx, events)
	state.rng_state = ctx.rng.state
	return events


## Apply the inputs and do not tick: how the work state changes the Hours or answers a card while the clock is paused
## (the clock driver ticks with step(state, [], ctx)). The run log stores the day each input was sent on, and replay()
## batches the inputs of a day with the tick that follows them, so a run played this way replays to the same state (O8).
static func apply_inputs(state: SimState, inputs: Array, ctx: SimContext) -> Array:
	var events: Array = []
	if state.ended:
		return events
	ctx.rng.seed = state.rng_seed
	ctx.rng.state = state.rng_state
	for input: Dictionary in inputs:
		_apply_input(state, ctx, input, events)
	state.rng_state = ctx.rng.state
	return events


## Replays a run from its log: the same seed and inputs give the same run (O8). Only the accepted inputs matter
## (SimState.log entries with "k" == "in", each with the day it was sent on); the days between them tick on their own.
## The run is replayed to until_day, or to the last day the log mentions.
static func replay(ctx: SimContext, run_number: int, run_seed: int, handbook: Array, log: Array, until_day: int = -1) -> SimState:
	var s := new_run(ctx, run_number, run_seed, handbook)
	var entries: Array = []
	var last_day := 0
	for entry: Dictionary in log:
		last_day = maxi(last_day, int(entry["d"]))
		if entry.get("k", "") == "in":
			entries.append(entry)
	var end_day := until_day if until_day >= 0 else last_day
	var i := 0
	while i < entries.size() and not s.ended:
		var day := int(entries[i]["d"])
		var batch: Array = []
		while i < entries.size() and int(entries[i]["d"]) == day:
			batch.append(entries[i]["i"])
			i += 1
		while s.day < day and s.queue.is_empty() and not s.ended:
			step(s, [], ctx)
		step(s, batch, ctx)
	while s.day < end_day and s.queue.is_empty() and not s.ended:
		step(s, [], ctx)
	return s


# ---------- inputs ----------

static func _apply_input(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> void:
	var kind: String = input.get("kind", "")
	var ok := false
	match kind:
		IN_SET_HOURS:
			ok = _in_set_hours(s, ctx, input)
		IN_CHOOSE:
			ok = _in_choose(s, ctx, input, events)
		IN_REVIEW_RESULT:
			ok = _in_review_result(s, ctx, input, events)
		IN_TICKET_PICK:
			ok = _in_ticket_pick(s, ctx, input)
		IN_DUEL_RESULT:
			ok = _in_duel_result(s, ctx, input, events)
		IN_ANSWER_OFFER:
			ok = _in_answer_offer(s, ctx, input, events)
		IN_APPLY:
			ok = _in_apply(s, ctx, input, events)
		IN_STUDY:
			ok = _in_study(s, ctx, events)
		IN_MOVE_HOME:
			ok = _in_move_home(s, ctx, input, events)
		IN_PUSH_BACK:
			ok = _in_push_back(s, ctx)
		IN_SET_QUALITY:
			ok = _in_set_quality(s, ctx, input)
		IN_ACK:
			ok = _in_ack(s)
	if ok:
		_log(s, ctx, "in", {"i": input})
	else:
		s.bump("rejected")
		events.append({"kind": "input_rejected", "input": kind})


static func _in_set_hours(s: SimState, ctx: SimContext, input: Dictionary) -> bool:
	if s.day <= s.hours_lock_until:
		return false
	var notch := clampi(int(input.get("notch", s.hours)), 1, ctx.cfg.hours_speed.size())
	if notch != s.hours:
		s.bump("hours_changes")
	s.hours = notch
	return true


static func _in_choose(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "event":
		return false
	var choice_id := String(input.get("choice", ""))
	if not (item["choices"] as Array).has(choice_id):
		return false
	s.queue.pop_front()
	_resolve_choice(s, ctx, String(item["id"]), choice_id, events)
	return true


static func _in_review_result(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "review":
		return false
	s.queue.pop_front()
	_resolve_review(s, ctx, item, float(input.get("evidence_left", 0.0)), events)
	return true


static func _in_ticket_pick(s: SimState, ctx: SimContext, input: Dictionary) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "ticket_pick":
		return false
	var pick := PICK_NAMES.find(String(input.get("pick", "")))
	if pick < 0:
		return false
	s.queue.pop_front()
	match pick:
		0:
			_new_ticket(s, ctx, KIND_FEATURE, ctx.rng.randi_range(1, 2))
		1:
			_new_ticket(s, ctx, KIND_BUGFIX, 0)
		2:
			_new_ticket(s, ctx, KIND_PAYDOWN, 1)
	return true


static func _in_duel_result(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "duel":
		return false
	s.queue.pop_front()
	_resolve_duel(s, ctx, item, bool(input.get("passed", false)), events)
	return true


static func _in_answer_offer(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var item := s.pending()
	if String(item.get("kind", "")) != "offer":
		return false
	s.queue.pop_front()
	var app_id := int(item["app"])
	var posting: Dictionary = item["posting"]
	_drop_application(s, app_id)
	if bool(input.get("accept", false)):
		if s.employed:
			_end_job(s, ctx, "quit", events, 0.0)
		if not s.ended:
			_start_job(s, ctx, posting, events, false)
	else:
		s.blacklist.append(String(posting["company"]))
		s.bump("declined")
		events.append({"kind": "offer_declined", "company": posting["company"]})
	return true


static func _in_apply(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var cfg := ctx.cfg
	if s.employed and s.jobs_held >= cfg.max_jobs:
		return false
	var idx := -1
	for i: int in s.board.size():
		if int(s.board[i]["id"]) == int(input.get("posting", -1)):
			idx = i
			break
	if idx < 0:
		return false
	var posting: Dictionary = s.board[idx]
	var p := WorkOdds.callback_p(cfg, int(posting["level"]), s.level, s.scar_short_tenure, _references(s, cfg))
	var callback := ctx.rng.randf() < p
	var reply := s.day + ctx.rng.randi_range(cfg.reply_days_min, cfg.reply_days_max)
	var interview := -1
	if callback:
		interview = reply + ctx.rng.randi_range(cfg.interview_days_min, cfg.interview_days_max)
	s.applications.append({"posting": posting, "applied": s.day, "reply": reply, "callback": callback, "interview": interview,
		"status": "wait", "duels_done": 0, "next_duel": -1})
	if s.employed:
		_add_burnout(s, cfg, cfg.apply_burnout_employed)
		s.bump("applies_employed")
		if ctx.rng.randf() < cfg.notice_p:
			_add_mo(s, cfg, cfg.notice_mo)
			events.append({"kind": "profile_noticed"})
	else:
		_add_burnout(s, cfg, cfg.apply_burnout_unemployed)
	s.bump("applies")
	s.board[idx] = _gen_posting(s, ctx)
	events.append({"kind": "application_sent", "company": posting["company"]})
	return true


static func _in_study(s: SimState, ctx: SimContext, events: Array) -> bool:
	var cfg := ctx.cfg
	if s.last_study_day == s.day:
		return false
	s.last_study_day = s.day
	_add_burnout(s, cfg, cfg.study_burnout)
	s.rust = clampf(s.rust + cfg.study_rust, 0.0, cfg.stat_max)
	s.skill = clampf(s.skill + cfg.study_skill, 0.0, cfg.stat_max)
	if not s.employed:
		s.studies_this_spell += 1
	s.bump("studies")
	events.append({"kind": "studied"})
	return true


static func _in_move_home(s: SimState, ctx: SimContext, input: Dictionary, events: Array) -> bool:
	var tier := int(input.get("tier", s.home))
	if tier == s.home or tier < 0 or tier >= ctx.cfg.home_rent_k.size():
		return false
	_move_home(s, ctx, tier, events)
	return true


static func _in_push_back(s: SimState, ctx: SimContext) -> bool:
	var cfg := ctx.cfg
	if not s.employed or s.level < WorkOdds.MID or s.push_back_used or s.ticket_progress >= 100.0:
		return false
	s.push_back_used = true
	s.ticket_deadline += roundi(cfg.ticket_size_days[s.ticket_size] * cfg.push_back_deadline)
	_add_mo(s, cfg, cfg.push_back_mo)
	return true


static func _in_set_quality(s: SimState, ctx: SimContext, input: Dictionary) -> bool:
	var bar := QUALITY_NAMES.find(String(input.get("bar", "")))
	if not s.employed or s.level < WorkOdds.SENIOR or bar < 0:
		return false
	s.quality = bar
	return true


static func _in_ack(s: SimState) -> bool:
	var item := s.pending()
	var kind := String(item.get("kind", ""))
	if kind != "layoff_scene" and kind != "forced_leave" and kind != "info":
		return false
	s.queue.pop_front()
	return true


# ---------- one day ----------

static func _tick(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	s.day += 1
	var day := s.day
	var arch: ArchetypeData = ctx.archetype(s.job_archetype) if s.employed else null
	var on_leave := s.employed and day <= s.leave_end

	_money(s, cfg, on_leave, events)

	var runway := WorkOdds.runway_months(s.savings, s.rent, s.living_cost * s.living_mult)
	if s.employed and not on_leave:
		var notch := s.hours
		var speed := s.speed_mod if day <= s.speed_mod_until else 1.0
		s.ticket_progress += WorkOdds.ticket_rate(cfg, s.ticket_size, notch, s.skill, s.codebase, arch, s.level, s.quality, speed)
		s.mo = clampf(s.mo + WorkOdds.mo_delta(cfg, arch, notch), cfg.mo_min, cfg.mo_max)
		s.codebase = clampf(s.codebase + WorkOdds.codebase_drift(cfg, arch, s.level, s.quality), 0.0, cfg.stat_max)
		_add_burnout(s, cfg, WorkOdds.burnout_delta(cfg, notch, s.home, s.codebase, runway, s.commute_burnout, s.h_overtime))
		if s.ticket_progress >= 100.0:
			_ship_ticket(s, ctx, events)
	else:
		_add_burnout(s, cfg, WorkOdds.idle_burnout_delta(cfg, s.hours, s.home, runway))
	s.rust = minf(cfg.stat_max, s.rust + cfg.rust_per_day)

	_hunt(s, ctx, events)
	if s.employed and not on_leave:
		if day >= s.next_review and s.next_review >= 0:
			_queue_review(s, ctx, arch, events)
		if day - s.lease_day >= cfg.lease_days:
			_present_event(s, ctx, "evt_e04_lease_renewal", events)
	elif not s.employed and day - s.lease_day >= cfg.lease_days:
		_present_event(s, ctx, "evt_e04_lease_renewal", events)
	if not s.chains.is_empty():
		_run_chains(s, ctx, events)
	_rolls(s, ctx, on_leave, events)
	_checks(s, ctx, on_leave, events)


static func _money(s: SimState, cfg: WorkConfig, on_leave: bool, events: Array) -> void:
	var day := s.day
	if day % cfg.living_cost_growth_days == 0:
		s.living_cost *= 1.0 + cfg.living_cost_growth
	if (day - cfg.rent_day) % cfg.days_per_month == 0:
		var bills := s.rent + s.living_cost * s.living_mult
		s.savings -= bills
		events.append({"kind": "rent", "amount": bills})
	if s.employed:
		s.pay_accrued += s.job_salary / cfg.days_per_month * (cfg.forced_leave_pay if on_leave else 1.0)
	if (day - cfg.payday) % cfg.days_per_month == 0 and s.pay_accrued > 0.0:
		s.savings += s.pay_accrued
		events.append({"kind": "payday", "amount": s.pay_accrued})
		s.pay_accrued = 0.0
	if s.savings < 0.0:
		s.below_zero_days += 1
	else:
		s.below_zero_days = 0


# ---------- tickets ----------

static func _new_ticket(s: SimState, ctx: SimContext, kind: int = KIND_ASSIGNED, size: int = -1) -> void:
	var cfg := ctx.cfg
	if size < 0:
		size = ctx.rng.randi_range(0, cfg.ticket_size_days.size() - 1)
	s.ticket_kind = kind
	s.ticket_size = size
	s.ticket_progress = 0.0
	s.ticket_start = s.day
	s.ticket_deadline = s.day + roundi(cfg.ticket_size_days[size] * cfg.ticket_deadline_mult)


static func _ship_ticket(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	var on_time := s.day <= s.ticket_deadline
	s.tickets_shipped += 1
	if on_time:
		s.tickets_on_time += 1
		s.on_time_since_review += 1
		_add_mo(s, cfg, cfg.mo_on_time)
	else:
		_add_mo(s, cfg, cfg.mo_late)
	s.skill = minf(cfg.stat_max, s.skill + cfg.skill_per_ticket)
	match s.ticket_kind:
		KIND_FEATURE:
			_add_mo(s, cfg, cfg.pick_feature_mo)
			s.codebase = clampf(s.codebase + cfg.pick_feature_codebase, 0.0, cfg.stat_max)
		KIND_BUGFIX:
			s.skill = clampf(s.skill + cfg.pick_bugfix_skill, 0.0, cfg.stat_max)
			s.codebase = clampf(s.codebase + cfg.pick_bugfix_codebase, 0.0, cfg.stat_max)
		KIND_PAYDOWN:
			_add_mo(s, cfg, cfg.pick_paydown_mo)
			s.codebase = clampf(s.codebase + cfg.pick_paydown_codebase, 0.0, cfg.stat_max)
	events.append({"kind": "ticket_shipped", "on_time": on_time, "size": s.ticket_size})
	if s.level >= WorkOdds.MID:
		s.ticket_progress = 0.0
		s.queue.append({"kind": "ticket_pick"})
	else:
		_new_ticket(s, ctx)


# ---------- stats ----------

static func _burnout_floor(s: SimState, cfg: WorkConfig) -> float:
	return cfg.burnout_history_floor * s.scar_burnout_history


static func _add_burnout(s: SimState, cfg: WorkConfig, delta: float) -> void:
	s.burnout = clampf(s.burnout + delta, _burnout_floor(s, cfg), cfg.burnout_max)


static func _add_mo(s: SimState, cfg: WorkConfig, delta: float) -> void:
	s.mo = clampf(s.mo + delta, cfg.mo_min, cfg.mo_max)


# ---------- events ----------

## Show an event: a card that waits for a choice, or a choice the Burnout makes for you (GDD 5.19). An event with
## no choices only happens (its effects are none today).
static func _present_event(s: SimState, ctx: SimContext, evt_id: String, events: Array) -> void:
	var evt: Dictionary = ctx.events.get(evt_id, {})
	if evt.is_empty():
		return
	s.event_last[evt_id] = s.day
	s.bump("events")
	var choices := EventPlan.available_choices(ctx, s, evt)
	if choices.is_empty():
		events.append({"kind": "event", "id": evt_id, "choices": []})
		return
	var ids: Array = []
	for choice: Dictionary in choices:
		ids.append(choice["id"])
	var exhausted: String = evt.get("exhausted_choice", "")
	if not exhausted.is_empty() and s.burnout >= ctx.cfg.auto_resolve_from:
		if ctx.rng.randf() < WorkOdds.auto_resolve_p(ctx.cfg, s.burnout):
			s.bump("auto_resolved")
			var pick := exhausted if ids.has(exhausted) else "none"
			events.append({"kind": "auto_resolved", "id": evt_id, "choice": pick})
			if pick != "none":
				_resolve_choice(s, ctx, evt_id, pick, events)
			return
	s.queue.append({"kind": "event", "id": evt_id, "choices": ids, "exhausted": exhausted})
	events.append({"kind": "event", "id": evt_id, "choices": ids})


static func _resolve_choice(s: SimState, ctx: SimContext, evt_id: String, choice_id: String, events: Array) -> void:
	var evt: Dictionary = ctx.events[evt_id]
	for choice: Dictionary in evt.get("choices", []):
		if choice["id"] == choice_id:
			_apply_effects(s, ctx, choice.get("effects", {}), events)
	var tip := String((evt.get("ducky", {}) as Dictionary).get("tip", "none"))
	if tip != "none" and not s.tips_seen.has(tip):
		s.tips_seen.append(tip)
		events.append({"kind": "tip", "id": tip, "event": evt_id})
	events.append({"kind": "event_resolved", "id": evt_id, "choice": choice_id})
	_log(s, ctx, "event", {"id": evt_id, "choice": choice_id})


## An event's effects, in one fixed order. Numbers come from the JSON; named actions are the few rules that are
## more than a number.
static func _apply_effects(s: SimState, ctx: SimContext, eff: Dictionary, events: Array) -> void:
	var cfg := ctx.cfg
	if eff.has("mo"):
		_add_mo(s, cfg, float(eff["mo"]))
	if eff.has("burnout"):
		_add_burnout(s, cfg, float(eff["burnout"]))
	if eff.has("codebase"):
		s.codebase = clampf(s.codebase + float(eff["codebase"]), 0.0, cfg.stat_max)
	if eff.has("skill"):
		s.skill = clampf(s.skill + float(eff["skill"]), 0.0, cfg.stat_max)
	if eff.has("rust"):
		s.rust = clampf(s.rust + float(eff["rust"]), 0.0, cfg.stat_max)
	if eff.has("savings"):
		s.savings += float(eff["savings"])
	if eff.has("living_mult"):
		s.living_mult = float(eff["living_mult"])
	if eff.has("commute_burnout"):
		s.commute_burnout = float(eff["commute_burnout"])
	if eff.has("speed_mod"):
		var sm: Dictionary = eff["speed_mod"]
		s.speed_mod = float(sm["mult"])
		s.speed_mod_until = s.day + int(sm["days"])
	if eff.has("hours_lock"):
		var hl: Dictionary = eff["hours_lock"]
		s.hours = int(hl["notch"])
		s.hours_lock_until = s.day + int(hl["days"])
	if eff.has("flags"):
		for flag: String in eff["flags"]:
			if not s.job_flags.has(flag):
				s.job_flags.append(flag)
	if eff.has("work_mode"):
		s.job_remote = String(eff["work_mode"]) == "remote"
	if eff.has("action"):
		_action(s, ctx, String(eff["action"]), events)


static func _action(s: SimState, ctx: SimContext, action: String, events: Array) -> void:
	var cfg := ctx.cfg
	match action:
		"lease_accept":
			s.rent *= 1.0 + cfg.lease_raise
			s.lease_day = s.day
		"lease_move_down":
			if s.home > 0:
				_move_home(s, ctx, s.home - 1, events)
		"home_upgrade":
			if s.home < cfg.home_rent_k.size() - 1:
				_move_home(s, ctx, s.home + 1, events)
		"board_early":
			_refresh_board(s, ctx)
		"ask_priya":
			var best := 0.0
			for cw: Dictionary in s.coworkers:
				best = maxf(best, float(cw["rapport"]))
			if best >= cfg.reference_rapport:
				for ch: Dictionary in s.chains:
					if ch["event"] == EVT_RESIZING:
						s.layoff_known_day = int(ch["fire_day"])
		"quit_job":
			_end_job(s, ctx, "quit", events, 0.0)
		"recruiter_call":
			_recruiter_application(s, ctx, events)


static func _move_home(s: SimState, ctx: SimContext, tier: int, events: Array) -> void:
	var cfg := ctx.cfg
	var new_rent := cfg.home_rent_k[tier]
	s.savings -= new_rent * cfg.move_cost_months
	s.home = tier
	s.rent = new_rent
	s.lease_day = s.day
	s.bump("moves")
	events.append({"kind": "moved", "home": tier})


# ---------- the chains: telegraphed events (GDD 5.19) ----------

static func _run_chains(s: SimState, ctx: SimContext, events: Array) -> void:
	var i := 0
	while i < s.chains.size():
		var ch: Dictionary = s.chains[i]
		for st: Dictionary in ch["stages"]:
			if int(st["day"]) == s.day:
				events.append({"kind": "rumor", "event": ch["event"], "text": st["text"]})
				if bool(st.get("prep", false)):
					_present_event(s, ctx, String(ch["event"]), events)
		if s.day == int(ch["fire_day"]):
			s.chains.remove_at(i)
			_chain_fires(s, ctx, ch, events)
			continue
		i += 1


static func _chain_fires(s: SimState, ctx: SimContext, ch: Dictionary, events: Array) -> void:
	var evt: Dictionary = ctx.events[ch["event"]]
	if String((evt.get("trigger", {}) as Dictionary).get("kind", "")) == "resizing":
		_resize(s, ctx, ch, events)
	else:
		_present_event(s, ctx, String(ch["event"]), events)


## A resizing (E07): run 1's cuts you for certain; later ones cut a share of the floor, picked by salary and luck
## and never by Manager Opinion (R-EVT-03, O1).
static func _resize(s: SimState, ctx: SimContext, ch: Dictionary, events: Array) -> void:
	var cfg := ctx.cfg
	var arch := ctx.archetype(s.job_archetype)
	s.living_mult = 1.0
	s.layoff_known_day = -1
	var cut_you := bool(ch.get("scripted", false))
	if not cut_you:
		var salaries: Array = [s.job_salary]
		for cw: Dictionary in s.coworkers:
			salaries.append(float(cw["salary"]))
		var cuts := WorkOdds.layoff_cut_count(cfg, arch, salaries.size())
		var picked := WorkOdds.layoff_cuts(cfg, salaries, cuts, ctx.rng)
		cut_you = picked.has(0)
		if not cut_you:
			var gone: Array[int] = []
			for idx: int in picked:
				gone.append(idx - 1)
			gone.sort()
			gone.reverse()
			for g: int in gone:
				s.past_coworkers.append({"id": s.coworkers[g]["id"], "rapport": s.coworkers[g]["rapport"]})
				s.coworkers.remove_at(g)
			s.bump("resizings_survived")
			events.append({"kind": "resizing_survived", "cuts": cuts})
			_schedule_resizing(s, ctx, arch, false)
			return
	var first_job := s.run_number == 1 and s.jobs_held == 1
	var months := WorkOdds.severance_months(cfg, arch, s.day - s.job_start, first_job, ctx.rng)
	var severance := months * s.job_salary   # k$: the scene shows it, and _end_job clears the salary
	s.bump("layoffs")
	_end_job(s, ctx, "layoff", events, months)
	if not s.ended:
		s.queue.append({"kind": "layoff_scene", "severance_months": months, "severance": severance})


## Plan the next resizing chain of this job: run 1's authored five signs and the fixed day, or a rumor 10-30 days
## ahead of a day rolled around the archetype's interval (shortened by the floor's event frequency).
static func _schedule_resizing(s: SimState, ctx: SimContext, arch: ArchetypeData, scripted: bool) -> void:
	var cfg := ctx.cfg
	var evt: Dictionary = ctx.events.get(EVT_RESIZING, {})
	if evt.is_empty():
		return
	var tel: Dictionary = evt.get("telegraph", {})
	if scripted:
		var stages: Array = []
		var signs: Array = tel.get("run1_signs", [])
		for i: int in signs.size():
			stages.append({"day": int(signs[i]["day"]), "text": signs[i]["text"], "prep": i + 1 == int(tel.get("prep_after_sign", 0))})
		s.chains.append({"event": EVT_RESIZING, "fire_day": int(tel["run1_fire_day"]), "stages": stages, "scripted": true})
		return
	if arch.layoff_interval_days <= 0:
		return
	var interval := arch.layoff_interval_days / WorkOdds.floor_mult(cfg.floor_event_step, s.floor_n())
	var fire := s.day + maxi(cfg.rumor_lead_days_max + 1, roundi(interval) + ctx.rng.randi_range(-arch.layoff_jitter_days, arch.layoff_jitter_days))
	var lead := ctx.rng.randi_range(cfg.rumor_lead_days_min, cfg.rumor_lead_days_max)
	s.chains.append({"event": EVT_RESIZING, "fire_day": fire, "scripted": false,
		"stages": [{"day": fire - lead, "text": tel.get("rumor", ""), "prep": true}]})


# ---------- rolls ----------

static func _rolls(s: SimState, ctx: SimContext, on_leave: bool, events: Array) -> void:
	if not s.employed or on_leave:
		_roll_random(s, ctx, events)
		return
	var cfg := ctx.cfg
	var inc: Dictionary = ctx.events.get(EVT_INCIDENT, {})
	if not inc.is_empty():
		var cooldown := int((inc["trigger"] as Dictionary).get("cooldown_days", 0))
		if s.day - s.last_incident_day >= cooldown:
			var p := WorkOdds.incident_p(cfg, s.codebase, s.floor_n(), EventPlan.threat_mult(ctx, s, inc))
			if ctx.rng.randf() < p:
				s.last_incident_day = s.day
				s.bump("incidents")
				_present_event(s, ctx, EVT_INCIDENT, events)
	_roll_random(s, ctx, events)
	for e: Dictionary in ctx.chain_events:
		var id: String = e["id"]
		if _has_chain(s, id) or s.day - int(s.event_last.get(id, -9999)) < int(e["cooldown"]):
			continue
		var evt: Dictionary = ctx.events[id]
		if not EventPlan.eligible(ctx, s, evt):
			continue
		var p2 := WorkOdds.random_event_p(cfg, float(e["per_year"]), s.floor_n(), EventPlan.threat_mult(ctx, s, evt))
		if ctx.rng.randf() < p2:
			s.event_last[id] = s.day
			var lead := ctx.rng.randi_range(cfg.rumor_lead_days_min, cfg.rumor_lead_days_max)
			var tel: Dictionary = evt.get("telegraph", {})
			s.chains.append({"event": id, "fire_day": s.day + lead, "scripted": false,
				"stages": [{"day": s.day + 1, "text": tel.get("rumor", ""), "prep": false}]})


static func _roll_random(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	for e: Dictionary in ctx.random_events:
		var id: String = e["id"]
		if s.day - int(s.event_last.get(id, -9999)) < int(e["cooldown"]):
			continue
		var evt: Dictionary = ctx.events[id]
		if not EventPlan.eligible(ctx, s, evt):
			continue
		var p := WorkOdds.random_event_p(cfg, float(e["per_year"]), s.floor_n(), EventPlan.threat_mult(ctx, s, evt))
		if ctx.rng.randf() < p:
			_present_event(s, ctx, id, events)


static func _has_chain(s: SimState, evt_id: String) -> bool:
	for ch: Dictionary in s.chains:
		if ch["event"] == evt_id:
			return true
	return false


# ---------- the review (GDD 5.16) ----------

static func _queue_review(s: SimState, ctx: SimContext, arch: ArchetypeData, events: Array) -> void:
	var cfg := ctx.cfg
	s.next_review = s.day + arch.review_cadence_days
	var evidence := WorkOdds.evidence(cfg, s.mo, s.on_time_since_review, s.h_brag)
	s.queue.append({"kind": "review", "evidence": evidence, "calibration": arch.calibration_hp})
	s.event_last[EVT_REVIEW] = s.day
	s.bump("reviews")
	events.append({"kind": "review", "evidence": evidence, "calibration": arch.calibration_hp})


static func _resolve_review(s: SimState, ctx: SimContext, item: Dictionary, evidence_left: float, events: Array) -> void:
	if not s.employed:
		return
	var cfg := ctx.cfg
	var arch := ctx.archetype(s.job_archetype)
	var evidence: float = item["evidence"]
	var rating := WorkOdds.rating(cfg, evidence, clampf(evidence_left, 0.0, evidence))
	s.below_streak = s.below_streak + 1 if rating == WorkOdds.BELOW else 0
	s.rating_streak = s.rating_streak + 1 if rating >= arch.promotion_min_rating else 0
	var raise := WorkOdds.raise_for(cfg, rating)
	s.job_salary *= 1.0 + raise
	var promoted := WorkOdds.promotes(arch, rating, s.rating_streak, s.level)
	if promoted:
		s.level += 1
		s.job_salary = maxf(s.job_salary, WorkOdds.offer_salary(cfg, arch, s.level, s.floor_n(), 0))
		s.rating_streak = 0
		s.bump("promotions")
	s.on_time_since_review = 0
	s.push_back_used = false
	if s.below_streak >= 2 and s.pip_end < 0:
		s.pip_end = s.day + cfg.pip_days
		events.append({"kind": "pip_started", "ends": s.pip_end})
	s.bump("rating_%s" % WorkOdds.RATINGS[rating])
	events.append({"kind": "review_result", "rating": rating, "raise": raise, "promoted": promoted})
	_log(s, ctx, "review", {"rating": rating, "promoted": promoted})
	var tip := String(((ctx.events[EVT_REVIEW] as Dictionary).get("ducky", {}) as Dictionary).get("tip", "none"))
	if tip != "none" and not s.tips_seen.has(tip):
		s.tips_seen.append(tip)
		events.append({"kind": "tip", "id": tip, "event": EVT_REVIEW})
	if (raise > 0.0 or promoted) and s.home < cfg.home_rent_k.size() - 1:
		_present_event(s, ctx, EVT_LIFESTYLE, events)


# ---------- the job hunt (GDD 5.20) ----------

static func _hunt(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	if s.day - s.board_day >= cfg.board_refresh_days:
		_refresh_board(s, ctx)
	var i := 0
	while i < s.applications.size():
		var app: Dictionary = s.applications[i]
		var status: String = app["status"]
		if status == "wait" and s.day >= int(app["reply"]):
			if bool(app["callback"]):
				app["status"] = "callback"
				events.append({"kind": "callback", "company": app["posting"]["company"], "interview": app["interview"]})
			else:
				s.applications.remove_at(i)
				events.append({"kind": "rejected", "company": app["posting"]["company"]})
				continue
		elif status == "callback" and s.day >= int(app["interview"]):
			_start_duel(s, ctx, app, events)
		elif status == "between" and s.day >= int(app["next_duel"]):
			_start_duel(s, ctx, app, events)
		i += 1


static func _start_duel(s: SimState, ctx: SimContext, app: Dictionary, events: Array) -> void:
	var cfg := ctx.cfg
	var posting: Dictionary = app["posting"]
	var arch := ctx.archetype(String(posting["archetype"]))
	var tier: TierData = ctx.tiers.get(String(arch.duel_tier)) as TierData
	var request := {
		"composure": WorkOdds.duel_composure(cfg, ctx.bg.composure_max, s.burnout),
		"meter_mult": WorkOdds.duel_zone_mult(cfg, s.skill, s.rust),
		"doubt_hp": WorkOdds.duel_doubt(cfg, tier.doubt_hp, int(posting["floor"])),
		"floor": int(posting["floor"]), "archetype": String(arch.id), "tier": String(arch.duel_tier),
		"unlocked_options": [], "rounds": cfg.review_prompts + 2,
	}
	app["status"] = "duel"
	s.queue.append({"kind": "duel", "app": int(posting["id"]), "index": int(app["duels_done"]), "of": arch.duels_per_offer, "request": request})
	s.bump("interviews")
	events.append({"kind": "interview", "company": posting["company"]})


static func _resolve_duel(s: SimState, ctx: SimContext, item: Dictionary, passed: bool, events: Array) -> void:
	var cfg := ctx.cfg
	s.rust = 0.0
	var app := _find_app(s, int(item["app"]))
	if app.is_empty():
		return
	if not passed:
		_drop_application(s, int(item["app"]))
		s.bump("interviews_failed")
		events.append({"kind": "interview_failed", "company": app["posting"]["company"]})
		return
	var done := int(app["duels_done"]) + 1
	app["duels_done"] = done
	if done >= int(item["of"]):
		app["status"] = "offer"
		s.queue.append({"kind": "offer", "app": int(item["app"]), "posting": app["posting"]})
		s.bump("offers")
		events.append({"kind": "offer", "company": app["posting"]["company"]})
	else:
		app["status"] = "between"
		app["next_duel"] = s.day + ctx.rng.randi_range(cfg.interview_days_min, cfg.interview_days_max)


static func _find_app(s: SimState, app_id: int) -> Dictionary:
	for app: Dictionary in s.applications:
		if int(app["posting"]["id"]) == app_id:
			return app
	return {}


## The application for a posting id ({} when it is gone): the adapter reads the posting a duel or an offer is about.
static func find_application(s: SimState, app_id: int) -> Dictionary:
	return _find_app(s, app_id)


static func _drop_application(s: SimState, app_id: int) -> void:
	for i: int in s.applications.size():
		if int(s.applications[i]["posting"]["id"]) == app_id:
			s.applications.remove_at(i)
			return


## E18: a recruiter's posting skips the board and the callback and goes straight to an interview 3-7 days out.
static func _recruiter_application(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	if s.employed and s.jobs_held >= cfg.max_jobs:
		return
	var posting := _gen_posting(s, ctx)
	var interview := s.day + ctx.rng.randi_range(cfg.interview_days_min, cfg.interview_days_max)
	s.applications.append({"posting": posting, "applied": s.day, "reply": s.day, "callback": true, "interview": interview,
		"status": "callback", "duels_done": 0, "next_duel": -1})
	events.append({"kind": "recruiter_posting", "company": posting["company"], "interview": interview})


static func _references(s: SimState, cfg: WorkConfig) -> int:
	var n := 0
	for cw: Dictionary in s.coworkers:
		if float(cw["rapport"]) >= cfg.reference_rapport:
			n += 1
	for cw: Dictionary in s.past_coworkers:
		if float(cw["rapport"]) >= cfg.reference_rapport:
			n += 1
	return n


# ---------- the board ----------

static func _refresh_board(s: SimState, ctx: SimContext) -> void:
	var cfg := ctx.cfg
	s.board.clear()
	for i: int in cfg.board_size + (cfg.edge_take_call_postings if s.h_take_call else 0):
		s.board.append(_gen_posting(s, ctx))
	s.board_day = s.day


## One posting, with its rolls in a fixed order: archetype, level, remote, the three clauses, the company.
static func _gen_posting(s: SimState, ctx: SimContext) -> Dictionary:
	var cfg := ctx.cfg
	var total := 0.0
	for id: String in ctx.arch_ids:
		total += ctx.archetype(id).board_weight
	var r := ctx.rng.randf() * total
	var arch: ArchetypeData = ctx.archetype(ctx.arch_ids[ctx.arch_ids.size() - 1])
	for id: String in ctx.arch_ids:
		r -= ctx.archetype(id).board_weight
		if r < 0.0:
			arch = ctx.archetype(id)
			break
	var lr := ctx.rng.randf()
	var level := s.level
	if lr < cfg.posting_level_weights[0]:
		level = maxi(0, s.level - 1)
	elif lr >= 1.0 - cfg.posting_level_weights[2]:
		level = mini(WorkOdds.SENIOR, s.level + 1)
	var floor_n := mini(s.jobs_held + 1, cfg.max_jobs)
	var remote := ctx.rng.randf() < arch.remote_share
	var clauses: Array = []
	var in_writing := ctx.rng.randf() < cfg.clause_remote_in_writing_p
	var on_call := ctx.rng.randf() < cfg.clause_on_call_p
	var pto := ctx.rng.randf() < cfg.clause_unlimited_pto_p
	if remote and in_writing:
		clauses.append("remote_in_writing")
	if on_call:
		clauses.append("on_call")
	if pto:
		clauses.append("unlimited_pto")
	var company := ""
	var pool: PackedStringArray = arch.company_ids
	if not pool.is_empty():
		var start := ctx.rng.randi_range(0, pool.size() - 1)
		company = pool[start]
		for k: int in pool.size():
			var candidate := pool[(start + k) % pool.size()]
			if not s.blacklist.has(candidate):
				company = candidate
				break
	var id_n := s.next_posting_id
	s.next_posting_id += 1
	return {"id": id_n, "company": company, "archetype": String(arch.id), "level": level, "floor": floor_n,
		"salary": WorkOdds.offer_salary(cfg, arch, level, floor_n, s.scar_resume_gap), "remote": remote,
		"clauses": clauses, "posted": s.day}


# ---------- jobs (GDD 3.3) ----------

static func _start_job(s: SimState, ctx: SimContext, posting: Dictionary, events: Array, scripted: bool) -> void:
	var cfg := ctx.cfg
	var arch := ctx.archetype(String(posting["archetype"]))
	s.jobs_held += 1
	s.employed = true
	s.unemployed_since = -1
	s.studies_this_spell = 0
	s.gap_scar_given = false
	s.job_company = String(posting["company"])
	s.job_archetype = String(arch.id)
	s.job_salary = float(posting["salary"])
	s.job_start = s.day
	s.job_remote = bool(posting["remote"])
	s.job_clauses = (posting.get("clauses", []) as Array).duplicate()
	s.job_flags = []
	s.commute_burnout = 0.0
	s.living_mult = 1.0
	s.leave_end = -1
	s.layoff_known_day = -1
	if int(posting["level"]) > s.level:
		s.level = int(posting["level"])
		events.append({"kind": "promoted_on_hire", "level": s.level})
	s.mo = 0.0
	if s.scar_bad_reference > 0:
		if _references(s, cfg) > 0:
			events.append({"kind": "reference_cleared"})
		else:
			s.mo = cfg.bad_reference_mo * s.scar_bad_reference
		s.scar_bad_reference = 0
	s.codebase = clampf(arch.codebase_start + cfg.corner_cutter_codebase * s.scar_corner_cutter, 0.0, cfg.stat_max)
	s.quality = WorkOdds.QUALITY_BALANCED
	s.next_review = s.day + arch.review_cadence_days
	s.on_time_since_review = 0
	s.below_streak = 0
	s.rating_streak = 0
	s.pip_end = -1
	s.push_back_used = false
	s.speed_mod_until = -1
	s.hours_lock_until = -1
	s.applications.clear()
	s.coworkers = _make_coworkers(s, ctx, arch, scripted)
	s.chains = []
	_schedule_resizing(s, ctx, arch, scripted and s.run_number == 1)
	_new_ticket(s, ctx)
	_refresh_board(s, ctx)
	s.bump("jobs")
	events.append({"kind": "job_started", "company": s.job_company, "archetype": s.job_archetype, "floor": s.jobs_held, "level": s.level})
	_log(s, ctx, "job", {"company": s.job_company, "floor": s.jobs_held})


## The people you work with: run 1's authored four, or floor_size - 1 generated ones with a level and a salary.
static func _make_coworkers(s: SimState, ctx: SimContext, arch: ArchetypeData, scripted: bool) -> Array:
	var cfg := ctx.cfg
	var out: Array = []
	if scripted and s.run_number == 1:
		var ids: Array = ctx.coworker_defs.keys()
		ids.sort()
		for id: String in ids:
			var def: Dictionary = ctx.coworker_defs[id]
			var lvl := WorkOdds.LEVELS.find(String(def["level"]))
			out.append({"id": id, "name": def["name"], "level": lvl, "salary": WorkOdds.offer_salary(cfg, arch, lvl, s.floor_n(), 0),
				"rapport": cfg.coworker_rapport_start})
		return out
	for i: int in maxi(0, arch.floor_size - 1):
		var r := ctx.rng.randf()
		var lvl := cfg.coworker_level_weights.size() - 1
		var acc := 0.0
		for k: int in cfg.coworker_level_weights.size():
			acc += cfg.coworker_level_weights[k]
			if r < acc:
				lvl = k
				break
		var noise := 1.0 + cfg.coworker_salary_noise * (ctx.rng.randf() * 2.0 - 1.0)
		out.append({"id": "cw_gen_%d" % i, "level": lvl,
			"salary": WorkOdds.offer_salary(cfg, arch, lvl, s.floor_n(), 0) * noise, "rapport": cfg.coworker_rapport_start})
	return out


## The job ends: reason is "layoff", "fired" or "quit". Accrued pay and severance are paid out, the Scars are
## handed out, a title-inflating archetype takes a level, and losing job max_jobs ends the run (D-16).
static func _end_job(s: SimState, ctx: SimContext, reason: String, events: Array, severance_months: float) -> void:
	if not s.employed:
		return
	var cfg := ctx.cfg
	var arch := ctx.archetype(s.job_archetype)
	var tenure := s.day - s.job_start
	var company := s.job_company
	s.savings += s.pay_accrued + severance_months * s.job_salary
	s.pay_accrued = 0.0
	if reason != "layoff" and tenure < cfg.short_tenure_days:
		s.scar_short_tenure = mini(s.scar_short_tenure + 1, cfg.scar_max_stacks)
	if reason == "fired" or (reason == "quit" and s.mo < cfg.bad_reference_quit_mo):
		s.scar_bad_reference = mini(s.scar_bad_reference + 1, cfg.scar_max_stacks)
	if s.level >= WorkOdds.SENIOR and s.codebase >= cfg.corner_cutter_leave_codebase:
		s.scar_corner_cutter = mini(s.scar_corner_cutter + 1, cfg.scar_max_stacks)
	for cw: Dictionary in s.coworkers:
		if float(cw["rapport"]) >= cfg.reference_rapport:
			s.past_coworkers.append({"id": cw["id"], "rapport": cw["rapport"]})
	s.level = maxi(0, s.level - arch.leave_level_drop)
	s.employed = false
	s.unemployed_since = s.day
	s.studies_this_spell = 0
	s.gap_scar_given = false
	s.job_company = ""
	s.job_archetype = ""
	s.job_salary = 0.0
	s.job_clauses = []
	s.job_flags = []
	s.commute_burnout = 0.0
	s.coworkers = []
	s.chains = []
	s.pip_end = -1
	s.leave_end = -1
	s.living_mult = 1.0
	s.ticket_progress = 0.0
	s.speed_mod_until = -1
	s.hours_lock_until = -1
	_drop_job_cards(s)
	s.bump("exit_%s" % reason)
	events.append({"kind": "job_ended", "reason": reason, "tenure": tenure, "severance_months": severance_months, "company": company})
	_log(s, ctx, "exit", {"reason": reason, "tenure": tenure})
	if s.jobs_held >= cfg.max_jobs:
		_end_run(s, ctx, "career_change", events)


## A review or a ticket pick belongs to the job that just ended: its card goes with it.
static func _drop_job_cards(s: SimState) -> void:
	var i := 0
	while i < s.queue.size():
		var kind := String((s.queue[i] as Dictionary).get("kind", ""))
		if kind == "review" or kind == "ticket_pick":
			s.queue.remove_at(i)
		else:
			i += 1


static func _end_run(s: SimState, ctx: SimContext, ending: String, events: Array) -> void:
	if s.ended:
		return
	s.ended = true
	s.ending = ending
	s.queue.clear()
	events.append({"kind": "ending", "ending": ending})
	_log(s, ctx, "ending", {"ending": ending})


# ---------- the checks ----------

static func _checks(s: SimState, ctx: SimContext, on_leave: bool, events: Array) -> void:
	var cfg := ctx.cfg
	var day := s.day
	if s.employed:
		if s.burnout >= cfg.burnout_max and not on_leave:
			_forced_leave(s, ctx, events)
		if s.pip_end >= 0 and day >= s.pip_end:
			s.pip_end = -1
			s.below_streak = 0
			if s.mo < cfg.pip_mo_min:
				_end_job(s, ctx, "fired", events, 0.0)
			else:
				events.append({"kind": "pip_cleared"})
		if s.employed and s.scar_short_tenure > 0 and day - s.job_start >= cfg.short_tenure_clear_days:
			s.scar_short_tenure = 0
		if s.employed and s.scar_corner_cutter > 0 and s.codebase < cfg.corner_cutter_clear_codebase:
			s.scar_corner_cutter = 0
	elif s.unemployed_since >= 0 and not s.gap_scar_given and day - s.unemployed_since > cfg.resume_gap_days:
		s.gap_scar_given = true
		if s.studies_this_spell < cfg.studies_prevent_gap:
			s.scar_resume_gap = mini(s.scar_resume_gap + 1, cfg.scar_max_stacks)
			events.append({"kind": "scar", "id": "resume_gap"})
	if s.burnout <= cfg.burnout_history_calm:
		s.calm_days += 1
		if s.scar_burnout_history > 0 and s.calm_days >= cfg.burnout_history_clear_days:
			s.scar_burnout_history -= 1
			s.calm_days = 0
	else:
		s.calm_days = 0
	for i: int in cfg.burnout_warnings.size():
		var at: float = cfg.burnout_warnings[i]
		if s.warn_armed[i] and s.burnout >= at:
			s.warn_armed[i] = false
			events.append({"kind": "burnout_warning", "level": i})
		elif not s.warn_armed[i] and s.burnout < at - cfg.burnout_warning_rearm:
			s.warn_armed[i] = true
	var hold_ok := s.employed and WorkOdds.studio_count(cfg, s.level, s.job_remote, s.home, s.burnout, s.savings, s.living_cost * s.living_mult) == 5
	if hold_ok:
		s.studio_hold += 1
		if s.studio_hold >= cfg.studio_days:
			_end_run(s, ctx, "studio", events)
			return
	elif s.studio_hold > 0:
		s.studio_hold = 0
		events.append({"kind": "studio_broken"})
	if s.ended:
		return
	if s.below_zero_days >= cfg.plan_b_days:
		_end_run(s, ctx, "plan_b", events)
	elif day >= cfg.legacy_day:
		_end_run(s, ctx, "legacy", events)


## Burnout hit 100: an interrupt, not an exit (GDD 3.3). The first costs a Burnout History Scar and 30 days at half
## pay with the job kept; the second ends the run.
static func _forced_leave(s: SimState, ctx: SimContext, events: Array) -> void:
	var cfg := ctx.cfg
	s.forced_leaves += 1
	s.bump("forced_leaves")
	if s.forced_leaves >= 2:
		_end_run(s, ctx, "burnout", events)
		return
	s.scar_burnout_history = mini(s.scar_burnout_history + 1, cfg.scar_max_stacks)
	s.leave_end = s.day + cfg.forced_leave_days
	s.ticket_deadline += cfg.forced_leave_days
	s.burnout = maxf(cfg.forced_leave_burnout, _burnout_floor(s, cfg))
	s.queue.append({"kind": "forced_leave", "days": cfg.forced_leave_days})
	events.append({"kind": "forced_leave"})


# ---------- the run log (RC-26) ----------

static func _log(s: SimState, ctx: SimContext, kind: String, data: Dictionary) -> void:
	if not ctx.log_enabled:
		return
	var entry := {"d": s.day, "k": kind}
	entry.merge(data)
	s.log.append(entry)

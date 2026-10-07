@tool
class_name EventPlan
extends RefCounted
## Which events can happen (GDD 5.19): tier, archetype, level, the "requires" conditions of work_events.json, and
## the calendar strip. Pure like WorkOdds: it reads a SimState and the SimContext, and changes nothing. The odds
## of a roll are WorkOdds'; the rolling itself is Sim's, in a fixed order.


## True when the event's archetype and level lists include yours and its own conditions hold.
static func eligible(ctx: SimContext, state: SimState, evt: Dictionary) -> bool:
	if state.employed:
		if not (evt.get("archetypes", []) as Array).has(state.job_archetype):
			return false
	if not (evt.get("levels", []) as Array).has(WorkOdds.LEVELS[state.level]):
		return false
	return requires_met(ctx, state, evt.get("requires", {}))


## Conditions of an event or of one choice. An empty dictionary always holds.
static func requires_met(ctx: SimContext, state: SimState, req: Dictionary) -> bool:
	for key: String in req:
		var want: Variant = req[key]
		match key:
			"employed":
				if state.employed != bool(want):
					return false
			"remote":
				if (state.employed and state.job_remote) != bool(want):
					return false
			"rto":
				if not state.employed:
					return false
				var arch := ctx.archetype(state.job_archetype)
				if (arch.rto_after_days >= 0 and state.day - state.job_start >= arch.rto_after_days) != bool(want):
					return false
			"home_min":
				if state.home < int(want):
					return false
			"tip":
				if not state.has_tip(String(want)):
					return false
			"clause":
				if not state.job_clauses.has(String(want)):
					return false
			"not_flag":
				if state.job_flags.has(String(want)):
					return false
			"deadline_or_incident_days":
				var n := int(want)
				var near_deadline := state.employed and state.ticket_deadline - state.day <= n and state.ticket_deadline >= state.day
				var after_incident := state.day - state.last_incident_day <= n
				if not (near_deadline or after_incident):
					return false
	return true


## The choices of an event that you can pick now, as the choice dictionaries.
static func available_choices(ctx: SimContext, state: SimState, evt: Dictionary) -> Array:
	var out: Array = []
	for choice: Dictionary in evt.get("choices", []):
		if requires_met(ctx, state, choice.get("requires", {})):
			out.append(choice)
	return out


## The weight of a random event today: the final threats get final_threat_mult while the Studio hold is filming.
static func threat_mult(ctx: SimContext, state: SimState, evt: Dictionary) -> float:
	if state.studio_hold > 0 and bool(evt.get("final_threat", false)):
		return ctx.cfg.final_threat_mult
	return 1.0


## What the calendar strip shows for the next `days` days (GDD 5.14): paydays, rent, the review, the lease, a
## ticket's deadline, a chain's fire day and an interview, as [{day, kind}] sorted by day.
static func calendar(ctx: SimContext, state: SimState, days: int) -> Array:
	var cfg := ctx.cfg
	var out: Array = []
	for d: int in range(state.day + 1, state.day + days + 1):
		if (d - cfg.payday) % cfg.days_per_month == 0 and state.employed:
			out.append({"day": d, "kind": "payday"})
		if (d - cfg.rent_day) % cfg.days_per_month == 0:
			out.append({"day": d, "kind": "rent"})
	if state.employed and state.next_review > state.day and state.next_review <= state.day + days:
		out.append({"day": state.next_review, "kind": "review"})
	var lease_due: int = state.lease_day + cfg.lease_days
	if lease_due > state.day and lease_due <= state.day + days:
		out.append({"day": lease_due, "kind": "lease"})
	if state.employed and state.ticket_deadline > state.day and state.ticket_deadline <= state.day + days:
		out.append({"day": state.ticket_deadline, "kind": "deadline"})
	for app: Dictionary in state.applications:
		var iv := int(app.get("interview", -1))
		if bool(app.get("callback", false)) and iv > state.day and iv <= state.day + days:
			out.append({"day": iv, "kind": "interview"})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return out

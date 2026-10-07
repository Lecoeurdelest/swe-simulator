@tool
class_name BotRandom
extends BotBase
## The Random bot (GDD 5.22): random Hours, random event choices, random applications, random offers, random
## everything else. Target: under 1% wins. Every input it sends is one the sim accepts.


func plan(state: SimState, ctx: SimContext) -> Array:
	var out: Array = []
	if rng.randf() < 0.05:
		out.append_array(hours_input(state, rng.randi_range(1, work_cfg.hours_speed.size())))
	if rng.randf() < 0.04 and not state.board.is_empty() and not (state.employed and state.jobs_held >= work_cfg.max_jobs):
		out.append({"kind": Sim.IN_APPLY, "posting": int((state.board[rng.randi_range(0, state.board.size() - 1)] as Dictionary)["id"])})
	if rng.randf() < 0.01 and state.last_study_day != state.day:
		out.append({"kind": Sim.IN_STUDY})
	if rng.randf() < 0.005:
		var tier := rng.randi_range(0, work_cfg.home_rent_k.size() - 1)
		if tier != state.home:
			out.append({"kind": Sim.IN_MOVE_HOME, "tier": tier})
	if state.employed and state.level >= WorkOdds.SENIOR and rng.randf() < 0.01:
		out.append({"kind": Sim.IN_SET_QUALITY, "bar": Sim.QUALITY_NAMES[rng.randi_range(0, 2)]})
	if state.employed and state.level >= WorkOdds.MID and not state.push_back_used and rng.randf() < 0.01 and state.ticket_progress < 100.0:
		out.append({"kind": Sim.IN_PUSH_BACK})
	return out


func choose(_state: SimState, _ctx: SimContext, item: Dictionary) -> String:
	var ids: Array = item["choices"]
	return String(ids[rng.randi_range(0, ids.size() - 1)])


func pick_ticket(_state: SimState, _ctx: SimContext) -> String:
	return Sim.PICK_NAMES[rng.randi_range(0, 2)]


func accept_offer(_state: SimState, _ctx: SimContext, _posting: Dictionary) -> bool:
	return rng.randf() < 0.5

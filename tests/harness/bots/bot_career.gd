@tool
class_name BotCareer
extends BotBase
## The job-hunting competence the career bots share: apply to the posting with the best expected value, study to
## keep a Resume Gap off, and answer an offer by comparing it with what you have. A subclass changes the policies
## (the scoring, the ceilings, the Hours notch) and the event choices; the Coaster skips this layer and the Random
## bot ignores it.

var max_active_applications: int = 3
var apply_burnout_ceiling: float = 70.0
var stage_bonus_unemployed: float = 4.0


func plan(state: SimState, ctx: SimContext) -> Array:
	var out: Array = hours_input(state, hours_notch(state, ctx))
	out.append_array(hunt(state, ctx))
	return out


## The Hours notch for today (the subclass's policy).
func hours_notch(_state: SimState, _ctx: SimContext) -> int:
	return work_cfg.hours_default


## Voluntary hunting inputs: study to prevent a Resume Gap, and apply to the best posting while hunting.
func hunt(state: SimState, ctx: SimContext) -> Array:
	var out: Array = []
	if not state.employed and state.studies_this_spell < work_cfg.studies_prevent_gap and state.last_study_day != state.day:
		out.append({"kind": Sim.IN_STUDY})
	if not wants_to_hunt(state, ctx):
		return out
	if state.applications.size() >= max_active_applications or state.burnout > apply_burnout_ceiling:
		return out
	if state.employed and state.jobs_held >= work_cfg.max_jobs:
		return out
	var best := best_posting(state, ctx)
	if not best.is_empty():
		out.append({"kind": Sim.IN_APPLY, "posting": int(best["id"])})
	return out


## Whether to look for a job today: always when unemployed; employed bots decide in the subclass.
func wants_to_hunt(state: SimState, _ctx: SimContext) -> bool:
	return not state.employed


## The posting worth the most, as expected value: callback odds times how good the job is. {} if none is worth it.
func best_posting(state: SimState, ctx: SimContext) -> Dictionary:
	var best: Dictionary = {}
	var best_ev := 0.0
	for posting: Dictionary in state.board:
		var worth := posting_score(state, ctx, posting)
		if worth <= 0.0:
			continue
		var p := WorkOdds.callback_p(work_cfg, int(posting["level"]), state.level, state.scar_short_tenure, references(state))
		var ev := p * worth
		if ev > best_ev:
			best_ev = ev
			best = posting
	return best


## How good a posting is (the subclass's taste); the base counts pay and a step up in level.
func posting_score(state: SimState, _ctx: SimContext, posting: Dictionary) -> float:
	var worth := float(posting["salary"]) + 2.0 * (int(posting["level"]) - state.level)
	if not state.employed:
		worth += stage_bonus_unemployed
	return worth


func accept_offer(state: SimState, ctx: SimContext, posting: Dictionary) -> bool:
	if not state.employed:
		return true
	return posting_score(state, ctx, posting) > current_job_score(state, ctx) + 0.5


## What the job you hold is worth by the same taste as postings (so an offer compares like with like).
func current_job_score(state: SimState, ctx: SimContext) -> float:
	return posting_score(state, ctx, {"salary": state.job_salary, "level": state.level, "remote": state.job_remote,
		"archetype": state.job_archetype, "clauses": state.job_clauses})


func references(state: SimState) -> int:
	var n := 0
	for cw: Dictionary in state.coworkers:
		if float(cw["rapport"]) >= work_cfg.reference_rapport:
			n += 1
	for cw: Dictionary in state.past_coworkers:
		if float(cw["rapport"]) >= work_cfg.reference_rapport:
			n += 1
	return n

@tool
class_name BotPlanner
extends BotCareer
## The Planner (GDD 5.22): keeps Burnout between 30 and 60, saves six months, routes Agency then MegaCorp and chases
## remote. Target: wins 5-10% (R-BAL-01, D-15). It is the bot the balance is tuned against, so it plays the whole
## career with care: it won't quit before day 180 (a Short Tenure Scar), hunts when a resizing is coming, and only
## moves into The Studio when it keeps six months of runway there.

const AGENCY := "agency"
const HUNT_AFTER_DAYS := 150          # leave a job no sooner than this, so the next one starts after day 180
const RESIZING_WARNING_DAYS := 75
const FILMING_BURNOUT_CAP := 27.0     # keep clear of the Studio's 30 while the hold runs
const SAVINGS_MARGIN_MONTHS := 1.0    # extra runway over the Studio's 6 before moving in

var _studio_ready_soon: bool = false
var _archetypes: Dictionary = {}


func hours_notch(state: SimState, _ctx: SimContext) -> int:
	var b := state.burnout
	if state.studio_hold > 0 or _studio_ready_soon:
		if b > FILMING_BURNOUT_CAP:
			return 1
		return 2 if b > FILMING_BURNOUT_CAP - 6.0 else 3
	if b < 30.0:
		return 4
	if b < 45.0:
		return 3
	if b < 60.0:
		return 2
	return 1


func plan(state: SimState, ctx: SimContext) -> Array:
	_studio_ready_soon = state.employed and state.level >= WorkOdds.SENIOR and state.job_remote and state.home >= work_cfg.studio_home
	var out := super.plan(state, ctx)
	out.append_array(home_moves(state))
	out.append_array(controls(state))
	return out


func wants_to_hunt(state: SimState, _ctx: SimContext) -> bool:
	if not state.employed:
		return true
	if state.studio_hold > 0 or state.burnout > 62.0:
		return false
	if _resizing_soon(state):
		return true
	if state.day - state.job_start < HUNT_AFTER_DAYS:
		return false
	if state.level >= WorkOdds.SENIOR:
		return not state.job_remote
	return state.job_archetype != AGENCY


func posting_score(state: SimState, _ctx: SimContext, posting: Dictionary) -> float:
	var worth := float(posting["salary"]) + 2.0 * (int(posting["level"]) - state.level)
	var senior := state.level >= WorkOdds.SENIOR or int(posting["level"]) >= WorkOdds.SENIOR
	if bool(posting["remote"]):
		worth += 3.0 if senior else 0.5
	if state.level < WorkOdds.SENIOR and String(posting["archetype"]) == AGENCY:
		worth += 2.5
	if (posting["clauses"] as Array).has("on_call"):
		worth -= 0.5
	if not state.employed:
		worth += stage_bonus_unemployed
	return worth


func accept_offer(state: SimState, ctx: SimContext, posting: Dictionary) -> bool:
	if not state.employed:
		return true
	return posting_score(state, ctx, posting) > current_job_score(state, ctx) + 1.0


func choose(state: SimState, ctx: SimContext, item: Dictionary) -> String:
	var ids: Array = item["choices"]
	var bills := state.rent + state.living_cost * state.living_mult
	var runway := state.savings / bills
	match String(item["id"]):
		"evt_e12_incident_prod":
			return "escalate" if ids.has("escalate") else "fix_it"
		"evt_e24_overtime_ask":
			return "stay_late" if state.burnout < 35.0 and state.mo < 30.0 and state.studio_hold == 0 else "decline"
		"evt_e18_recruiter_dm":
			return "take_call"
		"evt_e20_laptop_dies":
			return "pay" if runway > 3.0 else "limp"
		"evt_e21_lifestyle_offer":
			return "stay"
		"evt_e04_lease_renewal":
			return "move_down" if ids.has("move_down") and runway < 2.5 else "accept"
		"evt_e08_rto_mandate":
			return "push_back" if ids.has("push_back") else "comply"
		"evt_e07_resizing":
			return "update_profile"
	return super.choose(state, ctx, item)


func pick_ticket(state: SimState, _ctx: SimContext) -> String:
	if state.codebase > 55.0:
		return "paydown"
	return "bugfix" if state.skill < 30.0 and state.codebase > 35.0 else "feature"


## The Studio move: only as a Senior in a remote job, with six months of runway at Studio rent to spare; and a
## one-bed once the pay comfortably covers it.
func home_moves(state: SimState) -> Array:
	if not state.employed:
		return []
	var out: Array = []
	var studio_bills := work_cfg.home_rent_k[work_cfg.studio_home] + state.living_cost
	var move_cost := work_cfg.home_rent_k[work_cfg.studio_home] * work_cfg.move_cost_months
	if state.level >= WorkOdds.SENIOR and state.job_remote and state.home < work_cfg.studio_home \
			and state.savings - move_cost >= studio_bills * (work_cfg.studio_runway_months + SAVINGS_MARGIN_MONTHS):
		out.append({"kind": Sim.IN_MOVE_HOME, "tier": work_cfg.studio_home})
	elif state.home == 0 and state.savings > (state.rent + state.living_cost) * 5.0 \
			and state.job_salary - (work_cfg.home_rent_k[1] + state.living_cost) >= 0.8:
		out.append({"kind": Sim.IN_MOVE_HOME, "tier": 1})
	return out


## A Mid's push back when a ticket will miss its deadline, and a Senior's quality bar.
func controls(state: SimState) -> Array:
	var out: Array = []
	if not state.employed:
		return out
	var arch: ArchetypeData = _archetypes.get(state.job_archetype) as ArchetypeData
	if arch != null and state.level >= WorkOdds.MID and not state.push_back_used and state.ticket_progress > 0.0 and state.ticket_progress < 100.0:
		var rate := WorkOdds.ticket_rate(work_cfg, state.ticket_size, state.hours, state.skill, state.codebase, arch, state.level, state.quality, 1.0)
		if rate > 0.0 and state.day + (100.0 - state.ticket_progress) / rate > state.ticket_deadline + 1.0:
			out.append({"kind": Sim.IN_PUSH_BACK})
	if state.level >= WorkOdds.SENIOR:
		var bar := "clean" if state.codebase > 55.0 else "balanced"
		if Sim.QUALITY_NAMES[state.quality] != bar:
			out.append({"kind": Sim.IN_SET_QUALITY, "bar": bar})
	return out


func start_run(ctx: SimContext, duel_model: DuelModel, bot_seed: int) -> void:
	super.start_run(ctx, duel_model, bot_seed)
	_archetypes = ctx.archetypes


func _resizing_soon(state: SimState) -> bool:
	for ch: Dictionary in state.chains:
		if ch["event"] == Sim.EVT_RESIZING and int(ch["fire_day"]) - state.day <= RESIZING_WARNING_DAYS:
			return true
	return false

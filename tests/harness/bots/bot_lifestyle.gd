@tool
class_name BotLifestyle
extends BotCareer
## The Lifestyle bot (GDD 5.22): upgrades the home tier at every offer, and moves up whenever a raise or a promotion
## makes it look affordable. Hours notch 3 or 4. Target: mostly Plan B endings.


func hours_notch(state: SimState, _ctx: SimContext) -> int:
	return 3 if state.burnout > 50.0 else 4


func plan(state: SimState, ctx: SimContext) -> Array:
	var out := super.plan(state, ctx)
	if state.employed and state.home < work_cfg.home_rent_k.size() - 1 and state.job_salary > work_cfg.home_rent_k[state.home + 1] + state.living_cost:
		out.append({"kind": Sim.IN_MOVE_HOME, "tier": state.home + 1})
	return out


func choose(state: SimState, ctx: SimContext, item: Dictionary) -> String:
	var ids: Array = item["choices"]
	if ids.has("upgrade"):
		return "upgrade"
	return super.choose(state, ctx, item)

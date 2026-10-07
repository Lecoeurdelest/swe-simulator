@tool
class_name BotGrinder
extends BotCareer
## The Grinder (GDD 5.22): Hours notch 5, always. It hunts and answers like any career bot; only its hours differ.
## Target: mostly Burnout endings, under 2% wins.


func hours_notch(_state: SimState, _ctx: SimContext) -> int:
	return work_cfg.hours_speed.size()


func wants_to_hunt(state: SimState, _ctx: SimContext) -> bool:
	return not state.employed

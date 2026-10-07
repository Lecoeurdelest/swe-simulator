@tool
class_name BotCoaster
extends BotBase
## The Coaster (GDD 5.22): Hours notch 2, never applies, never moves, never studies. It answers every event with the
## passive choice. Target: no wins, and a median loss before day 1,800 (R-BAL-02, O2: standing still is never safe).


func plan(state: SimState, _ctx: SimContext) -> Array:
	return hours_input(state, 2)

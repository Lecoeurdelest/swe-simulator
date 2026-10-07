@tool
class_name BotBase
extends RefCounted
## A bot only sends inputs (ARCHITECTURE 19.6, ROADMAP Step 14 pitfalls): it reads the SimState and the SimContext and
## returns the inputs for one step; every rule lives in Sim. It rolls on its own RNG, seeded from the run seed, so a
## bot's dice never shift the sim's. inputs() answers whatever the clock waits on (an event card, a review, a duel, an
## offer) through the hooks below, and plan() adds the day's voluntary inputs; a subclass overrides the hooks.

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var duel: DuelModel
var work_cfg: WorkConfig
var gap_topics: Array = []
var bg: BackgroundData
var tiers: Dictionary = {}


## Reset for one run. bot_seed should come from the run's seed (the harness xors it with a bot-specific salt).
func start_run(ctx: SimContext, duel_model: DuelModel, bot_seed: int) -> void:
	rng.seed = bot_seed
	duel = duel_model
	work_cfg = ctx.cfg
	bg = ctx.bg
	tiers = ctx.tiers
	gap_topics = duel.roll_gap_topics(bg, rng)


func inputs(state: SimState, ctx: SimContext) -> Array:
	if state.is_waiting():
		return _answer(state, ctx, state.pending())
	return plan(state, ctx)


func _answer(state: SimState, ctx: SimContext, item: Dictionary) -> Array:
	match String(item["kind"]):
		"event":
			return [{"kind": Sim.IN_CHOOSE, "choice": choose(state, ctx, item)}]
		"review":
			var left := WorkOdds.review_standin_left(work_cfg, float(item["calibration"]), float(item["evidence"]), rng)
			return [{"kind": Sim.IN_REVIEW_RESULT, "evidence_left": left}]
		"ticket_pick":
			return [{"kind": Sim.IN_TICKET_PICK, "pick": pick_ticket(state, ctx)}]
		"duel":
			var req: Dictionary = item["request"]
			var tier: TierData = tiers.get(String(req["tier"])) as TierData
			var result := duel.resolve_interview(req, bg, tier, gap_topics, rng)
			return [{"kind": Sim.IN_DUEL_RESULT, "passed": result["passed"], "composure_left": result["composure"]}]
		"offer":
			return [{"kind": Sim.IN_ANSWER_OFFER, "accept": accept_offer(state, ctx, item["posting"])}]
	return [{"kind": Sim.IN_ACK}]


# ---------- hooks ----------

## The day's voluntary inputs (Hours, applying, studying, moving, a Mid's push back, a Senior's quality bar).
func plan(_state: SimState, _ctx: SimContext) -> Array:
	return []


## The choice for an event card: the exhausted choice when it is on offer, else the first button.
func choose(_state: SimState, _ctx: SimContext, item: Dictionary) -> String:
	var ids: Array = item["choices"]
	var exhausted := String(item.get("exhausted", ""))
	return exhausted if ids.has(exhausted) else String(ids[0])


func pick_ticket(_state: SimState, _ctx: SimContext) -> String:
	return "feature"


func accept_offer(_state: SimState, _ctx: SimContext, _posting: Dictionary) -> bool:
	return false


# ---------- helpers for subclasses ----------

## Set the Hours notch if it differs (the notches lock for a few days after an overtime ask).
func hours_input(state: SimState, notch: int) -> Array:
	if notch != state.hours and state.day > state.hours_lock_until:
		return [{"kind": Sim.IN_SET_HOURS, "notch": notch}]
	return []

@tool
class_name WorkSession
extends RefCounted
## One career run as the work state plays it (ARCHITECTURE 19.4, 19.7): the sim's state and context, the clock, the
## notices the player has yet to read, the quiet feed in the Body and the first-run coach marks. Pure, like Sim: no
## nodes, no autoloads and no wall clock (INV-03, INV-21, INV-22), so a test can play a whole job through it and a save
## round trip is checkable. GameState owns one, saves it and changes phases; the scene shows it and calls GameState
## verbs, which land here.
##
## Every player answer goes through Sim.apply_inputs, which does not tick: time moves only when tick() is called,
## which the scene does once a day while nothing is open. tick() refuses while a notice or a card is waiting.

const SAVE_VERSION := 2
const REVIEW_SEED_MIX := 7919
const COACH_SPEED := "coach_speed"
const COACH_HOURS := "coach_hours"
const COACH_STUDIO := "coach_studio"
const COACH_HOURS_FROM_DAY := 1    # once the clock has started
const COACH_STUDIO_FROM_DAY := 8

var sim: SimState
var ctx: SimContext
var clock: WorkClock = WorkClock.new()
var notices: Array = []         # to read, in order; the clock waits for each
var feed: Array = []            # the Body's quiet lines, newest last
var player_name: String = ""
var first_run: bool = false     # the first coach marks teach a run that has not been played before
var coach_closed: Array = []


static func start(context: SimContext, run_number: int, run_seed: int, handbook: Array, name: String, first: bool) -> WorkSession:
	var session := WorkSession.new()
	session.ctx = context
	session.sim = Sim.new_run(context, run_number, run_seed, handbook)
	session.player_name = name
	session.first_run = first
	return session


## What to_save wrote ({version, phase, sim, ui}). The context has to be the one built for the run's background.
static func from_save(data: Dictionary, context: SimContext) -> WorkSession:
	var session := WorkSession.new()
	session.ctx = context
	session.sim = SimState.from_save(data.get("sim", {}))
	var ui: Dictionary = SimState.decode_value(data.get("ui", {}))
	session.notices = (ui.get("notices", []) as Array).duplicate(true)
	session.feed = (ui.get("feed", []) as Array).duplicate(true)
	session.player_name = String(ui.get("name", ""))
	session.first_run = bool(ui.get("first_run", false))
	session.coach_closed = (ui.get("coach_closed", []) as Array).duplicate()
	return session


## The save of record for this run: the sim exactly (SimState.to_save) and the screen's own state, encoded the same way so
## a float cannot come back one digit off. The clock's speed is not saved: Continue always waits, paused (KILL_TESTS 6).
func to_save(phase: int) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"phase": phase,
		"sim": sim.to_save(),
		"ui": SimState.encode_value({
			"notices": notices.duplicate(true), "feed": feed.duplicate(true), "name": player_name,
			"first_run": first_run, "coach_closed": coach_closed.duplicate(),
		}),
	}


# ---------- what blocks the clock ----------

## Something is open over the work state: a notice to read, or a card the sim waits on. The clock does not run (INV-22).
func is_blocked() -> bool:
	return not notices.is_empty() or sim.is_waiting()


## The card on top: the first notice, else the sim's queue head ({} when the layoff scene or nothing is waiting).
func current_card() -> Dictionary:
	if not notices.is_empty():
		return notices[0]
	return WorkCards.head(sim, ctx)


## The layoff scene waits for the LAYOFF phase once the notices before it are read.
func wants_layoff_scene() -> bool:
	return notices.is_empty() and WorkCards.is_layoff_pending(sim)


func is_over() -> bool:
	return sim.ended


# ---------- time ----------

## One day. Does nothing while a notice or a card is open, or after an ending. Returns the sim's events.
func tick() -> Array:
	if is_blocked() or sim.ended:
		return []
	var events: Array = Sim.step(sim, [], ctx)
	_take(events)
	return events


## Apply one input without ticking. Returns the sim's events (an input_rejected one when it did not apply).
func apply(input: Dictionary) -> Array:
	var events: Array = Sim.apply_inputs(sim, [input], ctx)
	_take(events)
	return events


func _take(events: Array) -> void:
	notices.append_array(WorkCards.notices_from(events, sim, ctx))
	feed.append_array(WorkCards.feed_from(events, sim))
	while feed.size() > WorkCards.FEED_MAX:
		feed.pop_front()


# ---------- the player's answers ----------

func set_hours(notch: int) -> Array:
	return apply({"kind": Sim.IN_SET_HOURS, "notch": notch})


func choose(choice_id: String) -> Array:
	return apply({"kind": Sim.IN_CHOOSE, "choice": choice_id})


func pick_ticket(pick: String) -> Array:
	return apply({"kind": Sim.IN_TICKET_PICK, "pick": pick})


## The layoff scene's or the forced leave's OK.
func acknowledge() -> Array:
	return apply({"kind": Sim.IN_ACK})


## M2's review: the stand-in of GDD 5.16 (A67) on its own dice, seeded from the run seed and the day, so the sim's stream
## is never touched. M3 replaces this with the 3-prompt duel.
func resolve_review() -> Array:
	var item := sim.pending()
	if String(item.get("kind", "")) != "review":
		return []
	var rng := RandomNumberGenerator.new()
	rng.seed = sim.rng_seed ^ (sim.day * REVIEW_SEED_MIX)
	var left := WorkOdds.review_standin_left(ctx.cfg, float(item["calibration"]), float(item["evidence"]), rng)
	return apply({"kind": Sim.IN_REVIEW_RESULT, "evidence_left": left})


## M2's stub for an interview day (the duel arrives with M3's adapter): the interview goes badly.
func fail_interview() -> Array:
	return apply({"kind": Sim.IN_DUEL_RESULT, "passed": false, "composure_left": 0.0})


## M2's stub for an offer (nothing can win an interview yet): decline it.
func decline_offer() -> Array:
	return apply({"kind": Sim.IN_ANSWER_OFFER, "accept": false})


## Answer whatever is open in the simplest way: read a notice, take an event's first choice (careful: the last one that
## is not a quit, which is usually the cheaper one), resolve the review, pick a Feature ticket, acknowledge, skip an
## interview, decline an offer. For tests, the debug quick start and autoplay.
func answer_simply(careful: bool = false) -> void:
	var card := current_card()
	match String(card.get("kind", "")):
		"notice":
			dismiss_notice()
		WorkCards.K_EVENT:
			choose(_pick_choice(card["choices"] as Array, careful))
		WorkCards.K_REVIEW:
			resolve_review()
		WorkCards.K_PICK:
			pick_ticket("feature")
		WorkCards.K_LEAVE:
			acknowledge()
		WorkCards.K_DUEL:
			fail_interview()
		WorkCards.K_OFFER:
			decline_offer()
		_:
			acknowledge()   # whatever else the sim waits on (the layoff scene belongs to the LAYOFF phase)


static func _pick_choice(choices: Array, careful: bool) -> String:
	if careful:
		for i: int in range(choices.size() - 1, -1, -1):
			if not String(choices[i]).contains("quit"):
				return String(choices[i])
	return String(choices[0])


## Play on, answering every card carefully on the quietest Hours, until the layoff scene is next (or the run ends). Run
## 1's is on day 240. For the debug quick start: a patient player at notch 3 burns out long before then.
func play_to_layoff(max_steps: int = 20000) -> void:
	set_hours(1)
	var steps := 0
	while not wants_layoff_scene() and not sim.ended and steps < max_steps:
		steps += 1
		if is_blocked():
			answer_simply(true)
		else:
			tick()


## OK on the first notice.
func dismiss_notice() -> void:
	if not notices.is_empty():
		notices.pop_front()
		clock.hold()


# ---------- the first-run coach marks (GDD 4.3, spec gap settled at M2's huddle) ----------

## The coach mark to show now, or "" for none: one at a time, in order, on the first run only, never over a card. A
## mark is done when you do what it asks (start the clock, move the Hours) or tap it closed (D11).
func coach_id() -> String:
	if not first_run or is_blocked():
		return ""
	var hours_moved := int(sim.stats.get("hours_changes", 0)) > 0
	if not coach_closed.has(COACH_SPEED) and sim.day == 0 and not clock.is_running():
		return COACH_SPEED
	if not coach_closed.has(COACH_HOURS) and not hours_moved and sim.day >= COACH_HOURS_FROM_DAY:
		return COACH_HOURS
	if not coach_closed.has(COACH_STUDIO) and sim.day >= COACH_STUDIO_FROM_DAY and (hours_moved or coach_closed.has(COACH_HOURS)):
		return COACH_STUDIO
	return ""


func close_coach(id: String) -> void:
	if not id.is_empty() and not coach_closed.has(id):
		coach_closed.append(id)

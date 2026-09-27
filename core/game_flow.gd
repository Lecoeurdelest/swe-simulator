@tool
class_name GameFlow
extends RefCounted
## Which phase may follow which, and when the run save is written or deleted (GDD 4.1, 5.11).
## Pure data: tested by tests/test_flow.gd. Only GameState.change_phase() changes the phase.

enum Phase { TITLE, INTRO, BACKGROUND_SELECT, JOB_HUNT, INTERVIEW, OFFER, PHASE2_STUB, GAME_OVER }

const TRANSITIONS: Dictionary = {
	Phase.TITLE: [Phase.INTRO, Phase.BACKGROUND_SELECT, Phase.JOB_HUNT, Phase.INTERVIEW, Phase.OFFER],
	Phase.INTRO: [Phase.BACKGROUND_SELECT],
	Phase.BACKGROUND_SELECT: [Phase.JOB_HUNT, Phase.TITLE],
	Phase.JOB_HUNT: [Phase.INTERVIEW, Phase.GAME_OVER, Phase.TITLE],
	Phase.INTERVIEW: [Phase.OFFER, Phase.JOB_HUNT, Phase.TITLE],
	Phase.OFFER: [Phase.PHASE2_STUB, Phase.JOB_HUNT, Phase.GAME_OVER, Phase.TITLE],
	Phase.PHASE2_STUB: [Phase.TITLE, Phase.BACKGROUND_SELECT],
	Phase.GAME_OVER: [Phase.TITLE, Phase.BACKGROUND_SELECT],
}

## A run is "live" only in these phases; they are the only phases ever written to the save.
const SAVED_PHASES: Array[Phase] = [Phase.JOB_HUNT, Phase.INTERVIEW, Phase.OFFER]


static func can_transition(from: Phase, to: Phase) -> bool:
	var allowed: Array = TRANSITIONS.get(from, [])
	return allowed.has(to)


static func is_saved(phase: Phase) -> bool:
	return SAVED_PHASES.has(phase)


## The run is over: Plan B reached, or the player left the Hired card.
static func deletes_save(from: Phase, to: Phase) -> bool:
	return to == Phase.GAME_OVER or from == Phase.PHASE2_STUB


## Continue may only resume a live run that can legally follow TITLE.
static func can_resume(saved: Phase) -> bool:
	return is_saved(saved) and can_transition(Phase.TITLE, saved)

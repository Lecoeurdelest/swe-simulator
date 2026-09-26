@tool
extends McpTestSuite
## GameFlow transitions (GDD 4.1) and the save policy (GDD 5.11). Editor-side: no autoloads.

const LEGAL: Array[Array] = [
	[GameFlow.Phase.TITLE, GameFlow.Phase.INTRO],
	[GameFlow.Phase.TITLE, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.TITLE, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.TITLE, GameFlow.Phase.INTERVIEW],
	[GameFlow.Phase.TITLE, GameFlow.Phase.OFFER],
	[GameFlow.Phase.INTRO, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.BACKGROUND_SELECT, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB],
	[GameFlow.Phase.OFFER, GameFlow.Phase.JOB_HUNT],
	[GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE],
	[GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.TITLE],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.BACKGROUND_SELECT],
	# Back / pause "Quit to title" (the save survives):
	[GameFlow.Phase.BACKGROUND_SELECT, GameFlow.Phase.TITLE],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.TITLE],
	[GameFlow.Phase.INTERVIEW, GameFlow.Phase.TITLE],
	[GameFlow.Phase.OFFER, GameFlow.Phase.TITLE],
]

const ILLEGAL: Array[Array] = [
	[GameFlow.Phase.TITLE, GameFlow.Phase.TITLE],
	[GameFlow.Phase.TITLE, GameFlow.Phase.PHASE2_STUB],
	[GameFlow.Phase.TITLE, GameFlow.Phase.GAME_OVER],
	[GameFlow.Phase.INTRO, GameFlow.Phase.OFFER],
	[GameFlow.Phase.JOB_HUNT, GameFlow.Phase.OFFER],
	[GameFlow.Phase.GAME_OVER, GameFlow.Phase.JOB_HUNT],
]


func suite_name() -> String:
	return "flow"


func test_required_transitions_are_legal() -> void:
	for pair: Array in LEGAL:
		assert_true(GameFlow.can_transition(pair[0], pair[1]),
			"%s -> %s should be legal" % [GameFlow.Phase.find_key(pair[0]), GameFlow.Phase.find_key(pair[1])])


func test_illegal_jumps_are_blocked() -> void:
	for pair: Array in ILLEGAL:
		assert_false(GameFlow.can_transition(pair[0], pair[1]),
			"%s -> %s should be illegal" % [GameFlow.Phase.find_key(pair[0]), GameFlow.Phase.find_key(pair[1])])


func test_only_live_run_phases_are_saved() -> void:
	for phase: int in GameFlow.Phase.values():
		var live := phase in [GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER]
		assert_eq(GameFlow.is_saved(phase), live, "is_saved(%s)" % GameFlow.Phase.find_key(phase))


func test_save_deleted_on_plan_b_and_after_hired() -> void:
	assert_true(GameFlow.deletes_save(GameFlow.Phase.JOB_HUNT, GameFlow.Phase.GAME_OVER))
	assert_true(GameFlow.deletes_save(GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.TITLE))
	assert_true(GameFlow.deletes_save(GameFlow.Phase.PHASE2_STUB, GameFlow.Phase.BACKGROUND_SELECT))
	assert_false(GameFlow.deletes_save(GameFlow.Phase.OFFER, GameFlow.Phase.PHASE2_STUB), "killed on the Hired card: Continue still works")
	assert_false(GameFlow.deletes_save(GameFlow.Phase.JOB_HUNT, GameFlow.Phase.TITLE), "Quit to title keeps the run")


func test_continue_only_resumes_live_runs() -> void:
	for phase: int in GameFlow.Phase.values():
		var live := phase in [GameFlow.Phase.JOB_HUNT, GameFlow.Phase.INTERVIEW, GameFlow.Phase.OFFER]
		assert_eq(GameFlow.can_resume(phase), live, "can_resume(%s)" % GameFlow.Phase.find_key(phase))


func test_fresh_run_state_is_empty() -> void:  # retry() builds exactly this
	var r := RunState.new()
	assert_eq(r.phase, GameFlow.Phase.TITLE)
	assert_eq(r.day, 1)
	assert_eq(r.pity_count, 0)
	assert_true(r.applied.is_empty() and r.applications.is_empty() and r.blacklist.is_empty())
	assert_true(r.interview.is_empty() and r.offer.is_empty())

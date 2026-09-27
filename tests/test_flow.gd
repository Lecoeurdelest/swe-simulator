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

const ROUTER_PATH := "res://autoload/scene_router.gd"
const FEATURES_DIR := "res://features/"


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


## SceneRouter.SCENES names one existing screen per phase, and every screen answers Back
## (ARCHITECTURE 5, 9). The router is read as text: tests never load autoload scripts.
func test_every_phase_has_a_screen_with_handle_back() -> void:
	var paths: Array[String] = []
	var regex := RegEx.create_from_string("\"(res://features/[^\"]+\\.tscn)\"")
	for m: RegExMatch in regex.search_all(FileAccess.get_file_as_string(ROUTER_PATH)):
		paths.append(m.get_string(1))
	assert_eq(paths.size(), GameFlow.Phase.size(), "SceneRouter.SCENES has one scene per phase")
	for path: String in paths:
		assert_true(ResourceLoader.exists(path), "%s exists" % path)
		var script_path := path.get_basename() + ".gd"
		assert_true(FileAccess.get_file_as_string(script_path).contains("func handle_back() -> bool:"),
			"%s implements handle_back()" % script_path)


## INV-01 / INV-02: screens only call GameState verbs. They never set the phase, call
## change_phase() or swap scenes; SceneRouter does that.
func test_screens_never_change_phase_or_scene() -> void:
	var scripts := _scripts_under(FEATURES_DIR)
	assert_gt(scripts.size(), GameFlow.Phase.size() - 1, "every screen has a script")
	var sets_phase := RegEx.create_from_string("\\.phase\\s*=[^=]")
	for path: String in scripts:
		var src := FileAccess.get_file_as_string(path)
		assert_false(src.contains("change_scene"), "%s calls change_scene_*()" % path)
		assert_false(src.contains("change_phase("), "%s calls change_phase()" % path)
		assert_true(sets_phase.search(src) == null, "%s assigns a phase" % path)


static func _scripts_under(dir: String) -> Array[String]:
	var out: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == "gd":
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		out.append_array(_scripts_under(dir.path_join(sub)))
	return out

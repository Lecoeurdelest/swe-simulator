extends CanvasLayer
## Autoload "SceneRouter": swaps scenes behind a fade whenever GameState's phase changes.
## Scenes never call change_scene_*() themselves.

signal transition_finished(phase: GameFlow.Phase)

const FADE_SEC := 0.2
const SCENES: Dictionary = {
	GameFlow.Phase.TITLE: "res://features/title/title.tscn",
	GameFlow.Phase.INTRO: "res://features/intro/intro.tscn",
	GameFlow.Phase.BACKGROUND_SELECT: "res://features/background_select/background_select.tscn",
	GameFlow.Phase.JOB_HUNT: "res://features/job_hunt/job_hunt.tscn",
	GameFlow.Phase.INTERVIEW: "res://features/interview/interview.tscn",
	GameFlow.Phase.OFFER: "res://features/offer/offer.tscn",
	GameFlow.Phase.PHASE2_STUB: "res://features/phase2_stub/phase2_stub.tscn",
	GameFlow.Phase.GAME_OVER: "res://features/game_over/game_over.tscn",
}

var busy: bool = false
var _curtain := ColorRect.new()
var _queued: int = -1


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_curtain.color = Color(0.07, 0.07, 0.1)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE  # an invisible rect still eats taps unless IGNORE
	_curtain.modulate.a = 0.0
	add_child(_curtain)
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(_from: GameFlow.Phase, to: GameFlow.Phase) -> void:
	go_to(to)


func go_to(phase: GameFlow.Phase) -> void:
	if busy:
		_queued = phase  # the last request wins
		return
	var path: String = SCENES.get(phase, "")
	if not ResourceLoader.exists(path):
		push_error("SceneRouter: no scene for %s at '%s'" % [GameFlow.Phase.find_key(phase), path])
		return
	busy = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP  # no double taps during the fade
	ResourceLoader.load_threaded_request(path)         # loads while the screen fades out
	await _fade_to(1.0)
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	get_tree().paused = false
	get_tree().change_scene_to_packed(packed)
	await get_tree().scene_changed
	await _fade_to(0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
	transition_finished.emit(phase)
	if _queued != -1:
		var next := _queued as GameFlow.Phase
		_queued = -1
		go_to(next)


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_curtain, "modulate:a", alpha, FADE_SEC)
	await tween.finished

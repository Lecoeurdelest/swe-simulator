extends Control
## Step 3 stub of the interview (GDD S08): Win and Lose call the real verb. Step 4 builds the fight.

@onready var _info: Label = %Info
@onready var _back_button: Button = %BackButton
@onready var _win_button: Button = %WinButton
@onready var _lose_button: Button = %LoseButton
@onready var _pause: PauseMenu = %PauseMenu
@onready var _ready_overlay: Control = %ReadyOverlay


func _ready() -> void:
	var iv: Dictionary = GameState.run.interview
	_info.text = "%s (%s)\n%s" % [iv.get("company_id", "?"), iv.get("tier", "?"), iv.get("template_id", "?")]
	_back_button.pressed.connect(Device.handle_back)
	_win_button.pressed.connect(GameState.finish_interview.bind(true, 70.0))
	_lose_button.pressed.connect(GameState.finish_interview.bind(false, 0.0))
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	_ready_overlay.gui_input.connect(_on_ready_overlay_input)


## GameState pauses the tree when the app loses focus mid-interview (ARCHITECTURE 9), and
## "Ready? Tap to continue" unpauses it. Our own Pause sheet also pauses the tree, but shows itself.
func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_PAUSED:
			_ready_overlay.visible = not _pause.is_open()
		NOTIFICATION_UNPAUSED:
			_ready_overlay.hide()


## Back opens Pause (Step 4 adds: skip the VS intro first); Back again resumes.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	_ready_overlay.hide()
	_pause.open()
	return true


func _on_ready_overlay_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_ready_overlay.hide()
		get_tree().paused = false

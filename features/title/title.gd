extends Control
## Title screen (GDD S01, ARCHITECTURE 11.1), before the art pass.
## No save: tap anywhere = New game. With a save: [ New game ] above a full-width CONTINUE.
## Debug builds also show the Step 1 size readout and the Step 2 "Device check" button.

## Loaded by path when pressed, never preloaded: features/dev/ is excluded from release exports.
const DEVICE_CHECK_PATH := "res://features/dev/device_check.tscn"
const BLINK_SEC := 0.5
## Debug-only label, English on purpose (not player text, so not in CONTENT.md).
const DEBUG_DEVICE_CHECK := "Device check"

var _has_save: bool = false
var _device_check: Control = null

@onready var _software: Label = %Software
@onready var _engineer: Label = %Engineer
@onready var _simulator: Label = %Simulator
@onready var _size_readout: Label = %SizeReadout
@onready var _tap_to_start: Label = %TapToStart
@onready var _new_game_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
@onready var _replay_intro_button: Button = %ReplayIntroButton
@onready var _device_check_button: Button = %DeviceCheckButton
@onready var _version: Label = %Version
@onready var _quit_dialog: ConfirmDialog = %QuitDialog


func _ready() -> void:
	_software.text = Content.text("barks", "ui_logo_1")
	_engineer.text = Content.text("barks", "ui_logo_2")
	_simulator.text = Content.text("barks", "ui_logo_3")
	_tap_to_start.text = Content.text("barks", "ui_tap_to_start")
	_new_game_button.text = Content.text("barks", "ui_new_game")
	_continue_button.text = UiText.primary(Content.text("barks", "ui_continue"))
	_replay_intro_button.text = Content.text("barks", "ui_replay_intro")
	_device_check_button.text = DEBUG_DEVICE_CHECK
	_has_save = SaveIO.exists()
	_tap_to_start.visible = not _has_save
	_new_game_button.visible = _has_save
	_continue_button.visible = _has_save
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	_size_readout.visible = OS.is_debug_build()
	set_process(OS.is_debug_build())
	_device_check_button.visible = OS.is_debug_build() and ResourceLoader.exists(DEVICE_CHECK_PATH)
	_new_game_button.pressed.connect(GameState.start_new_game)
	_continue_button.pressed.connect(GameState.continue_game)
	_replay_intro_button.pressed.connect(GameState.replay_intro)
	_device_check_button.pressed.connect(_open_device_check)
	_quit_dialog.confirmed.connect(get_tree().quit)
	if not _has_save:
		var blink := create_tween().set_loops()
		blink.tween_interval(BLINK_SEC)
		blink.tween_callback(_toggle_tap_to_start)


## Step 1's scale-guard readout, kept as a debug overlay (ARCHITECTURE 11.1): resize the window
## and "game" changes while the pixels stay square.
func _process(_delta: float) -> void:
	var win := get_tree().root
	var game := Vector2i(win.get_visible_rect().size)
	var mode := "integer" if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER else "fractional"
	_size_readout.text = "win %dx%d game %dx%d %s" % [win.size.x, win.size.y, game.x, game.y, mode]


## No save: a tap anywhere outside the buttons starts a new game. Every container here is IGNORE,
## so the tap falls through to this root. It acts on release, like a Button.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if _has_save or mb == null or mb.button_index != MOUSE_BUTTON_LEFT or mb.pressed:
		return
	accept_event()
	GameState.start_new_game()


## Close the open overlay first; else "Quit?" on Android and desktop. iOS apps never quit themselves.
func handle_back() -> bool:
	if _device_check != null:
		return bool(_device_check.call(&"handle_back"))  # the device check counts Back presses
	if _quit_dialog.is_open():
		return _quit_dialog.handle_back()
	if OS.get_name() == "iOS":
		return false
	_quit_dialog.open(Content.text("barks", "ui_quit_confirm"), Content.text("barks", "ui_quit"), "", true)
	return true


func _toggle_tap_to_start() -> void:
	_tap_to_start.modulate.a = 1.0 - _tap_to_start.modulate.a


func _open_device_check() -> void:
	if _device_check != null:
		return
	_device_check = (load(DEVICE_CHECK_PATH) as PackedScene).instantiate() as Control
	_device_check.connect(&"closed", _close_device_check)
	add_child(_device_check)  # full rect, mouse_filter STOP: covers and blocks the title while open


func _close_device_check() -> void:
	_device_check.queue_free()
	_device_check = null

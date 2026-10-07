extends Control
## The layoff scene (GDD 5.19, D-22; ARCHITECTURE 19.7): "DANA VS YOU", and then no fight starts. Dana reads the
## euphemism, the severance appears, your access is revoked. Non-interactive: its four beats advance on taps like the
## intro's captions (no auto-advance: D12, A19, RC-34), Back opens Pause, and the last OK hands the sim its
## acknowledgement (GameState.career_acknowledge), which sends the run back to WORK. This is M2's plain version; M3
## gives it the VS intro's look and the hold-to-skip pill from the second viewing.

const BEATS := 4
const REVOKED_COLOR := Color(0.89411765, 0.23137255, 0.26666668)   # the warning red of the hub's rent line

var _beat := -1
var _locked := true     # the 250 ms input lock after each beat (GDD 2.8 rule 7)
var _leaving := false

@onready var _title: Label = %Title
@onready var _line: Label = %DanaLine
@onready var _line2: Label = %DanaLine2
@onready var _severance: Label = %Severance
@onready var _revoked: Label = %Revoked
@onready var _hint: Label = %Hint
@onready var _tap_pad: Control = %TapPad
@onready var _back_button: Button = %BackButton
@onready var _next_button: Button = %NextButton
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	if OS.is_debug_build() and GameState.session == null:
		GameState.debug_career_quick_start(true)   # project_run mode="custom": a run that has just been laid off
	var pending := GameState.session.sim.pending() if GameState.session != null else {}
	_title.text = Content.text("barks", "vs_layoff_title")
	_line.text = Content.text("barks", "bark_dana_layoff")
	_line2.text = Content.text("barks", "bark_dana_layoff_2")
	_severance.text = Content.text("barks", "ui_severance", {"money": UiText.money_k(float(pending.get("severance", 0.0)))})
	_revoked.text = Content.text("barks", "ui_access_revoked")
	_revoked.add_theme_color_override(&"font_color", REVOKED_COLOR)
	_hint.text = Content.text("barks", "ui_tap_to_continue")
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_back_button.pressed.connect(Device.handle_back)
	_next_button.pressed.connect(_advance)
	_tap_pad.gui_input.connect(_on_tap_input)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	for beat: Control in [_line2, _severance, _revoked]:
		beat.hide()
	_advance_to(0)


## Back opens Pause (RC-34); a second Back resumes.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	GameState.save()
	_pause.open()
	return true


## A tap anywhere advances, on release like a button.
func _on_tap_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton   # touches arrive as emulated mouse events
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_advance()


func _advance() -> void:
	if _locked or _leaving or _pause.is_open():
		return
	if _beat >= BEATS - 1:
		_leaving = true
		_next_button.disabled = true
		GameState.career_acknowledge()
		return
	_advance_to(_beat + 1)


func _advance_to(beat: int) -> void:
	_beat = beat
	match beat:
		1:
			_line2.show()
		2:
			_severance.show()
		3:
			_revoked.show()
	var last := beat >= BEATS - 1
	_next_button.text = UiText.primary(Content.text("barks", "ui_ok" if last else "ui_continue"))
	_hint.visible = not last
	_locked = true
	await get_tree().create_timer(Content.balance.input_lock_ms / 1000.0).timeout
	_locked = false

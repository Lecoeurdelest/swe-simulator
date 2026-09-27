class_name NightScreen
extends Control
## The night summary (GDD S04, 4.1): after Sleep the phone locks and shows one notification card,
## "Applied 4 - Rejected 2 - Ghosted 1 - Rent due in 9 days", with at most one Ducky tip under it (the
## night is a natural pause, GDD 8.1 rule 3). A tap anywhere, or Back, unlocks it: the hub then shows
## the morning inbox. It sits in the ModalLayer and blocks the hub behind it while open.

signal dismissed

var _unlock_at := 0  # msec: the tap that sent the phone to sleep can't also wake it (cfg.input_lock_ms)

@onready var _app_name: Label = %AppName
@onready var _summary: Label = %Summary
@onready var _tip: DuckyNote = %Tip


func _ready() -> void:
	hide()


## Texts come from Content (already translated); tip_text = "" shows no tip.
func open(app_name: String, summary: String, tip_text: String) -> void:
	_app_name.text = app_name
	_summary.text = summary
	_tip.tip_text = tip_text
	_tip.visible = not tip_text.is_empty()
	_unlock_at = Time.get_ticks_msec() + Content.balance.input_lock_ms
	show()


func is_open() -> bool:
	return visible


func summary_text() -> String:
	return _summary.text


## Back while locked = unlock, like a tap. The hub's handle_back() asks this first.
func handle_back() -> bool:
	if not visible:
		return false
	_dismiss()
	return true


## A tap anywhere unlocks, on release like the buttons (touch arrives as emulated mouse events).
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		accept_event()
		if Time.get_ticks_msec() >= _unlock_at:
			_dismiss()


func _dismiss() -> void:
	if not visible:
		return
	hide()
	dismissed.emit()

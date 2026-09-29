class_name DuckyNote
extends PanelContainer
## Placeholder Ducky tip note (GDD 2.7, 4.3, 8.1): 254 px wide, so the tip wraps at 40 columns
## (up to 4 lines, 120 characters). Set tip_text to a string from Content (already translated). The
## art pass replaces the look only.
## It never blocks input: every node in it is mouse_filter IGNORE. A closable note (a first-run coach
## mark, CoachMark; the offer's tip) shows a small "x" and takes only its own tap, which emits
## `close_tapped`; its owner hides it.

## A tap on a closable note: a press and a release on it with no drag past the scroll deadzone, like a
## Button (DECISIONS A30).
signal close_tapped

const CLOSE_MARK := "x"  # stands in for the close icon until the art pass

@export_multiline var tip_text: String = "":
	set(value):
		tip_text = value
		_pressed = false  # a press on the old text never closes the new one
		if is_node_ready():
			_tip.text = value

## Shows the small close mark in the top-right corner, and the note takes its own tap.
@export var closable: bool = false:
	set(value):
		closable = value
		if is_node_ready():
			_apply_closable()

var _pressed := false  # a press on the note that hasn't moved past the deadzone: its release closes
var _press_at := Vector2.ZERO
var _in_scroll := false
var _deadzone: float = float(ProjectSettings.get_setting("gui/common/default_scroll_deadzone", 6))

@onready var _name: Label = %Name
@onready var _tip: Label = %Tip
@onready var _close: Label = %Close


func _ready() -> void:
	_name.text = Content.text("naming", "mascot")
	_tip.text = tip_text
	_close.text = CLOSE_MARK
	_in_scroll = _scroll_ancestor()
	_apply_closable()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_pressed = false


## PASS, not STOP: inside a ScrollContainer the events go on to the list, so a drag that starts on the
## note still scrolls. Elsewhere the note accepts them, so the control under it never sees the tap.
func _apply_closable() -> void:
	_close.visible = closable
	mouse_filter = MOUSE_FILTER_PASS if closable else MOUSE_FILTER_IGNORE
	_pressed = false


func _gui_input(event: InputEvent) -> void:
	if not closable:
		return
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	var motion := event as InputEventMouseMotion
	var tapped := false
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_pressed = true
			_press_at = mb.global_position  # a scrolling list moves the note with the finger
		elif _pressed:
			_pressed = false
			tapped = Rect2(Vector2.ZERO, size).has_point(mb.position)
	elif motion != null and _pressed and motion.global_position.distance_to(_press_at) > _deadzone:
		_pressed = false
	else:
		return
	if not _in_scroll:
		accept_event()
	if tapped:
		close_tapped.emit()


func _scroll_ancestor() -> bool:
	var node := get_parent()
	while node != null:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false

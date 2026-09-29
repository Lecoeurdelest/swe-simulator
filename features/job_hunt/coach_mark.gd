class_name CoachMark
extends VBoxContainer
## A first-run Ducky coach mark (GDD 4.3): the full-width Ducky note, then a drawn arrow pointing down
## at one control (and, for the first card, a swipe-right arrow). A tap on the note closes the mark at
## once (its "x" says so) and emits `closed`, so the hub can keep it closed for the run; nothing else
## in it takes input (the arrow strip is mouse_filter IGNORE). The arrow follows its target's x while
## the layout moves. The art pass redraws the arrows; the positions stay.

signal closed(coach_id: String)

const ARROW_W := 12.0
const SWIPE_X := 8.0
const SWIPE_SHAFT := Vector2(16, 2)
const SWIPE_HEAD := 6.0
const ARROW_COLOR := Color(0.99607843, 0.68235296, 0.20392157)  # the PrimaryButton amber

var _coach_id := ""
var _target: Control
var _swipe := false
var _arrow_x := -1.0
var _pressed := false  # a press on the note that hasn't moved past the deadzone: its release closes
var _press_at := Vector2.ZERO
var _in_scroll := false
var _deadzone: float = float(ProjectSettings.get_setting("gui/common/default_scroll_deadzone", 6))

@onready var _note: DuckyNote = %Note
@onready var _arrows: Control = %Arrows


func _ready() -> void:
	_arrows.draw.connect(_draw_arrows)
	_note.gui_input.connect(_on_note_input)
	_in_scroll = _scroll_ancestor()
	set_process(false)


## Shows coach_id's text (already translated) with the arrow under the target's centre; swipe adds the
## swipe-right arrow. The same mark again changes nothing.
func point(coach_id: String, text: String, target: Control, swipe: bool = false) -> void:
	if visible and _coach_id == coach_id and _note.tip_text == text and _target == target and _swipe == swipe:
		return
	_coach_id = coach_id
	_note.tip_text = text
	_target = target
	_swipe = swipe
	_arrow_x = -1.0
	_pressed = false
	show()
	set_process(true)
	_arrows.queue_redraw()


func clear() -> void:
	hide()
	_coach_id = ""
	_target = null
	_pressed = false
	set_process(false)


func text() -> String:
	return _note.tip_text if visible else ""


func coach_id() -> String:
	return _coach_id if visible else ""


func _process(_delta: float) -> void:
	var x := -1.0
	if is_instance_valid(_target) and _target.is_visible_in_tree():
		x = roundf(_target.get_global_rect().get_center().x - _arrows.get_global_rect().position.x)
	if x != _arrow_x:
		_arrow_x = x
		_arrows.queue_redraw()


## A tap is a press and a release on the note without a drag past the scroll deadzone, like a Button.
## Over the deck the note takes the whole tap, so the card under it never sees it. In Mail's list the
## events pass on to the ScrollContainer, so a drag that starts on the note still scrolls.
func _on_note_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	var motion := event as InputEventMouseMotion
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_pressed = true
			_press_at = mb.global_position  # a scrolling list moves the note with the finger
		elif _pressed:
			_pressed = false
			if Rect2(Vector2.ZERO, _note.size).has_point(mb.position):
				_close()
	elif motion != null and _pressed and motion.global_position.distance_to(_press_at) > _deadzone:
		_pressed = false
	else:
		return
	if not _in_scroll:
		_note.accept_event()


## Hidden at once; `closed` waits for the end of the frame, because the hub rebuilds Mail's list (this
## mark included) when the run changes.
func _close() -> void:
	var id := _coach_id
	clear()
	closed.emit.call_deferred(id)


func _scroll_ancestor() -> bool:
	var node := get_parent()
	while node != null:
		if node is ScrollContainer:
			return true
		node = node.get_parent()
	return false


func _draw_arrows() -> void:
	var h := _arrows.size.y
	if _arrow_x >= 0.0:
		var x := clampf(_arrow_x, ARROW_W * 0.5, _arrows.size.x - ARROW_W * 0.5)
		_arrows.draw_colored_polygon(PackedVector2Array([
			Vector2(x - ARROW_W * 0.5, 0.0), Vector2(x + ARROW_W * 0.5, 0.0), Vector2(x, h)]), ARROW_COLOR)
	if _swipe:
		var mid := floorf((h - SWIPE_SHAFT.y) * 0.5)
		_arrows.draw_rect(Rect2(Vector2(SWIPE_X, mid), SWIPE_SHAFT), ARROW_COLOR)
		var tip_x := SWIPE_X + SWIPE_SHAFT.x
		_arrows.draw_colored_polygon(PackedVector2Array([
			Vector2(tip_x, 0.0), Vector2(tip_x + SWIPE_HEAD, h * 0.5), Vector2(tip_x, h)]), ARROW_COLOR)

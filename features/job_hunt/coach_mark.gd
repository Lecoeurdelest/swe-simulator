class_name CoachMark
extends VBoxContainer
## A first-run Ducky coach mark (GDD 4.3): the full-width Ducky note, then a drawn arrow pointing down
## at one control (and, for the first card, a swipe-right arrow). A tap on the note (a closable
## DuckyNote: its "x" says so) closes the mark at once and emits `closed`, so the hub can keep it closed
## for the run; nothing else in it takes input (the arrow strip is mouse_filter IGNORE). The arrow
## follows its target's x while the layout moves. The art pass redraws the arrows; the positions stay.

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

@onready var _note: DuckyNote = %Note
@onready var _arrows: Control = %Arrows


func _ready() -> void:
	_arrows.draw.connect(_draw_arrows)
	_note.close_tapped.connect(_close)
	set_process(false)


## Shows mark id's tip (already translated) with the arrow under the target's centre; swipe adds the
## swipe-right arrow. The same mark again changes nothing.
func point(id: String, tip: String, target: Control, swipe: bool = false) -> void:
	if visible and _coach_id == id and _note.tip_text == tip and _target == target and _swipe == swipe:
		return
	_coach_id = id
	_note.tip_text = tip
	_target = target
	_swipe = swipe
	_arrow_x = -1.0
	show()
	set_process(true)
	_arrows.queue_redraw()


func clear() -> void:
	hide()
	_coach_id = ""
	_target = null
	set_process(false)


func text() -> String:
	return _note.tip_text if visible else ""


func _process(_delta: float) -> void:
	var x := -1.0
	if is_instance_valid(_target) and _target.is_visible_in_tree():
		x = roundf(_target.get_global_rect().get_center().x - _arrows.get_global_rect().position.x)
	if x != _arrow_x:
		_arrow_x = x
		_arrows.queue_redraw()


## Hidden at once; `closed` waits for the end of the frame, because the hub rebuilds Mail's list (this
## mark included) when the run changes.
func _close() -> void:
	var id := _coach_id
	clear()
	closed.emit.call_deferred(id)


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

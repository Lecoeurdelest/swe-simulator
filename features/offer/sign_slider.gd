class_name SignSlider
extends Control
## Drag-to-sign (GDD S10, SHOULD-06; DECISIONS A95): ACCEPT becomes a drag from the left end of its track to the right, so
## signing a contract is a gesture and not a tap you can make by accident. Start on the handle, drag it along the track and
## let go past the end to sign; let go earlier and it springs back. With Relaxed Timing on, a tap anywhere on it signs.
## Mouse events only (INV-14: touches arrive as emulated mouse events), the handle is a full 36 px target, and it sits in the
## thumb band where ACCEPT was. It draws itself in the grey-box style until the art pass.

signal signed

const HANDLE_W := 36.0
const SIGN_FRACTION := 0.95     # how far along the track counts as signed
const TAP_SLOP := 6.0           # a press that moves less than this many pixels is a tap
const SPRING_S := 0.12
const TRACK_COLOR := Color(0.13, 0.15, 0.24, 1.0)
const BORDER_COLOR := Color(0.54509807, 0.60784316, 0.7058824, 1.0)
const FILL_COLOR := Color(0.99607843, 0.68235296, 0.20392157, 0.35)
const HANDLE_COLOR := Color(0.99607843, 0.68235296, 0.20392157, 1.0)
const INK_COLOR := Color(0.11, 0.12, 0.17, 1.0)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const CHEVRON := ">>"

var disabled := false: set = set_disabled
var relaxed := false            # Relaxed Timing: a tap signs

var _label := ""
var _x := 0.0                   # the handle's left edge, 0 to the end of the track
var _dragging := false
var _grab := 0.0                # where in the handle the press landed
var _moved := 0.0               # how far the pointer has moved since the press
var _spring: Tween


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(168.0, 36.0)


func set_label(text: String) -> void:
	_label = text
	queue_redraw()


func set_disabled(value: bool) -> void:
	disabled = value
	if value:
		_dragging = false
	modulate.a = 0.5 if value else 1.0
	queue_redraw()


## 0 at the start of the track, 1 at its end.
func progress() -> float:
	return _x / _travel()


func _travel() -> float:
	return maxf(size.x - HANDLE_W, 1.0)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press(button.position)
		else:
			_release()
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _dragging:
		_moved += motion.relative.length()
		_x = clampf(motion.position.x - _grab, 0.0, _travel())
		queue_redraw()
		accept_event()


## Only a press on the handle starts a drag, so a stray tap on the track does nothing (a tap signs in Relaxed Timing).
func _press(at: Vector2) -> void:
	var on_handle := Rect2(_x, 0.0, HANDLE_W, size.y).has_point(at)
	if not on_handle and not relaxed:
		return
	if _spring != null:
		_spring.kill()
	_dragging = true
	_moved = 0.0
	_grab = clampf(at.x - _x, 0.0, HANDLE_W) if on_handle else HANDLE_W * 0.5


func _release() -> void:
	if not _dragging:
		return
	_dragging = false
	if relaxed and _moved < TAP_SLOP:
		_sign()
	elif progress() >= SIGN_FRACTION:
		_sign()
	else:
		_spring_back()


func _sign() -> void:
	_x = _travel()
	queue_redraw()
	signed.emit()


func _spring_back() -> void:
	if not is_inside_tree():
		_x = 0.0
		queue_redraw()
		return
	if _spring != null:
		_spring.kill()
	_spring = create_tween()
	_spring.tween_method(_set_x, _x, 0.0, SPRING_S)


func _set_x(value: float) -> void:
	_x = value
	queue_redraw()


func _draw() -> void:
	var track := Rect2(Vector2.ZERO, size)
	draw_rect(track, TRACK_COLOR)
	if _x > 0.0:
		draw_rect(Rect2(0.0, 0.0, _x + HANDLE_W, size.y), FILL_COLOR)
	draw_rect(track, BORDER_COLOR, false, 1.0)
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var text_width := font.get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := floorf((size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5)
	draw_string(font, Vector2(floorf(HANDLE_W + (size.x - HANDLE_W - text_width) * 0.5), baseline), _label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, TEXT_COLOR)
	draw_rect(Rect2(_x, 0.0, HANDLE_W, size.y), HANDLE_COLOR)
	var chevron_width := font.get_string_size(CHEVRON, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(floorf(_x + (HANDLE_W - chevron_width) * 0.5), baseline), CHEVRON,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK_COLOR)

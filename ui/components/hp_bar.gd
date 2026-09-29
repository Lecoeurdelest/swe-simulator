@tool
class_name HpBar
extends Control
## A fighting-game health bar (GDD S08 and 9.1): 122x8 in the interview's bars band. Set max_value,
## then value. When the value drops, the colored fill jumps to it and a white ghost over the lost part
## trails down to it over GHOST_SEC; a rise just jumps. Changing max_value settles the bar with no
## ghost, so the start of an interview (and a resume, which rebuilds the scene) never animates.
## Widths are whole pixels (ARCHITECTURE 1.3), so the ghost shrinks 1 px at a time. The ghost's tween
## belongs to this node, so it stops while the tree is paused, like the interview's other tweens.
## @tool so the bar draws in the editor and tests can build one; it never animates in the editor.

const GHOST_SEC := 0.4  # GDD 9.1: "bars drain with a trailing white bar (0.4 s)"
const BACK_COLOR := Color(0.09411765, 0.078431375, 0.14509805)  # the palette's darkest ink
const GHOST_COLOR := Color.WHITE

@export var fill_color := Color(0.16, 0.68, 1.0):
	set(color):
		fill_color = color
		queue_redraw()
@export var max_value := 100.0:
	set(amount):
		max_value = amount
		_settle()
@export var value := 100.0:
	set(amount):
		var dropped := _shown(amount) < _shown(value)
		value = amount
		if dropped and is_inside_tree() and not Engine.is_editor_hint():
			_drain()
		else:
			_settle()

var _ghost := 100.0  # the ghost's right edge, in value units; never below the shown value
var _tween: Tween


## The fill's width in whole pixels. Anything above 0 shows at least 1 px, so a sliver of Doubt
## never reads as a K.O.
static func fill_px(amount: float, full: float, width: float) -> int:
	var px := floori(width)
	if amount <= 0.0 or full <= 0.0 or px <= 0:
		return 0
	return clampi(roundi(amount / full * px), 1, px)


## The ghost's right edge right now: equal to the shown value once it has settled.
func ghost_value() -> float:
	return _ghost


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK_COLOR)
	var fill := fill_px(_shown(value), max_value, size.x)
	var ghost := fill_px(_ghost, max_value, size.x)
	if ghost > fill:
		draw_rect(Rect2(fill, 0.0, ghost - fill, size.y), GHOST_COLOR)
	if fill > 0:
		draw_rect(Rect2(0.0, 0.0, fill, size.y), fill_color)


## The ghost starts where it is (mid-drain after a quick second hit) and eases in, so it lingers
## before it catches up.
func _drain() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_method(_set_ghost, _ghost, _shown(value), GHOST_SEC)
	queue_redraw()


func _settle() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_ghost = _shown(value)
	queue_redraw()


func _set_ghost(amount: float) -> void:
	_ghost = amount
	queue_redraw()


func _shown(amount: float) -> float:
	return clampf(amount, 0.0, maxf(max_value, 0.0))

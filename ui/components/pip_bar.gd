class_name PipBar
extends Control
## A row of energy pips (GDD 2.6: 6x8 each, 2 px apart): `filled` bright from the left, `locked`
## greyed at the right end, empty ones between. S03 greys the commute pips; the hub HUD can show
## the energy left of the day. Display only. Flat grey-box colors: the art pass swaps in the pip sprite.

const PIP := Vector2(6, 8)
const GAP := 2
const FILLED_COLOR := Color(0.99607843, 0.68235296, 0.20392157)  # the PrimaryButton amber
const EMPTY_COLOR := Color(0.54509807, 0.60784316, 0.7058824)
const LOCKED_COLOR := Color(0.22745098, 0.26666668, 0.4)

@export var total: int = 10:
	set(count):
		total = maxi(count, 0)
		update_minimum_size()
		queue_redraw()
@export var filled: int = 0:
	set(count):
		filled = count
		queue_redraw()
@export var locked: int = 0:
	set(count):
		locked = count
		queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func set_pips(total_pips: int, filled_pips: int, locked_pips: int) -> void:
	total = total_pips
	filled = filled_pips
	locked = locked_pips


func _get_minimum_size() -> Vector2:
	return Vector2(total * PIP.x + maxi(total - 1, 0) * GAP, PIP.y)


func _draw() -> void:
	var top := floorf((size.y - PIP.y) * 0.5)
	for i: int in total:
		var rect := Rect2(Vector2(i * (PIP.x + GAP), top), PIP)
		if i >= total - locked:
			draw_rect(rect, LOCKED_COLOR)
		elif i < filled:
			draw_rect(rect, FILLED_COLOR)
		else:
			draw_rect(rect.grow(-0.5), EMPTY_COLOR, false, 1.0)  # a 1 px outline on whole pixels

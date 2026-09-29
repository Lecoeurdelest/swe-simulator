@tool
class_name StatBar
extends Control
## A stat (KNOWLEDGE, EXPERIENCE or NETWORK, 0-100) as 5 segments (GDD 5.1): value / 20, rounded,
## filled from the left. The blocks are 7x7, 1 px apart, on the capitals of the monogram text line
## beside them, and the bar is one text line tall (13 px), so it fits a row of labels without changing
## its height. Used on the S03 background card, the Study app and the VS intro's plate.
## Flat grey-box colors: the art pass swaps in sprites. @tool so it draws in the editor and tests can
## build one.

const SEGMENTS := 5
const SEGMENT := Vector2(7, 7)
const GAP := 1
const LINE_HEIGHT := 13  # one line of monogram 16 (ARCHITECTURE 1.4)
const CAP_TOP := 4       # monogram's capitals start 4 px below the top of the line
const FILLED_COLOR := Color(0.99607843, 0.68235296, 0.20392157)  # the PrimaryButton amber
const EMPTY_COLOR := Color(0.09411765, 0.078431375, 0.14509805)  # the palette's darkest ink

@export_range(0, 100) var value: int = 0:
	set(amount):
		value = amount
		queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


static func filled_segments(amount: int) -> int:
	return clampi(roundi(amount * SEGMENTS / 100.0), 0, SEGMENTS)


func _get_minimum_size() -> Vector2:
	return Vector2(SEGMENTS * SEGMENT.x + (SEGMENTS - 1) * GAP, LINE_HEIGHT)


func _draw() -> void:
	var top := floorf((size.y - LINE_HEIGHT) * 0.5) + CAP_TOP
	var filled := filled_segments(value)
	for i: int in SEGMENTS:
		var at := Vector2(i * (SEGMENT.x + GAP), top)
		draw_rect(Rect2(at, SEGMENT), FILLED_COLOR if i < filled else EMPTY_COLOR)

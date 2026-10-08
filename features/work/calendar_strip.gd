@tool
class_name CalendarStrip
extends Control
## The calendar strip (GDD 5.14, 4.6): the next 60 days as a line with a tick for each thing coming: paydays, rent,
## the review, the lease, a ticket's deadline, an interview. Today is the left end. Information only. Each kind has
## its own tick height as well as its own color, so color is never the only signal (GDD 2.7). Flat grey-box look.

const HEIGHT := 12.0
const BASE_COLOR := Color(0.54509807, 0.60784316, 0.7058824)
const KINDS: Dictionary = {   # kind -> [tick height, color]
	"payday": [12.0, Color(0.38, 0.78, 0.35)],
	"rent": [6.0, Color(0.89411765, 0.23137255, 0.26666668)],
	"review": [12.0, Color(0.99607843, 0.68235296, 0.20392157)],
	"lease": [8.0, Color(0.74, 0.5, 0.9)],
	"deadline": [10.0, Color(1.0, 0.55, 0.2)],
	"interview": [12.0, Color(0.16, 0.68, 1.0)],
}

var _items: Array = []
var _days: int = 60


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, HEIGHT)


## items are WorkHud.calendar(): {offset, kind, label_id}; days is the strip's length (WorkConfig.calendar_days).
func set_items(items: Array, days: int) -> void:
	_items = items
	_days = maxi(days, 1)
	queue_redraw()


## The x of a tick: offset 1..days across the strip's width, whole pixels.
static func tick_x(offset: int, days: int, width: float) -> float:
	return floorf(clampf(float(offset) / float(maxi(days, 1)), 0.0, 1.0) * (width - 2.0))


func _draw() -> void:
	draw_rect(Rect2(0.0, HEIGHT - 2.0, size.x, 1.0), BASE_COLOR)
	for item: Dictionary in _items:
		var spec: Array = KINDS.get(String(item["kind"]), [6.0, BASE_COLOR])
		var h: float = spec[0]
		draw_rect(Rect2(tick_x(int(item["offset"]), _days, size.x), HEIGHT - 1.0 - h, 2.0, h), spec[1])

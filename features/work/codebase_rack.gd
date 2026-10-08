@tool
class_name CodebaseRack
extends Control
## The Codebase as a server rack of 10 LEDs (GDD 5.16, R-STAT-01): one turns red per 10 points. Display only. Flat
## grey-box colors until M5's art pass. Green is never the only signal: the red ones fill from the left, so the count
## reads by position as well as by color.

const LED := Vector2(4, 8)
const GAP := 2
const GOOD_COLOR := Color(0.38, 0.78, 0.35)
const RED_COLOR := Color(0.89411765, 0.23137255, 0.26666668)

@export var red: int = 0:
	set(count):
		red = clampi(count, 0, WorkHud.LED_COUNT)
		queue_redraw()


func _init() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	return Vector2(WorkHud.LED_COUNT * LED.x + (WorkHud.LED_COUNT - 1) * GAP, LED.y)


func _draw() -> void:
	var top := floorf((size.y - LED.y) * 0.5)
	for i: int in WorkHud.LED_COUNT:
		var color := RED_COLOR if i < red else GOOD_COLOR
		draw_rect(Rect2(Vector2(i * (LED.x + GAP), top), LED), color)

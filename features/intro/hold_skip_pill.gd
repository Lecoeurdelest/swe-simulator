class_name HoldSkipPill
extends Button
## "Hold to skip" (GDD S02, ARCHITECTURE 11.2): hold it for HOLD_S while the ring fills, then `held`
## fires once. Letting go early empties the ring, so a stray tap never skips the intro.
## A Button reports the press (button_down) and the release (button_up) even when the finger slides
## off it, and touches arrive as emulated mouse events, so this needs no touch code (GDD 2.8 rule 9).

signal held

const HOLD_S := 0.5              # GDD S02
const RING_X := 10.0             # the ring sits left of the right-aligned label
const RING_RADIUS := 5.0
const RING_WIDTH := 2.0
const RING_POINTS := 24
const TRACK_COLOR := Color(1.0, 1.0, 1.0, 0.25)
const FILL_COLOR := Color(0.996, 0.682, 0.204)   # the HeaderLabel amber

var _progress := 0.0             # 0 = an empty ring, 1 = held long enough
var _done := false


func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(cancel)
	set_process(false)


func _process(delta: float) -> void:
	_progress = minf(_progress + delta / HOLD_S, 1.0)
	queue_redraw()
	if _progress >= 1.0:
		set_process(false)
		_done = true
		held.emit()


## Empties the ring: the finger lifted early, or the app lost focus mid-hold.
func cancel() -> void:
	if _done:
		return
	set_process(false)
	_progress = 0.0
	queue_redraw()


func progress() -> float:
	return _progress


func _on_button_down() -> void:
	if _done:
		return
	_progress = 0.0
	set_process(true)


func _draw() -> void:
	var center := Vector2(RING_X, floorf(size.y * 0.5))
	draw_arc(center, RING_RADIUS, 0.0, TAU, RING_POINTS, TRACK_COLOR, RING_WIDTH)
	if _progress > 0.0:
		draw_arc(center, RING_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * _progress, RING_POINTS, FILL_COLOR, RING_WIDTH)

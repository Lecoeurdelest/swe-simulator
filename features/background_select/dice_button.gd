extends Button
## The S03 name dice button (GDD S03): a plain drawn die face until the art pass gives it a 16x16 icon.

const FACE := Vector2(14, 14)
const PIP := Vector2(2, 2)
const PIPS: Array[Vector2] = [Vector2(3, 3), Vector2(9, 3), Vector2(6, 6), Vector2(3, 9), Vector2(9, 9)]
const FACE_COLOR := Color(0.93, 0.93, 0.9)
const PIP_COLOR := Color(0.09411765, 0.078431375, 0.14509805)


## Runs after the Button has drawn its stylebox, so the die sits on top of it.
func _draw() -> void:
	var origin := ((size - FACE) * 0.5).floor()
	draw_rect(Rect2(origin, FACE), FACE_COLOR)
	for pip: Vector2 in PIPS:
		draw_rect(Rect2(origin + pip, PIP), PIP_COLOR)

class_name StatBar
extends Label
## PLACEHOLDER: the developer's Step 5 You-do replaces this with the real 5-segment bar (ROADMAP Step 5).
## Until then it is plain text, as the GDD S03 mockup draws it: "[###--]". Set value (a stat, 0-100)
## and value / 20, rounded, of the 5 segments fill (ARCHITECTURE 11.3).
## Keep `class_name StatBar` and `value` in your version: background_card.gd sets them.

const SEGMENTS := 5

@export_range(0, 100) var value: int = 0:
	set(amount):
		value = amount
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var filled := clampi(roundi(value * SEGMENTS / 100.0), 0, SEGMENTS)
	text = "[%s%s]" % ["#".repeat(filled), "-".repeat(SEGMENTS - filled)]

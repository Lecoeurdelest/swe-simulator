class_name HpBar
extends Control
## PLACEHOLDER: the developer's Step 4 You-do replaces this with the 0.4 s ghost-bar version (ROADMAP Step 4).
## Until then it is one plain bar (122x8 in the interview's bars band, GDD S08): set max_value, then
## value, and the bar jumps to it. No ghost bar, no tween.
## Keep `class_name HpBar`, `max_value`, `value` and `fill_color` in your version: interview.gd uses them.

@export var fill_color := Color(0.16, 0.68, 1.0):
	set(color):
		fill_color = color
		if is_node_ready():
			_apply_style()
@export var max_value := 100.0:
	set(amount):
		max_value = amount
		if is_node_ready():
			_bar.max_value = amount
@export var value := 100.0:
	set(amount):
		value = amount
		if is_node_ready():
			_bar.value = amount

@onready var _bar: ProgressBar = %Bar


func _ready() -> void:
	_bar.max_value = max_value
	_bar.value = value
	_apply_style()


## Flat grey-box colors: the art pass swaps in pixel 9-slices.
func _apply_style() -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.07, 0.07, 0.1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	_bar.add_theme_stylebox_override(&"background", background)
	_bar.add_theme_stylebox_override(&"fill", fill)

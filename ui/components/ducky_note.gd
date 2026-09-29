class_name DuckyNote
extends PanelContainer
## Placeholder Ducky tip note (GDD 2.7, 4.3, 8.1): 254 px wide, so the tip wraps at 40 columns
## (up to 4 lines, 120 characters). It never blocks input: every node in it is mouse_filter IGNORE
## (a coach mark makes the note itself take a tap: CoachMark). Set tip_text to a string from Content
## (already translated). The art pass replaces the look only.

const CLOSE_MARK := "x"  # stands in for the close icon until the art pass

@export_multiline var tip_text: String = "":
	set(value):
		tip_text = value
		if is_node_ready():
			_tip.text = value

## Shows the small close mark in the top-right corner (a note that closes on a tap).
@export var closable: bool = false:
	set(value):
		closable = value
		if is_node_ready():
			_close.visible = value

@onready var _name: Label = %Name
@onready var _tip: Label = %Tip
@onready var _close: Label = %Close


func _ready() -> void:
	_name.text = Content.text("naming", "mascot")
	_tip.text = tip_text
	_close.text = CLOSE_MARK
	_close.visible = closable

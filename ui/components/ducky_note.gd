class_name DuckyNote
extends PanelContainer
## Placeholder Ducky tip note (GDD 2.7, 4.3, 8.1): 254 px wide, so the tip wraps at 40 columns
## (up to 4 lines, 120 characters). It never blocks input: every node in it is mouse_filter IGNORE.
## Set tip_text to a string from Content (already translated). The art pass replaces the look only.

@export_multiline var tip_text: String = "":
	set(value):
		tip_text = value
		if is_node_ready():
			_tip.text = value

@onready var _name: Label = %Name
@onready var _tip: Label = %Tip


func _ready() -> void:
	_name.text = Content.text("naming", "mascot")
	_tip.text = tip_text

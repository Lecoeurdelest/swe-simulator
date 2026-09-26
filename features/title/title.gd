extends Control
## Step 1 stub of the Title screen (GDD S01): proves settings, autoloads and the scale guard.
## Resize the desktop window and watch "game" change. Replaced by the real Title in Step 3.

@onready var _info: Label = %Info


func _process(_delta: float) -> void:
	var win := get_tree().root
	var mode := "integer" if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER else "fractional"
	_info.text = "SWE Simulator %s\nwindow %s\ngame %s (%s)\nsave file: %s" % [
		ProjectSettings.get_setting("application/config/version"), win.size,
		Vector2i(win.get_visible_rect().size), mode, SaveIO.exists()]


func handle_back() -> bool:
	return false  # nothing to close here: Device emits back_unhandled (the "Quit?" dialog arrives in Step 3)

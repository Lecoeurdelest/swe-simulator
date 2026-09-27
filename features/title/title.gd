extends Control
## Step 1 stub of the Title screen (GDD S01): proves settings, autoloads and the scale guard.
## Resize the desktop window and watch "game" change. Replaced by the real Title in Step 3.
## Step 2: a debug-only "Device check" button opens features/dev/device_check.tscn as an overlay.

## Loaded by path when pressed, never preloaded: features/dev/ is excluded from release exports.
const DEVICE_CHECK_PATH := "res://features/dev/device_check.tscn"

var _device_check: Control = null

@onready var _info: Label = %Info
@onready var _device_check_button: Button = %DeviceCheckButton


func _ready() -> void:
	_device_check_button.visible = OS.is_debug_build() and ResourceLoader.exists(DEVICE_CHECK_PATH)
	_device_check_button.pressed.connect(_open_device_check)


func _process(_delta: float) -> void:
	var win := get_tree().root
	var mode := "integer" if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER else "fractional"
	_info.text = "SWE Simulator %s\nwindow %s\ngame %s (%s)\nsave file: %s" % [
		ProjectSettings.get_setting("application/config/version"), win.size,
		Vector2i(win.get_visible_rect().size), mode, SaveIO.exists()]


func handle_back() -> bool:
	if _device_check != null:
		return bool(_device_check.call(&"handle_back"))  # the device check counts Back presses
	return false  # nothing to close here: Device emits back_unhandled (the "Quit?" dialog arrives in Step 3)


func _open_device_check() -> void:
	if _device_check != null:
		return
	_device_check = (load(DEVICE_CHECK_PATH) as PackedScene).instantiate() as Control
	_device_check.connect(&"closed", _close_device_check)
	add_child(_device_check)  # full rect, mouse_filter STOP: covers and blocks the title while open


func _close_device_check() -> void:
	_device_check.queue_free()
	_device_check = null

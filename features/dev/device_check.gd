extends Control
## Debug-only device check (ROADMAP Step 2, task 8): answers the questions no desk test can.
## The title stub opens it as an overlay (debug builds only). It is not a GameFlow phase, and
## features/dev/ is excluded from release exports.

signal closed

const ROW_COUNT := 20
const ROW_HEIGHT := 36

var _pressed: int = 0
var _last_row: int = 0
var _scrolled: int = 0
var _back: int = 0
var _haptics: int = 0
var _paused: int = 0
var _resumed: int = 0
var _focus_out: int = 0
var _rows_pass: bool = false

@onready var _readout: Label = %Readout
@onready var _counters: Label = %Counters
@onready var _safe: SafeAreaMargin = %SafeArea
@onready var _list: ScrollContainer = %List
@onready var _rows: VBoxContainer = %Rows
@onready var _haptic_10: Button = %Haptic10
@onready var _haptic_40: Button = %Haptic40
@onready var _row_mode: Button = %RowMode
@onready var _back_button: Button = %Back
@onready var _close_button: Button = %Close


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # counters keep working if something pauses the tree
	# Saving a scene bakes the project default into scroll_deadzone; re-read it so this screen tests the setting.
	_list.scroll_deadzone = int(ProjectSettings.get_setting("gui/common/default_scroll_deadzone"))
	for i: int in ROW_COUNT:
		var row := Button.new()
		row.text = "Row %02d" % (i + 1)
		row.custom_minimum_size.y = ROW_HEIGHT
		row.pressed.connect(_on_row_pressed.bind(i + 1))
		_rows.add_child(row)
	_list.scroll_started.connect(_on_scroll_started)  # touch drags only (desktop: emulated from the mouse)
	_haptic_10.pressed.connect(_on_haptic.bind(10))
	_haptic_40.pressed.connect(_on_haptic.bind(40))
	_row_mode.pressed.connect(_on_row_mode_pressed)
	_back_button.pressed.connect(Device.handle_back)  # same chain as Esc / Android Back: Device -> Title -> handle_back() here
	_close_button.pressed.connect(closed.emit)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_paused += 1
		NOTIFICATION_APPLICATION_RESUMED:
			_resumed += 1
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focus_out += 1


func _process(_delta: float) -> void:
	var win := get_tree().root
	var game := Vector2i(win.get_visible_rect().size)
	var stretch := "integer" if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER else "fractional"
	var zoom := minf(float(win.size.x) / game.x, float(win.size.y) / game.y)
	var inset := Device.safe_insets()
	var safe_px := DisplayServer.get_display_safe_area()
	_readout.text = "\n".join([
		"%s %s (%s)" % [OS.get_name(), OS.get_model_name(), "debug" if OS.is_debug_build() else "release"],
		"window %dx%d" % [win.size.x, win.size.y],
		"game %dx%d %s x%.2f" % [game.x, game.y, stretch, zoom],
		"insets L%.1f T%.1f R%.1f B%.1f" % [inset.x, inset.y, inset.z, inset.w],
		"margin L%d T%d R%d B%d" % [
			_safe.get_theme_constant(&"margin_left"), _safe.get_theme_constant(&"margin_top"),
			_safe.get_theme_constant(&"margin_right"), _safe.get_theme_constant(&"margin_bottom")],
		"safe px %d,%d %dx%d" % [safe_px.position.x, safe_px.position.y, safe_px.size.x, safe_px.size.y],
		"haptics %s  deadzone %d" % ["on" if Device.haptics_enabled else "off", _list.scroll_deadzone],
	])
	_counters.text = "\n".join([
		"pressed %d (row %d)  scrolled %d (y %d)" % [_pressed, _last_row, _scrolled, _list.scroll_vertical],
		"back %d  haptic %d" % [_back, _haptics],
		"paused %d  resumed %d  focus_out %d" % [_paused, _resumed, _focus_out],
	])


## Called by the title's handle_back() while this overlay is open: count the press and keep it.
func handle_back() -> bool:
	_back += 1
	return true


func _on_row_pressed(row: int) -> void:
	_pressed += 1
	_last_row = row


func _on_scroll_started() -> void:
	_scrolled += 1


func _on_haptic(ms: int) -> void:
	_haptics += 1
	Device.haptic(ms)  # a no-op on desktop


## ARCHITECTURE 10.3 #7 / 18.1 #1: compare STOP rows (the default) with the PASS fallback on the phone.
func _on_row_mode_pressed() -> void:
	_rows_pass = not _rows_pass
	for row: Node in _rows.get_children():
		(row as Control).mouse_filter = Control.MOUSE_FILTER_PASS if _rows_pass else Control.MOUSE_FILTER_STOP
	_row_mode.text = "Rows PASS" if _rows_pass else "Rows STOP"

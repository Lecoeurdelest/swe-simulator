extends Node
## Autoload "Device": phone glue. Scale guard (GDD 2.2), safe area (2.9), Back button (4.4), haptics (9.3).

signal layout_changed    # game-area size or scale mode changed: SafeAreaMargin re-applies
signal back_unhandled    # Back pressed and the current scene didn't use it: Title shows "Quit?"

const BASE := Vector2(480, 270)

var haptics_enabled: bool = true
var _last_window_size := Vector2i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	haptics_enabled = bool(GameState.setting("options", "haptics", true))
	_check_window()


## size_changed doesn't always fire on desktop resizes, so compare every frame (one Vector2i compare).
func _process(_delta: float) -> void:
	_check_window()


func _check_window() -> void:
	var now := get_tree().root.size
	if now != _last_window_size:
		_last_window_size = now
		_update_scale_mode()


## Square pixels that fill the screen: integer scale, and the game area grows to use the leftover.
## Falls back to fractional when integer would waste over 20% (720p-class phones). Tech-verified.
func _update_scale_mode() -> void:
	var win := get_tree().root
	var w := Vector2(win.size)
	if w.x <= 0.0 or w.y <= 0.0:
		return
	var exact := minf(w.x / BASE.x, w.y / BASE.y)
	var s := floorf(exact)
	var stretch := Window.CONTENT_SCALE_STRETCH_INTEGER
	var game_size := Vector2i(BASE)
	if s >= 1.0 and s / exact >= 0.8:
		game_size = Vector2i(floori(w.x / s), floori(w.y / s))  # 2556x1179 -> 639x294 @4x
	else:
		stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL       # 1600x720 -> 600x270 @2.67x
	if win.content_scale_stretch != stretch or win.content_scale_size != game_size:
		win.content_scale_stretch = stretch
		win.content_scale_size = game_size
		layout_changed.emit()


## Safe-area insets in GAME pixels (left, top, right, bottom); zero on desktop.
## In viewport stretch mode get_final_transform() is the identity, so convert by hand (tech-verified).
func safe_insets() -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var win := get_tree().root
	var game := win.get_visible_rect().size
	var px := Vector2(win.size)
	var s := minf(px.x / game.x, px.y / game.y)
	if win.content_scale_stretch == Window.CONTENT_SCALE_STRETCH_INTEGER:
		s = maxf(floorf(s), 1.0)
	var origin := ((px - game * s) * 0.5).round()  # letterbox offset
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var tl := (safe.position - origin) / s
	var br := (safe.end - origin) / s
	return Vector4(maxf(tl.x, 0.0), maxf(tl.y, 0.0), maxf(game.x - br.x, 0.0), maxf(game.y - br.y, 0.0))


# ---------- Back ----------

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:  # Android Back (needs quit_on_go_back = false)
		handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if not OS.has_feature("mobile") and event.is_action_pressed(&"ui_cancel"):  # Esc = Back on desktop
		get_viewport().set_input_as_handled()
		handle_back()


## The current scene gets the first chance: close a modal, flip a card back, skip the cutscene, open pause.
func handle_back() -> void:
	if SceneRouter.busy:
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method(&"handle_back") and bool(scene.call(&"handle_back")):
		return
	back_unhandled.emit()


# ---------- haptics ----------

func haptic(ms: int = 10) -> void:
	if haptics_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)  # Android: enable permissions/vibrate in the export preset

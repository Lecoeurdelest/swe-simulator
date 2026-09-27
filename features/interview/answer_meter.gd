class_name AnswerMeter
extends Control
## The one-tap "stop the needle" Answer Meter (GDD 5.8.4). Called TimingBar in earlier drafts.
## Make it cover the whole screen (full rect) so a tap anywhere counts; it draws the bar at the y the scene
## passes to set_bar_y() (the S08 meter row, section 11.6), or 40 px above its bottom edge until then.
## Positions are fractions of the bar (0..1). The scene adds the zone labels.

signal resolved(input_quality: float)
signal zone_jumped  # startup "PIVOT!"

const BAR_HEIGHT := 10.0

var _cfg: BalanceConfig
var _speed := 0.6        # bar-widths per second (TierData.needle_speed, x1.15 when Tired)
var _h := 0.1            # NAILED IT half-width
var _c := 0.5            # zone centre
var _t := 0.0            # distance travelled, in bar-widths
var _elapsed := 0.0
var _jump_at := -1.0     # seconds; negative = no pivot
var _relaxed := false
var _done := true
var _rng: RandomNumberGenerator
var _bar_y := -1.0       # Step 4: the meter row's y in this Control; negative = 40 px above the bottom


func _ready() -> void:
	set_process(false)  # tech-verified: _process would otherwise run (and auto-miss) before start()
	mouse_filter = Control.MOUSE_FILTER_STOP


func start(cfg: BalanceConfig, speed: float, half_width: float, zone_jumps: bool, relaxed: bool, rng: RandomNumberGenerator) -> void:
	_cfg = cfg
	_speed = speed
	_h = half_width
	_relaxed = relaxed
	_rng = rng
	_c = rng.randf_range(_h, 1.0 - _h)
	_jump_at = rng.randf_range(cfg.jump_window_min_s, cfg.jump_window_max_s) if zone_jumps else -1.0
	_t = 0.0
	_elapsed = 0.0
	_done = false
	set_process(true)
	queue_redraw()


func needle() -> float:
	return pingpong(_t, 1.0)


## Step 4: the zone as (centre, half-width), so the scene can place the zone labels.
func zone() -> Vector2:
	return Vector2(_c, _h)


## Step 4 (ARCHITECTURE 11.6): the scene passes the meter row's y, in this Control's coordinates, on
## `resized` and Device.layout_changed, so the bar sits above the tap pad and never under the thumb.
func set_bar_y(y: float) -> void:
	_bar_y = y
	queue_redraw()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	_t += delta * _speed
	if _jump_at >= 0.0 and _elapsed >= _jump_at:
		_jump_at = -1.0
		_c = _rng.randf_range(_h, 1.0 - _h)
		zone_jumped.emit()
	if _t >= 2.0 * _cfg.max_round_trips:  # one round trip = there and back = 2 bar-widths
		_resolve(-1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _done:
		return
	accept_event()
	if _elapsed * 1000.0 >= _cfg.input_lock_ms:  # the tap that finished Dana's line can't stop the needle
		_resolve(needle())


func _resolve(tap: float) -> void:
	_done = true
	set_process(false)
	var q := _cfg.input_miss if tap < 0.0 else Odds.input_quality(_cfg, tap, _c, _h)
	if _relaxed:
		q = _cfg.relaxed_input  # Relaxed Timing setting: always 0.9
	Device.haptic(20 if q >= _cfg.input_perfect else 10)
	resolved.emit(q)


func _draw() -> void:
	if _cfg == null:
		return
	var w := float(_cfg.answer_meter_width_px)
	var origin := Vector2(floorf((size.x - w) * 0.5), floorf(_bar_y if _bar_y >= 0.0 else size.y - 40.0))
	draw_rect(Rect2(origin, Vector2(w, BAR_HEIGHT)), Color("#1d2b53"))                                        # Rambling / Overthinking
	draw_rect(Rect2(origin + Vector2(floorf((_c - 2.0 * _h) * w), 0), Vector2(floorf(4.0 * _h * w), BAR_HEIGHT)), Color("#ffa300"))  # Vague
	draw_rect(Rect2(origin + Vector2(floorf((_c - _h) * w), 0), Vector2(floorf(2.0 * _h * w), BAR_HEIGHT)), Color("#00e436"))        # NAILED IT
	draw_rect(Rect2(origin + Vector2(floorf(needle() * w) - 1.0, -3.0), Vector2(2.0, BAR_HEIGHT + 6.0)), Color.WHITE)

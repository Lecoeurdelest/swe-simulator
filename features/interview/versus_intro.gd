class_name VersusIntro
extends Control
## The VS screen (GDD S07, ARCHITECTURE 11.5). The interview instances it and calls play(company_id, tier),
## then waits for `finished`. The AnimationPlayer's "intro" clip holds the timing table, so you can retime
## it in the editor; its method track calls slam() at 0.35 s. BalanceConfig.vs_duration_s stretches the
## whole clip to that length. Tap anywhere (or Back) skips: after vs_min_view_s on the first interview of
## a run, at once after that. Your side comes from GameState.run.

signal finished

const CLIP := &"intro"
const HIT_STOP_S := 0.1        # GDD 9.1: the slam's 100 ms hit-stop
const SHAKE_PX := 4.0          # GDD 9.1: a 4 px whole-pixel shake
const SHAKE_STEP_S := 0.02
const SLAM_HAPTIC_MS := 40     # GDD 9.3
const STAT_SEGMENTS := 5       # GDD 5.1: a stat shows as 5 segments, value / 20, rounded
const STAT_LABEL_WIDTH := 10   # "EXPERIENCE", so the three bars line up
const NAME_BIG_MAX := 9        # GDD 2.7: the plate fits 9 characters at Press Start 2P 16, longer names use 8
const NAME_BIG := 16
const NAME_SMALL := 8
const DIAGONAL_RISE := 30.0    # ARCHITECTURE 11.5: the split runs across the middle, about y 210-270 of 480
## Grey-box stand-ins until the art pass (GDD 2.5): the company half and the interview stage by tier,
## your half by hoodie (backgrounds.json "hoodie").
const TIER_COLORS: Dictionary = {
	"startup": Color(0.0, 0.53, 0.32), "mid": Color(0.37, 0.34, 0.31), "big": Color(0.11, 0.17, 0.33),
}
const HOODIE_COLORS: Dictionary = {
	"teal": Color(0.0, 0.5, 0.5), "maroon": Color(0.49, 0.15, 0.33), "mustard": Color(0.8, 0.62, 0.15),
}
const FALLBACK_COLOR := Color(0.37, 0.34, 0.31)

var _playing := false
var _slammed := false
var _elapsed := 0.0
var _min_view_s := 0.0
var _company_id := ""          # the art pass puts this company's background behind Dana
var _top_color := FALLBACK_COLOR
var _bottom_color := FALLBACK_COLOR

@onready var _anim: AnimationPlayer = %AnimationPlayer
@onready var _shaker: Control = %Shaker
@onready var _split: Control = %Split
@onready var _dana_name: Label = %DanaName
@onready var _dana_title: Label = %DanaTitle
@onready var _dana_stats: Label = %DanaStats
@onready var _dana_moves: Label = %DanaMoves
@onready var _player_name: Label = %PlayerName
@onready var _player_nickname: Label = %PlayerNickname
@onready var _player_stats: Label = %PlayerStats
@onready var _vs_label: Label = %VSLabel
@onready var _banner: Label = %Banner


func _ready() -> void:
	hide()
	set_process(false)
	_split.draw.connect(_draw_split)
	_split.resized.connect(_split.queue_redraw)
	_anim.animation_finished.connect(_on_animation_finished)


static func tier_color(tier: String) -> Color:
	return TIER_COLORS.get(tier, FALLBACK_COLOR)


static func hoodie_color(hoodie: String) -> Color:
	return HOODIE_COLORS.get(hoodie, FALLBACK_COLOR)


func play(company_id: String, tier: String) -> void:
	var run: RunState = GameState.run
	var cfg: BalanceConfig = Content.balance
	var bg_entry: Dictionary = Content.entries("backgrounds").get(run.background_id, {})
	_company_id = company_id
	_top_color = tier_color(tier)
	_bottom_color = hoodie_color(str(bg_entry.get("hoodie", "")))
	_set_name(_dana_name, Content.text("naming", "interviewer").to_upper())
	_dana_title.text = Content.text("barks", "dana_title_" + tier)
	_dana_stats.text = "\n".join(PackedStringArray([Content.text("barks", "vs_dana_stat_1"),
		Content.text("barks", "vs_dana_stat_2"), Content.text("barks", "vs_dana_stat_3")]))
	_dana_moves.text = Content.text("barks", "vs_dana_moves")
	_set_name(_player_name, run.player_name.to_upper())
	_player_nickname.text = Content.field("backgrounds", run.background_id, "vs_nickname")
	_player_stats.text = "\n".join(PackedStringArray([_stat_bar(Content.text("barks", "ui_stat_knw"), run.stat("knw")),
		_stat_bar(Content.text("barks", "ui_stat_exp"), run.stat("exp")),
		_stat_bar(Content.text("barks", "ui_stat_net"), run.stat("net"))]))
	_vs_label.text = Content.text("barks", "vs_versus")
	_banner.text = Content.text("barks", "vs_banner_" + tier)
	_min_view_s = cfg.vs_min_view_s if run.interviews_taken == 0 else 0.0
	_elapsed = 0.0
	_slammed = false
	_playing = true
	_shaker.position = Vector2.ZERO
	_split.queue_redraw()
	show()
	set_process(true)
	var clip_length := _anim.get_animation(CLIP).length
	_anim.speed_scale = clip_length / cfg.vs_duration_s if cfg.vs_duration_s > 0.0 else 1.0
	_anim.play(CLIP)
	_anim.seek(0.0, true)  # apply the 0.00 s keys now, so the first frame never shows the end state


func is_playing() -> bool:
	return _playing


## A tap or Back: skips once the minimum view time has passed. Returns true if it skipped.
func try_skip() -> bool:
	if not _playing or _elapsed < _min_view_s:
		return false
	_finish()
	return true


## Called by the clip's method track at 0.35 s: the hit-stop, the shake and the haptic (ARCHITECTURE 11.5).
## The sound effect arrives with the audio step.
func slam() -> void:
	if not _playing or _slammed:
		return
	_slammed = true  # resuming from the key's own time must not slam twice
	Device.haptic(SLAM_HAPTIC_MS)
	_shake()
	_anim.pause()
	await get_tree().create_timer(HIT_STOP_S, false).timeout
	if _playing and not _anim.is_playing():
		_anim.play()


func _process(delta: float) -> void:
	_elapsed += delta


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	try_skip()


func _finish() -> void:
	if not _playing:
		return
	_playing = false
	set_process(false)
	_anim.stop()
	_shaker.position = Vector2.ZERO
	hide()
	finished.emit()


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == CLIP:
		_finish()


## Whole-pixel steps only (ARCHITECTURE 1.3): no tweened in-between positions.
func _shake() -> void:
	var tween := create_tween()
	for offset: Vector2 in [Vector2(SHAKE_PX, 0.0), Vector2(-SHAKE_PX, 0.0), Vector2(0.0, SHAKE_PX), Vector2(0.0, -SHAKE_PX), Vector2.ZERO]:
		tween.tween_callback(_shaker.set_position.bind(offset))
		tween.tween_interval(SHAKE_STEP_S)


func _draw_split() -> void:
	var area := _split.size
	var middle := floorf(area.y * 0.5)
	var left := Vector2(0.0, middle + DIAGONAL_RISE)
	var right := Vector2(area.x, middle - DIAGONAL_RISE)
	_split.draw_colored_polygon(PackedVector2Array([Vector2.ZERO, Vector2(area.x, 0.0), right, left]), _top_color)
	_split.draw_colored_polygon(PackedVector2Array([left, right, area, Vector2(0.0, area.y)]), _bottom_color)
	_split.draw_line(left, right, Color.WHITE, 2.0)


func _set_name(label: Label, text: String) -> void:
	label.text = text
	label.add_theme_font_size_override(&"font_size", NAME_BIG if text.length() <= NAME_BIG_MAX else NAME_SMALL)


static func _stat_bar(label: String, value: int) -> String:
	var filled := clampi(roundi(value / 20.0), 0, STAT_SEGMENTS)
	return "%s [%s%s]" % [label.rpad(STAT_LABEL_WIDTH), "#".repeat(filled), "-".repeat(STAT_SEGMENTS - filled)]

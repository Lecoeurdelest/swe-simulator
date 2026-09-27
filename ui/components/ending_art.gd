class_name EndingArt
extends Control
## The ending cards' 254x140 illustration (GDD S11, S12, 2.6) and its stamp. Grey-box colour blocks
## until the art pass: a sky, a floor and your bust in your hoodie colour. The stamp (HIRED!, PLAN B)
## sits on its own solid panel, so its text never lies on the picture (GDD 2.7). The ending instances
## this, calls setup(), then slam(); `landed` fires once the stamp is down.

signal landed

const STAMP_BIG_SCALE := 2.0   # the stamp drops in at a whole multiple of its size (GDD 2.7), then 1x
const STAMP_BIG_S := 0.05
const SHAKE_PX := 4.0          # GDD 9.1: a 4 px whole-pixel shake, on the picture only
const SHAKE_STEP_S := 0.02
const SLAM_HAPTIC_MS := 40     # GDD 9.3, as the VS slam

@onready var _shaker: Control = %Shaker
@onready var _sky: ColorRect = %Sky
@onready var _bust: ColorRect = %Bust
@onready var _stamp: Control = %Stamp
@onready var _stamp_label: Label = %StampLabel


func _ready() -> void:
	_stamp.modulate.a = 0.0


## Texts come from Content (already translated).
func setup(stamp_text: String, sky: Color, bust: Color) -> void:
	_stamp_label.text = stamp_text
	_sky.color = sky
	_bust.color = bust


func slam() -> void:
	_stamp.pivot_offset = (_stamp.size * 0.5).floor()
	_stamp.scale = Vector2.ONE * STAMP_BIG_SCALE
	_stamp.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(STAMP_BIG_S)
	tween.tween_callback(_land)


## Whole-pixel steps only (ARCHITECTURE 1.3): no tweened in-between positions.
func _land() -> void:
	_stamp.scale = Vector2.ONE
	Device.haptic(SLAM_HAPTIC_MS)
	var tween := create_tween()
	for offset: Vector2 in [Vector2(SHAKE_PX, 0.0), Vector2(-SHAKE_PX, 0.0), Vector2(0.0, SHAKE_PX), Vector2(0.0, -SHAKE_PX), Vector2.ZERO]:
		tween.tween_callback(_shaker.set_position.bind(offset))
		tween.tween_interval(SHAKE_STEP_S)
	tween.tween_callback(landed.emit)

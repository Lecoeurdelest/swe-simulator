extends Control
## The intro cutscene (GDD S02, ARCHITECTURE 11.2) as text slides, before the art pass. The panels of
## cutscene.json play in "order" (CutscenePlan). Each shows a grey placeholder picture in the 270x480
## frame that pans slowly over the panel's "seconds", and types its captions one by one in the dialogue
## box. A tap finishes the caption being typed; the next tap shows the next caption, so a tap never skips
## everything. Skipping is the "Hold to skip" pill (held 0.5 s), Back or desktop Esc. Every way out,
## the tap after the last caption included, calls GameState.finish_intro() once, which sets intro_seen.
## A {"style": "title"} caption smashes to black and slams the game's title in on its own panel.
## Losing focus pauses the pan, the typewriter and a hold in progress (ARCHITECTURE 9).

## Grey-box only: the placeholder is this much wider than the frame, so the pan shows. Real art sets
## its own pan by its size (CutscenePlan.pan_path).
const PLACEHOLDER_PAN_PX := 24
const PLACEHOLDER_CELL_PX := 24   # a checkerboard, so the motion is visible on flat grey
const PLACEHOLDER_SHADES: Array[float] = [0.24, 0.3, 0.36]
const PLACEHOLDER_CONTRAST := 0.05
const TITLE_SLAM_SCALE := 2.0     # the title drops in at a whole multiple of its size (GDD 2.7), then 1x
const TITLE_SLAM_S := 0.05
const TITLE_HAPTIC_MS := 40       # GDD 9.3, as the VS slam
## Debug-only panel readout, English on purpose (not player text, so not in CONTENT.md).
const DEBUG_READOUT := "%s  caption %d/%d"

var _panels: Array[Dictionary] = []
var _panel := -1                  # index into _panels; -1 before the first panel
var _caption := -1                # index into the panel's captions
var _typing := false
var _leaving := false             # finish_intro() was called: the scene is on its way out
var _paused := false              # the app lost focus
var _hinted := false              # the player has advanced once, so "Tap to continue" is gone for good
var _pan_tween: Tween
var _type_tween: Tween

@onready var _frame: Control = %Frame
@onready var _picture: TextureRect = %Picture
@onready var _debug_readout: Label = %DebugReadout
@onready var _title_card: Control = %TitleCard
@onready var _title_label: Label = %TitleLabel
@onready var _dialogue_box: Control = %DialogueBox
@onready var _name_tab: Label = %NameTab
@onready var _line: Label = %Line
@onready var _tap_hint: Control = %TapHintPanel   # on its own panel: text never sits on the picture
@onready var _skip_pill: HoldSkipPill = %SkipPill


func _ready() -> void:
	_panels = CutscenePlan.panels(Content.entries("cutscene"))
	_frame.custom_minimum_size = _frame_size()
	_skip_pill.text = Content.text("barks", "ui_skip_hold")
	(%TapHint as Label).text = Content.text("barks", "ui_tap_to_continue")
	_skip_pill.held.connect(_leave)
	_title_card.resized.connect(_center_title_pivot)
	_debug_readout.visible = OS.is_debug_build()
	# modulate, not hide(): hidden, the card and the box keep their place, so nothing jumps when they
	# come and go, and the card has its size for the slam's pivot
	_title_card.modulate.a = 0.0
	_dialogue_box.modulate.a = 0.0
	_tap_hint.hide()
	_start.call_deferred()


## ARCHITECTURE 9: Back (desktop Esc, Android Back LATER) skips the intro.
func handle_back() -> bool:
	_leave()
	return true


## A tap that no control took (every container here ignores the mouse; the pill keeps its own press).
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if _leaving or _caption < 0:
		return  # still fading in: the first caption hasn't started
	if _typing:
		_finish_typing()
	else:
		_hinted = true
		_tap_hint.hide()
		_next_caption()


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_set_paused(true)
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_set_paused(false)


# ---------- the flow ----------

## The fade-in reveals the first picture; its first caption types once the fade is over.
func _start() -> void:
	if _panels.is_empty():
		_leave()  # no cutscene.json: nothing to show, straight to Background select
		return
	_show_picture(0)
	if SceneRouter.busy:
		await SceneRouter.transition_finished
	if not _leaving:
		_next_caption()


func _show_panel(index: int) -> void:
	_show_picture(index)
	_next_caption()


## The panel's picture, panning over its "seconds". Its captions start at _next_caption().
func _show_picture(index: int) -> void:
	_panel = index
	_caption = -1
	var panel: Dictionary = _panels[index]
	_debug_readout.text = str(panel["id"])
	_picture.texture = _placeholder(index)
	_picture.size = _picture.texture.get_size()
	_picture.show()
	_title_card.modulate.a = 0.0
	var path := CutscenePlan.pan_path(_picture.size, _frame_size())
	_set_pan(path[0])
	_kill(_pan_tween)
	_pan_tween = create_tween()
	_pan_tween.tween_method(_set_pan, path[0], path[1], maxf(float(panel["seconds"]), 0.01)) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _paused:
		_pan_tween.pause()


## The panel's next caption, else the next panel, else the end of the intro.
func _next_caption() -> void:
	var captions: Array = _panels[_panel]["captions"]
	_caption += 1
	if _caption >= captions.size():
		if _panel + 1 < _panels.size():
			_show_panel(_panel + 1)
		else:
			_leave()
		return
	var caption: Dictionary = captions[_caption]
	_debug_readout.text = DEBUG_READOUT % [_panels[_panel]["id"], _caption + 1, captions.size()]
	if caption["style"] == CutscenePlan.STYLE_TITLE:
		_show_title(str(caption["text"]))
	else:
		_type(caption)


## Every way out goes through here, once.
func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	_kill(_pan_tween)
	_kill(_type_tween)
	_skip_pill.disabled = true
	GameState.finish_intro()


# ---------- captions (ARCHITECTURE 10.4) ----------

## Types the caption out at typewriter_cps under the speaker's name ("" = narration, no name).
func _type(caption: Dictionary) -> void:
	var speaker := str(caption["speaker"])
	_name_tab.visible = not speaker.is_empty()
	_name_tab.text = tr(speaker).to_upper()
	var text := tr(str(caption["text"]))
	_line.text = text
	_line.visible_ratio = 0.0
	_dialogue_box.modulate.a = 1.0
	_kill(_type_tween)
	var cps := Content.balance.typewriter_cps
	if cps <= 0.0:
		_typing = true
		_finish_typing()
		return
	_typing = true
	_type_tween = create_tween()
	_type_tween.tween_property(_line, ^"visible_ratio", 1.0, text.length() / cps)
	_type_tween.finished.connect(_finish_typing)
	if _paused:
		_type_tween.pause()


func _finish_typing() -> void:
	if not _typing:
		return
	_typing = false
	_kill(_type_tween)
	_line.visible_ratio = 1.0
	_tap_hint.visible = not _hinted


## The title card: the picture cuts to black, the dialogue box goes, and the title drops in at 2x.
func _show_title(text: String) -> void:
	_typing = false
	_kill(_pan_tween)
	_picture.hide()
	_dialogue_box.modulate.a = 0.0
	_title_label.text = tr(text)
	_title_card.modulate.a = 1.0
	_center_title_pivot()
	_title_card.scale = Vector2.ONE * TITLE_SLAM_SCALE
	var slam := create_tween()
	slam.tween_interval(TITLE_SLAM_S)
	slam.tween_callback(_land_title)


func _land_title() -> void:
	_title_card.scale = Vector2.ONE
	Device.haptic(TITLE_HAPTIC_MS)


func _center_title_pivot() -> void:
	_title_card.pivot_offset = (_title_card.size * 0.5).floor()


# ---------- the picture ----------

## Whole pixels only (ARCHITECTURE 1.3).
func _set_pan(at: Vector2) -> void:
	_picture.position = at.round()


## The frame is the base resolution (INV-19): on taller phones it sits centred on the near-black.
func _frame_size() -> Vector2:
	return Vector2(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
		int(ProjectSettings.get_setting("display/window/size/viewport_height")))


## A grey checkerboard stand-in for panel `index`'s art, one shade per panel so the cuts show.
func _placeholder(index: int) -> Texture2D:
	var size := Vector2i(_frame_size()) + Vector2i(PLACEHOLDER_PAN_PX, 0)
	var shade: float = PLACEHOLDER_SHADES[index % PLACEHOLDER_SHADES.size()]
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGB8)
	image.fill(Color(shade, shade, shade))
	var light := Color(shade + PLACEHOLDER_CONTRAST, shade + PLACEHOLDER_CONTRAST, shade + PLACEHOLDER_CONTRAST)
	for row: int in ceili(size.y / float(PLACEHOLDER_CELL_PX)):
		for col: int in ceili(size.x / float(PLACEHOLDER_CELL_PX)):
			if (row + col) % 2 == 0:
				image.fill_rect(Rect2i(col * PLACEHOLDER_CELL_PX, row * PLACEHOLDER_CELL_PX,
					PLACEHOLDER_CELL_PX, PLACEHOLDER_CELL_PX), light)
	return ImageTexture.create_from_image(image)


# ---------- focus loss ----------

func _set_paused(on: bool) -> void:
	if on == _paused:
		return
	_paused = on
	for tween: Tween in [_pan_tween, _type_tween]:
		if tween != null and tween.is_valid():
			if on:
				tween.pause()
			else:
				tween.play()
	if on:
		_skip_pill.cancel()  # the finger can't still be down when the app comes back


func _kill(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()

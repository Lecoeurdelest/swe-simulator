class_name BackgroundCard
extends MarginContainer
## The S03 background card (GDD S03, ARCHITECTURE 11.3): numbers from BackgroundData, text from
## backgrounds.json. It is also the S03 swipe surface, one of the two Controls that read raw touch
## (INV-14): this root stays put and reads the finger, the Panel inside follows it and tilts.

## +1 = swiped left (the next background), -1 = swiped right (the previous one).
signal swiped(step: int)

const MAX_TILT_DEG := 6.0     # like the job card (ARCHITECTURE 11.4)
const SETTLE_SEC := 0.12
const SLIDE_IN_PX := 24.0
const PERK_MARK := "+"        # stand-ins for the perk and flaw icons until the art pass
const FLAW_MARK := "-"

## A drag longer than a quarter of the base width is a swipe (ARCHITECTURE 11.4: 68 px of 270).
var _threshold: float = float(ProjectSettings.get_setting("display/window/size/viewport_width")) / 4.0
var _touch := -1              # index of the finger being tracked; -1 = none
var _start_x := 0.0
var _offset := 0.0            # the Panel's shift from where the container put it (drag or tween)
var _rest_x := 0.0
var _armed := false           # the drag is past the threshold (its haptic already played)
var _tween: Tween

@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _energy_label: Label = %EnergyLabel
@onready var _pips: PipBar = %Pips
@onready var _runway: Label = %Runway
@onready var _one_liner: Label = %OneLiner
@onready var _knowledge_label: Label = %KnowledgeLabel
@onready var _experience_label: Label = %ExperienceLabel
@onready var _network_label: Label = %NetworkLabel
@onready var _knowledge: StatBar = %KnowledgeBar
@onready var _experience: StatBar = %ExperienceBar
@onready var _network: StatBar = %NetworkBar
@onready var _perk_mark: Label = %PerkMark
@onready var _perk: Label = %Perk
@onready var _flaw_mark: Label = %FlawMark
@onready var _flaw: Label = %Flaw
@onready var _gaps: Label = %Gaps


func _ready() -> void:
	_energy_label.text = Content.text("barks", "ui_energy_per_day")
	_knowledge_label.text = Content.text("barks", "ui_stat_knw")
	_experience_label.text = Content.text("barks", "ui_stat_exp")
	_network_label.text = Content.text("barks", "ui_stat_net")
	_perk_mark.text = PERK_MARK
	_flaw_mark.text = FLAW_MARK


## Fills the card for one background. gap_topics are topic ids (naming.json _topics); from_side
## slides the card in from the right (+1) or the left (-1), 0 = no slide.
func show_background(bg_id: String, gap_topics: Array, from_side: int = 0) -> void:
	var bg := Content.background(bg_id)
	var cfg := Content.balance
	_title.text = "%s - %s" % [Content.field("backgrounds", bg_id, "title"), Content.field("backgrounds", bg_id, "difficulty")]
	_pips.set_pips(cfg.energy_max, cfg.energy_max - bg.commute_pips, bg.commute_pips)
	_runway.text = Content.text("barks", "ui_rent_runway", {"days": bg.runway_days})
	_one_liner.text = "\"%s\"" % Content.field("backgrounds", bg_id, "one_liner")
	_knowledge.value = bg.start_knw
	_experience.value = bg.start_exp
	_network.value = bg.start_net
	_perk.text = Content.field("backgrounds", bg_id, "perk")
	_flaw.text = Content.field("backgrounds", bg_id, "flaw")
	_gaps.visible = not gap_topics.is_empty()
	if _gaps.visible:
		var labels: Dictionary = Content.entries("naming").get("_topics", {})
		var args: Dictionary = {}
		for i: int in gap_topics.size():
			args["topic_%d" % (i + 1)] = tr(str(labels.get(gap_topics[i], gap_topics[i])))
		_gaps.text = Content.field("backgrounds", bg_id, "gaps_line", args)
	_animate_offset(from_side * SLIDE_IN_PX)


# ---------- swipe (raw touch; the emulated mouse events are ignored here) ----------

func _gui_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _touch == -1:
			_touch = touch.index
			_start_x = touch.position.x
			_armed = false
			if _tween != null:
				_tween.kill()
		elif not touch.pressed and touch.index == _touch:
			_release(touch.canceled)
		accept_event()
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _touch:
		_set_offset(drag.position.x - _start_x)
		var armed := absf(_offset) > _threshold
		if armed and not _armed:
			Device.haptic()  # the swipe "clicks" before release (GDD 9.3)
		_armed = armed
		accept_event()


func _release(canceled: bool) -> void:
	_touch = -1
	var step := 0
	if not canceled and absf(_offset) > _threshold:
		step = 1 if _offset < 0.0 else -1
	_animate_offset(_offset)  # settle back; a switch restarts it as a slide-in from the other side
	if step != 0:
		swiped.emit(step)


func _animate_offset(from: float) -> void:
	if _tween != null:
		_tween.kill()
	_set_offset(from)
	if is_zero_approx(from):
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_method(_set_offset, from, 0.0, SETTLE_SEC)


func _set_offset(x: float) -> void:
	_offset = x
	_apply_offset()


## Sorting puts the Panel back at rest (position and rotation), so the shift is re-applied after it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and is_node_ready():
		_rest_x = _panel.position.x
		_apply_offset()


func _apply_offset() -> void:
	if not is_node_ready():
		return
	_panel.pivot_offset = Vector2(_panel.size.x * 0.5, _panel.size.y)
	_panel.position.x = _rest_x + _offset
	_panel.rotation_degrees = clampf(_offset / _threshold, -1.0, 1.0) * MAX_TILT_DEG

class_name HiredBeat
extends Control
## The HIRED! stamp as a short beat on Accept (MC-08, A92; GDD S11's first beat): the stamp slams onto the illustration
## above the company, the role, the yearly pay and the tier's hired line, and a tap moves on (the Dream vs Reality sheet
## went to the ending cards, MC-09). The offer screen plays it over its paper and commits the Accept when it finishes,
## so a kill during it resumes at the offer, as the Hired card always did.

signal finished

const STAMP_DELAY_S := 0.15    # after the paper's buttons go quiet, the stamp lands

var _armed := false            # the stamp is down and the input lock has passed: a tap moves on
var _done := false

@onready var _art: EndingArt = %Art
@onready var _job_lines: Label = %JobLines
@onready var _hired_line: Label = %HiredLine
@onready var _tap_hint: Label = %TapHint


func _ready() -> void:
	set_process_input(false)


## paper: the contract paper (DuelAdapter.offer_paper). Shows the beat and starts the stamp.
func play(paper: Dictionary) -> void:
	var tier := str(paper.get("tier", ""))
	var company_id := str(paper.get("company_id", ""))
	var bg_entry: Dictionary = Content.entries("backgrounds").get(GameState.run.background_id, {})
	_art.setup(Content.text("endings", "end_hired_title"), VersusIntro.tier_color(tier),
		VersusIntro.hoodie_color(str(bg_entry.get("hoodie", ""))))
	_job_lines.text = "\n".join(PackedStringArray([
		Content.field("companies", company_id, "name"),
		tr(str(paper.get("job_title", ""))),
		Content.text("emails", "offer_salary", {"salary": UiText.money(int(paper.get("salary", 0)))}),
	]))
	var hired := PackedStringArray([Content.text("endings", "end_hired_" + tier)])
	if (Content.entries("companies").get(company_id, {}) as Dictionary).has("hired_extra"):
		hired.append(Content.field("companies", company_id, "hired_extra"))   # CONTENT.md 14: Stealth Mode
	_hired_line.text = "\n".join(hired)
	_tap_hint.text = Content.text("barks", "ui_tap_to_continue")
	_tap_hint.modulate.a = 0.0
	_armed = false
	_done = false
	show()
	_art.landed.connect(_on_stamp_landed, CONNECT_ONE_SHOT)
	var tween := create_tween()
	tween.tween_interval(STAMP_DELAY_S)
	tween.tween_callback(_art.slam)


## Back moves on like a tap, once the stamp is down. True while the beat is showing.
func skip() -> bool:
	if not visible:
		return false
	if _armed:
		_finish()
	return true


## The stamp is down: after the input lock (GDD 2.8 rule 7), a tap anywhere moves on.
func _on_stamp_landed() -> void:
	var tween := create_tween()
	tween.tween_interval(Content.balance.input_lock_ms / 1000.0)
	tween.tween_callback(_arm)


func _arm() -> void:
	if _done:
		return
	_armed = true
	_tap_hint.modulate.a = 1.0
	set_process_input(true)


## A tap anywhere (touches arrive as emulated mouse events), acting on the release like a button.
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if not mb.pressed and _armed:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	set_process_input(false)
	finished.emit()

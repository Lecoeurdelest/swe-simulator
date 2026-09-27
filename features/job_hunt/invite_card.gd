class_name InviteCard
extends PanelContainer
## One interview invite in Mail (GDD S06): a header with the golden envelope (a placeholder until the art
## pass) and the company, then the email's subject and body, "Interview with {company}: today or
## tomorrow" on the day it arrived, and [ Later ][ GO NOW  3 ] inside the card. Later folds the card to
## its header; a tap on the header opens it again. The invite stays in Mail either way. Buttons PASS
## their input on (the list scrolls).

signal go_now_pressed
signal folded_changed(folded: bool)

var _folded := false

@onready var _header: Button = %Header
@onready var _subject: Label = %Subject
@onready var _company: Label = %Company
@onready var _body: Label = %Body
@onready var _line: Label = %Line
@onready var _buttons: HBoxContainer = %Buttons
@onready var _later: Button = %LaterButton
@onready var _go: Button = %GoButton


func _ready() -> void:
	_later.text = Content.text("barks", "ui_later")
	_later.pressed.connect(_set_folded.bind(true))
	_header.pressed.connect(func() -> void: _set_folded(not _folded))
	_go.pressed.connect(go_now_pressed.emit)


## Texts come from Content (already translated). line = "" hides it. can_go = false greys GO NOW out
## (GDD 5.3: today's interview is used, too few pips, or the run ends this morning).
func setup(subject: String, company: String, body: String, line: String, go_text: String, can_go: bool, folded: bool) -> void:
	_subject.text = subject
	_company.text = company
	_body.text = body
	_line.text = line
	_go.text = go_text
	_go.disabled = not can_go
	_folded = folded
	_apply_fold()


func go_button() -> Button:
	return _go


func is_folded() -> bool:
	return _folded


func _set_folded(folded: bool) -> void:
	if folded == _folded:
		return
	_folded = folded
	_apply_fold()
	folded_changed.emit(folded)


func _apply_fold() -> void:
	_subject.visible = not _folded
	_body.visible = not _folded
	_line.visible = not _folded and not _line.text.is_empty()
	_buttons.visible = not _folded

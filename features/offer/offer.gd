extends Control
## The offer (GDD S10, ARCHITECTURE 11.7): a paper contract slides up over the dimmed interview stage,
## where Dana stays visible. It only shows run.offer (GameState.finish_interview built it) and one
## Ducky tip, and calls GameState.answer_offer(). Decline asks first, and on the grace day the question
## says the run ends (GDD 5.10); then Dana answers (5.9.4) before the Decline is committed.
## Back never declines an offer (ARCHITECTURE 9).

const CONTRACT_COLUMNS := 40   # GDD 2.7: the 254 px paper holds 40 characters of monogram 16
const LABEL_COLUMNS := 12      # GDD S10: one field per line after a 12-character label column
const PAPER_SLIDE_S := 0.3     # GDD 9.1 "the paper slides up from the bottom" (no duration given)
const DANA_LINE_S := 2.5       # Dana's Decline line moves on by itself after this, or on a tap

var _answered := false         # Accept or a confirmed Decline: the buttons stay off
var _declined := false         # answer_offer(false) was called (once)
var _slide := 0.0              # the paper's offset below its place in the column
var _paper_rest_y := 0.0

@onready var _stage: Control = %Stage
@onready var _tier_background: ColorRect = %TierBackground
@onready var _player_bust: ColorRect = %PlayerBust
@onready var _column: VBoxContainer = %Column
@onready var _paper: Control = %Paper
@onready var _contract: RichTextLabel = %Contract
@onready var _tip: DuckyNote = %TipNote
@onready var _dana_line: Control = %DanaLine
@onready var _dana_name: Label = %DanaName
@onready var _dana_text: Label = %DanaText
@onready var _back_button: Button = %BackButton
@onready var _decline_button: Button = %DeclineButton
@onready var _accept_button: Button = %AcceptButton
@onready var _pause: PauseMenu = %PauseMenu
@onready var _decline_dialog: ConfirmDialog = %DeclineDialog


func _ready() -> void:
	var run: RunState = GameState.run
	var bg_entry: Dictionary = Content.entries("backgrounds").get(run.background_id, {})
	_tier_background.color = VersusIntro.tier_color(str(run.offer.get("tier", "")))
	_player_bust.color = VersusIntro.hoodie_color(str(bg_entry.get("hoodie", ""))).lightened(0.4)
	_contract.text = "\n".join(_contract_lines(run))
	_tip.tip_text = Content.field("tips", HuntTips.offer(run), "short")
	_dana_name.text = Content.text("naming", "interviewer").to_upper()
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_decline_button.text = Content.text("barks", "ui_decline")
	_accept_button.text = UiText.primary(Content.text("barks", "ui_accept"))
	_back_button.pressed.connect(Device.handle_back)
	_decline_button.pressed.connect(_on_decline)
	_accept_button.pressed.connect(_on_accept)
	_decline_dialog.confirmed.connect(_on_decline_confirmed)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	_column.sort_children.connect(_on_column_sorted)
	set_process_input(false)
	_slide_in()


## ARCHITECTURE 9: the confirm dialog open = cancel it; Pause open = resume; Dana's Decline line =
## move on; else open Pause. Back never declines.
func handle_back() -> bool:
	if _decline_dialog.is_open():
		return _decline_dialog.handle_back()
	if _pause.is_open():
		return _pause.handle_back()
	if _dana_line.visible:
		_finish_decline()
		return true
	if not _answered:
		_pause.open()
	return true


## During Dana's Decline line only: any tap moves on (touches arrive as emulated mouse events).
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_finish_decline()


# ---------- the contract (GDD S10, CONTENT.md 13.1) ----------

## Top to bottom: the title and the letter, a blank line, one field per line after the label column
## (the equity only at startups, the second perk under the first), then the deadline. Every text comes
## from emails.json through the ids run.offer holds; the job title is the posting's own.
func _contract_lines(run: RunState) -> PackedStringArray:
	var offer: Dictionary = run.offer
	var company := Content.field("companies", str(offer.get("company_id", "")), "name")
	var commute: Dictionary = offer.get("commute", {})
	var lines := PackedStringArray()
	lines += UiText.word_wrap(Content.text("emails", "offer_title", {"company": company}), CONTRACT_COLUMNS)
	lines += UiText.word_wrap(Content.text("emails", "offer_dear", {"player_name": run.player_name}), CONTRACT_COLUMNS)
	lines += UiText.word_wrap(Content.text("emails", "offer_role", {"job_title": tr(str(offer.get("job_title", "")))}), CONTRACT_COLUMNS)
	lines.append("")
	lines += _field(Content.text("emails", "offer_label_salary"),
		Content.text("emails", "offer_salary", {"salary": UiText.money(int(offer.get("salary", 0)))}))
	if str(offer.get("equity_text", "")) != "":
		lines += _field(Content.text("emails", "offer_label_equity"), Content.text("emails", str(offer["equity_text"])))
	lines += _field(Content.text("emails", "offer_label_mode"), Content.text("emails", str(offer.get("work_mode", ""))))
	lines += _field(Content.text("emails", "offer_label_commute"),
		Content.text("emails", str(commute.get("id", "")), commute.get("args", {})))
	var label := Content.text("emails", "offer_label_perks")
	for perk: Variant in offer.get("perks", []):
		lines += _field(label, Content.text("emails", str(perk)))
		label = ""
	lines += _field(Content.text("emails", "offer_label_fine_print"), Content.text("emails", str(offer.get("fine_print", ""))))
	lines += UiText.word_wrap(Content.text("emails", "offer_deadline"), CONTRACT_COLUMNS)
	return lines


func _field(label: String, value: String) -> PackedStringArray:
	return UiText.field(label, value, LABEL_COLUMNS, CONTRACT_COLUMNS)


# ---------- the paper slides up ----------

## After the scene fade (the paper waits off-screen), the paper rises into its place. ACCEPT and
## Decline stay off until it lands, which is also the input lock (GDD 2.8 rule 7).
func _slide_in() -> void:
	_set_answer_buttons(false)
	_set_slide(get_viewport_rect().size.y)
	if SceneRouter.busy:
		await SceneRouter.transition_finished
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_slide, _slide, 0.0, PAPER_SLIDE_S)
	await tween.finished
	_set_answer_buttons(not _answered)


func _set_slide(offset: float) -> void:
	_slide = offset
	_paper.position.y = _paper_rest_y + _slide


## The column just laid out its children: the paper's place is where the slide ends, and the stage's
## desk line follows the paper's top edge, so Dana sits right above the contract (ARCHITECTURE 11.7).
func _on_column_sorted() -> void:
	_paper_rest_y = _paper.position.y
	_set_slide(_slide)
	_stage.offset_bottom = _column.get_global_rect().position.y + _paper_rest_y - get_global_rect().position.y


func _set_answer_buttons(on: bool) -> void:
	_decline_button.disabled = not on
	_accept_button.disabled = not on


# ---------- answers ----------

func _on_accept() -> void:
	if _answered:
		return
	_answered = true
	_set_answer_buttons(false)
	GameState.answer_offer(true)


## GDD 5.9.4: Decline asks first. On the grace day Decline is Plan B (GDD 5.10), so the question says so.
func _on_decline() -> void:
	if _answered:
		return
	var message := Content.text("barks", "ui_decline_confirm")
	if GameState.run.decline_ends_run():
		message = Content.text("barks", "ui_decline_confirm_grace")
	_decline_dialog.open(message, Content.text("barks", "ui_decline"), "", true)


## Dana answers in place of the tip. Only when her line is done (a tap, Back or DANA_LINE_S) is the
## Decline committed, so a kill during it leaves the offer open for Continue.
func _on_decline_confirmed() -> void:
	if _answered:
		return
	_answered = true
	_set_answer_buttons(false)
	_back_button.disabled = true
	_tip.hide()
	_dana_text.text = Content.text("barks", "bark_dana_decline")
	_dana_line.show()
	set_process_input(true)
	get_tree().create_timer(DANA_LINE_S, false).timeout.connect(_finish_decline)


func _finish_decline() -> void:
	if _declined:
		return
	_declined = true
	set_process_input(false)
	GameState.answer_offer(false)

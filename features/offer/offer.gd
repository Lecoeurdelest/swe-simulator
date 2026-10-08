extends Control
## The offer (GDD S10, ARCHITECTURE 11.7): a paper contract slides up over the dimmed interview stage,
## where Dana stays visible. It only shows run.offer (GameState.finish_interview built it) and one
## Ducky tip, which fades in once the paper has landed and closes on a tap (for this offer only), and
## calls GameState.answer_offer(). Decline asks first, and on the grace day the question says the run
## ends (GDD 5.10); then Dana answers (5.9.4) before the Decline is committed.
## Back never declines an offer (ARCHITECTURE 9).

const PAPER_SLIDE_S := 0.3     # GDD 9.1 "the paper slides up from the bottom" (no duration given)
const DANA_LINE_S := 2.5       # Dana's Decline line moves on by itself after this, or on a tap
const TIP_FADE_S := 0.15       # Ducky's tip fades in after the paper lands, so it never sits over the rising paper
const SETTLE_S := 0.2          # the paper eases into its new place when a note under it comes or goes

var _answered := false         # Accept or a confirmed Decline: the buttons stay off
var _declined := false         # answer_offer(false) was called (once)
var _slide := 0.0              # the paper's offset from its place in the column
var _paper_rest_y := 0.0
var _landed := false           # the slide-in is over: from now on the desk line moves with the paper
var _settle: Tween
var _settle_from := 0.0        # the paper's y when a note under it came or went
var _settle_t := 1.0           # the settle's eased progress; 1 = at rest

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
	_tip.close_tapped.connect(_on_tip_closed)
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

## The paper's lines (ContractText, GDD S10, CONTENT.md 13.1): the title and the letter, a blank line, one field per line
## after the label column (the equity only at startups, the second perk under the first, the career's clauses), then the
## deadline. Every text comes from emails.json through the ids run.offer holds; the job title is the posting's own.
func _contract_lines(run: RunState) -> PackedStringArray:
	var company := Content.field("companies", str(run.offer.get("company_id", "")), "name")
	return ContractText.lines(run.offer, Content.entries("emails"), company, run.player_name)


# ---------- the paper slides up ----------

## After the scene fade (the paper waits off-screen), the paper rises into its place. ACCEPT and
## Decline stay off until it lands, which is also the input lock (GDD 2.8 rule 7). Ducky's tip waits
## invisible (modulate, not hide(): the column keeps its room) and fades in once the paper is down.
func _slide_in() -> void:
	_set_answer_buttons(false)
	_tip.modulate.a = 0.0
	_set_slide(get_viewport_rect().size.y)
	if SceneRouter.busy:
		await SceneRouter.transition_finished
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_method(_set_slide, _slide, 0.0, PAPER_SLIDE_S)
	await tween.finished
	_landed = true
	_set_answer_buttons(not _answered)
	create_tween().tween_property(_tip, "modulate:a", 1.0, TIP_FADE_S)


## The stage's desk line follows the paper's top edge, so Dana sits right above the contract
## (ARCHITECTURE 11.7). While the paper rises from below, the line already waits at its place.
func _set_slide(offset: float) -> void:
	_slide = offset
	_paper.position.y = _paper_rest_y + _slide
	var desk_y := _paper_rest_y + (_slide if _landed else 0.0)
	_stage.offset_bottom = _column.get_global_rect().position.y + desk_y - get_global_rect().position.y


## The column just laid out its children: the paper's place is where the slide ends.
func _on_column_sorted() -> void:
	_paper_rest_y = _paper.position.y
	if _settle_t < 1.0:
		_set_settle(_settle_t)
	else:
		_set_slide(_slide)


## A note under the paper just came or went, so the column will move the paper's place: the paper
## (and the desk line) eases there from where it is now instead of jumping. The place can change more
## than once while a wrapped label finds its height, so each step aims at the latest place.
func _settle_paper() -> void:
	if _settle != null:
		_settle.kill()
	_settle_from = _paper_rest_y + _slide
	_settle_t = 0.0
	_settle = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_settle.tween_method(_set_settle, 0.0, 1.0, SETTLE_S)


func _set_settle(t: float) -> void:
	_settle_t = t
	_set_slide(lerpf(_settle_from - _paper_rest_y, 0.0, t))


## A tap on Ducky's tip closes it, like the hub's coach marks (D11). Only this offer: nothing is saved.
func _on_tip_closed() -> void:
	if not _landed or not _tip.visible:
		return
	_tip.hide()
	_settle_paper()


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
	if GameState.decline_ends_run():
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
	_settle_paper()
	set_process_input(true)
	get_tree().create_timer(DANA_LINE_S, false).timeout.connect(_finish_decline)


func _finish_decline() -> void:
	if _declined:
		return
	_declined = true
	set_process_input(false)
	GameState.answer_offer(false)

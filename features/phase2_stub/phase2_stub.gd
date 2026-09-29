extends Control
## The Hired card (GDD S11, ARCHITECTURE 11.7), in two beats, because everything at once needs about
## 500 px. Beat 1: the HIRED! stamp slams onto the illustration, above the company, the role, the yearly
## salary and the tier's hired line; a tap anywhere (or Back) moves on. Beat 2: the Dream vs Reality
## sheet slides up over the illustration and tallies its 5 rows one by one (RunState.dream_breakdown,
## whose rounded sum is run.dream_score), then the grade, the footer, the tip and TO BE CONTINUED; a tap
## finishes the tally at once. Leaving with [ < Title ] or [ NEW RUN ] deletes the run save
## (GameFlow.deletes_save); a kill here resumes at the offer, because PHASE2_STUB is never saved.

const HIRED_TIP := "tip_written_offer"   # GDD 8.3: the Hired card's tip
const STAMP_DELAY_S := 0.15    # after the scene fade, the stamp lands
const SHEET_SLIDE_S := 0.3     # as the offer paper (GDD 9.1 gives no duration)
const TALLY_ROW_S := 0.35      # the rows tally one by one (GDD S11 gives no pace)

enum Beat { CARD, TALLY, DONE }

var _beat := Beat.CARD
var _leaving := false          # Title or New run was pressed: the scene is on its way out
var _parts: Array[float] = []
var _tally: Tween
var _slide := 0.0              # the sheet's offset below its place in beat 2's column
var _sheet_rest_y := 0.0

@onready var _art: EndingArt = %Art
@onready var _info: Control = %Info
@onready var _job_lines: Label = %JobLines
@onready var _hired_line: Label = %HiredLine
@onready var _tap_hint: Label = %TapHint
@onready var _beat2: VBoxContainer = %Beat2
@onready var _sheet: Control = %Sheet
@onready var _dream_header: Label = %DreamHeader
@onready var _rows: VBoxContainer = %Rows
@onready var _grade: Label = %Grade
@onready var _score: Label = %Score
@onready var _footer: Label = %Footer
@onready var _tip: DuckyNote = %TipNote
@onready var _tbc_panel: Control = %TbcPanel
@onready var _to_be_continued: Label = %ToBeContinued
@onready var _title_button: Button = %TitleButton
@onready var _new_run_button: Button = %NewRunButton


func _ready() -> void:
	var run: RunState = GameState.run
	var job: Dictionary = run.employment
	var tier := str(job.get("tier", ""))
	var company_id := str(job.get("company_id", ""))
	var bg_entry: Dictionary = Content.entries("backgrounds").get(run.background_id, {})
	_art.setup(Content.text("endings", "end_hired_title"), VersusIntro.tier_color(tier),
		VersusIntro.hoodie_color(str(bg_entry.get("hoodie", ""))))
	_job_lines.text = "\n".join(PackedStringArray([
		Content.field("companies", company_id, "name"),
		tr(str(job.get("job_title", ""))),
		Content.text("emails", "offer_salary", {"salary": UiText.money(int(job.get("salary", 0)))}),
	]))
	var hired := PackedStringArray([Content.text("endings", "end_hired_" + tier)])
	if (Content.entries("companies").get(company_id, {}) as Dictionary).has("hired_extra"):
		hired.append(Content.field("companies", company_id, "hired_extra"))  # CONTENT.md 14: Stealth Mode
	_hired_line.text = "\n".join(hired)
	_tap_hint.text = Content.text("barks", "ui_tap_to_continue")
	_fill_dream_panel(run)
	_title_button.text = UiText.back(Content.text("barks", "ui_title"))
	_new_run_button.text = UiText.primary(Content.text("barks", "ui_new_run"))
	_title_button.pressed.connect(Device.handle_back)
	_new_run_button.pressed.connect(_on_new_run)
	_beat2.sort_children.connect(_on_beat2_sorted)
	_tap_hint.modulate.a = 0.0
	_set_buttons(false)
	set_process_input(false)
	_play_card()


## ARCHITECTURE 9: on beat 1 Back moves on, like a tap; after that "< Title" is this card's Back, and it
## and desktop Esc go to the title.
func handle_back() -> bool:
	if _beat == Beat.CARD:
		_start_tally()
	elif not _leaving:
		_leaving = true
		_set_buttons(false)
		GameState.quit_to_title()
	return true


## Beat 1 once armed, and the tally: a tap anywhere moves on (touches arrive as emulated mouse events).
## It acts on the release, like the buttons, and nothing under it gets the tap.
func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if mb.pressed:
		return
	if _beat == Beat.CARD:
		_start_tally()
	else:
		_finish_tally()


# ---------- beat 1: the card ----------

func _play_card() -> void:
	if SceneRouter.busy:
		await SceneRouter.transition_finished
	_art.landed.connect(_on_stamp_landed, CONNECT_ONE_SHOT)
	var tween := create_tween()
	tween.tween_interval(STAMP_DELAY_S)
	tween.tween_callback(_art.slam)


## The stamp is down: after the input lock (GDD 2.8 rule 7), a tap anywhere moves on.
func _on_stamp_landed() -> void:
	var tween := create_tween()
	tween.tween_interval(Content.balance.input_lock_ms / 1000.0)
	tween.tween_callback(_arm_card)


func _arm_card() -> void:
	if _beat != Beat.CARD:
		return
	_tap_hint.modulate.a = 1.0
	set_process_input(true)


# ---------- beat 2: Dream vs Reality ----------

## Every row, the score line and what follows it are filled now and stay invisible (modulate, so the
## layout never jumps) until the tally reaches them. Each row shows its points out of the row's maximum
## ("18.9/40"): the five maximums add up to the 100 the footer talks about.
func _fill_dream_panel(run: RunState) -> void:
	_parts = GameState.dream_breakdown()
	var cfg := Content.balance
	var maxes: Array[float] = [cfg.dream_w_salary, cfg.dream_w_remote, cfg.dream_w_commute, cfg.dream_w_flags,
		cfg.dream_w_runway]  # Odds.DREAM_ROWS order
	_dream_header.text = Content.text("endings", "end_dream_header")
	for i: int in Odds.DREAM_ROWS.size():
		var row := _rows.get_child(i)
		(row.get_node("Name") as Label).text = Content.text("endings", "end_dream_row_" + Odds.DREAM_ROWS[i])
		(row.get_node("Points") as Label).text = "%.1f/%d" % [_parts[i], roundi(maxes[i])] if i < _parts.size() else ""
		(row as CanvasItem).modulate.a = 0.0
	_score.text = "0"
	_grade.text = Content.text("endings", "end_dream_grade_%d" % Odds.dream_grade(run.dream_score))
	_footer.text = Content.text("endings", "end_dream_footer")
	_tip.tip_text = Content.field("tips", HIRED_TIP, "short")
	_to_be_continued.text = Content.text("endings", "end_tbc")
	for node: CanvasItem in _after_tally():
		node.modulate.a = 0.0


func _after_tally() -> Array[CanvasItem]:
	var nodes: Array[CanvasItem] = [_grade, _footer, _tip, _tbc_panel]
	return nodes


## Beat 1 -> beat 2: the card's text goes, the sheet slides up over the illustration (drawn above the
## action bar, which stays put: GDD 9.1 never moves the thumb band), then one row per TALLY_ROW_S with
## the running score.
func _start_tally() -> void:
	if _beat != Beat.CARD:
		return
	_beat = Beat.TALLY
	_info.hide()
	_tap_hint.hide()
	_beat2.show()
	_set_slide(get_viewport_rect().size.y)
	set_process_input(true)
	_tally = create_tween()
	_tally.tween_method(_set_slide, _slide, 0.0, SHEET_SLIDE_S).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	for i: int in _parts.size():
		_tally.tween_interval(TALLY_ROW_S)
		_tally.tween_callback(_show_rows.bind(i + 1))
	_tally.tween_interval(TALLY_ROW_S)
	_tally.tween_callback(_finish_tally)


## The first `count` rows show, and the score is their running total.
func _show_rows(count: int) -> void:
	var total := 0.0
	for i: int in mini(count, _parts.size()):
		(_rows.get_child(i) as CanvasItem).modulate.a = 1.0
		total += _parts[i]
	_score.text = str(roundi(total))


## The end of the tally, reached by the tween or by a tap: everything shows, the score is
## run.dream_score, and the buttons come on after the input lock.
func _finish_tally() -> void:
	if _beat != Beat.TALLY:
		return
	_beat = Beat.DONE
	if _tally != null:
		_tally.kill()
	set_process_input(false)
	_set_slide(0.0)
	_show_rows(_parts.size())
	_score.text = str(GameState.run.dream_score)
	for node: CanvasItem in _after_tally():
		node.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(Content.balance.input_lock_ms / 1000.0)
	tween.tween_callback(_set_buttons.bind(true))


## Whole pixels only (ARCHITECTURE 1.3).
func _set_slide(offset: float) -> void:
	_slide = offset
	_sheet.position.y = _sheet_rest_y + roundf(_slide)


## Beat 2's column just placed its children: the sheet's place is where the slide ends.
func _on_beat2_sorted() -> void:
	_sheet_rest_y = _sheet.position.y
	_set_slide(_slide)


# ---------- leaving ----------

func _set_buttons(on: bool) -> void:
	_title_button.disabled = not on or _leaving
	_new_run_button.disabled = not on or _leaving


func _on_new_run() -> void:
	if _leaving:
		return
	_leaving = true
	_set_buttons(false)
	GameState.retry()

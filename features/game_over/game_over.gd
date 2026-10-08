extends Control
## The Plan B card (GDD S12, 5.10, ARCHITECTURE 11.7), in one beat: the PLAN B stamp slams onto the
## illustration, then the ending (end_plan_b), your background's line, the closing line, one Ducky tip
## (HuntTips.plan_b) and the run's stats. [ RETRY ] starts a fresh run at Background select with the
## same background preselected (GameState.retry). The save is already gone: entering GAME_OVER deletes
## it (GameFlow.deletes_save).
## The career run's endings (GDD 3.3, CONTENT 16.5) use the same card: the ending's stamp and line, one Ducky tip where
## the data has one, and the run's days, jobs and layoffs. Plan B keeps its background line and closing line.

const STAMP_DELAY_S := 0.15    # after the scene fade, the stamp lands
## Grey-box stand-in until the art pass: the ClikClok ring-light glow behind you (GDD S12).
const PLAN_B_SKY := Color(0.36, 0.16, 0.36)
const ENDING_SKY: Dictionary = {   # grey-box skies for the career run's endings
	"plan_b": PLAN_B_SKY, "studio": Color(0.2, 0.45, 0.35), "burnout": Color(0.45, 0.15, 0.15),
	"career_change": Color(0.2, 0.3, 0.5), "legacy": Color(0.3, 0.3, 0.34),
}
const ENDING_TIPS: Dictionary = {"plan_b": "tip_emergency_fund", "burnout": "tip_overtime_loan"}   # where the data has one

var _leaving := false          # Title or Retry was pressed: the scene is on its way out

@onready var _art: EndingArt = %Art
@onready var _text: Label = %Text
@onready var _background_line: Label = %BackgroundLine
@onready var _final_line: Label = %FinalLine
@onready var _tip: DuckyNote = %TipNote
@onready var _stats: Label = %Stats
@onready var _title_button: Button = %TitleButton
@onready var _retry_button: Button = %RetryButton


func _ready() -> void:
	var run: RunState = GameState.run
	var session := GameState.session
	var bg_entry: Dictionary = Content.entries("backgrounds").get(run.background_id, {})
	var hoodie := VersusIntro.hoodie_color(str(bg_entry.get("hoodie", "")))
	if session != null:
		_fill_career(run, session.sim, hoodie)
	else:
		_art.setup(Content.text("endings", "end_plan_b_title"), PLAN_B_SKY, hoodie)
		_text.text = Content.text("endings", "end_plan_b")
		_background_line.text = Content.field("backgrounds", run.background_id, "plan_b_line")
		_final_line.text = Content.text("endings", "end_plan_b_final")
		_tip.tip_text = Content.field("tips", HuntTips.plan_b(run), "short")
		_stats.text = Content.text("endings", "end_stats", {
			"day": run.day, "n": run.total_applications, "i": run.interviews_taken, "r": run.total_rejections})
	_title_button.text = UiText.back(Content.text("barks", "ui_title"))
	_retry_button.text = UiText.primary(Content.text("barks", "ui_retry"))
	_title_button.pressed.connect(Device.handle_back)
	_retry_button.pressed.connect(_on_retry)
	_set_buttons(false)
	_slam_after_fade()


## A career ending (CONTENT 16.5): title, line, the tip the data has for it, and the run's numbers.
func _fill_career(run: RunState, sim: SimState, hoodie: Color) -> void:
	var ending := sim.ending if not sim.ending.is_empty() else "plan_b"
	_art.setup(Content.text("endings", "end_%s_title" % ending), ENDING_SKY.get(ending, PLAN_B_SKY), hoodie)
	var line_id := "end_%s" % ending
	if ending == "studio" and sim.jobs_held <= 1:
		line_id = "end_studio_one"
	_text.text = Content.text("endings", line_id, {"jobs": sim.jobs_held})
	var plan_b := ending == "plan_b"
	_background_line.visible = plan_b
	_final_line.visible = plan_b
	if plan_b:
		_background_line.text = Content.field("backgrounds", run.background_id, "plan_b_line")
		_final_line.text = Content.text("endings", "end_plan_b_final")
	var tip_id: String = ENDING_TIPS.get(ending, "")
	_tip.visible = not tip_id.is_empty()
	if not tip_id.is_empty():
		_tip.tip_text = Content.field("tips", tip_id, "short")
	_stats.text = Content.text("endings", "end_career_stats", {
		"day": sim.day, "jobs": sim.jobs_held, "layoffs": int(sim.stats.get("layoffs", 0)),
		"level": Content.text("barks", WorkHud.level_label_id(sim.level))})


## "< Title" is this card's on-screen Back; it and desktop Esc go to the title (ARCHITECTURE 9).
func handle_back() -> bool:
	if not _leaving:
		_leaving = true
		_set_buttons(false)
		GameState.quit_to_title()
	return true


func _slam_after_fade() -> void:
	if SceneRouter.busy:
		await SceneRouter.transition_finished
	_art.landed.connect(_on_stamp_landed, CONNECT_ONE_SHOT)
	var tween := create_tween()
	tween.tween_interval(STAMP_DELAY_S)
	tween.tween_callback(_art.slam)


## The buttons come on once the stamp is down and the input lock has passed (GDD 2.8 rule 7), so a
## second tap on Mail's START DAY, which sits where RETRY is, can't skip the ending.
func _on_stamp_landed() -> void:
	var tween := create_tween()
	tween.tween_interval(Content.balance.input_lock_ms / 1000.0)
	tween.tween_callback(_set_buttons.bind(true))


func _on_retry() -> void:
	if _leaving:
		return
	_leaving = true
	_set_buttons(false)
	GameState.retry()


func _set_buttons(on: bool) -> void:
	_title_button.disabled = not on or _leaving
	_retry_button.disabled = not on or _leaving

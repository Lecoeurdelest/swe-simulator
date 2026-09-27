class_name CvScreen
extends VBoxContainer
## The CV screen, Buzzwordsmith (GDD S05, ARCHITECTURE 11.4). A 2-row header, information only: the tag
## set with the Lie-risk dots (0-3), then the "Degree" and "Counts as 1+ yrs" chips. Below it, in a
## list that scrolls when a tip needs the room: Education, Experience and Projects, each with its
## Honest | Polished | Lie control, then the tip slot just above the action bar. A segment tap calls
## GameState.set_cv_level() (free; it changes only future applications); the hub commits on leaving.

const RISK_COLOR := Color(0.89411765, 0.23137255, 0.26666668)
const YES_COLOR := Color(0.38823530, 0.78039217, 0.3019608)
const NO_COLOR := Color(0.89411765, 0.23137255, 0.26666668)

@onready var _tag_set: Label = %TagSet
@onready var _risk_label: Label = %RiskLabel
@onready var _risk: PipBar = %RiskDots
@onready var _degree: Label = %DegreeChip
@onready var _years: Label = %YearsChip
@onready var _scroll: ScrollContainer = %CvScroll
@onready var _tip: DuckyNote = %CvTip
@onready var _rows: Dictionary[String, CvRow] = {"edu": %EduRow, "exp": %ExpRow, "proj": %ProjRow}


func _ready() -> void:
	_risk_label.text = Content.text("barks", "ui_cv_risk")
	_risk.filled_color = RISK_COLOR
	_risk.set_pips(RunState.CV_LINES.size(), 0, 0)
	# Step 2: a saved scene bakes the deadzone it was saved with, so read the project's value.
	_scroll.scroll_deadzone = int(ProjectSettings.get_setting("gui/common/default_scroll_deadzone", 0))
	_rows["edu"].set_label(Content.text("barks", "ui_cv_edu"))
	_rows["exp"].set_label(Content.text("barks", "ui_cv_exp"))
	_rows["proj"].set_label(Content.text("barks", "ui_cv_proj"))
	for line: String in _rows:
		_rows[line].level_chosen.connect(_on_level_chosen.bind(line))
	_scroll.resized.connect(_pin_tip)  # the header grows when the tag set wraps to a second line
	_tip.hide()


## The screen was just opened from the dock: the first open of a run shows tip_quantify_impact
## (GDD S05); later opens start without a tip.
func opened() -> void:
	_tip.hide()
	refresh()
	_scroll.scroll_vertical = 0
	_show_tip(HuntTips.cv_opened(GameState.run))


## Shows the CV as set: the header from the lines as they would be sent by a Quick Apply.
func refresh() -> void:
	var run := GameState.run
	var cv := Content.entries("cv_lines")
	var keywords: Dictionary = Content.entries("naming").get("_keywords", {})
	var sent := run.cv_sent(cv, false)
	var names: PackedStringArray = []
	for tag: Variant in sent["tags"]:
		names.append(tr(str(keywords.get(str(tag), str(tag)))))
	_tag_set.text = ", ".join(names)
	_risk.filled = (sent["lies"] as Array).size()
	_set_chip(_degree, "ui_cv_degree", bool(sent["degree"]))
	_set_chip(_years, "ui_cv_years", bool(sent["passes_years"]))
	for line: String in _rows:
		var level: String = run.cv_levels.get(line, "honest")
		_rows[line].show_line(run.cv_line(cv, line, level), level, keywords)


func tip_text() -> String:
	return _tip.tip_text if _tip.visible else ""


func row(line: String) -> CvRow:
	return _rows.get(line)


func _on_level_chosen(level: String, line: String) -> void:
	if not GameState.set_cv_level(line, level):
		return
	_show_tip(HuntTips.cv_level_chosen(GameState.run, Content.entries("cv_lines"), line, level))


## One tip at a time (GDD 8.1 rule 2): a new one replaces the note's text.
func _show_tip(tip_id: String) -> void:
	if tip_id.is_empty():
		return
	_tip.tip_text = Content.field("tips", tip_id, "short")
	_tip.show()
	GameState.mark_tip_shown(tip_id)
	_pin_tip()


## Keeps a showing tip in view when the list is taller than the screen (a 270x480 phone), once the
## layout has settled.
func _pin_tip() -> void:
	if not _tip.visible:
		return
	await get_tree().process_frame
	if is_instance_valid(_tip) and _tip.is_visible_in_tree():
		_scroll.ensure_control_visible(_tip)


## "Degree: yes" / "Counts as 1+ yrs: no": the word says it; the colour only repeats it (GDD 2.7).
func _set_chip(chip: Label, id: String, yes: bool) -> void:
	var word := Content.text("barks", "ui_yes") if yes else Content.text("barks", "ui_no")
	chip.text = Content.text("barks", id, {"yes_no": word})
	chip.add_theme_color_override(&"font_color", YES_COLOR if yes else NO_COLOR)

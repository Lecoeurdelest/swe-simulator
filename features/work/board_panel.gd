class_name BoardPanel
extends VBoxContainer
## The DoomApply board (GDD 5.20, 4.6; D-41, P-02): 3-5 postings stacked as nodes of a route, joined by a line, each with
## company, archetype, level, yearly pay, work mode, clauses and the callback band as 5 dots, never a percentage. Tap a
## node to select it; Apply (primary) and Study sit in the thumb band beside Back. It shows what WorkBoard computes and
## reports two presses (INV-03); the work screen turns them into GameState verbs. It replaces the Body and the Hours
## and dock rows while it is open, so the top band keeps showing Runway and Burnout while you apply.

signal apply_pressed(posting_id: int)
signal study_pressed

const ROUTE_X := 10.0                  # the line that joins the nodes runs along the left edge
const ROUTE_COLOR := Color(0.54509807, 0.60784316, 0.7058824, 1)
const NODE_MARGIN := 4.0               # the theme's buttons are 36 px tall for one line; a node holds three or four
const STATES: Array[StringName] = [&"normal", &"pressed", &"hover", &"hover_pressed", &"focus", &"disabled"]
const CLAUSE_IDS: Dictionary = {
	"on_call": "ui_clause_on_call", "remote_in_writing": "ui_clause_remote_in_writing", "unlimited_pto": "ui_clause_unlimited_pto",
}
const ARCHETYPE_IDS: Dictionary = {
	"startup": "ui_archetype_startup", "agency": "ui_archetype_agency", "megacorp": "ui_archetype_megacorp",
}

var _selected := -1                    # the posting id you tapped; -1 until one is
var _group := ButtonGroup.new()

@onready var _title: Label = %Title
@onready var _refresh: Label = %Refresh
@onready var _nodes: VBoxContainer = %Nodes
@onready var _waiting: Label = %Waiting
@onready var _study: Button = %StudyButton
@onready var _back: Button = %BackButton
@onready var _apply: Button = %ApplyButton


func _ready() -> void:
	_title.text = Content.text("naming", "app_jobs").to_upper()
	_back.text = UiText.back(Content.text("barks", "ui_back"))
	_apply.text = UiText.primary(Content.text("barks", "ui_apply"))
	_back.pressed.connect(Device.handle_back)
	_apply.pressed.connect(_on_apply_pressed)
	_study.pressed.connect(study_pressed.emit)
	_nodes.draw.connect(_draw_route)
	_nodes.sort_children.connect(_nodes.queue_redraw)


## Draws the board from the session's state: the nodes (the selection stays on its posting, else the first), the
## applications in flight and the two buttons' states.
func show_board(session: WorkSession) -> void:
	var s := session.sim
	var ctx := session.ctx
	var cfg := ctx.cfg
	var nodes := WorkBoard.nodes(s, ctx)
	var kept := false
	for node: Dictionary in nodes:
		if int(node["id"]) == _selected:
			kept = true
	if not kept:
		_selected = int(nodes[0]["id"]) if not nodes.is_empty() else -1
	_rebuild_nodes(nodes)
	var can_apply := WorkBoard.can_apply(s, cfg)
	_refresh.text = Content.text("barks", "ui_board_refresh", {"days": WorkBoard.days_to_refresh(s, cfg)})
	var first_time := session.first_run and int(s.stats.get("applies", 0)) == 0   # the first visit: say how it works
	var waiting := _waiting_text(WorkBoard.waiting(s), first_time)
	if can_apply:
		_apply.text = UiText.primary(Content.text("barks", "ui_apply_cost", {"n": int(WorkBoard.apply_burnout(s, cfg))}))
	else:
		_apply.text = UiText.primary(Content.text("barks", "ui_apply"))
		waiting += "\n" + Content.text("barks", "ui_last_floor")
	_waiting.text = waiting
	var can_study := WorkBoard.can_study(s)
	_study.text = Content.text("barks", "ui_study", {"n": int(cfg.study_burnout)}) if can_study else Content.text("barks", "ui_study_done")
	_study.disabled = not can_study
	_apply.disabled = _selected < 0 or not can_apply


func selected_id() -> int:
	return _selected


## The text of one node's button: the company, what the job is and where, the clauses (when it has any), and the odds.
func node_text(node: Dictionary) -> String:
	var company := Content.field("companies", String(node["company"]), "name")
	var what := "%s  %s  %s/yr  %s" % [
		Content.text("barks", String(ARCHETYPE_IDS.get(node["archetype"], "ui_archetype_startup"))),
		Content.text("barks", WorkHud.level_label_id(int(node["level"]))),
		UiText.money(int(node["salary"])),
		Content.text("barks", "ui_mode_remote" if bool(node["remote"]) else "ui_mode_office")]
	var lines: Array = [company, what]
	var clauses := PackedStringArray()
	for clause: Variant in node["clauses"]:
		clauses.append(Content.text("barks", String(CLAUSE_IDS.get(clause, ""))))
	if not clauses.is_empty():
		lines.append("  ".join(clauses))
	var dots := int(node["dots"])
	lines.append("%s %s" % [Content.text("barks", "ui_callback"), UiText.band(dots, Content.text("barks", "ui_odds_%d" % dots))])
	return "\n".join(lines)


func _rebuild_nodes(nodes: Array) -> void:
	for child: Node in _nodes.get_children():
		_nodes.remove_child(child)
		child.queue_free()
	for node: Dictionary in nodes:
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = _group
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.text = node_text(node)
		button.set_pressed_no_signal(int(node["id"]) == _selected)
		button.pressed.connect(_on_node_pressed.bind(int(node["id"])))
		_nodes.add_child(button)
		_compact(button)
	_nodes.queue_redraw()


## The theme's button style has margins for a one-line, 36 px button: a node's own copy keeps the look and trims them.
func _compact(button: Button) -> void:
	for state: StringName in STATES:
		var box := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if box == null:
			continue
		box.content_margin_top = NODE_MARGIN
		box.content_margin_bottom = NODE_MARGIN
		button.add_theme_stylebox_override(state, box)


func _waiting_text(waiting: Array, first_time: bool = false) -> String:
	if waiting.is_empty():
		return Content.text("barks", "ui_board_hint" if first_time else "ui_board_nothing")
	var lines := PackedStringArray([Content.text("barks", "ui_board_waiting")])
	for item: Dictionary in waiting:
		var id := "ui_app_reply" if String(item["kind"]) == "reply" else "ui_app_interview"
		lines.append(Content.text("barks", id, {"company": Content.field("companies", String(item["company"]), "name"), "day": int(item["day"])}))
	return "\n".join(lines)


func _on_node_pressed(posting_id: int) -> void:
	_selected = posting_id
	_apply.disabled = false


func _on_apply_pressed() -> void:
	if _selected >= 0:
		apply_pressed.emit(_selected)


## The route: a line down the left edge from each node to the next.
func _draw_route() -> void:
	var buttons := _nodes.get_children()
	for i: int in buttons.size() - 1:
		var from: Control = buttons[i]
		var to: Control = buttons[i + 1]
		_nodes.draw_line(Vector2(ROUTE_X, from.position.y + from.size.y), Vector2(ROUTE_X, to.position.y), ROUTE_COLOR, 2.0)

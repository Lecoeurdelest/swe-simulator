class_name MailScreen
extends VBoxContainer
## DoomApply's Mail (GDD S06, ARCHITECTURE 11.4): one scrolling list, in this order: the grace-day line,
## the first-run coach mark, the waiting invites ([ Later ][ GO NOW ] inside each card), a rescinded
## offer (with the tip under it), the expiry notices, the rejections as one stack card with [Flip all]
## (the tip under it otherwise), the quiet no-reply footer and the Radar update. It shows the morning
## report, or later that day run.day_mail; the invites are always the live run.invites. [ Start day ] is
## the hub's pinned action row, outside the list. Buttons in the list PASS their input on, so a drag
## scrolls (Step 2 result).

signal go_now(invite: Dictionary)

const INVITE_CARD := preload("res://features/job_hunt/invite_card.tscn")
const COACH_MARK := preload("res://features/job_hunt/coach_mark.tscn")
const DUCKY_NOTE := preload("res://ui/components/ducky_note.tscn")
const WARNING_COLOR := Color(0.89411765, 0.23137255, 0.26666668)  # the grace day, as the rent warning
const DIM_COLOR := Color(0.54509807, 0.60784316, 0.7058824)
const FLIP_BUTTON := Vector2(80, 34)

var _folded: Dictionary = {}    # invite uid -> true once Later folded its card (this scene only)
var _flipped_day := -1          # the report day whose rejection stack was flipped open
var _built_key := 0             # what the list shows, hashed: it is rebuilt only when that changes
var _invite_cards: Array[InviteCard] = []
var _coach: CoachMark
var _flip_button: Button
var _tip: DuckyNote

@onready var _scroll: ScrollContainer = %MailScroll
@onready var _list: VBoxContainer = %MailList


func _ready() -> void:
	# Step 2: a saved scene bakes the deadzone it was saved with, so read the project's value.
	_scroll.scroll_deadzone = int(ProjectSettings.get_setting("gui/common/default_scroll_deadzone", 0))


## report = run.morning_report before Start day (morning = true: a Plan B morning greys GO NOW out), or
## run.day_mail later that day. coach = show the first-run invite coach mark (GDD 4.3).
func show_mail(report: Dictionary, morning: bool, coach: bool) -> void:
	var run := GameState.run
	var key := hash([report, run.invites, run.rescinded, run.energy, run.interviews_today, run.day, morning, coach])
	if key == _built_key and _list.get_child_count() > 0:
		return
	_built_key = key
	_clear()
	if bool(report.get("grace_day", false)):
		_add(_line_panel(Content.text("barks", "ui_grace_day"), WARNING_COLOR))
	if coach and not run.invites.is_empty():
		_coach = COACH_MARK.instantiate()
		_add(_coach)
	var plan_b := morning and bool(report.get("plan_b", false))
	for invite: Dictionary in run.invites:
		_add_invite(invite, plan_b)
	if _coach != null and not _invite_cards.is_empty():
		_coach.point(Content.text("barks", "coach_invite_no_research"), _invite_cards[0].go_button())
		_coach.visible = not _invite_cards[0].is_folded()  # it points at GO NOW: gone while Later folds it
	var tip := HuntTips.inbox(run, report)
	if not run.rescinded.is_empty():
		_add(_mail_card("", _from(run.rescinded, false), Content.text("emails", "mail_rescinded")))
		_add_tip(tip)  # its tip right under it: joke, then tip (GDD 8.1 rule 1)
	for notice: Variant in report.get("expired", []):
		var mail_id := str((notice as Dictionary).get("mail_id", "mail_invite_expired"))
		_add(_mail_card(Content.field("emails", mail_id, "subject"), _from(notice, true),
			Content.field("emails", mail_id, "body")))
	_add_rejections(report)
	if run.rescinded.is_empty():
		_add_tip(tip)
	var no_reply := int(report.get("no_reply", 0))
	if no_reply == 1:
		_add(_label(Content.text("barks", "ui_ghost_footer_one"), DIM_COLOR))
	elif no_reply > 1:
		_add(_label(Content.text("barks", "ui_ghost_footer", {"n": no_reply}), DIM_COLOR))
	if report.has("radar"):
		_add(_label(_radar_text(report["radar"]), Color.WHITE))


func invite_cards() -> Array[InviteCard]:
	return _invite_cards


func flip_button() -> Button:
	return _flip_button if is_instance_valid(_flip_button) else null


func tip_text() -> String:
	return _tip.tip_text if is_instance_valid(_tip) else ""


func coach_text() -> String:
	return _coach.text() if is_instance_valid(_coach) else ""


# ---------- building the list ----------

func _clear() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_invite_cards.clear()
	_coach = null
	_flip_button = null
	_tip = null


func _add(node: Control) -> void:
	_list.add_child(node)


## Mail's one Ducky note (HuntTips.inbox); "" adds nothing.
func _add_tip(tip_id: String) -> void:
	if tip_id.is_empty():
		return
	_tip = DUCKY_NOTE.instantiate()
	_add(_tip)
	_tip.tip_text = Content.field("tips", tip_id, "short")


func _add_invite(invite: Dictionary, plan_b: bool) -> void:
	var run := GameState.run
	var uid := int(invite.get("uid", -1))
	var company := Content.field("companies", str(invite.get("company_id", "")), "name")
	var args := {"player_name": run.player_name, "company": company,
		"job_title": Content.field("postings", str(invite.get("template_id", "")), "title")}
	var mail_id := str(invite.get("mail_id", ""))
	# "today or tomorrow" is only true on the day it arrived; the next day the card leaves it out.
	var line := ""
	if int(invite.get("day_received", -1)) == run.day:
		line = Content.text("barks", "ui_invite_line", {"company": company})
	var card: InviteCard = INVITE_CARD.instantiate()
	_add(card)
	card.setup(Content.field("emails", mail_id, "subject", args), company, Content.field("emails", mail_id, "body", args),
		line, UiText.cost(UiText.primary(Content.text("barks", "ui_go_now")), GameState.interview_cost(invite)),
		GameState.can_take_interview(invite) and not plan_b, bool(_folded.get(uid, false)))
	card.go_now_pressed.connect(func() -> void: go_now.emit(invite))
	var first := _invite_cards.is_empty()
	card.folded_changed.connect(func(folded: bool) -> void:
		_folded[uid] = folded
		if first and is_instance_valid(_coach):
			_coach.visible = not folded)
	_invite_cards.append(card)


## One rejection is shown as it is; two or more as one stack card, "N rejections" [Flip all], which
## opens in place to one entry each (GDD S06). A knockout's entry is the Parsinator's email, naming the
## knockout; a plain one is its stored mail_reject_* line.
func _add_rejections(report: Dictionary) -> void:
	var rejections: Array = report.get("rejections", [])
	if rejections.is_empty():
		return
	var panel := _panel()
	var rows := _vbox(4)
	panel.add_child(rows)
	_add(panel)
	var entries := _vbox(6)
	for rejection: Variant in rejections:
		entries.add_child(_rejection_entry(rejection))
	if rejections.size() > 1:
		var header := HBoxContainer.new()
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var count := _label(Content.text("barks", "ui_rejections", {"n": rejections.size()}), Color.WHITE)
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header.add_child(count)
		_flip_button = Button.new()
		_flip_button.text = Content.text("barks", "ui_flip_all")
		_flip_button.custom_minimum_size = FLIP_BUTTON
		_flip_button.focus_mode = Control.FOCUS_NONE
		_flip_button.mouse_filter = Control.MOUSE_FILTER_PASS
		header.add_child(_flip_button)
		rows.add_child(header)
		var day := int(report.get("day", -1))
		var flipped := _flipped_day == day
		entries.visible = flipped
		_flip_button.visible = not flipped
		_flip_button.pressed.connect(func() -> void:
			_flipped_day = day
			entries.show()
			_flip_button.hide())
	rows.add_child(entries)


func _rejection_entry(rejection: Variant) -> Control:
	var r: Dictionary = rejection if rejection is Dictionary else {}
	var entry := _vbox(0)
	entry.add_child(_label(_from(r, true), DIM_COLOR))
	var knockout: Dictionary = r.get("knockout", {})
	var text := ""
	if not knockout.is_empty():
		var reason := Content.text("postings", str(knockout.get("id", "")), knockout.get("args", {}))
		text = Content.field("emails", "mail_knockout", "body",
			{"player_name": GameState.run.player_name, "knockout": reason})
	elif not str(r.get("mail_id", "")).is_empty():
		text = Content.text("emails", str(r["mail_id"]))
	entry.add_child(_label(text, Color.WHITE))
	return entry


## An email card without buttons: subject (optional), who it's from, the body.
func _mail_card(subject: String, from: String, body: String) -> Control:
	var panel := _panel()
	var rows := _vbox(2)
	panel.add_child(rows)
	if not subject.is_empty():
		rows.add_child(_label(subject, Color.WHITE))
	rows.add_child(_label(from, DIM_COLOR))
	rows.add_child(_label(body, Color.WHITE))
	return panel


func _line_panel(text: String, color: Color) -> Control:
	var panel := _panel()
	panel.add_child(_label(text, color))
	return panel


## "Company - Job title" for a mail entry (with_title), or the company alone.
func _from(entry: Dictionary, with_title: bool) -> String:
	var company := Content.field("companies", str(entry.get("company_id", "")), "name")
	if not with_title:
		return company
	return "%s - %s" % [company, Content.field("postings", str(entry.get("template_id", "")), "title")]


## "Recruiter Radar [##------]", or "... [##------] -> [###-----]" when it moved this morning.
func _radar_text(radar: Dictionary) -> String:
	var total := int(radar.get("max", 0))
	var before := UiText.meter(int(radar.get("before", 0)), total)
	var after := UiText.meter(int(radar.get("after", 0)), total)
	var title := Content.text("barks", "ui_radar")
	return "%s %s" % [title, after] if before == after else "%s %s -> %s" % [title, before, after]


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", separation)
	return box


func _label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override(&"font_color", color)
	return label

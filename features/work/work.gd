extends Control
## The work state (GDD 4.5, 4.6, 5.14; ARCHITECTURE 19.7): the career run on one screen, the cheapest it can be. From the
## top: the information band (Day and what is next, the Studio chip, Runway, Burnout, the Ticket and the Codebase's
## 10 LEDs, the 60-day calendar strip), the Body (a grey box with the job and the latest news until M5's diorama), and
## the thumb band: the Hours notches, the dock and Back beside the speed control. Cards (events, reviews, notices) come up
## over it in the ModalLayer and stop the clock. Rules live in the sim: this scene shows `GameState.session` and calls
## GameState's career_* verbs (INV-01, INV-03). The clock is `_process`: whole days, only while nothing is open (INV-22).

const FEED_SHOWN := 5
const BURNOUT_COLOR := Color(0.99607843, 0.68235296, 0.20392157)        # the PrimaryButton amber
const DANGER_COLOR := Color(0.89411765, 0.23137255, 0.26666668)          # the warning red (late ticket, red runway)
const TICKET_COLOR := Color(0.16, 0.68, 1.0)
const PICK_LABELS: Dictionary = {"feature": "ui_pick_feature", "bugfix": "ui_pick_bugfix", "paydown": "ui_pick_paydown"}
const APP_STUB_ID := "app_stub"

var _hours_buttons: Array[Button] = []
var _speed_buttons: Array[Button] = []
var _shown_signature := ""       # what the card sheet shows now, so a refresh never reopens (and re-locks) it
var _shown_card: Dictionary = {}
var _stub_open := false          # a dock app's "not in this build" card is open
var _board_open := false         # the DoomApply board replaces the Body and the thumb band; the clock waits (INV-22)

@onready var _next_label: Label = %NextLabel
@onready var _studio_label: Label = %StudioLabel
@onready var _runway_label: Label = %RunwayLabel
@onready var _burnout_label: Label = %BurnoutLabel
@onready var _burnout_bar: HpBar = %BurnoutBar
@onready var _ticket_label: Label = %TicketLabel
@onready var _ticket_bar: HpBar = %TicketBar
@onready var _ticket_days: Label = %TicketDays
@onready var _codebase_label: Label = %CodebaseLabel
@onready var _rack: CodebaseRack = %Rack
@onready var _strip: CalendarStrip = %Strip
@onready var _job_label: Label = %JobLabel
@onready var _feed: Label = %Feed
@onready var _coach: CoachMark = %Coach
@onready var _hours_label: Label = %HoursLabel
@onready var _back_button: Button = %BackButton
@onready var _dock_buttons: Array[Button] = [%JobsDock, %HomeDock, %VideoDock, %DuckyDock]
@onready var _card: EventCard = %EventCard
@onready var _board: BoardPanel = %Board
@onready var _body: PanelContainer = %Body
@onready var _thumb_band: VBoxContainer = %ThumbBand
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	if OS.is_debug_build() and GameState.session == null:
		GameState.debug_career_quick_start(false)   # project_run mode="custom": a fresh run 1 on day 0
	var cfg := GameState.session.ctx.cfg
	_hours_buttons.assign([%Hours1, %Hours2, %Hours3, %Hours4, %Hours5])
	_speed_buttons.assign([%Speed0, %Speed1, %Speed2, %Speed3])
	_burnout_bar.max_value = cfg.burnout_max
	_burnout_bar.fill_color = BURNOUT_COLOR
	_ticket_bar.max_value = 100.0
	_ticket_bar.fill_color = TICKET_COLOR
	_burnout_label.text = Content.text("barks", "ui_burnout")
	_ticket_label.text = Content.text("barks", "ui_ticket")
	_codebase_label.text = Content.text("barks", "ui_codebase")
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	for dock_id: Array in [[0, "ui_tab_jobs"], [1, "ui_tab_home"], [2, "ui_tab_video"], [3, "ui_tab_ducky"]]:
		_dock_buttons[dock_id[0]].text = Content.text("barks", dock_id[1])
		_dock_buttons[dock_id[0]].pressed.connect(_open_board if dock_id[0] == 0 else _open_stub_app)
	var hours_group := ButtonGroup.new()
	for i: int in _hours_buttons.size():
		_hours_buttons[i].button_group = hours_group
		_hours_buttons[i].pressed.connect(_on_hours_pressed.bind(i + 1))
	var speed_group := ButtonGroup.new()
	for i: int in _speed_buttons.size():
		_speed_buttons[i].button_group = speed_group
		_speed_buttons[i].text = Content.text("barks", WorkHud.speed_label_id(i, cfg))
		_speed_buttons[i].pressed.connect(_on_speed_pressed.bind(i))
	_back_button.pressed.connect(Device.handle_back)
	_card.answered.connect(_on_card_answered)
	_coach.closed.connect(GameState.career_close_coach)
	_board.apply_pressed.connect(GameState.career_apply)
	_board.study_pressed.connect(GameState.career_study)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	GameState.run_changed.connect(_refresh)
	_refresh()
	if GameState.session.take_board_hint():   # after the layoff scene the board opens by itself (GDD 4.5)
		_open_board.call_deferred()


## The clock (D-01, D-13; INV-22): whole days, one `career_tick` each, only while nothing is open over the work state
## and the scene is not changing. A tick that opens a card or leaves for another phase ends the frame's days.
func _process(delta: float) -> void:
	var session := GameState.session
	if session == null or GameState.run.phase != GameFlow.Phase.WORK:
		return
	if session.is_blocked() or _card.is_open() or _stub_open or _board_open or _pause.is_open() or SceneRouter.busy:
		session.clock.hold()
		return
	for _day: int in session.clock.advance(session.ctx.cfg, delta):
		GameState.career_tick()
		if GameState.run.phase != GameFlow.Phase.WORK or session.is_blocked():
			break


## Back (the action bar's, Esc, Android): close a dock app's card or the board, resume from Pause, else open Pause. A
## card the player must answer stays; its "=" opens Pause too.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	if _stub_open:
		_close_stub_app()
		return true
	if _board_open:
		_close_board()
		return true
	GameState.save()   # opening Pause keeps the quiet days since the last save, in case the app is killed from here
	_pause.open()
	return true


# ---------- showing the run ----------

func _refresh() -> void:
	var session := GameState.session
	if session == null or GameState.run.phase != GameFlow.Phase.WORK:
		return
	var s := session.sim
	var ctx := session.ctx
	_refresh_top_band(s, ctx)
	_refresh_body(s)
	_refresh_controls(session)
	_refresh_card(session)
	_refresh_coach(session)
	if _board_open:
		_board.show_board(session)


func _refresh_top_band(s: SimState, ctx: SimContext) -> void:
	var cfg := ctx.cfg
	var next := WorkHud.next_on_calendar(ctx, s)
	if next.is_empty():
		_next_label.text = Content.text("barks", "ui_day", {"day": s.day})
	else:
		_next_label.text = Content.text("barks", "ui_next", {
			"day": s.day, "what": Content.text("barks", String(next["label_id"])), "days": int(next["offset"])})
	_studio_label.text = Content.text("barks", "ui_studio_chip", {"n": WorkHud.studio_count(s, cfg)})
	_runway_label.text = Content.text("barks", "ui_runway", {"months": WorkHud.runway_text(s)})
	_tint(_runway_label, DANGER_COLOR if WorkHud.runway_is_red(s, cfg) else Color.WHITE)
	_burnout_bar.value = s.burnout
	_burnout_bar.fill_color = DANGER_COLOR if s.burnout >= cfg.auto_resolve_from else BURNOUT_COLOR
	_ticket_bar.value = WorkHud.ticket_frac(s) * 100.0
	if s.employed:
		_ticket_days.text = "%dd" % WorkHud.ticket_days_left(s)
		_tint(_ticket_days, DANGER_COLOR if WorkHud.ticket_is_late(s) else Color.WHITE)
	else:
		_ticket_days.text = "-"
		_tint(_ticket_days, Color.WHITE)
	_rack.red = WorkHud.codebase_red_leds(s)
	_strip.set_items(WorkHud.calendar(ctx, s), cfg.calendar_days)


func _refresh_body(s: SimState) -> void:
	if s.employed:
		var company := Content.field("companies", s.job_company, "name")
		_job_label.text = Content.text("barks", "ui_job_line", {
			"level": Content.text("barks", WorkHud.level_label_id(s.level)), "company": company})
	else:
		_job_label.text = Content.text("barks", "ui_between_jobs")
	var lines: PackedStringArray = []
	var feed := GameState.session.feed
	for line: Dictionary in feed.slice(maxi(feed.size() - FEED_SHOWN, 0)):
		lines.append("D%d  %s" % [int(line["day"]), _feed_text(line)])
	_feed.text = "\n".join(lines)


func _refresh_controls(session: WorkSession) -> void:
	var s := session.sim
	_hours_label.text = "%s: %s" % [Content.text("barks", "ui_hours"), Content.text("barks", WorkHud.hours_label_id(s.hours))]
	var locked := s.day <= s.hours_lock_until
	for i: int in _hours_buttons.size():
		_hours_buttons[i].set_pressed_no_signal(i + 1 == s.hours)
		_hours_buttons[i].disabled = locked
	for i: int in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(i == session.clock.speed)


func _refresh_card(session: WorkSession) -> void:
	if _stub_open:
		return
	var card := session.current_card()
	if card.is_empty():
		_shown_signature = ""
		_shown_card = {}
		_card.hide_card()
		return
	var signature := JSON.stringify(card)
	if signature == _shown_signature and _card.is_open():
		return
	_shown_signature = signature
	_shown_card = card
	_card.show_card(_card_view(card))


func _refresh_coach(session: WorkSession) -> void:
	var id := "" if _stub_open or _board_open else session.coach_id()
	match id:
		WorkSession.COACH_SPEED:
			_coach.point(id, Content.text("barks", id), _speed_buttons[1])
		WorkSession.COACH_HOURS:
			_coach.point(id, Content.text("barks", id), _hours_buttons[2])
		WorkSession.COACH_STUDIO:
			_coach.point(id, Content.text("barks", id), null)
		_:
			_coach.clear()


# ---------- the player's controls ----------

func _on_hours_pressed(notch: int) -> void:
	GameState.career_set_hours(notch)


func _on_speed_pressed(position: int) -> void:
	GameState.career_set_speed(position)


## The DoomApply board (D-41): it takes the Body's and the thumb band's place, and the clock waits while it is open.
func _open_board() -> void:
	if _board_open or _stub_open or _card.is_open():
		return
	_board_open = true
	_body.hide()
	_thumb_band.hide()
	_board.show()
	_refresh()


func _close_board() -> void:
	_board_open = false
	_board.hide()
	_body.show()
	_thumb_band.show()
	_refresh()


func _open_stub_app() -> void:
	if _stub_open or _card.is_open():
		return
	_stub_open = true
	_card.show_card({"title": "", "text": Content.text("barks", "ui_app_stub"),
		"buttons": [{"id": APP_STUB_ID, "text": UiText.primary(Content.text("barks", "ui_ok")), "primary": true}]})


func _close_stub_app() -> void:
	_stub_open = false
	_card.hide_card()
	_refresh()


# ---------- cards ----------

## A card's button was pressed. The sheet closes first, so a next card that looks exactly like this one (two burnout
## warnings in a row) still opens fresh and re-arms its lock.
func _on_card_answered(button_id: String) -> void:
	if _stub_open:
		_close_stub_app()
		return
	var card := _shown_card
	_shown_signature = ""
	_shown_card = {}
	_card.hide_card()
	match String(card.get("kind", "")):
		"notice":
			GameState.career_dismiss_notice()
		WorkCards.K_EVENT:
			GameState.career_choose(button_id)
		WorkCards.K_REVIEW:
			GameState.career_begin_duel()
		WorkCards.K_PICK:
			GameState.career_pick_ticket(button_id)
		WorkCards.K_LEAVE:
			GameState.career_acknowledge()
		WorkCards.K_DUEL:
			GameState.career_begin_duel()
		WorkCards.K_OFFER:
			GameState.career_begin_offer()


## The words for a card: {title, text, buttons: [{id, text, primary}]}. Cards carry ids and numbers (WorkCards); the
## text comes from the JSON here.
func _card_view(card: Dictionary) -> Dictionary:
	var ok := [{"id": "ok", "text": UiText.primary(Content.text("barks", "ui_ok")), "primary": true}]
	match String(card.get("kind", "")):
		"notice":
			return _notice_view(card, ok)
		WorkCards.K_EVENT:
			return _event_view(card)
		WorkCards.K_REVIEW:
			return {"title": Content.text("barks", "ui_cal_review").to_upper(),
				"text": Content.field("work_events", String(card["event"]), "text"),
				"buttons": [{"id": "start", "text": UiText.primary(Content.text("barks", "ui_review_start")), "primary": true}]}
		WorkCards.K_PICK:
			var buttons: Array = []
			for pick: String in card["choices"]:
				var label := Content.text("barks", String(PICK_LABELS[pick]))
				if pick == "paydown":
					label = "%s - %s" % [label, Content.text("barks", "ui_pick_paydown_note")]
				buttons.append({"id": pick, "text": label, "primary": false})
			return {"title": "", "text": Content.text("barks", "ui_pick_prompt"), "buttons": buttons}
		WorkCards.K_LEAVE:
			return {"title": "", "text": Content.text("barks", "ui_forced_leave"), "buttons": ok}
		WorkCards.K_DUEL:
			return {"title": "", "text": Content.text("barks", "ui_interview_day", {
					"company": Content.field("companies", String(card["company"]), "name")}),
				"buttons": [{"id": "start", "text": UiText.primary(Content.text("barks", "ui_interview_start")), "primary": true}]}
		WorkCards.K_OFFER:
			return {"title": "", "text": Content.text("barks", "ui_offer_ready"), "buttons": ok}
	return {"title": "", "text": "", "buttons": ok}


func _notice_view(card: Dictionary, ok: Array) -> Dictionary:
	var style := String(card.get("style", WorkCards.INFO))
	if style == WorkCards.DUCKY:
		return {"title": Content.text("naming", "mascot"), "text": Content.field("tips", String(card["tip"]), "short"), "buttons": ok}
	var text := ""
	if card.has("literal"):
		text = tr(String(card["literal"]))
	elif String(card.get("id", "")) == "ui_auto_resolved":
		text = Content.text("barks", "ui_auto_resolved", {"choice": _choice_label(String(card["event"]), String(card["choice"]))})
	elif card.has("rating"):
		text = _review_result_text(card)
	elif card.has("id"):
		text = Content.text("barks", String(card["id"]), {"n": int(card.get("n", 0)),
			"company": _company_name(String(card.get("company", ""))), "day": int(card.get("day", 0))})
	elif card.has("event"):
		text = Content.field("work_events", String(card["event"]), "text")
	return {"title": "", "text": text, "buttons": ok}


func _event_view(card: Dictionary) -> Dictionary:
	var evt_id := String(card["event"])
	var args := _text_args(card.get("args", {}))
	var evt: Dictionary = Content.entry("work_events", evt_id)
	var buttons: Array = []
	for choice_id: String in card["choices"]:
		for choice: Dictionary in evt.get("choices", []):
			if String(choice["id"]) == choice_id:
				buttons.append({"id": choice_id, "text": UiText.fill(tr(String(choice["text"])), args), "primary": false})
	return {"title": "", "text": UiText.fill(tr(String(evt.get("text", evt_id))), args), "buttons": buttons}


func _review_result_text(card: Dictionary) -> String:
	var results: Dictionary = (Content.entry("work_events", String(card["event"])) as Dictionary).get("results", {})
	var text := UiText.fill(tr(String(results.get(String(card["rating"]), ""))), {"n": int(card["raise_pct"])})
	if bool(card.get("promoted", false)):
		text += "\n" + Content.text("barks", "ui_promoted", {"level": Content.text("barks", WorkHud.level_label_id(int(card["level"])))})
	return text


## A choice's label for the "Burnout picked: ..." line; "nothing" for an event that was skipped.
func _choice_label(evt_id: String, choice_id: String) -> String:
	var evt: Dictionary = Content.entry("work_events", evt_id)
	for choice: Dictionary in evt.get("choices", []):
		if String(choice["id"]) == choice_id:
			return tr(String(choice["text"]))
	return Content.text("barks", "ui_choice_none")


## The placeholders an event's text may use: {money} (k$) and {home} (the next tier up).
func _text_args(raw: Dictionary) -> Dictionary:
	return {
		"money": UiText.money_k(float(raw.get("money_k", 0.0))),
		"home": Content.text("barks", WorkHud.home_label_id(int(raw.get("home", 0)))),
		"coworker": "",
	}


func _feed_text(line: Dictionary) -> String:
	if line.has("literal"):
		return tr(String(line["literal"]))
	var args: Dictionary = line.get("args", {})
	var fill := {"money": UiText.money_k(float(args.get("money_k", 0.0))), "n": int(args.get("n", 0)),
		"company": _company_name(String(args.get("company", "")))}
	if String(line.get("field", "")).is_empty():
		return Content.text(String(line["file"]), String(line["id"]), fill)
	return Content.field(String(line["file"]), String(line["id"]), String(line["field"]), fill)


## A company's display name from its id ("" for none).
func _company_name(company_id: String) -> String:
	return Content.field("companies", company_id, "name") if not company_id.is_empty() else ""


func _tint(label: Label, color: Color) -> void:
	if color == Color.WHITE:
		label.remove_theme_color_override(&"font_color")
	else:
		label.add_theme_color_override(&"font_color", color)

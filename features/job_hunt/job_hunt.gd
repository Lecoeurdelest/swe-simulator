extends Control
## The job hunt hub (GDD S04-S06, ARCHITECTURE 11.4): the screen is your phone running DoomApply. From
## the top: the HUD (information only), the app header, the body (one app at a time: Jobs = the deck,
## Mail = the inbox, Study = BigOhNo), the action row and the dock. Sleep locks the phone (the night
## summary); after it, Mail holds the morning inbox until Start day. On the first run Ducky's coach
## marks sit over the card's header strip (GDD 4.3); a tap closes one for the run. Rules live in
## RunState and HuntTips: this scene shows `run` and calls GameState verbs.

enum App { JOBS, MAIL, STUDY }

const SLEEP_CONFIRM_PIPS := 2  # GDD S04: Sleep asks first while 2 or more pips are left
const MENU_MARK := "="         # stands in for the menu icon until the art pass (GDD S04 "[=]")
const WARNING_COLOR := Color(0.89411765, 0.23137255, 0.26666668)  # the rent countdown at 3 days (GDD 5.10)
const STUDY_JOKES: PackedStringArray = ["ui_study_joke_1", "ui_study_joke_2", "ui_study_joke_3"]
## Debug-only text, English on purpose (not player text): the DEBUG row is hidden in release builds.
const DEBUG_TOGGLE := "DEBUG"
const DEBUG_FAKE_INVITE := "Fake invite"
const DEBUG_RENT_OUT := "Rent runs out"
const DEBUG_REFUSED := "Refused: tired, or today's interview is used. It waits in Mail."
const DEBUG_NO_COMPANY := "No %s company left."

var _app := App.JOBS
var _busy := false          # a card is being sent or skipped: the deck ignores input until it's done
var _shown_uid := -1        # the board card the JobCard shows
var _flipped_once := false  # a card was flipped this session: the flip coach mark is done (GDD 4.3)
var _study_count := 0       # rotates BigOhNo's jokes (cosmetic)

@onready var _day: Label = %Day
@onready var _rent: Label = %Rent
@onready var _energy_label: Label = %EnergyLabel
@onready var _pips: PipBar = %Pips
@onready var _energy_count: Label = %EnergyCount
@onready var _radar_label: Label = %RadarLabel
@onready var _radar: Label = %Radar
@onready var _app_name: Label = %AppName
@onready var _invite_pill: PanelContainer = %InvitePill
@onready var _pill_text: Label = %PillText
@onready var _card: JobCard = %Card
@onready var _empty_deck: PanelContainer = %EmptyDeck
@onready var _empty_text: Label = %EmptyText
@onready var _mail: MailScreen = %MailPanel
@onready var _study_text: Label = %StudyText
@onready var _study_tip: DuckyNote = %StudyTip
@onready var _study_joke: Label = %StudyJoke
@onready var _knw_label: Label = %KnwLabel
@onready var _knw_bar: StatBar = %KnwBar
@onready var _coach: CoachMark = %Coach
@onready var _coach_spacer: Control = %CoachSpacer
@onready var _front_actions: HBoxContainer = %FrontActions
@onready var _menu_button: Button = %MenuButton
@onready var _skip_button: Button = %SkipButton
@onready var _apply_button: Button = %ApplyButton
@onready var _back_actions: HBoxContainer = %BackActions
@onready var _flip_back_button: Button = %FlipBackButton
@onready var _tailor_button: Button = %TailorButton
@onready var _app_actions: HBoxContainer = %AppActions
@onready var _app_back_button: Button = %AppBackButton
@onready var _study_button: Button = %StudyButton
@onready var _morning_actions: HBoxContainer = %MorningActions
@onready var _start_day_button: Button = %StartDayButton
@onready var _sleep_dock: DockButton = %SleepDock
@onready var _mail_dock: DockButton = %MailDock
@onready var _night: NightScreen = %NightScreen
@onready var _sleep_confirm: ConfirmDialog = %SleepConfirm
@onready var _pause: PauseMenu = %PauseMenu
@onready var _debug_row: VBoxContainer = %DebugRow
@onready var _debug_toggle: Button = %DebugToggle
@onready var _debug_status: Label = %DebugStatus
@onready var _debug_panel: VBoxContainer = %DebugPanel
## Each app's dock slot and body panel, in dock order.
@onready var _docks: Dictionary[App, DockButton] = {
	App.JOBS: %JobsDock, App.MAIL: %MailDock, App.STUDY: %StudyDock,
}
@onready var _panels: Dictionary[App, Control] = {
	App.JOBS: %JobsPanel, App.MAIL: %MailPanel, App.STUDY: %StudyPanel,
}


func _ready() -> void:
	if OS.is_debug_build() and GameState.run.background_id == "":
		GameState.debug_quick_start("graduate", GameFlow.Phase.JOB_HUNT)  # project_run mode="custom"
	var cfg := Content.balance
	_energy_label.text = Content.text("barks", "ui_energy")
	_radar_label.text = Content.text("barks", "ui_radar_short")
	_pill_text.text = Content.text("barks", "ui_invite_waiting")
	_empty_text.text = Content.text("barks", "ui_deck_empty", {"n": cfg.board_new_per_day})
	_study_text.text = Content.text("barks", "ui_study_title")
	_knw_label.text = Content.text("barks", "ui_stat_knw")
	_menu_button.text = MENU_MARK
	_skip_button.text = Content.text("barks", "ui_skip")
	_apply_button.text = UiText.cost(UiText.primary(Content.text("barks", "ui_apply")), cfg.cost_quick_apply)
	_flip_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_tailor_button.text = UiText.cost(UiText.primary(Content.text("barks", "ui_tailor")), cfg.cost_tailor_apply)
	_app_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_study_button.text = UiText.cost(UiText.primary(Content.text("barks", "ui_tab_study")), cfg.cost_study)
	_start_day_button.text = UiText.primary(Content.text("barks", "ui_start_day"))
	_docks[App.JOBS].text = Content.text("barks", "ui_tab_jobs")
	_docks[App.MAIL].text = Content.text("barks", "ui_tab_mail")
	_docks[App.STUDY].text = Content.text("barks", "ui_tab_study")
	_sleep_dock.text = Content.text("barks", "ui_sleep")
	for app: App in _docks:
		_docks[app].pressed.connect(_open_app.bind(app))
	_sleep_dock.pressed.connect(_on_sleep_pressed)
	_menu_button.pressed.connect(Device.handle_back)
	_flip_back_button.pressed.connect(Device.handle_back)
	_app_back_button.pressed.connect(Device.handle_back)
	_skip_button.pressed.connect(_skip)
	_apply_button.pressed.connect(_send.bind(false))
	_tailor_button.pressed.connect(_send.bind(true))
	_study_button.pressed.connect(_on_study)
	_start_day_button.pressed.connect(_on_start_day)
	_card.swiped.connect(_on_card_swiped)
	_card.tapped.connect(_on_card_tapped)
	_card.resized.connect(_fit_coach)
	_empty_deck.resized.connect(_fit_coach)
	_coach.resized.connect(_fit_coach)  # a new note's height is only known once its text has wrapped
	_mail.go_now.connect(_on_go_now)
	_mail.coach_closed.connect(GameState.close_coach_mark)
	_coach.closed.connect(GameState.close_coach_mark)
	_night.dismissed.connect(_refresh)
	_sleep_confirm.confirmed.connect(_sleep)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	GameState.run_changed.connect(_refresh)
	_setup_debug()
	if _morning_pending():
		_open_night()  # a Continue between Sleep and Start day replays the night, then the same morning
	_refresh()


## Back chain (ARCHITECTURE 9): close the top modal, unlock the night screen, flip the card back, return
## from an app to Jobs; else open Pause. [=], the action row's [ < Back ] and desktop Esc all land here.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	if _sleep_confirm.is_open():
		return _sleep_confirm.handle_back()
	if _night.is_open():
		return _night.handle_back()
	if _busy:
		return true  # a card is flying: Back waits for it
	if _current_app() == App.JOBS and _card.is_back():
		_card.flip(false)
		_refresh_actions()
		return true
	if _app != App.JOBS and not _morning_pending():
		_open_app(App.JOBS)
		return true
	_pause.open()
	return true


# ---------- showing the run ----------

func _refresh() -> void:
	var run := GameState.run
	var cfg := Content.balance
	var bg := Content.background(run.background_id)
	_day.text = Content.text("barks", "ui_day", {"day": run.day})
	_rent.text = _rent_text(run.rent_days_left)
	if run.rent_days_left <= cfg.rent_warning_days:
		_rent.add_theme_color_override(&"font_color", WARNING_COLOR)
	else:
		_rent.remove_theme_color_override(&"font_color")
	_pips.set_pips(cfg.energy_max, run.energy, run.commute_pips)
	_energy_count.text = "%d/%d" % [run.energy, cfg.energy_max - run.commute_pips]
	_radar.text = UiText.meter(run.pity_count, bg.pity_n if bg != null else 0)
	var app := _current_app()
	_app_name.text = _app_title(app)
	_invite_pill.visible = not run.invites.is_empty()
	_mail_dock.badge = not run.invites.is_empty()
	for each: App in _panels:
		_panels[each].visible = each == app
		_docks[each].set_pressed_no_signal(each == app)
	match app:
		App.MAIL:
			_mail.show_mail(_mail_report(), _morning_pending(), HuntTips.coach_invite(run))
		App.STUDY:
			_knw_bar.value = run.stat("knw")
	if not _busy:
		_sync_card(false)
	_refresh_actions()


## The action row follows the app and the card's face; an action you can't afford is greyed out
## (GDD 5.3). During the morning only Mail and its Start day are open.
func _refresh_actions() -> void:
	var run := GameState.run
	var cfg := Content.balance
	var app := _current_app()
	var morning := _morning_pending()
	var back := app == App.JOBS and _card.visible and _card.is_back()
	var has_card := not run.board.is_empty()
	_front_actions.visible = app == App.JOBS and not back and not morning
	_back_actions.visible = back and not morning
	_app_actions.visible = app != App.JOBS and not morning
	_morning_actions.visible = morning
	_skip_button.disabled = not has_card
	_apply_button.disabled = not has_card or run.energy < cfg.cost_quick_apply
	_tailor_button.disabled = run.energy < cfg.cost_tailor_apply
	_study_button.visible = app == App.STUDY
	# At the cap Study would only burn pips (GDD 5.1: KNOWLEDGE caps at stat_cap).
	_study_button.disabled = run.energy < cfg.cost_study or run.stat("knw") >= cfg.stat_cap
	for each: App in _docks:
		_docks[each].disabled = morning and each != App.MAIL
	_sleep_dock.disabled = morning
	_update_coach()


## Shows the board's top card, or the empty deck. again = re-show it even if it is the same card
## (after a skip on a one-card deck), with the rise from the stack.
func _sync_card(again: bool) -> void:
	var board := GameState.run.board
	_card.visible = not board.is_empty()
	_empty_deck.visible = board.is_empty()
	if board.is_empty():
		_shown_uid = -1
		return
	var top: Dictionary = board[0]
	var odds := GameState.card_odds(top)
	if int(top["uid"]) == _shown_uid and not again:
		_card.update_odds(odds, GameState.run.referral_tokens)
		return
	_shown_uid = int(top["uid"])
	_card.show_card(top, odds, GameState.run.referral_tokens)
	if again:
		_card.rise()


func _current_app() -> App:
	return App.MAIL if _morning_pending() else _app


## Sleep leaves a morning report until Mail's Start day (GDD 4.1: Sleep -> night -> morning inbox).
func _morning_pending() -> bool:
	return not GameState.run.morning_report.is_empty()


## Mail shows the morning before Start day, then the day's mail until the next Sleep.
func _mail_report() -> Dictionary:
	return GameState.run.morning_report if _morning_pending() else GameState.run.day_mail


func _rent_text(days: int) -> String:
	if days <= 0:
		return Content.text("barks", "ui_rent_due_today")  # the grace day and the Plan B morning
	if days == 1:
		return Content.text("barks", "ui_rent_due_one")
	return Content.text("barks", "ui_rent_due", {"days": days})


func _app_title(app: App) -> String:
	match app:
		App.STUDY:
			return Content.text("naming", "app_study")
	return Content.text("naming", "app_jobs")  # Jobs and DoomApply's Mail


## Opening Study starts it fresh (no joke, no tip).
func _open_app(app: App) -> void:
	if _busy:
		_refresh()  # a dock tap mid-animation only puts the dock's highlight back
		return
	if app != App.JOBS and _card.is_back():
		_card.flip(false)
	var from := _app
	_app = app
	if app == App.STUDY and from != App.STUDY:
		_study_joke.hide()
		_study_tip.hide()
	_refresh()


# ---------- the deck ----------

## Swipe right = Quick Apply, swipe left = Skip (GDD S04). A refused swipe settles back.
func _on_card_swiped(direction: int) -> void:
	if direction > 0 and _can_act(false) and GameState.run.energy >= Content.balance.cost_quick_apply:
		_send(false)
	elif direction < 0 and _can_act(false):
		_skip()
	else:
		_card.settle()


func _on_card_tapped() -> void:
	if _busy or _current_app() != App.JOBS:
		return
	if not _card.is_back():
		_flipped_once = true
	_card.flip(not _card.is_back())
	_refresh_actions()


func _can_act(back: bool) -> bool:
	return not _busy and _current_app() == App.JOBS and _shown_uid != -1 and _card.is_back() == back


## APPLY (Quick Apply, 1 pip) from the front, or TAILOR & APPLY (2 pips, maybe with a referral) from
## the back. The first applications of a run get the full Parsinator scan, then the SENT stamp
## (GDD S04); the card flies off right and the next one rises.
func _send(tailored: bool) -> void:
	if not _can_act(tailored):
		return
	var uid := _shown_uid
	_busy = true
	_card.set_locked(true)
	var sent := GameState.tailor_apply(uid, _card.use_referral()) if tailored else GameState.quick_apply(uid)
	if not sent:
		_finish_card(false)
		_card.settle()
		return
	var run := GameState.run
	var hits := int(run.applications.back().get("hits", 0))
	await _card.play_sent(run.total_applications <= Content.balance.full_scan_animations, hits)
	await _card.fling(1)
	_finish_card(true)


## SKIP or swipe left: the card goes to the back of the deck and flies off left.
func _skip() -> void:
	if not _can_act(false):
		return
	_busy = true
	_card.set_locked(true)
	if not GameState.skip_card(_shown_uid):
		_finish_card(false)
		_card.settle()
		return
	await _card.fling(-1)
	_finish_card(true)


func _finish_card(next: bool) -> void:
	_busy = false
	_card.set_locked(false)
	if next:
		_sync_card(true)
	_refresh()


# ---------- first-run coach marks (GDD 4.3) ----------

## Which coach mark the Jobs screen shows now (HuntTips.coach), "" for none. Never mid-animation. The
## invite's mark lives in Mail (MailScreen). A tap on a mark closes it: GameState.close_coach_mark
## keeps it closed for the run.
func _coach_id() -> String:
	if _busy or _current_app() != App.JOBS or _night.is_open():
		return ""
	return HuntTips.coach(GameState.run, _card.visible, _card.is_back(), _flipped_once)


func _update_coach() -> void:
	var id := _coach_id()
	match id:
		"coach_apply":
			_coach.point(id, Content.text("barks", id), _apply_button, true)
		"coach_flip":
			_coach.point(id, Content.text("barks", id), _card)
		"coach_sleep":
			_coach.point(id, Content.text("barks", id), _sleep_dock)
		_:
			_coach.clear()
	_fit_coach()


## The mark's bottom edge sits on the bottom of the card's header strip (over the empty-deck note when
## the deck is empty): the spacer under it in the body's overlay is that tall. Only while the mark shows
## on Jobs: a card that hasn't been laid out yet (the hub opened on Mail) reports a height sized for
## zero-width text, and the spacer must never push the thumb band off the screen.
func _fit_coach() -> void:
	var below := 0.0
	if _coach.visible:
		if _card.is_visible_in_tree():
			below = _card.size.y - _card.strip_bottom()
		elif _empty_deck.is_visible_in_tree():
			below = _empty_deck.size.y
		var body := _coach_spacer.get_parent().get_parent() as Control
		below = minf(below, body.size.y - _coach.get_combined_minimum_size().y)
	_coach_spacer.custom_minimum_size.y = maxf(roundf(below), 0.0)


# ---------- the other apps and the day ----------

## STUDY 2 (BigOhNo): KNOWLEDGE +5 up to the cap, one of the three jokes, and on the run's first study
## Ducky's tip_fundamentals (GDD 8.3).
func _on_study() -> void:
	if not GameState.study():  # greyed out when it can't be paid for (GDD 5.3)
		return
	_study_joke.text = Content.text("barks", STUDY_JOKES[posmod(_study_count, STUDY_JOKES.size())])
	_study_count += 1
	_study_joke.show()
	var tip := HuntTips.studied(GameState.run)
	if not tip.is_empty():
		_study_tip.tip_text = Content.field("tips", tip, "short")
		_study_tip.show()
		GameState.mark_tip_shown(tip)


## GDD S04: with 2 or more pips left, Sleep asks first ([ < Back ][ SLEEP ]).
func _on_sleep_pressed() -> void:
	if _busy or _morning_pending():
		_refresh()
		return
	var energy := GameState.run.energy
	if energy >= SLEEP_CONFIRM_PIPS:
		_sleep_confirm.open(Content.text("barks", "ui_sleep_confirm", {"n": energy}), Content.text("barks", "ui_sleep"))
	else:
		_sleep()


## One commit (ARCHITECTURE 7.1), then the phone locks: the night summary, then Mail with the morning.
func _sleep() -> void:
	if _card.is_back():
		_card.flip(false)
	GameState.sleep()
	_open_night()
	_refresh()


## The lock screen's one notification card (GDD S04) from the morning report's night numbers, with at
## most one tip (HuntTips.night: the first referral, 8 Quick Applies without an invite, or a
## Tailor & Apply).
func _open_night() -> void:
	var run := GameState.run
	var night: Dictionary = run.morning_report.get("night", {})
	var summary := "%s - %s" % [
		Content.text("barks", "ui_night_summary", {"n": int(night.get("applied", 0)),
			"r": int(night.get("rejected", 0)), "g": int(night.get("ghosted", 0))}),
		_rent_text(int(night.get("rent_days_left", run.rent_days_left)))]
	var tip := HuntTips.night(run, Content.background(run.background_id))
	var tip_text := ""
	if not tip.is_empty():
		tip_text = Content.field("tips", tip, "short")
		GameState.mark_tip_shown(tip)
	_night.open(Content.text("naming", "app_jobs"), summary, tip_text)


## Mail "Start day": back to the deck, or Plan B (GameState changes the phase).
func _on_start_day() -> void:
	_app = App.JOBS
	GameState.start_day()


## Mail "GO NOW". From the morning inbox it starts the day first (a Plan B morning greys GO NOW out, so
## Start day can't end the run here); then the interview (GameState checks the pips and the day's slot).
func _on_go_now(invite: Dictionary) -> void:
	if _busy or _night.is_open():
		return
	_app = App.MAIL
	if _morning_pending():
		GameState.start_day()
		if GameState.run.phase != GameFlow.Phase.JOB_HUNT:
			return
	GameState.start_interview(invite)


# ---------- debug (debug builds only) ----------

func _setup_debug() -> void:
	_debug_row.visible = OS.is_debug_build()
	if not _debug_row.visible:
		return
	_debug_toggle.text = DEBUG_TOGGLE
	_debug_toggle.toggled.connect(func(on: bool) -> void: _debug_panel.visible = on)
	%FakeLabel.text = DEBUG_FAKE_INVITE
	%RentOutButton.text = DEBUG_RENT_OUT
	for pair: Array in [[%FakeMidButton, "mid"], [%FakeStartupButton, "startup"], [%FakeBigButton, "big"]]:
		var button: Button = pair[0]
		button.text = Content.field("tiers", pair[1], "tag")
		button.pressed.connect(_debug_fake_invite.bind(pair[1]))
	%RentOutButton.pressed.connect(GameState.end_run_plan_b)


## A waiting invite of that tier, then straight into its interview, as the Step 4 stub did.
func _debug_fake_invite(tier_id: String) -> void:
	var invite := GameState.debug_fake_invite(tier_id)
	if invite.is_empty():
		_debug_status.text = DEBUG_NO_COMPANY % tier_id
		return
	GameState.start_interview(invite)
	if GameState.run.phase == GameFlow.Phase.JOB_HUNT:
		_debug_status.text = DEBUG_REFUSED

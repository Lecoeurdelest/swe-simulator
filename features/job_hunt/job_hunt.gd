extends Control
## Step 3 stub of the job hunt (GDD S04): the HUD basics plus buttons that call the real verbs.
## Step 5 replaces it with DoomApply (the deck, CV, Mail, Study and the dock).

## Debug stand-in for a morning invite; Step 5 builds real ones in run.invites.
const FAKE_INVITE: Dictionary = {
	"app_uid": 0, "company_id": "co_beigeware", "template_id": "job_mid_backend", "tier": "mid",
}
## Debug-only stub text and buttons, English on purpose (not player text): Step 5 replaces them.
const DEBUG_FAKE_INVITE := "Fake invite (Mid)"
const DEBUG_RENT_OUT := "Rent runs out"
const DEBUG_KNOWLEDGE := "Knowledge %d"
const DEBUG_INTERVIEWS_TODAY := "Interviews today: %d/%d"
const DEBUG_TOO_TIRED := "Too tired to study (costs %d energy)."
const DEBUG_NO_INTERVIEW := "No interview: it needs %d energy and today's slot."

@onready var _day: Label = %Day
@onready var _rent: Label = %Rent
@onready var _energy: Label = %Energy
@onready var _knowledge: Label = %Knowledge
@onready var _header: Label = %Header
@onready var _status: Label = %Status
@onready var _fake_invite_button: Button = %FakeInviteButton
@onready var _rent_out_button: Button = %RentOutButton
@onready var _pause_button: Button = %PauseButton
@onready var _study_button: Button = %StudyButton
@onready var _sleep_button: Button = %SleepButton
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	_header.text = Content.text("naming", "app_jobs")
	_study_button.text = Content.text("barks", "ui_tab_study")
	_sleep_button.text = Content.text("barks", "ui_sleep")
	_fake_invite_button.text = DEBUG_FAKE_INVITE
	_rent_out_button.text = DEBUG_RENT_OUT
	_pause_button.pressed.connect(Device.handle_back)
	_fake_invite_button.pressed.connect(_on_fake_invite)
	_rent_out_button.pressed.connect(GameState.end_run_plan_b)
	_study_button.pressed.connect(_on_study)
	_sleep_button.pressed.connect(GameState.sleep)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	GameState.run_changed.connect(_refresh)
	_refresh()


## [=] is the hub's on-screen Back: it opens Pause, and Back again resumes (ARCHITECTURE 9).
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	_pause.open()
	return true


func _refresh() -> void:
	var run: RunState = GameState.run
	var cfg: BalanceConfig = Content.balance
	_day.text = Content.text("barks", "ui_day", {"day": run.day})
	if run.rent_days_left == 1:
		_rent.text = Content.text("barks", "ui_rent_due_one")
	else:
		_rent.text = Content.text("barks", "ui_rent_due", {"days": run.rent_days_left})
	_energy.text = "%s %d/%d" % [Content.text("barks", "ui_energy"), run.energy, cfg.energy_max - run.commute_pips]
	_knowledge.text = DEBUG_KNOWLEDGE % run.stat("knw")
	_status.text = DEBUG_INTERVIEWS_TODAY % [run.interviews_today, cfg.max_interviews_per_day]


func _on_study() -> void:
	if not GameState.study():
		_status.text = DEBUG_TOO_TIRED % Content.balance.cost_study


func _on_fake_invite() -> void:
	GameState.start_interview(FAKE_INVITE)
	if GameState.run.phase == GameFlow.Phase.JOB_HUNT:  # refused: too tired, or today's interview is used
		_status.text = DEBUG_NO_INTERVIEW % Content.balance.cost_interview

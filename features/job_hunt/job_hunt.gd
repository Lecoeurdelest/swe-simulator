extends Control
## Step 3 stub of the job hunt (GDD S04): the HUD basics plus buttons that call the real verbs.
## Step 5 replaces it with DoomApply (the deck, CV, Mail, Study and the dock).

## Debug stand-in for a morning invite; Step 5 builds real ones in run.invites.
const FAKE_INVITE: Dictionary = {
	"app_uid": 0, "company_id": "co_beigeware", "template_id": "job_mid_backend", "tier": "mid",
}

@onready var _day: Label = %Day
@onready var _rent: Label = %Rent
@onready var _energy: Label = %Energy
@onready var _knowledge: Label = %Knowledge
@onready var _status: Label = %Status
@onready var _fake_invite_button: Button = %FakeInviteButton
@onready var _rent_out_button: Button = %RentOutButton
@onready var _pause_button: Button = %PauseButton
@onready var _study_button: Button = %StudyButton
@onready var _sleep_button: Button = %SleepButton
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
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
	_day.text = tr("Day {day}").format({"day": run.day})
	if run.rent_days_left == 1:
		_rent.text = tr("Rent due TOMORROW")
	else:
		_rent.text = tr("Rent due in {days} days").format({"days": run.rent_days_left})
	_energy.text = "%s %d/%d" % [tr("Energy"), run.energy, cfg.energy_max - run.commute_pips]
	_knowledge.text = "Knowledge %d" % run.stat("knw")
	_status.text = "Interviews today: %d/%d" % [run.interviews_today, cfg.max_interviews_per_day]


func _on_study() -> void:
	if not GameState.study():
		_status.text = "Too tired to study (costs %d energy)." % Content.balance.cost_study


func _on_fake_invite() -> void:
	GameState.start_interview(FAKE_INVITE)
	if GameState.run.phase == GameFlow.Phase.JOB_HUNT:  # refused: too tired, or today's interview is used
		_status.text = "No interview: it needs %d energy and today's slot." % Content.balance.cost_interview

extends Node
## Autoload "GameState" (no class_name: it would clash with the autoload name).
## Owns the RunState, the run's RNG, the phase and the settings file.
## Scenes read `run` and call verbs. Only change_phase() changes the phase.
## Every verb that commits a player action ends with _commit() (save + HUD refresh).

signal phase_changed(from: GameFlow.Phase, to: GameFlow.Phase)
signal run_changed   # energy, rent, stats, board... changed: refresh the HUD

const SETTINGS_PATH := "user://settings.cfg"

var run: RunState = RunState.new()
var rng := RandomNumberGenerator.new()
var settings := ConfigFile.new()
var preselect_background: String = ""   # set by retry(): Background select focuses this card


func _ready() -> void:
	settings.load(SETTINGS_PATH)  # a missing file just means defaults


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			save()
			if run.phase == GameFlow.Phase.INTERVIEW:
				get_tree().paused = true  # interview.gd shows "Ready? Tap to continue", then unpauses
		NOTIFICATION_WM_CLOSE_REQUEST:
			save()


# ---------- settings (meta + options; never part of the run) ----------

func setting(section: String, key: String, default: Variant) -> Variant:
	return settings.get_value(section, key, default)


func set_setting(section: String, key: String, value: Variant) -> void:
	settings.set_value(section, key, value)
	settings.save(SETTINGS_PATH)


# ---------- saving ----------

## Writes only while a run is live (JOB_HUNT / INTERVIEW / OFFER); a no-op otherwise.
func save() -> void:
	if not GameFlow.is_saved(run.phase):
		return
	run.rng_state = str(rng.state)
	SaveIO.write(run)


func _commit() -> void:
	save()
	run_changed.emit()


# ---------- flow ----------

func change_phase(to: GameFlow.Phase) -> void:
	var from := run.phase
	if not GameFlow.can_transition(from, to):
		push_error("Illegal phase change %s -> %s" % [GameFlow.Phase.find_key(from), GameFlow.Phase.find_key(to)])
		return
	run.phase = to
	if GameFlow.deletes_save(from, to):
		SaveIO.delete()
	save()
	phase_changed.emit(from, to)


func start_new_game() -> void:  # Title: "Tap to start"
	run = RunState.new()
	var intro_seen: bool = setting("meta", "intro_seen", false)
	change_phase(GameFlow.Phase.BACKGROUND_SELECT if intro_seen else GameFlow.Phase.INTRO)


func replay_intro() -> void:  # Title: "Replay intro"
	run = RunState.new()
	change_phase(GameFlow.Phase.INTRO)


func finish_intro() -> void:  # the intro ended, or Skip, or Android Back
	set_setting("meta", "intro_seen", true)
	change_phase(GameFlow.Phase.BACKGROUND_SELECT)


func continue_game() -> void:
	var loaded := SaveIO.read()
	if loaded == null or not GameFlow.can_resume(loaded.phase):
		start_new_game()  # never leave Continue dead
		return
	var resume_at := loaded.phase
	run = loaded
	run.phase = GameFlow.Phase.TITLE
	rng.seed = run.rng_seed.to_int()   # seed first: setting seed resets state
	rng.state = run.rng_state.to_int()
	change_phase(resume_at)


## Plan B "Retry" and Hired "New run": a brand-new RunState, same background preselected.
func retry() -> void:
	var from := run.phase
	preselect_background = run.background_id
	run = RunState.new()
	run.phase = from  # keeps the transition legal; leaving PHASE2_STUB deletes the save
	change_phase(GameFlow.Phase.BACKGROUND_SELECT)


## Pause "Quit to title", Background select Back, ending "Title". The save survives for Continue.
func quit_to_title() -> void:
	change_phase(GameFlow.Phase.TITLE)


func choose_background(bg_id: String, player_name: String, run_seed: int = 0) -> void:
	_init_run(bg_id, player_name, run_seed if run_seed != 0 else randi())  # the global RNG only picks the seed
	change_phase(GameFlow.Phase.JOB_HUNT)


## Debug only: set a run up in place so `project_run mode="custom"` can launch one feature scene.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched.
func debug_quick_start(bg_id: String, phase: GameFlow.Phase, run_seed: int = 20260926) -> void:
	run = RunState.new()
	_init_run(bg_id, "Alex", run_seed)
	run.phase = phase


func _init_run(bg_id: String, player_name: String, run_seed: int) -> void:
	var bg := Content.background(bg_id)
	var cfg := Content.balance
	rng.seed = run_seed
	run.rng_seed = str(run_seed)
	run.background_id = bg_id
	run.player_name = player_name
	run.stats.assign({"knw": bg.start_knw, "exp": bg.start_exp, "net": bg.start_net})
	run.commute_pips = bg.commute_pips
	run.commute_minutes = bg.commute_minutes
	run.energy = cfg.energy_max - bg.commute_pips
	run.rent_days_left = bg.runway_days
	run.referral_tokens = bg.referral_tokens
	run.lone_wolf = bg.teamwork_mult < bg.teamwork_mult_after_network
	var gap_pool: Array = Content.entries("naming").get("_gap_topic_pool", [])
	run.gap_topics.assign(Odds.pick(rng, gap_pool, bg.gap_topics_count))
	run.first_run = int(setting("meta", "run_count", 0)) == 0


# ---------- job hunt verbs (Step 5 fills these in; each ends with _commit()) ----------

func study() -> bool:
	var cfg := Content.balance
	if not run.spend_energy(cfg.cost_study):
		return false
	run.stats["knw"] = mini(run.stats["knw"] + cfg.study_knw_gain, cfg.stat_cap)
	_commit()
	return true


## Night tick + (Step 5) morning reveal and board refill into run.morning_report: ONE commit,
## so a kill between "night" and "morning" can't lose or repeat the reveal.
func sleep() -> void:
	run.sleep(Content.balance)
	_commit()


# ---------- interview ----------

## Inbox "GO NOW": pay energy, freeze the interview (seed + questions), go.
func start_interview(invite: Dictionary) -> void:
	var cfg := Content.balance
	var tier_data := Content.tier(invite["tier"])
	var bg := Content.background(run.background_id)
	var cost := cfg.cost_interview + (bg.interview_travel_pips if tier_data.in_person else 0)
	if run.interviews_today >= cfg.max_interviews_per_day or not run.spend_energy(cost):
		return
	run.interviews_today += 1
	run.interview = {
		"invite_uid": invite["app_uid"], "company_id": invite["company_id"],
		"template_id": invite["template_id"], "tier": invite["tier"],
		"seed": str(rng.randi()), "tired": Odds.is_tired(cfg, run.energy),
		"question_ids": [],  # Step 4: pick from the tier's pools minus run.seen_question_ids
		"probe_line": "",    # Step 4: lie-probe roll (GDD 5.8.5)
	}
	change_phase(GameFlow.Phase.INTERVIEW)  # saves the checkpoint


## won = K.O. or committee win. busted = the lie probe ended in BUSTED (company blacklisted).
func finish_interview(won: bool, composure_left: float, busted: bool = false) -> void:
	var iv := run.interview
	var company_id: String = iv.get("company_id", "")
	run.interviews_taken += 1
	run.times_met_dana += 1
	run.dana_last_company = company_id
	if busted:
		run.blacklist.append(company_id)
	if won:
		var tier_data := Content.tier(iv["tier"])
		var bg := Content.background(run.background_id)
		run.offer = {
			"company_id": company_id, "template_id": iv["template_id"], "tier": iv["tier"],
			"salary": Odds.offer_salary(Content.balance, tier_data, bg, composure_left, bg.composure_max),
			"office_days": tier_data.office_days, "negotiated": false,
			# Step 6: job_title, perks, fine_print, equity_text (picked with the interview's RNG)
		}
	run.interview = {}
	change_phase(GameFlow.Phase.OFFER if won else GameFlow.Phase.JOB_HUNT)


# ---------- offer and endings ----------

func answer_offer(accept: bool) -> void:
	var company_id: String = run.offer.get("company_id", "")
	if not accept:  # Decline (after the confirm dialog): blacklisted, back to the same day
		run.blacklist.append(company_id)
		run.offer = {}
		change_phase(GameFlow.Phase.JOB_HUNT)
		return
	# Step 6/8: an unconfessed degree-claim Lie rolls tier.background_check here -> rescinded -> JOB_HUNT.
	var bg := Content.background(run.background_id)
	var flags: Array = Content.entries("companies").get(company_id, {}).get("red_flags", [])
	run.employment = run.offer.duplicate(true)
	run.dream_score = Odds.dream_score(Content.balance, run.offer["salary"], run.offer["office_days"],
		run.commute_minutes, flags.size(), run.rent_days_left, bg.runway_days)
	_count_finished_run()
	change_phase(GameFlow.Phase.PHASE2_STUB)


## Morning with rent at 0, no invite, grace day used (or none waiting).
func end_run_plan_b() -> void:
	_count_finished_run()
	change_phase(GameFlow.Phase.GAME_OVER)


func _count_finished_run() -> void:
	set_setting("meta", "run_count", int(setting("meta", "run_count", 0)) + 1)

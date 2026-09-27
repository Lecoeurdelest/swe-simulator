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
## Background select focuses this card: the last background played (settings meta "last_background",
## GDD S03), "" before the first run (The Graduate then).
var preselect_background: String = ""


func _ready() -> void:
	settings.load(SETTINGS_PATH)  # a missing file just means defaults
	preselect_background = str(setting("meta", "last_background", ""))


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
	if GameFlow.deletes_save(from, to):  # the run is over: its save goes, and it counts once
		SaveIO.delete()
		_count_finished_run()
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
	_init_run(bg_id, player_name, run_seed if run_seed != 0 else new_run_seed())
	preselect_background = bg_id
	set_setting("meta", "last_background", bg_id)
	change_phase(GameFlow.Phase.JOB_HUNT)


## A fresh run seed: the global RNG only ever picks seeds. Never 0, which means "pick one" above.
## Background select picks it when it opens, so its card can show the gaps this seed will roll.
func new_run_seed() -> int:
	var run_seed := 0
	while run_seed == 0:
		run_seed = randi()
	return run_seed


## The gap topics a run with this seed will roll (GDD S03 shows them before CHOOSE). It matches
## _init_run() because the gap roll is the run RNG's first draw after seeding.
func preview_gap_topics(bg_id: String, run_seed: int) -> Array:
	var bg := Content.background(bg_id)
	if bg == null:
		return []
	var preview := RandomNumberGenerator.new()
	preview.seed = run_seed
	return Odds.pick(preview, _gap_pool(), bg.gap_topics_count)


## Debug only: set a run up in place so `project_run mode="custom"` can launch one feature scene.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched.
func debug_quick_start(bg_id: String, phase: GameFlow.Phase, run_seed: int = 20260926) -> void:
	run = RunState.new()
	_init_run(bg_id, "Alex", run_seed)
	run.phase = phase


## Debug only (the hub's DEBUG row keeps an interview one tap away): a waiting invite from the tier's
## first MVP company that isn't blacklisted, for the tier's first open posting, as if it arrived this
## morning. No application backs it, so it never probes. No dice. {} when the tier has no company left.
func debug_fake_invite(tier_id: String) -> Dictionary:
	var company_id := _first_entry_id("companies", func(id: String, e: Dictionary) -> bool:
		return str(e.get("tier", "")) == tier_id and bool(e.get("mvp", false)) and not run.blacklist.has(id))
	var template_id := _first_entry_id("postings", func(_id: String, e: Dictionary) -> bool:
		return str(e.get("tier", "")) == tier_id and str(e.get("company", "any")) == "any" \
			and not bool(e.get("should", false)))
	if company_id.is_empty() or template_id.is_empty():
		return {}
	var invite := {
		"uid": run.new_uid(), "app_uid": -1, "company_id": company_id, "template_id": template_id,
		"tier": tier_id, "day_received": run.day, "kind": "rolled", "mail_id": "mail_invite_" + tier_id,
	}
	run.invites.append(invite)
	_commit()
	return invite.duplicate()


## The first id, in sorted order, of a content file's entries that passes test(id, entry).
func _first_entry_id(file: String, test: Callable) -> String:
	var entries := Content.entries(file)
	var ids: Array = entries.keys()
	ids.sort()
	for id: Variant in ids:
		var entry: Variant = entries[id]
		if entry is Dictionary and bool(test.call(str(id), entry)):
			return str(id)
	return ""


## The background's starting numbers, the name, the seed, the gap topics, first_run, then the
## day-1 board, all on the run RNG in this order. Keep the gap roll the first draw after seeding:
## preview_gap_topics() shows it on the Background select card.
func _init_run(bg_id: String, player_name: String, run_seed: int) -> void:
	var bg := Content.background(bg_id)
	var cfg := Content.balance
	rng.seed = run_seed
	run.rng_seed = str(run_seed)
	run.set_background(cfg, bg)
	run.player_name = player_name
	run.gap_topics.assign(Odds.pick(rng, _gap_pool(), bg.gap_topics_count))
	run.first_run = int(setting("meta", "run_count", 0)) == 0
	run.deal_board(cfg, _tiers(), _hunt_content(), rng)


func _gap_pool() -> Array:
	return Content.entries("naming").get("_gap_topic_pool", [])


# ---------- job hunt verbs (each committed action ends with _commit()) ----------

## Swipe right or APPLY: Quick Apply with the CV as set (1 pip). False when refused: the card is
## gone, its company is blacklisted, or there isn't enough energy.
func quick_apply(card_uid: int) -> bool:
	return _apply(card_uid, false, false)


## Card back TAILOR & APPLY (2 pips), optionally spending a referral token.
func tailor_apply(card_uid: int, use_referral: bool) -> bool:
	return _apply(card_uid, true, use_referral)


func _apply(card_uid: int, tailored: bool, referral: bool) -> bool:
	if run.apply_card(Content.balance, _tiers(), _bg(), _hunt_content(), card_uid, tailored, referral).is_empty():
		return false
	_commit()
	return true


## Swipe left or SKIP: the card goes to the back of the deck.
func skip_card(card_uid: int) -> bool:
	if not run.skip_card(card_uid):
		return false
	_commit()
	return true


## A CV screen segment tap (GDD S05): free and instant. It is saved when the screen closes (commit_cv).
func set_cv_level(line: String, level: String) -> bool:
	if not run.set_cv_level(line, level):
		return false
	run_changed.emit()
	return true


## Leaving the CV screen (DONE or Back): the CV change is one committed action (ARCHITECTURE 8).
func commit_cv() -> void:
	_commit()


func study() -> bool:
	var cfg := Content.balance
	if not run.spend_energy(cfg.cost_study):
		return false
	run.stats["knw"] = mini(run.stats["knw"] + cfg.study_knw_gain, cfg.stat_cap)
	_commit()
	return true


## Sleep: the night tick, the morning reveal, the board refill, the day-2 guarantee and the rent
## check all land in run.morning_report with exactly ONE save, so a kill right after Sleep resumes on
## the same morning and a kill before it replays the same dice (ARCHITECTURE 7.1).
func sleep() -> void:
	run.sleep(Content.balance, _tiers(), _bg(), _hunt_content(), rng)
	_commit()


## Mail "Start day": the morning has been seen. Rent at 0 with no grace day ends the run (GDD 5.10).
func start_day() -> void:
	if run.start_day():
		end_run_plan_b()
	else:
		_commit()


## What a board card shows (GDD S04): its 3 tags checked against the CV as set, and the odds of each
## way to apply (RunState.card_odds). {} if the card's data is missing. Changes nothing.
func card_odds(card: Dictionary) -> Dictionary:
	return run.card_odds(Content.balance, _tiers(), _bg(), _hunt_content(), card)


## A Ducky tip a once-per-run trigger just showed (HuntTips, GDD 8.3). Not a player action: it is
## saved with the next commit.
func mark_tip_shown(tip_id: String) -> void:
	if not run.tips_shown.has(tip_id):
		run.tips_shown.append(tip_id)


## The hunt rules' data arguments (RunState, "job hunt" section).
func _tiers() -> Dictionary:
	var out: Dictionary = {}
	for id: String in RunState.TIER_IDS:
		out[id] = Content.tier(id)
	return out


func _hunt_content() -> Dictionary:
	var out: Dictionary = {}
	for file: String in ["postings", "companies", "cv_lines", "emails"]:
		out[file] = Content.entries(file)
	return out


func _bg() -> BackgroundData:
	return Content.background(run.background_id)


# ---------- interview ----------

## Mail "GO NOW": today's slot and the energy are checked, the invite leaves Mail, the energy is paid,
## then the interview is frozen: its seed, its questions (GDD 5.13) and the lie-probe roll (GDD 5.8.5),
## all on the run RNG in that order, so a resume replays it exactly. Nothing changes when refused.
func start_interview(invite: Dictionary) -> void:
	var cfg := Content.balance
	var tier_data := Content.tier(str(invite.get("tier", "")))
	if tier_data == null or not can_take_interview(invite):
		return
	var cost := interview_cost(invite)
	var taken := run.take_invite(int(invite.get("uid", -1)))
	if taken.is_empty():
		return  # expired, withdrawn or already taken
	run.spend_energy(cost)
	run.interviews_today += 1
	var tier_id := str(taken["tier"])
	var interview_seed := str(rng.randi())
	var plan := InterviewPlan.pick(cfg, tier_id, Content.entries("questions_choice"),
		Content.entries("questions_knowledge"), run.seen_question_ids, rng, InterviewPlan.warmup_due(run))
	run.interview = {
		"invite_uid": taken["uid"], "company_id": taken["company_id"],
		"template_id": taken["template_id"], "tier": tier_id,
		"seed": interview_seed, "tired": Odds.is_tired(cfg, run.energy),
		"question_ids": plan["question_ids"],  # prompt order (cfg.prompt_pattern)
		"warmup_id": plan["warmup_id"],        # "" unless the first interview of the first run
		"probe_line": run.roll_probe(cfg, tier_data, _hunt_content(), int(taken["app_uid"]), rng),
	}
	InterviewPlan.mark_seen(run.seen_question_ids, plan["question_ids"] + [plan["warmup_id"]])
	change_phase(GameFlow.Phase.INTERVIEW)  # saves the checkpoint


## GDD 5.3: an interview costs cfg.cost_interview pips, plus the background's travel pips when the
## tier interviews in person (the Self-Taught's +1). -1 for an unknown tier.
func interview_cost(invite: Dictionary) -> int:
	var tier_data := Content.tier(str(invite.get("tier", "")))
	if tier_data == null:
		return -1
	return Content.balance.cost_interview + (_bg().interview_travel_pips if tier_data.in_person else 0)


## GO NOW is possible: today's interview isn't used yet and the pips are there (GDD 5.3). Mail greys
## GO NOW out otherwise.
func can_take_interview(invite: Dictionary) -> bool:
	var cost := interview_cost(invite)
	return cost >= 0 and run.interviews_today < Content.balance.max_interviews_per_day and run.energy >= cost


## won = K.O. or committee win. busted = the lie probe ended in BUSTED (company blacklisted).
## came_clean = you came clean on the probe (Step 4: that line counts as confessed for this company).
## A win builds the whole offer from the checkpoint (RunState.make_offer) before it is cleared.
func finish_interview(won: bool, composure_left: float, busted: bool = false, came_clean: bool = false) -> void:
	var iv := run.interview
	var company_id: String = iv.get("company_id", "")
	run.interviews_taken += 1
	run.times_met_dana += 1
	run.dana_last_company = company_id
	if busted:
		run.blacklist_company(company_id)
	run.settle_probe(company_id, str(iv.get("probe_line", "")), came_clean, busted)
	if won:
		run.make_offer(Content.balance, Content.tier(str(iv["tier"])), _bg(), _hunt_content(), composure_left)
	run.interview = {}
	change_phase(GameFlow.Phase.OFFER if won else GameFlow.Phase.JOB_HUNT)


# ---------- offer and endings ----------

## Decline (after the confirm dialog): the company is blacklisted and the hunt goes on the same day,
## except on the grace day (rent at 0), when declining is Plan B (GDD 5.10, RunState.decline_ends_run).
## Accept: an unconfessed degree-claim Lie sent to this company rolls tier.background_check on the
## run RNG (GDD 5.9.4). Caught: the offer is rescinded (run.rescinded holds mail_rescinded), the
## company blacklisted, back to the hunt the same day. Otherwise the Hired card.
## Accept writes no save: PHASE2_STUB is never saved, so a kill on the Hired card resumes at the
## offer with the RNG state from before the check (GDD 5.11), and accepting again rolls the same dice.
func answer_offer(accept: bool) -> void:
	var company_id: String = run.offer.get("company_id", "")
	if not accept:
		var ends_run := run.decline_ends_run()
		run.blacklist_company(company_id)
		run.offer = {}
		if ends_run:
			end_run_plan_b()
		else:
			change_phase(GameFlow.Phase.JOB_HUNT)
		return
	var tier_data := Content.tier(str(run.offer.get("tier", "")))
	if tier_data != null and run.background_check_caught(tier_data, _hunt_content(), company_id, rng):
		run.rescind_offer()
		change_phase(GameFlow.Phase.JOB_HUNT)
		return
	run.hire(Content.balance, _bg(), Content.entries("companies").get(company_id, {}).get("red_flags", []))
	change_phase(GameFlow.Phase.PHASE2_STUB)


## The Hired card's Dream vs Reality rows (RunState.dream_breakdown). Changes nothing.
func dream_breakdown() -> Array[float]:
	return run.dream_breakdown(Content.balance, _bg())


## Morning with rent at 0, no invite, grace day used (or none waiting); or Decline on the grace day.
func end_run_plan_b() -> void:
	change_phase(GameFlow.Phase.GAME_OVER)


## settings meta run_count (first_run reads it): a run counts once, when it is over for good, which is
## when change_phase() deletes its save (Plan B, or leaving the Hired card). Not on Accept: a kill on
## the Hired card resumes at the offer, and accepting again must not count the run twice.
func _count_finished_run() -> void:
	set_setting("meta", "run_count", int(setting("meta", "run_count", 0)) + 1)

extends Node
## Autoload "GameState" (no class_name: it would clash with the autoload name).
## Owns the RunState, the run's RNG, the phase and the settings file. The career run (M2) lives in `session`, a
## WorkSession: `run` then only holds the phase and the background, and the career_* verbs below drive the session.
## Scenes read `run` / `session` and call verbs. Only change_phase() changes the phase.
## Every verb that commits a player action ends with _commit() (save + HUD refresh).

signal phase_changed(from: GameFlow.Phase, to: GameFlow.Phase)
signal run_changed   # energy, rent, stats, board... changed: refresh the HUD

const SETTINGS_PATH := "user://settings.cfg"

var run: RunState = RunState.new()
var rng := RandomNumberGenerator.new()
var settings := ConfigFile.new()
## The career run on screen (ARCHITECTURE 19.4, 19.7): null in Phase 1's hunt and outside a run.
var session: WorkSession = null
## New game starts the career run. Only the Title's debug button turns this off, for Phase 1's hunt (until M4 retires it).
var career_flow: bool = true
var _intro_starts_career: bool = false   # the intro in front of us is a new game's, not a replay
## Background select focuses this card: the last background played (settings meta "last_background",
## GDD S03), "" before the first run (The Graduate then).
var preselect_background: String = ""


func _ready() -> void:
	settings.load(SETTINGS_PATH)  # a missing file just means defaults
	preselect_background = str(setting("meta", "last_background", ""))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if session != null:
				session.clock.speed = WorkClock.PAUSE   # no time passes while the app is away (D-13, INV-22)
				session.clock.hold()
				run_changed.emit()                      # the speed control shows Pause when you come back
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


## The next new run is a first run: no run has counted yet (settings meta run_count, below).
func next_run_is_first() -> bool:
	return int(setting("meta", "run_count", 0)) == 0


## Debug builds only (the Title's "Reset first run"): the next New game is a first run again, with its
## coach marks, the day-2 guarantee and the warm-up. A saved run keeps its own first_run.
func reset_first_run() -> void:
	set_setting("meta", "run_count", 0)


# ---------- saving ----------

## Writes only while a run is live (JOB_HUNT / INTERVIEW / OFFER, WORK / LAYOFF); a no-op otherwise. The career run saves
## the session ({version: 2, phase, sim, ui}), Phase 1's hunt the RunState.
func save() -> void:
	if not GameFlow.is_saved(run.phase):
		return
	if session != null and _is_career_phase(run.phase):
		SaveIO.write_career(session.to_save(run.phase))
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


## The career run (DECISIONS A78): run 1 is the Intern at the authored job, after the intro the first time; later runs pick
## a background first. Phase 1's hunt is only reachable through start_hunt_game().
func start_new_game() -> void:  # Title: "Tap to start"
	run = RunState.new()
	session = null
	career_flow = true
	_intro_starts_career = false
	if not next_run_is_first():
		change_phase(GameFlow.Phase.BACKGROUND_SELECT)
	elif setting("meta", "intro_seen", false):
		_begin_career(1, "intern", "", new_run_seed())
	else:
		_intro_starts_career = true
		change_phase(GameFlow.Phase.INTRO)


## Debug builds only (the Title's "Old hunt" button): Phase 1's job hunt, as v0.1 shipped it, until M4 retires it.
func start_hunt_game() -> void:
	run = RunState.new()
	session = null
	career_flow = false
	_intro_starts_career = false
	var intro_seen: bool = setting("meta", "intro_seen", false)
	change_phase(GameFlow.Phase.BACKGROUND_SELECT if intro_seen else GameFlow.Phase.INTRO)


func replay_intro() -> void:  # Title: "Replay intro"
	run = RunState.new()
	session = null
	career_flow = true
	_intro_starts_career = false
	change_phase(GameFlow.Phase.INTRO)


func finish_intro() -> void:  # the intro ended, or Skip, or Android Back
	set_setting("meta", "intro_seen", true)
	if career_flow and _intro_starts_career:
		_intro_starts_career = false
		_begin_career(1, "intern", "", new_run_seed())
	else:
		change_phase(GameFlow.Phase.BACKGROUND_SELECT)


## Continue resumes whichever run the slot holds: a career run (version 2) or Phase 1's hunt. Never a dead button.
func continue_game() -> void:
	match SaveIO.kind():
		SaveIO.KIND_CAREER:
			if _resume_career():
				return
		SaveIO.KIND_HUNT:
			if _resume_hunt():
				return
	start_new_game()


func _resume_hunt() -> bool:
	var loaded := SaveIO.read()
	if loaded == null or not GameFlow.can_resume(loaded.phase):
		return false
	var resume_at := loaded.phase
	session = null
	career_flow = false
	run = loaded
	run.phase = GameFlow.Phase.TITLE
	rng.seed = run.rng_seed.to_int()   # seed first: setting seed resets state
	rng.state = run.rng_state.to_int()
	change_phase(resume_at)
	return true


func _resume_career() -> bool:
	var data := SaveIO.peek()
	var resume_at := int(data.get("phase", GameFlow.Phase.WORK)) as GameFlow.Phase
	if not _is_career_phase(resume_at) or not GameFlow.can_resume(resume_at):
		return false
	var bg_id := str((data.get("sim", {}) as Dictionary).get("bg_id", "intern"))
	session = WorkSession.from_save(data, SimContext.load_default(bg_id))   # the clock starts paused (KILL_TESTS 6)
	career_flow = true
	_intro_starts_career = false
	run = RunState.new()
	run.background_id = bg_id
	run.player_name = session.player_name
	change_phase(resume_at)
	return true


## Plan B "Retry" and Hired "New run": a brand-new RunState, same background preselected.
func retry() -> void:
	var from := run.phase
	preselect_background = run.background_id
	session = null
	run = RunState.new()
	run.phase = from  # keeps the transition legal; leaving PHASE2_STUB deletes the save
	change_phase(GameFlow.Phase.BACKGROUND_SELECT)


## Pause "Quit to title", Background select Back, ending "Title". The save survives for Continue.
func quit_to_title() -> void:
	if session != null:
		save()   # a career run resumes where you left it, not at its last eventful day
	change_phase(GameFlow.Phase.TITLE)
	session = null


func choose_background(bg_id: String, player_name: String, run_seed: int = 0) -> void:
	var chosen_seed := run_seed if run_seed != 0 else new_run_seed()
	preselect_background = bg_id
	set_setting("meta", "last_background", bg_id)
	if career_flow:
		_begin_career(int(setting("meta", "run_count", 0)) + 1, bg_id, player_name, chosen_seed)
		return
	_init_run(bg_id, player_name, chosen_seed)
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


## Debug only: set a career run up in place so `project_run mode="custom"` can launch the work or layoff scene alone.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched. to_layoff plays run 1 to the
## layoff scene (answering whatever comes, the simplest way).
func debug_career_quick_start(to_layoff: bool = false, run_seed: int = 20261009) -> void:
	run = RunState.new()
	run.background_id = "intern"
	run.player_name = "Alex"
	career_flow = true
	session = WorkSession.start(SimContext.load_default("intern"), 1, run_seed, [], "Alex", true)
	run.phase = GameFlow.Phase.WORK
	if to_layoff:
		session.play_to_layoff()
		run.phase = GameFlow.Phase.LAYOFF


## Debug only: set a run up in place so `project_run mode="custom"` can launch one feature scene.
## No change_phase() and no signal, so SceneRouter never replaces the scene you launched.
func debug_quick_start(bg_id: String, phase: GameFlow.Phase, run_seed: int = 20260926) -> void:
	run = RunState.new()
	_init_run(bg_id, "Alex", run_seed)
	run.phase = phase


## Debug only (the hub's DEBUG row keeps an interview one tap away): a waiting invite from the tier's
## first MVP company that isn't blacklisted, for the tier's first open posting, as if it arrived this
## morning. No application backs it. No dice. {} when the tier has no company left.
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
	run.first_run = next_run_is_first()
	run.deal_board(cfg, _tiers(), _hunt_content(), rng)


func _gap_pool() -> Array:
	return Content.entries("naming").get("_gap_topic_pool", [])


# ---------- the career run (M2; ARCHITECTURE 19.4, 19.7) ----------
## The WORK scene calls these; the rules are the sim's (WorkSession -> Sim). Every answer is applied without a tick, so
## time moves only in career_tick(), which the scene calls once a day while nothing is open. Each answer saves.

func _is_career_phase(phase: GameFlow.Phase) -> bool:
	return phase == GameFlow.Phase.WORK or phase == GameFlow.Phase.LAYOFF


## A new career run: the sim's first state, the Handbook's collected tips, then the work state (which saves).
func _begin_career(run_number: int, bg_id: String, player_name: String, run_seed: int) -> void:
	var from := run.phase
	var first := next_run_is_first()
	session = WorkSession.start(SimContext.load_default(bg_id), run_number, run_seed, collected_tips(), player_name, first)
	run = RunState.new()
	run.phase = from   # keeps the transition legal, like retry()
	run.background_id = bg_id
	run.player_name = player_name
	change_phase(GameFlow.Phase.WORK)


## The tips the player has collected over all runs (the Handbook, GDD 5.21), as ids.
func collected_tips() -> Array:
	return Array(setting("meta", "handbook", []))


## One day (the clock). Saves when something happened worth keeping: a card, a payday, a shipped ticket.
func career_tick() -> void:
	if session == null:
		return
	var events := session.tick()
	_after_career(events, _career_events_worth_a_save(events))   # refreshes the screen after every day, saves on the notable ones


func career_set_speed(position: int) -> void:
	if session != null:
		session.clock.set_speed(position, session.ctx.cfg)
		run_changed.emit()


func career_set_hours(notch: int) -> void:
	_career_answer(func() -> Array: return session.set_hours(notch))


func career_choose(choice_id: String) -> void:
	_career_answer(func() -> Array: return session.choose(choice_id))


func career_pick_ticket(pick: String) -> void:
	_career_answer(func() -> Array: return session.pick_ticket(pick))


func career_resolve_review() -> void:
	_career_answer(func() -> Array: return session.resolve_review())


func career_fail_interview() -> void:
	_career_answer(func() -> Array: return session.fail_interview())


func career_decline_offer() -> void:
	_career_answer(func() -> Array: return session.decline_offer())


## OK on the layoff scene or the forced leave.
func career_acknowledge() -> void:
	_career_answer(func() -> Array: return session.acknowledge())


## OK on a notice. Not an input to the sim: only the screen's own state changes.
func career_dismiss_notice() -> void:
	if session == null:
		return
	session.dismiss_notice()
	_after_career([], true)


func career_close_coach(coach_id: String) -> void:
	if session != null:
		session.close_coach(coach_id)
		_commit()


func _career_answer(answer: Callable) -> void:
	if session == null:
		return
	_after_career(answer.call(), true)


## After any step or answer: an ending leaves the run, the layoff scene is its own phase, and the save keeps what
## happened (the run log and the screen's state travel with it).
func _after_career(events: Array, save_now: bool) -> void:
	if session.is_over():
		_finish_career()
		return
	if run.phase == GameFlow.Phase.WORK and session.wants_layoff_scene():
		session.clock.set_speed(WorkClock.PAUSE, session.ctx.cfg)   # the scene is a beat of its own: the clock waits after it
		change_phase(GameFlow.Phase.LAYOFF)   # saves
		return
	if run.phase == GameFlow.Phase.LAYOFF and not WorkCards.is_layoff_pending(session.sim):
		change_phase(GameFlow.Phase.WORK)     # saves
		return
	if save_now or session.is_blocked():
		_commit()
	else:
		run_changed.emit()


func _career_events_worth_a_save(events: Array) -> bool:
	for e: Dictionary in events:
		if String(e.get("kind", "")) in ["payday", "rent", "ticket_shipped", "job_ended", "event", "review"]:
			return true
	return false


## The sim ended the run: the tips it showed join the Handbook, then the ending card. Entering GAME_OVER deletes the save
## and counts the run (change_phase).
func _finish_career() -> void:
	var tips: Array = collected_tips()
	for tip: Variant in session.sim.tips_seen:
		if not tips.has(tip):
			tips.append(tip)
	set_setting("meta", "handbook", tips)
	change_phase(GameFlow.Phase.GAME_OVER)


# ---------- job hunt verbs (each committed action ends with _commit()) ----------

## Swipe right or APPLY: Quick Apply with your honest CV (1 pip). False when refused: the card is
## gone, its company is blacklisted, or there isn't enough energy.
func quick_apply(card_uid: int) -> bool:
	return _apply(card_uid, false, false)


## Card back TAILOR & APPLY (2 pips): every CV line goes out Polished for this application; optionally
## spending a referral token.
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


## What a board card shows (GDD S04): its 3 tags checked against your honest CV, and the odds of each
## way to apply (RunState.card_odds). {} if the card's data is missing. Changes nothing.
func card_odds(card: Dictionary) -> Dictionary:
	return run.card_odds(Content.balance, _tiers(), _bg(), _hunt_content(), card)


## A Ducky tip a once-per-run trigger just showed (HuntTips, GDD 8.3). Not a player action: it is
## saved with the next commit.
func mark_tip_shown(tip_id: String) -> void:
	if not run.tips_shown.has(tip_id):
		run.tips_shown.append(tip_id)


## A first-run coach mark tapped closed (GDD 4.3, HuntTips.coach): it never shows again this run. Saved
## at once, because Quit to title writes no save and Continue must not bring it back.
func close_coach_mark(coach_id: String) -> void:
	if coach_id.is_empty() or run.coach_closed.has(coach_id):
		return
	run.coach_closed.append(coach_id)
	_commit()


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
## then the interview is frozen: its seed, then its questions (GDD 5.13), on the run RNG in that
## order, so a resume replays it exactly. Nothing changes when refused.
func start_interview(invite: Dictionary) -> void:
	var cfg := Content.balance
	if not can_take_interview(invite):
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


## won = K.O. or committee win. A win builds the whole offer from the checkpoint (RunState.make_offer)
## before it is cleared.
func finish_interview(won: bool, composure_left: float) -> void:
	var iv := run.interview
	var company_id: String = iv.get("company_id", "")
	run.interviews_taken += 1
	run.times_met_dana += 1
	run.dana_last_company = company_id
	if won:
		run.make_offer(Content.balance, Content.tier(str(iv["tier"])), _bg(), _hunt_content(), composure_left)
	run.interview = {}
	change_phase(GameFlow.Phase.OFFER if won else GameFlow.Phase.JOB_HUNT)


# ---------- offer and endings ----------

## Decline (after the confirm dialog): the company is blacklisted and the hunt goes on the same day,
## except on the grace day (rent at 0), when declining is Plan B (GDD 5.10, RunState.decline_ends_run).
## Accept: the offer becomes the job (run.hire) and the Hired card shows. Accept writes no save:
## PHASE2_STUB is never saved, so a kill on the Hired card resumes at the offer (GDD 5.11), and
## accepting again hires with the same contract. No dice.
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

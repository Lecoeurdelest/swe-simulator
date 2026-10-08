extends Control
## The interview (GDD S07-S09, ARCHITECTURE 11.6): the VS intro, 5 prompts on the real formulas, then a
## K.O., the committee wheel or a rejection with Ducky's card. One coroutine, _run(), drives it all.
## Doubt and Composure live here, not in the save (ARCHITECTURE 8): a resume restarts this interview from
## the checkpoint with the same seed, so the same questions and the same luck replay. The dice are rolled
## in a fixed order whatever you tap (InterviewPlan.meter_rng).
## The tap rule: the AnswerMeter sits below SafeArea and every container and panel in SafeArea ignores the
## mouse, so a tap that misses a real control reaches the meter; [II] keeps its own tap. Taps that reach
## this root finish or advance the dialogue.
## Debug builds print IVSTART / IVTRACE / IVWHEEL / IVFORCE / IVRESULT lines and show the DBG panel
## (forced outcomes) in the stage band.
## The career run feeds this screen through the adapter (DuelAdapter, GDD 5.20): its checkpoint may carry Composure,
## Doubt HP and the Answer Meter's width multiplier, and the screen reads them when they are there, so a Phase 1
## checkpoint plays as it always did. The finish goes to GameState.finish_interview either way.
## The review (GDD 5.16, D-39) is this screen in another mode: the checkpoint's kind says "review", the bars are your
## Evidence and the manager's Calibration, three choice prompts from the review pool each cost Evidence by how well you
## answered, and it ends with the rating (GameState.finish_review) instead of a K.O., a wheel or a rejection.

signal _line_shown
signal _advanced
signal _answer_picked(index: int)
signal _hunt_chosen
signal _parked  # never emitted: a flow replaced by a forced debug outcome waits here for good (_wait)

## Debug quick start (ARCHITECTURE 11.6): project_run mode="custom" on this scene plays this background at
## this tier. User args override them: --iv-bg=intern --iv-tier=big
const DEBUG_BG := "graduate"
const DEBUG_TIER := "mid"
## Debug-only panel labels, English on purpose (not player text, so not in CONTENT.md).
const DEBUG_TOGGLE := "DBG"
const PAUSE_ICON := "II"            # stands in for the pause icon until the art pass
const METER_BAR_TOP := 15.0         # the bar's y in the 40 px meter row: Vague above it, the rest below
const METER_LABEL_GAP := 4.0
const PIVOT_FLASH_S := 0.6
const KO_HOLD_S := 0.5              # GDD S09: "K.O.!" holds 0.5 s, then becomes "OFFER!"
const KO_HAPTIC_MS := 60            # GDD 9.3
const WHEEL_SPIN_S := 2.0           # GDD S09: the wheel spins 2 s
const BANNER_BIG := 32              # Press Start 2P sizes (GDD 2.7): K.O.! and OFFER!
const BANNER_SMALL := 16            # the committee and rejection banners, up to 3 lines
const ZONE_COLOR := Color(0.0, 0.894, 0.212)    # the meter's own colors, so each label matches its zone
const VAGUE_COLOR := Color(1.0, 0.639, 0.0)
const EDGE_COLOR := Color(0.761, 0.765, 0.78)
const REACTIONS: Dictionary = {&"green": "great", &"yellow": "ok", &"red": "bad"}  # bark_dana_<kind>_<1-3>
const REACTION_VARIANTS := 3
const REVIEW_REACTIONS: Dictionary = {"good": "good", "neutral": "ok", "bad": "bad"}   # bark_kev_<good|ok|bad>_<1-3>
const MANAGER_COLOR := Color(0.55, 0.38, 0.24)   # the manager's placeholder portrait until the art pass (P-08, GDD 2.5)

var _cfg: BalanceConfig
var _tier: TierData
var _bg: BackgroundData
var _rng := RandomNumberGenerator.new()   # the interview RNG, seeded from the checkpoint (ARCHITECTURE 7.2)
var _prompts: Array[Dictionary] = []
var _prompt_index := -1             # the prompt being asked; -1 before prompt 1
var _doubt := 0.0
var _doubt_max := 0.0               # Dana's Doubt at the start: the committee band is a share of it
var _composure := 0.0
var _zone_mult := 1.0               # the work state's multiplier on the meter's half-width (Skill, Rust)
var _review := false                # the 3-prompt review duel: your Evidence against the manager's Calibration (D-39)
var _manager := ""                  # the manager's name, for the dialogue box and the portrait's plate
var _hits: Dictionary = {}          # answer kind -> what one round costs your Evidence (the checkpoint's)
var _tired := false
var _textbook_used := false
var _worst_q := INF
var _worst_id := ""
var _worst_red := false
var _last_bad_tip := ""
var _ending := false                # an outcome is playing; nothing can interrupt it
var _flow := 0                      # bumped by a forced debug outcome: the flow it replaces parks
var _typing := false
var _waiting_advance := false
var _type_tween: Tween
var _lock_token := 0
var _meter_lock_token := 0
var _meter_live := false            # the needle is moving and a tap on the meter stops it
var _fit_queued := false
var _meter_result := ""             # after the tap: PERFECT / GOOD / CLOSE / ...uhh over the needle
var _pivot_flash := false
var _meter_text: Dictionary = {}
var _player_color := Color.WHITE
var _hunt_buttons: Array[Button] = []
var _debug_enabled := false

@onready var _stage: Control = %Stage
@onready var _tier_background: ColorRect = %TierBackground
@onready var _meter: AnswerMeter = %AnswerMeter
@onready var _composure_label: Label = %ComposureLabel
@onready var _round_label: Label = %RoundLabel
@onready var _doubt_label: Label = %DoubtLabel
@onready var _composure_bar: HpBar = %ComposureBar
@onready var _doubt_bar: HpBar = %DoubtBar
@onready var _stage_spacer: Control = %StageSpacer
@onready var _dialogue_box: Control = %DialogueBox
@onready var _name_tab: Label = %NameTab
@onready var _line: Label = %Line
@onready var _pause_button: Button = %PauseButton
@onready var _meter_row: Control = %MeterRow
@onready var _answer_column: Control = %AnswerColumn
@onready var _answer_buttons: Array[Button] = [%Answer1, %Answer2, %Answer3]
@onready var _tap_pad: Control = %TapPad
@onready var _hint_label: Label = %HintLabel
@onready var _tired_label: Label = %TiredLabel
@onready var _ducky_card: Control = %DuckyCard
@onready var _card_note: DuckyNote = %CardNote
@onready var _back_to_hunt_button: Button = %BackToHuntButton
@onready var _versus: VersusIntro = %VersusIntro
@onready var _result_layer: Control = %ResultLayer
@onready var _coach_note: DuckyNote = %CoachNote
@onready var _ko_banner: Control = %KOBanner
@onready var _banner_label: Label = %BannerLabel
@onready var _wheel: CommitteeWheel = %CommitteeWheel
@onready var _debug_layer: Control = %DebugLayer
@onready var _debug_toggle: Button = %DebugToggle
@onready var _debug_grid: Control = %DebugGrid
@onready var _ready_overlay: Control = %ReadyOverlay
@onready var _ready_label: Label = %ReadyLabel
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	_debug_enabled = OS.is_debug_build()
	if _debug_enabled and GameState.run.background_id == "":
		_debug_quick_start()
	_cfg = Content.balance
	var run: RunState = GameState.run
	_review = str(run.interview.get("kind", "")) == DuelAdapter.KIND_REVIEW
	_tier = Content.tier(str(run.interview.get("tier", "")))
	_bg = Content.background(run.background_id)
	_hunt_buttons.assign([_back_to_hunt_button])
	_set_static_text()
	_connect_signals()
	_setup_debug_panel()
	_hide_transient()
	if _tier == null or _bg == null or run.interview.is_empty():
		push_error("Interview: the run has no interview checkpoint")
		return
	_tier_background.color = VersusIntro.tier_color(str(_tier.id))
	var bg_entry: Dictionary = Content.entries("backgrounds").get(run.background_id, {})
	_player_color = VersusIntro.hoodie_color(str(bg_entry.get("hoodie", ""))).lightened(0.4)
	_queue_fit()
	_run.call_deferred()


## GameState pauses the tree when the app loses focus mid-interview (ARCHITECTURE 9), and
## "Ready? Tap to continue" unpauses it. Our own Pause sheet also pauses the tree, but shows itself.
## The needle, the typewriter and every timer here stop while the tree is paused.
func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_PAUSED:
			_ready_overlay.visible = not _pause.is_open()
		NOTIFICATION_UNPAUSED:
			_ready_overlay.hide()
			_rearm_locks()


## ARCHITECTURE 9: Pause open = Resume; the Ready overlay = Pause; Ducky's card = Back to the hunt;
## the VS intro = a tap on it (VersusIntro.tap); anything else = Pause. Once an ending beat starts (K.O., the
## wheel, a rejection) Pause is out of reach: [II] hides, the Ready overlay's Back only resumes and
## other Backs do nothing, so Quit to title can't replay an interview whose ending you have seen.
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	if _ready_overlay.visible:
		if _ending:
			_resume_from_ready()
		else:
			_open_pause()
		return true
	if _hunt_offered():
		_on_back_to_hunt()
		return true
	if _ending:
		return true  # the beat plays out: taps advance it
	if _versus.tap():
		return true
	_open_pause()
	return true


## A tap that no control took: the first one finishes the typewriter, the next one advances (10.4).
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	accept_event()
	if _typing:
		_finish_typing()
	elif _waiting_advance:
		_waiting_advance = false
		_advanced.emit()


# ---------- the flow (ARCHITECTURE 11.6 steps 1-8) ----------

func _run() -> void:
	var iv: Dictionary = GameState.run.interview
	if _review:
		await _run_review(iv)
		return
	_rng = InterviewPlan.interview_rng(str(iv.get("seed", "0")))
	_tired = bool(iv.get("tired", false))
	var start := DuelAdapter.start_values(iv, _tier, _bg)
	_doubt = float(start["doubt"])
	_doubt_max = _doubt
	_composure = float(start["composure"])
	_zone_mult = float(start["zone_mult"])
	_doubt_bar.max_value = _doubt
	_composure_bar.max_value = _composure
	_update_bars()
	_prompts = InterviewPlan.prompts(iv.get("question_ids", []), Content.entries("questions_choice"))
	var warmup_id := str(iv.get("warmup_id", ""))
	_round_label.text = Content.text("barks", "ui_round", {"n": 1, "total": _prompts.size()})
	_trace_start(iv)
	_versus.play(str(iv.get("company_id", "")), str(iv.get("tier", "")))
	await _wait(_versus.finished)
	_show_debug_panel()
	await _greet(iv)
	for i: int in _prompts.size():
		_prompt_index = i
		if i == 1 and warmup_id != "":  # GDD 5.8.2: the warm-up comes before prompt 2
			await _ask_warmup(warmup_id)
		var n := i + 1
		_round_label.text = Content.text("barks", "ui_round", {"n": n, "total": _prompts.size()})
		var prompt: Dictionary = _prompts[i]
		match str(prompt["kind"]):
			"choice":
				await _ask_choice(n, str(prompt["id"]))
			"knowledge":
				await _ask_knowledge(n, str(prompt["id"]), false)
		if _doubt <= 0.0:
			await _ko()
			return
		if _composure <= 0.0:
			await _reject("composure_zero", "bark_dana_composure_zero")
			return
	_prompt_index = _prompts.size()
	if Odds.committee_eligible(_cfg, _doubt, _doubt_max):
		await _committee()
	else:
		await _reject("rejected", "bark_dana_other_candidates")


## Every wait for the player goes through here. A forced debug outcome bumps _flow; the flow it replaced
## wakes up stale on its next signal and parks on _parked, so two flows never drive the screen at once.
func _wait(sig: Signal) -> Variant:
	var flow := _flow
	var value: Variant = await sig
	if flow != _flow:
		await _parked
	return value


## The review (GDD 5.16, D-39): the manager opens, three choice prompts follow, and the rating ends it. The bars are the
## interview's: COMPOSURE is your Evidence, DOUBT the manager's Calibration, which moves with your answers like Doubt does
## but cannot be emptied in three prompts, so it decides nothing (A94). What decides the rating is the Evidence left.
func _run_review(iv: Dictionary) -> void:
	_rng = InterviewPlan.interview_rng(str(iv.get("seed", "0")))
	_manager = str(iv.get("manager", ""))
	_hits = (iv.get("hits", {}) as Dictionary).duplicate()
	_composure = float(iv["evidence"])
	_doubt = float(iv["calibration"])
	_doubt_max = _doubt
	_composure_bar.max_value = _composure
	_doubt_bar.max_value = _doubt
	_update_bars()
	_prompts = InterviewPlan.prompts(iv.get("question_ids", []), Content.entries("questions_review"))
	_show_manager()
	_round_label.text = Content.text("barks", "ui_round", {"n": 1, "total": _prompts.size()})
	await _say_manager(Content.text("barks", "bark_kev_open"))
	for i: int in _prompts.size():
		_round_label.text = Content.text("barks", "ui_round", {"n": i + 1, "total": _prompts.size()})
		await _ask_review_prompt(i + 1, str(_prompts[i]["id"]))
	await _review_end()


## The manager's portrait is a labelled placeholder on the same grid as Dana's bust (GDD 2.5): a colour block with the name.
func _show_manager() -> void:
	var bust := %DanaBust as ColorRect
	bust.color = MANAGER_COLOR
	var plate := Label.new()
	plate.text = _manager.to_upper()
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)   # the desk covers the bust's foot
	bust.add_child(plate)


## One prompt: the manager asks, you pick one of three shuffled answers, the manager's chip lands on your Evidence by
## how well you answered (good 0.4 of it, okay all of it, a joke 1.8), and he reacts.
func _ask_review_prompt(n: int, id: String) -> void:
	var question: Dictionary = Content.entry("questions_review", id)
	var answers := Odds.shuffled(_rng, question.get("answers", []))
	_manager_speaks()
	await _type(Content.field("questions_review", id, "prompt"))
	var index := await _pick(answers)
	var kind := str((answers[index] as Dictionary).get("kind", "neutral"))
	_composure -= float(_hits.get(kind, 0.0))
	_doubt = clampf(_doubt + Odds.ethics_doubt_delta(_cfg, StringName(kind), false, 1.0), 0.0, _doubt_max)
	_update_bars()
	_manager_speaks()
	await _say(Content.text("barks", "bark_kev_%s_%d" % [REVIEW_REACTIONS.get(kind, "ok"), posmod(n - 1, REACTION_VARIANTS) + 1]))


## The rating banner over the stage, the manager's closing line, then the sim gets the Evidence you have left.
func _review_end() -> void:
	_begin_ending()
	var left := maxf(_composure, 0.0)
	var rating := WorkOdds.rating(GameState.session.ctx.cfg, float(GameState.run.interview["evidence"]), left)
	var rating_id: String = WorkOdds.RATINGS[rating]
	_show_banner(Content.text("barks", "vs_review_" + rating_id), BANNER_BIG)
	await _say_manager(Content.text("barks", "bark_kev_close_" + rating_id))
	GameState.finish_review(left)


func _manager_speaks() -> void:
	_name_tab.text = _manager.to_upper()
	_name_tab.remove_theme_color_override(&"font_color")


func _say_manager(text: String) -> void:
	_manager_speaks()
	await _say(text)


## CONTENT 8.1: the greeting (or "greet again" from the second interview of a run), then the
## background opener on the first interview of a run, then the Tired line if you arrived Tired.
func _greet(iv: Dictionary) -> void:
	var run: RunState = GameState.run
	if str(iv.get("greet", "")) == DuelAdapter.GREET_AFTER_LAYOFF:  # the career run: Dana laid you off, then met you again
		var laid_off_at := Content.field("companies", str(iv.get("last_company", "")), "name")
		await _say_dana(Content.text("barks", "bark_dana_greet_after_layoff", {"last_company": laid_off_at}))
	elif run.interviews_taken > 0 and run.dana_last_company != "":
		var last_company := Content.field("companies", run.dana_last_company, "name")
		await _say_dana(Content.text("barks", "bark_dana_greet_again", {"last_company": last_company}))
	else:
		var company := Content.field("companies", str(iv.get("company_id", "")), "name")
		await _say_dana(Content.text("barks", "bark_dana_greet_" + str(_tier.id), {"company": company}))
	if run.interviews_taken == 0:
		await _say_dana(Content.field("backgrounds", run.background_id, "dana_opener"))
	if _tired:
		await _say_dana(Content.text("barks", "bark_dana_tired"))


## GDD 5.8.3: three shuffled answers; your background's exclusive answer replaces the neutral one.
func _ask_choice(n: int, id: String) -> void:
	var question: Dictionary = Content.entry("questions_choice", id)
	var answers := Odds.shuffled(_rng, _choice_answers(question))
	var order := PackedStringArray()
	for answer: Dictionary in answers:
		order.append(str(answer.get("kind", "")))
	_dana_speaks()
	await _type(Content.field("questions_choice", id, "prompt"))
	var index := await _pick(answers)
	var picked: Dictionary = answers[index]
	var kind := StringName(str(picked.get("kind", "")))
	var teamwork := bool(question.get("teamwork", false))
	_doubt += Odds.ethics_doubt_delta(_cfg, kind, teamwork, Odds.teamwork_mult(_bg, GameState.run.lone_wolf))
	_composure -= Odds.ethics_composure_loss(_cfg, kind)
	_update_bars()
	if kind == &"bad":
		_last_bad_tip = str(question.get("tip", ""))
	_trace(n, id, "choice", {"order": ",".join(order), "answer": kind})
	_dana_speaks()
	await _say(tr(str(picked.get("reaction", ""))))


func _choice_answers(question: Dictionary) -> Array:
	var exclusive: Dictionary = question.get("exclusive", {})
	var mine := str(exclusive.get("background", "")) == GameState.run.background_id
	var answers: Array = []
	for answer: Dictionary in question.get("answers", []):
		answers.append(exclusive if mine and str(answer.get("kind", "")) == "neutral" else answer)
	return answers


## GDD 5.8.4 on the Answer Meter: S and h from the stats, the needle speed from the tier (and Tired),
## Q = 0.75 S + 25 I. warmup = the first run's practice question: it changes nothing.
func _ask_knowledge(n: int, id: String, warmup: bool) -> void:
	var run: RunState = GameState.run
	var question: Dictionary = Content.entry("questions_knowledge", id)
	var is_tech := str(question.get("kind", "tech")) == "tech"
	var weak := str(question.get("weak_for", "none")) == run.background_id \
		or run.gap_topics.has(str(question.get("topic", "")))
	var p := Odds.knowledge_p(_cfg, _tier, _bg, run.stat("knw"), run.stat("exp"), is_tech, weak)
	var s := Odds.stat_score(_cfg, _tier, p, int(question.get("difficulty", 2)), Odds.roll_luck(_cfg, _rng))
	var bonus := 0.0
	if not warmup and not _textbook_used:  # GDD 5.8.4: the Graduate's first knowledge question
		bonus = _bg.textbook_zone_bonus
		_textbook_used = true
	var h := DuelAdapter.half_width(_cfg, s, bonus, _zone_mult)
	_tired_label.visible = _tired
	_show_thumb(_tap_pad)
	_meter_result = ""
	_meter.show()
	_meter.start(_cfg, Odds.needle_speed(_cfg, _tier, _tired), h, _tier.zone_jumps, _relaxed(), InterviewPlan.meter_rng(_rng))
	var zone_c := _meter.zone().x
	# Visible luck (GDD 5.8.4): the zone shows while Dana asks, and the needle waits for her question.
	# Meanwhile taps pass through the meter to finish her line.
	_meter.set_process(false)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter_row.queue_redraw()
	_dana_speaks()
	await _type(Content.field("questions_knowledge", id, "prompt"))
	_meter_live = true
	_meter.mouse_filter = Control.MOUSE_FILTER_STOP
	_meter.set_process(true)
	var input: float = await _wait(_meter.resolved)
	_meter_live = false
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE  # stays on screen, frozen where you stopped it
	_coach_note.hide()
	_tap_pad.hide()
	var answer_q := Odds.answer_q(_cfg, s, input)
	var grade := Odds.spoken_grade(_cfg, answer_q)
	if not warmup:
		_doubt += Odds.knowledge_doubt_delta(_cfg, answer_q)
		_composure -= Odds.knowledge_composure_loss(_cfg, answer_q)
		_update_bars()
		if answer_q < _worst_q:
			_worst_q = answer_q
			_worst_id = id
			_worst_red = grade == &"red"
	_trace(n, id, "warmup" if warmup else "knowledge", {"S": "%.2f" % s, "h": "%.4f" % h, "c": "%.4f" % zone_c,
		"I": "%.2f" % input, "Q": "%.2f" % answer_q, "answer": grade})
	_meter_result = _input_label(input)
	_meter_row.queue_redraw()
	if grade == &"red":  # GDD S08: Ducky's real answer as a full-width note in the thumb band
		_show_note(_real_answer(Content.field("questions_knowledge", id, "ducky")))
	_player_speaks()
	await _say(Content.field("questions_knowledge", id, str(grade)))
	_dana_speaks()
	await _say(Content.text("barks", "bark_dana_%s_%d" % [REACTIONS[grade], posmod(n - 1, REACTION_VARIANTS) + 1]))
	_meter.hide()
	_ducky_card.hide()
	_meter_result = ""
	_meter_row.queue_redraw()  # clears the zone and grade labels with the bar


## GDD 4.3 and 5.8.2: the first run's practice question, labelled, with Ducky's coach line.
func _ask_warmup(id: String) -> void:
	_round_label.text = Content.text("barks", "vs_warmup")
	_coach_note.tip_text = Content.text("barks", "coach_meter")
	_coach_note.show()
	await _ask_knowledge(0, id, true)


func _ko() -> void:
	_begin_ending()
	_doubt = 0.0
	_update_bars()
	_log_result("ko")
	Device.haptic(KO_HAPTIC_MS)
	_show_banner(Content.text("barks", "vs_ko"), BANNER_BIG)
	await get_tree().create_timer(KO_HOLD_S, false).timeout
	_show_banner(Content.text("barks", "vs_offer"), BANNER_BIG)
	await _say_dana(Content.text("barks", "bark_dana_ko"))
	_finish(true)


## GDD 5.8.6: the win wedge is drawn at the real odds; the outcome is rolled on the interview RNG first.
## forced_result ("win" / "loss") comes only from the debug panel and replaces the roll.
func _committee(forced_result: String = "") -> void:
	_begin_ending()
	var win_p := Odds.committee_win_p(_cfg, _doubt, _doubt_max, GameState.run.stat("net"))
	var won := Odds.roll(_rng, win_p) if forced_result == "" else forced_result == "win"
	if _debug_enabled:
		print("IVWHEEL|p=%.4f|won=%s|forced=%s" % [win_p, won, forced_result != ""])
	_show_banner(Content.text("barks", "vs_committee"), BANNER_SMALL)
	await _say_dana(Content.text("barks", "bark_dana_committee"))
	_ko_banner.hide()
	_wheel.show_odds(win_p)
	await _wheel.spin(won, WHEEL_SPIN_S)
	if won:
		_log_result("wheel_win")
		await _say_dana(Content.text("barks", "bark_dana_committee_win"))
		_finish(true)
		return
	_log_result("wheel_loss")
	await _say_dana(Content.text("barks", "bark_dana_committee_lose"))
	await _rejection_card("tip_research_company")  # GDD 8.3: committee loss


func _reject(outcome: String, dana_line_id: String) -> void:
	_begin_ending()
	_log_result(outcome)
	_show_banner(Content.text("barks", "vs_reject"), BANNER_SMALL)
	await _say_dana(Content.text("barks", dana_line_id))
	await _rejection_card(_rejection_tip())


## GDD S09: the thumb band becomes Ducky's card: one tip, the model answer of your worst knowledge
## question and a full-width [ Back to the hunt ], which is this screen's Back ([II] hides).
## Rejections use up the day's interview.
func _rejection_card(tip_id: String) -> void:
	var text := Content.field("tips", tip_id, "short")
	if _worst_id != "":
		text += "\n" + _real_answer(Content.field("questions_knowledge", _worst_id, "green"))
	_card_note.tip_text = text
	_meter.hide()
	_meter_row.hide()
	_pause_button.hide()
	_back_to_hunt_button.show()
	_back_to_hunt_button.disabled = false
	_show_thumb(_ducky_card)
	_lock(_hunt_buttons)
	_dana_speaks()
	_type(Content.text("barks", "bark_dana_reject"))
	await _wait(_hunt_chosen)
	_finish(false)


## One tip that matches the cause (GDD 8.1 rule 4, 8.3). Agent default, please review: a red knowledge
## answer first (the tip of the question whose model answer the card shows), then the last bad choice
## answer's own tip, then Tired, then research (without Research, every MVP rejection is "without research").
func _rejection_tip() -> String:
	if _worst_red:
		return str((Content.entry("questions_knowledge", _worst_id) as Dictionary).get("tip", "tip_think_aloud"))
	if _last_bad_tip != "":
		return _last_bad_tip
	if _tired:
		return "tip_rest"
	return "tip_research_company"


func _begin_ending() -> void:
	_ending = true
	_pause_button.hide()  # see handle_back(): no Pause once the outcome is showing
	if _debug_enabled:
		_debug_layer.hide()


func _finish(won: bool) -> void:
	GameState.finish_interview(won, maxf(_composure, 0.0))


# ---------- dialogue box (ARCHITECTURE 10.4) ----------

func _dana_speaks() -> void:
	_name_tab.text = Content.text("naming", "interviewer").to_upper()
	_name_tab.remove_theme_color_override(&"font_color")


func _player_speaks() -> void:
	_name_tab.text = GameState.run.player_name.to_upper()
	_name_tab.add_theme_color_override(&"font_color", _player_color)


func _say_dana(text: String) -> void:
	_dana_speaks()
	await _say(text)


## Types the line out, then waits for the tap that advances.
func _say(text: String) -> void:
	await _type(text)
	_waiting_advance = true
	await _wait(_advanced)


## Types the line out at typewriter_cps; a tap finishes it at once.
func _type(text: String) -> void:
	_waiting_advance = false
	if _type_tween != null:
		_type_tween.kill()
	_line.text = text
	_line.visible_ratio = 0.0
	if _cfg.typewriter_cps <= 0.0 or text.is_empty():
		_typing = false
		_line.visible_ratio = 1.0
		return
	_typing = true
	_type_tween = create_tween()
	_type_tween.tween_property(_line, ^"visible_ratio", 1.0, text.length() / _cfg.typewriter_cps)
	_type_tween.finished.connect(_finish_typing)
	await _wait(_line_shown)


func _finish_typing() -> void:
	if not _typing:
		return
	_typing = false
	if _type_tween != null:
		_type_tween.kill()
	_line.visible_ratio = 1.0
	_line_shown.emit()


# ---------- answers and locks ----------

func _pick(answers: Array) -> int:
	for i: int in _answer_buttons.size():
		var button := _answer_buttons[i]
		button.visible = i < answers.size()
		if button.visible:
			button.text = tr(str((answers[i] as Dictionary).get("text", "")))
	_show_thumb(_answer_column)
	_lock(_answer_buttons)
	var index: int = await _wait(_answer_picked)
	return index


func _on_answer_pressed(index: int) -> void:
	if not _answer_column.visible:
		return  # one answer per prompt: a double tap can't answer twice
	_answer_column.hide()
	_answer_picked.emit(index)


func _hunt_offered() -> bool:
	return _ducky_card.visible and _back_to_hunt_button.visible and not _back_to_hunt_button.disabled


func _on_back_to_hunt() -> void:
	if not _hunt_offered():
		return
	_back_to_hunt_button.disabled = true  # a second finish_interview() would be an illegal phase change
	_hunt_chosen.emit()


## GDD 2.8 rule 7: buttons ignore taps for input_lock_ms after they appear, so the tap that finished
## the typewriter can't also press one. A newer lock supersedes an older one.
func _lock(buttons: Array[Button]) -> void:
	_lock_token += 1
	var token := _lock_token
	for button: Button in buttons:
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(_cfg.input_lock_ms / 1000.0, false).timeout
	if token == _lock_token:
		for button: Button in buttons:
			button.mouse_filter = Control.MOUSE_FILTER_STOP


## The meter's own 250 ms lock runs from its start(); after a pause the scene adds one more, so the tap
## that closed "Ready?" or Pause can't also stop the needle.
func _lock_meter() -> void:
	_meter_lock_token += 1
	var token := _meter_lock_token
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(_cfg.input_lock_ms / 1000.0, false).timeout
	if token == _meter_lock_token and _meter_live:
		_meter.mouse_filter = Control.MOUSE_FILTER_STOP


## ARCHITECTURE 9: the tap on "Ready?" (or Resume) re-arms the lock.
func _rearm_locks() -> void:
	if _answer_column.visible:
		_lock(_answer_buttons)
	elif _hunt_offered():
		_lock(_hunt_buttons)
	if _meter_live:
		_lock_meter()


func _on_ready_overlay_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_resume_from_ready()


func _resume_from_ready() -> void:
	_ready_overlay.hide()
	get_tree().paused = false


func _open_pause() -> void:
	_ready_overlay.hide()
	_pause.open()


# ---------- the Answer Meter's row ----------

## The zone labels (GDD 2.7: zones carry text, never color alone): Vague above the bar at each side of
## the zone, then Rambling, NAILED IT (PIVOT! when it jumps) and Overthinking below it. After the tap,
## only the input grade over the needle.
func _draw_meter_labels() -> void:
	if not _meter.visible:
		return
	var font := _meter_row.get_theme_default_font()
	var font_size := _meter_row.get_theme_default_font_size()
	var width := float(_cfg.answer_meter_width_px)
	var left := floorf(_meter.get_global_rect().position.x + (_meter.size.x - width) * 0.5) \
		- _meter_row.get_global_rect().position.x
	var ascent := font.get_ascent(font_size)
	var below := METER_BAR_TOP + AnswerMeter.BAR_HEIGHT + 3.0 + ascent
	if _meter_result != "":
		_draw_meter_label(font, font_size, _meter_result, left + _meter.needle() * width, below, Color.WHITE, left, width)
		return
	var zone := _meter.zone()
	for side: float in [-1.5, 1.5]:
		var at := zone.x + side * zone.y
		if at >= 0.0 and at <= 1.0:
			_draw_meter_label(font, font_size, _meter_text["near"], left + at * width, ascent, VAGUE_COLOR, left, width)
	var zone_text: String = _meter_text["pivot"] if _pivot_flash else _meter_text["zone"]
	var nailed := _draw_meter_label(font, font_size, zone_text, left + zone.x * width, below,
		VAGUE_COLOR if _pivot_flash else ZONE_COLOR, left, width)
	var rambling_width := font.get_string_size(_meter_text["left"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if left + rambling_width + METER_LABEL_GAP <= nailed.x:
		_meter_row.draw_string(font, Vector2(left, below), _meter_text["left"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, EDGE_COLOR)
	var over_width := font.get_string_size(_meter_text["right"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if left + width - over_width - METER_LABEL_GAP >= nailed.y:
		_meter_row.draw_string(font, Vector2(floorf(left + width - over_width), below), _meter_text["right"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, EDGE_COLOR)


## Draws text centred on x, kept inside the bar. Returns its left and right edges.
func _draw_meter_label(font: Font, font_size: int, text: String, x: float, baseline: float, color: Color,
		bar_left: float, bar_width: float) -> Vector2:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var from := floorf(clampf(x - text_width * 0.5, bar_left, bar_left + bar_width - text_width))
	_meter_row.draw_string(font, Vector2(from, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	return Vector2(from, from + text_width)


func _on_zone_jumped() -> void:
	_pivot_flash = true
	_meter_row.queue_redraw()
	_dana_speaks()
	_set_line(Content.text("barks", "bark_dana_pivot"))
	await get_tree().create_timer(PIVOT_FLASH_S, false).timeout
	_pivot_flash = false
	_meter_row.queue_redraw()


func _input_label(input: float) -> String:
	if input >= _cfg.input_perfect:
		return Content.text("barks", "meter_perfect")
	if input >= _cfg.input_good:
		return Content.text("barks", "meter_good")
	if input >= _cfg.input_close:
		return Content.text("barks", "meter_close")
	return Content.text("barks", "meter_miss")


func _relaxed() -> bool:
	return bool(GameState.setting("options", "relaxed_timing", false))


# ---------- layout ----------

func _queue_fit() -> void:
	if _fit_queued:
		return
	_fit_queued = true
	_fit_layout.call_deferred()


## ARCHITECTURE 11.6: the stage's bottom edge (the desk line) follows the dialogue box's top, so extra
## height shows more wall and sky, never more floor. The result layer covers the stage band, and the
## meter draws its bar in the meter row, above the tap pad.
func _fit_layout() -> void:
	_fit_queued = false
	var origin := get_global_rect().position
	var desk_y := _dialogue_box.get_global_rect().position.y - origin.y
	_stage.offset_bottom = desk_y
	_result_layer.offset_top = _stage_spacer.get_global_rect().position.y - origin.y
	_result_layer.offset_bottom = desk_y
	_meter.set_bar_y(_meter_row.get_global_rect().position.y - _meter.get_global_rect().position.y + METER_BAR_TOP)
	_meter_row.queue_redraw()


# ---------- small helpers ----------

func _set_static_text() -> void:
	_composure_label.text = Content.text("barks", "ui_evidence" if _review else "ui_composure")
	_doubt_label.text = Content.text("barks", "ui_calibration" if _review else "ui_doubt")
	_hint_label.text = Content.text("barks", "meter_hint")
	_tired_label.text = Content.text("barks", "ui_tired")
	_back_to_hunt_button.text = Content.text("barks", "ui_back_to_work" if GameState.career_flow else "ui_back_to_hunt")
	_ready_label.text = Content.text("barks", "ui_ready")
	_pause_button.text = PAUSE_ICON
	_meter_text = {
		"left": Content.text("barks", "meter_left"), "near": Content.text("barks", "meter_near"),
		"zone": Content.text("barks", "meter_zone"), "right": Content.text("barks", "meter_right"),
		"pivot": Content.text("barks", "vs_pivot"),
	}


func _connect_signals() -> void:
	_pause_button.pressed.connect(Device.handle_back)
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)
	_ready_overlay.gui_input.connect(_on_ready_overlay_input)
	for i: int in _answer_buttons.size():
		_answer_buttons[i].pressed.connect(_on_answer_pressed.bind(i))
	_back_to_hunt_button.pressed.connect(_on_back_to_hunt)
	_meter.zone_jumped.connect(_on_zone_jumped)
	_meter_row.draw.connect(_draw_meter_labels)
	resized.connect(_queue_fit)
	Device.layout_changed.connect(_queue_fit)
	_dialogue_box.item_rect_changed.connect(_queue_fit)
	_stage_spacer.item_rect_changed.connect(_queue_fit)
	_meter_row.item_rect_changed.connect(_queue_fit)


func _hide_transient() -> void:
	_meter.hide()
	for node: CanvasItem in [_answer_column, _tap_pad, _ducky_card, _coach_note, _ko_banner, _wheel, _ready_overlay]:
		node.hide()
	_line.text = ""
	_name_tab.text = ""


## The thumb band shows one thing at a time (ARCHITECTURE 11.6 ThumbSlot); null shows none.
func _show_thumb(node: Control) -> void:
	for slot: CanvasItem in [_answer_column, _tap_pad, _ducky_card]:
		slot.visible = slot == node


## A full-width Ducky note in the thumb band, without the card's button: the red answer's
## "Real answer: ...".
func _show_note(text: String) -> void:
	_card_note.tip_text = text
	_back_to_hunt_button.hide()
	_show_thumb(_ducky_card)


func _set_line(text: String) -> void:
	_typing = false
	_waiting_advance = false
	if _type_tween != null:
		_type_tween.kill()
	_line.text = text
	_line.visible_ratio = 1.0


func _show_banner(text: String, font_size: int) -> void:
	_banner_label.text = text
	_banner_label.add_theme_font_size_override(&"font_size", font_size)
	_ko_banner.show()


func _update_bars() -> void:
	_doubt_bar.value = maxf(_doubt, 0.0)
	_composure_bar.value = maxf(_composure, 0.0)


func _real_answer(text: String) -> String:
	return "%s %s" % [Content.text("barks", "ducky_real_answer"), text]


# ---------- debug ----------

func _trace_start(iv: Dictionary) -> void:
	if not _debug_enabled:
		return
	var ids := PackedStringArray()
	for prompt: Dictionary in _prompts:
		ids.append(str(prompt["id"]))
	print("IVSTART|tier=%s|bg=%s|company=%s|seed=%s|doubt=%.2f|comp=%.2f|tired=%s|warmup=%s|ids=%s|taken=%d" % [
		_tier.id, GameState.run.background_id, iv.get("company_id", ""), iv.get("seed", ""), _doubt, _composure,
		_tired, iv.get("warmup_id", ""), ",".join(ids), GameState.run.interviews_taken])


## prompt=0 is the warm-up. Choice lines carry the shuffled answer order; knowledge lines S, h, the
## zone centre c (before any pivot), I and Q.
func _trace(n: int, id: String, kind: String, fields: Dictionary) -> void:
	if not _debug_enabled:
		return
	var parts := PackedStringArray()
	for key: String in fields:
		parts.append("%s=%s" % [key, fields[key]])
	print("IVTRACE|prompt=%d|id=%s|kind=%s|%s|doubt=%.2f|comp=%.2f" % [n, id, kind, "|".join(parts), _doubt, _composure])


func _log_result(outcome: String) -> void:
	if _debug_enabled:
		print("IVRESULT|outcome=%s|doubt=%.2f|comp=%.2f|tier=%s|bg=%s" % [
			outcome, _doubt, _composure, _tier.id, GameState.run.background_id])


## The DBG panel (debug builds only): a 34x34 toggle in the stage band's top-left, never in the thumb
## band. It forces each outcome through the real ending code.
func _setup_debug_panel() -> void:
	if not _debug_enabled:
		_debug_layer.queue_free()
		return
	_debug_layer.hide()
	_debug_grid.hide()
	_debug_toggle.text = DEBUG_TOGGLE
	_debug_toggle.pressed.connect(func() -> void: _debug_grid.visible = not _debug_grid.visible)
	(%ForceKO as Button).pressed.connect(_on_debug_force.bind("ko"))
	(%ForceWheelWin as Button).pressed.connect(_on_debug_force.bind("wheel_win"))
	(%ForceWheelLoss as Button).pressed.connect(_on_debug_force.bind("wheel_loss"))
	(%ForceComposureZero as Button).pressed.connect(_on_debug_force.bind("composure_zero"))


func _show_debug_panel() -> void:
	if _debug_enabled and not _ending and not _review:
		_debug_layer.show()


## Debug only: ends the interview now through the real ending code (banners, wheel, Ducky's card and
## GameState.finish_interview), from whatever prompt is on screen. Wheel win/loss first bring Doubt into
## the committee band.
func _on_debug_force(outcome: String) -> void:
	if _ending:
		return
	_flow += 1
	_begin_ending()
	_clear_prompt()
	print("IVFORCE|outcome=%s|prompt=%d|doubt=%.2f|comp=%.2f" % [outcome, _prompt_index + 1, _doubt, _composure])
	match outcome:
		"ko":
			await _ko()
		"wheel_win", "wheel_loss":
			_doubt = minf(_doubt, _cfg.committee_band * _doubt_max)
			_update_bars()
			await _committee("win" if outcome == "wheel_win" else "loss")
		"composure_zero":
			_composure = 0.0
			_update_bars()
			await _reject("composure_zero", "bark_dana_composure_zero")


func _clear_prompt() -> void:
	_meter_live = false
	_meter.set_process(false)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter.hide()
	_meter_result = ""
	_meter_row.queue_redraw()
	_show_thumb(null)
	_coach_note.hide()
	_ko_banner.hide()
	_set_line("")


## Debug only (ARCHITECTURE 11.6): launched alone with project_run mode="custom", there is no run yet, so
## set one up in place and freeze a checkpoint the way GameState.start_interview does (seed first, then
## the real InterviewPlan picks on the run RNG). The phase is never changed, so SceneRouter keeps this scene.
func _debug_quick_start() -> void:
	var args := _debug_args()
	var bg_id: String = args.get("iv-bg", DEBUG_BG)
	var tier_id: String = args.get("iv-tier", DEBUG_TIER)
	if Content.background(bg_id) == null:
		bg_id = DEBUG_BG
	if Content.tier(tier_id) == null:
		tier_id = DEBUG_TIER
	GameState.debug_quick_start(bg_id, GameFlow.Phase.INTERVIEW)
	var run: RunState = GameState.run
	var cfg: BalanceConfig = Content.balance
	var cost := cfg.cost_interview + (Content.background(bg_id).interview_travel_pips if Content.tier(tier_id).in_person else 0)
	run.spend_energy(cost)
	run.interviews_today += 1
	var interview_seed := str(GameState.rng.randi())
	var plan := InterviewPlan.pick(cfg, tier_id, Content.entries("questions_choice"),
		Content.entries("questions_knowledge"), run.seen_question_ids, GameState.rng, InterviewPlan.warmup_due(run))
	run.interview = {
		"invite_uid": 0, "company_id": _first_of_tier(Content.entries("companies"), tier_id),
		"template_id": _first_of_tier(Content.entries("postings"), tier_id), "tier": tier_id,
		"seed": interview_seed, "tired": Odds.is_tired(cfg, run.energy),
		"question_ids": plan["question_ids"], "warmup_id": plan["warmup_id"],
	}
	InterviewPlan.mark_seen(run.seen_question_ids, plan["question_ids"] + [plan["warmup_id"]])


static func _debug_args() -> Dictionary:
	var args: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var pair := arg.trim_prefix("--").split("=", true, 1)
		if pair.size() == 2:
			args[pair[0]] = pair[1]
	return args


## The first id, in sorted order, of this tier's MVP companies or of its postings open to any company.
static func _first_of_tier(entries: Dictionary, tier_id: String) -> String:
	var ids: Array = entries.keys()
	ids.sort()
	for id: Variant in ids:
		var entry: Variant = entries[id]
		if entry is Dictionary:
			var fields: Dictionary = entry
			if str(fields.get("tier", "")) == tier_id and bool(fields.get("mvp", true)) \
					and str(fields.get("company", "any")) == "any":
				return str(id)
	return ""

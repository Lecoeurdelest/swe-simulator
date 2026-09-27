extends Control
## The interview (GDD S07-S09, ARCHITECTURE 11.6): the VS intro, 5 prompts on the real formulas, then a
## K.O., the committee wheel or a rejection with Ducky's card. One coroutine, _run(), drives it all.
## Doubt and Composure live here, not in the save (ARCHITECTURE 8): a resume restarts this interview from
## the checkpoint with the same seed, so the same questions and the same luck replay.
## The tap rule: the AnswerMeter sits below SafeArea and every container and panel in SafeArea ignores the
## mouse, so a tap that misses a real control reaches the meter; [II] keeps its own tap. Taps that reach
## this root finish or advance the dialogue.
## Debug builds print one IVTRACE line per resolved prompt and one IVRESULT line per outcome.

signal _line_shown
signal _advanced
signal _answer_picked(index: int)

## Debug quick start (ARCHITECTURE 11.6): project_run mode="custom" on this scene plays this background at
## this tier. User args override them: --iv-bg=intern --iv-tier=big
const DEBUG_BG := "graduate"
const DEBUG_TIER := "mid"
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

var _cfg: BalanceConfig
var _tier: TierData
var _bg: BackgroundData
var _rng := RandomNumberGenerator.new()   # the interview RNG, seeded from the checkpoint (ARCHITECTURE 7.2)
var _doubt := 0.0
var _composure := 0.0
var _tired := false
var _textbook_used := false
var _worst_q := INF
var _worst_id := ""
var _worst_red := false
var _last_bad_tip := ""
var _typing := false
var _waiting_advance := false
var _type_tween: Tween
var _lock_token := 0
var _fit_queued := false
var _meter_result := ""             # after the tap: PERFECT / GOOD / CLOSE / ...uhh over the needle
var _pivot_flash := false
var _meter_text: Dictionary = {}
var _player_color := Color.WHITE
var _hunt_buttons: Array[Button] = []

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
@onready var _probe_row: Control = %ProbeRow
@onready var _come_clean_button: Button = %ComeCleanButton
@onready var _bluff_button: Button = %BluffButton
@onready var _ducky_card: Control = %DuckyCard
@onready var _card_note: DuckyNote = %CardNote
@onready var _back_to_hunt_button: Button = %BackToHuntButton
@onready var _versus: VersusIntro = %VersusIntro
@onready var _result_layer: Control = %ResultLayer
@onready var _coach_note: DuckyNote = %CoachNote
@onready var _ko_banner: Control = %KOBanner
@onready var _banner_label: Label = %BannerLabel
@onready var _wheel: CommitteeWheel = %CommitteeWheel
@onready var _ready_overlay: Control = %ReadyOverlay
@onready var _ready_label: Label = %ReadyLabel
@onready var _pause: PauseMenu = %PauseMenu


func _ready() -> void:
	if OS.is_debug_build() and GameState.run.background_id == "":
		_debug_quick_start()
	_cfg = Content.balance
	var run: RunState = GameState.run
	_tier = Content.tier(str(run.interview.get("tier", "")))
	_bg = Content.background(run.background_id)
	_hunt_buttons.assign([_back_to_hunt_button])
	_set_static_text()
	_connect_signals()
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
func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_PAUSED:
			_ready_overlay.visible = not _pause.is_open()
		NOTIFICATION_UNPAUSED:
			_ready_overlay.hide()
			_rearm_locks()


## Back: skip the VS intro when allowed, else open Pause; Back again resumes (ARCHITECTURE 9).
func handle_back() -> bool:
	if _pause.is_open():
		return _pause.handle_back()
	if _versus.try_skip():
		return true
	_ready_overlay.hide()
	_pause.open()
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
	_rng.seed = str(iv.get("seed", "0")).to_int()
	_tired = bool(iv.get("tired", false))
	_doubt = float(_tier.doubt_hp)
	_composure = float(_bg.composure_max)
	_doubt_bar.max_value = _doubt
	_composure_bar.max_value = _composure
	_update_bars()
	var prompts := _build_prompts(iv)
	var warmup_id := str(iv.get("warmup_id", ""))
	_round_label.text = Content.text("barks", "ui_round", {"n": 1, "total": prompts.size()})
	_trace_start(iv, prompts)
	_versus.play(str(iv.get("company_id", "")), str(iv.get("tier", "")))
	await _versus.finished
	await _greet(iv)
	for i: int in prompts.size():
		if i == 1 and warmup_id != "":  # GDD 5.8.2: the warm-up comes before prompt 2
			await _ask_warmup(warmup_id)
		var n := i + 1
		_round_label.text = Content.text("barks", "ui_round", {"n": n, "total": prompts.size()})
		var prompt: Dictionary = prompts[i]
		match str(prompt["kind"]):
			"choice":
				await _ask_choice(n, str(prompt["id"]))
			"knowledge":
				await _ask_knowledge(n, str(prompt["id"]), false)
			"probe":
				await _ask_probe(n, str(prompt["id"]))
		if _doubt <= 0.0:
			await _ko()
			return
		if _composure <= 0.0:
			await _reject("composure_zero", "bark_dana_composure_zero")
			return
	if Odds.committee_eligible(_cfg, _doubt, _tier.doubt_hp):
		await _committee()
	else:
		await _reject("rejected", "bark_dana_other_candidates")


## One prompt per question id, in checkpoint order (cfg.prompt_pattern). GDD 5.8.2: a lie probe
## replaces knowledge prompt 2 (the checkpoint's probe_line; Step 5 rolls it).
func _build_prompts(iv: Dictionary) -> Array[Dictionary]:
	var choice_pool := Content.entries("questions_choice")
	var probe_line := str(iv.get("probe_line", ""))
	var knowledge_count := 0
	var prompts: Array[Dictionary] = []
	for id: Variant in iv.get("question_ids", []):
		var kind := "choice" if choice_pool.has(str(id)) else "knowledge"
		if kind == "knowledge":
			knowledge_count += 1
			if knowledge_count == 2 and probe_line != "":
				prompts.append({"kind": "probe", "id": probe_line})
				continue
		prompts.append({"kind": kind, "id": str(id)})
	return prompts


## CONTENT 8.1: the greeting (or "greet again" from the second interview of a run), then the
## background opener on the first interview of a run, then the Tired line if you arrived Tired.
func _greet(iv: Dictionary) -> void:
	var run: RunState = GameState.run
	if run.interviews_taken > 0 and run.dana_last_company != "":
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
	_trace(n, id, "choice", "-", "-", "-", "-", str(kind))
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
	var h := Odds.zone_half(_cfg, s, bonus)
	_tired_label.visible = _tired
	_show_thumb(_tap_pad)
	_meter_result = ""
	_meter.show()
	_meter.start(_cfg, Odds.needle_speed(_cfg, _tier, _tired), h, _tier.zone_jumps, _relaxed(), _rng)
	# Visible luck (GDD 5.8.4): the zone shows while Dana asks, and the needle waits for her question.
	# Meanwhile taps pass through the meter to finish her line.
	_meter.set_process(false)
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_meter_row.queue_redraw()
	_dana_speaks()
	await _type(Content.field("questions_knowledge", id, "prompt"))
	_meter.mouse_filter = Control.MOUSE_FILTER_STOP
	_meter.set_process(true)
	var input: float = await _meter.resolved
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
	_trace(n, id, "warmup" if warmup else "knowledge", "%.2f" % s, "%.4f" % h, "%.2f" % input, "%.2f" % answer_q, str(grade))
	_meter_result = _input_label(input)
	_meter_row.queue_redraw()
	if grade == &"red":  # GDD S08: Ducky's real answer as a full-width note in the thumb band
		_card_note.tip_text = _real_answer(Content.field("questions_knowledge", id, "ducky"))
		_back_to_hunt_button.hide()
		_show_thumb(_ducky_card)
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


## The lie probe (GDD 5.8.5, ARCHITECTURE 11.6 step 5) is the next task: Come clean / Bluff on the
## ProbeRow with Odds.bluff_p, and BUSTED passes busted = true to finish_interview. Until then no
## checkpoint carries a probe_line, so this never runs.
func _ask_probe(_n: int, cv_line_id: String) -> void:
	push_warning("Interview: the lie probe is not built yet; skipped %s" % cv_line_id)


func _ko() -> void:
	_doubt = 0.0
	_update_bars()
	_log_result("ko")
	Device.haptic(KO_HAPTIC_MS)
	_show_banner(Content.text("barks", "vs_ko"), BANNER_BIG)
	await get_tree().create_timer(KO_HOLD_S, false).timeout
	_show_banner(Content.text("barks", "vs_offer"), BANNER_BIG)
	await _say_dana(Content.text("barks", "bark_dana_ko"))
	GameState.finish_interview(true, _composure)


## GDD 5.8.6: the win wedge is drawn at the real odds; the outcome is rolled on the interview RNG first.
func _committee() -> void:
	var win_p := Odds.committee_win_p(_cfg, _doubt, _tier.doubt_hp, GameState.run.stat("net"))
	var won := Odds.roll(_rng, win_p)
	if OS.is_debug_build():
		print("IVWHEEL|p=%.4f|won=%s" % [win_p, won])
	_show_banner(Content.text("barks", "vs_committee"), BANNER_SMALL)
	await _say_dana(Content.text("barks", "bark_dana_committee"))
	_ko_banner.hide()
	_wheel.show_odds(win_p)
	await _wheel.spin(won, WHEEL_SPIN_S)
	if won:
		_log_result("wheel_win")
		await _say_dana(Content.text("barks", "bark_dana_committee_win"))
		GameState.finish_interview(true, _composure)
		return
	_log_result("wheel_loss")
	await _say_dana(Content.text("barks", "bark_dana_committee_lose"))
	await _rejection_card("tip_research_company")  # GDD 8.3: committee loss


func _reject(outcome: String, dana_line_id: String) -> void:
	_log_result(outcome)
	_show_banner(Content.text("barks", "vs_reject"), BANNER_SMALL)
	await _say_dana(Content.text("barks", dana_line_id))
	await _rejection_card(_rejection_tip())


## GDD S09: the thumb band becomes Ducky's card: one tip, the model answer of your worst knowledge
## question and a full-width [ Back to the hunt ]. Rejections use up the day's interview.
func _rejection_card(tip_id: String) -> void:
	var text := Content.field("tips", tip_id, "short")
	if _worst_id != "":
		text += "\n" + _real_answer(Content.field("questions_knowledge", _worst_id, "green"))
	_card_note.tip_text = text
	_meter.hide()
	_meter_row.hide()
	_back_to_hunt_button.show()
	_back_to_hunt_button.disabled = false
	_show_thumb(_ducky_card)
	_lock(_hunt_buttons)
	_dana_speaks()
	_type(Content.text("barks", "bark_dana_reject"))
	await _back_to_hunt_button.pressed
	_back_to_hunt_button.disabled = true
	GameState.finish_interview(false, maxf(_composure, 0.0))


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
	await _advanced


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
	await _line_shown


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
	var index: int = await _answer_picked
	return index


func _on_answer_pressed(index: int) -> void:
	if not _answer_column.visible:
		return  # one answer per prompt: a double tap can't answer twice
	_answer_column.hide()
	_answer_picked.emit(index)


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


## ARCHITECTURE 9: the tap on "Ready?" re-arms the lock.
func _rearm_locks() -> void:
	if _answer_column.visible:
		_lock(_answer_buttons)
	elif _ducky_card.visible and _back_to_hunt_button.visible:
		_lock(_hunt_buttons)


func _on_ready_overlay_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_ready_overlay.hide()
		get_tree().paused = false


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
	_composure_label.text = Content.text("barks", "ui_composure")
	_doubt_label.text = Content.text("barks", "ui_doubt")
	_hint_label.text = Content.text("barks", "meter_hint")
	_tired_label.text = Content.text("barks", "ui_tired")
	_come_clean_button.text = Content.text("barks", "ui_come_clean")
	_bluff_button.text = Content.text("barks", "ui_bluff")
	_back_to_hunt_button.text = Content.text("barks", "ui_back_to_hunt")
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
	_meter.zone_jumped.connect(_on_zone_jumped)
	_meter_row.draw.connect(_draw_meter_labels)
	resized.connect(_queue_fit)
	Device.layout_changed.connect(_queue_fit)
	_dialogue_box.item_rect_changed.connect(_queue_fit)
	_stage_spacer.item_rect_changed.connect(_queue_fit)
	_meter_row.item_rect_changed.connect(_queue_fit)


func _hide_transient() -> void:
	_meter.hide()
	for node: CanvasItem in [_answer_column, _tap_pad, _probe_row, _ducky_card, _coach_note, _ko_banner, _wheel, _ready_overlay]:
		node.hide()
	_line.text = ""
	_name_tab.text = ""


## The thumb band shows one thing at a time (ARCHITECTURE 11.6 ThumbSlot).
func _show_thumb(node: Control) -> void:
	for slot: CanvasItem in [_answer_column, _tap_pad, _probe_row, _ducky_card]:
		slot.visible = slot == node


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

func _trace_start(iv: Dictionary, prompts: Array[Dictionary]) -> void:
	if not OS.is_debug_build():
		return
	var ids := PackedStringArray()
	for prompt: Dictionary in prompts:
		ids.append(str(prompt["id"]))
	print("IVSTART|tier=%s|bg=%s|company=%s|seed=%s|doubt=%.2f|comp=%.2f|tired=%s|warmup=%s|ids=%s|taken=%d" % [
		_tier.id, GameState.run.background_id, iv.get("company_id", ""), iv.get("seed", ""), _doubt, _composure,
		_tired, iv.get("warmup_id", ""), ",".join(ids), GameState.run.interviews_taken])


## prompt=0 is the warm-up. S, h, I and Q are "-" on a choice prompt.
func _trace(n: int, id: String, kind: String, s: String, h: String, input: String, q: String, answer: String) -> void:
	if OS.is_debug_build():
		print("IVTRACE|prompt=%d|id=%s|kind=%s|S=%s|h=%s|I=%s|Q=%s|answer=%s|doubt=%.2f|comp=%.2f" % [
			n, id, kind, s, h, input, q, answer, _doubt, _composure])


func _log_result(outcome: String) -> void:
	if OS.is_debug_build():
		print("IVRESULT|outcome=%s|doubt=%.2f|comp=%.2f|tier=%s|bg=%s" % [
			outcome, _doubt, _composure, _tier.id, GameState.run.background_id])


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
		"question_ids": plan["question_ids"], "warmup_id": plan["warmup_id"], "probe_line": "",
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

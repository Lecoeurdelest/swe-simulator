@tool
extends McpTestSuite
## The work state's session (ARCHITECTURE 19.4, 19.7; KILL_TESTS 6-8; O8, INV-22): a career run played the way the
## screen plays it. Time moves only on tick(), which refuses while a notice or a card is open; every answer goes through
## Sim.apply_inputs, which does not tick; the save is exact; a run played this way replays from its log. Editor-side:
## no autoloads, no user://.

const SEED := 20261009

var c: SimContext = SimFixture.ctx(true)


func suite_name() -> String:
	return "work_session"


func _start(first: bool = true) -> WorkSession:
	return WorkSession.start(c, 1, SEED, [], "Alex", first)


## Answer whatever is open, the way a patient player would (WorkSession.answer_simply).
func _answer(session: WorkSession) -> void:
	session.answer_simply()


## Play until `day`, answering every card, or until the layoff scene is next. The guard keeps a bug from hanging the run.
func _play_to(session: WorkSession, day: int) -> void:
	var guard := 0
	while session.sim.day < day and not session.is_over() and guard < 20000:
		guard += 1
		if session.is_blocked():
			if session.wants_layoff_scene():
				return
			_answer(session)
		else:
			session.tick()
	assert_true(guard < 20000, "the session never hung")


func test_a_new_run_waits_paused_on_day_zero() -> void:
	var session := _start()
	assert_eq(session.sim.day, 0)
	assert_true(session.sim.employed, "run 1 starts employed (D-02)")
	assert_eq(session.clock.speed, WorkClock.PAUSE, "the clock waits until the player starts it")
	assert_false(session.is_blocked())
	assert_true(session.current_card().is_empty())
	assert_eq(session.player_name, "Alex")
	session.tick()
	assert_eq(session.sim.day, 1, "tick() is one day")


func test_tick_refuses_while_a_notice_or_a_card_is_open() -> void:  # INV-22
	var session := _start()
	session.notices.append(WorkCards.notice(WorkCards.INFO, {"literal": "Hiring is paused."}))
	assert_true(session.is_blocked())
	assert_eq(session.current_card()["literal"], "Hiring is paused.")
	assert_true(session.tick().is_empty(), "a notice stops the clock")
	assert_eq(session.sim.day, 0)
	session.dismiss_notice()
	assert_false(session.is_blocked())
	session.sim.queue.append({"kind": "event", "id": "evt_e12_incident_prod", "choices": ["fix_it", "escalate"], "exhausted": "fix_it"})
	assert_true(session.is_blocked(), "a card the sim waits on stops it too")
	assert_true(session.tick().is_empty())
	assert_eq(session.sim.day, 0)
	assert_eq(session.current_card()["kind"], WorkCards.K_EVENT)


func test_answers_never_burn_a_day() -> void:  # Sim.apply_inputs
	var session := _start()
	session.set_hours(5)
	assert_eq(session.sim.hours, 5)
	assert_eq(session.sim.day, 0, "changing the Hours on a paused clock costs no day")
	session.sim.queue.append({"kind": "event", "id": "evt_e12_incident_prod", "choices": ["fix_it", "escalate"], "exhausted": "fix_it"})
	var events := session.choose("fix_it")
	assert_eq(session.sim.day, 0, "and neither does an answer")
	assert_true(session.sim.queue.is_empty())
	assert_gt(SimFixture.count(events, "event_resolved"), 0)
	var refused := session.choose("fix_it")
	assert_eq(SimFixture.count(refused, "input_rejected"), 1, "an answer to nothing is refused, not applied")


func test_a_whole_job_plays_through_to_the_layoff() -> void:  # the M2 gate: finish job 1 and know why
	var session := _start()
	var rumors := 0
	var reviews := 0
	var guard := 0
	while not session.wants_layoff_scene() and not session.is_over() and guard < 20000:
		guard += 1
		if session.is_blocked():
			var card := session.current_card()
			if card.get("kind", "") == "notice" and card.has("literal"):
				rumors += 1
			if card.get("kind", "") == WorkCards.K_REVIEW:
				reviews += 1
			_answer(session)
		else:
			session.tick()
	assert_true(session.wants_layoff_scene(), "job 1 ends in the layoff scene")
	assert_eq(session.sim.day, 240, "on day 240 (R-RUN-02)")
	assert_eq(rumors, 5, "after five readable signs")
	assert_eq(reviews, 1, "and one review on day 180")
	assert_false(session.sim.employed, "the job is already gone")
	assert_true(float(session.sim.pending()["severance"]) > 0.0, "with a severance figure for the scene")
	session.acknowledge()
	assert_false(session.is_blocked(), "the scene's OK frees the clock")
	assert_false(session.wants_layoff_scene())
	session.tick()
	assert_eq(session.sim.day, 241, "and the run goes on, between jobs")


func test_the_save_round_trip_is_exact_and_lives_the_same_days() -> void:  # KILL_TESTS 6, O8
	var a := _start()
	_play_to(a, 175)
	a.set_hours(4)
	a.sim.queue.append({"kind": "event", "id": "evt_e12_incident_prod", "choices": ["fix_it", "escalate"], "exhausted": "fix_it"})
	a.notices.append(WorkCards.notice(WorkCards.INFO, {"literal": "Minh's desk is empty.", "n": 1.5}))
	a.close_coach(WorkSession.COACH_SPEED)
	var text := SaveIO.encode(a.to_save(GameFlow.Phase.WORK))
	assert_eq(SaveIO.kind_of(SaveIO.decode(text)), SaveIO.KIND_CAREER, "it reads as a career save")
	var b := WorkSession.from_save(SaveIO.decode(text), c)
	assert_eq(JSON.stringify(b.sim.to_dict()), JSON.stringify(a.sim.to_dict()), "the sim comes back bit for bit")
	assert_eq(b.notices, a.notices, "the notice that was open is open again (moment 7)")
	assert_eq(b.notices[0]["n"], 1.5, "floats in the screen's state survive too")
	assert_eq(b.feed, a.feed)
	assert_eq(b.coach_closed, [WorkSession.COACH_SPEED])
	assert_eq(b.player_name, "Alex")
	assert_true(b.first_run)
	assert_eq(b.clock.speed, WorkClock.PAUSE, "Continue waits")
	assert_eq(b.current_card()["literal"], "Minh's desk is empty.", "the same card, before any choice")
	assert_eq(b.sim.pending()["id"], "evt_e12_incident_prod", "and the same event card behind it")
	for session: WorkSession in [a, b]:
		session.dismiss_notice()
		session.choose("fix_it")
		_play_to(session, 235)
	assert_eq(JSON.stringify(b.sim.to_dict()), JSON.stringify(a.sim.to_dict()), "and 60 days later they are still the same run")


func test_a_run_played_with_inputs_between_ticks_replays_from_its_log() -> void:  # O8, Sim.apply_inputs
	var session := _start()
	var guard := 0
	while session.sim.day < 238 and not session.is_over() and guard < 20000:
		guard += 1
		if session.is_blocked():
			if session.wants_layoff_scene():
				break
			_answer(session)
		else:
			if session.sim.day % 9 == 0:
				session.set_hours(1 + (session.sim.day / 9) % 5)   # a change on a paused clock, before the day's tick
			session.tick()
	var replayed := Sim.replay(c, 1, SEED, [], session.sim.log, session.sim.day)
	assert_eq(replayed.day, session.sim.day)
	for key: String in ["savings", "burnout", "mo", "skill", "rust", "codebase", "ticket_progress", "job_salary", "pay_accrued", "hours", "level", "stats"]:
		assert_eq(replayed.get(key), session.sim.get(key), "replayed %s" % key)
	assert_eq(JSON.stringify(replayed.to_dict()), JSON.stringify(session.sim.to_dict()), "the whole state")


func test_the_review_stand_in_rolls_its_own_dice() -> void:  # A67
	var a := _start()
	var b := _start()
	_play_to(a, 179)
	_play_to(b, 179)
	a.tick()
	b.tick()
	assert_eq(a.current_card()["kind"], WorkCards.K_REVIEW, "day 180 brings the review")
	assert_true(a.resolve_review().size() > 0)
	assert_true(b.resolve_review().size() > 0)
	assert_eq(JSON.stringify(a.sim.to_dict()), JSON.stringify(b.sim.to_dict()), "the same run, the same rating")
	var logged := false
	for entry: Dictionary in a.sim.log:
		if entry.get("k", "") == "in" and entry["i"].get("kind", "") == Sim.IN_REVIEW_RESULT:
			logged = true
	assert_true(logged, "the stand-in's answer is in the log, so a replay reuses it")
	assert_true(a.resolve_review().is_empty(), "no review waits any more")
	assert_false(a.notices.is_empty(), "the rating is a notice to read")
	assert_eq(a.notices[0]["event"], Sim.EVT_REVIEW)


func test_the_autoplay_helpers_close_an_interview_and_an_offer() -> void:  # fail_interview and decline_offer
	var session := _start()
	session.sim.queue.append({"kind": "duel", "app": 1, "index": 0, "of": 1, "request": {}})
	session.sim.applications.append({"posting": {"id": 1, "company": "co_synergai"}, "applied": 0, "reply": 1, "callback": true,
		"interview": 2, "status": "interview", "duels_done": 0, "next_duel": -1})
	assert_eq(session.current_card()["kind"], WorkCards.K_DUEL)
	session.fail_interview()
	assert_false(session.sim.is_waiting(), "a failed interview frees the clock")
	session.sim.queue.append({"kind": "offer", "app": 2, "posting": {"id": 2, "company": "co_synergai"}})
	session.decline_offer()
	assert_false(session.sim.is_waiting(), "a declined offer too")


func test_coach_marks_come_one_at_a_time_on_the_first_run_only() -> void:  # GDD 4.3, the M2 huddle
	var session := _start()
	assert_eq(session.coach_id(), WorkSession.COACH_SPEED, "day 0, clock waiting: start it")
	session.clock.set_speed(1, c.cfg)
	assert_eq(session.coach_id(), "", "the clock is running: that mark is done, and the next waits for day 1")
	session.tick()
	assert_eq(session.coach_id(), WorkSession.COACH_HOURS, "then the Hours")
	session.close_coach(WorkSession.COACH_HOURS)
	assert_eq(session.coach_id(), "", "a closed mark stays closed")
	_play_to(session, WorkSession.COACH_STUDIO_FROM_DAY)
	assert_eq(session.coach_id(), WorkSession.COACH_STUDIO, "then the Studio chip, once the Hours mark is out of the way")
	session.close_coach(WorkSession.COACH_STUDIO)
	assert_eq(session.coach_id(), "")
	var later := _start(false)
	assert_eq(later.coach_id(), "", "no marks after the first run")
	var moved := _start()
	moved.clock.set_speed(1, c.cfg)
	moved.tick()
	moved.set_hours(2)
	assert_eq(moved.coach_id(), "", "moving the Hours is what that mark asks for")
	_play_to(moved, WorkSession.COACH_STUDIO_FROM_DAY)
	assert_eq(moved.coach_id(), WorkSession.COACH_STUDIO, "and then the Studio chip follows")
	var blocked := _start()
	blocked.notices.append(WorkCards.notice(WorkCards.INFO, {"literal": "x"}))
	assert_eq(blocked.coach_id(), "", "never over a card")


func test_the_feed_keeps_only_the_latest_lines() -> void:
	var session := _start()
	_play_to(session, 150)
	assert_true(session.feed.size() <= WorkCards.FEED_MAX)
	assert_gt(session.feed.size(), 0, "paydays, rents and tickets leave lines")
	for line: Dictionary in session.feed:
		assert_true(int(line["day"]) <= session.sim.day)


func test_a_burned_out_player_is_asked_to_read_the_warnings() -> void:  # R-EVT-02 beats
	var session := _start()
	session.sim.burnout = 61.0
	session.tick()
	var warned := false
	for n: Dictionary in session.notices:
		if n.get("id", "") == "ui_burnout_warn_60":
			warned = true
	assert_true(warned, "the first beat is a notice when Burnout crosses 60")
	assert_true(session.is_blocked())


func test_run_ones_clip_is_one_card_that_blocks_the_clock_until_a_tap() -> void:  # D-42
	var session := _start()
	assert_true(session.notices.is_empty(), "the unit-test session starts without it: GameState queues it for a real run 1")
	session.queue_clip()
	assert_true(session.is_blocked(), "the clock waits for the clip")
	assert_eq(session.current_card()["style"], WorkCards.CLIP)
	assert_eq(session.coach_id(), "", "no coach note over a card")
	assert_true(session.tick().is_empty(), "no time passes under it (INV-22)")
	session.dismiss_notice()
	assert_false(session.is_blocked(), "a tap starts the run")
	assert_eq(session.coach_id(), WorkSession.COACH_SPEED, "then the first coach note")


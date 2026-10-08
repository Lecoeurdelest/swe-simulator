@tool
extends McpTestSuite
## The cards, notices and feed lines the work state shows (GDD 4.6, 5.19; ARCHITECTURE 19.7), built from the sim's
## events and queue. Plain data in, plain data out: no text, only ids and numbers. Editor-side: no autoloads.

var c: SimContext = SimFixture.ctx(true)


func suite_name() -> String:
	return "work_cards"


func _styles(notices: Array) -> Array:
	var out: Array = []
	for n: Dictionary in notices:
		out.append(n["style"])
	return out


func test_a_rumor_is_a_notice_with_its_own_line() -> void:  # R-RUN-02: the five signs must be read
	var s := SimFixture.fresh(c)
	var out := WorkCards.notices_from([{"kind": "rumor", "event": "evt_e07_resizing", "text": "Hiring is paused."}], s, c)
	assert_eq(out.size(), 1)
	assert_eq(out[0]["style"], WorkCards.INFO)
	assert_eq(out[0]["literal"], "Hiring is paused.")


func test_the_three_burnout_beats_use_their_lines() -> void:  # CONTENT 16.2
	var s := SimFixture.fresh(c)
	var ids: Array = []
	for level: int in 3:
		var out := WorkCards.notices_from([{"kind": "burnout_warning", "level": level}], s, c)
		assert_eq(out[0]["style"], WorkCards.WARNING)
		ids.append(out[0]["id"])
	assert_eq(ids, ["ui_burnout_warn_60", "ui_burnout_warn_70", "ui_burnout_warn_75"])


func test_an_auto_resolved_card_says_burnout_picked() -> void:  # R-EVT-02, AC-EVT02-2
	var s := SimFixture.fresh(c)
	var out := WorkCards.notices_from([{"kind": "auto_resolved", "id": "evt_e24_overtime_ask", "choice": "stay_late"}], s, c)
	assert_eq(out[0]["id"], "ui_auto_resolved")
	assert_eq(out[0]["event"], "evt_e24_overtime_ask")
	assert_eq(out[0]["choice"], "stay_late", "the scene looks the label up in the event")


func test_a_review_result_carries_its_rating_and_raise() -> void:
	var s := SimFixture.fresh(c)
	s.level = WorkOdds.MID
	var out := WorkCards.notices_from([{"kind": "review_result", "rating": WorkOdds.EXCEEDS, "raise": 0.03, "promoted": true}], s, c)
	assert_eq(out[0]["event"], Sim.EVT_REVIEW)
	assert_eq(out[0]["rating"], "exceeds")
	assert_eq(out[0]["raise_pct"], 3)
	assert_true(out[0]["promoted"])
	assert_eq(out[0]["level"], WorkOdds.MID)


func test_tips_pips_and_survived_resizings_are_notices() -> void:
	var s := SimFixture.fresh(c)
	var out := WorkCards.notices_from([
		{"kind": "pip_started", "ends": 90},
		{"kind": "tip", "id": "tip_escalate", "event": "evt_e12_incident_prod"},
		{"kind": "resizing_survived", "cuts": 2}], s, c)
	assert_eq(_styles(out), [WorkCards.WARNING, WorkCards.DUCKY, WorkCards.INFO])
	assert_eq(out[0]["id"], "ui_pip")
	assert_eq(out[1]["tip"], "tip_escalate")
	assert_eq(out[2]["n"], 2)


func test_an_event_without_choices_is_a_notice_only_when_it_pauses() -> void:
	var s := SimFixture.fresh(c)
	assert_true(WorkCards.notices_from([{"kind": "event", "id": "evt_e01_payday", "choices": []}], s, c).is_empty(), "payday does not pause")
	assert_true(WorkCards.notices_from([{"kind": "event", "id": "evt_e12_incident_prod", "choices": ["fix_it"]}], s, c).is_empty(), "a card with choices comes from the queue, not as a notice")
	var pausing := WorkCards.notices_from([{"kind": "event", "id": "evt_e07_resizing", "choices": []}], s, c)
	assert_eq(pausing.size(), 1, "an event that pauses and has no choices only needs reading")
	assert_eq(pausing[0]["event"], "evt_e07_resizing")


func test_the_feed_keeps_the_quiet_lines() -> void:
	var s := SimFixture.fresh(c)
	s.day = 25
	var feed := WorkCards.feed_from([
		{"kind": "payday", "amount": 2.55}, {"kind": "rent", "amount": 2.1},
		{"kind": "ticket_shipped", "on_time": true, "size": 1}, {"kind": "ticket_shipped", "on_time": false, "size": 1},
		{"kind": "rumor", "event": "evt_e07_resizing", "text": "Hiring is paused."},
		{"kind": "something_else"}], s)
	assert_eq(feed.size(), 5, "the unknown kind adds nothing")
	assert_eq(feed[0]["id"], "evt_e01_payday")
	assert_eq(feed[0]["field"], "text")
	assert_eq(feed[0]["args"]["money_k"], 2.55)
	assert_eq(feed[1]["field"], "text_rent")
	assert_eq(feed[2]["id"], "ui_feed_shipped")
	assert_eq(feed[3]["id"], "ui_feed_late")
	assert_eq(feed[4]["literal"], "Hiring is paused.")
	for line: Dictionary in feed:
		assert_eq(line["day"], 25)


func test_the_head_card_follows_the_queue() -> void:
	var s := SimFixture.fresh(c)
	assert_true(WorkCards.head(s, c).is_empty(), "nothing waits")
	s.queue.append({"kind": "event", "id": "evt_e12_incident_prod", "choices": ["fix_it", "escalate"], "exhausted": "fix_it"})
	var card := WorkCards.head(s, c)
	assert_eq(card["kind"], WorkCards.K_EVENT)
	assert_eq(card["event"], "evt_e12_incident_prod")
	assert_eq(card["choices"], ["fix_it", "escalate"])
	s.queue = [{"kind": "review", "evidence": 55.0, "calibration": 60.0}]
	assert_eq(WorkCards.head(s, c)["kind"], WorkCards.K_REVIEW)
	s.queue = [{"kind": "ticket_pick"}]
	assert_eq(WorkCards.head(s, c)["choices"], ["feature", "bugfix", "paydown"], "the Mid's three cards (R-CTL-02)")
	s.queue = [{"kind": "forced_leave", "days": 30}]
	assert_eq(WorkCards.head(s, c)["kind"], WorkCards.K_LEAVE)
	assert_eq(WorkCards.head(s, c)["days"], 30)
	s.queue = [{"kind": "duel", "app": 1, "index": 0, "of": 1, "request": {}}]
	assert_eq(WorkCards.head(s, c)["kind"], WorkCards.K_DUEL)
	s.queue = [{"kind": "offer", "app": 1, "posting": {}}]
	assert_eq(WorkCards.head(s, c)["kind"], WorkCards.K_OFFER)


func test_the_layoff_scene_is_not_a_card() -> void:
	var s := SimFixture.fresh(c)
	s.queue = [{"kind": "layoff_scene", "severance_months": 1.0, "severance": 2.55}]
	assert_true(WorkCards.head(s, c).is_empty(), "the LAYOFF phase shows it")
	assert_true(WorkCards.is_layoff_pending(s))
	s.queue.clear()
	assert_false(WorkCards.is_layoff_pending(s))


func test_event_args_name_the_money_and_the_next_home() -> void:  # E20 "Buy a new one ({money})", E21 "Move to {home}"
	var s := SimFixture.fresh(c)
	var laptop := WorkCards.event_args("evt_e20_laptop_dies", s, c)
	assert_true(absf(float(laptop["money_k"]) - 1.2) < 0.0001, "the laptop costs 1.2 k$")
	assert_eq(laptop["home"], 1, "one tier up from the Shared room")
	s.home = 3
	assert_eq(WorkCards.event_args("evt_e21_lifestyle_offer", s, c)["home"], 3, "the Penthouse is the top")
	assert_eq(float(WorkCards.event_args("evt_e12_incident_prod", s, c)["money_k"]), 0.0, "an event with no cost names none")


func test_a_layoff_card_carries_the_severance_it_paid() -> void:  # the scene shows the figure (CONTENT 16.6)
	var s := SimFixture.fresh(c)
	var salary := s.job_salary
	s.day = 239
	var events := Sim.step(s, [], c)
	assert_eq(s.day, 240)
	var item := s.pending()
	assert_eq(item.get("kind", ""), "layoff_scene", "run 1's layoff is on day 240")
	assert_true(absf(float(item["severance"]) - float(item["severance_months"]) * salary) < 0.0001, "months x the salary it had")
	assert_gt(float(item["severance"]), 0.0)
	assert_eq(SimFixture.count(events, "job_ended"), 1)

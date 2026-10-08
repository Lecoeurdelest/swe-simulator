@tool
class_name WorkCards
extends RefCounted
## What the work state shows over the clock (GDD 4.6, 5.19; ARCHITECTURE 19.7), built from the sim's events and its
## queue as plain data. Pure, like WorkHud: the scene only draws these dictionaries and sends the player's answer back.
## A card carries ids and numbers, never text, so the words stay in the JSON (INV-15) and a test can check each one.
##
## Notices: something to read, with OK. The clock waits until it is dismissed (INV-22). Styles: info, warning and
##   ducky (a tip). Fields by what they name: "literal" (a line the data already carries, a rumor), "id" (a barks id),
##   "event" (a work_events entry), "tip", plus the numbers its text needs.
## Feed lines: one quiet line in the Body (payday, rent, a shipped ticket, a rumor), no pause.
## Head cards: the sim's queue head, which the player must answer: an event with choices, a review, a Mid's ticket
##   pick, the forced leave, an interview day (Start leads to the duel screen: DuelAdapter). The layoff scene is the
##   LAYOFF phase's, and an offer is answered on the contract screen.

const INFO := "info"
const WARNING := "warning"
const DUCKY := "ducky"
const CLIP := "clip"   # run 1's day-0 clip card (D-42): Remy's five conditions

const K_EVENT := "event"
const K_REVIEW := "review"
const K_PICK := "ticket_pick"
const K_LEAVE := "forced_leave"
const K_DUEL := "duel"
const K_OFFER := "offer"

const BURNOUT_WARN_IDS: PackedStringArray = ["ui_burnout_warn_60", "ui_burnout_warn_70", "ui_burnout_warn_75"]
const FEED_MAX := 8


static func notice(style: String, fields: Dictionary) -> Dictionary:
	var out: Dictionary = {"kind": "notice", "style": style}
	out.merge(fields)
	return out


## The notices a step's (or an input's) events leave to read, in order.
static func notices_from(events: Array, s: SimState, ctx: SimContext) -> Array:
	var out: Array = []
	for e: Dictionary in events:
		match String(e.get("kind", "")):
			"rumor":
				out.append(notice(INFO, {"literal": String(e["text"])}))
			"burnout_warning":
				out.append(notice(WARNING, {"id": BURNOUT_WARN_IDS[clampi(int(e["level"]), 0, BURNOUT_WARN_IDS.size() - 1)]}))
			"auto_resolved":
				out.append(notice(WARNING, {"id": "ui_auto_resolved", "event": String(e["id"]), "choice": String(e["choice"])}))
			"review_result":
				out.append(notice(INFO, {
					"event": Sim.EVT_REVIEW, "rating": WorkOdds.RATINGS[int(e["rating"])],
					"raise_pct": roundi(float(e["raise"]) * 100.0), "promoted": bool(e["promoted"]), "level": s.level}))
			"pip_started":
				out.append(notice(WARNING, {"id": "ui_pip"}))
			"tip":
				out.append(notice(DUCKY, {"tip": String(e["id"])}))
			"resizing_survived":
				out.append(notice(INFO, {"id": "ui_resizing_survived", "n": int(e["cuts"])}))
			"callback":   # a reply with an interview day (GDD 5.20, A92): a notice; the day is on the calendar strip too
				out.append(notice(INFO, {"id": "ui_callback_notice", "company": String(e["company"]), "day": int(e["interview"])}))
			"recruiter_posting":
				out.append(notice(INFO, {"id": "ui_recruiter_posting", "company": String(e["company"]), "day": int(e["interview"])}))
			"profile_noticed":
				out.append(notice(WARNING, {"id": "ui_profile_noticed"}))
			"event":
				if (e.get("choices", []) as Array).is_empty():  # no choices: it only needs reading, if it pauses at all
					var evt: Dictionary = ctx.events.get(String(e["id"]), {})
					if bool(evt.get("pause", false)):
						out.append(notice(INFO, {"event": String(e["id"])}))
	return out


## The quiet lines a step's events leave in the Body: {day, file, id, field, args, literal} (a line is its literal text, or
## the text at file/id/field with its args).
static func feed_from(events: Array, s: SimState) -> Array:
	var out: Array = []
	for e: Dictionary in events:
		match String(e.get("kind", "")):
			"payday":
				out.append(line(s.day, "work_events", "evt_e01_payday", "text", {"money_k": float(e["amount"])}))
			"rent":
				out.append(line(s.day, "work_events", "evt_e01_payday", "text_rent", {"money_k": float(e["amount"])}))
			"ticket_shipped":
				out.append(line(s.day, "barks", "ui_feed_shipped" if bool(e["on_time"]) else "ui_feed_late", "", {}))
			"rumor":
				out.append({"day": s.day, "literal": String(e["text"])})
			"resizing_survived":
				out.append(line(s.day, "barks", "ui_resizing_survived", "", {"n": int(e["cuts"])}))
			"application_sent":
				out.append(line(s.day, "barks", "ui_applied_feed", "", {"company": String(e["company"])}))
			"rejected":
				out.append(line(s.day, "barks", "ui_rejected_feed", "", {"company": String(e["company"])}))
			"interview_failed":
				out.append(line(s.day, "barks", "ui_interview_failed_feed", "", {"company": String(e["company"])}))
			"offer_declined":
				out.append(line(s.day, "barks", "ui_offer_declined_feed", "", {"company": String(e["company"])}))
			"job_started":
				out.append(line(s.day, "barks", "ui_job_started_feed", "", {"company": String(e["company"])}))
			"studied":
				out.append(line(s.day, "barks", "ui_studied_feed", "", {}))
	return out


static func line(day: int, file: String, id: String, field: String, args: Dictionary) -> Dictionary:
	return {"day": day, "file": file, "id": id, "field": field, "args": args}


## The card the sim is waiting on, or {} when time can run (or when only the LAYOFF phase's scene is waiting).
static func head(s: SimState, ctx: SimContext) -> Dictionary:
	var item := s.pending()
	match String(item.get("kind", "")):
		"event":
			var evt_id := String(item["id"])
			return {"kind": K_EVENT, "event": evt_id, "choices": (item["choices"] as Array).duplicate(),
				"args": event_args(evt_id, s, ctx)}
		"review":
			return {"kind": K_REVIEW, "event": Sim.EVT_REVIEW}
		"ticket_pick":
			return {"kind": K_PICK, "choices": Array(Sim.PICK_NAMES)}
		"forced_leave":
			return {"kind": K_LEAVE, "days": int(item["days"])}
		"duel":
			var app := Sim.find_application(s, int(item["app"]))
			return {"kind": K_DUEL, "company": String((app.get("posting", {}) as Dictionary).get("company", "")),
				"index": int(item["index"]), "of": int(item["of"])}
		"offer":
			return {"kind": K_OFFER}
	return {}


## Numbers an event's text may name: {money} is what its first money choice costs, {home} the next home tier up.
static func event_args(evt_id: String, s: SimState, ctx: SimContext) -> Dictionary:
	var money := 0.0
	var evt: Dictionary = ctx.events.get(evt_id, {})
	for choice: Dictionary in evt.get("choices", []):
		var eff: Dictionary = choice.get("effects", {})
		if eff.has("savings"):
			money = absf(float(eff["savings"]))
			break
	return {"money_k": money, "home": mini(s.home + 1, ctx.cfg.home_rent_k.size() - 1)}


## True when the sim's queue head is the layoff scene (the LAYOFF phase shows it).
static func is_layoff_pending(s: SimState) -> bool:
	return String(s.pending().get("kind", "")) == "layoff_scene"

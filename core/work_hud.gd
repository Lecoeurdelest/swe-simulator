@tool
class_name WorkHud
extends RefCounted
## What the work state's top band shows, as numbers and text ids (GDD 5.16, 4.6): the four numbers (Runway, Burnout,
## Ticket, the Codebase's 10 LEDs), the Studio chip and the 60-day calendar strip. Pure, like WorkOdds: it reads a
## SimState and changes nothing, so the scene only draws what it is told (INV-03) and a test can check each number.

const LED_COUNT := 10
const LED_STEP := 10.0   # one LED turns red per 10 Codebase points

const CAL_IDS: Dictionary = {
	"payday": "ui_cal_payday", "rent": "ui_cal_rent", "review": "ui_cal_review",
	"interview": "ui_cal_interview", "deadline": "ui_cal_deadline", "lease": "ui_cal_lease",
}
const LEVEL_IDS: PackedStringArray = ["ui_level_junior", "ui_level_mid", "ui_level_senior"]
const HOME_IDS: PackedStringArray = ["ui_home_shared", "ui_home_one_bed", "ui_home_studio", "ui_home_penthouse"]


## Rent plus living costs for a month, in k$ (what the Runway chip divides by).
static func monthly_bills(s: SimState) -> float:
	return s.rent + s.living_cost * s.living_mult


## Months of bills the savings cover, never below zero.
static func runway_months(s: SimState) -> float:
	return maxf(0.0, WorkOdds.runway_months(s.savings, s.rent, s.living_cost * s.living_mult))


## The chip turns red under runway_red_months. The number always shows too, so colour is never the only signal.
static func runway_is_red(s: SimState, cfg: WorkConfig) -> bool:
	return runway_months(s) < cfg.runway_red_months


## "4.2": the {months} of ui_runway.
static func runway_text(s: SimState) -> String:
	return "%.1f" % runway_months(s)


## Burnout as a 0..1 bar fill.
static func burnout_frac(s: SimState, cfg: WorkConfig) -> float:
	return clampf(s.burnout / cfg.burnout_max, 0.0, 1.0)


## The server rack: how many of the 10 LEDs are red (one per 10 Codebase points).
static func codebase_red_leds(s: SimState) -> int:
	return clampi(floori(s.codebase / LED_STEP), 0, LED_COUNT)


## The ticket's progress as a 0..1 bar fill. Between jobs there is no ticket.
static func ticket_frac(s: SimState) -> float:
	if not s.employed:
		return 0.0
	return clampf(s.ticket_progress / 100.0, 0.0, 1.0)


## Days to the ticket's deadline; negative when it is late. 0 between jobs.
static func ticket_days_left(s: SimState) -> int:
	return s.ticket_deadline - s.day if s.employed else 0


static func ticket_is_late(s: SimState) -> bool:
	return s.employed and s.day > s.ticket_deadline


## How many of the Studio's five conditions hold now (the chip's "Studio 3/5").
static func studio_count(s: SimState, cfg: WorkConfig) -> int:
	return WorkOdds.studio_count(cfg, s.level, s.job_remote, s.home, s.burnout, s.savings, s.living_cost * s.living_mult)


static func hours_label_id(notch: int) -> String:
	return "ui_hours_%d" % clampi(notch, 1, 5)


static func level_label_id(level: int) -> String:
	return LEVEL_IDS[clampi(level, 0, LEVEL_IDS.size() - 1)]


static func home_label_id(home: int) -> String:
	return HOME_IDS[clampi(home, 0, HOME_IDS.size() - 1)]


## The speed control's label id for a position: 0 is Pause, then one per WorkConfig speed ("1x", "2x", "4x").
static func speed_label_id(position: int, cfg: WorkConfig) -> String:
	if position <= WorkClock.PAUSE or position > cfg.speeds.size():
		return "ui_speed_pause"
	return "ui_speed_%d" % cfg.speeds[position - 1]


## The calendar strip (GDD 5.14): what is coming in the next calendar_days days, as {offset, kind, label_id} with
## offset 1..calendar_days from today. Several things on one day stay as separate entries.
static func calendar(ctx: SimContext, s: SimState) -> Array:
	var out: Array = []
	for item: Dictionary in EventPlan.calendar(ctx, s, ctx.cfg.calendar_days):
		var kind: String = item["kind"]
		out.append({"offset": int(item["day"]) - s.day, "kind": kind, "label_id": String(CAL_IDS.get(kind, ""))})
	return out


## The next thing on the calendar (for a text line under the strip), or {} when the strip is empty.
static func next_on_calendar(ctx: SimContext, s: SimState) -> Dictionary:
	var items := calendar(ctx, s)
	return items[0] if not items.is_empty() else {}

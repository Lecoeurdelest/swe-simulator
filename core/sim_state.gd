@tool
class_name SimState
extends RefCounted
## The whole career as plain data (INV-07, GDD 5.14, ARCHITECTURE 19.2): numbers, strings, bools, Arrays and
## Dictionaries, never a Resource or a Node. Sim.step changes it and nothing else does. Money is in k$ (GDD 5.15).
## Levels are 0 junior, 1 mid, 2 senior; homes 0 shared room to 3 penthouse (WorkOdds). to_dict and from_dict walk
## the script variables below, so a new field is saved without touching them. Seeds and the RNG state travel as
## strings (INV-05). The save of record is to_save: Godot's JSON parser does not read every double back exactly (it can be a
## unit in the last place off), and one stray digit is enough to flip a threshold days of game time later, so to_save writes
## every float as its raw 64 bits in hex and from_save restores it exactly. to_dict keeps plain floats for tests and display.

const VERSION := 1
const FLOAT_TAG := "f:"

# ---------- the run ----------
var version: int = VERSION
var rng_seed: int = 0
var rng_state: int = 0
var bg_id: String = "intern"
var run_number: int = 1
var day: int = 0
var ended: bool = false
var ending: String = ""

# ---------- money, k$ ----------
var savings: float = 0.0
var pay_accrued: float = 0.0
var below_zero_days: int = 0
var living_cost: float = 1.2
var living_mult: float = 1.0
var home: int = 0
var rent: float = 0.9
var lease_day: int = 0

# ---------- the career ----------
var level: int = 0
var jobs_held: int = 0
var employed: bool = false
var unemployed_since: int = -1
var studies_this_spell: int = 0
var gap_scar_given: bool = false
var last_study_day: int = -1

# ---------- the job ----------
var job_company: String = ""
var job_archetype: String = ""
var job_salary: float = 0.0
var job_start: int = 0
var job_remote: bool = false
var job_clauses: Array = []
var job_flags: Array = []
var commute_burnout: float = 0.0
var coworkers: Array = []
var past_coworkers: Array = []

# ---------- work stats ----------
var hours: int = 3
var burnout: float = 0.0
var mo: float = 0.0
var skill: float = 0.0
var rust: float = 0.0
var codebase: float = 0.0
var quality: int = 1

# ---------- the ticket ----------
var ticket_size: int = 1
var ticket_kind: int = 0
var ticket_progress: float = 0.0
var ticket_start: int = 0
var ticket_deadline: int = 0
var tickets_shipped: int = 0
var tickets_on_time: int = 0
var push_back_used: bool = false

# ---------- temporary effects ----------
var speed_mod: float = 1.0
var speed_mod_until: int = -1
var hours_lock_until: int = -1
var last_incident_day: int = -9999

# ---------- the review ----------
var next_review: int = -1
var on_time_since_review: int = 0
var below_streak: int = 0
var rating_streak: int = 0
var pip_end: int = -1

# ---------- Scars and the forced leave ----------
var scar_short_tenure: int = 0
var scar_burnout_history: int = 0
var scar_bad_reference: int = 0
var scar_resume_gap: int = 0
var scar_corner_cutter: int = 0
var calm_days: int = 0
var forced_leaves: int = 0
var leave_end: int = -1

# ---------- events ----------
var event_last: Dictionary = {}
var queue: Array = []
var chains: Array = []
var warn_armed: Array = [true, true, true]
var layoff_known_day: int = -1

# ---------- the job hunt ----------
var board: Array = []
var board_day: int = -9999
var next_posting_id: int = 1
var applications: Array = []
var blacklist: Array = []

# ---------- the win ----------
var studio_hold: int = 0

# ---------- the Handbook ----------
var handbook: Array = []
var tips_seen: Array = []
var h_emergency: bool = false
var h_brag: bool = false
var h_take_call: bool = false
var h_overtime: bool = false

# ---------- bookkeeping ----------
var stats: Dictionary = {}
var log: Array = []


## The item the clock is waiting on (an event card, a review, a duel, an offer...), or {} when time can run.
func pending() -> Dictionary:
	return queue[0] if not queue.is_empty() else {}


func is_waiting() -> bool:
	return not queue.is_empty()


## The floor of the job you hold, or of the next one you could take: 1 to max_jobs.
func floor_n() -> int:
	return maxi(1, jobs_held)


func has_tip(tip_id: String) -> bool:
	return handbook.has(tip_id)


## Cache the Handbook's four Edge tips as bools, so the daily formulas never search the list.
func refresh_edges() -> void:
	h_emergency = handbook.has("tip_emergency_fund")
	h_brag = handbook.has("tip_brag_doc")
	h_take_call = handbook.has("tip_take_the_call")
	h_overtime = handbook.has("tip_overtime_loan")


func bump(key: String, by: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + by


## The exact save (O8): to_dict with every float as "f:" and 16 hex digits. Only ints stay JSON numbers, so a JSON round
## trip cannot change a value.
func to_save() -> Dictionary:
	return _encode(to_dict())


static func from_save(data: Dictionary) -> SimState:
	return from_dict(_decode(data))


static func _encode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0, v)
			return FLOAT_TAG + bytes.hex_encode()
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in v:
				out.append(_encode(item))
			return out
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key: Variant in v:
				out[key] = _encode(v[key])
			return out
	return v


static func _decode(v: Variant) -> Variant:
	match typeof(v):
		TYPE_STRING:
			var text: String = v
			if text.length() == FLOAT_TAG.length() + 16 and text.begins_with(FLOAT_TAG):
				return text.substr(FLOAT_TAG.length()).hex_decode().decode_double(0)
			return text
		TYPE_FLOAT:
			return int(v)
		TYPE_ARRAY:
			var out: Array = []
			for item: Variant in v:
				out.append(_decode(item))
			return out
		TYPE_DICTIONARY:
			var out: Dictionary = {}
			for key: Variant in v:
				out[key] = _decode(v[key])
			return out
	return v


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for prop: Dictionary in get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var key: String = prop["name"]
		var value: Variant = get(key)
		if key == "rng_seed" or key == "rng_state":
			out[key] = str(value)
		elif value is Array or value is Dictionary:
			out[key] = value.duplicate(true)
		else:
			out[key] = value
	return out


## Unknown keys are ignored and missing ones keep their defaults, so an old save still loads (like RunState).
## JSON gives floats back for every number: ints and bools are restored by each field's own type.
static func from_dict(data: Dictionary) -> SimState:
	var s := SimState.new()
	for prop: Dictionary in s.get_property_list():
		if not (int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var key: String = prop["name"]
		if not data.has(key):
			continue
		var raw: Variant = data[key]
		match int(prop["type"]):
			TYPE_INT:
				s.set(key, int(str(raw)) if raw is String else int(raw))
			TYPE_FLOAT:
				s.set(key, float(raw))
			TYPE_BOOL:
				s.set(key, bool(raw))
			TYPE_STRING:
				s.set(key, str(raw))
			TYPE_ARRAY, TYPE_DICTIONARY:
				s.set(key, (raw as Variant).duplicate(true))
	s.refresh_edges()
	return s

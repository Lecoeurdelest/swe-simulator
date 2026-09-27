@tool
class_name RunState
extends RefCounted
## One playthrough (GDD 10.4). EVERY `var` below is saved to JSON automatically by to_dict(),
## so only plain data lives here: String / int / float / bool, Array, Dictionary. Ids are Strings.
## Never store a Resource, a Node or a StringName here.
## Rule methods (spend_energy, sleep, ...) change this object. They never touch autoloads, scenes
## or the global RNG: they take cfg / tier / bg / rng as arguments, so tests and the balance sim
## can run them inside the editor.

const VERSION := 1

# --- flow and RNG ---
var phase: GameFlow.Phase = GameFlow.Phase.TITLE
var rng_seed: String = "0"            # 64-bit RNG values travel as strings (JSON numbers are doubles)
var rng_state: String = "0"
var first_run: bool = true            # the day-2 guarantee (GDD 5.7) only applies to the first run

# --- character (Phase 2 takes this person to work) ---
var background_id: String = ""
var player_name: String = "Alex"
var stats: Dictionary[String, int] = {"knw": 0, "exp": 0, "net": 0}
var lone_wolf: bool = false           # Self-Taught until the first Network (SHOULD)
var gap_topics: Array[String] = []
var commute_pips: int = 0
var commute_minutes: int = 0
var cv_levels: Dictionary[String, String] = {"edu": "honest", "exp": "honest", "proj": "honest"}
var lies_carried: Array[String] = []  # Lie cv-line ids that were sent and never busted or confessed
var confessed: Array[String] = []     # "company_id|cv_line_id": no background check for that pair

# --- day loop ---
var day: int = 1
var energy: int = 0
var rent_days_left: int = 0
var grace_used: bool = false
var referral_tokens: int = 0
var pity_count: int = 0               # Recruiter Radar
var interviews_today: int = 0
var next_uid: int = 1
var board: Array[Dictionary] = []         # {uid, template_id, company_id, tier, posted_days_ago, applicants, is_ghost, reposted}
var applications: Array[Dictionary] = []  # {uid, template_id, company_id, tier, day_sent, reveal_day, p, hits, knockout, is_ghost, referral, tailored, lies, status}
var applied: Array[String] = []           # "template_id|company_id": never dealt again this run
var invites: Array[Dictionary] = []       # {app_uid, company_id, template_id, tier, day_received, kind}
var morning_report: Dictionary = {}       # built by Sleep; the hunt scene shows it, "Start day" clears it
var blacklist: Array[String] = []         # company ids: declined, BUSTED or rescinded
var researched: Array[String] = []        # company ids (SHOULD)
var seen_question_ids: Array[String] = []

# --- interview checkpoint: a resume replays exactly this interview (GDD 5.11) ---
var interview: Dictionary = {}        # {invite_uid, company_id, template_id, tier, seed, question_ids, probe_line, warmup_id, tired}
var interviews_taken: int = 0
var times_met_dana: int = 0
var dana_last_company: String = ""

# --- offer, job, result ---
var offer: Dictionary = {}            # {company_id, template_id, job_title, salary, work_mode, office_days, perks, fine_print, equity_text, negotiated}
var employment: Dictionary = {}       # the accepted offer + tier + red_flags (Phase 2 reads this)
var dream_score: int = -1
var total_applications: int = 0
var total_rejections: int = 0


# ---------- rule methods (examples; more arrive with each feature) ----------

func stat(id: String) -> int:
	return stats.get(id, 0)


func spend_energy(pips: int) -> bool:
	if pips > energy:
		return false
	energy -= pips
	return true


func new_uid() -> int:
	next_uid += 1
	return next_uid - 1


## The lie probe's lasting effects (GDD 5.8.5), applied with the interview result so nothing is saved
## mid-interview: Come clean marks the line confessed for this company (no background check there,
## 5.9.4), and a confessed or BUSTED line is no longer a lie you carry (Phase 2 hook).
func settle_probe(company_id: String, cv_line_id: String, came_clean: bool, busted: bool) -> void:
	if cv_line_id == "":
		return
	var pair := company_id + "|" + cv_line_id
	if came_clean and not confessed.has(pair):
		confessed.append(pair)
	if came_clean or busted:
		lies_carried.erase(cv_line_id)


## Night: one Sleep. The morning reveal runs when the next day starts.
func sleep(cfg: BalanceConfig) -> void:
	day += 1
	rent_days_left = maxi(rent_days_left - 1, 0)
	energy = cfg.energy_max - commute_pips
	interviews_today = 0


# ---------- save format ----------

func to_dict() -> Dictionary:
	var d: Dictionary = {"version": VERSION}
	for prop: Dictionary in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[prop["name"]] = get(prop["name"])
	return d


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	# When VERSION changes, migrate `d` here first, e.g. if int(d.get("version", 1)) < 2: ...
	for prop: Dictionary in r.get_property_list():
		var key: String = prop["name"]
		if not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) or not d.has(key):
			continue
		var value: Variant = _whole_floats_to_ints(d[key])
		var current: Variant = r.get(key)
		match typeof(current):
			TYPE_ARRAY:
				(current as Array).assign(value)        # keeps the typed array (Array[String] ...)
			TYPE_DICTIONARY:
				(current as Dictionary).assign(value)
			TYPE_INT:
				r.set(key, int(value))
			TYPE_FLOAT:
				r.set(key, float(value))
			TYPE_BOOL:
				r.set(key, bool(value))
			_:
				r.set(key, str(value))
	return r


## JSON turns every number into a float. Whole numbers become ints again, recursively.
static func _whole_floats_to_ints(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var f: float = v
			if f == floorf(f) and absf(f) < 9.0e15:
				return int(f)
			return f
		TYPE_ARRAY:
			var arr: Array = []
			for e: Variant in v:
				arr.append(_whole_floats_to_ints(e))
			return arr
		TYPE_DICTIONARY:
			var dict: Dictionary = {}
			var src: Dictionary = v
			for k: Variant in src:
				dict[k] = _whole_floats_to_ints(src[k])
			return dict
	return v

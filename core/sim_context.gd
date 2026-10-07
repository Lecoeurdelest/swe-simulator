@tool
class_name SimContext
extends RefCounted
## What Sim.step reads but never changes (INV-08): the constants, the archetypes, the parsed event and coworker
## JSON, the Phase 1 data the duel request borrows, and the run's RNG. Build one with load_default() (tests, the
## harness: no autoloads, res:// files only) or by hand. The sim saves the RNG's seed and state in SimState and
## restores them at the start of every step, so one context can serve many runs in turn.

const WORK_CONFIG_PATH := "res://data/work/work_config.tres"
const ARCHETYPE_DIR := "res://data/archetypes/"
const BACKGROUND_DIR := "res://data/backgrounds/"
const TIER_DIR := "res://data/tiers/"
const EVENTS_PATH := "res://data/content/work_events.json"
const COWORKERS_PATH := "res://data/content/coworkers.json"

var cfg: WorkConfig
var archetypes: Dictionary = {}          # id -> ArchetypeData
var arch_ids: PackedStringArray = []     # sorted: the order rolls are made in
var events: Dictionary = {}              # evt id -> entry (work_events.json)
var coworker_defs: Dictionary = {}       # cw_* id -> entry (coworkers.json)
var coworker_pool: PackedStringArray = []
var bg: BackgroundData
var tiers: Dictionary = {}               # tier id -> TierData
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var log_enabled: bool = true             # the run log; the harness turns it off for speed

var random_events: Array = []            # [{id, per_year, cooldown}], sorted by id
var chain_events: Array = []             # telegraphed events that start from a roll, sorted by id


static func load_default(bg_id: String = "intern") -> SimContext:
	var ctx := SimContext.new()
	ctx.cfg = load(WORK_CONFIG_PATH) as WorkConfig
	for file: String in ResourceLoader.list_directory(ARCHETYPE_DIR):
		if file.ends_with(".tres"):
			var arch := load(ARCHETYPE_DIR + file) as ArchetypeData
			ctx.archetypes[String(arch.id)] = arch
	ctx.bg = load(BACKGROUND_DIR + bg_id + ".tres") as BackgroundData
	for file: String in ResourceLoader.list_directory(TIER_DIR):
		if file.ends_with(".tres"):
			var tier := load(TIER_DIR + file) as TierData
			ctx.tiers[String(tier.id)] = tier
	ctx.events = _read_json(EVENTS_PATH)
	var cw := _read_json(COWORKERS_PATH)
	ctx.coworker_pool = PackedStringArray(cw.get("_coworker_pool", []))
	for key: String in cw:
		if key.begins_with("cw_"):
			ctx.coworker_defs[key] = cw[key]
	ctx.build()
	return ctx


## Sort the archetype ids and pre-sort the events that roll, so no dictionary order ever decides a roll.
func build() -> void:
	arch_ids = PackedStringArray(archetypes.keys())
	arch_ids.sort()
	random_events.clear()
	chain_events.clear()
	var ids: Array = events.keys()
	ids.sort()
	for id: String in ids:
		if id.begins_with("_"):
			continue
		var evt: Dictionary = events[id]
		var trigger: Dictionary = evt.get("trigger", {})
		match String(trigger.get("kind", "")):
			"random":
				random_events.append({"id": id, "per_year": float(trigger.get("per_year", 0.0)), "cooldown": int(trigger.get("cooldown_days", 0))})
			"chain":
				chain_events.append({"id": id, "per_year": float(trigger.get("per_year", 0.0)), "cooldown": int(trigger.get("cooldown_days", 0))})


func archetype(id: String) -> ArchetypeData:
	return archetypes.get(id) as ArchetypeData


static func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

extends Node
## Autoload "Content": read-only registry of static data (GDD 5.0).
##   Numbers you tune (.tres): Content.balance, Content.background(id), Content.tier(id)
##   Text keyed by id (JSON):  Content.entry("companies", "co_beigeware"), Content.text("barks", "ui_apply")
## Never modify what it returns: loaded Resources are cached and shared by the whole game.
## Missing files only warn, so the game runs before the data exists (Step 1-3).

const BALANCE_PATH := "res://data/balance/balance_config.tres"
const JSON_FILES: PackedStringArray = [
	"naming", "backgrounds", "tiers", "companies", "postings", "cv_lines",
	"questions_choice", "questions_knowledge", "barks", "emails", "tips",
	"endings", "events", "cutscene", "names", "news", "work_events", "coworkers", "questions_review",
]

var balance: BalanceConfig
var _backgrounds: Dictionary[StringName, BackgroundData] = {}
var _tiers: Dictionary[StringName, TierData] = {}
var _json: Dictionary[String, Dictionary] = {}   # file name -> { id -> entry }


func _ready() -> void:
	balance = load(BALANCE_PATH) if ResourceLoader.exists(BALANCE_PATH) else BalanceConfig.new()
	for res: Resource in load_tres_dir("res://data/backgrounds/"):
		var bg := res as BackgroundData
		if bg != null:
			_backgrounds[bg.id] = bg
	for res: Resource in load_tres_dir("res://data/tiers/"):
		var tier_data := res as TierData
		if tier_data != null:
			_tiers[tier_data.id] = tier_data
	for file: String in JSON_FILES:
		_json[file] = load_json("res://data/content/%s.json" % file)
	print("Content: %d backgrounds, %d tiers, %d/%d JSON files" % [
		_backgrounds.size(), _tiers.size(), _json.values().filter(func(d: Dictionary) -> bool: return not d.is_empty()).size(), JSON_FILES.size()])


func background(id: StringName) -> BackgroundData:
	return _backgrounds.get(id)


func tier(id: StringName) -> TierData:
	return _tiers.get(id)


func entries(file: String) -> Dictionary:
	return _json.get(file, {})


func entry(file: String, id: String) -> Variant:
	return entries(file).get(id)


## Display text for an id: translated with tr(), {placeholders} filled from args.
func text(file: String, id: String, args: Dictionary = {}) -> String:
	var e: Variant = entry(file, id)
	if e == null:
		push_warning("Content: missing text %s/%s" % [file, id])
		return id
	var raw: String = e if e is String else str((e as Dictionary).get("text", id))
	return UiText.fill(tr(raw), args)


## One text field of a structured entry, e.g. field("questions_knowledge", "kq_hash_map", "prompt").
func field(file: String, id: String, key: String, args: Dictionary = {}) -> String:
	var e: Variant = entry(file, id)
	if not (e is Dictionary) or not (e as Dictionary).has(key):
		push_warning("Content: missing %s/%s.%s" % [file, id, key])
		return id
	return UiText.fill(tr(str(e[key])), args)


static func load_tres_dir(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for file: String in ResourceLoader.list_directory(dir):  # original names, also in exported builds
		if file.ends_with(".tres"):
			var res := load(dir + file)
			if res != null:
				out.append(res)
	return out


static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_error("Content: %s must be one JSON object keyed by id" % path)
		return {}
	return data

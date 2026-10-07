extends SceneTree
## Loads every .gd and .tscn under the game folders; parse errors print as SCRIPT ERROR.
## Copied into the project copy as __check_all.gd by lib.sh.
const ROOTS := ["res://autoload", "res://core", "res://data", "res://features", "res://ui", "res://tests"]
var bad := 0
var count := 0
var _started := false
func _process(_delta: float) -> bool:
	if _started:
		return false
	_started = true  # first frame: the autoloads exist now, so GameState/Content/Device resolve
	for r: String in ROOTS:
		_walk(r)
	print("CHECK files=%d failed=%d" % [count, bad])
	quit()
	return false
func _walk(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for sub: String in d.get_directories():
		_walk(path + "/" + sub)
	for f: String in d.get_files():
		var p := path + "/" + f
		if f.ends_with(".gd"):
			count += 1
			var s: GDScript = load(p)
			if s == null or not s.can_instantiate():
				bad += 1
				print("BAD_SCRIPT ", p)
		elif f.ends_with(".tscn"):
			count += 1
			var ps: PackedScene = load(p)
			if ps == null or not ps.can_instantiate():
				bad += 1
				print("BAD_SCENE ", p)

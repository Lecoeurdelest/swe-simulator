@tool
class_name SaveIO
extends RefCounted
## The one run save: JSON in user:// (app-private on Android and iOS), written to a temp file,
## then renamed, so a crash mid-write never leaves half a save.
## Never load .tres/.res from user://: a resource file can carry a script that runs on load.
##
## Two kinds share the slot (ARCHITECTURE 19.4): Phase 1's hunt run (RunState.to_dict, version 1) and the career
## run's ({version: 2, phase, sim, ui}: WorkSession.to_save). kind_of() tells them apart; a hunt save never reads as a
## career one, so Continue can route to the right flow.

const PATH := "user://save_v1.json"
const KIND_NONE := ""
const KIND_HUNT := "hunt"
const KIND_CAREER := "career"
const CAREER_VERSION := 2


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(path)


## Phase 1's run (RunState). false when the slot holds nothing writable.
static func write(run: RunState, path: String = PATH) -> bool:
	return write_text(JSON.stringify(run.to_dict(), "\t"), path)


## The career run: WorkSession.to_save(phase).
static func write_career(payload: Dictionary, path: String = PATH) -> bool:
	return write_text(encode(payload), path)


static func encode(payload: Dictionary) -> String:
	return JSON.stringify(payload, "\t")


## Temp file, then rename. Some platforms refuse to rename over an existing file, so remove it and retry.
static func write_text(text: String, path: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	f.close()
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	return err == OK


## The save file as parsed JSON ({} when there is none or it is unreadable).
static func peek(path: String = PATH) -> Dictionary:
	if not exists(path):
		return {}
	return decode(FileAccess.get_file_as_string(path))


static func decode(text: String) -> Dictionary:
	var json := JSON.new()   # not parse_string: that prints an engine error for a bad file
	if json.parse(text) != OK or not (json.data is Dictionary):
		push_warning("Save file unreadable; ignoring it.")
		return {}
	return json.data


## "career" for a version-2 save with a sim, "hunt" for any other save, "" for nothing.
static func kind_of(data: Dictionary) -> String:
	if data.is_empty():
		return KIND_NONE
	if int(data.get("version", 1)) >= CAREER_VERSION and data.has("sim"):
		return KIND_CAREER
	return KIND_HUNT


static func kind(path: String = PATH) -> String:
	return kind_of(peek(path))


## Phase 1's run, or null when the slot is empty, unreadable or holds a career run.
static func read(path: String = PATH) -> RunState:
	var data := peek(path)
	if kind_of(data) != KIND_HUNT:
		return null
	return RunState.from_dict(data)


static func delete(path: String = PATH) -> void:
	if exists(path):
		DirAccess.remove_absolute(path)

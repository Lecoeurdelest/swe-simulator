@tool
class_name SaveIO
extends RefCounted
## The one run save: JSON in user:// (app-private on Android and iOS), written to a temp file,
## then renamed, so a crash mid-write never leaves half a save.
## Never load .tres/.res from user://: a resource file can carry a script that runs on load.

const PATH := "user://save_v1.json"


static func exists(path: String = PATH) -> bool:
	return FileAccess.file_exists(path)


static func write(run: RunState, path: String = PATH) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(JSON.stringify(run.to_dict(), "\t"))
	f.close()
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:  # some platforms refuse to rename over an existing file
		DirAccess.remove_absolute(path)
		err = DirAccess.rename_absolute(tmp, path)
	return err == OK


static func read(path: String = PATH) -> RunState:
	if not exists(path):
		return null
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		push_warning("Save file unreadable; ignoring it.")
		return null
	return RunState.from_dict(data)


static func delete(path: String = PATH) -> void:
	if exists(path):
		DirAccess.remove_absolute(path)

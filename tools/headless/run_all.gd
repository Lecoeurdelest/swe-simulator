extends SceneTree
## Headless runner: every res://tests/test_*.gd through McpTestRunner (same pass rule as godot-ai test_run).
## Copied into the project copy as __run_all.gd by lib.sh. Pass `-- suite=<name>` to run one suite.
func _init() -> void:
	var filter := ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("suite="):
			filter = a.substr(6)
	var suites: Array = []
	var files: Array[String] = []
	for f: String in DirAccess.open("res://tests").get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f: String in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			print("LOAD_FAIL ", f)
			continue
		suites.append(script.new())
	var res: Dictionary = McpTestRunner.new().run_suites(suites, filter, "", {}, false)
	print("RESULT passed=%d failed=%d total=%d suites=%d ms=%d" % [res.passed, res.failed, res.total, res.suite_count, res.duration_ms])
	for fail: Dictionary in res.get("failures", []):
		print("FAIL ", fail.get("suite", ""), ".", fail.get("test", ""), ": ", str(fail.get("message", "")).replace("\n", " | "))
	quit()

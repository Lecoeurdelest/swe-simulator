extends SceneTree
## The balancing harness (GDD 5.22, ARCHITECTURE 19.6, DECISIONS A56): bots play whole careers through Sim.step, headless,
## outside test_run. It loads res:// data like the tests do and touches no autoload, no user:// and no scene.
##
##   godot --headless --path <copy> --script res://tests/harness/run_harness.gd -- bot=planner seeds=10000
##
## Arguments (key=value): bot = planner | coaster | grinder | lifestyle | random | all (default all);
## seeds = how many runs (default 1000); first = the first seed (default 1); run = the run number, 1 starts employed at
## the authored job and 2 or more start between jobs (default 1); bg = intern | graduate | self_taught (default intern);
## handbook = none | full (the Edge and Option tips collected, default none); out = a folder to write <bot>.json into;
## set = overrides for experiments, "field:value,arch.startup.pay_mult:0.9,bg.start_savings_months:1" (HarnessRunner.apply_overrides);
## trace = N prints the first seed's state every N days and every sim event (debugging one run); dump = 1 prints one
## RUN,seed,ending,day,jobs,level,employed,savings,burnout,promotions,layoffs,quits_and_fires line per run.
## Prints one RESULT line per bot, then the JSON report on a REPORT line.



func _init() -> void:
	var args := _parse(OS.get_cmdline_user_args())
	var names: Array = HarnessRunner.BOTS if str(args.get("bot", "all")) == "all" else [str(args["bot"])]
	var seeds := int(args.get("seeds", "1000"))
	var first := int(args.get("first", "1"))
	var run_number := int(args.get("run", "1"))
	var bg_id := str(args.get("bg", "intern"))
	var handbook: Array = HarnessRunner.HANDBOOK_FULL if str(args.get("handbook", "none")) == "full" else []
	var out_dir := str(args.get("out", ""))
	var trace_every := int(args.get("trace", "0"))
	var dump := str(args.get("dump", "0")) == "1"
	var ctx := SimContext.load_default(bg_id)
	ctx.log_enabled = false
	for problem: String in HarnessRunner.apply_overrides(ctx, str(args.get("set", ""))):
		print("OVERRIDE_PROBLEM ", problem)
	var duel := DuelModel.load_default()
	for bot_name: String in names:
		var bot := HarnessRunner.make_bot(bot_name)
		if bot == null:
			print("UNKNOWN_BOT ", bot_name)
			continue
		var report := HarnessRunner.play(bot_name, bot, ctx, duel, first, seeds, run_number, handbook, trace_every, dump)
		report["params"] = {"bot": bot_name, "seeds": seeds, "first": first, "run": run_number, "bg": bg_id, "handbook": str(args.get("handbook", "none"))}
		print(HarnessRunner.summary_line(report))
		print("REPORT ", JSON.stringify(report))
		if out_dir != "":
			DirAccess.make_dir_recursive_absolute(out_dir)
			var f := FileAccess.open("%s/%s.json" % [out_dir, bot_name], FileAccess.WRITE)
			if f != null:
				f.store_string(JSON.stringify(report, "  "))
	quit()


func _parse(raw: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	for a: String in raw:
		var i := a.find("=")
		if i > 0:
			out[a.substr(0, i)] = a.substr(i + 1)
	return out

@tool
class_name HarnessRunner
extends RefCounted
## The harness's run loop, shared by run_harness.gd (the command line) and test_sim_smoke (a few hundred seeds inside
## test_run): a bot plays whole careers through Sim.step and the results are summarized (GDD 5.22, ARCHITECTURE 19.6).

const BOTS := ["planner", "coaster", "grinder", "lifestyle", "random"]
const GUARD_STEPS := 40000
const HANDBOOK_FULL: Array = ["tip_emergency_fund", "tip_brag_doc", "tip_take_the_call", "tip_overtime_loan", "tip_remote_in_writing"]


static func make_bot(bot_name: String) -> BotBase:
	match bot_name:
		"planner":
			return BotPlanner.new()
		"coaster":
			return BotCoaster.new()
		"grinder":
			return BotGrinder.new()
		"lifestyle":
			return BotLifestyle.new()
		"random":
			return BotRandom.new()
	return null


## Play `seeds` careers with one bot and summarize them.
static func play(bot_name: String, bot: BotBase, ctx: SimContext, duel: DuelModel, first: int, seeds: int, run_number: int, handbook: Array, trace_every: int = 0) -> Dictionary:
	var endings: Dictionary = {}
	var days: Array[int] = []
	var loss_days: Array[int] = []
	var jobs_total := 0
	var mid_in_job1 := 0
	var rejected := 0
	var guard_hits := 0
	var totals: Dictionary = {}
	var hold_max := 0
	var level_end: Array[int] = [0, 0, 0]
	var started := Time.get_ticks_msec()
	for seed_n: int in range(first, first + seeds):
		var state := Sim.new_run(ctx, run_number, seed_n, handbook)
		bot.start_run(ctx, duel, seed_n ^ 0x5DEECE66D)
		var steps := 0
		var reached_mid := false
		while not state.ended and steps < GUARD_STEPS:
			var sent := bot.inputs(state, ctx)
			var happened := Sim.step(state, sent, ctx)
			steps += 1
			if trace_every > 0 and seed_n == first:
				trace_step(state, sent, happened, trace_every)
			if not reached_mid and state.jobs_held == 1 and state.level >= WorkOdds.MID:
				reached_mid = true
		if not state.ended:
			guard_hits += 1
		var ending := state.ending if state.ended else "guard"
		endings[ending] = int(endings.get(ending, 0)) + 1
		days.append(state.day)
		if ending != "studio":
			loss_days.append(state.day)
		jobs_total += state.jobs_held
		if reached_mid:
			mid_in_job1 += 1
		level_end[state.level] += 1
		for key: String in state.stats:
			totals[key] = int(totals.get(key, 0)) + int(state.stats[key])
		rejected += int(state.stats.get("rejected", 0))
		hold_max = maxi(hold_max, state.studio_hold)
	var elapsed := Time.get_ticks_msec() - started
	days.sort()
	loss_days.sort()
	var wins := int(endings.get("studio", 0))
	return {
		"bot": bot_name, "runs": seeds, "wins": wins, "win_rate": float(wins) / maxf(1.0, seeds),
		"endings": endings, "median_day": _pct(days, 0.5), "p10_day": _pct(days, 0.1), "p90_day": _pct(days, 0.9),
		"median_loss_day": _pct(loss_days, 0.5), "jobs_mean": float(jobs_total) / maxf(1.0, seeds),
		"mid_in_job1_share": float(mid_in_job1) / maxf(1.0, seeds), "level_at_end": level_end,
		"stats_per_run": _per_run(totals, seeds), "rejected_inputs": rejected, "guard_hits": guard_hits,
		"studio_hold_max": hold_max, "ms_total": elapsed, "ms_per_run": float(elapsed) / maxf(1.0, seeds),
	}


static func trace_step(s: SimState, sent: Array, happened: Array, every: int) -> void:
	var notable: Array[String] = []
	for e: Dictionary in happened:
		if e["kind"] != "rent" and e["kind"] != "payday":
			notable.append(JSON.stringify(e))
	for i: Dictionary in sent:
		notable.append("SENT " + JSON.stringify(i))
	if s.day % every == 0 or not notable.is_empty():
		print("d%-4d %s job=%s lvl=%d hrs=%d bo=%5.1f mo=%5.1f sk=%4.1f ru=%4.1f cb=%4.1f tk=%3.0f%%/%d sav=%6.2f below=%d hold=%d q=%d %s" % [
			s.day, "EMP" if s.employed else "---", s.job_archetype, s.level, s.hours, s.burnout, s.mo, s.skill, s.rust, s.codebase,
			s.ticket_progress, s.ticket_deadline, s.savings, s.below_zero_days, s.studio_hold, s.queue.size(), " | ".join(notable)])


static func _per_run(totals: Dictionary, seeds: int) -> Dictionary:
	var out: Dictionary = {}
	for key: String in totals:
		out[key] = snappedf(float(totals[key]) / maxf(1.0, seeds), 0.001)
	return out


static func _pct(sorted_values: Array[int], q: float) -> int:
	if sorted_values.is_empty():
		return 0
	return sorted_values[clampi(int(q * (sorted_values.size() - 1)), 0, sorted_values.size() - 1)]


static func summary_line(r: Dictionary) -> String:
	return "RESULT bot=%s runs=%d wins=%d (%.2f%%) median_day=%d median_loss_day=%d jobs=%.2f mid_in_job1=%.0f%% endings=%s ms_per_run=%.1f total_s=%.1f rejected=%d guard=%d" % [
		r["bot"], r["runs"], r["wins"], 100.0 * float(r["win_rate"]), r["median_day"], r["median_loss_day"], r["jobs_mean"],
		100.0 * float(r["mid_in_job1_share"]), JSON.stringify(r["endings"]), r["ms_per_run"], float(r["ms_total"]) / 1000.0,
		r["rejected_inputs"], r["guard_hits"]]



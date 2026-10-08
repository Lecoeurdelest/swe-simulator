@tool
class_name InterviewPlan
extends RefCounted
## Which questions one interview asks (GDD 5.8.2). GameState.start_interview picks them once and
## freezes them in the checkpoint, so a resume replays the same interview. Pure: the pools are
## parsed JSON (id -> entry), from Content.entries() in the game and from FileAccess in the tests.
## Tested by test_interview_plan (picking, the prompts and the dice a checkpoint replays, the VS plate).

## GDD S07: Dana's VS plate shows one joke stat and one special move (barks.json ids), in turn.
const VS_DANA_STATS: PackedStringArray = ["vs_dana_stat_1", "vs_dana_stat_2", "vs_dana_stat_3"]
const VS_DANA_MOVES: PackedStringArray = ["vs_dana_move_1", "vs_dana_move_2", "vs_dana_move_3"]


## GDD 5.8.2: the warm-up belongs to the first interview of the first run only.
static func warmup_due(run: RunState) -> bool:
	return run.first_run and run.interviews_taken == 0


## Dana's VS plate for this interview: {stat, move}, barks.json ids. Each list takes turns by how often
## you met her before (run.times_met_dana counts once an interview ends), without dice (INV-04), so a
## resumed interview shows the same lines.
static func vs_plate(run: RunState) -> Dictionary:
	return {
		"stat": VS_DANA_STATS[posmod(run.times_met_dana, VS_DANA_STATS.size())],
		"move": VS_DANA_MOVES[posmod(run.times_met_dana, VS_DANA_MOVES.size())],
	}


## Returns {question_ids, warmup_id}. question_ids holds one id per cfg.prompt_pattern slot, in prompt
## order. Only the tier's questions are used, never opener_only ones, and questions in `seen` only
## once the unseen ones run out (then the least recently seen first). The warm-up is one of the
## easiest remaining knowledge questions, or "" when with_warmup is false.
static func pick(cfg: BalanceConfig, tier_id: String, choice_pool: Dictionary, knowledge_pool: Dictionary,
		seen: Array[String], rng: RandomNumberGenerator, with_warmup: bool) -> Dictionary:
	var knowledge_ids := eligible(knowledge_pool, tier_id)
	var choice_picks := _draw(rng, eligible(choice_pool, tier_id), seen, cfg.prompt_pattern.count("choice"))
	var knowledge_picks := _draw(rng, knowledge_ids, seen, cfg.prompt_pattern.count("knowledge"))
	var picks: Dictionary = {"choice": choice_picks, "knowledge": knowledge_picks}
	var question_ids: Array[String] = []
	for kind: String in cfg.prompt_pattern:
		if not picks.has(kind):
			push_error("InterviewPlan: unknown prompt kind '%s' in prompt_pattern" % kind)
		elif not (picks[kind] as Array).is_empty():
			question_ids.append((picks[kind] as Array).pop_front())
	var warmup_id := ""
	if with_warmup:
		var remaining: Array[String] = []
		for id: String in knowledge_ids:
			if not question_ids.has(id):
				remaining.append(id)
		var warmup := _draw(rng, _easiest(knowledge_pool, remaining), seen, 1)
		if not warmup.is_empty():
			warmup_id = warmup[0]
	return {"question_ids": question_ids, "warmup_id": warmup_id}


## n ids from a pool with no tiers (the review's prompts, GDD 5.16): unseen ones in an order the RNG decides, then the
## least recently asked. The ids are sorted first, so the JSON key order never decides.
static func pick_ids(pool: Dictionary, seen: Array[String], rng: RandomNumberGenerator, n: int) -> Array[String]:
	var ids: Array[String] = []
	for id: String in pool:
		if not id.begins_with("_") and pool[id] is Dictionary:
			ids.append(id)
	ids.sort()
	return _draw(rng, ids, seen, n)


## The ids of one pool that a tier can ask, sorted so the picks never depend on the JSON key order.
static func eligible(pool: Dictionary, tier_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in pool:
		if id.begins_with("_") or not (pool[id] is Dictionary):  # "_" keys are metadata (ARCHITECTURE 6.3)
			continue
		var entry: Dictionary = pool[id]
		var tiers: Array = entry.get("tiers", [])
		if tiers.has(tier_id) and not bool(entry.get("opener_only", false)):
			ids.append(id)
	ids.sort()
	return ids


## The prompts a checkpoint plays, in order: one {kind, id} per question id, kind "choice" or
## "knowledge" (an old save's probe_line is never read: its knowledge prompt 2 is asked, DECISIONS D9).
static func prompts(question_ids: Array, choice_pool: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: Variant in question_ids:
		out.append({"kind": "choice" if choice_pool.has(str(id)) else "knowledge", "id": str(id)})
	return out


## The interview RNG (ARCHITECTURE 7.2): a fresh generator seeded from the checkpoint's seed, a
## String because 64-bit values don't survive JSON as numbers. The same seed replays the same dice.
static func interview_rng(seed_text: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_text.to_int()
	return rng


## A generator of its own for one Answer Meter (zone centre, pivot time, the pivot's new centre),
## seeded from exactly one roll of the interview RNG. The pivot rolls only if you tap after it, so
## on the interview RNG itself it would shift every later roll; this way a resume replays the later
## prompts' luck however early you tap (GDD 5.11).
static func meter_rng(interview: RandomNumberGenerator) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = interview.randi()
	return rng


## Moves each asked id to the end of `seen`, so `seen` stays ordered from least to most recently asked.
static func mark_seen(seen: Array[String], ids: Array) -> void:
	for id: String in ids:
		if id != "":
			seen.erase(id)
			seen.append(id)


## n ids: unseen ones in an order decided by the RNG, then (a dry pool) the least recently seen.
static func _draw(rng: RandomNumberGenerator, ids: Array[String], seen: Array[String], n: int) -> Array[String]:
	var fresh: Array[String] = []
	var stale: Array[String] = []
	for id: String in ids:
		if seen.has(id):
			stale.append(id)
		else:
			fresh.append(id)
	var out: Array[String] = []
	out.assign(Odds.pick(rng, fresh, n))
	if out.size() < n:
		stale.sort_custom(func(a: String, b: String) -> bool: return seen.find(a) < seen.find(b))
		out.append_array(stale.slice(0, n - out.size()))
	return out


static func _easiest(pool: Dictionary, ids: Array[String]) -> Array[String]:
	var lowest := -1
	for id: String in ids:
		var difficulty := int((pool[id] as Dictionary).get("difficulty", 0))
		if lowest < 0 or difficulty < lowest:
			lowest = difficulty
	var out: Array[String] = []
	for id: String in ids:
		if int((pool[id] as Dictionary).get("difficulty", 0)) == lowest:
			out.append(id)
	return out

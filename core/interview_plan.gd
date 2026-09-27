@tool
class_name InterviewPlan
extends RefCounted
## Which questions one interview asks (GDD 5.8.2). GameState.start_interview picks them once and
## freezes them in the checkpoint, so a resume replays the same interview. Pure: the pools are
## parsed JSON (id -> entry), from Content.entries() in the game and from FileAccess in the tests.
## Tested by test_interview_plan.


## GDD 5.8.2: the warm-up belongs to the first interview of the first run only.
static func warmup_due(run: RunState) -> bool:
	return run.first_run and run.interviews_taken == 0


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

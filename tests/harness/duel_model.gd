@tool
class_name DuelModel
extends RefCounted
## The harness's stand-ins for the two duels a bot can't play (DECISIONS A67, GDD 5.22). An interview is resolved
## with the duel's own formulas (Odds: knowledge P, the Stat Score, the meter's width, Q, the committee wheel) and a
## modeled tap error, as GDD 5.12's bot did; its questions come from the real pools. A review is
## WorkOdds.review_standin_left until M3 designs the review's prompts. Pure and headless: res:// files only, no
## autoloads, the caller's RNG.

const TAP_ERROR_MS := 75.0      # the Phase 1 bot's timing error (GDD 5.12), one standard deviation
const P_GOOD := 0.85            # ... and its ethics answers: good / neutral / bad
const P_NEUTRAL := 0.10
const BALANCE_PATH := "res://data/balance/balance_config.tres"
const KNOWLEDGE_PATH := "res://data/content/questions_knowledge.json"
const CHOICE_PATH := "res://data/content/questions_choice.json"
const NAMING_PATH := "res://data/content/naming.json"

var cfg: BalanceConfig
var gap_pool: Array = []
var _knowledge: Dictionary = {}   # tier id -> [{difficulty, tech, weak_for, topic}]
var _choice: Dictionary = {}      # tier id -> [{teamwork}]


static func load_default() -> DuelModel:
	var m := DuelModel.new()
	m.cfg = load(BALANCE_PATH) as BalanceConfig
	var k := _read(KNOWLEDGE_PATH)
	var c := _read(CHOICE_PATH)
	var naming := _read(NAMING_PATH)
	m.gap_pool = naming.get("_gap_topic_pool", [])
	for id: String in k:
		var q: Dictionary = k[id]
		for tier: String in q.get("tiers", []):
			if not m._knowledge.has(tier):
				m._knowledge[tier] = []
			(m._knowledge[tier] as Array).append({"difficulty": int(q["difficulty"]), "tech": String(q["kind"]) == "tech",
				"weak_for": String(q.get("weak_for", "none")), "topic": String(q.get("topic", ""))})
	for id: String in c:
		var q: Dictionary = c[id]
		if bool(q.get("opener_only", false)):
			continue
		for tier: String in q.get("tiers", []):
			if not m._choice.has(tier):
				m._choice[tier] = []
			(m._choice[tier] as Array).append({"teamwork": bool(q.get("teamwork", false))})
	return m


## The topics a background has gaps in, rolled once per run (GDD 5.2): the Self-Taught's two.
func roll_gap_topics(bg: BackgroundData, rng: RandomNumberGenerator) -> Array:
	return Odds.pick(rng, gap_pool, bg.gap_topics_count)


## One interview: returns {passed, doubt, composure, ko, wheel}. The request is Sim's duel request (the work
## state's Composure, meter width and Doubt); KNOWLEDGE, EXPERIENCE and NETWORK stay at the background's starting
## values (D-26).
func resolve_interview(req: Dictionary, bg: BackgroundData, tier: TierData, gap_topics: Array, rng: RandomNumberGenerator) -> Dictionary:
	var composure: float = req["composure"]
	var doubt: float = req["doubt_hp"]
	var doubt_max := doubt
	var zone_mult: float = req["meter_mult"]
	var choices: Array = _choice.get(String(tier.id), [])
	var knowledge: Array = (_knowledge.get(String(tier.id), []) as Array).duplicate()
	var lone_wolf := bg.teamwork_mult < bg.teamwork_mult_after_network
	for prompt: String in cfg.prompt_pattern:
		if prompt == "choice":
			var q: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
			var roll := rng.randf()
			var kind: StringName = &"good" if roll < P_GOOD else (&"neutral" if roll < P_GOOD + P_NEUTRAL else &"bad")
			doubt += Odds.ethics_doubt_delta(cfg, kind, bool(q["teamwork"]), Odds.teamwork_mult(bg, lone_wolf))
			composure -= Odds.ethics_composure_loss(cfg, kind)
		else:
			var idx := rng.randi_range(0, knowledge.size() - 1)
			var q: Dictionary = knowledge[idx]
			knowledge.remove_at(idx)
			var weak: bool = String(q["weak_for"]) == String(bg.id) or gap_topics.has(q["topic"])
			var p := Odds.knowledge_p(cfg, tier, bg, bg.start_knw, bg.start_exp, bool(q["tech"]), weak)
			var s := Odds.stat_score(cfg, tier, p, int(q["difficulty"]), Odds.roll_luck(cfg, rng))
			var h := maxf(cfg.zone_half_base, Odds.zone_half(cfg, s) * zone_mult)
			var miss := absf(rng.randfn(0.0, TAP_ERROR_MS)) / 1000.0 * tier.needle_speed
			var qv := Odds.answer_q(cfg, s, Odds.input_quality(cfg, miss, 0.0, h))
			doubt += Odds.knowledge_doubt_delta(cfg, qv)
			composure -= Odds.knowledge_composure_loss(cfg, qv)
		if doubt <= 0.0:
			return {"passed": true, "doubt": 0.0, "composure": composure, "ko": true, "wheel": false}
		if composure <= 0.0:
			return {"passed": false, "doubt": doubt, "composure": 0.0, "ko": false, "wheel": false}
	if Odds.committee_eligible(cfg, doubt, doubt_max):
		var wins := rng.randf() < Odds.committee_win_p(cfg, doubt, doubt_max, bg.start_net)
		return {"passed": wins, "doubt": doubt, "composure": composure, "ko": false, "wheel": true}
	return {"passed": false, "doubt": doubt, "composure": composure, "ko": false, "wheel": false}


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

@tool
class_name DuelAdapter
extends RefCounted
## The adapter between the career run's sim and the shipped duel and contract screens (GDD 5.20, ARCHITECTURE 19.5,
## R-JOB-06; DECISIONS A88, A89). The sim asks for an interview, a review or an answer to an offer through its queue;
## this class turns that queue item into plain data the Phase 1 screens already know how to play (the interview
## checkpoint, the contract paper) and turns what they report into the sim's inputs. Pure, like Sim: no nodes, no
## autoloads, and no draw from the sim's stream. Everything it rolls comes from local generators seeded from the run
## seed, the application (or the day) and the duel's index, so Continue replays the same questions and the same luck.
##
## Request and result shapes (plain dictionaries, INV-07; the field names are the sim's own):
##   DuelRequest  {composure, meter_mult, doubt_hp, floor, archetype, tier, unlocked_options, rounds}   (Sim._start_duel)
##   DuelResult   {passed, composure_left}
##   OfferRequest the posting {id, company, archetype, level, floor, salary, remote, clauses, posted} (the `offer` item)
##   OfferResult  {decision, final_salary, clauses}

const KIND_INTERVIEW := "interview"
const KIND_REVIEW := "review"
const GREET_FIRST := "first"                # the tier's greeting, then the background's opener
const GREET_AGAIN := "again"                # "Didn't I interview you at {last_company}?"
const GREET_AFTER_LAYOFF := "after_layoff"  # Dana laid you off, then met you again at the next company

const SALT_PICK := 7919
const SALT_INTERVIEW := 104729
const SALT_REVIEW := 1299709
const SALT_REVIEW_PICK := 15485863
const SALT_OFFER := 32452843
const OFFER_PERKS := 1                      # Phase 1's paper lists two perks; the career's adds a Clauses field and keeps to 20 lines
const ONSITE_DAYS := 5                      # a non-remote startup posting is in the office all week
const REMOTE_MODE := "offer_mode_remote"
const ONSITE_MODE := "offer_mode_onsite"
const MANAGER_AUTHORED := "cw_kev"          # run 1's manager (GDD 5.18)


## A seed as a String (64-bit values do not survive JSON as numbers: INV-05), the same for the same inputs.
static func seed_text(run_seed: int, salt: int, a: int, b: int) -> String:
	return str(("%d|%d|%d|%d" % [run_seed, salt, a, b]).hash())


# ---------- the interview ----------

## The interview checkpoint for the sim's `duel` queue item {app, index, of, request}, in the shape Phase 1's
## interview resumes from (RunState.interview) plus the career's numbers. history: {seen: Array[String], first_run,
## met (interviews finished), last_company, after_layoff}. The caller marks the picked ids as seen.
static func interview_checkpoint(item: Dictionary, posting: Dictionary, run_seed: int, ctx: SimContext, history: Dictionary) -> Dictionary:
	var request: Dictionary = item["request"]
	var app := int(item["app"])
	var index := int(item["index"])
	var tier_id := String(request["tier"])
	var seen: Array[String] = []
	seen.assign(history.get("seen", []))
	var first_run := bool(history.get("first_run", false))
	var met := int(history.get("met", 0))
	var with_warmup := first_run and met == 0     # InterviewPlan.warmup_due: the first interview of the first run
	var pick_rng := InterviewPlan.interview_rng(seed_text(run_seed, SALT_PICK, app, index))
	var plan := InterviewPlan.pick(ctx.balance, tier_id, ctx.content.get("questions_choice", {}),
		ctx.content.get("questions_knowledge", {}), seen, pick_rng, with_warmup)
	var greet := GREET_FIRST
	if bool(history.get("after_layoff", false)):
		greet = GREET_AFTER_LAYOFF
	elif met > 0 and not String(history.get("last_company", "")).is_empty():
		greet = GREET_AGAIN
	return {
		"kind": KIND_INTERVIEW, "invite_uid": -1, "company_id": String(posting["company"]), "template_id": "", "tier": tier_id,
		"seed": seed_text(run_seed, SALT_INTERVIEW, app, index), "tired": false,
		"question_ids": plan["question_ids"], "warmup_id": plan["warmup_id"],
		"composure": float(request["composure"]), "doubt_hp": float(request["doubt_hp"]), "meter_mult": float(request["meter_mult"]),
		"rounds": (plan["question_ids"] as Array).size(), "unlocked_options": (request.get("unlocked_options", []) as Array).duplicate(),
		"floor": int(request["floor"]), "archetype": String(request["archetype"]),
		"app": app, "index": index, "of": int(item["of"]),
		"greet": greet, "last_company": String(history.get("last_company", "")),
	}


## What the interview starts with. A Phase 1 checkpoint has none of the career's fields, so every number falls back to the
## .tres files it always read (tier.doubt_hp, bg.composure_max, a meter multiplier of 1): a hunt save still plays.
static func start_values(iv: Dictionary, tier: TierData, bg: BackgroundData) -> Dictionary:
	return {
		"composure": float(iv.get("composure", bg.composure_max)),
		"doubt": float(iv.get("doubt_hp", tier.doubt_hp)),
		"zone_mult": float(iv.get("meter_mult", 1.0)),
	}


## The Answer Meter's half-width: the stat score's NAILED IT width (plus the Graduate's textbook bonus) times the work
## state's multiplier (Skill widens it, Rust narrows it), never below the 0.06 floor (RC-25, GDD 5.20). S is untouched.
static func half_width(cfg: BalanceConfig, s: float, bonus: float, zone_mult: float) -> float:
	return maxf(cfg.zone_half_base, Odds.zone_half(cfg, s, bonus) * zone_mult)


# ---------- the review ----------

## The review checkpoint for the sim's `review` queue item {evidence, calibration}: three prompts from the review pool,
## the manager's name, and the two HP pools. `seen` is the review prompts asked before (least recently first).
static func review_checkpoint(item: Dictionary, s: SimState, ctx: SimContext, seen: Array) -> Dictionary:
	var arch := ctx.archetype(s.job_archetype)
	var seen_ids: Array[String] = []
	seen_ids.assign(seen)
	var pick_rng := InterviewPlan.interview_rng(seed_text(s.rng_seed, SALT_REVIEW_PICK, s.day, s.jobs_held))
	var ids := InterviewPlan.pick_ids(ctx.content.get("questions_review", {}), seen_ids, pick_rng, ctx.cfg.review_prompts)
	return {
		"kind": KIND_REVIEW, "invite_uid": -1, "company_id": s.job_company, "template_id": "", "tier": String(arch.duel_tier),
		"seed": seed_text(s.rng_seed, SALT_REVIEW, s.day, s.jobs_held), "tired": false,
		"question_ids": ids, "warmup_id": "", "rounds": ids.size(), "archetype": String(arch.id),
		"evidence": float(item["evidence"]), "calibration": float(item["calibration"]),
		"manager": manager_name(s, ctx),
		"hits": {
			"good": WorkOdds.review_hit(ctx.cfg, float(item["calibration"]), "good"),
			"neutral": WorkOdds.review_hit(ctx.cfg, float(item["calibration"]), "neutral"),
			"bad": WorkOdds.review_hit(ctx.cfg, float(item["calibration"]), "bad"),
		},
	}


## Your manager: Kev at Hierarchai (run 1's authored crew), else a name from the pool, the same for the whole job.
static func manager_name(s: SimState, ctx: SimContext) -> String:
	for cw: Dictionary in s.coworkers:
		if String(cw.get("id", "")) == MANAGER_AUTHORED:
			return String(cw.get("name", ""))
	var pool := ctx.coworker_pool
	if pool.is_empty():
		return ""
	return pool[posmod(("%d|%d" % [s.rng_seed, s.jobs_held]).hash(), pool.size())]


# ---------- the contract ----------

## The contract paper for an offer: the same shape RunState.make_offer builds for Phase 1's offer screen (ids into
## emails.json for every text, the posting's title as raw text, plain data), plus the posting's clauses and its level.
## The salary is the yearly figure (GDD 5.20, MC-10): the sim's is a month's pay in k$. The perks, the hidden clause
## (a fine-print joke from the duel tier's pool, revealed here) and the title come from the offer's own generator.
static func offer_paper(posting: Dictionary, ctx: SimContext, run_seed: int) -> Dictionary:
	var emails: Dictionary = ctx.content.get("emails", {})
	var arch := ctx.archetype(String(posting["archetype"]))
	var tier_id := String(arch.duel_tier)
	var tier := ctx.tiers.get(tier_id) as TierData
	var remote := bool(posting.get("remote", false))
	var office_days := 0
	if not remote:
		office_days = ONSITE_DAYS if tier_id == RunState.EQUITY_TIER else tier.office_days
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_text(run_seed, SALT_OFFER, int(posting["id"]), 0).to_int()
	var perks := Odds.pick(rng, _ids_with_prefix(emails, "perk_", tier_id), OFFER_PERKS)
	var fine_print := Odds.pick(rng, RunState.fine_print_pool(emails, tier_id, perks), 1)
	var level_title := String(emails.get("title_" + WorkOdds.LEVELS[int(posting["level"])], ""))
	return {
		"company_id": String(posting["company"]), "template_id": "", "tier": tier_id, "archetype": String(arch.id),
		"level": int(posting["level"]), "floor": int(posting.get("floor", 1)),
		"job_title": level_title + String(emails.get("title_suffix_" + String(arch.id), "")),
		"salary": WorkOdds.yearly_salary(ctx.cfg, float(posting["salary"])),
		"work_mode": REMOTE_MODE if remote else _mode_id(tier_id, office_days), "office_days": office_days,
		"commute": RunState.offer_commute(office_days, ctx.bg.commute_minutes),
		"perks": perks, "fine_print": str(fine_print[0]) if not fine_print.is_empty() else "",
		"clauses": (posting.get("clauses", []) as Array).duplicate(), "remote": remote,
		"equity_text": "offer_equity" if tier_id == RunState.EQUITY_TIER else "",
	}


static func _mode_id(tier_id: String, office_days: int) -> String:
	if office_days >= ONSITE_DAYS:
		return ONSITE_MODE
	return "offer_mode_" + tier_id


## The sorted ids starting with prefix whose "tiers" list this tier (perk_*, fp_* in emails.json).
static func _ids_with_prefix(emails: Dictionary, prefix: String, tier_id: String) -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in emails:
		var id := str(key)
		if id.begins_with(prefix) and emails[key] is Dictionary and ((emails[key] as Dictionary).get("tiers", []) as Array).has(tier_id):
			ids.append(id)
	ids.sort()
	return ids


# ---------- what the screens report, as the sim's inputs ----------

static func duel_result_input(passed: bool, composure_left: float) -> Dictionary:
	return {"kind": Sim.IN_DUEL_RESULT, "passed": passed, "composure_left": composure_left}


static func review_result_input(evidence_left: float) -> Dictionary:
	return {"kind": Sim.IN_REVIEW_RESULT, "evidence_left": evidence_left}


static func offer_input(accept: bool) -> Dictionary:
	return {"kind": Sim.IN_ANSWER_OFFER, "accept": accept}


## The OfferResult of GDD 5.20: no negotiation (D-27), so the final salary is the offered one.
static func offer_result(accept: bool, paper: Dictionary) -> Dictionary:
	return {"decision": "accept" if accept else "decline", "final_salary": int(paper.get("salary", 0)),
		"clauses": (paper.get("clauses", []) as Array).duplicate()}

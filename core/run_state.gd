@tool
class_name RunState
extends RefCounted
## One playthrough (GDD 10.4). EVERY `var` below is saved to JSON automatically by to_dict(),
## so only plain data lives here: String / int / float / bool, Array, Dictionary. Ids are Strings.
## Never store a Resource, a Node or a StringName here.
## Rule methods (spend_energy, sleep, ...) change this object. They never touch autoloads, scenes
## or the global RNG: they take cfg / tier / bg / rng as arguments, so tests and the balance sim
## can run them inside the editor.

const VERSION := 1
## Job hunt ids (GDD 5.0). The board deals round-robin in TIER_IDS order.
const TIER_IDS: PackedStringArray = ["startup", "mid", "big"]
const CV_LINES: PackedStringArray = ["edu", "exp", "proj"]
const GUARANTEE_DAY := 2              # the first-run guarantee: day-1 applications, the morning of day 2
const REJECT_MAIL_PREFIX := "mail_reject_"   # emails.json: the plain rejection lines
const OFFER_PERKS := 2                # GDD 5.9, S10: every offer lists 2 perks and 1 fine-print joke
const EQUITY_TIER := "startup"        # GDD 7: only startups add the joke equity to the salary
const OFFER_SEED_SALT := "|offer"     # offer_rng(): the interview seed plus this names the offer's dice

# --- flow and RNG ---
var phase: GameFlow.Phase = GameFlow.Phase.TITLE
var rng_seed: String = "0"            # 64-bit RNG values travel as strings (JSON numbers are doubles)
var rng_state: String = "0"
var first_run: bool = true            # the day-2 guarantee (GDD 5.7) only applies to the first run

# --- character (Phase 2 takes this person to work) ---
var background_id: String = ""
var player_name: String = "Alex"
var stats: Dictionary[String, int] = {"knw": 0, "exp": 0, "net": 0}
var lone_wolf: bool = false           # Self-Taught until the first Network (SHOULD)
var gap_topics: Array[String] = []
var commute_pips: int = 0
var commute_minutes: int = 0

# --- day loop ---
var day: int = 1
var energy: int = 0
var rent_days_left: int = 0
var grace_used: bool = false
var referral_tokens: int = 0
var pity_count: int = 0               # Recruiter Radar
var interviews_today: int = 0
var next_uid: int = 1
var board: Array[Dictionary] = []         # the deck, top card first: {uid, template_id, company_id, tier, posted_days_ago, applicants, is_ghost, reposted}
# applications, in send order: {uid (= the card's), template_id, company_id, tier, day_sent, reveal_day, p, hits,
#   relevant, knockout, knockout_reason {id, args}, is_ghost, referral, tailored, status}
#   status: pending -> invited | rejected | silent (-> ghosted); invited -> interview | expired
var applications: Array[Dictionary] = []
var applied: Array[String] = []           # "template_id|company_id": never dealt again this run
var dropped: Array[String] = []           # "template_id|company_id" pairs that fell off the board unapplied: they return "reposted"
# invites waiting in Mail: {uid, app_uid, company_id, template_id, tier, day_received, kind, mail_id}
#   kind: rolled | radar | guarantee | profile (the guarantee's "saw your profile!" from a board card)
var invites: Array[Dictionary] = []
var morning_report: Dictionary = {}       # built by Sleep; the hunt scene shows it, "Start day" clears it
var day_mail: Dictionary = {}             # the morning report after "Start day": Mail keeps showing it until the next Sleep
var tips_shown: Array[String] = []        # tip ids a once-per-run trigger already showed (HuntTips, GDD 8.3)
var coach_closed: Array[String] = []      # first-run coach marks tapped closed: never shown again this run (HuntTips.coach)
var blacklist: Array[String] = []         # company ids whose offer you declined
var researched: Array[String] = []        # company ids (SHOULD)
var seen_question_ids: Array[String] = []

# --- interview checkpoint: a resume replays exactly this interview (GDD 5.11) ---
var interview: Dictionary = {}        # {invite_uid, company_id, template_id, tier, seed, question_ids, warmup_id, tired}
var interviews_taken: int = 0
var times_met_dana: int = 0
var dana_last_company: String = ""

# --- offer, job, result ---
# the offer on the table (make_offer): {company_id, template_id, tier, job_title, salary, work_mode, office_days,
#   commute {id, args}, perks [ids], fine_print, equity_text}; texts are emails.json ids, job_title the posting's title
var offer: Dictionary = {}
var employment: Dictionary = {}       # the accepted offer + red_flags (hire(); Phase 2 reads this)
var dream_score: int = -1
var total_applications: int = 0
var total_rejections: int = 0


# ---------- rule methods (examples; more arrive with each feature) ----------

func stat(id: String) -> int:
	return stats.get(id, 0)


func spend_energy(pips: int) -> bool:
	if pips > energy:
		return false
	energy -= pips
	return true


func new_uid() -> int:
	next_uid += 1
	return next_uid - 1


## A new run's starting numbers from its background (GDD 5.2). GameState adds the name, the seed,
## the gap topics and first_run, then deals the day-1 board.
func set_background(cfg: BalanceConfig, bg: BackgroundData) -> void:
	background_id = String(bg.id)
	stats.assign({"knw": bg.start_knw, "exp": bg.start_exp, "net": bg.start_net})
	commute_pips = bg.commute_pips
	commute_minutes = bg.commute_minutes
	energy = cfg.energy_max - bg.commute_pips
	rent_days_left = bg.runway_days
	referral_tokens = bg.referral_tokens
	lone_wolf = bg.teamwork_mult < bg.teamwork_mult_after_network


# ---------- job hunt (GDD 5.6-5.10). Every rule takes its data as arguments: ----------
# cfg: BalanceConfig; tiers: {"startup": TierData, "mid": ..., "big": ...};
# bg: this run's BackgroundData; rng: the run RNG;
# content: {"postings": ..., "companies": ..., "cv_lines": ...}, the parsed JSON files keyed by file name.

## "template_id|company_id": one card identity, as stored in applied and dropped.
static func pair_key(template_id: String, company_id: String) -> String:
	return template_id + "|" + company_id


## The morning deal (GDD 5.6): cfg.board_new_per_day cards, round-robin over the tiers (6 = 2 per
## tier), put on top of the deck. Blacklisted companies leave the board first; then the oldest cards
## drop off down to cfg.board_max. Returns how many cards were dealt.
func deal_board(cfg: BalanceConfig, tiers: Dictionary, content: Dictionary, rng: RandomNumberGenerator) -> int:
	var postings := _file(content, "postings")
	var companies := _file(content, "companies")
	for i: int in range(board.size() - 1, -1, -1):
		if blacklist.has(str(board[i]["company_id"])):
			board.remove_at(i)
	var tier_ids: Array[String] = []
	for id: String in TIER_IDS:
		if _tier(tiers, id) != null:
			tier_ids.append(id)
	if tier_ids.is_empty():
		return 0
	var dealt: Array[Dictionary] = []
	for i: int in cfg.board_new_per_day:
		var card := _deal_card(cfg, _tier(tiers, tier_ids[i % tier_ids.size()]), postings, companies, dealt, rng)
		if not card.is_empty():
			dealt.append(card)
	var dealt_count := dealt.size()
	dealt.append_array(board)
	board = dealt
	while board.size() > cfg.board_max:
		_drop_oldest()
	return dealt_count


## A declined offer (GDD 5.7): the company is blacklisted for the run. Its cards leave the board at
## once (not only at the next morning's deal), its waiting invites are withdrawn without a mail (their
## applications end "expired"), and its pending applications reveal as silent (_reveal_outcomes).
func blacklist_company(company_id: String) -> void:
	if not blacklist.has(company_id):
		blacklist.append(company_id)
	for i: int in range(board.size() - 1, -1, -1):
		if str(board[i]["company_id"]) == company_id:
			board.remove_at(i)
	for i: int in range(invites.size() - 1, -1, -1):
		if str(invites[i]["company_id"]) != company_id:
			continue
		var app := _application(int(invites[i]["app_uid"]))
		if not app.is_empty():
			app["status"] = "expired"
		invites.remove_at(i)


## Swipe left: the card goes to the back of the deck.
func skip_card(card_uid: int) -> bool:
	var i := _card_index(card_uid)
	if i < 0:
		return false
	board.append(board.pop_at(i))
	return true


## The CV lines actually sent (GDD 5.4): your background's true CV. Quick Apply sends every line
## Honest; Tailor & Apply sends every line as its Polished version (honest reframing) for that one
## application. Returns {line_ids, tags (the union), degree, passes_years}.
func cv_sent(cv_lines: Dictionary, tailored: bool) -> Dictionary:
	var level := "polished" if tailored else "honest"
	var line_ids: Array[String] = []
	var tags: Array[String] = []
	var degree := false
	var passes_years := false
	for line: String in CV_LINES:
		var id := _cv_line_id(cv_lines, line, level)
		if id.is_empty():
			continue
		var entry: Dictionary = cv_lines[id]
		line_ids.append(id)
		for tag: Variant in entry.get("tags", []):
			if not tags.has(str(tag)):
				tags.append(str(tag))
		degree = degree or bool(entry.get("degree", false))
		passes_years = passes_years or bool(entry.get("passes_years", false))
	return {"line_ids": line_ids, "tags": tags, "degree": degree, "passes_years": passes_years}


## What a card shows (GDD S04): its 3 tags checked against your honest CV ({tag, hit}), and for each
## way to apply ("quick", "tailored", "referral" = tailored + a token) {p, band, hits, relevant,
## knockout}. knockout is the red chip: {id, args} into postings.json ("card_knockout" wraps
## it), or {} for none. Ghost risk is never included. {} if the card's data is missing.
func card_odds(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary, card: Dictionary) -> Dictionary:
	var tier := _tier(tiers, str(card.get("tier", "")))
	var posting := _posting(content, str(card.get("template_id", "")))
	if tier == null or posting.is_empty():
		return {}
	var cv := _file(content, "cv_lines")
	var honest: Array = cv_sent(cv, false)["tags"]
	var tag_rows: Array[Dictionary] = []
	for tag: Variant in posting.get("tags", []):
		tag_rows.append({"tag": str(tag), "hit": honest.has(str(tag))})
	return {
		"tags": tag_rows,
		"quick": _quote(cfg, tier, bg, posting, cv, false, false),
		"tailored": _quote(cfg, tier, bg, posting, cv, true, false),
		"referral": _quote(cfg, tier, bg, posting, cv, true, true),
	}


## Quick Apply (tailored = false) or Tailor & Apply (tailored = true), optionally with a referral
## token (GDD 5.3, 5.6). Pays the energy, freezes P_invite with today's stats and schedules the
## reply. The outcome is NOT rolled now: the reveal morning rolls it (GDD 5.7).
## Returns the new application, or {} when the card is gone, its company is blacklisted or it
## can't be paid for.
func apply_card(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary, card_uid: int, tailored: bool, referral: bool) -> Dictionary:
	var i := _card_index(card_uid)
	if i < 0 or blacklist.has(str(board[i]["company_id"])):
		return {}
	var card: Dictionary = board[i]
	var tier := _tier(tiers, str(card["tier"]))
	var posting := _posting(content, str(card["template_id"]))
	if tier == null or posting.is_empty() or (referral and referral_tokens <= 0):
		return {}
	if not spend_energy(cfg.cost_tailor_apply if tailored else cfg.cost_quick_apply):
		return {}
	if referral:
		referral_tokens -= 1
	var quote := _quote(cfg, tier, bg, posting, _file(content, "cv_lines"), tailored, referral)
	var knockout: Dictionary = quote["knockout"]
	var app := {
		"uid": card["uid"], "template_id": card["template_id"], "company_id": card["company_id"],
		"tier": card["tier"], "day_sent": day,
		"reveal_day": Odds.reply_day(cfg, tier, day, not knockout.is_empty()),
		"p": _frozen_p(quote["p"]), "hits": quote["hits"], "relevant": quote["relevant"],
		"knockout": not knockout.is_empty(), "knockout_reason": knockout,
		"is_ghost": card["is_ghost"], "referral": referral, "tailored": tailored, "status": "pending",
	}
	applications.append(app)
	applied.append(pair_key(str(card["template_id"]), str(card["company_id"])))
	board.remove_at(i)
	total_applications += 1
	return app


## Sleep: ONE committed action (ARCHITECTURE 7.1). The night tick, then the whole morning: expired
## invites, the reveal in send order, ghosting, the board refill, the day-2 guarantee and the rent
## check (GDD 5.3, 5.6, 5.7, 5.10). The result is written to morning_report and returned:
##   day, night {applied, rejected, ghosted, rent_days_left} (the lock-screen summary),
##   invites [invite] (inbox first), rejections [{app_uid, company_id, template_id, tier, knockout, mail_id}]
##   in send order (knockout {id, args} names it; mail_id "mail_knockout", or for a plain rejection the
##   mail_reject_* line reject_mail_id() picks, "" without emails.json),
##   no_reply (silent and ghost-job reveals), ghosted [{app_uid, company_id, template_id, tier, days}],
##   expired [{invite_uid, app_uid, company_id, template_id, tier, mail_id}] ("filled internally"),
##   radar {before, after, max}, guarantee ("", "guarantee" or "profile"), board_new,
##   grace_day, plan_b (GameState ends the run after the inbox), rent_days_left.
## Called with cfg alone (the Step 1 form) it only runs the night tick and returns {}.
func sleep(cfg: BalanceConfig, tiers: Dictionary = {}, bg: BackgroundData = null, content: Dictionary = {}, rng: RandomNumberGenerator = null) -> Dictionary:
	var applied_today := 0
	for app: Dictionary in applications:
		if int(app["day_sent"]) == day:
			applied_today += 1
	day += 1
	rent_days_left = maxi(rent_days_left - 1, 0)
	energy = cfg.energy_max - commute_pips
	interviews_today = 0
	day_mail = {}
	for card: Dictionary in board:
		card["posted_days_ago"] = int(card["posted_days_ago"]) + 1
	if tiers.is_empty() or bg == null or rng == null:
		return {}
	morning_report = _morning(cfg, tiers, bg, content, rng, applied_today)
	return morning_report


## Mail "Start day": the morning has been seen and the report is cleared. It moves to day_mail, so
## Mail still shows the day's mail (expiry notices, rejections, the grace-day line) until the next Sleep.
## Returns true when this morning ended the run (GameState then calls end_run_plan_b()).
func start_day() -> bool:
	var plan_b := bool(morning_report.get("plan_b", false))
	day_mail = morning_report
	morning_report = {}
	return plan_b


## Mail "GO NOW": the invite leaves the inbox and its application is marked "interview".
## Returns the invite, or {} if it isn't waiting (GameState pays and checks the day's limit first).
func take_invite(invite_uid: int) -> Dictionary:
	for i: int in invites.size():
		if int(invites[i]["uid"]) == invite_uid:
			var invite: Dictionary = invites.pop_at(i)
			var app := _application(int(invite["app_uid"]))
			if not app.is_empty():
				app["status"] = "interview"
			return invite
	return {}


## GDD 5.9, S10: the whole offer, built by GameState.finish_interview from the interview checkpoint
## (so call it before the checkpoint is cleared). Plain data only (INV-07): the numbers, the posting's
## title (the raw JSON text; the screen tr()s it) and emails.json ids for every other text, so the
## paper can be drawn again after a resume. The perks and the fine print are picked on offer_rng(),
## seeded from the checkpoint's seed: a replayed interview builds the same contract, and neither the
## run RNG nor the global RNG moves. Returns a copy of the new offer.
func make_offer(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, content: Dictionary, composure_left: float) -> Dictionary:
	var tier_id := String(tier.id)
	var template_id := str(interview.get("template_id", ""))
	var emails := _file(content, "emails")
	var rng := offer_rng(str(interview.get("seed", "")))
	var perks := Odds.pick(rng, _tier_entries(emails, "perk_", tier_id), OFFER_PERKS)
	var fine_print := Odds.pick(rng, fine_print_pool(emails, tier_id, perks), 1)
	offer = {
		"company_id": str(interview.get("company_id", "")), "template_id": template_id, "tier": tier_id,
		"job_title": str(_posting(content, template_id).get("title", "")),
		"salary": Odds.offer_salary(cfg, tier, bg, composure_left, bg.composure_max),
		"work_mode": "offer_mode_" + tier_id, "office_days": tier.office_days,
		"commute": offer_commute(tier.office_days, commute_minutes),
		"perks": perks, "fine_print": str(fine_print[0]) if not fine_print.is_empty() else "",
		"equity_text": "offer_equity" if tier_id == EQUITY_TIER else "",
	}
	return offer.duplicate(true)


## The offer's own dice (ARCHITECTURE 7.2): a generator seeded from the interview checkpoint's seed
## (a String) and a salt, so it never replays the interview's own rolls.
static func offer_rng(interview_seed: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = (interview_seed + OFFER_SEED_SALT).hash()
	return rng


## The contract's commute line (GDD S10) as {id, args} into emails.json: no office days is the remote
## line; otherwise days x minutes each way and the weekly hours (GDD 5.9.5), one decimal: "12.7".
static func offer_commute(office_days: int, minutes_each_way: int) -> Dictionary:
	if office_days <= 0:
		return {"id": "offer_commute_remote", "args": {}}
	var hours := office_days * 2.0 * minutes_each_way / 60.0
	return {"id": "offer_commute_office",
		"args": {"office_days": office_days, "commute_min": minutes_each_way, "hours": "%.1f" % hours}}


## GDD 5.9.4-5.9.5, Accept: the offer becomes the job, with its
## company's red flags (GDD 10.4; company_red_flags is that company's companies.json list), and is
## scored Dream vs Reality with the rent days left today. The offer stays as it was.
func hire(cfg: BalanceConfig, bg: BackgroundData, company_red_flags: Array) -> void:
	employment = offer.duplicate(true)
	employment["red_flags"] = company_red_flags.duplicate()
	dream_score = Odds.dream_score(cfg, int(employment.get("salary", 0)), int(employment.get("office_days", 0)),
		commute_minutes, company_red_flags.size(), rent_days_left, bg.runway_days)


## The Hired card's five rows (Odds.dream_breakdown) for the job taken, from the numbers hire() scored:
## their rounded sum is dream_score.
func dream_breakdown(cfg: BalanceConfig, bg: BackgroundData) -> Array[float]:
	return Odds.dream_breakdown(cfg, int(employment.get("salary", 0)), int(employment.get("office_days", 0)),
		commute_minutes, (employment.get("red_flags", []) as Array).size(), rent_days_left, bg.runway_days)


## GDD 5.10: Decline on the grace day (0 rent days: the only way an offer is open with no rent left)
## is Plan B, not back to the hunt. The offer screen asks with the matching question.
func decline_ends_run() -> bool:
	return rent_days_left <= 0


## A plain rejection's email (GDD S06), picked without dice: the application uid chooses one of the
## mail_reject_* lines (sorted ids), so a resume or a replayed Sleep shows the same line.
## "" when the content has no emails.
static func reject_mail_id(content: Dictionary, app_uid: int) -> String:
	var ids: Array[String] = []
	for key: Variant in _file(content, "emails"):
		if str(key).begins_with(REJECT_MAIL_PREFIX):
			ids.append(str(key))
	if ids.is_empty():
		return ""
	ids.sort()
	return ids[posmod(app_uid, ids.size())]


# ---------- job hunt internals ----------

func _morning(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary, rng: RandomNumberGenerator, applied_today: int) -> Dictionary:
	var report := {
		"day": day, "night": {}, "invites": [], "rejections": [], "no_reply": 0, "ghosted": [],
		"expired": [], "radar": {"before": pity_count, "after": pity_count, "max": bg.pity_n},
		"guarantee": "", "board_new": 0, "grace_day": false, "plan_b": false, "rent_days_left": rent_days_left,
	}
	_expire_invites(cfg, report)
	var outcomes := _reveal_outcomes(tiers, bg, rng)
	var guarantee_due := _guarantee_due(cfg, outcomes)
	if guarantee_due:
		var best := _best_day1_application()
		if not best.is_empty():
			_set_outcome(outcomes, best, "guarantee")
			report["guarantee"] = "guarantee"
			pity_count = 0
	_apply_outcomes(outcomes, report, content)
	_ghost_silent(cfg, report)
	report["board_new"] = deal_board(cfg, tiers, content, rng)
	if guarantee_due and report["guarantee"] == "":
		var invite := _profile_invite(cfg, tiers, bg, content)
		if not invite.is_empty():
			(report["invites"] as Array).append(invite)
			report["guarantee"] = "profile"
			pity_count = 0
	(report["radar"] as Dictionary)["after"] = pity_count
	var rent := Odds.rent_check(cfg, rent_days_left, grace_used, not invites.is_empty())
	if rent == "grace":
		grace_used = true
	report["grace_day"] = rent == "grace"
	report["plan_b"] = rent == "plan_b"
	report["night"] = {
		"applied": applied_today, "rejected": (report["rejections"] as Array).size(),
		"ghosted": (report["ghosted"] as Array).size(), "rent_days_left": rent_days_left,
	}
	return report


func _expire_invites(cfg: BalanceConfig, report: Dictionary) -> void:
	var expired: Array = report["expired"]
	for i: int in range(invites.size() - 1, -1, -1):
		var invite: Dictionary = invites[i]
		if not Odds.invite_expired(cfg, int(invite["day_received"]), day):
			continue
		invites.remove_at(i)
		var app := _application(int(invite["app_uid"]))
		if not app.is_empty():
			app["status"] = "expired"
		expired.push_front({
			"invite_uid": invite["uid"], "app_uid": invite["app_uid"], "company_id": invite["company_id"],
			"template_id": invite["template_id"], "tier": invite["tier"], "mail_id": "mail_invite_expired",
		})


## GDD 5.7 steps 1-4 for each application due this morning, in send order (applications are appended
## as they are sent). The Radar moves as each one resolves. Statuses change later, in _apply_outcomes.
## A blacklisted company never answers: its applications reveal as silent, without dice.
func _reveal_outcomes(tiers: Dictionary, bg: BackgroundData, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var outcomes: Array[Dictionary] = []
	for app: Dictionary in applications:
		if app["status"] != "pending" or int(app["reveal_day"]) > day:
			continue
		var tier := _tier(tiers, str(app["tier"]))
		if tier == null:
			continue
		var outcome := "silent"
		if not blacklist.has(str(app["company_id"])):
			outcome = Odds.reveal_outcome(tier, bg, app, pity_count, rng)
		# A knockout failure never fills the Radar, even when a blacklist turned it silent.
		var counts := bool(app["relevant"]) and not bool(app["knockout"])
		pity_count = Odds.pity_after(bg, pity_count, outcome, counts)
		outcomes.append({"app": app, "outcome": outcome})
	return outcomes


## First run, the morning of day 2, at least day2_guarantee_min_apps sent on day 1, no invite yet.
func _guarantee_due(cfg: BalanceConfig, outcomes: Array[Dictionary]) -> bool:
	if not first_run or day != GUARANTEE_DAY:
		return false
	for o: Dictionary in outcomes:
		if o["outcome"] in ["invite", "radar"]:
			return false
	var sent_day1 := 0
	for app: Dictionary in applications:
		if int(app["day_sent"]) == GUARANTEE_DAY - 1:
			sent_day1 += 1
	return sent_day1 >= cfg.day2_guarantee_min_apps


## The best eligible day-1 application: highest P, not a ghost job, not knocked out, not to a
## blacklisted company, not resolved before this morning (this morning's reveals are still "pending"
## here). Ties go to the first sent.
func _best_day1_application() -> Dictionary:
	var best: Dictionary = {}
	for app: Dictionary in applications:
		if int(app["day_sent"]) != GUARANTEE_DAY - 1 or app["status"] != "pending":
			continue
		if bool(app["knockout"]) or bool(app["is_ghost"]) or blacklist.has(str(app["company_id"])):
			continue
		if best.is_empty() or float(app["p"]) > float(best["p"]):
			best = app
	return best


func _set_outcome(outcomes: Array[Dictionary], app: Dictionary, outcome: String) -> void:
	for o: Dictionary in outcomes:
		if int((o["app"] as Dictionary)["uid"]) == int(app["uid"]):
			o["outcome"] = outcome
			return
	outcomes.append({"app": app, "outcome": outcome})


func _apply_outcomes(outcomes: Array[Dictionary], report: Dictionary, content: Dictionary) -> void:
	var new_invites: Array = report["invites"]
	var rejections: Array = report["rejections"]
	for o: Dictionary in outcomes:
		var app: Dictionary = o["app"]
		var outcome: String = o["outcome"]
		match outcome:
			"invite":
				app["status"] = "invited"
				new_invites.append(_add_invite(app, "rolled", "mail_invite_" + str(app["tier"])))
			"radar", "guarantee":
				app["status"] = "invited"
				new_invites.append(_add_invite(app, outcome, "mail_invite_" + outcome))
			"knockout", "rejected":
				app["status"] = "rejected"
				total_rejections += 1
				var knockout: Dictionary = {}
				if outcome == "knockout":
					knockout = (app["knockout_reason"] as Dictionary).duplicate(true)
				rejections.append({
					"app_uid": app["uid"], "company_id": app["company_id"], "template_id": app["template_id"],
					"tier": app["tier"], "knockout": knockout,
					"mail_id": "mail_knockout" if outcome == "knockout" else reject_mail_id(content, int(app["uid"])),
				})
			_:  # "ghost" and "silent": nothing arrives
				app["status"] = "silent"
				report["no_reply"] = int(report["no_reply"]) + 1


func _ghost_silent(cfg: BalanceConfig, report: Dictionary) -> void:
	var ghosted: Array = report["ghosted"]
	for app: Dictionary in applications:
		if app["status"] == "silent" and Odds.is_ghosted(cfg, int(app["day_sent"]), day):
			app["status"] = "ghosted"
			ghosted.append({
				"app_uid": app["uid"], "company_id": app["company_id"], "template_id": app["template_id"],
				"tier": app["tier"], "days": day - int(app["day_sent"]),
			})


## The guarantee's fallback (GDD 5.7): the highest-odds startup card on the board "saw your profile".
## Never a ghost job: with only ghost startup cards left there is no fallback invite (rare). The card
## leaves the board and its pair counts as applied. Ties go to the oldest card (lowest uid), never to
## deck order, so how the deck was swiped can't change the morning.
func _profile_invite(cfg: BalanceConfig, tiers: Dictionary, bg: BackgroundData, content: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_p := -1.0
	for card: Dictionary in board:
		if card["tier"] != "startup" or bool(card["is_ghost"]):
			continue
		var odds := card_odds(cfg, tiers, bg, content, card)
		if odds.is_empty():
			continue
		var p := float((odds["tailored"] as Dictionary)["p"])
		if p > best_p or (p == best_p and int(card["uid"]) < int(best["uid"])):
			best = card
			best_p = p
	if best.is_empty():
		return {}
	board.remove_at(_card_index(int(best["uid"])))
	applied.append(pair_key(str(best["template_id"]), str(best["company_id"])))
	return _add_invite({"uid": best["uid"], "company_id": best["company_id"], "template_id": best["template_id"],
		"tier": best["tier"]}, "profile", "mail_invite_guarantee")


func _add_invite(source: Dictionary, kind: String, mail_id: String) -> Dictionary:
	var invite := {
		"uid": new_uid(), "app_uid": source["uid"], "company_id": source["company_id"],
		"template_id": source["template_id"], "tier": source["tier"], "day_received": day,
		"kind": kind, "mail_id": mail_id,
	}
	invites.append(invite)
	return invite.duplicate(true)


## One card for tier: a template of that tier (not a SHOULD one such as the Unicorn), paired with a
## company of the tier (a pinned template only with its own company). Never a pair that was applied
## to or is already on the board; templates not on the board yet go first. The MVP companies deal
## first; once none of their pairs is free, the tier's other companies step in, so the board never
## starves (GDD 5.6: 38 pairs with the 6 MVP companies, 58 with all 9).
func _deal_card(cfg: BalanceConfig, tier: TierData, postings: Dictionary, companies: Dictionary, dealt: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var tier_id := String(tier.id)
	var on_board: Array[String] = []
	var templates_seen: Array[String] = []
	for card: Dictionary in board + dealt:
		on_board.append(pair_key(str(card["template_id"]), str(card["company_id"])))
		templates_seen.append(str(card["template_id"]))
	var free: Dictionary = {}       # template_id -> company ids still free
	for mvp: bool in [true, false]:
		free = _free_pairs(postings, tier_id, _companies_of(companies, tier_id, mvp), on_board)
		if not free.is_empty():
			break
	if free.is_empty():
		return {}
	var usable: Array[String] = []
	var fresh: Array[String] = []   # templates not on the board or dealt this morning
	for tid: String in free:
		usable.append(tid)
		if not templates_seen.has(tid):
			fresh.append(tid)
	var template_id: String = Odds.pick(rng, fresh if not fresh.is_empty() else usable, 1)[0]
	var company_id: String = Odds.pick(rng, free[template_id], 1)[0]
	var posting: Dictionary = postings[template_id]
	var rolled := Odds.roll_card(cfg, tier, str(posting.get("ghost", "roll")) == "always", rng)
	return {
		"uid": new_uid(), "template_id": template_id, "company_id": company_id, "tier": tier_id,
		"posted_days_ago": rolled["posted_days_ago"], "applicants": rolled["applicants"],
		"is_ghost": rolled["is_ghost"], "reposted": dropped.has(pair_key(template_id, company_id)),
	}


## template_id -> the company ids of `enabled` still free for it (in sorted template order), for a
## tier's templates that aren't SHOULD; a pinned template only with its own company.
func _free_pairs(postings: Dictionary, tier_id: String, enabled: Array[String], on_board: Array[String]) -> Dictionary:
	var free: Dictionary = {}
	for tid: String in _ids(postings):
		var entry: Dictionary = postings[tid]
		if str(entry.get("tier", "")) != tier_id or bool(entry.get("should", false)):
			continue
		var pinned := str(entry.get("company", "any"))
		var company_ids: Array[String] = []
		for cid: String in enabled:
			var pair := pair_key(tid, cid)
			if (pinned == "any" or pinned == cid) and not applied.has(pair) and not on_board.has(pair):
				company_ids.append(cid)
		if not company_ids.is_empty():
			free[tid] = company_ids
	return free


## A tier's companies that aren't blacklisted (GDD 5.5): the MVP ones ("mvp": true), or the others.
func _companies_of(companies: Dictionary, tier_id: String, mvp: bool) -> Array[String]:
	var out: Array[String] = []
	for id: String in _ids(companies):
		var company: Dictionary = companies[id]
		if str(company.get("tier", "")) == tier_id and not blacklist.has(id) and bool(company.get("mvp", false)) == mvp:
			out.append(id)
	return out


func _drop_oldest() -> void:
	var oldest := 0
	for i: int in board.size():
		if int(board[i]["uid"]) < int(board[oldest]["uid"]):
			oldest = i
	var pair := pair_key(str(board[oldest]["template_id"]), str(board[oldest]["company_id"]))
	if not dropped.has(pair):
		dropped.append(pair)
	board.remove_at(oldest)


func _quote(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, posting: Dictionary, cv_lines: Dictionary, tailored: bool, referral: bool) -> Dictionary:
	var sent := cv_sent(cv_lines, tailored)
	var posting_tags: Array = posting.get("tags", [])
	var sent_tags: Array = sent["tags"]
	var hits := Odds.tag_hits(PackedStringArray(posting_tags), PackedStringArray(sent_tags))
	var p := Odds.p_invite(cfg, tier, bg, hits, tailored, stat("net"), referral)
	return {
		"p": p, "band": Odds.odds_band(cfg, p), "hits": hits, "relevant": Odds.is_relevant(cfg, hits),
		"knockout": Odds.knockout_reason(bool(posting.get("degree", false)), int(posting.get("min_years", 0)),
			bool(sent["degree"]), bool(sent["passes_years"]), referral),
	}


## P as frozen in an application, rounded to 9 decimals: the JSON save keeps about 15 significant
## digits, so an unrounded P reads back a hair different and a Continue would roll against another P.
static func _frozen_p(p: float) -> float:
	return ("%.9f" % p).to_float()


## The cv_lines.json id for this background's line at a level, "honest" or "polished" (the fields
## decide, not the id's spelling).
func _cv_line_id(cv_lines: Dictionary, line: String, level: String) -> String:
	for key: Variant in cv_lines:
		var entry: Variant = cv_lines[key]
		if entry is Dictionary and entry.get("background") == background_id \
				and entry.get("line") == line and entry.get("variant") == level:
			return str(key)
	return ""


func _card_index(card_uid: int) -> int:
	for i: int in board.size():
		if int(board[i]["uid"]) == card_uid:
			return i
	return -1


func _application(app_uid: int) -> Dictionary:
	for app: Dictionary in applications:
		if int(app["uid"]) == app_uid:
			return app
	return {}


static func _posting(content: Dictionary, template_id: String) -> Dictionary:
	var entry: Variant = _file(content, "postings").get(template_id)
	if entry is Dictionary:
		return entry
	return {}


static func _tier(tiers: Dictionary, id: String) -> TierData:
	return tiers.get(id) as TierData


static func _file(content: Dictionary, file: String) -> Dictionary:
	var d: Variant = content.get(file)
	if d is Dictionary:
		return d
	return {}


## GDD S10: the tier's fine print (fp_* in emails.json) minus any that repeats a perk on the same
## paper: fp_<x> is left out when perk_<x> was dealt, so a startup never lists "Unlimited PTO*" twice.
static func fine_print_pool(emails: Dictionary, tier_id: String, perks: Array) -> Array[String]:
	var pool: Array[String] = []
	for id: String in _tier_entries(emails, "fp_", tier_id):
		if not perks.has("perk_" + id.trim_prefix("fp_")):
			pool.append(id)
	return pool


## The sorted ids starting with prefix whose "tiers" list this tier (perk_*, fp_* in emails.json).
static func _tier_entries(entries: Dictionary, prefix: String, tier_id: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _ids(entries):
		if id.begins_with(prefix) and ((entries[id] as Dictionary).get("tiers", []) as Array).has(tier_id):
			ids.append(id)
	return ids


## A content file's entry ids, sorted, so dealing never depends on dictionary order. Plain-string UI
## ids (e.g. "card_posted") and "_" metadata keys are skipped.
static func _ids(entries: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for key: Variant in entries:
		if entries[key] is Dictionary and not str(key).begins_with("_"):
			ids.append(str(key))
	ids.sort()
	return ids


# ---------- save format ----------

func to_dict() -> Dictionary:
	var d: Dictionary = {"version": VERSION}
	for prop: Dictionary in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			d[prop["name"]] = get(prop["name"])
	return d


static func from_dict(d: Dictionary) -> RunState:
	var r := RunState.new()
	# When VERSION changes, migrate `d` here first, e.g. if int(d.get("version", 1)) < 2: ...
	for prop: Dictionary in r.get_property_list():
		var key: String = prop["name"]
		if not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) or not d.has(key):
			continue
		var value: Variant = _whole_floats_to_ints(d[key])
		var current: Variant = r.get(key)
		match typeof(current):
			TYPE_ARRAY:
				(current as Array).assign(value)        # keeps the typed array (Array[String] ...)
			TYPE_DICTIONARY:
				(current as Dictionary).assign(value)
			TYPE_INT:
				r.set(key, int(value))
			TYPE_FLOAT:
				r.set(key, float(value))
			TYPE_BOOL:
				r.set(key, bool(value))
			_:
				r.set(key, str(value))
	return r


## JSON turns every number into a float. Whole numbers become ints again, recursively.
static func _whole_floats_to_ints(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var f: float = v
			if f == floorf(f) and absf(f) < 9.0e15:
				return int(f)
			return f
		TYPE_ARRAY:
			var arr: Array = []
			for e: Variant in v:
				arr.append(_whole_floats_to_ints(e))
			return arr
		TYPE_DICTIONARY:
			var dict: Dictionary = {}
			var src: Dictionary = v
			for k: Variant in src:
				dict[k] = _whole_floats_to_ints(src[k])
			return dict
	return v

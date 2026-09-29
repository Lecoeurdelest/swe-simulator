@tool
class_name HuntTips
extends RefCounted
## Which Ducky tip the job hunt shows, and when (GDD 8.3). A tip waits for a natural pause (8.1 rule 3):
## the night summary, the morning inbox, Study, and the offer that ends the hunt. Also the first run's
## coach marks (GDD 4.3).
## Pure: it only reads the run.
## GameState.mark_tip_shown() records a once-per-run tip in run.tips_shown; GameState.close_coach_mark()
## records a coach mark tapped closed in run.coach_closed.

const SPRAY_QUICK_APPLIES := 8   # GDD 8.3: "8 Quick Applies without an invite"
const REJECTION_TIP_EVERY := 10  # GDD 8.3: "first rejection email / every 10th rejection"
const COACH_SLEEP_PIPS := 2      # GDD 4.3: the Sleep coach mark at 2 energy or less...
const COACH_SLEEP_APPS := 4      # ...or after 4 applications
const COACH_INVITE := "coach_invite"  # the invite's mark, whichever line Ducky says (Research is SHOULD)
## An application only reaches these statuses after an invite arrived for it.
const INVITED_STATUSES: PackedStringArray = ["invited", "interview", "expired"]


## Mail's one tip (GDD S06, 8.1 rule 2, 8.3), under the rejection stack: the run's first knockout
## rejection -> tip_ats_knockouts; else its first rejection, or every 10th -> tip_rejection_numbers;
## "" for none. The run is read after the Sleep that built the report (its rejections are counted),
## so one report gives the same tip in the morning and in Mail later that day.
static func inbox(run: RunState, report: Dictionary) -> String:
	var rejections: Array = report.get("rejections", [])
	if rejections.is_empty():
		return ""
	var knockouts_now := 0
	for rejection: Variant in rejections:
		if rejection is Dictionary and not ((rejection as Dictionary).get("knockout", {}) as Dictionary).is_empty():
			knockouts_now += 1
	if knockouts_now > 0 and _knockout_rejections(run) == knockouts_now:
		return "tip_ats_knockouts"
	var after := run.total_rejections
	var before := after - rejections.size()
	var last_multiple := after - posmod(after, REJECTION_TIP_EVERY)
	if before <= 0 or (last_multiple >= REJECTION_TIP_EVERY and last_multiple > before):
		return "tip_rejection_numbers"
	return ""


## Tonight's tip on the lock screen, each once per run: the first referral used -> tip_referrals;
## 8 Quick Applies without an invite -> tip_tailor_over_spray; after a Tailor & Apply (every line sent
## as its honest Polished reframing) -> tip_projects_count when bg's honest CV fails "1+ years"
## (years_pass_honest: the Graduate, the Self-Taught), then tip_quantify_impact. "" for none.
static func night(run: RunState, bg: BackgroundData = null) -> String:
	if not run.tips_shown.has("tip_referrals"):
		for app: Dictionary in run.applications:
			if bool(app.get("referral", false)):
				return "tip_referrals"
	if not run.tips_shown.has("tip_tailor_over_spray") and not had_invite(run):
		var quick := 0
		for app: Dictionary in run.applications:
			if not bool(app.get("tailored", false)):
				quick += 1
		if quick >= SPRAY_QUICK_APPLIES:
			return "tip_tailor_over_spray"
	if _any_tailored(run):
		if bg != null and not bg.years_pass_honest and not run.tips_shown.has("tip_projects_count"):
			return "tip_projects_count"
		if not run.tips_shown.has("tip_quantify_impact"):
			return "tip_quantify_impact"
	return ""


## After a Study action: the first one this run -> tip_fundamentals (GDD 8.3).
static func studied(run: RunState) -> String:
	return "" if run.tips_shown.has("tip_fundamentals") else "tip_fundamentals"


## The Jobs screen's coach mark on day 1 of the first run (GDD 4.3): "coach_sleep" at COACH_SLEEP_PIPS
## energy or less or after COACH_SLEEP_APPS applications (over the empty deck too); else, with a card
## up, "coach_apply" until the first application, then "coach_flip" until a card was flipped (flipped)
## or tailored; "" for none, and never over the card's back. Each goes away when you do what it asks.
## One tapped closed (run.coach_closed) never comes back, and the mark after it still waits for its
## own rule: closing Apply doesn't bring Flip early.
static func coach(run: RunState, has_card: bool, card_back: bool, flipped: bool) -> String:
	if not run.first_run or run.day != 1 or (has_card and card_back):
		return ""
	var id := ""
	if run.energy <= COACH_SLEEP_PIPS or run.total_applications >= COACH_SLEEP_APPS:
		id = "coach_sleep"
	elif has_card and run.total_applications == 0:
		id = "coach_apply"
	elif has_card and not flipped and not _any_tailored(run):
		id = "coach_flip"
	return "" if run.coach_closed.has(id) else id


## Mail's coach mark (GDD 4.3 "Day 2 morning"): the first run's invites point at their GO NOW until the
## first interview, unless it was tapped closed.
static func coach_invite(run: RunState) -> bool:
	return run.first_run and run.interviews_taken == 0 and run.interview.is_empty() and not run.invites.is_empty() \
		and not run.coach_closed.has(COACH_INVITE)


## The offer's one tip (GDD S10, 8.1 rule 2, 8.3): a startup offer, which carries the joke equity ->
## tip_equity_lottery; any other -> tip_total_comp (its trigger: an offer with a commute). Negotiate
## is SHOULD, so tip_negotiate never shows yet.
static func offer(run: RunState) -> String:
	return "tip_equity_lottery" if str(run.offer.get("equity_text", "")) != "" else "tip_total_comp"


## The Plan B card's one tip (GDD S12, 8.1 rule 4: it matches the cause). No invite all run: nobody
## replied, and tailoring is what gets replies -> tip_tailor_over_spray. Invites but no job ->
## tip_rejection_numbers (many rejections are normal; keep going).
static func plan_b(run: RunState) -> String:
	return "tip_rejection_numbers" if had_invite(run) else "tip_tailor_over_spray"


## An invite arrived this run: one is waiting, an application got one (invited, taken or expired),
## or an interview was taken or is under way (a "saw your profile" invite has no application).
static func had_invite(run: RunState) -> bool:
	if not run.invites.is_empty() or run.interviews_taken > 0 or not run.interview.is_empty():
		return true
	for app: Dictionary in run.applications:
		if INVITED_STATUSES.has(str(app.get("status", ""))):
			return true
	return false


static func _knockout_rejections(run: RunState) -> int:
	var count := 0
	for app: Dictionary in run.applications:
		if str(app.get("status", "")) == "rejected" and bool(app.get("knockout", false)):
			count += 1
	return count


static func _any_tailored(run: RunState) -> bool:
	for app: Dictionary in run.applications:
		if bool(app.get("tailored", false)):
			return true
	return false

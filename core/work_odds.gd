@tool
class_name WorkOdds
extends RefCounted
## The career run's formulas (GDD 5.15-5.21) as static functions, like Odds. No state, no autoloads, no global
## RNG: anything random takes the run's RandomNumberGenerator. Tested by test_sim_rules, test_sim_review and
## test_sim_events. Levels, homes and ratings are indexes into these lists.

const LEVELS: PackedStringArray = ["junior", "mid", "senior"]
const HOMES: PackedStringArray = ["shared", "one_bed", "studio", "penthouse"]
const RATINGS: PackedStringArray = ["below", "meets", "exceeds"]
const JUNIOR := 0
const MID := 1
const SENIOR := 2
const BELOW := 0
const MEETS := 1
const EXCEEDS := 2
const QUALITY_CLEAN := 0
const QUALITY_BALANCED := 1
const QUALITY_FAST := 2


# ---------- floors and money (GDD 5.15, 6.1) ----------

## 1 + step x (floor - 1): the multiplier every floor-depth rule shares.
static func floor_mult(step: float, floor_n: int) -> float:
	return 1.0 + step * (floor_n - 1)


## An offer's salary in k$ a month: the level's base x the archetype's multiplier x the floor's raise x the Scars.
static func offer_salary(cfg: WorkConfig, arch: ArchetypeData, level: int, floor_n: int, gap_stacks: int) -> float:
	return cfg.salary_base_k[level] * arch.pay_mult * floor_mult(cfg.floor_salary_step, floor_n) * (1.0 - cfg.resume_gap_offer_cut * gap_stacks)


## Savings over one month of rent and living costs, in months (the chip turns red under runway_red_months).
static func runway_months(savings: float, rent: float, living: float) -> float:
	return savings / (rent + living)


## Starting savings in k$: the background's months of expenses in the Shared room, plus the Emergency fund edge.
static func start_savings(cfg: WorkConfig, bg: BackgroundData, emergency_edge: bool) -> float:
	var months := bg.start_savings_months + (cfg.edge_emergency_months if emergency_edge else 0.0)
	return months * (cfg.home_rent_k[cfg.start_home] + cfg.living_cost_k)


## Months of salary paid when a job ends in a layoff. options are rolled with equal odds; per_year is
## prorated by the days of tenure. first_job_max picks the largest option instead (run 1's Pivotly: always 1).
static func severance_months(cfg: WorkConfig, arch: ArchetypeData, tenure_days: int, first_job_max: bool, rng: RandomNumberGenerator) -> float:
	var options: PackedFloat64Array = arch.severance_options
	var pick: float = 0.0
	if not options.is_empty():
		if first_job_max:
			pick = options[0]
			for o: float in options:
				pick = maxf(pick, o)
		else:
			pick = options[rng.randi_range(0, options.size() - 1)]
	return pick + arch.severance_per_year * float(tenure_days) / float(cfg.days_per_year)


# ---------- the daily formulas (GDD 5.16, 5.17) ----------

## Ticket progress per day in percent of a ticket: (100 / size) x Hours x Skill x Codebase x process x a
## Senior's calendar tax and quality bar x any speed change from an event.
static func ticket_rate(cfg: WorkConfig, size: int, notch: int, skill: float, codebase: float, arch: ArchetypeData, level: int, quality: int, speed_mod: float) -> float:
	var rate := 100.0 / cfg.ticket_size_days[size] * cfg.hours_speed[notch - 1]
	rate *= (1.0 + skill / cfg.skill_speed_div) * (1.0 - codebase / cfg.codebase_speed_div) * arch.ticket_speed * speed_mod
	if level >= SENIOR:
		rate *= cfg.calendar_tax
		if quality == QUALITY_CLEAN:
			rate *= cfg.quality_clean_speed
		elif quality == QUALITY_FAST:
			rate *= cfg.quality_fast_speed
	return rate


## Burnout change per day while you work, before the Burnout History floor: the Hours notch, minus the home's
## recovery, plus a heavy Codebase, a short runway and a commute. A negative notch value is rest and is never
## scaled; the Overtime edge trims only the notch-5 gain.
static func burnout_delta(cfg: WorkConfig, notch: int, home: int, codebase: float, runway: float, commute: float, overtime_edge: bool) -> float:
	var hours := cfg.hours_burnout[notch - 1]
	if overtime_edge and notch == cfg.hours_burnout.size() and hours > 0.0:
		hours *= cfg.edge_overtime_burnout_mult
	var d := hours - cfg.home_recovery[home] + commute
	if codebase >= cfg.codebase_burnout_min:
		d += cfg.codebase_burnout
	if runway < cfg.runway_red_months:
		d += cfg.low_runway_burnout
	return d


## Burnout change per day with no work (between jobs or on a forced leave). It is the same formula as working (D-04: one
## clock), minus what only a job has (a heavy Codebase, a commute): the Hours notch still sets how hard you push, the home
## still recovers you, and a thin runway still weighs on you.
static func idle_burnout_delta(cfg: WorkConfig, notch: int, home: int, runway: float) -> float:
	var d := cfg.hours_burnout[notch - 1] - cfg.home_recovery[home]
	if runway < cfg.runway_red_months:
		d += cfg.low_runway_burnout
	return d


## Manager Opinion change per day: the Hours notch, plus an archetype's utilization at notches 1-2.
static func mo_delta(cfg: WorkConfig, arch: ArchetypeData, notch: int) -> float:
	var d := cfg.hours_mo[notch - 1]
	if notch <= 2:
		d += arch.utilization_mo
	return d


## The Codebase's drift per day: the archetype's, plus a Senior's quality bar.
static func codebase_drift(cfg: WorkConfig, arch: ArchetypeData, level: int, quality: int) -> float:
	var d := arch.codebase_drift
	if level >= SENIOR:
		if quality == QUALITY_CLEAN:
			d += cfg.quality_clean_codebase
		elif quality == QUALITY_FAST:
			d += cfg.quality_fast_codebase
	return d


## p(incident per day): the Codebase's, times the floor's event frequency and any other multiplier (on-call,
## the Studio's final threat).
static func incident_p(cfg: WorkConfig, codebase: float, floor_n: int, mult: float) -> float:
	return (cfg.incident_base + cfg.incident_per_codebase * codebase) * floor_mult(cfg.floor_event_step, floor_n) * mult


## Days between incidents when each one starts a cooldown: the cooldown plus the mean wait of a daily roll.
static func incident_gap_days(cfg: WorkConfig, codebase: float, cooldown_days: int) -> float:
	return cooldown_days + 1.0 / incident_p(cfg, codebase, 1, 1.0)


# ---------- the review (GDD 5.16) ----------

## Your Evidence HP: a base, half your Manager Opinion, 5 per ticket shipped on time since the last review,
## and the Brag doc edge.
static func evidence(cfg: WorkConfig, mo: float, on_time_tickets: int, brag_edge: bool) -> float:
	var e := cfg.evidence_base + mo / cfg.evidence_mo_div + cfg.evidence_per_ticket * on_time_tickets
	if brag_edge:
		e += cfg.edge_brag_evidence
	return maxf(1.0, e)


## The rating from the Evidence you have left: under 25% of it is Below, over 70% Exceeds, else Meets.
static func rating(cfg: WorkConfig, evidence_total: float, evidence_left: float) -> int:
	var share := evidence_left / evidence_total
	if share < cfg.rating_below_max:
		return BELOW
	if share > cfg.rating_exceeds_min:
		return EXCEEDS
	return MEETS


## The stand-in for the review duel until M3 (A67): the manager's Calibration HP chips at your Evidence for
## review_standin_damage of itself, give or take review_standin_noise. Returns the Evidence you keep.
static func review_standin_left(cfg: WorkConfig, calibration: float, evidence_total: float, rng: RandomNumberGenerator) -> float:
	var damage := calibration * cfg.review_standin_damage * (1.0 + cfg.review_standin_noise * (rng.randf() * 2.0 - 1.0))
	return clampf(evidence_total - damage, 0.0, evidence_total)


## The raise a rating earns, as a fraction of salary.
static func raise_for(cfg: WorkConfig, rating_id: int) -> float:
	if rating_id == EXCEEDS:
		return cfg.raise_exceeds
	if rating_id == MEETS:
		return cfg.raise_meets
	return 0.0


## True when this review promotes you: the archetype's rating, held for its streak (counting this review).
static func promotes(arch: ArchetypeData, rating_id: int, streak: int, level: int) -> bool:
	return level < SENIOR and rating_id >= arch.promotion_min_rating and streak >= arch.promotion_streak


# ---------- events (GDD 5.19) ----------

## The chance Burnout picks for you: 0 below auto_resolve_from, then (Burnout - 70) / 30, certain at 100.
static func auto_resolve_p(cfg: WorkConfig, burnout: float) -> float:
	if burnout < cfg.auto_resolve_from:
		return 0.0
	return clampf((burnout - cfg.auto_resolve_base) / cfg.auto_resolve_span, 0.0, 1.0)


## How many employees a resizing cuts: the archetype's share of the floor, at least layoff_min_cut.
static func layoff_cut_count(cfg: WorkConfig, arch: ArchetypeData, employees: int) -> int:
	return clampi(maxi(cfg.layoff_min_cut, roundi(arch.layoff_share * employees)), 0, employees)


## Which employees a resizing cuts (R-EVT-03): each one's chance is weighted layoff_salary_weight by salary rank (the
## highest salary the largest share, the lowest none) and layoff_luck_weight by chance (an equal share each), and
## `cuts` people are drawn from those weights without replacement. Manager Opinion is not an input (O1). Returns
## indexes into salaries, in the order they were drawn.
static func layoff_cuts(cfg: WorkConfig, salaries: Array, cuts: int, rng: RandomNumberGenerator) -> Array[int]:
	var n := salaries.size()
	var by_salary: Array[int] = []
	for i: int in n:
		by_salary.append(i)
	by_salary.sort_custom(func(a: int, b: int) -> bool:
		var sa: float = salaries[a]
		var sb: float = salaries[b]
		return sa < sb if sa != sb else a < b)
	var rank_total := maxf(1.0, n * (n - 1) / 2.0)
	var weight: Array[float] = []
	weight.resize(n)
	for rank: int in n:
		weight[by_salary[rank]] = cfg.layoff_salary_weight * rank / rank_total + cfg.layoff_luck_weight / n
	var out: Array[int] = []
	var left: Array[int] = []
	for i: int in n:
		left.append(i)
	for k: int in mini(cuts, n):
		var total := 0.0
		for i: int in left:
			total += weight[i]
		var r := rng.randf() * total
		var pick := left.size() - 1
		for j: int in left.size():
			r -= weight[left[j]]
			if r < 0.0:
				pick = j
				break
		out.append(left[pick])
		left.remove_at(pick)
	return out


## Daily odds of a random event: a per-year rate spread over the days, times the floor's event frequency and the
## Studio's final-threat weight.
static func random_event_p(cfg: WorkConfig, per_year: float, floor_n: int, threat_mult: float) -> float:
	return per_year / cfg.days_per_year * floor_mult(cfg.floor_event_step, floor_n) * threat_mult


# ---------- the job hunt (GDD 5.20) ----------

## f_level: 1.0 at your level, 0.5 one level up, 0.8 below.
static func level_factor(cfg: WorkConfig, posting_level: int, level: int) -> float:
	if posting_level > level:
		return cfg.callback_level_up
	if posting_level < level:
		return cfg.callback_level_down
	return cfg.callback_level_same


## p_callback = 0.35 x f_level x (1 - 0.15 per Short Tenure stack) x (1 + 0.1 per reference). e_handbook is 1.0
## in v1: no Edge tip touches it.
static func callback_p(cfg: WorkConfig, posting_level: int, level: int, short_tenure_stacks: int, references: int) -> float:
	return cfg.callback_base * level_factor(cfg, posting_level, level) \
		* (1.0 - cfg.callback_short_tenure_cut * short_tenure_stacks) * (1.0 + cfg.callback_reference_bonus * references)


# ---------- the duel's inputs (GDD 5.20, R-JOB-03) ----------

## Your Composure HP: the background's base, lowered by Burnout.
static func duel_composure(cfg: WorkConfig, base: float, burnout: float) -> float:
	return base * (1.0 - burnout / cfg.duel_composure_burnout_div)


## The Answer Meter's width multiplier: Skill widens it, Rust narrows it. The caller keeps the 0.06 floor (RC-25).
static func duel_zone_mult(cfg: WorkConfig, skill: float, rust: float) -> float:
	return (1.0 + skill / cfg.duel_zone_skill_div) * (1.0 - rust / cfg.duel_zone_rust_div)


## Dana's Doubt HP: the tier's base, raised by the floor.
static func duel_doubt(cfg: WorkConfig, base: float, floor_n: int) -> float:
	return base * floor_mult(cfg.floor_doubt_step, floor_n)


# ---------- the Studio (GDD 3.4) ----------

## How many of the five conditions hold: Senior, Remote, The Studio, Burnout at or below 30, and a runway of 6
## months at Studio rent.
static func studio_count(cfg: WorkConfig, level: int, remote: bool, home: int, burnout: float, savings: float, living: float) -> int:
	var n := 0
	if level >= SENIOR:
		n += 1
	if remote:
		n += 1
	if home == cfg.studio_home:
		n += 1
	if burnout <= cfg.studio_burnout_max:
		n += 1
	if savings / (cfg.home_rent_k[cfg.studio_home] + living) >= cfg.studio_runway_months:
		n += 1
	return n

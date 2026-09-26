@tool
class_name Odds
extends RefCounted
## Every game formula (GDD 5.6-5.9) as static functions. No state, no autoloads, no global RNG:
## anything random takes the run's RandomNumberGenerator. Tested by test_odds / test_interview / test_offer.
## Never call randf(), randi(), Array.shuffle() or Array.pick_random() in gameplay: they use the global RNG.

# ---------- dice ----------

static func roll(rng: RandomNumberGenerator, p: float) -> bool:
	return rng.randf() < p


## n distinct items from pool, in an order decided by this RNG.
static func pick(rng: RandomNumberGenerator, pool: Array, n: int) -> Array:
	var bag := pool.duplicate()
	var out: Array = []
	while out.size() < n and not bag.is_empty():
		out.append(bag.pop_at(rng.randi_range(0, bag.size() - 1)))
	return out


static func shuffled(rng: RandomNumberGenerator, items: Array) -> Array:
	return pick(rng, items, items.size())


# ---------- job hunt (GDD 5.6) ----------

static func tag_hits(posting_tags: PackedStringArray, tags_sent: PackedStringArray) -> int:
	var hits := 0
	for tag: String in posting_tags:
		if tags_sent.has(tag):
			hits += 1
	return hits


static func is_relevant(cfg: BalanceConfig, hits: int) -> bool:
	return hits >= cfg.relevant_min_tags


static func is_knockout(degree_required: bool, min_years: int, cv_has_degree: bool, cv_passes_years: bool, referral: bool) -> bool:
	if referral:
		return false
	return (degree_required and not cv_has_degree) or (min_years > 0 and not cv_passes_years)


## P_invite for one application. hits = matched tags out of the posting's 3 (M = hits / 3).
static func p_invite(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, hits: int, tailored: bool, net: int, referral: bool) -> float:
	var p := tier.base_invite * (cfg.match_base + hits / 3.0)
	p *= cfg.tailor_apply_mult if tailored else cfg.quick_apply_mult
	p *= 1.0 + net / cfg.net_divisor
	p *= bg.invite_mult(tier.id)
	p *= cfg.referral_mult if referral else 1.0
	return clampf(p, cfg.p_invite_min, cfg.p_invite_max)


## 1-5 dots on a card: Long shot, Unlikely, Possible, Decent, Good.
static func odds_band(cfg: BalanceConfig, p: float) -> int:
	var band := 1
	for threshold: float in cfg.band_thresholds:
		if p >= threshold:
			band += 1
	return band


# ---------- interview (GDD 5.8) ----------

static func teamwork_mult(bg: BackgroundData, lone_wolf: bool) -> float:
	return bg.teamwork_mult if lone_wolf else bg.teamwork_mult_after_network


static func is_tired(cfg: BalanceConfig, pips_left_after_paying: int) -> bool:
	return pips_left_after_paying <= cfg.tired_threshold


static func needle_speed(cfg: BalanceConfig, tier: TierData, tired: bool) -> float:
	return tier.needle_speed * (cfg.tired_needle_mult if tired else 1.0)


## P: how well your character knows this question (before luck).
static func knowledge_p(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, knw: int, experience: int, is_tech: bool, weak: bool) -> float:
	var exp_eff := experience + (bg.startup_exp_bonus if tier.id == &"startup" else 0)
	var p: float
	if is_tech:
		p = cfg.tech_knw_w * knw + cfg.tech_exp_w * exp_eff
	else:
		p = cfg.behav_knw_w * knw + cfg.behav_exp_w * exp_eff
	return p - (cfg.weak_penalty if weak else 0.0)


static func roll_luck(cfg: BalanceConfig, rng: RandomNumberGenerator) -> float:
	return rng.randf_range(-cfg.luck_range, cfg.luck_range)


## S, the Stat Score (5-95). question_difficulty is 1, 2 or 3.
static func stat_score(cfg: BalanceConfig, tier: TierData, p: float, question_difficulty: int, luck: float) -> float:
	var d := tier.tier_difficulty + cfg.question_diff_offsets[question_difficulty - 1]
	return clampf(50.0 + cfg.stat_sensitivity * (p - d) + luck, 5.0, 95.0)


## h, the NAILED IT half-width as a fraction of the bar.
static func zone_half(cfg: BalanceConfig, s: float, bonus: float = 0.0) -> float:
	return cfg.zone_half_base + cfg.zone_half_per_s * s / 100.0 + bonus


## I, the input quality from where the needle stopped (tap, center and h are fractions of the bar).
static func input_quality(cfg: BalanceConfig, tap: float, center: float, h: float) -> float:
	var dist := absf(tap - center)
	if dist <= cfg.perfect_frac * h:
		return cfg.input_perfect
	if dist <= h:
		return cfg.input_good
	if dist <= cfg.close_mult * h:
		return cfg.input_close
	return cfg.input_miss


static func answer_q(cfg: BalanceConfig, s: float, input: float) -> float:
	return cfg.q_stat_weight * s + cfg.q_input_scale * input


## Signed change to Doubt (negative = good for you).
static func knowledge_doubt_delta(cfg: BalanceConfig, q: float) -> float:
	return -cfg.doubt_dmg_scale * maxf(0.0, q - cfg.doubt_dmg_floor)


static func knowledge_composure_loss(cfg: BalanceConfig, q: float) -> float:
	return maxf(0.0, cfg.comp_dmg_ceiling - q)


static func spoken_grade(cfg: BalanceConfig, q: float) -> StringName:
	if q >= cfg.green_q_min:
		return &"green"
	if q >= cfg.yellow_q_min:
		return &"yellow"
	return &"red"


## kind: good | neutral | bad | insider.
static func ethics_doubt_delta(cfg: BalanceConfig, kind: StringName, teamwork_question: bool, teamwork: float) -> float:
	match kind:
		&"good":
			return cfg.ethics_good * (teamwork if teamwork_question else 1.0)
		&"neutral":
			return cfg.ethics_neutral
		&"insider":
			return cfg.insider_why_us
		&"bad":
			return cfg.ethics_bad_doubt
	return 0.0


static func ethics_composure_loss(cfg: BalanceConfig, kind: StringName) -> float:
	return cfg.ethics_bad_comp if kind == &"bad" else 0.0


static func committee_eligible(cfg: BalanceConfig, doubt: float, doubt_max: float) -> bool:
	return doubt <= cfg.committee_band * doubt_max


static func committee_win_p(cfg: BalanceConfig, doubt: float, doubt_max: float, net: int) -> float:
	var closeness := 1.0 - doubt / (cfg.committee_band * doubt_max)
	return minf(cfg.committee_cap, cfg.committee_base + cfg.committee_close_bonus * closeness + net / cfg.committee_net_div)


static func bluff_p(cfg: BalanceConfig, tier: TierData, knw: int, experience: int, degree_claim: bool) -> float:
	var p := cfg.bluff_base + (knw - 50) / cfg.bluff_knw_div + (experience - cfg.bluff_exp_ref) / cfg.bluff_exp_div
	p -= tier.bluff_detect + (cfg.bluff_weight_degree if degree_claim else cfg.bluff_weight_lie)
	return clampf(p, cfg.bluff_min, cfg.bluff_max)


# ---------- offer and endings (GDD 5.9) ----------

static func round_to(value: float, step: int) -> int:
	return roundi(value / step) * step


## Yearly salary in whole dollars.
static func offer_salary(cfg: BalanceConfig, tier: TierData, bg: BackgroundData, composure_left: float, composure_max: float) -> int:
	var band_pos := clampf(cfg.band_base + cfg.band_perf_weight * composure_left / composure_max, 0.0, 1.0)
	var raw := lerpf(tier.salary_min_k * 1000.0, tier.salary_max_k * 1000.0, band_pos) * bg.salary_mult
	return round_to(raw, cfg.salary_round)


static func negotiate_p(cfg: BalanceConfig, net: int, other_invite_waiting: bool) -> float:
	return minf(cfg.nego_cap, cfg.nego_base + net / cfg.nego_net_div + (cfg.nego_leverage if other_invite_waiting else 0.0))


static func negotiated_salary(cfg: BalanceConfig, salary: int, rng: RandomNumberGenerator) -> int:
	return round_to(salary * (1.0 + rng.randf_range(cfg.nego_gain_min, cfg.nego_gain_max)), cfg.salary_round)


static func dream_score(cfg: BalanceConfig, salary: int, office_days: int, commute_minutes: int, red_flags: int, rent_days_left: int, runway_days: int) -> int:
	var weekly_commute_h := office_days * 2.0 * commute_minutes / 60.0
	var pts := cfg.dream_w_salary * minf(1.0, float(salary) / cfg.dream_salary_target)
	pts += cfg.dream_w_remote * (5 - office_days) / 5.0
	pts += cfg.dream_w_commute * maxf(0.0, 1.0 - weekly_commute_h / cfg.dream_commute_zero_h)
	pts += maxf(0.0, cfg.dream_w_flags - cfg.dream_flag_penalty * red_flags)
	pts += cfg.dream_w_runway * rent_days_left / float(runway_days)
	return roundi(pts)

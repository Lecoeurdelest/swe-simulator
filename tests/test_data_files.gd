@tool
extends McpTestSuite
## The 11 tuning .tres files (ARCHITECTURE 6.2, 19.3) hold exactly the GDD section 11 defaults.
## Changing a value in a .tres (or a script default) means updating GDD 11 and this test in the
## same commit, so every tuning change is a conscious one. Loads res:// files only (no autoloads).

const BALANCE_PATH := "res://data/balance/balance_config.tres"
const TIER_DIR := "res://data/tiers/"
const BG_DIR := "res://data/backgrounds/"
const WORK_PATH := "res://data/work/work_config.tres"
const ARCHETYPE_DIR := "res://data/archetypes/"

## GDD 11, owner B (one file). A var, not a const: Packed*Array() is not a constant expression.
var balance_expected: Dictionary = {
	# 11.1 Energy, time, board
	"energy_max": 10, "rent_warning_days": 3,
	"cost_quick_apply": 1, "cost_tailor_apply": 2, "cost_research": 1, "cost_study": 2,
	"cost_network": 2, "cost_interview": 3,
	"tired_threshold": 2, "tired_needle_mult": 1.15, "max_interviews_per_day": 1,
	"invite_valid_days": 2, "board_new_per_day": 6, "board_max": 10,
	"ghost_posted_days_min": 60, "ghost_posted_days_max": 500, "full_scan_animations": 3,
	# 11.2 Stats and growth
	"stat_cap": 80, "study_knw_gain": 5, "network_net_gain": 5,
	"network_ref_base": 0.35, "network_ref_net_div": 200.0,
	# 11.3 Applications and responses
	"match_base": 0.5, "quick_apply_mult": 0.6, "tailor_apply_mult": 1.5, "referral_mult": 2.5,
	"net_divisor": 100.0, "p_invite_min": 0.01, "p_invite_max": 0.60, "relevant_min_tags": 2,
	"knockout_reply_delay_days": 1, "ghosted_after_days": 7, "day2_guarantee_min_apps": 3,
	"band_thresholds": PackedFloat32Array([0.03, 0.07, 0.12, 0.20]),
	"site_megaboard_ghost_add": 0.05, "site_humblebrag_invite_mult": 1.1,
	# 11.4 Interview
	"prompt_pattern": PackedStringArray(["choice", "knowledge", "knowledge", "knowledge", "choice"]),
	"question_diff_offsets": PackedInt32Array([-5, 0, 5]),
	"stat_sensitivity": 0.7, "luck_range": 12.0, "weak_penalty": 15.0,
	"tech_knw_w": 0.7, "tech_exp_w": 0.3, "behav_knw_w": 0.3, "behav_exp_w": 0.7,
	"zone_half_base": 0.06, "zone_half_per_s": 0.12, "perfect_frac": 0.4, "close_mult": 2.0,
	"input_perfect": 1.0, "input_good": 0.8, "input_close": 0.5, "input_miss": 0.2,
	"relaxed_input": 0.9, "q_stat_weight": 0.75, "q_input_scale": 25.0,
	"jump_window_min_s": 1.0, "jump_window_max_s": 2.5, "max_round_trips": 3,
	"answer_meter_width_px": 200, "doubt_dmg_scale": 0.9, "doubt_dmg_floor": 30.0,
	"comp_dmg_ceiling": 50.0, "green_q_min": 60.0, "yellow_q_min": 45.0,
	"ethics_good": -10.0, "ethics_neutral": -4.0, "ethics_bad_doubt": 8.0, "ethics_bad_comp": 15.0,
	"insider_why_us": -18.0, "committee_band": 0.15, "committee_base": 0.40,
	"committee_close_bonus": 0.20, "committee_net_div": 200.0, "committee_cap": 0.85,
	"input_lock_ms": 250, "vs_duration_s": 2.0, "typewriter_cps": 40.0,
	# 11.6 Offer and endings
	"band_base": 0.25, "band_perf_weight": 0.50, "salary_round": 1000, "dream_salary_target": 150000,
	"dream_w_salary": 40.0, "dream_w_remote": 25.0, "dream_w_commute": 15.0,
	"dream_w_flags": 10.0, "dream_w_runway": 10.0,
	"dream_commute_zero_h": 10.0, "dream_flag_penalty": 5.0, "grace_day": true,
}

## GDD 11, owner T: one column per file (ARCHITECTURE 6.2 table).
const TIERS: Dictionary = {
	"startup": {
		"base_invite": 0.10, "ghost_job_rate": 0.05, "silent_share": 0.40, "reply_delay_days": 1,
		"posted_days_min": 0, "posted_days_max": 5, "applicants_min": 20, "applicants_max": 120,
		"in_person": false, "doubt_hp": 118, "tier_difficulty": 40, "needle_speed": 0.60,
		"zone_jumps": true,
		"salary_min_k": 50, "salary_max_k": 70, "office_days": 0,
		"meeting_load": 0.2, "layoff_risk": 0.3, "growth_mult": 1.5,
	},
	"mid": {
		"base_invite": 0.065, "ghost_job_rate": 0.10, "silent_share": 0.30, "reply_delay_days": 2,
		"posted_days_min": 1, "posted_days_max": 14, "applicants_min": 150, "applicants_max": 500,
		"in_person": true, "doubt_hp": 128, "tier_difficulty": 42, "needle_speed": 0.60,
		"zone_jumps": false,
		"salary_min_k": 65, "salary_max_k": 90, "office_days": 2,
		"meeting_load": 0.5, "layoff_risk": 0.1, "growth_mult": 1.0,
	},
	"big": {
		"base_invite": 0.03, "ghost_job_rate": 0.20, "silent_share": 0.50, "reply_delay_days": 3,
		"posted_days_min": 1, "posted_days_max": 30, "applicants_min": 1500, "applicants_max": 3000,
		"in_person": true, "doubt_hp": 132, "tier_difficulty": 44, "needle_speed": 0.75,
		"zone_jumps": false,
		"salary_min_k": 95, "salary_max_k": 125, "office_days": 4,
		"meeting_load": 0.8, "layoff_risk": 0.2, "growth_mult": 0.8,
	},
}

## GDD 11, owner BG: one column per file (ARCHITECTURE 6.2 table).
const BACKGROUNDS: Dictionary = {
	"intern": {
		"start_knw": 50, "start_exp": 40, "start_net": 45,
		"teamwork_mult": 1.25, "teamwork_mult_after_network": 1.25, "gap_topics_count": 0,
		"commute_pips": 1, "commute_minutes": 20, "runway_days": 15, "interview_travel_pips": 0,
		"invite_mult_big": 1.0, "invite_mult_mid": 1.0, "invite_mult_startup": 0.8,
		"referral_tokens": 2, "pity_n": 6, "has_degree_honest": true, "years_pass_honest": true,
		"composure_max": 100, "startup_exp_bonus": 0, "textbook_zone_bonus": 0.0, "salary_mult": 1.10,
		"start_savings_months": 0.5,
	},
	"graduate": {
		"start_knw": 55, "start_exp": 15, "start_net": 15,
		"teamwork_mult": 1.0, "teamwork_mult_after_network": 1.0, "gap_topics_count": 0,
		"commute_pips": 2, "commute_minutes": 45, "runway_days": 12, "interview_travel_pips": 0,
		"invite_mult_big": 1.2, "invite_mult_mid": 1.0, "invite_mult_startup": 1.0,
		"referral_tokens": 0, "pity_n": 8, "has_degree_honest": true, "years_pass_honest": false,
		"composure_max": 100, "startup_exp_bonus": 0, "textbook_zone_bonus": 0.04, "salary_mult": 1.00,
		"start_savings_months": 0.4,
	},
	"self_taught": {
		"start_knw": 55, "start_exp": 10, "start_net": 5,
		"teamwork_mult": 0.6, "teamwork_mult_after_network": 1.0, "gap_topics_count": 2,
		"commute_pips": 4, "commute_minutes": 95, "runway_days": 12, "interview_travel_pips": 1,
		"invite_mult_big": 1.0, "invite_mult_mid": 1.0, "invite_mult_startup": 1.3,
		"referral_tokens": 0, "pity_n": 10, "has_degree_honest": false, "years_pass_honest": false,
		"composure_max": 90, "startup_exp_bonus": 5, "textbook_zone_bonus": 0.0, "salary_mult": 0.90,
		"start_savings_months": 0.4,
	},
}


## GDD 11.7, owner W (one file). Packed arrays run level / home / Hours-notch order, as the GDD tables do. Three values are
## STEP-14's first tuning (DECISIONS A74): the .tres holds them, the script defaults keep the Run Spec numbers.
var work_expected: Dictionary = {
	# Clock (5.14)
	"days_per_month": 30, "days_per_year": 360, "speeds": PackedInt32Array([1, 2, 4]), "calendar_days": 60,
	"legacy_day": 2160,
	# Money (5.15)
	"rent_day": 1, "payday": 25, "living_cost_k": 1.2, "living_cost_growth": 0.06, "living_cost_growth_days": 180,
	"lease_raise": 0.10, "lease_days": 360, "raise_meets": 0.01, "raise_exceeds": 0.03, "plan_b_days": 30,
	"runway_red_months": 2.0, "salary_base_k": PackedFloat64Array([3.0, 4.2, 6.0]), "resume_gap_offer_cut": 0.10,
	"home_rent_k": PackedFloat64Array([0.9, 1.5, 2.4, 4.0]),
	"home_recovery": PackedFloat64Array([0.0, 0.10, 0.25, 0.35]), "move_cost_months": 1.0, "start_home": 0,
	"run1_pay_days_accrued": 5, "run1_company": "co_pivotly", "run1_archetype": "startup", "run1_remote": false,
	# Work stats (5.16)
	"burnout_max": 100.0, "stat_max": 100.0, "mo_min": -100.0, "mo_max": 100.0, "skill_per_ticket": 2.0,
	"rust_per_day": 0.1, "ticket_size_days": PackedInt32Array([10, 20, 35]), "ticket_deadline_mult": 1.5,
	"hours_speed": PackedFloat64Array([0.6, 0.8, 1.0, 1.25, 1.5]),
	"hours_burnout": PackedFloat64Array([-0.6, -0.3, 0.1, 0.5, 1.0]),
	"hours_mo": PackedFloat64Array([-0.15, -0.05, 0.0, 0.05, 0.10]), "hours_default": 3, "skill_speed_div": 200.0,
	"codebase_speed_div": 200.0, "codebase_burnout_min": 70.0, "codebase_burnout": 0.2, "low_runway_burnout": 0.4,
	"incident_base": 0.002, "incident_per_codebase": 0.0006, "mo_on_time": 5.0, "mo_late": -5.0,
	# The review (5.16)
	"review_prompts": 3, "evidence_base": 50.0, "evidence_mo_div": 2.0, "evidence_per_ticket": 5.0,
	"rating_below_max": 0.25, "rating_exceeds_min": 0.70, "pip_days": 60, "pip_mo_min": 0.0,
	"review_standin_damage": 0.37, "review_standin_noise": 0.20,
	# Controls (5.17)
	"pick_feature_mo": 6.0, "pick_feature_codebase": 3.0, "pick_bugfix_skill": 3.0, "pick_bugfix_codebase": -2.0,
	"pick_paydown_codebase": -15.0, "pick_paydown_mo": 0.0, "push_back_deadline": 0.30, "push_back_mo": -3.0,
	"quality_clean_codebase": -0.05, "quality_clean_speed": 0.85, "quality_fast_codebase": 0.12,
	"quality_fast_speed": 1.2, "fast_blame_days": 30, "calendar_tax": 0.85,
	# Archetypes and floors (5.18, 6.1)
	"floor_event_step": 0.15, "floor_doubt_step": 0.16, "floor_salary_step": 0.04, "max_jobs": 5,
	"coworker_level_weights": PackedFloat64Array([0.35, 0.40, 0.25]), "coworker_salary_noise": 0.05,
	"coworker_rapport_start": 50.0,
	# Events (5.19)
	"auto_resolve_from": 75.0, "auto_resolve_base": 70.0, "auto_resolve_span": 30.0,
	"burnout_warnings": PackedFloat64Array([60.0, 70.0, 75.0]), "burnout_warning_rearm": 10.0,
	"layoff_salary_weight": 0.8, "layoff_luck_weight": 0.2, "layoff_min_cut": 1, "final_threat_mult": 3.0,
	"rumor_lead_days_min": 10, "rumor_lead_days_max": 30,
	# The job hunt (5.20)
	"board_size": 4, "board_refresh_days": 14, "apply_burnout_employed": 3.0, "apply_burnout_unemployed": 2.0,
	"reply_days_min": 3, "reply_days_max": 10, "notice_p": 0.05, "notice_mo": -10.0, "callback_base": 0.35,
	"callback_level_same": 1.0, "callback_level_up": 0.5, "callback_level_down": 0.8, "callback_short_tenure_cut": 0.15,
	"callback_reference_bonus": 0.10, "interview_days_min": 3, "interview_days_max": 7, "study_burnout": 4.0,
	"study_rust": -20.0, "study_skill": 1.0, "studies_prevent_gap": 3,
	"posting_level_weights": PackedFloat64Array([0.15, 0.60, 0.25]), "clause_remote_in_writing_p": 0.30,
	"clause_on_call_p": 0.25, "clause_unlimited_pto_p": 0.20, "duel_composure_burnout_div": 200.0,
	"duel_zone_skill_div": 200.0, "duel_zone_rust_div": 200.0, "reference_rapport": 60.0,
	# Scars and forced leave (5.21)
	"scar_max_stacks": 3, "short_tenure_days": 180, "short_tenure_clear_days": 360, "burnout_history_floor": 15.0,
	"burnout_history_clear_days": 120, "burnout_history_calm": 30.0, "bad_reference_mo": -20.0,
	"bad_reference_quit_mo": -30.0, "resume_gap_days": 60, "corner_cutter_leave_codebase": 80.0,
	"corner_cutter_codebase": 15.0, "corner_cutter_clear_codebase": 40.0, "forced_leave_days": 30,
	"forced_leave_pay": 0.5, "forced_leave_burnout": 50.0,
	# The Studio and the Handbook (3.4, 5.21)
	"studio_days": 90, "studio_burnout_max": 30.0, "studio_runway_months": 6.0, "studio_home": 2,
	"edge_emergency_months": 1.0, "edge_brag_evidence": 10.0, "edge_take_call_postings": 1,
	"edge_overtime_burnout_mult": 0.9,
}

## GDD 11.7, owner A: one column per file (the three archetypes, MC-05: ids startup, agency, megacorp).
var archetype_expected: Dictionary = {
	"startup": {
		"duel_tier": &"startup", "duels_per_offer": 1, "remote_share": 0.60, "board_weight": 1.0,
		"company_ids": PackedStringArray(["co_pivotly", "co_synergai", "co_quantumleaf", "co_stealth"]),
		"pay_mult": 0.85, "severance_options": PackedFloat64Array([0.0, 0.5, 1.0]), "severance_per_year": 0.0,
		"leave_level_drop": 0, "codebase_start": 20.0, "codebase_drift": 0.08, "ticket_speed": 1.0,
		"utilization_mo": 0.0, "floor_size": 8, "review_cadence_days": 180, "calibration_hp": 60.0,
		"promotion_min_rating": 2, "promotion_streak": 1, "layoff_share": 0.20, "layoff_interval_days": 270,
		"layoff_jitter_days": 60, "rto_after_days": 360,
	},
	"agency": {
		"duel_tier": &"mid", "duels_per_offer": 1, "remote_share": 0.10, "board_weight": 1.0,
		"company_ids": PackedStringArray(["co_outsourcery", "co_pixelpivot", "co_beigeware", "co_bytebistro"]),
		"pay_mult": 0.80, "severance_options": PackedFloat64Array([0.5]), "severance_per_year": 0.0,
		"leave_level_drop": 1, "codebase_start": 55.0, "codebase_drift": 0.03, "ticket_speed": 1.0,
		"utilization_mo": -0.2, "floor_size": 12, "review_cadence_days": 120, "calibration_hp": 50.0,
		"promotion_min_rating": 1, "promotion_streak": 1, "layoff_share": 0.15, "layoff_interval_days": 300,
		"layoff_jitter_days": 60, "rto_after_days": -1,
	},
	"megacorp": {
		"duel_tier": &"big", "duels_per_offer": 2, "remote_share": 0.25, "board_weight": 1.0,
		"company_ids": PackedStringArray(["co_monolith", "co_omniglobal", "co_nimbus", "co_adverse"]),
		"pay_mult": 1.25, "severance_options": PackedFloat64Array([0.0]), "severance_per_year": 2.0,
		"leave_level_drop": 0, "codebase_start": 40.0, "codebase_drift": 0.04, "ticket_speed": 0.67,
		"utilization_mo": 0.0, "floor_size": 24, "review_cadence_days": 180, "calibration_hp": 80.0,
		"promotion_min_rating": 2, "promotion_streak": 2, "layoff_share": 0.10, "layoff_interval_days": 360,
		"layoff_jitter_days": 60, "rto_after_days": 0,
	},
}

func suite_name() -> String:
	return "data_files"


func test_balance_config_matches_gdd() -> void:
	var cfg := load(BALANCE_PATH) as BalanceConfig
	assert_true(cfg != null, "%s must load as a BalanceConfig" % BALANCE_PATH)
	if cfg == null:
		return
	_check_all(cfg, balance_expected, "balance_config")


func test_tiers_match_gdd() -> void:
	assert_eq(_tres_ids(TIER_DIR), ["big", "mid", "startup"], "data/tiers/ holds exactly the 3 tiers")
	for id: String in TIERS:
		var tier := load(TIER_DIR + id + ".tres") as TierData
		assert_true(tier != null, "%s.tres must load as a TierData" % id)
		if tier == null:
			return
		assert_eq(tier.id, StringName(id), "%s.tres: id == file name" % id)
		_check_all(tier, TIERS[id], id)


func test_backgrounds_match_gdd() -> void:
	assert_eq(_tres_ids(BG_DIR), ["graduate", "intern", "self_taught"], "data/backgrounds/ holds exactly the 3 backgrounds")
	for id: String in BACKGROUNDS:
		var bg := load(BG_DIR + id + ".tres") as BackgroundData
		assert_true(bg != null, "%s.tres must load as a BackgroundData" % id)
		if bg == null:
			return
		assert_eq(bg.id, StringName(id), "%s.tres: id == file name" % id)
		_check_all(bg, BACKGROUNDS[id], id)


func test_work_config_matches_gdd() -> void:
	var cfg := load(WORK_PATH) as WorkConfig
	assert_true(cfg != null, "%s must load as a WorkConfig" % WORK_PATH)
	if cfg == null:
		return
	_check_all(cfg, work_expected, "work_config")


func test_archetypes_match_gdd() -> void:
	assert_eq(_tres_ids(ARCHETYPE_DIR), ["agency", "megacorp", "startup"], "data/archetypes/ holds exactly the 3 archetypes")
	for id: String in archetype_expected:
		var arch := load(ARCHETYPE_DIR + id + ".tres") as ArchetypeData
		assert_true(arch != null, "%s.tres must load as an ArchetypeData" % id)
		if arch == null:
			return
		assert_eq(arch.id, StringName(id), "%s.tres: id == file name" % id)
		_check_all(arch, archetype_expected[id], id)
		assert_true(ResourceLoader.exists(TIER_DIR + String(arch.duel_tier) + ".tres"), "%s: duel_tier names a tier file" % id)


func test_work_derived_values() -> void:  # GDD 5.15: the Run Spec's sanity check
	var cfg := load(WORK_PATH) as WorkConfig
	var startup := load(ARCHETYPE_DIR + "startup.tres") as ArchetypeData
	assert_true(is_equal_approx(cfg.salary_base_k[0] * startup.pay_mult, 2.55), "a Startup Junior earns 2.55 k$ a month")
	assert_true(is_equal_approx(cfg.salary_base_k[0] * startup.pay_mult - cfg.home_rent_k[0] - cfg.living_cost_k, 0.45), "about 0.45 k$ spare in the Shared room")
	assert_eq(cfg.hours_speed.size(), 5, "five Hours notches")
	assert_eq(cfg.hours_burnout.size(), cfg.hours_mo.size(), "every notch has Burnout and MO values")


func test_derived_values() -> void:  # ARCHITECTURE 6.2 "Derived values": 9 / 8 / 6 energy, only Self-Taught is a lone wolf
	var cfg := load(BALANCE_PATH) as BalanceConfig
	var energy: Array[int] = []
	var lone: Array[bool] = []
	for id: String in ["intern", "graduate", "self_taught"]:
		var bg := load(BG_DIR + id + ".tres") as BackgroundData
		energy.append(cfg.energy_max - bg.commute_pips)
		lone.append(bg.teamwork_mult < bg.teamwork_mult_after_network)
	assert_eq(energy, [9, 8, 6] as Array[int])
	assert_eq(lone, [false, false, true] as Array[bool])


## Every exported field must be listed (a new field forces a GDD 11 row and a line here),
## and every listed field must hold the GDD value with the same type.
func _check_all(res: Resource, expected: Dictionary, where: String) -> void:
	for prop: Dictionary in res.get_property_list():
		var usage: int = prop["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE and prop["name"] != "id":
			assert_true(expected.has(prop["name"]), "%s: field %s has no GDD 11 value in this test" % [where, prop["name"]])
	for field: String in expected:
		var want: Variant = expected[field]
		var got: Variant = res.get(field)
		var msg := "%s.%s = %s, GDD 11 says %s" % [where, field, str(got), str(want)]
		assert_eq(typeof(got), typeof(want), msg + " (type)")
		if want is float:
			assert_true(is_equal_approx(got, want), msg)
		else:
			assert_eq(got, want, msg)


func _tres_ids(dir: String) -> Array[String]:
	var ids: Array[String] = []
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres"):
			ids.append(file.get_basename())
	ids.sort()
	return ids

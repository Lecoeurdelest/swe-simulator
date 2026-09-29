@tool
extends McpTestSuite
## The 7 tuning .tres files (ARCHITECTURE 6.2) hold exactly the GDD section 11 defaults.
## Changing a value in a .tres (or a script default) means updating GDD 11 and this test in the
## same commit, so every tuning change is a conscious one. Loads res:// files only (no autoloads).

const BALANCE_PATH := "res://data/balance/balance_config.tres"
const TIER_DIR := "res://data/tiers/"
const BG_DIR := "res://data/backgrounds/"

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
	"input_lock_ms": 250, "vs_duration_s": 2.0, "vs_min_view_s": 1.0, "typewriter_cps": 40.0,
	# 11.6 Offer and endings
	"band_base": 0.25, "band_perf_weight": 0.50, "salary_round": 1000,
	"nego_base": 0.55, "nego_net_div": 200.0, "nego_leverage": 0.15, "nego_cap": 0.85,
	"nego_gain_min": 0.05, "nego_gain_max": 0.08, "dream_salary_target": 150000,
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
	},
	"graduate": {
		"start_knw": 55, "start_exp": 15, "start_net": 15,
		"teamwork_mult": 1.0, "teamwork_mult_after_network": 1.0, "gap_topics_count": 0,
		"commute_pips": 2, "commute_minutes": 45, "runway_days": 12, "interview_travel_pips": 0,
		"invite_mult_big": 1.2, "invite_mult_mid": 1.0, "invite_mult_startup": 1.0,
		"referral_tokens": 0, "pity_n": 8, "has_degree_honest": true, "years_pass_honest": false,
		"composure_max": 100, "startup_exp_bonus": 0, "textbook_zone_bonus": 0.04, "salary_mult": 1.00,
	},
	"self_taught": {
		"start_knw": 55, "start_exp": 10, "start_net": 5,
		"teamwork_mult": 0.6, "teamwork_mult_after_network": 1.0, "gap_topics_count": 2,
		"commute_pips": 4, "commute_minutes": 95, "runway_days": 12, "interview_travel_pips": 1,
		"invite_mult_big": 1.0, "invite_mult_mid": 1.0, "invite_mult_startup": 1.3,
		"referral_tokens": 0, "pity_n": 10, "has_degree_honest": false, "years_pass_honest": false,
		"composure_max": 90, "startup_exp_bonus": 5, "textbook_zone_bonus": 0.0, "salary_mult": 0.90,
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

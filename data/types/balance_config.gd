@tool
class_name BalanceConfig
extends Resource
## Global tuning constants (GDD section 11, owner "B"). One file: res://data/balance/balance_config.tres.
## These defaults ARE the GDD defaults. Tune the .tres in the Inspector; leave these lines alone
## (the formula tests build BalanceConfig.new() and expect the GDD numbers).

@export_group("Energy, time, board (11.1)")
@export var energy_max: int = 10
@export var rent_warning_days: int = 3
@export var cost_quick_apply: int = 1
@export var cost_tailor_apply: int = 2
@export var cost_research: int = 1
@export var cost_study: int = 2
@export var cost_network: int = 2
@export var cost_interview: int = 3
@export var tired_threshold: int = 2
@export var tired_needle_mult: float = 1.15
@export var max_interviews_per_day: int = 1
@export var invite_valid_days: int = 2
@export var board_new_per_day: int = 6
@export var board_max: int = 10
@export var ghost_posted_days_min: int = 60
@export var ghost_posted_days_max: int = 500
@export var full_scan_animations: int = 3

@export_group("Stats and growth (11.2)")
@export var stat_cap: int = 80
@export var study_knw_gain: int = 5
@export var network_net_gain: int = 5
@export var network_ref_base: float = 0.35
@export var network_ref_net_div: float = 200.0

@export_group("Applications and responses (11.3)")
@export var match_base: float = 0.5
@export var quick_apply_mult: float = 0.6
@export var tailor_apply_mult: float = 1.5
@export var referral_mult: float = 2.5
@export var net_divisor: float = 100.0
@export var p_invite_min: float = 0.01
@export var p_invite_max: float = 0.60
@export var relevant_min_tags: int = 2
@export var knockout_reply_delay_days: int = 1
@export var ghosted_after_days: int = 7
@export var day2_guarantee_min_apps: int = 3
@export var band_thresholds: PackedFloat32Array = PackedFloat32Array([0.03, 0.07, 0.12, 0.20])
@export var site_megaboard_ghost_add: float = 0.05
@export var site_humblebrag_invite_mult: float = 1.1

@export_group("Interview (11.4)")
@export var prompt_pattern: PackedStringArray = PackedStringArray(["choice", "knowledge", "knowledge", "knowledge", "choice"])
@export var question_diff_offsets: PackedInt32Array = PackedInt32Array([-5, 0, 5])
@export var stat_sensitivity: float = 0.7
@export var luck_range: float = 12.0
@export var weak_penalty: float = 15.0
@export var tech_knw_w: float = 0.7
@export var tech_exp_w: float = 0.3
@export var behav_knw_w: float = 0.3
@export var behav_exp_w: float = 0.7
@export var zone_half_base: float = 0.06
@export var zone_half_per_s: float = 0.12
@export var perfect_frac: float = 0.4
@export var close_mult: float = 2.0
@export var input_perfect: float = 1.0
@export var input_good: float = 0.8
@export var input_close: float = 0.5
@export var input_miss: float = 0.2
@export var relaxed_input: float = 0.9
@export var q_stat_weight: float = 0.75
@export var q_input_scale: float = 25.0
@export var jump_window_min_s: float = 1.0
@export var jump_window_max_s: float = 2.5
@export var max_round_trips: int = 3
@export var answer_meter_width_px: int = 200
@export var doubt_dmg_scale: float = 0.9
@export var doubt_dmg_floor: float = 30.0
@export var comp_dmg_ceiling: float = 50.0
@export var green_q_min: float = 60.0
@export var yellow_q_min: float = 45.0
@export var ethics_good: float = -10.0        # Doubt change (negative = Doubt goes down = good for you)
@export var ethics_neutral: float = -4.0
@export var ethics_bad_doubt: float = 8.0
@export var ethics_bad_comp: float = 15.0     # Composure lost
@export var insider_why_us: float = -18.0
@export var committee_band: float = 0.15
@export var committee_base: float = 0.40
@export var committee_close_bonus: float = 0.20
@export var committee_net_div: float = 200.0
@export var committee_cap: float = 0.85
@export var input_lock_ms: int = 250
@export var vs_duration_s: float = 2.0
@export var typewriter_cps: float = 40.0

@export_group("Offer and endings (11.6)")
@export var band_base: float = 0.25
@export var band_perf_weight: float = 0.50
@export var salary_round: int = 1000
@export var nego_base: float = 0.55
@export var nego_net_div: float = 200.0
@export var nego_leverage: float = 0.15
@export var nego_cap: float = 0.85
@export var nego_gain_min: float = 0.05
@export var nego_gain_max: float = 0.08
@export var dream_salary_target: int = 150000
@export var dream_w_salary: float = 40.0      # GDD "dream_weights" 40 / 25 / 15 / 10 / 10
@export var dream_w_remote: float = 25.0
@export var dream_w_commute: float = 15.0
@export var dream_w_flags: float = 10.0
@export var dream_w_runway: float = 10.0
@export var dream_commute_zero_h: float = 10.0
@export var dream_flag_penalty: float = 5.0
@export var grace_day: bool = true

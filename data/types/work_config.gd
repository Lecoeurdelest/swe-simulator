@tool
class_name WorkConfig
extends Resource
## The career run's global constants (GDD section 11.7, owner "W"). One file: res://data/work/work_config.tres.
## These defaults are the Run Spec's numbers (and my gap-fills, DECISIONS A63-A73). The .tres holds the tuned ones: three
## differ after STEP-14's first tuning (DECISIONS A74; GDD 11.7 lists both). Tune the .tres, leave these lines alone (the
## sim tests build WorkConfig.new() and expect the Run Spec's worked examples). Per-archetype numbers live in
## ArchetypeData, an event's own numbers in data/content/work_events.json (DECISIONS A54).
## Level arrays run junior, mid, senior; home arrays run shared room, one-bed, studio, penthouse;
## notch arrays run Hours notch 1 to 5.

@export_group("Clock (5.14)")
@export var days_per_month: int = 30
@export var days_per_year: int = 360
@export var speeds: PackedInt32Array = PackedInt32Array([1, 2, 4])
@export var calendar_days: int = 60
@export var legacy_day: int = 2160

@export_group("Money (5.15)")
@export var rent_day: int = 1
@export var payday: int = 25
@export var living_cost_k: float = 1.2
@export var living_cost_growth: float = 0.06
@export var living_cost_growth_days: int = 180
@export var lease_raise: float = 0.10
@export var lease_days: int = 360
@export var raise_meets: float = 0.01
@export var raise_exceeds: float = 0.03
@export var plan_b_days: int = 30
@export var runway_red_months: float = 2.0
@export var salary_base_k: PackedFloat64Array = PackedFloat64Array([3.0, 4.2, 6.0])
@export var resume_gap_offer_cut: float = 0.10
@export var home_rent_k: PackedFloat64Array = PackedFloat64Array([0.9, 1.5, 2.4, 4.0])
@export var home_recovery: PackedFloat64Array = PackedFloat64Array([0.0, 0.10, 0.25, 0.35])
@export var move_cost_months: float = 1.0
@export var start_home: int = 0
@export var run1_pay_days_accrued: int = 5
@export var run1_company: String = "co_synergai"
@export var run1_archetype: String = "startup"
@export var run1_remote: bool = false

@export_group("Work stats (5.16)")
@export var burnout_max: float = 100.0
@export var stat_max: float = 100.0
@export var mo_min: float = -100.0
@export var mo_max: float = 100.0
@export var skill_per_ticket: float = 2.0
@export var rust_per_day: float = 0.1
@export var ticket_size_days: PackedInt32Array = PackedInt32Array([10, 20, 35])
@export var ticket_deadline_mult: float = 1.0
@export var hours_speed: PackedFloat64Array = PackedFloat64Array([0.6, 0.8, 1.0, 1.25, 1.5])
@export var hours_burnout: PackedFloat64Array = PackedFloat64Array([-0.6, -0.3, 0.1, 0.5, 1.0])
@export var hours_mo: PackedFloat64Array = PackedFloat64Array([-0.15, -0.05, 0.0, 0.05, 0.10])
@export var hours_default: int = 3
@export var skill_speed_div: float = 200.0
@export var codebase_speed_div: float = 200.0
@export var codebase_burnout_min: float = 70.0
@export var codebase_burnout: float = 0.2
@export var low_runway_burnout: float = 0.4
@export var incident_base: float = 0.002
@export var incident_per_codebase: float = 0.0006
@export var mo_on_time: float = 5.0
@export var mo_late: float = -5.0

@export_group("The review (5.16)")
@export var review_prompts: int = 3
@export var evidence_base: float = 50.0
@export var evidence_mo_div: float = 2.0
@export var evidence_per_ticket: float = 5.0
@export var rating_below_max: float = 0.25
@export var rating_exceeds_min: float = 0.70
@export var pip_days: int = 60
@export var pip_mo_min: float = 0.0
@export var review_standin_damage: float = 0.55
@export var review_standin_noise: float = 0.20
@export var review_hit_good: float = 0.4          # the review duel (D-39, A94): a good answer takes this share of the manager's chip,
@export var review_hit_okay: float = 1.0          # an okay one takes all of it,
@export var review_hit_joke: float = 1.8          # and a joke nearly doubles it

@export_group("Controls (5.17)")
@export var pick_feature_mo: float = 6.0
@export var pick_feature_codebase: float = 3.0
@export var pick_bugfix_skill: float = 3.0
@export var pick_bugfix_codebase: float = -2.0
@export var pick_paydown_codebase: float = -15.0
@export var pick_paydown_mo: float = 0.0
@export var push_back_deadline: float = 0.30
@export var push_back_mo: float = -3.0
@export var quality_clean_codebase: float = -0.05
@export var quality_clean_speed: float = 0.85
@export var quality_fast_codebase: float = 0.12
@export var quality_fast_speed: float = 1.2
@export var fast_blame_days: int = 30
@export var calendar_tax: float = 0.85

@export_group("Archetypes and floors (5.18, 6.1)")
@export var floor_event_step: float = 0.15
@export var floor_doubt_step: float = 0.08
@export var floor_salary_step: float = 0.04
@export var max_jobs: int = 5
@export var coworker_level_weights: PackedFloat64Array = PackedFloat64Array([0.35, 0.40, 0.25])
@export var coworker_salary_noise: float = 0.05
@export var coworker_rapport_start: float = 50.0

@export_group("Events (5.19)")
@export var auto_resolve_from: float = 75.0
@export var auto_resolve_base: float = 70.0
@export var auto_resolve_span: float = 30.0
@export var burnout_warnings: PackedFloat64Array = PackedFloat64Array([60.0, 70.0, 75.0])
@export var burnout_warning_rearm: float = 10.0
@export var layoff_salary_weight: float = 0.8
@export var layoff_luck_weight: float = 0.2
@export var layoff_min_cut: int = 1
@export var final_threat_mult: float = 3.0
@export var rumor_lead_days_min: int = 10
@export var rumor_lead_days_max: int = 30

@export_group("The job hunt (5.20)")
@export var board_size: int = 4
@export var board_refresh_days: int = 14
@export var apply_burnout_employed: float = 3.0
@export var apply_burnout_unemployed: float = 2.0
@export var reply_days_min: int = 3
@export var reply_days_max: int = 10
@export var notice_p: float = 0.05
@export var notice_mo: float = -10.0
@export var callback_base: float = 0.35
@export var callback_level_same: float = 1.0
@export var callback_level_up: float = 0.5
@export var callback_level_down: float = 0.8
@export var callback_short_tenure_cut: float = 0.15
@export var callback_reference_bonus: float = 0.10
@export var callback_band_steps: PackedFloat64Array = PackedFloat64Array([0.10, 0.20, 0.30, 0.40])   # the 5-dot band's thresholds (A90)
@export var interview_days_min: int = 3
@export var interview_days_max: int = 7
@export var study_burnout: float = 4.0
@export var study_rust: float = -20.0
@export var study_skill: float = 1.0
@export var studies_prevent_gap: int = 3
@export var posting_level_weights: PackedFloat64Array = PackedFloat64Array([0.15, 0.60, 0.25])
@export var clause_remote_in_writing_p: float = 0.30
@export var clause_on_call_p: float = 0.25
@export var clause_unlimited_pto_p: float = 0.20
@export var duel_composure_burnout_div: float = 200.0
@export var duel_zone_skill_div: float = 200.0
@export var duel_zone_rust_div: float = 200.0
@export var reference_rapport: float = 60.0

@export_group("Scars and forced leave (5.21)")
@export var scar_max_stacks: int = 3
@export var short_tenure_days: int = 180
@export var short_tenure_clear_days: int = 360
@export var burnout_history_floor: float = 15.0
@export var burnout_history_clear_days: int = 120
@export var burnout_history_calm: float = 30.0
@export var bad_reference_mo: float = -20.0
@export var bad_reference_quit_mo: float = -30.0
@export var resume_gap_days: int = 60
@export var corner_cutter_leave_codebase: float = 80.0
@export var corner_cutter_codebase: float = 15.0
@export var corner_cutter_clear_codebase: float = 40.0
@export var forced_leave_days: int = 30
@export var forced_leave_pay: float = 0.5
@export var forced_leave_burnout: float = 50.0

@export_group("The Studio and the Handbook (3.4, 5.21)")
@export var studio_days: int = 90
@export var studio_burnout_max: float = 30.0
@export var studio_runway_months: float = 6.0
@export var studio_home: int = 2
@export var edge_emergency_months: float = 1.0
@export var edge_brag_evidence: float = 10.0
@export var edge_take_call_postings: int = 1
@export var edge_overtime_burnout_mult: float = 0.9

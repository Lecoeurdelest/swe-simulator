@tool
class_name BackgroundData
extends Resource
## One playable background = one difficulty (GDD section 11, owner "BG").
## Files: res://data/backgrounds/intern.tres, graduate.tres, self_taught.tres.
## Script defaults = the Graduate values. Text lives in data/content/backgrounds.json.

@export var id: StringName = &""              # intern | graduate | self_taught (== file name)

@export_group("Stats")
@export var start_knw: int = 55
@export var start_exp: int = 15
@export var start_net: int = 15
@export var teamwork_mult: float = 1.0
@export var teamwork_mult_after_network: float = 1.0
@export var gap_topics_count: int = 0

@export_group("Day loop")
@export var commute_pips: int = 2
@export var commute_minutes: int = 45
@export var runway_days: int = 12
@export var interview_travel_pips: int = 0

@export_group("Applications")
@export var invite_mult_big: float = 1.2
@export var invite_mult_mid: float = 1.0
@export var invite_mult_startup: float = 1.0
@export var referral_tokens: int = 0
@export var pity_n: int = 8
@export var has_degree_honest: bool = true   # must match cv_lines.json (content_lint checks it)
@export var years_pass_honest: bool = false

@export_group("Interview")
@export var composure_max: int = 100
@export var startup_exp_bonus: int = 0
@export var textbook_zone_bonus: float = 0.04

@export_group("Offer")
@export var salary_mult: float = 1.0

@export_group("Career run (11.7)")
@export var start_savings_months: float = 0.4   # months of expenses: Phase 1's runway_days / 30 (A68)


func invite_mult(tier_id: StringName) -> float:
	match tier_id:
		&"big":
			return invite_mult_big
		&"startup":
			return invite_mult_startup
	return invite_mult_mid

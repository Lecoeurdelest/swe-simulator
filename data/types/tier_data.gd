@tool
class_name TierData
extends Resource
## One company tier (GDD section 11, owner "T"). Files: res://data/tiers/startup.tres, mid.tres, big.tres.
## All hiring odds live here. Display text lives in data/content/tiers.json under the same id.
## Script defaults = the Mid-size values. Never change a loaded TierData at runtime.

@export var id: StringName = &""              # startup | mid | big (== file name)

@export_group("Board and applications")
@export var base_invite: float = 0.065
@export var ghost_job_rate: float = 0.10
@export var silent_share: float = 0.30
@export var reply_delay_days: int = 2
@export var posted_days_min: int = 1
@export var posted_days_max: int = 14
@export var applicants_min: int = 150
@export var applicants_max: int = 500

@export_group("Interview")
@export var in_person: bool = true
@export var doubt_hp: int = 128
@export var tier_difficulty: int = 42
@export var needle_speed: float = 0.60        # bar-widths per second
@export var zone_jumps: bool = false          # startup "PIVOT!"
@export var lie_probe_chance: float = 0.45
@export var bluff_detect: float = 0.05
@export var background_check: float = 0.30

@export_group("Offer")
@export var salary_min_k: int = 65            # yearly salary, thousands of dollars
@export var salary_max_k: int = 90
@export var office_days: int = 2

@export_group("Phase 2 (stored, unused in the MVP)")
@export var meeting_load: float = 0.5
@export var layoff_risk: float = 0.1
@export var growth_mult: float = 1.0

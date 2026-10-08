@tool
class_name ArchetypeData
extends Resource
## One company archetype (GDD 5.18, 11.7, owner "A"): the rules of a job. Files: res://data/archetypes/startup.tres,
## agency.tres, megacorp.tres. Script defaults = the Agency values. Never branch on an archetype's id (INV-09):
## every difference between archetypes is a number or a field here. Text lives in data/content/.

@export var id: StringName = &""              # startup | agency | megacorp (== file name)

@export_group("Duel and board")
@export var duel_tier: StringName = &"mid"    # the Phase 1 tier whose Doubt, difficulty and questions the duel borrows (MC-05)
@export var duels_per_offer: int = 1
@export var remote_share: float = 0.10
@export var board_weight: float = 1.0         # relative share of the board's postings
@export var company_ids: PackedStringArray = PackedStringArray(["co_pixelpivot", "co_beigeware", "co_bytebistro"])

@export_group("Pay")
@export var pay_mult: float = 0.80
@export var severance_options: PackedFloat64Array = PackedFloat64Array([0.5])   # months of salary, rolled with equal odds
@export var severance_per_year: float = 0.0   # extra months per 360 days of tenure, prorated
@export var leave_level_drop: int = 1         # levels lost on leaving (title inflation)

@export_group("The job")
@export var codebase_start: float = 55.0
@export var codebase_drift: float = 0.03
@export var ticket_speed: float = 1.0
@export var utilization_mo: float = -0.2      # MO a day at Hours notches 1-2
@export var floor_size: int = 12              # employees in the layoff pool, you included

@export_group("The review")
@export var review_cadence_days: int = 120
@export var calibration_hp: float = 50.0
@export var promotion_min_rating: int = 1     # 1 = Meets, 2 = Exceeds
@export var promotion_streak: int = 1         # consecutive reviews at that rating

@export_group("Layoffs and the return-to-office memo")
@export var layoff_share: float = 0.15        # of the floor, per resizing
@export var layoff_interval_days: int = 300   # days from a job's start (or the last resizing) to the next
@export var layoff_jitter_days: int = 60      # rolled between -jitter and +jitter
@export var rto_after_days: int = -1          # E08 can fire once tenure reaches this; -1 never

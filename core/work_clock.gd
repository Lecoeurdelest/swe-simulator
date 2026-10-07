@tool
class_name WorkClock
extends RefCounted
## The work state's clock (GDD 5.14, DECISIONS D-01, D-13; INV-22): frame time in, whole days out. Pause is 0 days a
## second; 1x, 2x and 4x are WorkConfig.speeds (days per second). It never reads the wall clock: the scene hands it
## its frame delta, and only while nothing is open over the work state (a card, an app, Pause). It rules nothing;
## Sim.step does, one call per day.

## One hitch (a dropped frame, the editor stalling) must never fast-forward a month.
const MAX_DAYS_PER_FRAME := 4
const PAUSE := 0

## 0 is Pause; 1.. picks WorkConfig.speeds[speed - 1].
var speed: int = PAUSE
var _carry: float = 0.0


## The speed control's position count: Pause plus one per WorkConfig speed.
static func speed_count(cfg: WorkConfig) -> int:
	return cfg.speeds.size() + 1


## Days per second at this position (0 for Pause or an unknown position).
func days_per_second(cfg: WorkConfig) -> float:
	if speed <= PAUSE or speed > cfg.speeds.size():
		return 0.0
	return float(cfg.speeds[speed - 1])


func set_speed(position: int, cfg: WorkConfig) -> void:
	speed = clampi(position, PAUSE, cfg.speeds.size())
	_carry = 0.0


func is_running() -> bool:
	return speed > PAUSE


## The whole days to run for this frame. The fraction carries to the next frame, so 1x is one day a second on
## average whatever the frame rate; at most MAX_DAYS_PER_FRAME come out at once.
func advance(cfg: WorkConfig, delta: float) -> int:
	var rate := days_per_second(cfg)
	if rate <= 0.0 or delta <= 0.0:
		return 0
	_carry += delta * rate
	var whole := int(_carry)
	_carry -= float(whole)   # only the fraction carries: the days over the cap are dropped, not queued
	return mini(whole, MAX_DAYS_PER_FRAME)


## A card, an app or Pause opened: the half-built day is thrown away, so the clock restarts from zero when it comes back.
func hold() -> void:
	_carry = 0.0

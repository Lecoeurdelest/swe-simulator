@tool
extends McpTestSuite
## The work state's clock (GDD 5.14, DECISIONS D-01, D-13; INV-22): frame time in, whole days out. Editor-side: no autoloads.

var cfg: WorkConfig = WorkConfig.new()   # the Run Spec's speeds: 1, 2 and 4 days a second


func suite_name() -> String:
	return "work_clock"


func test_pause_never_runs_a_day() -> void:
	var clock := WorkClock.new()
	assert_false(clock.is_running(), "a new clock waits")
	assert_eq(clock.advance(cfg, 10.0), 0, "ten seconds of Pause")
	assert_eq(clock.days_per_second(cfg), 0.0)


func test_one_x_is_a_day_a_second_whatever_the_frame_rate() -> void:
	var clock := WorkClock.new()
	clock.set_speed(1, cfg)
	assert_true(clock.is_running())
	assert_eq(clock.advance(cfg, 1.0), 1, "one second, one day")
	var days := 0
	for i: int in 120:   # two seconds of 60 fps frames
		days += clock.advance(cfg, 1.0 / 60.0)
	assert_eq(days, 2, "120 frames of 1/60 s are two days")


func test_two_x_and_four_x_follow_the_speeds() -> void:
	var clock := WorkClock.new()
	clock.set_speed(2, cfg)
	assert_eq(clock.days_per_second(cfg), 2.0)
	assert_eq(clock.advance(cfg, 0.5), 1, "half a second at 2x")
	clock.set_speed(3, cfg)
	assert_eq(clock.days_per_second(cfg), 4.0)
	assert_eq(clock.advance(cfg, 0.25), 1, "a quarter of a second at 4x")


func test_a_hitch_never_fast_forwards_a_month() -> void:
	var clock := WorkClock.new()
	clock.set_speed(3, cfg)
	assert_eq(clock.advance(cfg, 5.0), WorkClock.MAX_DAYS_PER_FRAME, "20 days of stall come out as the cap")
	assert_eq(clock.advance(cfg, 0.0), 0, "and nothing is owed afterwards")
	clock.set_speed(1, cfg)
	assert_eq(clock.advance(cfg, 0.3), 0, "the dropped days left no backlog")


func test_hold_throws_away_the_half_built_day() -> void:
	var clock := WorkClock.new()
	clock.set_speed(1, cfg)
	assert_eq(clock.advance(cfg, 0.9), 0)
	clock.hold()   # a card opened
	assert_eq(clock.advance(cfg, 0.2), 0, "the 0.9 s before the card does not count")
	assert_eq(clock.advance(cfg, 0.8), 1, "a full second after it does")


func test_the_speed_position_is_clamped_and_counted() -> void:
	var clock := WorkClock.new()
	assert_eq(WorkClock.speed_count(cfg), 4, "Pause, 1x, 2x, 4x")
	clock.set_speed(99, cfg)
	assert_eq(clock.speed, 3, "past the last speed means the last")
	clock.set_speed(-5, cfg)
	assert_eq(clock.speed, WorkClock.PAUSE, "below Pause means Pause")

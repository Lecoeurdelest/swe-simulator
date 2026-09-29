@tool
extends McpTestSuite
## The two bar components (ARCHITECTURE 11.3, 11.6): StatBar's 5 segments (GDD 5.1) and HpBar's whole
## pixel fill and settled ghost (GDD 9.1). Pure: the bars are built out of the tree, never with
## autoloads (INV-12), so the ghost never animates here; the drain itself is checked in the running game.

const HP_WIDTH := 122.0  # GDD S08: each interview bar is 122x8


func suite_name() -> String:
	return "bars"


func test_stat_segments_are_value_over_20_rounded() -> void:
	var cases := {0: 0, 9: 0, 10: 1, 29: 1, 30: 2, 45: 2, 50: 3, 55: 3, 70: 4, 80: 4, 90: 5, 100: 5}
	for amount: int in cases:
		assert_eq(StatBar.filled_segments(amount), cases[amount], "value %d" % amount)
	assert_eq(StatBar.filled_segments(-5), 0, "clamped")
	assert_eq(StatBar.filled_segments(150), 5, "clamped")


func test_stat_bar_is_one_text_line_tall() -> void:
	var bar := track(StatBar.new()) as StatBar
	assert_eq(bar.get_combined_minimum_size(), Vector2(39, 13), "5 blocks of 7 px, 1 px apart; a 13 px monogram line")
	assert_eq(bar.mouse_filter, Control.MOUSE_FILTER_IGNORE, "display only")


func test_hp_fill_is_whole_pixels() -> void:
	assert_eq(HpBar.fill_px(60.0, 60.0, HP_WIDTH), 122, "full")
	assert_eq(HpBar.fill_px(30.0, 60.0, HP_WIDTH), 61)
	assert_eq(HpBar.fill_px(45.5, 105.5, HP_WIDTH), 53, "rounded to a whole pixel")
	assert_eq(HpBar.fill_px(0.0, 60.0, HP_WIDTH), 0, "empty")
	assert_eq(HpBar.fill_px(-4.0, 60.0, HP_WIDTH), 0, "below zero is empty")
	assert_eq(HpBar.fill_px(0.1, 120.0, HP_WIDTH), 1, "a sliver above zero still shows")
	assert_eq(HpBar.fill_px(130.0, 120.0, HP_WIDTH), 122, "clamped to the bar")
	assert_eq(HpBar.fill_px(50.0, 0.0, HP_WIDTH), 0, "no maximum yet")


func test_hp_start_settles_without_a_ghost() -> void:
	for full: float in [80.0, 100.0, 120.0]:
		var bar := track(HpBar.new()) as HpBar
		bar.max_value = full
		bar.value = full
		assert_eq(bar.ghost_value(), full, "the interview's start (max %d): nothing to drain" % full)


func test_hp_ghost_follows_the_value_when_settled() -> void:
	var bar := track(HpBar.new()) as HpBar
	bar.max_value = 100.0
	bar.value = 40.0
	assert_eq(bar.ghost_value(), 40.0, "out of the tree a drop settles at once")
	bar.value = 70.0
	assert_eq(bar.ghost_value(), 70.0, "a rise jumps")
	bar.value = -10.0
	assert_eq(bar.ghost_value(), 0.0, "clamped at 0")
	bar.value = 250.0
	assert_eq(bar.ghost_value(), 100.0, "clamped at the maximum")
	bar.max_value = 60.0
	assert_eq(bar.ghost_value(), 60.0, "a new maximum settles the bar")

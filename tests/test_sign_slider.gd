@tool
extends McpTestSuite
## Drag-to-sign (GDD S10, SHOULD-06; DECISIONS A95): the contract is signed by dragging the handle along its track and
## letting go at the end. Synthetic mouse events straight into the control (INV-14: touches arrive as mouse events).
## Editor-side: no autoloads, no user://.


func suite_name() -> String:
	return "sign_slider"


func _slider() -> SignSlider:
	var slider := SignSlider.new()
	slider.size = Vector2(168.0, 36.0)
	return slider


func _press(slider: SignSlider, x: float) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(x, 18.0)
	slider._gui_input(event)


func _release(slider: SignSlider, x: float) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = Vector2(x, 18.0)
	slider._gui_input(event)


func _drag(slider: SignSlider, to_x: float, from_x: float) -> void:
	var event := InputEventMouseMotion.new()
	event.position = Vector2(to_x, 18.0)
	event.relative = Vector2(to_x - from_x, 0.0)
	slider._gui_input(event)


## Counts how many times the slider signed.
func _counter(slider: SignSlider) -> Array[int]:
	var count: Array[int] = [0]
	slider.signed.connect(func() -> void: count[0] += 1)
	return count


func test_dragging_the_handle_to_the_end_signs() -> void:
	var slider := _slider()
	var count := _counter(slider)
	_press(slider, 10.0)
	_drag(slider, 60.0, 10.0)
	_drag(slider, 120.0, 60.0)
	_drag(slider, 160.0, 120.0)
	assert_eq(count[0], 0, "nothing is signed until you let go")
	_release(slider, 160.0)
	assert_eq(count[0], 1, "signed once, at the end of the track")
	assert_eq(slider.progress(), 1.0, "the handle stays at the end")
	slider.free()


func test_letting_go_early_springs_back() -> void:
	var slider := _slider()
	var count := _counter(slider)
	_press(slider, 10.0)
	_drag(slider, 70.0, 10.0)
	assert_true(slider.progress() > 0.3 and slider.progress() < 0.6, "the handle follows the finger: %f" % slider.progress())
	_release(slider, 70.0)
	assert_eq(count[0], 0, "a short drag signs nothing")
	assert_eq(slider.progress(), 0.0, "and the handle is back at the start")
	slider.free()


func test_the_handle_never_leaves_the_track() -> void:
	var slider := _slider()
	_press(slider, 10.0)
	_drag(slider, 900.0, 10.0)
	assert_eq(slider.progress(), 1.0, "the end of the track")
	_drag(slider, -500.0, 900.0)
	assert_eq(slider.progress(), 0.0, "and the start")
	slider.free()


func test_a_press_that_misses_the_handle_does_nothing() -> void:
	var slider := _slider()
	var count := _counter(slider)
	_press(slider, 120.0)
	_drag(slider, 160.0, 120.0)
	_release(slider, 160.0)
	assert_eq(count[0], 0, "a stray tap or swipe on the track cannot sign (it is a gesture on purpose)")
	assert_eq(slider.progress(), 0.0)
	slider.free()


func test_relaxed_timing_lets_a_tap_sign() -> void:  # GDD 2.8: the accessibility setting
	var slider := _slider()
	slider.relaxed = true
	var count := _counter(slider)
	_press(slider, 120.0)
	_release(slider, 120.0)
	assert_eq(count[0], 1, "a tap anywhere signs")
	var drag := _slider()
	drag.relaxed = true
	var drags := _counter(drag)
	_press(drag, 10.0)
	_drag(drag, 80.0, 10.0)
	_release(drag, 80.0)
	assert_eq(drags[0], 0, "a drag that stops short still springs back")
	slider.free()
	drag.free()


func test_a_disabled_slider_ignores_everything() -> void:
	var slider := _slider()
	var count := _counter(slider)
	slider.disabled = true
	_press(slider, 10.0)
	_drag(slider, 160.0, 10.0)
	_release(slider, 160.0)
	assert_eq(count[0], 0, "while the paper is rising or the answer is given")
	assert_eq(slider.progress(), 0.0)
	slider.free()


func test_the_handle_is_a_full_thumb_target() -> void:  # INV-14: hit areas of 34 px or more
	assert_true(SignSlider.HANDLE_W >= 34.0, "the handle is %f px wide" % SignSlider.HANDLE_W)

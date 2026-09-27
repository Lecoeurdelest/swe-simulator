@tool
extends McpTestSuite
## The intro's play order (CutscenePlan, GDD S02, ARCHITECTURE 11.2) on hand-made entries and on
## cutscene.json itself. Pure: the JSON is read with FileAccess, never through Content (INV-12).

const CUTSCENE_PATH := "res://data/content/cutscene.json"
const PANEL_COUNT := 6            # GDD S02: 6 still panels
const MAX_SECONDS := 40.0         # GDD S02: 40 s or less
const FRAME := Vector2(270, 480)  # GDD 2.6: an intro panel on screen


func suite_name() -> String:
	return "intro"


func test_panels_follow_order_not_ids() -> void:
	var entries := {
		"z_first": {"order": 1, "seconds": 6, "captions": [{"speaker": "", "text": "one"}]},
		"a_second": {"order": 2, "seconds": 7, "captions": [{"speaker": "Remy", "text": "two"}]},
		"m_tie_b": {"order": 3, "seconds": 1, "captions": [{"text": "four"}]},
		"m_tie_a": {"order": 3, "seconds": 1, "captions": [{"text": "three"}]},
	}
	var ids: Array = CutscenePlan.panels(entries).map(func(p: Dictionary) -> String: return p["id"])
	assert_eq(ids, ["z_first", "a_second", "m_tie_a", "m_tie_b"], "by order, ties by id")


func test_panels_skip_what_is_not_a_panel() -> void:
	var entries := {
		"_notes": "metadata",
		"ui_like": "a plain string",
		"no_order": {"seconds": 5, "captions": [{"text": "orphan"}]},
		"no_text": {"order": 1, "seconds": 5, "captions": [{"speaker": "Remy", "text": ""}, "not a caption"]},
		"kept": {"order": 2, "seconds": 5.5, "captions": [{"speaker": "Remy", "text": ""}, {"text": "hi", "style": "title"}]},
	}
	var panels := CutscenePlan.panels(entries)
	assert_eq(panels.size(), 1, "only 'kept' has an order and a caption with text")
	if panels.size() != 1:
		return
	assert_eq(panels[0]["id"], "kept")
	assert_eq(panels[0]["seconds"], 5.5)
	assert_eq(panels[0]["captions"], [{"speaker": "", "text": "hi", "style": "title"}],
		"the empty caption goes; missing fields default to empty strings")


func test_pan_path_follows_the_picture_size() -> void:
	assert_eq(CutscenePlan.pan_path(FRAME, FRAME), [Vector2.ZERO, Vector2.ZERO] as Array[Vector2],
		"a 270x480 picture stays still")
	assert_eq(CutscenePlan.pan_path(Vector2(480, 480), FRAME), [Vector2.ZERO, Vector2(-210, 0)] as Array[Vector2],
		"480x480 pans sideways across its extra 210 px (GDD 2.6)")
	assert_eq(CutscenePlan.pan_path(Vector2(270, 720), FRAME), [Vector2.ZERO, Vector2(0, -240)] as Array[Vector2],
		"270x720 tilts down across its extra 240 px (GDD 2.6)")
	assert_eq(CutscenePlan.pan_path(Vector2(294.5, 400), FRAME), [Vector2.ZERO, Vector2(-24, 0)] as Array[Vector2],
		"whole pixels, and a picture smaller than the frame never moves the other way")


func test_cutscene_json_plays_as_the_gdd_says() -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(CUTSCENE_PATH))
	assert_true(data is Dictionary, "%s must be one JSON object keyed by id" % CUTSCENE_PATH)
	if not (data is Dictionary):
		return
	var panels := CutscenePlan.panels(data)
	assert_eq(panels.size(), PANEL_COUNT, "GDD S02: 6 panels, every one with a caption")
	assert_eq(panels.size(), (data as Dictionary).size(), "every entry of cutscene.json is a panel that plays")
	var orders: Array = panels.map(func(p: Dictionary) -> int: return p["order"])
	assert_eq(orders, range(1, PANEL_COUNT + 1), "orders 1-6, no gaps, no repeats")
	assert_true(CutscenePlan.total_seconds(panels) <= MAX_SECONDS,
		"GDD S02: 40 s or less, got %.1f" % CutscenePlan.total_seconds(panels))
	var titles := 0
	for panel: Dictionary in panels:
		assert_gt(float(panel["seconds"]), 0.0, "%s needs seconds for its pan" % panel["id"])
		for caption: Dictionary in panel["captions"]:
			assert_true(caption["style"] in ["", CutscenePlan.STYLE_TITLE],
				"%s: unknown caption style '%s'" % [panel["id"], caption["style"]])
			if caption["style"] == CutscenePlan.STYLE_TITLE:
				titles += 1
	assert_eq(titles, 1, "one title card (GDD S02: title slam, then Background select)")

@tool
extends McpTestSuite
## UI text: UiText's label and money styling (GDD 4.2 mockups), and every content id the screens ask
## for. Pure: the JSON is read with FileAccess and the scripts as text, never through Content (INV-12).

const CONTENT_DIR := "res://data/content/"
const CODE_DIRS: PackedStringArray = ["res://features/", "res://ui/"]
## Content.text("file", "id" ...) or Content.field("file", "id", "key" ...) where each quoted literal
## is the whole argument. Ids built at runtime ("offer_mode_" + tier, a variable) are not checked here.
const CALL_PATTERN := "Content\\.(text|field)\\(\\s*\"(\\w+)\"\\s*,\\s*\"(\\w+)\"\\s*(?:\\)|,\\s*(?:\"(\\w+)\"\\s*[,)])?)"


func suite_name() -> String:
	return "ui_text"


func test_primary_is_capitals() -> void:
	assert_eq(UiText.primary("Continue"), "CONTINUE")
	assert_eq(UiText.primary("New run"), "NEW RUN")
	assert_eq(UiText.primary("ACCEPT"), "ACCEPT", "already capitals stay the same")


func test_back_adds_the_arrow() -> void:
	assert_eq(UiText.back("Back"), "< Back")
	assert_eq(UiText.back("Title"), "< Title")


func test_money_groups_thousands() -> void:
	assert_eq(UiText.money(0), "$0")
	assert_eq(UiText.money(999), "$999")
	assert_eq(UiText.money(1000), "$1,000")
	assert_eq(UiText.money(71000), "$71,000", "the GDD S10 mockup")
	assert_eq(UiText.money(150000), "$150,000")
	assert_eq(UiText.money(1234567), "$1,234,567")
	assert_eq(UiText.money(-4500), "-$4,500")


func test_band_is_dots_plus_a_word() -> void:
	assert_eq(UiText.band(3, "Possible"), "[###--] Possible", "the GDD 5.6 card band look")
	assert_eq(UiText.band(1, "Long shot"), "[#----] Long shot")
	assert_eq(UiText.band(5, "Good"), "[#####] Good")
	assert_eq(UiText.band(9, "Good"), "[#####] Good", "clamped")
	assert_true(UiText.band(1, "Long shot").length() <= 18, "fits a 124 px half-width button (GDD 2.7)")


func test_cost_follows_the_label() -> void:
	assert_eq(UiText.cost("APPLY", 1), "APPLY  1", "the GDD S04 mockup")
	assert_eq(UiText.cost("TAILOR & APPLY", 2), "TAILOR & APPLY  2")
	assert_true(UiText.cost("TAILOR & APPLY", 2).length() <= 25, "fits the 168 px primary (GDD 2.7)")


func test_meter_fills_from_the_left() -> void:
	assert_eq(UiText.meter(3, 6), "[###---]", "the GDD S04 Radar")
	assert_eq(UiText.meter(0, 8), "[--------]")
	assert_eq(UiText.meter(12, 10), "[##########]", "clamped")
	assert_eq(UiText.meter(-1, 3), "[---]", "clamped")


func test_count_groups_thousands() -> void:
	assert_eq(UiText.count(0), "0")
	assert_eq(UiText.count(999), "999")
	assert_eq(UiText.count(1247), "1,247", "the GDD S04 card back")
	assert_eq(UiText.count(1500000), "1,500,000")
	assert_eq(UiText.count(-4500), "-4,500")


## Wraps exactly where the content lint counts lines (GDD 2.7), so a checked budget is what shows.
func test_wrap_matches_the_lint() -> void:
	assert_eq(UiText.word_wrap("a".repeat(40), 40), PackedStringArray(["a".repeat(40)]), "exactly 40 columns fit")
	assert_eq(UiText.word_wrap("a".repeat(20) + " " + "b".repeat(20), 40),
		PackedStringArray(["a".repeat(20), "b".repeat(20)]), "41 columns wrap at the space")
	assert_eq(UiText.word_wrap("a".repeat(85), 40).size(), 3, "an over-long word breaks mid-word")
	assert_eq(UiText.word_wrap("one\ntwo", 40), PackedStringArray(["one", "two"]), "a newline starts a line")
	assert_eq(UiText.word_wrap("", 40), PackedStringArray([""]), "empty is one empty line")
	var text := "Non-compete: for 24 months you won't work in, near, or think about software."
	assert_eq(UiText.word_wrap(text, 28), PackedStringArray(["Non-compete: for 24 months", "you won't work in, near, or",
		"think about software."]), "fine print at 28 columns (GDD S10)")
	var lint := load("res://tests/test_content_lint.gd") as GDScript
	for columns: int in [10, 28, 40]:
		assert_eq(UiText.word_wrap(text, columns).size(), int(lint.call("wrap_lines", text, columns)),
			"same line count as the lint at %d columns" % columns)


## GDD S10: one field per line after a 12-character label column, values wrapping at 28 columns.
func test_contract_field_lines() -> void:
	assert_eq(UiText.field("Salary:", "$71,000/year", 12, 40), PackedStringArray(["Salary:     $71,000/year"]))
	assert_eq(UiText.field("Commute:", "0 minutes. The influencer was right about one thing.", 12, 40),
		PackedStringArray(["Commute:    0 minutes. The influencer", "            was right about one thing."]),
		"the S10 mockup's 2 commute lines")
	assert_eq(UiText.field("", "Kombucha on tap", 12, 40), PackedStringArray(["            Kombucha on tap"]),
		"an empty label continues the field above")
	for line: String in UiText.field("Fine print:", "Equity: 0.0001%, 4-year vest, 1-year cliff. Worth one sandwich at target valuation.", 12, 40):
		assert_true(line.length() <= 40, "'%s' fits 40 columns" % line)


func test_call_pattern_reads_only_whole_literals() -> void:
	var calls := RegEx.create_from_string(CALL_PATTERN)
	assert_true(calls.is_valid(), "CALL_PATTERN does not compile")
	var plain := calls.search("Content.text(\"barks\", \"ui_back\")")
	assert_true(plain != null and plain.get_string(3) == "ui_back", "a plain call")
	var with_args := calls.search("Content.text(\"barks\", \"ui_day\", {\"day\": 3})")
	assert_true(with_args != null and with_args.get_string(3) == "ui_day" and with_args.get_string(4).is_empty(), "args are not a key")
	var with_key := calls.search("Content.field(\"companies\", \"co_x\", \"name\")")
	assert_true(with_key != null and with_key.get_string(4) == "name", "a literal field key")
	assert_true(calls.search("Content.text(\"emails\", \"offer_mode_\" + tier)") == null, "a built id is skipped")
	assert_true(calls.search("Content.field(\"backgrounds\", id, \"title\")") == null, "a variable id is skipped")


## A missing id would show on screen as the raw id (Content.text() falls back to it).
func test_screen_text_ids_exist() -> void:
	var problems: Array[String] = []
	var calls := RegEx.create_from_string(CALL_PATTERN)
	var json_cache: Dictionary = {}
	var checked := 0
	for path: String in scripts_under(CODE_DIRS):
		for m: RegExMatch in calls.search_all(FileAccess.get_file_as_string(path)):
			checked += 1
			var file := m.get_string(2)
			var id := m.get_string(3)
			var key := m.get_string(4)
			if not json_cache.has(file):
				json_cache[file] = _load_json(file)
			var entries: Dictionary = json_cache[file]
			var entry: Variant = entries.get(id)
			if entries.is_empty():
				problems.append("%s: %s%s.json is missing or empty" % [path, CONTENT_DIR, file])
			elif entry == null:
				problems.append("%s: %s/%s does not exist" % [path, file, id])
			elif m.get_string(1) == "field" and not key.is_empty() \
					and not (entry is Dictionary and (entry as Dictionary).has(key)):
				problems.append("%s: %s/%s has no field '%s'" % [path, file, id, key])
			elif m.get_string(1) == "text" and entry is Dictionary and not (entry as Dictionary).has("text"):
				problems.append("%s: %s/%s is an object with no 'text'; use Content.field()" % [path, file, id])
	assert_gt(checked, 0, "no Content.text()/field() calls with literal ids under %s" % ", ".join(CODE_DIRS))
	assert_true(problems.is_empty(), "%d screen text id problem(s):\n  %s" % [problems.size(), "\n  ".join(PackedStringArray(problems))])


## Every .gd file under these folders, recursively.
static func scripts_under(dirs: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var todo: Array[String] = []
	todo.assign(dirs)
	while not todo.is_empty():
		var dir: String = todo.pop_back()
		for sub: String in DirAccess.get_directories_at(dir):
			todo.append(dir + sub + "/")
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".gd"):
				out.append(dir + file)
	return out


func _load_json(file: String) -> Dictionary:
	var path := CONTENT_DIR + file + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

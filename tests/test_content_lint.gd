@tool
extends McpTestSuite
## Content lint (ARCHITECTURE 12.3; budgets from GDD 2.7; lists from CONTENT.md 0 and 1.3).
## Reads res://data/content/*.json with FileAccess and res://data/backgrounds/*.tres with load():
## tests run inside the editor, so never through the Content autoload (INV-12).
## Artist-only fields (art, visual, audio, note) and naming.json's _notes are never linted.

const CONTENT_DIR := "res://data/content/"
const BACKGROUND_DIR := "res://data/backgrounds/"
const FILES: PackedStringArray = [
	"naming", "backgrounds", "tiers", "companies", "postings", "cv_lines",
	"questions_choice", "questions_knowledge", "barks", "emails", "tips",
	"endings", "events", "cutscene", "names", "news",
]
const TIERS: PackedStringArray = ["startup", "mid", "big"]
const WRAP_COLUMNS := 40
const MIN_CHOICE_PER_TIER := 11     # GDD 5.8.2: enough for 5 interviews
const MIN_KNOWLEDGE_PER_TIER := 19

## Budget category -> [max characters, max lines at 40 columns]. See budget_of() for the mapping.
const BUDGETS: Dictionary = {
	"answer": [40, 1],     # answer buttons and the insider "Why us?" button: exactly the button width
	"one_line": [40, 1],   # red flags, posting title, salary text
	"prompt": [100, 3],    # question prompts and CV lie probes
	"spoken": [80, 3],     # knowledge green / yellow / red
	"card": [60, 2],       # posting joke, company card joke and review, background one-liner, CV line
	"dialogue": [120, 4],  # reactions, barks, coach lines, ducky, Dana's lines, cutscene captions
	"tip": [120, 4],       # tip short
	"email": [240, 7],     # email bodies
	"name": [10, 1],       # player names (LineEdit.max_length)
	"other": [120, 4],     # any other displayed string must at least fit the dialogue box
}

## CONTENT.md section 0.
const PLACEHOLDERS: PackedStringArray = [
	"player_name", "company", "job_title", "salary", "work_mode", "commute_min", "office_days", "hours",
	"last_company", "knockout", "insider", "days", "n", "day", "topic_1", "topic_2",
	"r", "g", "i", "yes_no", "total",
]

## CONTENT.md 1.3, matched case-insensitively as whole words. It lives here, not in the game data,
## because tests/ is never exported: real brand names never ship. Every word is [a-z0-9'], so it
## goes into the RegEx unescaped.
const BANNED_BRANDS: PackedStringArray = [
	"google", "alphabet", "microsoft", "macrohard", "apple", "amazon", "amazoom", "meta", "facebook",
	"faceplant", "instagram", "whatsapp", "tiktok", "youtube", "netflix", "uber", "lyft", "airbnb",
	"linkedin", "linkedout", "indeed", "indeedn't", "glassdoor", "glassdoorknob", "leetcode",
	"hackerrank", "github", "gitlab", "stackoverflow", "openai", "chatgpt", "anthropic", "claude",
	"gemini", "copilot", "nvidia", "tesla", "twitter", "reddit", "discord", "slack", "zoom",
	"salesforce", "oracle", "ibm", "intel", "samsung", "spotify", "stanford", "stanfurd", "harvard",
	"mit", "oxford", "cambridge", "berkeley", "caltech", "princeton", "yale", "ledgerly",
	"kubernetes", "docker", "aws", "azure", "redis", "bytedance", "douyin", "snapchat", "pinterest",
	"patreon", "tinder", "ziprecruiter", "careerbuilder", "wellfound", "angellist", "teamblind",
	"taleo", "icims", "hirevue", "jobvite", "smartrecruiters", "jobscan", "zety", "canva", "neetcode",
	"algoexpert", "codesignal", "codewars", "duolingo", "udemy", "coursera", "codecademy",
	"freecodecamp", "udacity", "xai", "deepseek", "midjourney", "replit", "doordash", "grubhub",
	"deliveroo", "instacart", "postmates", "adp", "paychex", "quickbooks", "accenture", "deloitte",
	"hewlett", "xerox", "pagerduty", "jira", "bitcoin", "dogecoin", "coinbase", "cmu", "cornell",
	"synergai", "quantumleaf", "nimbus", "hirebot", "jobdeck", "glassceiling", "resumeforge",
	"promptpal", "bytebistro", "algogrind",
]

## Banned words allowed anyway, each as {"word": "...", "reason": "..."} (CONTENT.md 1.3 lint_allow).
const LINT_ALLOW: Array = []

## Never linted: notes for the artist (ARCHITECTURE 6.3).
const NOTE_KEYS: PackedStringArray = ["art", "visual", "audio", "note", "_notes"]
## Ids and enums, not display text: the test_ref_* methods check them instead.
const DATA_KEYS: PackedStringArray = [
	"tier", "tiers", "company", "tags", "topic", "kind", "weak_for", "tip", "background", "line",
	"variant", "ghost", "style", "hoodie", "_gap_topic_pool",
]
## Dictionaries keyed by ids: their keys show up as "*" in a field path.
const ID_KEYED: PackedStringArray = ["probe_at", "_keywords", "_topics"]

var _data: Dictionary = {}                # file name -> parsed Dictionary ({} if missing or broken)
var _parse_errors: Array[String] = []
var _texts: Array[Dictionary] = []        # {file, id, field, text} for every player-facing string


func suite_name() -> String:
	return "content_lint"


func suite_setup(_ctx: Dictionary) -> void:
	_data.clear()
	_parse_errors.clear()
	for file: String in FILES:
		_data[file] = {}
		var path := CONTENT_DIR + file + ".json"
		if not FileAccess.file_exists(path):
			_parse_errors.append("%s is missing" % path)
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			_parse_errors.append("%s:%d: %s" % [path, json.get_error_line(), json.get_error_message()])
		elif not (json.data is Dictionary):
			_parse_errors.append("%s must be one JSON object keyed by id" % path)
		else:
			_data[file] = json.data
	_texts.clear()
	for file: String in FILES:
		var entries := _entries(file)
		for id: String in entries:
			if id in NOTE_KEYS or id in DATA_KEYS:
				continue
			_collect(file, id, entries[id], "", id in ID_KEYED)


# ---------- 1. parsing ----------

func test_parse_every_file() -> void:
	_report(_parse_errors, "parse")


# ---------- 2. referenced ids ----------

func test_ref_tier_ids() -> void:
	var problems: Array[String] = []
	var ids: Array = _entries("tiers").keys()
	for tier: String in TIERS:
		if not tier in ids:
			problems.append("tiers.json has no '%s'" % tier)
	for id: String in ids:
		if not id in TIERS:
			problems.append("tiers.json has an unknown tier '%s'" % id)
	_report(problems, "tier id")


func test_ref_company_tiers() -> void:
	var problems: Array[String] = []
	var companies := _entries("companies")
	assert_gt(companies.size(), 0, "companies.json is empty")
	for id: String in companies:
		var tier: String = str(_field(companies, id, "tier"))
		if not _entries("tiers").has(tier):
			problems.append("companies/%s: tier '%s'" % [id, tier])
	_report(problems, "company tier")


func test_ref_posting_companies_and_tiers() -> void:
	var problems: Array[String] = []
	var companies := _entries("companies")
	var postings := _entries("postings")
	var templates := 0
	for id: String in postings:
		if not (postings[id] is Dictionary):
			continue  # plain UI strings: card_*, knock_*, research_*, hirebot_*, stamp_sent
		templates += 1
		var tier: String = str(_field(postings, id, "tier"))
		var company: String = str(_field(postings, id, "company"))
		if not _entries("tiers").has(tier):
			problems.append("postings/%s: tier '%s'" % [id, tier])
		if company != "any":
			if not companies.has(company):
				problems.append("postings/%s: company '%s'" % [id, company])
			elif str(_field(companies, company, "tier")) != tier:
				problems.append("postings/%s: company '%s' is not a %s company" % [id, company, tier])
	assert_gt(templates, 0, "postings.json has no templates")
	_report(problems, "posting reference")


func test_ref_tags_are_keywords() -> void:
	var problems: Array[String] = []
	var keywords: Dictionary = _entries("naming").get("_keywords", {})
	assert_gt(keywords.size(), 0, "naming.json has no _keywords")
	for file: String in ["postings", "cv_lines"]:
		var entries := _entries(file)
		for id: String in entries:
			if not (entries[id] is Dictionary):
				continue
			for tag: Variant in _field(entries, id, "tags", []):
				if not keywords.has(str(tag)):
					problems.append("%s/%s: tag '%s'" % [file, id, tag])
	_report(problems, "tag")


func test_ref_knowledge_topics() -> void:
	var problems: Array[String] = []
	var topics: Dictionary = _entries("naming").get("_topics", {})
	assert_gt(topics.size(), 0, "naming.json has no _topics")
	var questions := _entries("questions_knowledge")
	for id: String in questions:
		var topic: String = str(_field(questions, id, "topic"))
		if not topics.has(topic):
			problems.append("questions_knowledge/%s: topic '%s'" % [id, topic])
	_report(problems, "topic")


func test_ref_gap_topic_pool() -> void:
	var problems: Array[String] = []
	var naming := _entries("naming")
	var topics: Dictionary = naming.get("_topics", {})
	var pool: Array = naming.get("_gap_topic_pool", [])
	assert_gt(pool.size(), 0, "naming.json has no _gap_topic_pool")
	for topic: Variant in pool:
		if not topics.has(str(topic)):
			problems.append("_gap_topic_pool: '%s' is not in _topics" % topic)
	_report(problems, "gap topic")


func test_ref_question_tips() -> void:
	var problems: Array[String] = []
	var tips := _entries("tips")
	for file: String in ["questions_choice", "questions_knowledge"]:
		var questions := _entries(file)
		assert_gt(questions.size(), 0, "%s.json is empty" % file)
		for id: String in questions:
			var tip: String = str(_field(questions, id, "tip"))
			if not tips.has(tip):
				problems.append("%s/%s: tip '%s'" % [file, id, tip])
	_report(problems, "question tip")


func test_ref_question_tiers() -> void:
	var problems: Array[String] = []
	for file: String in ["questions_choice", "questions_knowledge"]:
		var questions := _entries(file)
		for id: String in questions:
			problems.append_array(_bad_tiers("%s/%s" % [file, id], _field(questions, id, "tiers", [])))
	_report(problems, "question tier")


func test_ref_weak_for() -> void:
	var problems: Array[String] = []
	var backgrounds := _entries("backgrounds")
	var questions := _entries("questions_knowledge")
	for id: String in questions:
		var weak: String = str(_field(questions, id, "weak_for"))
		if weak != "none" and not backgrounds.has(weak):
			problems.append("questions_knowledge/%s: weak_for '%s'" % [id, weak])
	_report(problems, "weak_for")


func test_ref_exclusive_answer_backgrounds() -> void:
	var problems: Array[String] = []
	var backgrounds := _entries("backgrounds")
	var questions := _entries("questions_choice")
	var exclusives := 0
	for id: String in questions:
		var exclusive: Variant = _field(questions, id, "exclusive")
		if exclusive is Dictionary:
			exclusives += 1
			var bg: String = str((exclusive as Dictionary).get("background", ""))
			if not backgrounds.has(bg):
				problems.append("questions_choice/%s: exclusive.background '%s'" % [id, bg])
	assert_gt(exclusives, 0, "no background-exclusive answers found")
	_report(problems, "exclusive background")


func test_ref_perk_and_fine_print_tiers() -> void:
	var problems: Array[String] = []
	var emails := _entries("emails")
	var checked := 0
	for id: String in emails:
		if id.begins_with("perk_") or id.begins_with("fp_"):
			checked += 1
			problems.append_array(_bad_tiers("emails/" + id, _field(emails, id, "tiers", [])))
	assert_gt(checked, 0, "emails.json has no perk_ / fp_ entries")
	_report(problems, "perk / fine-print tier")


func test_ref_cv_line_backgrounds_and_probe_companies() -> void:
	var problems: Array[String] = []
	var backgrounds := _entries("backgrounds")
	var companies := _entries("companies")
	var lines := _entries("cv_lines")
	for id: String in lines:
		var bg: String = str(_field(lines, id, "background"))
		if not backgrounds.has(bg):
			problems.append("cv_lines/%s: background '%s'" % [id, bg])
		var probe_at: Variant = _field(lines, id, "probe_at", {})
		if probe_at is Dictionary:
			for company: String in probe_at:
				if not companies.has(company):
					problems.append("cv_lines/%s: probe_at company '%s'" % [id, company])
	_report(problems, "CV line reference")


func test_ref_background_ids_match_tres() -> void:
	var problems: Array[String] = []
	var ids: Array = _entries("backgrounds").keys()
	assert_gt(ids.size(), 0, "backgrounds.json has no backgrounds")
	for id: String in ids:
		var bg := _load_background(id, problems)
		if bg != null and String(bg.id) != id:
			problems.append("%s%s.tres has id '%s'" % [BACKGROUND_DIR, id, bg.id])
	if DirAccess.dir_exists_absolute(BACKGROUND_DIR):
		for file: String in ResourceLoader.list_directory(BACKGROUND_DIR):
			if file.ends_with(".tres") and not file.get_basename() in ids:
				problems.append("%s%s has no text in backgrounds.json" % [BACKGROUND_DIR, file])
	_report(problems, "background id")


# ---------- 3. text budgets (GDD 2.7), including the line cap at 40 columns ----------

func test_budget_answer_buttons() -> void:
	_check_budget("answer")


func test_budget_one_line_labels() -> void:
	_check_budget("one_line")


func test_budget_prompts() -> void:
	_check_budget("prompt")


func test_budget_spoken_answers() -> void:
	_check_budget("spoken")


func test_budget_card_lines() -> void:
	_check_budget("card")


func test_budget_dialogue() -> void:
	_check_budget("dialogue")


func test_budget_tips() -> void:
	_check_budget("tip")


func test_budget_email_bodies() -> void:
	_check_budget("email")


func test_budget_player_names() -> void:
	_check_budget("name")


func test_budget_other_text() -> void:
	_check_budget("other")


func test_budget_wrap_counts_like_a_label() -> void:
	assert_eq(wrap_lines("a".repeat(40), 40), 1, "exactly 40 columns fit one line")
	assert_eq(wrap_lines("a".repeat(19) + " " + "b".repeat(20), 40), 1, "40 columns including the space")
	assert_eq(wrap_lines("a".repeat(20) + " " + "b".repeat(20), 40), 2, "41 columns wrap at the space")
	assert_eq(wrap_lines("a".repeat(85), 40), 3, "an over-long word breaks mid-word")
	assert_eq(wrap_lines("one\ntwo", 40), 2, "a newline starts a line")


# ---------- 4-6. brands, ASCII, placeholders ----------

func test_banned_brands_absent() -> void:
	var problems: Array[String] = []
	var allowed: Array[String] = []
	for entry: Dictionary in LINT_ALLOW:
		var word: String = str(entry.get("word", ""))
		if not word in BANNED_BRANDS:
			problems.append("LINT_ALLOW: '%s' is not on the banned list" % word)
		if str(entry.get("reason", "")).strip_edges().is_empty():
			problems.append("LINT_ALLOW: '%s' has no reason" % word)
		allowed.append(word)
	var words: Array[String] = []
	for word: String in BANNED_BRANDS:
		if not word in allowed:
			words.append(word)
	var brand := RegEx.create_from_string("(?i)\\b(?:%s)\\b" % "|".join(PackedStringArray(words)))
	assert_true(brand.is_valid(), "the banned-brand RegEx does not compile")
	assert_gt(_texts.size(), 0, "no player-facing strings found")
	for t: Dictionary in _texts:
		var text: String = t["text"]
		for m: RegExMatch in brand.search_all(text):
			problems.append("%s: '%s' in \"%s\"" % [_where(t), m.get_string(), text])
	_report(problems, "banned brand")


func test_ascii_only() -> void:
	var problems: Array[String] = []
	assert_gt(_texts.size(), 0, "no player-facing strings found")
	for t: Dictionary in _texts:
		var text: String = t["text"]
		for i: int in text.length():
			if text.unicode_at(i) >= 128:
				problems.append("%s: U+%04X at %d in \"%s\"" % [_where(t), text.unicode_at(i), i, text])
				break
	_report(problems, "non-ASCII")


func test_placeholders_known() -> void:
	var problems: Array[String] = []
	var placeholder := RegEx.create_from_string("\\{([^{}]*)\\}")
	assert_gt(_texts.size(), 0, "no player-facing strings found")
	for t: Dictionary in _texts:
		var text: String = t["text"]
		for m: RegExMatch in placeholder.search_all(text):
			if not m.get_string(1) in PLACEHOLDERS:
				problems.append("%s: {%s} is not in the CONTENT.md 0 list: \"%s\"" % [_where(t), m.get_string(1), text])
	_report(problems, "placeholder")


# ---------- 7. shapes ----------

func test_shape_choice_answer_kinds() -> void:
	var problems: Array[String] = []
	var questions := _entries("questions_choice")
	assert_gt(questions.size(), 0, "questions_choice.json is empty")
	for id: String in questions:
		var kinds: Array[String] = []
		for answer: Variant in _field(questions, id, "answers", []):
			kinds.append(str((answer as Dictionary).get("kind", "")) if answer is Dictionary else "?")
		var good := kinds.count("good")
		if _field(questions, id, "opener_only", false):
			good += kinds.count("insider")  # the Research opener's insider answer takes the good slot
		if kinds.size() != 3 or good != 1 or kinds.count("neutral") != 1 or kinds.count("bad") != 1:
			problems.append("questions_choice/%s: answer kinds %s (want one good, one neutral, one bad)" % [id, kinds])
	_report(problems, "choice answer")


func test_shape_cv_lines_per_background() -> void:
	var problems: Array[String] = []
	var lines := _entries("cv_lines")
	var backgrounds := _entries("backgrounds")
	assert_gt(backgrounds.size(), 0, "backgrounds.json has no backgrounds")
	for bg: String in backgrounds:
		var slots: Array[String] = []
		for id: String in lines:
			if str(_field(lines, id, "background")) == bg:
				slots.append("%s/%s" % [_field(lines, id, "line"), _field(lines, id, "variant")])
		for line: String in ["edu", "exp", "proj"]:
			for variant: String in ["honest", "polished", "lie"]:
				if slots.count(line + "/" + variant) != 1:
					problems.append("%s: %d CV lines for %s/%s (want 1)" % [bg, slots.count(line + "/" + variant), line, variant])
		if slots.size() != 9:
			problems.append("%s: %d CV lines (want 9)" % [bg, slots.size()])
	_report(problems, "CV line count")


func test_shape_honest_flags_match_tres() -> void:
	var problems: Array[String] = []
	var lines := _entries("cv_lines")
	var backgrounds := _entries("backgrounds")
	assert_gt(backgrounds.size(), 0, "backgrounds.json has no backgrounds")
	for id: String in backgrounds:
		var bg := _load_background(id, problems)
		if bg == null:
			continue
		var degree := false
		var years := false
		for line_id: String in lines:
			if str(_field(lines, line_id, "background")) == id and str(_field(lines, line_id, "variant")) == "honest":
				degree = degree or bool(_field(lines, line_id, "degree", false))
				years = years or bool(_field(lines, line_id, "passes_years", false))
		if bg.has_degree_honest != degree:
			problems.append("%s.tres has_degree_honest = %s, but its honest CV lines say %s" % [id, bg.has_degree_honest, degree])
		if bg.years_pass_honest != years:
			problems.append("%s.tres years_pass_honest = %s, but its honest CV lines say %s" % [id, bg.years_pass_honest, years])
	_report(problems, "honest flag")


func test_shape_tier_pool_minimums() -> void:
	var problems: Array[String] = []
	var choice := _entries("questions_choice")
	var knowledge := _entries("questions_knowledge")
	for tier: String in TIERS:
		var choice_count := 0
		for id: String in choice:
			if tier in _field(choice, id, "tiers", []) and not _field(choice, id, "opener_only", false):
				choice_count += 1
		var knowledge_count := 0
		for id: String in knowledge:
			if tier in _field(knowledge, id, "tiers", []):
				knowledge_count += 1
		if choice_count < MIN_CHOICE_PER_TIER:
			problems.append("%s: %d choice questions (min %d)" % [tier, choice_count, MIN_CHOICE_PER_TIER])
		if knowledge_count < MIN_KNOWLEDGE_PER_TIER:
			problems.append("%s: %d knowledge questions (min %d)" % [tier, knowledge_count, MIN_KNOWLEDGE_PER_TIER])
	_report(problems, "question pool")


# ---------- helpers ----------

## Budget category of one string (a BUDGETS key), or "" when it has none: a tip's Notebook text
## scrolls, and triggers are never shown. Mirrors GDD 2.7 row by row; everything else is "other".
static func budget_of(file: String, id: String, field: String) -> String:
	if file == "names":
		return "name"
	if field in ["answers.text", "exclusive.text", "insider"]:
		return "answer"
	if field == "red_flags" or (file == "postings" and field in ["title", "salary_text"]):
		return "one_line"
	if field in ["prompt", "probe", "probe_at.*"]:
		return "prompt"
	if field in ["green", "yellow", "red"]:
		return "spoken"
	if field in ["card_joke", "one_liner", "review"] or (file == "postings" and field == "joke") \
			or (file == "cv_lines" and field == "text"):
		return "card"
	if file == "tips":
		return "tip" if field == "short" else ""
	if file == "emails" and (field == "body" or (field.is_empty() and id.begins_with("mail_"))):
		return "email"
	if file == "barks" or field in ["answers.reaction", "exclusive.reaction", "ducky", "dana_line", "dana_opener", "captions.text"]:
		return "dialogue"
	return "other"


## Lines a string needs at `columns` characters: greedy word wrap by spaces, like an autowrapped
## Label; a word longer than a whole line breaks mid-word.
static func wrap_lines(text: String, columns: int) -> int:
	var lines := 0
	for paragraph: String in text.split("\n"):
		lines += 1
		var used := 0
		for word: String in paragraph.split(" ", false):
			var n := word.length()
			if used == 0:
				used = n
			elif used + 1 + n <= columns:
				used += 1 + n
			else:
				lines += 1
				used = n
			while used > columns:
				lines += 1
				used -= columns
	return lines


func _check_budget(category: String) -> void:
	var problems: Array[String] = []
	var limits: Array = BUDGETS[category]
	var max_chars: int = limits[0]
	var max_lines: int = limits[1]
	var checked := 0
	for t: Dictionary in _texts:
		if budget_of(t["file"], t["id"], t["field"]) != category:
			continue
		checked += 1
		var text: String = t["text"]
		var lines := wrap_lines(text, WRAP_COLUMNS)
		if text.length() > max_chars or lines > max_lines:
			problems.append("%s: %d chars (max %d), %d lines at %d columns (max %d): \"%s\"" % [
				_where(t), text.length(), max_chars, lines, WRAP_COLUMNS, max_lines, text])
	assert_gt(checked, 0, "no '%s' strings found" % category)
	_report(problems, "'%s' budget" % category)


## Walks one entry and records every display string. field is the key path without array
## indices ("answers.text"); keys of an ID_KEYED dictionary become "*".
func _collect(file: String, id: String, value: Variant, path: String, keyed_by_id: bool) -> void:
	if value is String:
		_texts.append({"file": file, "id": id, "field": path, "text": value})
	elif value is Dictionary:
		var dict: Dictionary = value
		for key: String in dict:
			# Keys of an id-keyed dictionary are ids, not field names, so they are never filtered out.
			if not keyed_by_id and (key in NOTE_KEYS or key in DATA_KEYS):
				continue
			var segment := "*" if keyed_by_id else key
			_collect(file, id, dict[key], segment if path.is_empty() else path + "." + segment, key in ID_KEYED)
	elif value is Array:
		for item: Variant in value:
			_collect(file, id, item, path, false)


func _entries(file: String) -> Dictionary:
	return _data.get(file, {})


## One field of a structured entry, or fallback when the entry is not an object or lacks it.
func _field(entries: Dictionary, id: String, key: String, fallback: Variant = null) -> Variant:
	var entry: Variant = entries.get(id)
	if entry is Dictionary:
		return (entry as Dictionary).get(key, fallback)
	return fallback


## Problems with a tier list: it must be explicit (never "all") and name only real tiers.
func _bad_tiers(where: String, tiers: Variant) -> Array[String]:
	var problems: Array[String] = []
	if not (tiers is Array) or (tiers as Array).is_empty():
		problems.append("%s: tiers must be a non-empty list, got %s" % [where, tiers])
		return problems
	for tier: Variant in tiers:
		if not str(tier) in TIERS:
			problems.append("%s: tier '%s'" % [where, tier])
	return problems


func _load_background(id: String, problems: Array[String]) -> BackgroundData:
	var path := BACKGROUND_DIR + id + ".tres"
	if not ResourceLoader.exists(path):
		problems.append("%s is missing (Step 3 creates it; ARCHITECTURE 6.2)" % path)
		return null
	var bg := load(path) as BackgroundData
	if bg == null:
		problems.append("%s is not a BackgroundData" % path)
	return bg


func _where(t: Dictionary) -> String:
	var field: String = t["field"]
	return "%s/%s%s" % [t["file"], t["id"], "" if field.is_empty() else "." + field]


func _report(problems: Array[String], what: String) -> void:
	assert_true(problems.is_empty(), "%d %s problem(s):\n  %s" % [problems.size(), what, "\n  ".join(PackedStringArray(problems))])

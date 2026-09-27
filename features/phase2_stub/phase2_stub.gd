extends Control
## Step 3 stub of the Hired card (GDD S11). Step 6 builds the two beats and Dream vs Reality.
## Leaving it (Title or New run) deletes the run save (GameFlow.deletes_save).

@onready var _header: Label = %Header
@onready var _summary: Label = %Summary
@onready var _to_be_continued: Label = %ToBeContinued
@onready var _title_button: Button = %TitleButton
@onready var _new_run_button: Button = %NewRunButton


func _ready() -> void:
	var run: RunState = GameState.run
	var job: Dictionary = run.employment
	_header.text = Content.text("endings", "end_hired_title")
	_summary.text = "\n".join(PackedStringArray([
		Content.field("companies", str(job.get("company_id", "")), "name"),
		Content.field("postings", str(job.get("template_id", "")), "title"),
		Content.text("emails", "offer_salary", {"salary": UiText.money(int(job.get("salary", 0)))}),
		"%s: %d" % [Content.text("endings", "end_dream_header"), run.dream_score],
	]))
	_to_be_continued.text = Content.text("endings", "end_tbc")
	_title_button.text = UiText.back(Content.text("barks", "ui_title"))
	_new_run_button.text = UiText.primary(Content.text("barks", "ui_new_run"))
	_title_button.pressed.connect(Device.handle_back)
	_new_run_button.pressed.connect(GameState.retry)


## "< Title" is this card's on-screen Back; it and desktop Esc go to the title (ARCHITECTURE 9).
func handle_back() -> bool:
	GameState.quit_to_title()
	return true

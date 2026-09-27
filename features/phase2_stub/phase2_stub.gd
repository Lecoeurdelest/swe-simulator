extends Control
## Step 3 stub of the Hired card (GDD S11). Step 6 builds the two beats and Dream vs Reality.
## Leaving it (Title or New run) deletes the run save (GameFlow.deletes_save).

@onready var _summary: Label = %Summary
@onready var _title_button: Button = %TitleButton
@onready var _new_run_button: Button = %NewRunButton


func _ready() -> void:
	var run: RunState = GameState.run
	var job: Dictionary = run.employment
	_summary.text = "%s\n%s\n$%d/year\nDream vs Reality: %d" % [
		job.get("company_id", "?"), job.get("template_id", "?"), int(job.get("salary", 0)), run.dream_score]
	_title_button.pressed.connect(Device.handle_back)
	_new_run_button.pressed.connect(GameState.retry)


## "< Title" is this card's on-screen Back; it and desktop Esc go to the title (ARCHITECTURE 9).
func handle_back() -> bool:
	GameState.quit_to_title()
	return true

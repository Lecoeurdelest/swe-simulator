extends Control
## Step 3 stub of the Plan B ending (GDD S12). Step 6 builds the card. The save is already gone:
## entering GAME_OVER deletes it (GameFlow.deletes_save).

@onready var _stats: Label = %Stats
@onready var _title_button: Button = %TitleButton
@onready var _retry_button: Button = %RetryButton


func _ready() -> void:
	var run: RunState = GameState.run
	_stats.text = tr("Days: {day} - Applications: {n} - Interviews: {i} - Rejections: {r}").format({
		"day": run.day, "n": run.total_applications, "i": run.interviews_taken, "r": run.total_rejections})
	_title_button.pressed.connect(Device.handle_back)
	_retry_button.pressed.connect(GameState.retry)


## "< Title" is this card's on-screen Back; it and desktop Esc go to the title (ARCHITECTURE 9).
func handle_back() -> bool:
	GameState.quit_to_title()
	return true

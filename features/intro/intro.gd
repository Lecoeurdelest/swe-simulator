extends Control
## Step 3 stub of the intro cutscene (GDD S02). Step 6 builds the text slides from cutscene.json.

@onready var _back_button: Button = %BackButton
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	_back_button.pressed.connect(Device.handle_back)
	_skip_button.pressed.connect(GameState.finish_intro)


## Back skips the intro (ARCHITECTURE 9, GDD 4.4).
func handle_back() -> bool:
	GameState.finish_intro()
	return true

extends Control
## Step 3 stub of the intro cutscene (GDD S02). Step 6 builds the text slides from cutscene.json.

## Debug-only stub text, English on purpose (not player text): Step 6 replaces this screen.
const DEBUG_HEADER := "INTRO"
const DEBUG_NOTE := "Stub: the intro cutscene arrives in Step 6.\nSkip, Back or Esc goes to Background select."

@onready var _header: Label = %Header
@onready var _note: Label = %Text
@onready var _back_button: Button = %BackButton
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	_header.text = DEBUG_HEADER
	_note.text = DEBUG_NOTE
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_skip_button.text = UiText.primary(Content.text("barks", "ui_skip"))
	_back_button.pressed.connect(Device.handle_back)
	_skip_button.pressed.connect(GameState.finish_intro)


## Back skips the intro (ARCHITECTURE 9, GDD 4.4).
func handle_back() -> bool:
	GameState.finish_intro()
	return true

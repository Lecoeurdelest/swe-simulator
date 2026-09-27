extends Control
## Step 3 stub of Background select (GDD S03): three plain buttons and the default name from names.json.
## The real layout (card, selector, name row) is the developer's Step 3 You-do.

const DEFAULT_BACKGROUND := "graduate"
## Debug-only stub text, English on purpose (not player text): the real S03 layout replaces it.
const DEBUG_HEADER := "BACKGROUND SELECT"
const DEBUG_NOTE := "Stub: three plain buttons, name Alex.\nThe highlighted one is preselected."

@onready var _header: Label = %Header
@onready var _prompt: Label = %Prompt
@onready var _note: Label = %Text
@onready var _back_button: Button = %BackButton
@onready var _choices: Dictionary = {
	"intern": %InternButton, "graduate": %GraduateButton, "self_taught": %SelfTaughtButton,
}


func _ready() -> void:
	_header.text = DEBUG_HEADER
	_note.text = DEBUG_NOTE
	_prompt.text = Content.text("barks", "ui_background_header")
	_back_button.text = UiText.back(Content.text("barks", "ui_title"))  # GDD S03: [ < Title ]
	_back_button.pressed.connect(Device.handle_back)
	var default_name := Content.text("names", "default")
	var preselected: String = GameState.preselect_background
	if not _choices.has(preselected):
		preselected = DEFAULT_BACKGROUND
	for id: String in _choices:
		var button := _choices[id] as Button
		button.text = "%s - %s" % [Content.field("backgrounds", id, "title"), Content.field("backgrounds", id, "difficulty")]
		button.pressed.connect(GameState.choose_background.bind(id, default_name))
		if id == preselected:  # after Retry: the last background; otherwise The Graduate (GDD S03)
			button.theme_type_variation = &"PrimaryButton"


## Back returns to the title (ARCHITECTURE 9). The save, if any, survives for Continue.
func handle_back() -> bool:
	GameState.quit_to_title()
	return true

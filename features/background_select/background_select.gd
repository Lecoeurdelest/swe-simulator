extends Control
## Step 3 stub of Background select (GDD S03): three plain buttons, the default name "Alex".
## The real layout (card, selector, name row) is the developer's Step 3 You-do.

const DEFAULT_BACKGROUND := "graduate"
const DEFAULT_NAME := "Alex"

@onready var _back_button: Button = %BackButton
@onready var _choices: Dictionary = {
	"intern": %InternButton, "graduate": %GraduateButton, "self_taught": %SelfTaughtButton,
}


func _ready() -> void:
	_back_button.pressed.connect(Device.handle_back)
	var preselected: String = GameState.preselect_background
	if not _choices.has(preselected):
		preselected = DEFAULT_BACKGROUND
	for id: String in _choices:
		var button := _choices[id] as Button
		button.pressed.connect(GameState.choose_background.bind(id, DEFAULT_NAME))
		if id == preselected:  # after Retry: the last background; otherwise The Graduate (GDD S03)
			button.theme_type_variation = &"PrimaryButton"


## Back returns to the title (ARCHITECTURE 9). The save, if any, survives for Continue.
func handle_back() -> bool:
	GameState.quit_to_title()
	return true

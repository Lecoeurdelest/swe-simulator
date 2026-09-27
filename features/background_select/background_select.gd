extends Control
## Background select (GDD S03, ARCHITECTURE 11.3): one data-driven card, the 3-button selector,
## the card swipe and the name dice. CHOOSE starts the run with GameState.choose_background().

const DEFAULT_BACKGROUND := "graduate"

var _selected := ""
## Picked when the screen opens and passed to CHOOSE, so the Self-Taught's card shows the very gap
## topics the run will roll (GameState.preview_gap_topics).
var _run_seed := 0
var _dice := RandomNumberGenerator.new()  # the name dice only: never the run RNG

@onready var _header: Label = %Header
@onready var _card: BackgroundCard = %Card
@onready var _name_label: Label = %NameLabel
@onready var _name_field: LineEdit = %NameField
@onready var _dice_button: Button = %DiceButton
@onready var _selector: HBoxContainer = %Selector
@onready var _action_bar: HBoxContainer = %ActionBar
@onready var _keyboard_spacer: Control = %KeyboardSpacer
@onready var _safe_area: MarginContainer = %SafeArea
@onready var _column: VBoxContainer = %Column
@onready var _back_button: Button = %BackButton
@onready var _choose_button: Button = %ChooseButton
## Left to right, as on screen: a swipe steps through this order.
@onready var _choices: Dictionary[String, Button] = {
	"intern": %InternButton, "graduate": %GraduateButton, "self_taught": %SelfTaughtButton,
}


func _ready() -> void:
	_dice.randomize()
	_run_seed = GameState.new_run_seed()
	_header.text = Content.text("barks", "ui_background_header")
	_name_label.text = Content.text("barks", "ui_name")
	_name_field.text = Content.text("names", "default")
	_back_button.text = UiText.back(Content.text("barks", "ui_title"))  # GDD S03: [ < Title ]
	_choose_button.text = UiText.primary(Content.text("barks", "ui_choose"))
	var group := ButtonGroup.new()
	for id: String in _choices:
		var button := _choices[id]
		button.text = "%s\n%s" % [Content.field("backgrounds", id, "selector"), Content.field("backgrounds", id, "difficulty")]
		button.button_group = group
		button.pressed.connect(_on_selector_pressed.bind(id))
	_card.swiped.connect(_on_card_swiped)
	_dice_button.pressed.connect(_roll_name)
	_name_field.editing_toggled.connect(_on_name_editing)
	_back_button.pressed.connect(Device.handle_back)
	_choose_button.pressed.connect(_choose)
	set_process(false)
	var preselected: String = GameState.preselect_background
	_select(preselected if _choices.has(preselected) else DEFAULT_BACKGROUND, 0)  # GDD S03


## Back returns to the title (ARCHITECTURE 9). The save, if any, survives for Continue.
func handle_back() -> bool:
	GameState.quit_to_title()
	return true


func _select(id: String, from_side: int) -> void:
	if id == _selected:
		return
	_selected = id
	_choices[id].button_pressed = true  # the ButtonGroup releases the others
	_card.show_background(id, GameState.preview_gap_topics(id, _run_seed), from_side)


func _on_selector_pressed(id: String) -> void:
	var order := _choices.keys()
	_select(id, signi(order.find(id) - order.find(_selected)))


## step +1 = the next background to the right; the ends don't wrap (the card just settles back).
func _on_card_swiped(step: int) -> void:
	var order := _choices.keys()
	var index := clampi(order.find(_selected) + step, 0, order.size() - 1)
	_select(order[index], step)


## A different name from the 20-name pool (CONTENT.md 3.2) each roll.
func _roll_name() -> void:
	var current := _name_field.text
	var others: Array = Content.entries("names").get("pool", []).filter(
		func(pool_name: Variant) -> bool: return str(pool_name) != current)
	if not others.is_empty():
		_name_field.text = str(others[_dice.randi_range(0, others.size() - 1)])


func _choose() -> void:
	var player_name := _name_field.text.strip_edges()
	if player_name.is_empty():
		player_name = Content.text("names", "default")
	GameState.choose_background(_selected, player_name, _run_seed)


# ---------- typing the name (optional; ARCHITECTURE 10.3 #8) ----------

func _on_name_editing(editing: bool) -> void:
	set_process(editing)
	if not editing:
		_lift_name_row(0.0)
		if _name_field.text.strip_edges().is_empty():
			_name_field.text = Content.text("names", "default")


func _process(_delta: float) -> void:
	_lift_name_row(Device.keyboard_height())


## The iOS keyboard covers about the bottom 40%, the selector and the action bar with it. While it
## is up they give way to a spacer as tall as the keyboard, so the name row sits just above it.
## On a short screen the card steps aside too, rather than pushing the column off the top.
func _lift_name_row(keyboard: float) -> void:
	var lifted := keyboard > 0.0
	_selector.visible = not lifted
	_action_bar.visible = not lifted
	_keyboard_spacer.visible = lifted
	var margins := _safe_area.get_theme_constant(&"margin_top") + _safe_area.get_theme_constant(&"margin_bottom")
	_keyboard_spacer.custom_minimum_size.y = maxf(keyboard - _safe_area.get_theme_constant(&"margin_bottom"), 0.0) if lifted else 0.0
	_card.visible = true
	if lifted and _column.get_combined_minimum_size().y > _safe_area.size.y - margins:
		_card.visible = false

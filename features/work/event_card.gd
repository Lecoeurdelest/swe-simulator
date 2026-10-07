class_name EventCard
extends Control
## The card over the work state (GDD 4.6, 5.19; ARCHITECTURE 19.7, 10.1): a sheet at the bottom of the screen with a
## text and at most three full-width 254x36 buttons, in the screen's ModalLayer. Its buttons wake 250 ms after it
## opens (GDD 2.8 rule 7), so the tap that closed the last card cannot answer this one. The dimmer behind it blocks
## every tap. It shows what it is told (show_card) and reports which button was pressed (`answered`); the screen
## decides what that means. The sheet's "=" opens Pause, so Back stays on the screen while a card is open (GDD 4.4).

signal answered(button_id: String)

const MENU_MARK := "="    # stands in for the menu icon until the art pass
const FADE_SEC := 0.12

var _fade: Tween
var _lock: Tween

@onready var _sheet: PanelContainer = %Sheet
@onready var _title: Label = %Title
@onready var _text: Label = %Text
@onready var _buttons: VBoxContainer = %Buttons
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	hide()
	_menu_button.text = MENU_MARK
	_menu_button.pressed.connect(Device.handle_back)


func is_open() -> bool:
	return visible


## view: {title: String, text: String, buttons: [{id: String, text: String, primary: bool}]}. An empty title hides the
## title line. The buttons are disabled for input_lock_ms.
func show_card(view: Dictionary) -> void:
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	var title := String(view.get("title", ""))
	_title.text = title
	_title.visible = not title.is_empty()
	_text.text = String(view.get("text", ""))
	for spec: Dictionary in view.get("buttons", []):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 36)
		button.focus_mode = Control.FOCUS_NONE
		button.text = String(spec["text"])
		if bool(spec.get("primary", false)):
			button.theme_type_variation = &"PrimaryButton"
		button.disabled = true
		button.pressed.connect(_on_pressed.bind(String(spec["id"])))
		_buttons.add_child(button)
	show()
	_start_fade()
	_start_lock()


func hide_card() -> void:
	hide()
	if _fade != null:
		_fade.kill()
	if _lock != null:
		_lock.kill()


## True while the lock is on: the screen and the tests can tell a card that is not yet answerable.
func is_locked() -> bool:
	for child: Node in _buttons.get_children():
		if child is Button and (child as Button).disabled:
			return true
	return false


## The labels of the buttons now showing (for the screen's checks and the tests).
func button_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for child: Node in _buttons.get_children():
		if child is Button:
			out.append((child as Button).text)
	return out


func _on_pressed(button_id: String) -> void:
	_set_buttons_disabled(true)   # one answer per card: a double tap cannot answer twice
	answered.emit(button_id)


func _start_fade() -> void:
	if _fade != null:
		_fade.kill()
	_sheet.modulate.a = 0.0
	_fade = create_tween()
	_fade.tween_property(_sheet, "modulate:a", 1.0, FADE_SEC)


func _start_lock() -> void:
	if _lock != null:
		_lock.kill()
	_lock = create_tween()
	_lock.tween_interval(Content.balance.input_lock_ms / 1000.0)
	_lock.tween_callback(_set_buttons_disabled.bind(false))


func _set_buttons_disabled(off: bool) -> void:
	for child: Node in _buttons.get_children():
		if child is Button:
			(child as Button).disabled = off

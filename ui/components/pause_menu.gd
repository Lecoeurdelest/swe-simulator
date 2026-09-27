class_name PauseMenu
extends Control
## Pause (GDD S13, ARCHITECTURE 10.1): a bottom sheet in the screen's ModalLayer, most-used button lowest.
## open() pauses the tree. Resume, a tap outside the sheet, or Back unpauses it and emits `resumed`.
## Quit to title only emits `quit_to_title_pressed` and leaves the tree paused: the screen calls
## GameState.quit_to_title(), and SceneRouter unpauses the tree when it swaps the scene.
## The scene root's process_mode is ALWAYS, so the sheet keeps taking taps while the tree is paused.

signal resumed
signal quit_to_title_pressed

@onready var _dimmer: Control = %Dimmer
@onready var _quit_button: Button = %QuitButton
@onready var _resume_button: Button = %ResumeButton


func _ready() -> void:
	hide()
	_quit_button.text = Content.text("barks", "ui_pause_title")
	_resume_button.text = UiText.primary(Content.text("barks", "ui_pause_resume"))
	_quit_button.pressed.connect(_on_quit_pressed)
	_resume_button.pressed.connect(resume)
	_dimmer.gui_input.connect(_on_dimmer_input)


func open() -> void:
	_quit_button.disabled = false
	show()
	get_tree().paused = true


func is_open() -> bool:
	return visible


func resume() -> void:
	if not visible:
		return
	hide()
	get_tree().paused = false
	resumed.emit()


## Back while open = Resume. The screen's handle_back() asks this first.
func handle_back() -> bool:
	if not visible:
		return false
	resume()
	return true


func _on_quit_pressed() -> void:
	_quit_button.disabled = true  # a second quit_to_title() would be an illegal TITLE -> TITLE change
	quit_to_title_pressed.emit()


## A tap on the dimmer, outside the sheet, = Resume. It acts on release, like the buttons do.
func _on_dimmer_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton  # touches arrive as emulated mouse events
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		resume()

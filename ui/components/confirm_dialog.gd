class_name ConfirmDialog
extends Control
## A question with two answers over a full-screen dimmer (ARCHITECTURE 10.1: it lives in the screen's
## ModalLayer). The dimmer blocks every tap behind it; only the two buttons answer. Back = cancel.
## Add it to the tree, then open(). It hides itself after an answer; the owner may free it.

signal confirmed
signal cancelled

var _default_confirm_text := ""
var _default_cancel_text := ""

@onready var _message: Label = %Message
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	hide()
	_default_confirm_text = _confirm_button.text
	_default_cancel_text = _cancel_button.text
	_confirm_button.pressed.connect(_answer.bind(true))
	_cancel_button.pressed.connect(_answer.bind(false))


## Pass texts from Content.text() (already translated). An empty button text keeps the scene's default.
## danger = true turns the confirm button red for choices you can't take back (Decline, Quit);
## its label still says what it does, so color is never the only signal (GDD 2.7).
func open(message: String, confirm_text: String = "", cancel_text: String = "", danger: bool = false) -> void:
	_message.text = message
	_confirm_button.text = confirm_text if not confirm_text.is_empty() else _default_confirm_text
	_cancel_button.text = cancel_text if not cancel_text.is_empty() else _default_cancel_text
	_confirm_button.theme_type_variation = &"DangerButton" if danger else &"PrimaryButton"
	show()


func is_open() -> bool:
	return visible


## Back (on-screen, Android, desktop Esc) while open = cancel. The screen's handle_back() asks this first.
func handle_back() -> bool:
	if not visible:
		return false
	_answer(false)
	return true


func _answer(yes: bool) -> void:
	if not visible:
		return  # one answer per open(): a double tap can't answer twice
	hide()
	if yes:
		confirmed.emit()
	else:
		cancelled.emit()

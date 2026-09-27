extends Control
## Step 3 stub of the offer (GDD S10): Accept, and Decline after a confirm. Step 6 builds the contract.

@onready var _header: Label = %Header
@onready var _contract: Label = %Contract
@onready var _back_button: Button = %BackButton
@onready var _decline_button: Button = %DeclineButton
@onready var _accept_button: Button = %AcceptButton
@onready var _pause: PauseMenu = %PauseMenu
@onready var _decline_dialog: ConfirmDialog = %DeclineDialog


func _ready() -> void:
	var offer: Dictionary = GameState.run.offer
	var company: String = Content.field("companies", str(offer.get("company_id", "")), "name")
	_header.text = Content.text("barks", "vs_offer")
	_contract.text = "\n".join(PackedStringArray([
		Content.text("emails", "offer_title", {"company": company}),
		Content.field("postings", str(offer.get("template_id", "")), "title"),
		Content.text("emails", "offer_salary", {"salary": UiText.money(int(offer.get("salary", 0)))}),
		Content.text("emails", "offer_mode_" + str(offer.get("tier", ""))),
	]))
	_back_button.text = UiText.back(Content.text("barks", "ui_back"))
	_decline_button.text = Content.text("barks", "ui_decline")
	_accept_button.text = UiText.primary(Content.text("barks", "ui_accept"))
	_back_button.pressed.connect(Device.handle_back)
	_decline_button.pressed.connect(_on_decline)
	_accept_button.pressed.connect(GameState.answer_offer.bind(true))
	_decline_dialog.confirmed.connect(GameState.answer_offer.bind(false))
	_pause.quit_to_title_pressed.connect(GameState.quit_to_title)


## Back closes the open dialog or sheet, else opens Pause. Back never declines an offer (ARCHITECTURE 9).
func handle_back() -> bool:
	if _decline_dialog.is_open():
		return _decline_dialog.handle_back()
	if _pause.is_open():
		return _pause.handle_back()
	_pause.open()
	return true


func _on_decline() -> void:
	_decline_dialog.open(Content.text("barks", "ui_decline_confirm"), Content.text("barks", "ui_decline"), "", true)

class_name JobCard
extends MarginContainer
## The DoomApply job card (GDD S04, ARCHITECTURE 11.4). Front: the tier's header strip, logo, company
## and tier, the job title, 3 tags checked against the CV as set, the joke, a knockout chip and the
## Quick Apply odds. Back: company and tier, applicants, posted, salary, the tailored odds and the
## referral toggle. It only shows and animates: the hub calls the GameState verbs.
## It is also the hub's swipe surface, one of the two Controls that read raw touch (INV-14): this
## root stays put and reads the finger, the Panel inside follows it, tilts and flies off.

## +1 = swiped right (Quick Apply), -1 = swiped left (Skip). The card waits where it was dropped:
## the hub answers with play_sent() + fling(), or settle() when the verb is refused.
signal swiped(direction: int)
signal tapped

const MAX_TILT_DEG := 6.0      # GDD 9.1
const SETTLE_SEC := 0.12
const FLING_SEC := 0.15        # GDD 9.1: off the side edge in 0.15 s
const FLIP_HALF_SEC := 0.08
const FLIP_MIN_SCALE := 0.05   # never 0: a zero scale can't be inverted for hit tests
const RISE_SEC := 0.12
const RISE_PX := 12.0
const SCAN_SEC := 1.0          # GDD S04: the Parsinator 3000 scan
const SCAN_READ_SHARE := 0.7   # the reading line sweeps, then "Keywords found: n/3"
const SCAN_LINE_PX := 2.0
const STAMP_SEC := 0.3         # GDD S04: the SENT stamp
const STAMP_SLAM_SEC := 0.1
const STAMP_FROM_SCALE := 2.0
const HIT_MARK := "v"          # stand-ins for the check and cross icons until the art pass (GDD 2.7)
const MISS_MARK := "x"
const HIT_COLOR := Color(0.38823530, 0.78039217, 0.3019608)
const MISS_COLOR := Color(0.89411765, 0.23137255, 0.26666668)
## Placeholder header strips until the 238x48 crops of the tier interview backgrounds exist (GDD 2.6),
## in the GDD 2.5 tier moods: startup purple neon, mid-size warm beige, big corp cool blue-grey.
const STRIP_COLORS: Dictionary = {
	"startup": Color(0.40784314, 0.21960784, 0.42352942),
	"mid": Color(0.78039217, 0.6627451, 0.5019608),
	"big": Color(0.3529412, 0.4117647, 0.53333336),
}

## A drag longer than a quarter of the base width is a swipe (GDD 9.1: 68 px of 270).
var _threshold: float = float(ProjectSettings.get_setting("display/window/size/viewport_width")) / 4.0
## A touch that moves less than the scroll deadzone is a tap (ARCHITECTURE 11.4).
var _deadzone: float = float(ProjectSettings.get_setting("gui/common/default_scroll_deadzone", 6))
var _touch := -1               # index of the finger being tracked; -1 = none
var _start := Vector2.ZERO
var _moved := 0.0              # the farthest the finger got from where it landed
var _armed := false            # the drag is past the threshold (its haptic already played)
var _offset := 0.0             # the Panel's shift from where the container put it
var _lift := 0.0               # the rise from the stack
var _flip := 1.0               # the Panel's x scale while flipping
var _rest := Vector2.ZERO
var _back := false
var _locked := false
var _referral := false
var _odds: Dictionary = {}
var _tween: Tween

@onready var _panel: PanelContainer = %Panel
@onready var _front: VBoxContainer = %Front
@onready var _strip: ColorRect = %Strip
@onready var _company: Label = %Company
@onready var _tier_tag: Label = %TierTag
@onready var _job_title: Label = %JobTitle
@onready var _tags: Array[Label] = [%Tag1, %Tag2, %Tag3]
@onready var _joke: Label = %Joke
@onready var _knockout: PanelContainer = %Knockout
@onready var _knockout_text: Label = %KnockoutText
@onready var _quick_odds: Label = %QuickOdds
@onready var _back_face: VBoxContainer = %Back
@onready var _back_title: Label = %BackTitle
@onready var _back_company: Label = %BackCompany
@onready var _applicants: Label = %Applicants
@onready var _posted: Label = %Posted
@onready var _reposted: Label = %Reposted
@onready var _salary: Label = %Salary
@onready var _back_knockout: PanelContainer = %BackKnockout
@onready var _back_knockout_text: Label = %BackKnockoutText
@onready var _tailored_odds: Label = %TailoredOdds
@onready var _referral_button: Button = %ReferralButton
@onready var _scan: ColorRect = %Scan
@onready var _scan_line: ColorRect = %ScanLine
@onready var _scan_text: Label = %ScanText
@onready var _stamp: PanelContainer = %Stamp
@onready var _stamp_text: Label = %StampText


func _ready() -> void:
	_reposted.text = Content.text("postings", "card_reposted")
	_stamp_text.text = Content.text("postings", "stamp_sent")
	_referral_button.toggled.connect(_on_referral_toggled)
	_set_face(false)


## Shows one board card from its front, at rest, with the referral off. odds = GameState.card_odds().
func show_card(card: Dictionary, odds: Dictionary, referral_tokens: int) -> void:
	_kill_tween()
	var template_id := str(card.get("template_id", ""))
	var company_id := str(card.get("company_id", ""))
	var tier_id := str(card.get("tier", ""))
	var company := Content.field("companies", company_id, "name")
	var title := Content.field("postings", template_id, "title")
	_strip.color = STRIP_COLORS.get(tier_id, STRIP_COLORS["mid"])
	_company.text = company
	_tier_tag.text = Content.field("tiers", tier_id, "tag")
	_job_title.text = title
	_joke.text = "\"%s\"" % Content.field("postings", template_id, "joke")
	_back_title.text = title
	_back_company.text = "%s - %s" % [company, Content.field("tiers", tier_id, "name")]
	_applicants.text = Content.text("postings", "card_applicants", {"n": UiText.count(int(card.get("applicants", 0)))})
	_posted.text = Content.text("postings", "card_posted", {"days": int(card.get("posted_days_ago", 0))})
	_reposted.visible = bool(card.get("reposted", false))
	_salary.text = Content.field("postings", template_id, "salary_text")
	_referral = false
	_referral_button.set_pressed_no_signal(false)
	update_odds(odds, referral_tokens)
	_back = false
	_set_face(false)
	_scan.hide()
	_stamp.hide()
	_offset = 0.0
	_lift = 0.0
	_flip = 1.0
	_panel.modulate.a = 1.0
	_apply()


## The parts that follow the CV and the tokens (tags, knockouts, odds, the referral toggle); the face
## and the position stay as they are.
func update_odds(odds: Dictionary, referral_tokens: int) -> void:
	_odds = odds
	var keywords: Dictionary = Content.entries("naming").get("_keywords", {})
	var rows: Array = odds.get("tags", [])
	for i: int in _tags.size():
		var label := _tags[i]
		label.visible = i < rows.size()
		if not label.visible:
			continue
		var row: Dictionary = rows[i]
		var hit := bool(row.get("hit", false))
		var tag := str(row.get("tag", ""))
		label.text = "[%s %s]" % [HIT_MARK if hit else MISS_MARK, tr(str(keywords.get(tag, tag)))]
		label.add_theme_color_override(&"font_color", HIT_COLOR if hit else MISS_COLOR)
	_show_quote(odds.get("quick", {}), "ui_odds_quick", _knockout, _knockout_text, _quick_odds)
	if referral_tokens <= 0 and _referral:
		_referral = false
		_referral_button.set_pressed_no_signal(false)
	_referral_button.visible = referral_tokens > 0
	_referral_button.text = Content.text("barks", "ui_use_referral", {"n": referral_tokens})
	_show_back_quote()


func is_back() -> bool:
	return _back


## Where the front's header strip ends, measured from the card's top at rest: first-run coach marks sit
## over the strip (GDD 4.3), so the hub keeps them this far above the card's bottom.
func strip_bottom() -> float:
	return _rest.y + _front.position.y + _strip.position.y + _strip.size.y


## True while the back's [Use referral] toggle is on.
func use_referral() -> bool:
	return _referral


## Locked: a send or a skip is playing, so touches are ignored.
func set_locked(locked: bool) -> void:
	_locked = locked


## Turns the card over (GDD S04: tap = flip) with a quick squeeze on the x axis.
func flip(to_back: bool) -> void:
	if to_back == _back:
		return
	_back = to_back
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_flip, _flip, FLIP_MIN_SCALE, FLIP_HALF_SEC)
	_tween.tween_callback(_set_face.bind(to_back))
	_tween.tween_method(_set_flip, FLIP_MIN_SCALE, 1.0, FLIP_HALF_SEC)


## Back to rest after a short drag or a refused swipe.
func settle() -> void:
	_kill_tween()
	if is_zero_approx(_offset):
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_method(_set_offset, _offset, 0.0, SETTLE_SEC)


## GDD S04, 9.1: the first applications of a run get the Parsinator 3000 scan (1 s), every one the
## SENT stamp (0.3 s). Played over the card where it is; await it.
func play_sent(scan: bool, hits: int) -> void:
	_kill_tween()
	if scan:
		_scan_text.text = Content.text("postings", "hirebot_scan")
		_scan.show()
		_set_scan_line(0.0)
		_tween = create_tween()
		_tween.tween_method(_set_scan_line, 0.0, 1.0, SCAN_SEC * SCAN_READ_SHARE)
		_tween.tween_callback(func() -> void:
			_scan_text.text = Content.text("postings", "hirebot_found", {"n": hits}))
		_tween.tween_interval(SCAN_SEC * (1.0 - SCAN_READ_SHARE))
		await _tween.finished
		_scan.hide()
	_stamp.show()
	_set_stamp(0.0)
	_tween = create_tween()
	_tween.tween_method(_set_stamp, 0.0, 1.0, STAMP_SLAM_SEC).set_ease(Tween.EASE_IN)
	_tween.tween_interval(STAMP_SEC - STAMP_SLAM_SEC)
	await _tween.finished


## Flies off the side edge (GDD 9.1: 0.15 s) and stays hidden until show_card(); await it.
func fling(direction: int) -> void:
	_kill_tween()
	_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_method(_set_offset, _offset, signf(direction) * (size.x + _threshold), FLING_SEC)
	await _tween.finished
	_panel.modulate.a = 0.0


## The next card rises from the stack (GDD 9.1).
func rise() -> void:
	_kill_tween()
	_panel.modulate.a = 0.0
	_set_lift(RISE_PX)
	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_lift, RISE_PX, 0.0, RISE_SEC)
	_tween.tween_property(_panel, "modulate:a", 1.0, RISE_SEC)


# ---------- swipe and tap (raw touch; the emulated mouse events are ignored here) ----------

func _gui_input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed and _touch == -1 and not _locked:
			_touch = touch.index
			_start = touch.position
			_moved = 0.0
			_armed = false
			_kill_tween()
		elif not touch.pressed and touch.index == _touch:
			_release(touch.canceled)
		accept_event()
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _touch:
		_moved = maxf(_moved, drag.position.distance_to(_start))
		if not _back:  # the back doesn't swipe: its actions are on the action row
			_set_offset(drag.position.x - _start.x)
			var armed := absf(_offset) > _threshold
			if armed and not _armed:
				Device.haptic()  # the swipe "clicks" before release (GDD 9.3)
			_armed = armed
		accept_event()


func _release(canceled: bool) -> void:
	_touch = -1
	if not canceled and not _back and absf(_offset) > _threshold:
		swiped.emit(1 if _offset > 0.0 else -1)
		return
	if not canceled and _moved <= _deadzone:
		_set_offset(0.0)
		tapped.emit()  # no settle() after it: that would kill the flip the tap just started
		return
	settle()


# ---------- drawing state ----------

func _show_quote(quote: Dictionary, label_id: String, chip: PanelContainer, chip_text: Label, odds_label: Label) -> void:
	var knockout: Dictionary = quote.get("knockout", {})
	chip.visible = not knockout.is_empty()
	if chip.visible:
		var reason := Content.text("postings", str(knockout.get("id", "")), knockout.get("args", {}))
		chip_text.text = Content.text("postings", "card_knockout", {"knockout": reason})
	var band := int(quote.get("band", 1))
	odds_label.text = "%s %s" % [Content.text("barks", label_id), UiText.band(band, Content.text("barks", "ui_odds_%d" % band))]


func _show_back_quote() -> void:
	_show_quote(_odds.get("referral" if _referral else "tailored", {}), "ui_odds_tailored",
		_back_knockout, _back_knockout_text, _tailored_odds)


func _on_referral_toggled(on: bool) -> void:
	_referral = on
	_show_back_quote()


## Both faces stay in the layout, so the card keeps one height; the hidden one is transparent and
## its toggle takes no taps.
func _set_face(back: bool) -> void:
	_front.modulate.a = 0.0 if back else 1.0
	_back_face.modulate.a = 1.0 if back else 0.0
	_referral_button.mouse_filter = Control.MOUSE_FILTER_STOP if back else Control.MOUSE_FILTER_IGNORE


func _set_offset(x: float) -> void:
	_offset = x
	_apply()


func _set_lift(y: float) -> void:
	_lift = y
	_apply()


func _set_flip(x_scale: float) -> void:
	_flip = x_scale
	_apply()


func _set_scan_line(progress: float) -> void:
	_scan_line.size = Vector2(_scan.size.x, SCAN_LINE_PX)
	_scan_line.position = Vector2(0.0, roundf(progress * maxf(_scan.size.y - SCAN_LINE_PX, 0.0)))


## progress 0 -> 1: the stamp slams from twice its size down onto the card.
func _set_stamp(progress: float) -> void:
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.scale = Vector2.ONE * lerpf(STAMP_FROM_SCALE, 1.0, progress)
	_stamp.modulate.a = progress


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


## Sorting puts the Panel back at rest (position, rotation, scale), so the shift is re-applied after it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and is_node_ready():
		_rest = _panel.position
		_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	_panel.pivot_offset = Vector2(_panel.size.x * 0.5, _panel.size.y)
	_panel.position = _rest + Vector2(roundf(_offset), roundf(_lift))
	_panel.rotation_degrees = clampf(_offset / _threshold, -1.0, 1.0) * MAX_TILT_DEG
	_panel.scale = Vector2(_flip, 1.0)

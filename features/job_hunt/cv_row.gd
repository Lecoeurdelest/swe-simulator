class_name CvRow
extends VBoxContainer
## One CV line on the CV screen (GDD S05): its label, the line as set (up to 60 characters on 2 lines),
## a full-width Honest | Polished | Lie segmented control (3 x 82 x 34) and the tags that line adds.
## It only shows and reports taps: the CV screen calls the GameState verb. The segments sit in a
## ScrollContainer, so they PASS their input on (the Step 2 drag-vs-tap result).

signal level_chosen(level: String)

@onready var _label: Label = %Label
@onready var _text: Label = %Text
@onready var _tags: Label = %Tags
@onready var _segments: Dictionary[String, Button] = {"honest": %Honest, "polished": %Polished, "lie": %Lie}


func _ready() -> void:
	var group := ButtonGroup.new()
	_segments["honest"].text = Content.text("barks", "ui_honest")
	_segments["polished"].text = Content.text("barks", "ui_polished")
	_segments["lie"].text = Content.text("barks", "ui_lie")
	for level: String in _segments:
		var button := _segments[level]
		button.button_group = group
		button.toggled.connect(func(on: bool) -> void:
			if on:
				level_chosen.emit(level))


func set_label(text: String) -> void:
	_label.text = text


## entry = this background's cv_lines.json entry at `level` (RunState.cv_line); keywords = the
## naming.json keyword names.
func show_line(entry: Dictionary, level: String, keywords: Dictionary) -> void:
	_text.text = tr(str(entry.get("text", "")))
	var names: PackedStringArray = []
	for tag: Variant in entry.get("tags", []):
		names.append(tr(str(keywords.get(str(tag), str(tag)))))
	_tags.text = ", ".join(names) if not names.is_empty() else "-"
	for each: String in _segments:
		_segments[each].set_pressed_no_signal(each == level)


func segment(level: String) -> Button:
	return _segments.get(level)

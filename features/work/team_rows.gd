class_name TeamRows
extends VBoxContainer
## The team under the job line (D-40, GDD 5.18): one two-line row per coworker, the name and role, then their card line
## (CONTENT 16.1). A desk that has gone dark shows "(desk empty)" and fades; the rows clear with the job. It shows what
## WorkHud.team gives it, and only rebuilds when that changes, because the screen refreshes every day.

const GONE_COLOR := Color(0.45, 0.47, 0.55)

var _signature := ""


func show_team(rows: Array) -> void:
	var signature := JSON.stringify(rows)
	if signature == _signature:
		return
	_signature = signature
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	for row: Dictionary in rows:
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if bool(row["gone"]):
			label.text = "%s  %s" % [row["name"], Content.text("barks", "ui_desk_empty")]
			label.add_theme_color_override(&"font_color", GONE_COLOR)
		else:
			label.text = "%s - %s\n%s" % [row["name"], tr(String(row["role"])), tr(String(row["line"]))]
		add_child(label)
	visible = not rows.is_empty()

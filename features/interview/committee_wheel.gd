class_name CommitteeWheel
extends Control
## The Hiring Committee wheel (GDD 5.8.6, S09): a 128 px pie whose win wedge is drawn at the real odds,
## with the odds printed on it (visible luck, GDD 5.13). It only shows a result: the interview rolls the
## outcome on its RNG first, then spin() stops the pointer in the middle of that wedge.

const WIN_COLOR := Color(0.0, 0.894, 0.212)     # the Answer Meter's NAILED IT green
const LOSE_COLOR := Color(0.114, 0.169, 0.325)  # the Answer Meter's Rambling navy
const TURNS := 3
const ARC_POINTS := 48

var _win_p := 0.5
var _turn := 0.0  # the pointer, in turns clockwise from 12 o'clock


func show_odds(win_p: float) -> void:
	_win_p = clampf(win_p, 0.0, 1.0)
	_turn = 0.0
	show()
	queue_redraw()


## Spins for `seconds`, easing out, and stops in the middle of the win or the lose wedge.
func spin(won: bool, seconds: float) -> void:
	var stop_at := _win_p * 0.5 if won else _win_p + (1.0 - _win_p) * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_turn, 0.0, TURNS + stop_at, seconds)
	await tween.finished


func _set_turn(turn: float) -> void:
	_turn = turn
	queue_redraw()


func _draw() -> void:
	var center := (size * 0.5).floor()
	var radius := floorf(minf(size.x, size.y) * 0.5) - 1.0
	draw_circle(center, radius, LOSE_COLOR)
	if _win_p > 0.0:
		var wedge := PackedVector2Array([center])
		var steps := maxi(2, ceili(ARC_POINTS * _win_p))
		for i: int in steps + 1:
			wedge.append(center + _direction(_win_p * i / steps) * radius)
		draw_colored_polygon(wedge, WIN_COLOR)
	draw_arc(center, radius, 0.0, TAU, ARC_POINTS, Color.WHITE, 1.0)
	var font := get_theme_default_font()
	var font_size := get_theme_default_font_size()
	var odds := "%d%%" % roundi(_win_p * 100.0)
	var text_size := font.get_string_size(odds, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var at := center + _direction(_win_p * 0.5) * radius * 0.55
	draw_string(font, (at - Vector2(text_size.x * 0.5, text_size.y * 0.5 - font.get_ascent(font_size))).floor(),
		odds, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.BLACK)
	draw_line(center, center + _direction(_turn) * (radius - 4.0), Color.WHITE, 2.0)
	draw_circle(center, 3.0, Color.WHITE)


static func _direction(turn: float) -> Vector2:
	var angle := TAU * turn - PI * 0.5  # 0 turns = 12 o'clock, clockwise
	return Vector2(cos(angle), sin(angle))

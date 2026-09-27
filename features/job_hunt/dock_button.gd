class_name DockButton
extends Button
## One slot of the DoomApply dock (GDD S04, 2.8 #4): a 16x16 icon above a label of up to 6 characters
## (the DockButton theme variation keeps the label at the bottom), and a gold badge while `badge` is on
## (Mail: an invite is waiting). The icon is a plain drawn placeholder until the art pass gives each
## app its 16x16 icon.

enum Glyph { APP, MOON }

const ICON := Vector2(16, 16)
const ICON_TOP := 4.0
const ICON_COLOR := Color(0.54509807, 0.60784316, 0.7058824)
const MOON_COLOR := Color(0.99607843, 0.90588236, 0.38039216)
const MOON_RADIUS := 7.0
const MOON_BITE := Vector2(4, -3)   # the second circle that carves the crescent
const BADGE := Vector2(6, 6)
const BADGE_INSET := 3.0
const BADGE_COLOR := Color(0.99607843, 0.90588236, 0.38039216)  # the gold of the "Invite waiting" pill

@export var glyph: Glyph = Glyph.APP:
	set(value):
		glyph = value
		queue_redraw()
@export var badge: bool = false:
	set(value):
		badge = value
		queue_redraw()


## Runs after the Button has drawn its stylebox, so the icon and the badge sit on top of it.
func _draw() -> void:
	var origin := Vector2(floorf((size.x - ICON.x) * 0.5), ICON_TOP)
	match glyph:
		Glyph.MOON:
			var center := origin + ICON * 0.5
			var box := get_theme_stylebox(&"normal") as StyleBoxFlat
			draw_circle(center, MOON_RADIUS, MOON_COLOR)
			if box != null:
				draw_circle(center + MOON_BITE, MOON_RADIUS - 1.0, box.bg_color)
		_:
			draw_rect(Rect2(origin, ICON).grow(-0.5), ICON_COLOR, false, 1.0)
			draw_rect(Rect2(origin + Vector2(4, 4), Vector2(8, 2)), ICON_COLOR)
			draw_rect(Rect2(origin + Vector2(4, 8), Vector2(6, 2)), ICON_COLOR)
	if badge:
		draw_rect(Rect2(Vector2(size.x - BADGE.x - BADGE_INSET, BADGE_INSET), BADGE), BADGE_COLOR)

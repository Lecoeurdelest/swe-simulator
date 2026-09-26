class_name SafeAreaMargin
extends MarginContainer
## Put every tappable thing inside one of these; keep backgrounds outside it (full-bleed).
## Portrait: the Dynamic Island / notch is the top inset, the home indicator the bottom one.
## Left and right use the larger inset on both sides, in case a device reports asymmetric insets.

@export var min_margin: int = 4
@export var debug_fake_insets := Vector4i.ZERO  # game px (left, top, right, bottom): preview a notch on desktop


func _ready() -> void:
	Device.layout_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var inset := Vector4(debug_fake_insets) if debug_fake_insets != Vector4i.ZERO else Device.safe_insets()
	var side := maxi(ceili(maxf(inset.x, inset.z)), min_margin)
	add_theme_constant_override(&"margin_left", side)
	add_theme_constant_override(&"margin_right", side)
	add_theme_constant_override(&"margin_top", maxi(ceili(inset.y), min_margin))
	add_theme_constant_override(&"margin_bottom", maxi(ceili(inset.w), min_margin))

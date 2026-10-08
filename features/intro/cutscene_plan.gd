@tool
class_name CutscenePlan
extends RefCounted
## The intro's play order from cutscene.json (GDD S02, ARCHITECTURE 11.2), as plain data. Pure, like
## UiText: the intro scene passes in Content.entries("cutscene"), so tests can run it on the file itself.

const STYLE_TITLE := "title"   # a caption that renders as the title card, not in the dialogue box


## The panels in "order" (ties by id): [{id, order, seconds, captions: [{speaker, text, style}]}].
## An entry without an "order" or without a caption with text is not a panel ("_" notes, plain strings). A caption may say
## "for": "choose" (the question that leads to Background select) or "handover" (the line that leads to day 0 of a career's
## run 1, MC-11); each plays only in its own intro. handover says which intro this is.
static func panels(entries: Dictionary, handover: bool = false) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: Variant in entries:
		var entry: Variant = entries[id]
		if not (entry is Dictionary) or not (entry as Dictionary).has("order"):
			continue
		var captions: Array[Dictionary] = []
		for caption: Variant in (entry as Dictionary).get("captions", []):
			if caption is Dictionary and not str((caption as Dictionary).get("text", "")).is_empty() and _plays(caption, handover):
				captions.append({
					"speaker": str(caption.get("speaker", "")),
					"text": str(caption["text"]),
					"style": str(caption.get("style", "")),
				})
		if captions.is_empty():
			continue
		out.append({"id": str(id), "order": int(entry["order"]), "seconds": float(entry.get("seconds", 0.0)),
			"captions": captions})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["order"] < b["order"] or (a["order"] == b["order"] and a["id"] < b["id"]))
	return out


## A caption that says "for": "handover" plays only in the intro that hands over to day 0, one that says "choose" only in
## the other; the rest play in both.
static func _plays(caption: Dictionary, handover: bool) -> bool:
	match str(caption.get("for", "")):
		"handover":
			return handover
		"choose":
			return not handover
	return true


## The whole intro's pan time in seconds (GDD S02 wants 40 or less).
static func total_seconds(plan: Array[Dictionary]) -> float:
	var total := 0.0
	for panel: Dictionary in plan:
		total += float(panel["seconds"])
	return total


## Where a panel's picture sits in the frame at the start and at the end of its "seconds": a picture
## wider than the frame pans sideways across its extra width, a taller one tilts down, one the frame's
## size stays still (GDD 2.6: 270x480, up to 480x480 for a pan, 270x720 for a tilt). Whole pixels.
static func pan_path(picture: Vector2, frame: Vector2) -> Array[Vector2]:
	var extra := (picture - frame).max(Vector2.ZERO).floor()
	return [Vector2.ZERO, -extra]

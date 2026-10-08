@tool
class_name ContractText
extends RefCounted
## The contract paper's lines (GDD S10, CONTENT 13.1), from the paper dictionary and the emails.json entries. Pure, so a
## test can measure the real paper: pre-wrapped at 40 columns by UiText.word_wrap and UiText.field, one field per line
## after a 12-character label, values wrapping at 28. The offer screen shows exactly these lines; the career run's paper
## (DuelAdapter.offer_paper) adds the Clauses field.

const COLUMNS := 40            # GDD 2.7: the 254 px paper holds 40 characters of monogram 16
const LABEL_COLUMNS := 12      # GDD S10: one field per line after a 12-character label column
const MAX_LINES := 20          # about a 250 px paper: 20 lines of 12 px plus the panel's margins


static func lines(paper: Dictionary, emails: Dictionary, company: String, player_name: String) -> PackedStringArray:
	var out := PackedStringArray()
	var commute: Dictionary = paper.get("commute", {})
	out += UiText.word_wrap(_text(emails, "offer_title", {"company": company}), COLUMNS)
	out += UiText.word_wrap(_text(emails, "offer_dear", {"player_name": player_name}), COLUMNS)
	out += UiText.word_wrap(_text(emails, "offer_role", {"job_title": str(paper.get("job_title", ""))}), COLUMNS)
	out.append("")
	out += _field(_text(emails, "offer_label_salary"),
		_text(emails, "offer_salary", {"salary": UiText.money(int(paper.get("salary", 0)))}))
	if str(paper.get("equity_text", "")) != "":
		out += _field(_text(emails, "offer_label_equity"), _text(emails, str(paper["equity_text"])))
	out += _field(_text(emails, "offer_label_mode"), _text(emails, str(paper.get("work_mode", ""))))
	out += _field(_text(emails, "offer_label_commute"), _text(emails, str(commute.get("id", "")), commute.get("args", {})))
	var label := _text(emails, "offer_label_perks")
	for perk: Variant in paper.get("perks", []):
		out += _field(label, _entry_text(emails, str(perk)))
		label = ""
	var clauses: Array = paper.get("clauses", [])
	if not clauses.is_empty():
		var parts := PackedStringArray()
		for clause: Variant in clauses:
			parts.append(_text(emails, "clause_" + str(clause)))
		out += _field(_text(emails, "offer_label_clauses"), " ".join(parts))
	out += _field(_text(emails, "offer_label_fine_print"), _entry_text(emails, str(paper.get("fine_print", ""))))
	out += UiText.word_wrap(_text(emails, "offer_deadline"), COLUMNS)
	return out


static func _field(label: String, value: String) -> PackedStringArray:
	return UiText.field(label, value, LABEL_COLUMNS, COLUMNS)


## A plain-string entry (offer_title, offer_dear, ...) with its {placeholders} filled.
static func _text(emails: Dictionary, id: String, args: Dictionary = {}) -> String:
	return UiText.fill(str(emails.get(id, "")), args)


## A perk or fine-print entry: {tiers, text}.
static func _entry_text(emails: Dictionary, id: String) -> String:
	var entry: Variant = emails.get(id, {})
	return str((entry as Dictionary).get("text", "")) if entry is Dictionary else str(entry)

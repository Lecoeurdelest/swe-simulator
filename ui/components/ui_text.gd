@tool
class_name UiText
extends RefCounted
## How labels and money look on screen (GDD 4.2 mockups). Pure string helpers: scenes pass in text
## from Content.text(), so the words stay in the JSON (INV-15) and only the styling lives here.
## Agent default, please review (Step 4): CONTENT.md keeps each label in its normal case, and a
## PrimaryButton shows it in capitals, as the mockups do ([ CONTINUE ], [ NEW RUN ]). To drop the
## capitals, make primary() return its text unchanged.

const BACK_ARROW := "< "  # stands in for the back-arrow icon until the art pass


## Label for a PrimaryButton: "Continue" -> "CONTINUE".
static func primary(text: String) -> String:
	return text.to_upper()


## Label for the action bar's bottom-left Back slot: "Back" -> "< Back", "Title" -> "< Title".
static func back(text: String) -> String:
	return BACK_ARROW + text


## A button that costs energy shows the pips after its label, as the GDD S04 mockup does:
## ("APPLY", 1) -> "APPLY  1", ("TAILOR & APPLY", 2) -> "TAILOR & APPLY  2".
static func cost(text: String, pips: int) -> String:
	return "%s  %d" % [text, pips]


## A text meter, filled from the left: (3, 5) -> "[###--]". The Recruiter Radar and the odds bands.
static func meter(filled: int, total: int) -> String:
	var dots := clampi(filled, 0, maxi(total, 0))
	return "[%s%s]" % ["#".repeat(dots), "-".repeat(maxi(total, 0) - dots)]


## An odds band as dots plus a word (GDD 2.7, 5.6): band 3 of 5, "Possible" -> "[###--] Possible".
static func band(filled: int, word: String, total: int = 5) -> String:
	return "%s %s" % [meter(filled, total), word]


## A whole number with thousands separators: 1247 -> "1,247" (the card back's applicants).
static func count(amount: int) -> String:
	var digits := str(absi(amount))
	var groups := ""
	while digits.length() > 3:
		groups = "," + digits.right(3) + groups
		digits = digits.left(-3)
	return ("-" if amount < 0 else "") + digits + groups


## Whole dollars as the offer letter shows them: 71000 -> "$71,000".
static func money(amount: int) -> String:
	var grouped := count(absi(amount))
	return ("-" if amount < 0 else "") + "$" + grouped


## Word wrap as an autowrapped Label does it, and as test_content_lint counts lines: a word moves to
## the next line when it would pass `columns`, a word longer than a whole line is cut, "\n" starts a
## line. monogram is monospaced, so columns are exact.
static func word_wrap(text: String, columns: int) -> PackedStringArray:
	var out := PackedStringArray()
	for paragraph: String in text.split("\n"):
		var line := ""
		for word: String in paragraph.split(" ", false):
			if line.is_empty():
				line = word
			elif line.length() + 1 + word.length() <= columns:
				line += " " + word
			else:
				out.append(line)
				line = word
			while line.length() > columns:
				out.append(line.left(columns))
				line = line.substr(columns)
		out.append(line)
	return out


## One field of the offer contract (GDD S10): the label in a column label_columns wide, the value
## wrapped in the columns left of the line, its wrapped lines indented under the first. An empty label
## continues the field above. ("Perks:", "Kombucha on tap", 12, 40) -> ["Perks:      Kombucha on tap"].
static func field(label: String, value: String, label_columns: int, columns: int) -> PackedStringArray:
	var out := PackedStringArray()
	var lines := word_wrap(value, columns - label_columns)
	for i: int in lines.size():
		out.append((label.rpad(label_columns) if i == 0 else " ".repeat(label_columns)) + lines[i])
	return out

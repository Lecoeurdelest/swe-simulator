@tool
class_name WorkBoard
extends RefCounted
## What the DoomApply board shows (GDD 5.20, D-41, P-02), as plain data: the postings as nodes with their yearly pay,
## clauses and callback dots, the applications waiting on a reply, and whether you can apply or study. Pure, like
## WorkHud: it reads a SimState and changes nothing, so the board scene only draws what it is told (INV-03) and a test
## can check each number. A node carries ids and numbers, never text.


## The board's postings, in the sim's order, as {id, company, archetype, level, floor, salary (yearly, whole dollars),
## remote, clauses, dots (1-5)}. The dots are the callback odds' band (WorkOdds.callback_dots); the odds themselves are
## never shown (pillar 3).
static func nodes(s: SimState, ctx: SimContext) -> Array:
	var out: Array = []
	var refs := Sim.references(s, ctx.cfg)
	for p: Dictionary in s.board:
		var odds := WorkOdds.callback_p(ctx.cfg, int(p["level"]), s.level, s.scar_short_tenure, refs)
		out.append({
			"id": int(p["id"]), "company": String(p["company"]), "archetype": String(p["archetype"]), "level": int(p["level"]),
			"floor": int(p.get("floor", 1)), "salary": WorkOdds.yearly_salary(ctx.cfg, float(p["salary"])),
			"remote": bool(p.get("remote", false)), "clauses": (p.get("clauses", []) as Array).duplicate(),
			"dots": WorkOdds.callback_dots(ctx.cfg, odds),
		})
	return out


## The applications still in flight, soonest first: {company, kind ("reply" or "interview"), day}. A duel waiting on the
## screen or an offer waiting on the contract is not listed: those have a card of their own.
static func waiting(s: SimState) -> Array:
	var out: Array = []
	for app: Dictionary in s.applications:
		var company := String((app["posting"] as Dictionary).get("company", ""))
		match String(app.get("status", "")):
			"wait":
				out.append({"company": company, "kind": "reply", "day": int(app["reply"])})
			"callback":
				out.append({"company": company, "kind": "interview", "day": int(app["interview"])})
			"between":
				out.append({"company": company, "kind": "interview", "day": int(app["next_duel"])})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return out


## Applying is off only at job 5, where there is no next floor (D-16, A72).
static func can_apply(s: SimState, cfg: WorkConfig) -> bool:
	return not (s.employed and s.jobs_held >= cfg.max_jobs)


## The Burnout an application costs: more while you still hold a job to lose.
static func apply_burnout(s: SimState, cfg: WorkConfig) -> float:
	return cfg.apply_burnout_employed if s.employed else cfg.apply_burnout_unemployed


## Study is one a day.
static func can_study(s: SimState) -> bool:
	return s.last_study_day != s.day


## Days until the board's postings are replaced (0 on the day it refreshes).
static func days_to_refresh(s: SimState, cfg: WorkConfig) -> int:
	return maxi(0, cfg.board_refresh_days - (s.day - s.board_day))

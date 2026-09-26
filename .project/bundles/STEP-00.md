# Bundle: STEP-00 (Tools, decisions and reading)

Snapshot: 2026-09-26, docs at 64ed38f. Spec: [ROADMAP Step 0](../../docs/ROADMAP.md). State: `in_progress`.

## Objective

Git works, the engine version is pinned, and every open design decision D1-D8 has the developer's answer.

## Criteria

| ID | Statement | Status |
|---|---|---|
| AC-S00-1 | `git --version` works in a fresh terminal; name and email set | pass (git 2.55.0) |
| AC-S00-2 | The Godot install won't update itself behind your back | pending (developer) |
| AC-S00-3 | `docs/DECISIONS.md` lists D1-D8, each with an answer and one line of why | pending (developer) |

## Inputs

- GDD section 0, 1.2, 4.1 and **12** (D1-D8 with recommended defaults); skim CONTENT.md for tone.
- Names to confirm: protagonist **Alex** (re-rollable), interviewer **Dana**.

## Claude does

- Explains each decision's trade-off in plain words, one at a time; "default" is a fine answer.
- Writes `docs/DECISIONS.md`: one line per decision, `Dn - answer - why`.

## Developer does

- Answers D1-D8 in their own words.
- Pins Godot. ROADMAP says Steam, but this Mac runs `/Applications/Godot.app` (ISSUE-01): if it isn't the Steam build, pinning means "don't replace the app mid-step; export templates must stay 4.7.2".

## Out of scope

- Rewriting the GDD. Changes of mind go to `docs/DECISIONS.md`.

## Stop conditions

- A decision answer contradicts a GDD rule: record it in DECISIONS.md and flag which GDD/ARCHITECTURE lines it affects; don't edit them silently.

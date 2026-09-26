# Bundle: STEP-00 (Tools, decisions and reading)

Snapshot: 2026-09-27, docs v1.1 (portrait, iPhone first; uncommitted on top of 6f40919). Spec: [ROADMAP Step 0](../../docs/ROADMAP.md). State: `in_progress`.
Earlier snapshot: 2026-09-26, docs v1.0 at 64ed38f (D1-D8 open, the Mac toolchain question in ISSUE-01).

## Objective

Git works, the engine version is pinned, and every open design decision D1-D8 has the developer's answer.

## Criteria

| ID | Statement | Status |
|---|---|---|
| AC-S00-1 | Git works, name and email are set, and the repo is on GitHub | **inconclusive** (audit 2026-09-27): r2 shows git 2.53.0 on the PC, user.name and the Mac's commit 6f40919 there, but no saved run shows user.email or the GitHub remote. Save them (email: set or not, never the value) in the next run, or the developer confirms |
| AC-S00-2 | Steam won't update Godot on the Windows PC behind your back | pending (developer) |
| AC-S00-3 | `docs/DECISIONS.md` lists D1-D8 and P1, each with an answer and one line of why | pass (developer, 2026-09-26: D1 portrait, D2-D8 defaults, P1 iPhone first) |

## Decisions (docs/DECISIONS.md, 2026-09-26)

| ID | Answer |
|---|---|
| D1 | Portrait only (`orientation = 1`) |
| D2 | 270x480 base, viewport + expand + integer, plus the `Device` scale guard |
| D3-D8 | The recommended defaults (Answer Meter; 3 CV lines x Honest/Polished/Lie; Plan B + grace day + Retry; background + name dice; one-tap Negotiate; Doubt HP 118/128/132 until Playtest #1) |
| P1 | iPhone first, built on the MacBook; Android LATER |
| C1 | 12 parody names renamed after a trademark web check; content ids unchanged |

## Inputs

- GDD section 0, 1.2, 2.8 (one-thumb touch rules), 4.1 and 12; skim CONTENT.md for tone.
- `docs/DECISIONS.md`. Names: protagonist **Alex** (re-rollable), interviewer **Dana**.

## Claude does

- Done: explained each decision's trade-off and wrote `docs/DECISIONS.md`, one line each with the reason.
- A later change of mind: a new superseding row in `docs/DECISIONS.md` first, then the GDD section it points to (GDD 12).

## Developer does

- Pin Godot on the Windows PC: in Steam, set Godot Engine to update only when launched (the option name is unverified: Properties > Updates; ARCHITECTURE 18.1 #11). The Mac uses the godotengine.org 4.7.2 zip, which never updates itself.
- The reading (about 2 h), and the You-do: reread `docs/DECISIONS.md` and say each decision back in your own words.

## Out of scope

- Rewriting the GDD. Changes of mind go to `docs/DECISIONS.md` first.

## Stop conditions

- A decision answer contradicts a GDD rule: record it in DECISIONS.md and flag which GDD/ARCHITECTURE lines it affects; don't edit them silently.
- Running installers through Claude on Windows (MSIX AppData virtualization): the developer runs them.

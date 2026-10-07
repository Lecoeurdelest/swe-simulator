# Ideas parking lot

Ideas wait here until you (the developer) schedule them. Nothing on this page is designed or built, and nothing here is a decision: when you pick one up, it goes through a design huddle and gets a row in `docs/DECISIONS.md` first, then a scope tag (MUST / SHOULD / LATER) in the GDD. A new idea replaces something already planned; it never just adds to the pile (ROADMAP 1, best practice 8; risk 1). Park an idea as one short entry: what it is, who raised it and when, and anything already ruled in or out.

## Phase 2 (the working life): picked up by the Run Spec v1 (2026-10-07)

**Status:** picked up. The Run Spec v1 is the working life (DECISIONS W8, superseding P3's "not decided yet"), merged into the docs on 2026-10-07 and built as M1-M6 (ROADMAP 12). Where your first ideas went:

- **Small random events at the company** became the career run's events (GDD 5.19): an incident (E12), a phishing test (E13), a coworker who clicks a scam (E14), a hardcoded secret (E15), and the resizing (E07), the company's "resize" with its five warning signs in run 1. "Kept small" changed, though: in the Run Spec, events are the game, about 25 decisions a year (RC-18).
- **A few minor career improvements** became promotions (GDD 5.16), controls that grow with your level (5.17) and the Handbook's small, capped edges (5.21).
- **No cosmetic customization for now** still holds: D-01 ("no cosmetics") agrees with D6 (GDD 5.2, 10.3).

Your entry as you gave it (developer, 2026-09-29), kept for the record: Phase 2 is what happens after the Hired card ("TO BE CONTINUED - Phase 2: The Working Life"); don't build anything until its mechanic is chosen. Small random events at the company, kept small (the company gets hacked; a coworker clicks a scam email; the company "resizes"). A few minor career improvements, also kept small. No cosmetic customization for now. The lying hooks it used to list (`cv_levels`, `lies_carried`, imposter-debt tasks) left with D9.

## Best Dream score per background (LATER, D10)

Remember your best Dream vs Reality score for each background across runs and show it (GDD 3.1 meta, 5.9.5). You answered REVIEW_QUEUE Q2 with LATER on 2026-09-29, so the settings file doesn't store it yet. (In the career run every ending card shows a career-long Dream score whose formula is Open, MC-09.)

## A rent tip for E04 (D-28, 2026-10-07)

E04, the lease renewal, lost its Ducky tip ("Landlords negotiate too; ask before you sign") with its negotiation, so it has no tip for now (an explicit none). A new, true rent tip can come with M6's Ducky writing pass, with your sign-off (GDD 8.6).

## A CI job for the tests and the harness (RC-32, 2026-10-07)

The Run Spec wants the harness and the content lint "in CI" so a tuning change can't silently break an objective. The repo has no CI, so they run with the headless runner before every commit that changes a tuning number or an event (GDD 5.22). A GitHub Actions job that runs Godot 4.7.2 headless could do it on every push later.

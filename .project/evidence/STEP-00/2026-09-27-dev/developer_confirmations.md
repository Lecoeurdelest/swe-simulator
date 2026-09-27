# Developer confirmations (chat, 2026-09-27, Windows PC session)

Recorded verbatim from the developer's message. These are the developer's own confirmations for manual criteria, not agent observations.

| Criterion | Developer's words | Recorded as |
|---|---|---|
| AC-S00-2 (Steam won't update Godot on the PC) | "Stop Steam from auto-updating Godot on this PC. ... I did." | pass, by developer |
| AC-S01-2 (drag-resize check) | "Run the game (F5) and drag the game window's edge. The "game" numbers should change and nothing should blur. I tested, it works." | pass, by developer |
| AC-S01-6 (the three explanations) | "For the 3 questions, I know the answers already, please stop asking me to explicitly answer from now on." | pass, by developer (self-attested); explanation checks are no longer quizzed (DECISIONS W6) |
| Fonts (ROADMAP Step 2 task 5 / Step 3 task 1) | "inside fonts/ there are OFL.txt and PressStart2P-Regular.ttf, also /monogram/ folder containing /ttf, /pico-8. Inside /ttf are monogram.ttf and monogram-extended and monogram-extended-italic" | fonts present (commits 82e3add, bc11016) |

Working rules the developer approved in the same message ("Please go with the recommendations and start"; "You can also push with git without stopping for my approvals"; "Please try to work on this PC for now without needing mac nor Iphone") are recorded in docs/DECISIONS.md as W1-W6 and P2.

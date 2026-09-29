# Kill tests (Step 6)

A phone kills background apps without warning, so the game saves after every committed action and when it loses focus (ARCHITECTURE 8, 9; GDD 5.11). This checklist is the ROADMAP Step 6 iPhone check (it stays yours: DECISIONS W7 suspended only the learning exercises): kill the game at 5 moments and check that CONTINUE puts you back where the table says. It takes about 15 minutes.

## How to kill the game

| Where | Kill | Resume |
|---|---|---|
| iPhone | Swipe up from the bottom edge and hold to open the app switcher, then swipe the game's card up and away. | Open the game again and tap CONTINUE on the title. |
| Desktop (the editor) | Stop the running game (the editor's Stop button, F8, or godot-ai `project_manage op=stop`). This is harsher than the iPhone: the game gets no "paused" notification, so it can't save on the way out. | Run the project again and tap CONTINUE. |

Start a fresh run (New game on the title) and play it through the 5 moments in order: one run covers all of them. For the interview you need an invite: on your first run, apply to 3 or more cards on day 1 and the day-2 morning brings one (GDD 5.7); debug builds also have the hub's DEBUG row (fake invite). Moment 4 needs a won interview, and a harder run may reach Plan B before it wins one: in debug builds the interview's DBG panel has K.O., which goes straight to the offer.

## The 5 moments

| # | Kill when | Expected after CONTINUE |
|---|---|---|
| 1 | **Mid-hunt:** on Jobs after a couple of APPLY taps (on a first run, tap a Ducky note closed too). | The hub on the same day, with the same energy, the same top card and deck and the same applications sent. A Ducky note you tapped closed stays closed. |
| 2 | **Right after Sleep:** while the night lock screen shows. | The same night summary again ("Applied N - Rejected N - ..."), then a tap shows the same morning inbox. Sleep is not run twice: same day number, same mail. |
| 3 | **Mid-interview:** after answering a question or two. | The same interview starts again from the VS intro (it waits for your tap): same company, same questions in the same order, Doubt and Composure full again. The energy was paid once (not again), the invite is gone from Mail, and today's interview stays used. |
| 4 | **On the offer:** while the paper contract shows. | The same contract: company, role, salary, work mode, commute, both perks and the fine print unchanged. ACCEPT and Decline work. |
| 5 | **On the Hired card:** after ACCEPT, while HIRED! or the Dream vs Reality tally shows. | The **offer** again (the Hired card is never saved), with the same contract. ACCEPT gives the same Hired card and the same Dream score. Then leave it with `< Title` or NEW RUN: the title no longer shows CONTINUE (the save is cleared). |

## If one fails

Write down the moment, what you saw and what you expected, and leave the phone as it is if you can. Common causes are in ROADMAP Step 6 "Pitfalls": a Node saved in the run, `morning_report` not cleared on Start day, a Decline that doesn't blacklist the company.

## Results

| Date | Device | 1 | 2 | 3 | 4 | 5 | Notes |
|---|---|---|---|---|---|---|---|
| 2026-09-27 | Windows PC, desktop kill (Claude) | pass | pass | pass | pass | pass | `.project/evidence/STEP-06/2026-09-27-r1/kill_tests_log.md` |
| | iPhone (developer) | | | | | | |

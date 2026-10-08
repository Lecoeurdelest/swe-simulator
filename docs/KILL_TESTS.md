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

## The career run (Run Spec v1, built in M2)

O8 asks for this: kill the app mid-run, and the state restores identically (GDD 13.1). The career run saves at every event, after every player input and when the app goes to background (GDD 5.11, RC-35), so "identically" means the state of the last save, and M1 proved the restore itself: a `SimState.to_save()` round trip is bit for bit and lives the same days (`test_sim_replay`; the save must be `to_save`, not plain JSON numbers, because Godot's JSON parser can read a double back one unit in the last place off: DECISIONS A75). On the iPhone a kill comes after the pause notification, so nothing is lost; the desktop's harsher stop can lose the days since the last save, never a choice. M2 built the work state (ROADMAP Step 15), and moments 6, 7, 8 and 11 were killed on the desktop on 2026-10-08 (the results table below); M3 adds the duel and the scene's moments:

| # | Kill when | Expected after CONTINUE |
|---|---|---|
| 6 | the clock running, no card open | the same day (on the desktop: the day of the last event or input), the same numbers, the same Hours notch; the clock waits, paused, until you start it |
| 7 | an event card open, before you choose | the same card with the same choices; an auto-resolve isn't rolled again |
| 8 | right after a choice | the choice made, its effects applied once |
| 9 | mid-review duel (M3) | the same review from its start, with the same prompts (as moment 3) |
| 10 | during the layoff scene (a plain version in M2, the full scene in M3) | the scene again from its start; the job is lost and the severance paid only once |
| 11 | on an ending card | no CONTINUE: the save was deleted on entering the ending |
| 12 | mid-interview, a career interview from the board (M3) | the same interview from its start: the same questions and the same luck (the checkpoint travels in the career save) |
| 13 | on the contract, before you sign (M3) | the same contract paper, nothing accepted: you still hold your job |
| 14 | during the HIRED! stamp after signing (M3) | the contract again, not accepted: Accept commits when a tap moves on |

## If one fails

Write down the moment, what you saw and what you expected, and leave the phone as it is if you can. Common causes are in ROADMAP Step 6 "Pitfalls": a Node saved in the run, `morning_report` not cleared on Start day, a Decline that doesn't blacklist the company.

## Results

| Date | Device | 1 | 2 | 3 | 4 | 5 | Notes |
|---|---|---|---|---|---|---|---|
| 2026-09-27 | Windows PC, desktop kill (Claude) | pass | pass | pass | pass | pass | `.project/evidence/STEP-06/2026-09-27-r1/kill_tests_log.md` |
| | iPhone (developer) | | | | | | |

The career run's moments (6-14; the headers show 6-11, and moments 12-14 are in the notes):

| Date | Device | 6 | 7 | 8 | 9 | 10 | 11 | Notes |
|---|---|---|---|---|---|---|---|---|
| 2026-10-08 | Windows PC, desktop kill (Claude) | pass | pass | pass | M3 | not killed | pass | `.project/evidence/STEP-15/2026-10-08-r1/kill_tests_log.md`; 10 passes through a full run played through `GameState` (WORK, LAYOFF, WORK, GAME_OVER) but was not killed inside the scene |
| 2026-10-08 | Windows PC, desktop kill (Claude), M3 | | | | pass | pass | | `.project/evidence/STEP-16/2026-10-08-r1/kill_tests_log.md`: 9 (review) and 10 (the layoff scene on the VS screen) now killed inside the scene; 12, 13 and 14 pass |
| | iPhone (developer) | | | | | | | |

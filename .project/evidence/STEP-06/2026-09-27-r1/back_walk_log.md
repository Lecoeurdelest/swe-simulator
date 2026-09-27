# STEP-06 robustness stage: the Back walk, every screen and sub-state

Date 2026-09-27, Windows PC, Godot 4.7.2-stable (steam), branch step-06-offer-endings. Runs 72 (exploration, before the fixes) and 73-78 (the walk, on the final code except where noted).
ROADMAP Step 6 task 6: the Pause sheet on the hunt, interview and offer, and the on-screen Back and the Back chain on every screen (ARCHITECTURE 9, GDD 4.4). iOS has no Back button, so every state was checked for an on-screen way out as well as for desktop Esc.
Tests: `robustness_test_run.txt` (225/225, 21 suites). Kill tests: `kill_tests_log.md`.

## Method

- **Esc** = a real key press and release through `game_manage input_key` (Device's `_unhandled_input` -> `Device.handle_back()`).
- **Taps** = real `game_manage input_mouse` motion + press + release, in window pixels (2x the game pixels; the game window is 540x960 for 270x480).
- State was read after each step with `game_eval` (read-only), except where the table says `game_eval` drove it:
  - focus loss: `GameState.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` shows the interview's "Ready?" overlay (desktop can't switch apps from here);
  - the first-viewing VS intro's first second: `Device.handle_back()` called by `game_eval` right after the scene fade (the same function Esc calls; a real key can't land inside that 0.8 s window through the tool's latency);
  - the Background select name field emptied once (`text = ""`) to check that ending the typing restores the default name;
  - the card's "Posted ..." line read through `_posted_text(0/1/2/488)` (no 0- or 1-day card was on the board).
- Every on-screen Back in the game calls `Device.handle_back()`, the same chain as Esc: the hub's `[=]` and `[ < Back ]` rows, the interview's `[II]`, the offer's `[ < Back ]`, `[ < Title ]` on Background select, the Hired card and Plan B.

## What this stage changed

| Where | Before | Now |
|---|---|---|
| Interview ending beats (K.O., the committee banner and wheel, the rejection banner and card) | `[II]` stayed until the rejection card, so Pause > Quit to title > Continue replayed an interview whose ending you had already seen (Step 4 finding). Back opened Pause the same way, and on the Ready overlay too. | Agent default: `_begin_ending()` hides `[II]`. Back during an ending beat does nothing (taps advance it); on the Ready overlay it only resumes (like its tap); on Ducky's card it is still `[ Back to the hunt ]`. |
| Background select, typing the name | A tap outside the field kept the typing going (run 72). On the iPhone the keyboard hides the selector and the action bar with `[ < Title ]`, so only the keyboard's Return got you out. | A tap anywhere outside the field ends the typing (the tap still reaches what it hit); the action bar comes back and an empty name falls back to the default. `unedit()` doesn't emit `editing_toggled`, so the handler is called by hand. Esc and Return already ended it. |

## The walk

| Screen / sub-state | On-screen way out (iOS) | Esc (desktop Back) | Result | Run |
|---|---|---|---|---|
| Title, no save | tap anywhere = New game (no Quit on iOS, A4) | "Quit the game?" dialog opens | pass | 73 |
| Title, quit dialog | `[ < Back ]` closes it (real tap) | closes it | pass | 73 |
| Title, debug device check | Close button closes it (real tap) | counted ("back 1"), the overlay stays (A1) | pass | 73 |
| Title with a save | CONTINUE / `[ New game ]` | not pressed here (the same `handle_back()` as without a save) | pass for CONTINUE (real taps in every kill test) | 74-78 |
| Intro, panel 1 | "Hold to skip" pill (verified in the intro stage, runs 68-71) | skips to Background select, `intro_seen` = true | pass | 73 |
| Background select | `[ < Title ]` -> Title (real tap) | -> Title | pass | 73 |
| Background select, typing the name | tap outside the field ends typing (new); the keyboard's Return (Enter) ends typing | ends typing (the LineEdit takes the first Esc); the next Esc -> Title | pass: tap outside -> editing false, `_process` off, action bar and selector back, empty name -> "Alex"; Enter -> editing false; Esc -> editing false, then Title | 73 (Esc), 78 (tap outside, Enter) |
| Hub, Jobs (card front) | `[=]` -> Pause (real tap) | -> Pause | pass | 73 |
| Hub, Pause sheet | RESUME (real tap) -> resume; tap outside the sheet -> resume; Quit to title -> Title with CONTINUE | -> resume | pass; CONTINUE restored day 1, energy 7, board [2..6], the same rng state | 73 |
| Hub, a card flying (APPLY scan) | none needed (0.3-1 s) | ignored while `_busy` (no Pause) | pass (`_busy` was true right after the Esc; 2 s later no Pause, no stuck state) | 73 |
| Hub, card back | `[ < Back ]` -> front (real tap) | -> front | pass | 73 |
| Hub, CV | `[ < Back ]` -> Jobs (real tap); DONE (not tapped here) | -> Jobs | pass; the CV change (exp polished) was in the save after `[ < Back ]` | 73 |
| Hub, Mail (daytime) | `[ < Back ]` -> Jobs (real tap) | -> Jobs (same branch as CV / Study) | pass | 73 |
| Hub, Study | `[ < Back ]` (the same button as Mail's, tapped there) | -> Jobs | pass | 73 |
| Hub, Sleep confirm | `[ < Back ]` cancels (real tap); SLEEP sleeps | cancels | pass (day stayed 1 after each cancel) | 73 |
| Hub, night lock screen | tap anywhere -> morning inbox | -> morning inbox | pass | 75 (Esc), 78 (tap) |
| Hub, morning inbox (before Start day) | START DAY (the only control, GDD S06) | -> Pause (not Jobs); Esc again -> resume | pass (matches ARCHITECTURE 9); see finding 1 | 75 |
| Interview, VS intro, first viewing, first second | none needed (2 s) | Pause at 0.275 s, not skipped; Back again -> resume, the VS plays on | pass (`game_eval` `Device.handle_back()`) | 78 |
| Interview, VS intro, second interview of the run | tap anywhere skips | skipped at 0.58 s, no Pause, Dana's greeting starts | pass (real Esc) | 78 |
| Interview, dialogue | `[II]` -> Pause (real tap); tap outside -> resume | -> Pause; Esc -> resume | pass | 75 |
| Interview, Answer Meter live (warm-up) | `[II]` | -> Pause, needle frozen (0.8037 on both reads 0.3 s apart); Esc -> resume, the needle runs, a tap stops it | pass | 76 |
| Interview, red answer's "Real answer" note (no button) | `[II]` | -> Pause | pass | 76 |
| Interview, lie probe (DBG probe line) | `[II]`; Come clean / Bluff, now 124x44 | -> Pause; Esc -> resume | pass | 76 |
| Interview, Come clean tip note | `[II]` | -> Pause | pass | 76 |
| Interview, "Ready?" overlay (focus lost mid-interview) | tap -> resume (the tap doesn't advance the line) | -> Pause; Esc -> resume | pass | 75 |
| Interview ending: committee banner + Dana's line (DBG wheel win) | `[II]` hidden (new); taps advance | nothing (new) | pass | 76 |
| Interview ending: "Ready?" overlay during it | tap -> resume | resume only, no Pause (new) | pass | 76 |
| Interview ending: the wheel spinning | none (2 s) | nothing | pass | 76 |
| Interview ending: K.O. -> "OFFER!" + Dana's line (DBG K.O.) | `[II]` hidden; taps advance -> Offer | nothing | pass | 78 |
| Interview ending: rejection banner + Dana's line (DBG Composure 0) | `[II]` hidden; taps advance | nothing | pass | 78 |
| Interview, Ducky's rejection card | `[ Back to the hunt ]` | -> the hunt (same day); with the Ready overlay up: Esc resumes, the card stays | pass | 78 |
| Offer | `[ < Back ]` -> Pause (real tap); tap outside -> resume | -> Pause; Esc -> resume; the phase stays OFFER (Back never declines) | pass | 77 |
| Offer, Decline confirm | `[ < Back ]` cancels (real tap; it sits exactly on Decline, so a double tap on Decline cancels) | cancels | pass | 77 |
| Offer, Dana's Decline line | a tap, or 2.5 s | moves on (Decline committed: co_nimbus blacklisted, the hunt the same day) | pass (the Esc landed about 1 s in; the 2.5 s timer and Esc are too close to tell apart through the tool, the offer stage checked the Esc path alone) | 78 |
| Hired, beat 1 | tap anywhere | -> the tally (beat 2) | pass | 78 |
| Hired, after the tally | `[ < Title ]` / NEW RUN (not tapped here; the endings stage tapped them); a tap finishes the tally first | -> Title: save deleted, run_count 0 -> 1 | pass | 78 |
| Plan B (DEBUG "Rent runs out") | `[ < Title ]` / RETRY (on after the stamp + 250 ms; not tapped here, the endings stage tapped them) | -> Title, no save | pass | 78 |

Every screen root implements `handle_back()` (`test_every_phase_has_a_screen_with_handle_back`), and every state above has an on-screen way out or is a short beat that ends by itself or on a tap.

## Findings left as they are (please review)

1. **Morning inbox: no on-screen Pause.** GDD S06 pins a full-width START DAY and nothing else, so on the iPhone Pause (Quit to title) is one step away: START DAY, then `[=]`. Esc opens Pause there, as ARCHITECTURE 9 says. Killing the app is also safe (Continue replays the same night and morning). Nothing changed.
2. **Hired card: Back during the tally goes straight to the title** (ARCHITECTURE 9: `quit_to_title()`), while a tap only finishes the tally. Beat 1's Back moves on (the endings stage). Nothing changed.
3. **Hired / Plan B: Back works before the stamp lands**; only the buttons wait for the stamp + 250 ms (a deliberate Back isn't a stray double tap). Nothing changed.
4. **For the Doc sync stage:** ARCHITECTURE 9's table doesn't yet say (a) Interview: during an ending beat Back does nothing and on the Ready overlay only resumes, `[II]` hides from the first ending beat (not only on the card); (b) Background select: while typing, the field takes the first Esc and a tap outside ends typing; (c) Hired: Back on beat 1 moves on. ARCHITECTURE 10.2 should list the new `ProbeButton` variation; 17.2's `_deal_card` comment and 12.2's `test_ui_text` count (now 12) changed.

## Files on disk

After runs 72-78 every changed file matched what was written (compared with a scratch snapshot taken before the edits): the editor never wrote a stale buffer back. `interview.tscn` was changed only through the editor (force-reloaded from disk first, then `theme_type_variation` set on the two probe buttons and saved: a 2-line diff). `addons/godot_ai/utils/log_buffer.gd` got a new modification time during a `test_run`, but its content is byte-identical to the committed blob (same git blob hash). LF line endings throughout. `user://settings.cfg` (created by these runs) was deleted; no save was left.

# UX implementer: coach marks close on a tap, VS intro waits for a tap (2026-09-29)

Developer review requests 1 (Ducky coach note blocks the view on the Jobs screen) and 4 (the VS intro moves on too fast with too much text).

Headless: `RESULT passed=212 failed=0 total=212 suites=19` (`ux_test_run.txt`), `CHECK files=84 failed=0` (`ux_parse.txt`). Before this slice: 208/208.

## A. Ducky coach marks close on a tap (commit "feat(hunt): Ducky coach marks close on a tap")

What changed:
- `CoachMark` (Jobs: apply, flip, sleep; Mail: the invite's GO NOW mark) closes at once on a tap anywhere on the Ducky note. A tap is a press and a release on the note without a drag past the scroll deadzone (6 px). Over the deck the note accepts the events, so the card under it never flips or swipes. In Mail's list the events pass on, so a drag that starts on the note still scrolls. The arrow strip stays mouse_filter IGNORE.
- A closed mark never comes back this run: `GameState.close_coach_mark(id)` appends to the new saved `RunState.coach_closed` and saves at once (Quit to title writes no save). The rule moved from the hub to `HuntTips.coach()` / `HuntTips.coach_invite()`: a closed mark shows nothing, and the next mark still waits for its own rule (closing Apply doesn't show Flip before the first application).
- The hint: a small "x" at the top-right of the note (`DuckyNote.closable`; no new string).
- Bug fix found on the way: the first time a coach mark showed, the hub fitted it while its text had not wrapped yet, so the spacer came out 0 and the note sat at the bottom of the body, over the card's title, tags and joke (`ux_coach_apply_unfitted.png`). That is most likely the "middle of the screen" the developer saw. `_coach.resized` now refits it, so it sits over the card's header strip as GDD 4.3 says.
- Doing the action still closes each mark, as before.

Verified in the editor (main scene, 540x960 window). `first_run` is false in this machine's settings (`run_count=1`), and the settings file was not changed, so after New game > CHOOSE the in-memory `GameState.run.first_run` was set to true with `game_eval`. Every step after that used real taps:
- `ux_coach_apply_unfitted.png`: before the refit fix, the Apply mark lay over the card body.
- `ux_coach_apply.png`, `ux_coach_apply_first_show.png` (after the fix, first show): the Apply mark with the "x", over the header strip, and the arrows to APPLY plus the swipe arrow.
- Tapping the note: `ux_coach_apply_closed.png` shows the mark gone and the card still on its front (not flipped, not swiped). `run.coach_closed == ["coach_apply"]`, and the save file has it too.
- Stop the game, then Continue: `ux_coach_continue.png` shows no Apply mark.
- APPLY brings up the Flip mark (`ux_coach_flip.png`). A tap closes it. Mail, then Jobs: it stays closed (`ux_coach_flip_closed_after_mail.png`).
- 3 more applications (4 in all) bring up the Sleep mark (`ux_coach_sleep.png`). A tap on its "x" closes it and the card doesn't flip (`ux_coach_sleep_closed.png`).
- Pause > Quit to title > Continue: no mark comes back (`ux_coach_quit_continue.png`).
- Sleep, the night, then the day-2 morning: Mail shows the guarantee invite's coach mark with the "x" (`ux_coach_invite.png`). A tap closes it, GO NOW doesn't fire, and `coach_closed` gains "coach_invite", saved (`ux_coach_invite_closed.png`).
- Second run: APPLY closes the Apply mark by the action (`coach_closed` stays empty) and Flip shows. A tap on the card flips it and the Flip mark goes (action).
- Game log: no errors.
- Not checked: a real finger drag that starts on Mail's note (`game_manage` can't send drags with a button held). The code passes those events on to the ScrollContainer.

Tests (`tests/test_hunt_tips.gd`): `test_coach_marks_follow_the_first_day`, `test_a_coach_mark_tapped_closed_stays_closed`, `test_invite_coach_mark_until_the_first_interview`, and `test_new_fields_survive_a_save`, which now round-trips `coach_closed` and loads an old save without it.

## B. VS intro waits for a tap and shows less text (commit "feat(interview): VS intro waits for a tap and shows less text")

What changed:
- No auto-advance. When the 2.0 s clip (`vs_duration_s`) ends, its last frame holds and "Tap to continue" (`ui_tap_to_continue`, on its own small panel under the tier banner) blinks: 0.5 s on, 0.5 s off (1 flash/s, GDD 9.1 allows up to 3).
- `VersusIntro.tap()` replaces `try_skip()`. A tap, or Back through the interview's `handle_back()`, does nothing before the slam (0.35 s). During the rest of the clip it jumps to the last frame (all text, the prompt blinking). On the last frame it emits `finished`, and the interview's greeting starts.
- Less text. Dana's plate shows her name, title and ONE joke stat, and the moves panel shows ONE move. The line is `InterviewPlan.vs_plate(run)`, indexed by `run.times_met_dana % 3` with no dice, so a resumed interview shows the same pair. `vs_dana_moves` is split into `vs_dana_move_1..3`. Your side is unchanged.
- `BalanceConfig.vs_min_view_s` is removed (nothing used it any more). `vs_duration_s` stays.

Verified in the editor:
- `interview.tscn` run directly: after about 3 s the VS screen still waits (`ux_vs_held.png`, the held frame with "Tap to continue" at y 449-476 under the banner at y 402-438). The blink alpha, sampled every 0.2 s, read 0,1,1,1,0,0.
- The clip was replayed with `Engine.time_scale` at 0.005 to 0.05 to catch moments. A real tap at clip time 0.005 s was ignored: it kept playing, not held (`ux_vs_before_slam.png`, the split before the busts arrive). `ux_vs_midclip.png` was taken suspended at about 0.55 s, with the banner still fading in. A real tap there jumped to the end: banner, plates and hint all at alpha 1, and no dialogue yet (`ux_vs_held_after_midclip_tap.png`).
- Esc (desktop Back) on the held frame finished it, and the greeting started (`ux_vs_finished_greeting.png`). Pause did not open.
- Title > Continue > DEBUG > Fake invite (mid) > interview: the VS screen held after 3.5 s with "Candidates today: 11" and "Special move: The Five-Year Plan" (`times_met_dana` 0). A real tap started the greeting. Then [II] > Quit to title > Continue: the resumed interview (same seed, IVSTART logged twice) shows the VS screen again and waits (`ux_vs_resumed_waits.png`).
- Game log: no errors from the game. The only 2 errors came from my own `game_eval` reading `current_animation_position` after the clip stopped.

Tests: `tests/test_interview_plan.gd` `test_vs_plate_takes_turns` (the stat and the move take turns over 7 meetings, repeat calls give the same pair, and every id exists in barks.json). `tests/test_data_files.gd` no longer lists `vs_min_view_s`.

Side effect: the verification runs overwrote the machine's `user://save_v1.json` with test runs, as any play does. `settings.cfg` is unchanged.

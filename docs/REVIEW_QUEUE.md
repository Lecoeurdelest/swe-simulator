# Review queue: what's waiting for you

Written at the end of Claude's autonomous PC run (ROADMAP Steps 2-6), 2026-09-27. The whole loop is playable in grey boxes on the PC: title, intro, background select, the DoomApply job hunt, the interview, the offer, and the Hired and Plan B endings. **225 tests pass** (21 suites), and three full agent-played runs reached the Hired card. Tick items off here or delete this file when you're done.

## 1. Merge the work (5 minutes)

The branches are stacked: each step starts where the previous one ended. `step-06-offer-endings` therefore contains everything.

- **Simplest:** open one pull request `step-06-offer-endings` -> `main` and merge it with **"Create a merge commit"** (not squash): <https://github.com/Lecoeurdelest/swe-simulator/compare/main...step-06-offer-endings>
- To review step by step, use the compare links:
  - [Step 2](https://github.com/Lecoeurdelest/swe-simulator/compare/main...step-02-device-check)
  - [Step 3](https://github.com/Lecoeurdelest/swe-simulator/compare/step-02-device-check...step-03-stub-flow)
  - [Step 4](https://github.com/Lecoeurdelest/swe-simulator/compare/step-03-stub-flow...step-04-interview-greybox)
  - [Step 5](https://github.com/Lecoeurdelest/swe-simulator/compare/step-04-interview-greybox...step-05-hunt-greybox)
  - [Step 6](https://github.com/Lecoeurdelest/swe-simulator/compare/step-05-hunt-greybox...step-06-offer-endings)
- Afterwards: `git switch main && git pull` on each machine. You can delete the step branches on GitHub.
- **Restart the Godot editor once.** It clears the stale "Identifier not found: GameState/Content/..." editor errors (autoloads were added through godot-ai). The game and tests aren't affected.

## 2. Decisions to review (`docs/DECISIONS.md`, A1-A20)

Everything tagged "agent default, please review" followed the documented recommendation (W4). Skim A1-A20. To change one, add a new row.

**Questions only you can answer:**

| # | Question | Current behaviour |
|---|---|---|
| A10 | After BUSTED, should a later K.O. or wheel win still make an offer? | Yes: the interview continues and a win still offers; the company is blacklisted for future cards. |
| Q1 | Should Dana re-probe a lie you already confessed at this company if you send it again? | Yes (the rules allow it). |
| Q2 | "Best Dream score per background" (GDD 3.1 meta) isn't built. MUST, SHOULD or LATER? | Not built. |
| Q3 | Balance (ISSUE-09): the agent playtest ran harder than GDD 5.12 (1 K.O. and 4 committee wheels in 21 interviews; Medium and Hard first runs hit Plan B). | Unchanged until Playtest #1 (Step 7). |
| Q4 | Is the Dream vs Reality footer ("The video scored 100. The video was sponsored.") funny or smug? (Step 6 huddle) | Shown as written. |
| Q5 | Should a swipe also commit on a quick flick? (A14) | Distance only, 67.5 px. Decide after feeling it on the iPhone. |

## 3. Copy to sign off (`docs/CONTENT.md`)

**New text with no source, so please approve or reword:**
- `ui_quit` "Quit"
- `ui_decline_confirm_grace` "Decline this offer? Rent is due today, so this ends the run."
- `ui_tap_to_continue` "Tap to continue"
- `offer_label_equity` "Equity:"
- `offer_equity` "0.0001%"

**Grammatical variants of existing lines:**
- `ui_rent_due_today` "Rent due today"
- `card_posted_one` "Posted 1 day ago"
- `card_posted_today` "Posted today"
- `ui_ghost_footer_one` "1 application: no reply. Probably ever."

**Labels copied from GDD mockups or the CONTENT 13.1 template (a quick skim is enough):**
- Logo and background select: `ui_logo_1..3`, `ui_background_header`, `ui_energy_per_day`, `ui_rent_runway`, `ui_name`, the INTERN / GRADUATE / SELF-TAUGHT selector labels, `ui_stat_knw/exp/net`.
- Interview: `ui_composure`, `ui_doubt`, `ui_round`, `ui_back_to_hunt`, `bark_dana_other_candidates`, `vs_versus`.
- Job hunt: `ui_radar_short`, `ui_odds_quick`, `ui_odds_tailored`, `ui_deck_empty`, `ui_yes/no`, `ui_cv_edu/exp/proj`, `ui_invite_line`.
- Offer: `offer_title`, `offer_salary`, `offer_dear`, `offer_role`, `offer_label_*`, `offer_deadline`.

**Wording issues found while building:**
- The Graduate's perk says "wider zone on your first *tech* question", but the rule (GDD 5.8.4) applies to the first *knowledge* question, which can be behavioral.
- Dana greeting a Big corp whose name ends in a period prints "Welcome to Engagement Farms Inc.. You have 45 minutes." (a double period).
- A startup contract can show "Unlimited PTO*" as both a perk and the fine print.
- GDD 4.3 says "Tired? Tap the moon..." while `coach_sleep` says "Out of energy? ...". The JSON text is used.

## 4. Your "You do" exercises (learning tasks Claude never does)

The game runs with plain placeholders until you replace them. Each placeholder file says so in its header.
- [ ] **Step 4:** build `ui/components/hp_bar.tscn` with the 0.4 s "ghost" bar. Keep `class_name HpBar` and `max_value` / `value` / `fill_color`.
- [ ] **Step 4:** change `doubt_hp` in `data/tiers/mid.tres` in the Inspector, replay an interview (run `features/interview/interview.tscn` as the current scene), and feel the difference. Update `tests/test_data_files.gd` if you keep the change.
- [ ] **Step 5:** build the 5-segment `ui/components/stat_bar.tscn`. Keep `class_name StatBar` and `value` (0-100).
- [ ] **Step 5:** write 5 posting jokes of your own (60 characters max) in `data/content/postings.json`. `test_content_lint` tells you if one is too long.
- [ ] **Step 6:** choose the fine-print jokes you like best (`emails.json` `fp_*`).
- The Step 3 "Background Select layout" exercise is superseded (A16). The real screen is built; study its containers.

## 5. iPhone checklist (when the Mac and iPhone are ready)

1. **ROADMAP Step 2, the setup** (tasks 1-7, 9-10): Xcode, Godot 4.7.2 + iOS templates on the Mac, Team ID, the iOS preset, Developer Mode, Run. Write down the install date (7-day expiry).
2. **Title > Device check:** record AC-S02-8..19. Test drag-vs-tap with both "Rows STOP" and "Rows PASS", and check whether the 10 ms haptic can be felt. Claude then writes the results into ARCHITECTURE 18.1.
3. **Steps 3-6 on the phone:**
   - One-thumb click-through; is the text readable at arm's length? (A3's 12 px line pitch)
   - Do the three company types feel different in interviews?
   - Can you see your odds before the needle moves, and does your thumb never cover it?
   - Swipe feel (A14)
   - Does an invite arrive by day 2 in 3-5 minutes?
   - The laugh test
   - 3 full runs with no crash
   - The 5 kills in `docs/KILL_TESTS.md`
   - The intro skip
4. **Then tag the grey-box on `main`:** `git tag v0.1-greybox` and `git push origin v0.1-greybox` (AC-S06-4).

## 6. What's next after that

- **Step 7, Playtest #1** (needs people): 3-5 testers, you stay silent. Port the GDD 5.12 simulation to `tests/test_balance.gd`, then tune numbers (D8, ISSUE-09).
- **Step 8, SHOULD features in GDD 10.2 order:** Research first, which is also the GDD's strongest balance lever, then Negotiate, and so on.
- Every step's status is in `docs/task/README.md`. Evidence for everything Claude verified is in `.project/evidence/`.

# Review queue: what's waiting for you

**2026-10-07: the Run Spec v1 merge is in progress** on branch `run-spec-v1-merge`. `docs/merge-report.md` says what's done, what's left and which questions are still yours. Decided so far: M1 starts now (W9), Phase 1's stats only feed the duel (D-26), and all negotiation is removed: the offer's Negotiate (D-27) and the lease renewal's (D-28). The sections below are from 2026-09-29; the merge rewrites this file when it's finished.

Written at the end of the Step 7 review run, 2026-09-29. Your v0.1 review is built on the branch `step-07-dev-review`: CV editing and lying are gone (D9), Ducky's coach marks close on a tap (D11), the VS screen waits for your tap and shows less text (D12), the choice questions and the Hired card are in plainer words (C3, C4), and the real HP and stat bars replaced the placeholders (W7). A review fix pass followed: leftovers of the CV removal, Ducky's offer tip (Q6), the VS fade, the Hired-card points, a few tips, and a debug button that replays the first run (A47-A51). **217 tests pass** (20 suites). Nothing was built for Phase 2. Tick items off here or delete this file when you're done.

## 1. Merge the work (5 minutes)

`step-07-dev-review` sits on top of `main` (your Step 6 merge) with 12 commits: the CV and lying removal, the copy fixes, the coach marks, the VS intro, the bars, the docs and tracking sync, then the review fix pass (D9 leftovers; the offer tip and the VS fade; the Hired-card points; tip fixes; the debug Reset first run; its docs and tracking).

- The pull request is open: [#6](https://github.com/Lecoeurdelest/swe-simulator/pull/6). Merge it with **"Create a merge commit"** (not squash).
- Afterwards: `git switch main && git pull` on each machine. You can delete the branch on GitHub.
- Heads-up: the verification runs on this PC may have left a test run in its save. If the title screen shows CONTINUE, tap New game for a clean run. They also pressed the new debug button "Reset first run" (A51), so your next New game on this PC is a first run, with Ducky's coach marks.

## 2. Decisions to review (`docs/DECISIONS.md`)

Your answers from the review are written down as decisions; check that they say what you meant. The agent defaults followed the recommended option (W4); skim them, and add a new row to change one.

| ID | In short |
|---|---|
| D9 | CV editing and lying removed (supersedes D4). No "Polish CV" button: no stat fits, and Tailor & Apply already is the per-job polish. |
| D10 | Best Dream score per background is LATER. |
| D11 | Coach marks close on a tap (a small "x" shows it). |
| D12 | The VS intro waits for a tap; Dana shows one joke stat and one special move. |
| C2 | Section 3 copy approved, and its 4 wording issues fixed. |
| C3 | The 14 choice questions checked for plain language (11 reworded, 3 already plain). |
| C4 | New Hired-card header, row labels, lowest grade and footer. |
| W7 | "You do" exercises suspended; Claude builds those features (supersedes W3). Installs, signing, iPhone checks and sign-offs stay yours. |
| P3 | Phase 2 isn't scheduled until you choose its mechanic; ideas parked; no cosmetics for now (D6 stands). |
| A21-A24 | CV removal details: the CV tips moved to the night screen after a Tailor & Apply; a 4-slot dock; the Graduate's flaw text; old saves still load; the lint keeps CV lines true. |
| A25-A29 | Copy details: one tip's second line; the Hired-card wording; 6 tips reworded; the period rule for names ending in "."; a perk-themed fine print (pizza parties) is still allowed. |
| A30-A35 | Coach marks: a tap counts on release; Mail's invite note closes too; closed notes are saved; closing one doesn't bring the next one early; "x" is a placeholder; the note now sits over the card's header strip. |
| A36-A39 | VS intro: the prompt blinks once a second; the stat and the move take turns; Back acts like a tap; `vs_min_view_s` removed. |
| A40-A46 | Bars: the white ghost eases in over 0.4 s; any value above 0 shows at least 1 px; stat blocks are amber on ink; both are `@tool`; your VS plate uses the stat bars. |
| A47-A51 | Review fix pass: the offer's Ducky tip fades in after the paper lands and closes on a tap (answers Q6); Hired-card rows show points out of the row's maximum ("18.9/40"); a new tip for the harsh-feedback question; 3 tips and one reaction reworded; a debug-only "Reset first run" on the title. |

A1-A20 from the first run are still there if you haven't skimmed them. A10, A11 and the lying parts of A9, A12, A13 and A20 are void under D9.

Q6 (Ducky's tip over the offer's Fine print) is answered by A47: the paper slid up under the note for 0.3 s; at rest they never overlap. The note now fades in after the paper lands, and a tap closes it.

**Questions only you can answer:**

| # | Question | Current behaviour |
|---|---|---|
| A42 | Should the Composure bar be mirrored, so both HP bars grow from the screen centre like a fighting game? | Both fill left to right. |
| Q3 | Balance (ISSUE-09): the agent playtest ran harder than GDD 5.12. D9 adds to it: Quick Apply now sends your honest CV, so the Graduate and the Self-Taught fail "1+ years" filters unless they Tailor & Apply. | Unchanged until Playtest #1 and the balance re-sim (Step 7). |
| Q5 | Should a swipe also commit on a quick flick? (A14) | Distance only, 67.5 px. Decide after feeling it on the iPhone. |

## 3. Copy to sign off (`docs/CONTENT.md`)

**Choice questions (section 7, C3):** all 14 now read plainly for someone outside tech (11 reworded; why-us, grind-culture and any-questions were already plain). `eq_leaked_password`'s neutral reaction is now "Deleting it doesn't change it. Half the company already saw it. Some took screenshots." (A50). The right answer should still be jokingly obvious, and the wrong ones should be the joke. Read them in CONTENT.md section 7.

**Hired card (section 14, C4):**
- `end_dream_header` "YOUR JOB vs REMY'S VIDEO"
- Rows: "Salary (Remy: $150k)", "Days at home (Remy: 5 of 5)", "Commute (Remy: 3 steps)", "Red flags (Remy: none)", "Rent days to spare"
- `end_dream_grade_1` "All reality, no dream" (grades 2-4 unchanged)
- `end_dream_footer` "100 is the life in Remy's video. Nobody gets 100. Not even Remy."
- Each row shows its points out of the row's maximum, e.g. "Salary (Remy: $150k)  18.9/40" (A48).

**VS screen (section 8.3, D12):** one move per interview, in turn, instead of the list of three:
- `vs_dana_move_1` "Special move: The Five-Year Plan"
- `vs_dana_move_2` "Special move: The Salary Expectation Trap"
- `vs_dana_move_3` "Special move: The Awkward Silence"

**Coach marks:** no new text. The close hint is a plain "x" until the art pass (A34).

**Tips (section 11), reworded in plain words. Tip accuracy is yours to check (W4):**
- `tip_small_changes` "Release small, tested updates early in the week, so problems get fixed before the weekend."
- `tip_blameless` "Good teams review mistakes without blame: what happened, how it was fixed, and what stops a repeat."
- `tip_secrets` "A leaked password is no longer secret. Report it so it gets changed; deleting the message isn't enough."
- `tip_teamwork_without_job` "No team yet? Public coding projects, team coding events and freelance clients give you feedback and team stories." (no trigger in the MVP now, A49)
- `tip_star_stories` "Prepare 5 stories: conflict, failure, teamwork, a win, learning fast. Tell each as situation, task, action, result."
- New, `tip_take_feedback` (the harsh-feedback question, A49): "Rude feedback can still hold a real fix. Ask what to change, then raise the tone privately and calmly."
- `tip_ask_questions` "Always ask a question at the end: what success looks like in 90 days, how the team works, real hours."

## 4. Your "You do" exercises

Suspended (W7): Claude built `hp_bar` (the 0.4 s white ghost bar) and `stat_bar` (5 segments), and the other exercises were dropped. Installs, signing, the iPhone checks and your sign-offs stay yours.

## 5. iPhone checklist (when the Mac and iPhone are ready)

1. **ROADMAP Step 2, the setup** (tasks 1-7, 9-10): Xcode, Godot 4.7.2 + iOS templates on the Mac, Team ID, the iOS preset, Developer Mode, Run. Write down the install date (7-day expiry).
2. **Title > Device check:** record AC-S02-8..19. Test drag-vs-tap with both "Rows STOP" and "Rows PASS", and check whether the 10 ms haptic can be felt. Claude then writes the results into ARCHITECTURE 18.1.
3. **Steps 3-7 on the phone:**
   - One-thumb click-through; is the text readable at arm's length? (A3's 12 px line pitch)
   - Do the three company types feel different in interviews?
   - Can you see your odds before the needle moves, and does your thumb never cover it?
   - Swipe feel (A14, Q5)
   - Does an invite arrive by day 2 in 3-5 minutes?
   - **Coach marks** (a fresh install is a first run; in a debug build, Title > "Reset first run" replays it): tap a Ducky note. Does it close, with the card under it staying put? In Mail, does a drag that starts on the invite note still scroll? (ARCHITECTURE 18.1 #17)
   - **VS intro:** the clip ends on a held frame with a blinking "Tap to continue". Is it easy to read now, and does a tap feel right?
   - **Offer:** Ducky's tip fades in after the paper lands. Tap it: does it close, and does the paper ease down smoothly?
   - **HP bars:** does the white ghost's 0.4 s drain feel good, and do the empty stat-bar blocks read on the dark panels? (18.1 #18)
   - The laugh test
   - 3 full runs with no crash
   - The 5 kills in `docs/KILL_TESTS.md` (moments 1 and 3 changed: tap a Ducky note closed; the VS screen waits for your tap)
   - The intro skip
4. **Then tag the grey-box on `main`:** `git tag v0.1-greybox` and `git push origin v0.1-greybox` (AC-S06-4).

## 6. What's next after that

- **Step 7, Playtest #1** (needs people): 3-5 testers on your iPhone, and you stay silent (ROADMAP 7). Claude builds the Run Report screen and ports the GDD 5.12 simulation to `tests/test_balance.gd`. The sim has to be re-run after D9, because Quick Apply now sends the honest CV. Then the numbers get tuned (D8, ISSUE-09).
- **Phase 2 is parked** until you choose its mechanic. Your ideas (small random events, a few minor career improvements, no cosmetics for now) are in `docs/ideas_parking_lot.md`. Nothing is built for it.
- **Step 8, SHOULD features in GDD 10.2 order:** Research first, which is also the GDD's strongest balance lever, and so on. (Negotiate was removed on 2026-10-07: D-27.)
- Every step's status is in `docs/task/README.md`. Evidence for everything Claude verified is in `.project/evidence/`; this review's is in `.project/evidence/STEP-07/2026-09-29-review/`.

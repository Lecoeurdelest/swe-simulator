# Review queue: what's waiting for you

Rewritten on 2026-10-08, after you signed off STEP-14 (M1), and updated the same day for STEP-15 (M2). The Run Spec merge, its open conflicts and M1's review (the old sections 0.1-0.6) are answered: the record is `docs/DECISIONS.md` D-29..D-38 and `docs/merge-report.md`. Sections 1-5 carry over what was still waiting from the Step 7 review (2026-09-29). Tick items off here, or delete the file when you're done.

## 0. Waiting for you now

1. **Merge `step-14-signoff`** on GitHub (a merge commit, not squash): the decision rows D-29..D-38, INV-21..23, the one-month starting savings, Phase 1's company names in place of the placeholders, the settled docs, and the rerun evidence. Then **`step-15-greybox-ui`** (M2, built on top of it), in that order.
2. **Tick STEP-14's "Done when" boxes** in ROADMAP 12 (Step 14). The tracking already says done; the checkboxes are yours.
3. **Run the M2 playtest** (`docs/PLAYTEST_M2.md`), which also carries Playtest #1 (D-33): three outside players, silent, on the desktop build or your iPhone. The step cannot be done without it. Pull `step-15-greybox-ui`, run the project and press New game (Reset first run first).
4. **M2's agent defaults A78-A87** in `docs/DECISIONS.md`, all "please review": the entry points, the save, the clock, the cards, the stand-ins, what happens after the layoff, the coach marks, the layout, the debug helpers and the new strings (A87 lists my drafts for your tone check, including the prep card's line).
5. **Phase 1 leftovers:** A42, Q5 and the Phase 1 copy sign-off (sections 2 and 3 below).
6. **The iPhone checklist** (section 5), when the Mac and iPhone are ready; it now also holds the career run's kill moments 6-11 (`docs/KILL_TESTS.md`).

### 0.1 Worth knowing before the playtest (what building M2 showed)

- **Reasonable hours are a slow burn.** The Runway chip is red from day 1 (the Intern starts with one month of savings) and a thin runway adds 0.4 a day to Burnout, so notch 3 drifts up about 0.5 a day. A player who never touches the Hours reaches Burnout 75 near day 150 (the auto-resolve starts) and may hit the forced leave around day 200. That is what the gate's second question tests, but it is the first thing to watch; M4 retunes with the real numbers.
- **Heroics are tempting.** E12's exhausted choice, "Fix it yourself", is +15 Burnout; my own patient autoplay at notch 3 that always took an event's first choice reached the Burnout ending on day 102.
- **Run 2 is a dead end in M2.** It starts between jobs and there is no board until M3, so Plan B ends it about a month in. Background select still shows Phase 1's card (energy, rent runway).
- **A recruiter's call leads nowhere yet:** the interview is skipped (M3's adapter).

### 0.2 Answered on 2026-10-08 (for the record)

| What | Answer | Logged as |
|---|---|---|
| The first tuning | accepted; the median run and the loss mix wait for M4 | D-29 |
| MC-04, starting savings | about one month: 1.0 (Intern) / 0.8 (Graduate, Self-Taught) | D-30 |
| The Handbook's strength | left until M6 | D-31 |
| MC-03, what a background changes | the duel's inputs, starting savings and the commute only; the harder backgrounds are revisited at M4 | D-32 |
| MC-01 (the rest), Steps 7-13 | Playtest #1 folds into the M2 gate; R-BAL replaces the Phase 1 balance sim; drag-to-sign moves to M3, the other hunt SHOULDs are parked; art and release come after M4; `v0.5-mvp` ships the career run | D-33 |
| MC-05..MC-23 | accepted as proposed (Hierarchai, Scope & Creep Digital and OmniGlobal Dynamics replace the placeholder names) | D-34 |
| The agent defaults A62-A76 | accepted | D-35 |
| Scope of the career run | build every MUST and SHOULD | D-36 |
| Tone and tip accuracy | signed off (CONTENT 16's drafts and the 23 event tips) | D-37 |
| INV-21..23 | added | D-38 |

## 1. The Step 7 review (merged)

Pull request #6 (`step-07-dev-review`) was merged into `main` (dde5b99): CV editing and lying removed (D9), coach marks that close on a tap (D11), the VS screen that waits for your tap (D12), plainer choice questions and Hired-card copy (C3, C4), and the real HP and stat bars (W7), plus the review fix pass (A47-A51). 217 tests passed in 20 suites. You can delete the merged step branches on GitHub.

## 2. Decisions to review from the Step 7 review (`docs/DECISIONS.md`)

| ID | In short |
|---|---|
| D9 | CV editing and lying removed (supersedes D4). No "Polish CV" button: no stat fits, and Tailor & Apply already is the per-job polish. |
| D10 | Best Dream score per background is LATER. |
| D11 | Coach marks close on a tap (a small "x" shows it). |
| D12 | The VS intro waits for a tap; Dana shows one joke stat and one special move. |
| C2 | The review queue's copy approved, and its 4 wording issues fixed. |
| C3 | The 14 choice questions checked for plain language (11 reworded, 3 already plain). |
| C4 | New Hired-card header, row labels, lowest grade and footer. |
| W7 | "You do" exercises suspended; Claude builds those features (supersedes W3). Installs, signing, iPhone checks and sign-offs stay yours. |
| P3 | Phase 2 wasn't scheduled until you chose its mechanic. Superseded on 2026-10-07: the Run Spec is that mechanic (W8). |
| A21-A51 | The agent defaults of the review: the CV removal's details, copy details, coach marks, the VS intro, the bars, and the review fix pass (the offer's Ducky tip, "18.9/40" rows, `tip_take_feedback`, a debug "Reset first run"). |

A1-A20 from the first run are still there if you haven't skimmed them. A10, A11 and the lying parts of A9, A12, A13 and A20 are void under D9.

**Questions only you can answer:**

| # | Question | Current behaviour |
|---|---|---|
| A42 | Should the Composure bar be mirrored, so both HP bars grow from the screen center like a fighting game? | Both fill left to right. The career run's duel uses the same bars. |
| Q3 | Balance (ISSUE-09): the agent playtest ran harder than GDD 5.12, and D9 makes it a little harder again. | Retired by D-33 (2026-10-08): the career run's R-BAL harness replaces Step 7's Phase 1 sim, and ISSUE-09 went with it. |
| Q5 | Should a swipe also commit on a quick flick? (A14) | Distance only, 67.5 px. Decide after feeling it on the iPhone. |

## 3. Phase 1 copy to sign off (`docs/CONTENT.md`)

- **Choice questions** (section 7, C3): all 14 read plainly for someone outside tech. The right answer should still be jokingly obvious, and the wrong ones the joke.
- **Hired card** (section 14, C4): the header "YOUR JOB vs REMY'S VIDEO", the rows naming Remy's numbers, grade 1 "All reality, no dream", the footer "100 is the life in Remy's video. Nobody gets 100. Not even Remy." (What the career run does with the Hired card is MC-08.)
- **VS screen** (section 8.3, D12): one special move per interview, in turn.
- **Reworded tips** (section 11; tip accuracy is yours): `tip_small_changes`, `tip_blameless`, `tip_secrets`, `tip_teamwork_without_job`, `tip_star_stories`, the new `tip_take_feedback`, `tip_ask_questions`.

## 4. Your "You do" exercises

Suspended (W7): Claude builds the features. Installs, signing, the iPhone checks and your sign-offs stay yours.

## 5. iPhone checklist (when the Mac and iPhone are ready)

1. **ROADMAP Step 2, the setup:** Xcode, Godot 4.7.2 and its iOS templates on the Mac, the Team ID, the iOS preset, Developer Mode, Run. Write down the install date (7-day expiry).
2. **Title > Device check:** record AC-S02-8..19, including drag-vs-tap with "Rows STOP" and "Rows PASS" and whether the 10 ms haptic can be felt.
3. **Steps 3-7 on the phone:** one-thumb reach and readability (A3's 12 px line pitch), the tiers' feel in interviews, the swipe (A14, Q5), the coach marks' tap and Mail's scroll (ARCHITECTURE 18.1 #17), the VS intro's tap, the offer's Ducky tip, the HP bars' ghost (18.1 #18), 3 full runs with no crash, the 5 kills in `docs/KILL_TESTS.md`, the intro skip.
4. **Then tag the grey-box on `main`:** `git tag v0.1-greybox`, then `git push origin v0.1-greybox` (AC-S06-4).
5. **Later, the career run's kills** (moments 6-11 in `docs/KILL_TESTS.md`), once M2 builds the work state.

## 6. What's next

- **M2 (STEP-15), the grey-box UI,** is built on `step-15-greybox-ui` (ROADMAP 12; its bundle is `.project/bundles/STEP-15.md`) and waits for your playtest. **M3 (STEP-16, run 1 end to end)** is next: the board, the review duel, the adapter, Hierarchai's coworkers.
- **Steps 7-13 follow the career run** (D-33): Playtest #1 is the M2 gate, the art and release steps come after M4, and `v0.5-mvp` ships the career run.
- Every step's status is in `docs/task/README.md`, and the evidence for everything Claude verified is in `.project/evidence/`.

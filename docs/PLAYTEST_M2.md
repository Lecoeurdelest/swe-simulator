# The M2 gate: how to run the playtest

ROADMAP 12 (Step 15, task 4) and DECISIONS D-33: three outside players, in silence, on the career run's grey box. This is also Playtest #1, folded in. Only you can run it. It takes about 20 minutes a player: job 1 is 240 days, a day a second at 1x, so about 4 minutes of clock plus the cards.

## The two questions the step is graded on

1. **Do they finish job 1?** They reach the layoff scene on day 240.
2. **Can they say why they were laid off?** Ask it afterwards, in their words. A good answer names the company's situation (the freeze, the "efficiency" talk, the roadmap, the empty desk), not their own performance (O1, D-22).

Ask the four gate questions of ROADMAP 7 as well, afterwards, one at a time:

| Ask | Pass | If it fails |
|---|---|---|
| Could you have avoided the layoff? | "No, but I could have been readier" | make the five signs louder (R-RUN-02) |
| What did you do with the Hours? | moved it at least twice a job, with a reason | the Junior is passive: more events, or let events push the slider |
| What were you trying to get? | names The Studio or one of its conditions | the chip and the coach note are not enough (R-WIN-07) |
| Where did you stop playing? | at a natural break: a payday, a review, a job change | add a soft stop point after big events |

## Setting up

- **A clean first run.** On the Title press **Reset first run** (debug builds), then **New game**. The intro plays the first time (skip it only if the player asks). If a stale **CONTINUE** shows, **New game** replaces it.
- **Desktop or iPhone** (P2: your call): the desktop build until the Mac is set up. Give them the phone or the mouse and say only: "It's a game about getting a tech job. Think out loud." Then stay quiet and take notes (ROADMAP 7).
- Never explain the Hours, the Runway chip or the coach notes. The notes are what is being tested.

## What to watch for

- Do they start the clock (the first coach note says "Tap 1x") and do they find the **Hours notches** (the second note)? How long before the first tap on them, and why?
- Do they read the **rumor cards** (five between day 150 and day 235) or tap through them? Do they mention them afterwards?
- What do they do about **Burnout** (the bar, then the three warning lines from 60) and the red **Runway** chip?
- A pause longer than 3 seconds; a tap on something that is not interactive (the dock apps say "not in this build yet"; the top band is information only); where they laugh; where they stop.
- Do they say "boom", "ouch" or "unfair" at a card? Which one?

## What this build does not have (do not apologize for it, just note it)

M3 (STEP-16) is built on top of the M2 build, so a playtest on the newest build also plays its content: run 1 opens on Remy's clip, the team shows under the job line, the review is a 3-question duel with Kev, the layoff scene is on the VS screen, and the DoomApply board, the interviews and the contract work. The gate's two questions are unchanged and still end at the layoff; players who go on are playing M3's board, which is welcome but not graded.

- **No Home, ClikClok or Handbook apps** (they say "not in this build yet"), no Mid or Senior controls beyond the ticket pick, and Plan B still ends a run whose savings run out.
- **The clauses are mostly a joke** and "Ask Priya" does nothing yet (nothing raises Rapport in run 1).
- Grey boxes instead of the office diorama (M5). Runs after the first show Phase 1's background card.
- Reasonable hours (notch 3) are a slow burn: the Runway chip is red from day 1, and a thin runway adds to Burnout. A player who never touches the Hours drifts toward Burnout 75 around day 150, which is the point of the dial, and what the second gate question asks about.

## After the session

Write down, per player: how far they got, the day they stopped or the layoff, their answers to the six questions, what confused them, and what made them laugh. Anything two or more players hit is a must-fix (ROADMAP 7). Put the notes in `.project/evidence/STEP-15/<date>-playtest/notes.md`, tell Claude, and the step's first criterion (AC-S15-1) can be recorded.

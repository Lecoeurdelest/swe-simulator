> **Archived input, read-only.** This is Run Spec v1 as received on 2026-10-07. Everything below the line is unchanged (the original file's sha256 is `f64ea13ca5c739cef5ab4a68ae6cad3aefcac03f9856308fb95e2fbd3b5106af`). It was merged into the docs on 2026-10-07 (DECISIONS W8): the design now lives in `docs/GDD.md`, `docs/DECISIONS.md`, `docs/CONTENT.md`, `docs/ARCHITECTURE.md` and `docs/ROADMAP.md`, and those win over this file. `docs/merge-report.md` maps every section to its new place and lists the conflicts. Don't edit this file: change the merged docs.

---

# Software Engineer Simulator — Run Spec v1

Oct 5, 2026 · @Quy

## 1. Summary

Software Engineer Simulator is a satirical career roguelite: one run is one career of up to five jobs, and you win by living the influencer video as a Senior engineer.

The work state is the game. A macro clock runs one in-game day per second while you survive rent, burnout and an inherited codebase through events. The job hunt is the DoomApply button on your phone; behind it, interviews are still the Dana duel and offers are still the contract modal. Most runs end in a loss, and what Ducky taught you carries into the next run.

| Run at a glance | Target |
| --- | --- |
| One career run | 25–35 min, about 3–4 in-game years |
| Session | 5–12 min, save anywhere, no time passes while the app is closed |
| Jobs per run | 5 at most |
| Win rate | 5–10% for skilled play |
| Total content | 2.5–4 h |
| Art | The original docs' pixel-art style; no commissioned art, existing sprites reused first |

**What changed in this revision**

- Win is **The Studio, as a Senior engineer**. Leaving tech is now a loss. The existing ClikClok-coach ending becomes the "runway hits zero" loss, so shipped content is reused.
- Junior gets **one** continuous control: the Hours slider.
- Three company archetypes. Because they repeat across five jobs, **floor depth** becomes the difficulty scalar.
- Lifestyle creep ships in v1 and sits **on the win path**: The Studio is a rent tier you must afford.
- The layoff meeting is a non-interactive scene.
- Proposed here, awaiting your confirmation: the job board as a route map, cost-weighted layoff selection, counterplay for every Scar, and a 90-day Studio hold.

**One pushback on the new win condition.** "Successful in IT" needs a measurable definition, or it collapses into "reach Senior", which is too easy and isn't the video. This spec defines success as the video's own conditions (section 4).

## 2. Decision log

Twenty-five decisions are locked; eight proposals in this spec need your yes or no. "Yours" means you stated it; "Unchallenged" means I proposed it and you didn't object, so it can still be reopened.

| ID | Decision | Date | Basis | Replaces |
| --- | --- | --- | --- | --- |
| D-25 | Art stays the original docs' pixel-art style; the office diorama is drawn in it | 2026-10-07 | Yours | Code-drawn schematic shapes |
| D-24 | Win = The Studio as a Senior engineer; leaving tech is a loss ending | 2026-10-05 | Yours | "Escape the cycle" win |
| D-23 | First promotion is reachable inside job 1 | 2026-10-05 | Yours | — |
| D-22 | Layoff meeting is a non-interactive scene | 2026-10-05 | Yours | Unwinnable duel |
| D-21 | No art budget: no commissioned art | 2026-10-05 | Yours | — |
| D-20 | Lifestyle creep ships in v1 | 2026-10-05 | Yours | v2 |
| D-19 | The Studio is the canonical ending | 2026-10-05 | Yours | ClikClok ending |
| D-18 | Handbook grants options plus small, capped stat edges | 2026-10-05 | Yours | Options only |
| D-17 | Three company archetypes in v1 | 2026-10-05 | Yours | Five archetypes |
| D-16 | At most 5 jobs per run, then a forced hard loss | 2026-10-05 | Yours | — |
| D-15 | Win-rate target 5–10% | 2026-10-05 | Yours | — |
| D-14 | Junior has exactly one continuous control | 2026-10-05 | Yours | Zero controls at Junior |
| D-13 | No time passes while the app is closed | 2026-10-05 | Yours | — |
| D-12 | The Codebase (inherited tech debt) is the core system | 2026-10-05 | Yours | — |
| D-11 | Soft loss sends you to the job hunt with a Scar; hard loss ends the run | 2026-10-02 | Unchallenged | Undefined "lose" |
| D-10 | Runway is the anti-coast mechanic: salary is fixed, expenses rise | 2026-10-02 | Unchallenged | — |
| D-09 | Escalation comes from company and clock, not title; title caps at Senior | 2026-10-02 | Unchallenged | Lead/Staff levels |
| D-08 | Career roguelite: harder with each level, near-inevitable loss, something persists | 2026-10-02 | Yours | Realistic career sim |
| D-07 | Junior eye level: no project-manager mechanics at Junior | 2026-10-01 | Yours | Effort-allocation dial |
| D-06 | Playtime: session 5–12 min, run 25–35 min, total 2.5–4 h | 2026-10-01 | Unchallenged | 10-hour target |
| D-05 | CV tailoring is dropped | 2026-10-01 | Yours | — |
| D-04 | One clock: unemployment is the same clock with salary 0 | 2026-10-01 | Unchallenged | Two separate phases |
| D-03 | Job hunt is a phone menu button; interviews stay the Dana duel | 2026-10-01 | Yours | Equal-weight Phase 1 |
| D-02 | Run 1 starts employed; job 1 ends in a telegraphed, guaranteed layoff | 2026-10-01 | Yours | Phase 1 first |
| D-01 | Macro clock, about 1 in-game day per second; no cosmetics | 2026-10-01 | Yours | Micro office loop |

**Proposed in this spec — confirm or reject**

| ID | Proposal | Why |
| --- | --- | --- |
| P-01 | Floor depth (job number 1–5) is the difficulty scalar; archetypes set flavour and rules | Three archetypes repeat across five jobs, so they can't carry escalation alone |
| P-02 | The DoomApply board is the route map: each posting is a node you choose | Gives the job hunt a strategic job without adding a system |
| P-03 | Layoff selection is weighted by salary, not performance | Makes "layoffs select for cost" a rule, not a line of text |
| P-04 | Every Scar has counterplay; at most 3 stacks each | Prevents a run being decided by job 2 |
| P-05 | The Studio = 5 conditions held for 90 days | A measurable "success in IT" |
| P-06 | Run 1 background is fixed: The Intern, converted to Junior | Fits "run 1 starts employed" |
| P-07 | The three archetypes are Startup, Agency and MegaCorp | A clean trade-off of pay, remote and promotion speed |
| P-08 | Performance review is a 3-prompt duel on the Dana duel UI | Keeps the earlier duel decision at a third of the content cost |

**Superseded:** Focus Bar, interruptions, headphones and manager patrol; the effort-allocation dial; Lead and Staff levels; the Phase 1/Phase 2 and chapter framing; the job hunt's energy pips and separate rent countdown; CV tailoring; ClikClok and "leave tech" as wins; the layoff duel; five archetypes; the 10-hour target; the code-drawn schematic office.

## 3. Run structure

A run is one career: up to five jobs (floors), each left by a soft loss or a voluntary exit, until you win or a hard loss ends it.

&#91;embedded content: run loop · 2 starts, the career loop, 1 win, 4 hard losses\]

Every soft loss sends you to the board and the next floor; The Studio is the only way out that counts as a win.

**First playthrough vs later runs**

|  | Run 1 | Run 2 and later |
| --- | --- | --- |
| Background | The Intern, converted to Junior (P-06) | Pick The Intern, The Graduate or The Self-Taught, as unlocked |
| Starts | Employed at Pivotly (Startup), day 0 | Between Jobs, DoomApply board open |
| Floor 1 | Always Pivotly, with 5 authored coworkers | Chosen from the board |
| Guaranteed layoff | Yes, day 240, telegraphed from about day 150 | No; every exit is earned |
| First review | Day 180; promotion to Mid reachable (D-23) | On the archetype's cadence |

Run 1 beats: influencer clip on day 0, first rumor around day 150, review and possible promotion on day 180, more signs, Dana's invite around day 235, layoff scene on day 240, then the DoomApply board. Promotion followed by a layoff 60 days later is deliberate: it teaches that performance doesn't protect you.

**Exits from a job**

| Exit | Type | Trigger | Scar |
| --- | --- | --- | --- |
| Laid off | Soft | A resizing event selects you | None: a layoff is not your fault |
| Fired | Soft | Two "Below" reviews in a row with the PIP not cleared | Bad Reference |
| Quit | Soft, voluntary | You accept another offer, or quit from an event | Short Tenure if under 180 days |
| Forced leave | Interrupt, not an exit | Burnout reaches 100 | Burnout History |

Losing job 5 by any route becomes a hard loss (D-16).

**Endings**

| Ending | Type | Trigger | Card line |
| --- | --- | --- | --- |
| The Studio | Win | All five Studio conditions held for 90 days | "You woke at 10:47. It took {jobs} jobs." |
| Plan B | Hard loss | Savings below zero for 30 days in a row | "You became a ClikClok career coach." (existing) |
| Burnout | Hard loss | A second forced leave in one run | "You took the leave. You didn't come back." |
| Career Change | Hard loss | You lose job 5 | "You teach a bootcamp now. You show them the video." |
| Legacy System | Hard loss | Day 2,160 (6 in-game years) without a win | "Six years. Same service. You are the legacy system." |

Every ending card shows the career-long Dream vs Reality score.

## 4. Win condition: The Studio

You win by living the influencer video as a Senior engineer: five conditions true at once, held for 90 in-game days.

| # | Condition | The video's promise | Req |
| --- | --- | --- | --- |
| S1 | Level is Senior | A software engineer who made it | R-WIN-01 |
| S2 | Work mode is Remote | Wakes at 10:47 | R-WIN-02 |
| S3 | Home tier is The Studio | The cozy studio | R-WIN-03 |
| S4 | Burnout at or below 30 | "Works" 12 minutes a day | R-WIN-04 |
| S5 | Runway of 6 months or more at Studio rent | Can actually afford it | R-WIN-05 |

- **Hold (R-WIN-06).** When all five are true, the ClikClok app starts "Filming…", a 90-day bar (90 s at 1×). Any condition breaking resets it to zero; partial credit is open question Q-06.
- **Always visible (R-WIN-07).** The checklist lives in the ClikClok app, and a "Studio 3/5" chip sits on the HUD from day 0. The player knows the target in the first minute.
- **Final threats (R-WIN-08).** While filming, these events get 3× weight: RTO mandate rumor (threatens S2), 2 a.m. incident and overtime ask (S4), Penthouse offer (S5), resizing rumor (all five).
- **Ending.** A ClikClok-style vertical "video" assembled from your run log, captioned with your real career: "10:47 — woke up. 4 jobs. 2 layoffs. 1 Studio." Dream vs Reality shows what it cost.

**Why it's hard: no archetype gives you all five.** The win is a routing puzzle across jobs.

| Archetype | Remote postings | Senior pay vs Studio costs | Speed to Senior |
| --- | --- | --- | --- |
| Startup | Often, 60% | Barely covers it; savings build slowly | Normal |
| Agency | Rarely, 10% | Doesn't cover it | Fast, but you drop a level when you leave |
| MegaCorp | Sometimes, 25%, threatened by RTO | Covers it with room to save | Slow |

Typical winning routes chain archetypes: Agency for the title, then MegaCorp or a remote Startup posting for the pay. A remote MegaCorp posting is the rare "dream job" node on the board.

## 5. Clock and economy

Salary is fixed within a level and expenses grow on a clock, so standing still slowly drains your runway. Every number here is a starting value for the balancing harness (section 13), not a final one. Money is in thousands of in-game dollars (k$).

**Clock (R-CLK)**

| Rule | Value |
| --- | --- |
| Tick | 1 tick = 1 in-game day; a month is 30 days, a year 360 |
| Speeds | Pause, 1× (1 day per second), 2×, 4× |
| Auto-pause | Any event with choices, interviews, reviews, Studio milestones |
| Offline | No time passes while the app is closed (D-13); state saves at every event and when the app goes to background |
| Calendar strip | The next 60 days: paydays, rent, reviews, interviews, deadlines, scheduled events |

**Money flow (R-ECO)**

| Item | Rule |
| --- | --- |
| Rent and living costs | Debited on day 1 of each month |
| Salary | Credited on day 25, a deliberate cash-flow dip |
| Living costs | 1.2 k$/month, +6% every 180 days |
| Rent | The home tier's price, +10% at each yearly lease renewal (event E04) |
| Raises within a level | Meets +1%, Exceeds +3%, below expense growth on purpose |
| Debt | Savings may go negative; 30 days in a row below zero is the Plan B ending |
| Runway shown | savings ÷ (rent + living costs), in months, one decimal |

**Salary, k$/month**

| Level | Base | Startup ×0.85 | Agency ×0.80 | MegaCorp ×1.25 |
| --- | --- | --- | --- | --- |
| Junior | 3.0 | 2.55 | 2.40 | 3.75 |
| Mid | 4.2 | 3.57 | 3.36 | 5.25 |
| Senior | 6.0 | 5.10 | 4.80 | 7.50 |

Offers rise 4% per floor of depth. The Résumé Gap Scar takes 10% off; a successful negotiation adds 8%.

**Home tiers — lifestyle creep (R-ECO-05)**

| Tier | Rent, k$/month | Burnout recovery | Note |
| --- | --- | --- | --- |
| Shared room | 0.9 | none | Where you start |
| One-bed | 1.5 | −0.10 per day |  |
| The Studio | 2.4 | −0.25 per day | Required for the win (S3) |
| Penthouse | 4.0 | −0.35 per day | The trap, offered after a Senior raise |

An upgrade is offered after every raise (E21) and is always available in the Home app. Moving either way costs one month of the new rent.

**Severance:** Startup 0–1 month (run 1 always 1), Agency 0.5 month, MegaCorp 2 months per 360 days of tenure. Fired or quit: none.

Sanity check: a Junior coasting at Pivotly in a shared room starts with about 0.45 k$ spare a month and runs a deficit during year 3. Coasting can never win anyway, because The Studio needs Senior.

## 6. Stats

The player watches four numbers; five hidden values do the rest and surface only at reviews, interviews and in events.

**On screen (R-STAT-01)**

| Stat | Range | Owner | Shown as |
| --- | --- | --- | --- |
| Runway | Months, from savings | You | "4.2 mo" chip, red under 2 |
| Burnout | 0–100 | You | A bar, plus your avatar's posture in the diorama |
| Ticket | 0–100%, with a deadline | You | Progress bar under the calendar strip |
| Codebase | 0–100 | The world at Junior and Mid; yours at Senior | A server rack of 10 LEDs, one turns red per 10 points |

**Hidden (R-STAT-02)**

| Value | Range | Moves with | Used by |
| --- | --- | --- | --- |
| Manager Opinion (MO) | −100 to 100 | Hours, shipping on time, events | Review duel, firing |
| Skill | 0–100 | +2 per ticket shipped, mentorship, Study | Ticket speed, interview Answer Meter |
| Rust | 0–100 | +0.1 a day without an interview, −20 per Study, 0 after an interview | Narrows the interview Answer Meter |
| Rapport, per named coworker | 0–100 | Help or deflect choices | Layoff warnings, references, mentorship |
| Studio hold | 0–90 days | Section 4 | The win |

**Daily formulas (R-STAT-03).** *h* is the Hours notch, 1–5 (section 7); *C* is Codebase.

```latex
\text{ticket progress per day} = \frac{100\%}{\text{size}} \times s_h \times \left(1 + \frac{\text{Skill}}{200}\right) \times \left(1 - \frac{C}{200}\right) \times a_{\text{archetype}}
```

Ticket sizes at baseline are S 10 days, M 20, L 35. Hours speed *s* = 0.6, 0.8, 1.0, 1.25, 1.5 for notches 1–5. Archetype speed *a* = Startup 1.0, Agency 1.0, MegaCorp 0.67.

```latex
\Delta\text{Burnout per day} = \ell_h - r_{\text{home}} + 0.2\,[C \ge 70] + 0.4\,[\text{runway} < 2] + \text{events}
```

Hours load *ℓ* = −0.6, −0.3, +0.1, +0.5, +1.0 for notches 1–5. *r* is the home tier's recovery (section 5). The Burnout History Scar raises the floor (section 11).

```latex
p_{\text{incident per day}} = 0.002 + 0.0006 \times C
```

At Codebase 20 that is one incident every \~70 days; at 50, every \~31; at 80, every \~20 (R-CB-02). Codebase drifts up daily by archetype (Startup +0.08, Agency +0.03, MegaCorp +0.04), plus the Senior quality bar, events, and minus pay-down tickets. MO moves −0.15, −0.05, 0, +0.05, +0.10 a day by Hours notch, +5 per ticket shipped on time and −5 per late one.

**Review rating (R-STAT-04)**

- The review is a 3-prompt duel on the Dana duel UI with a manager portrait (P-08).
- Your Evidence HP = 50 + MO/2 + 5 per on-time ticket since the last review, +10 with the brag-doc tip.
- Manager's Calibration HP: Startup 60, Agency 50, MegaCorp 80 (forced distribution).
- Your HP left decides the rating: under 25% Below, 25–70% Meets, over 70% Exceeds.
- Promotion: Startup on Exceeds; Agency on Meets or better; MegaCorp on two Exceeds in a row. Cadence: 180 days, Agency 120.
- Two Below in a row opens a 60-day PIP. MO under 0 at its end means you're fired.

## 7. Controls and promotion

Agency grows with level: a Junior controls only their own hours, a Mid chooses their work, a Senior sets the quality bar and owns the Codebase.

**Junior: the Hours slider (R-CTL-01, D-14)**

| Notch | Label | Ticket speed | Burnout per day | MO per day |
| --- | --- | --- | --- | --- |
| 1 | Quiet quitting | ×0.6 | −0.6 | −0.15 |
| 2 | Nine-to-five-ish | ×0.8 | −0.3 | −0.05 |
| 3 | Reasonable | ×1.0 | +0.1 | 0 |
| 4 | Just this sprint | ×1.25 | +0.5 | +0.05 |
| 5 | Hustle culture | ×1.5 | +1.0 | +0.10 |

Hours is the slider because it's the only thing a junior actually owns, and it's one trade-off — output against burnout — readable at a glance. Effort allocation was rejected as a manager's tool; the quality bar is a Senior's call. At notches 4–5 your desk lamp stays on after everyone leaves. The overtime ask (E24) can lock you to notch 5 for five days.

A Junior's other inputs are discrete: event choices, the Home app (tier), and DoomApply (apply, study).

**Mid unlocks (R-CTL-02)**

- **Ticket pick.** When a ticket ships, choose the next from three cards: Feature (M or L; MO +6, Codebase +3), Bugfix (S; Skill +3, Codebase −2), Pay-down (M; Codebase −15, MO 0 — "nobody notices").
- **Push back.** Once per review cycle, extend the current deadline by 30% for MO −3.
- **Review requests** (E25) start arriving.

**Senior unlocks (R-CTL-03)**

- **Quality bar.** Clean: Codebase −0.05 a day, speed ×0.85. Balanced: no change. Fast: Codebase +0.12 a day, speed ×1.2.
- **The Codebase is yours.** An incident within 30 days of running Fast triggers the blame post-mortem (E26).
- **Calendar tax.** Meetings cut ticket speed to ×0.85 at all times.

**Level carry-over between jobs (R-CTL-04)**

- You keep your level when you change jobs.
- Leaving an Agency drops you one level (title inflation), never below Junior.
- You may apply one level above your own at half the callback rate. If hired, you're promoted on hire.

## 8. Company archetypes

Three archetypes set the rules of a job; floor depth (job 1–5) sets how hard it is (P-01, P-07). Company names are placeholders.

|  | Pivotly (Startup) | Outsourcery (Agency) | Monolith (MegaCorp) |
| --- | --- | --- | --- |
| Salary multiplier | ×0.85 | ×0.80 | ×1.25 |
| Remote postings | 60% | 10% | 25% |
| Review cadence | 180 days | 120 days | 180 days |
| Promotion rule | Exceeds | Meets or better | Two Exceeds in a row |
| Codebase start, daily drift | 20, +0.08 | 55, +0.03 | 40, +0.04 |
| Ticket speed | ×1.0 | ×1.0 | ×0.67, process |
| Layoff pattern | Funding-driven, frequent | Client churn, then the bench | "Efficiency" rounds, about yearly |
| Severance | 0–1 month | 0.5 month | 2 months per year of tenure |
| Signature pressure | Pivots reset your project | Utilization: Hours notch 1–2 costs MO −0.2 a day | RTO mandate threatens remote |
| Leaving | No penalty | Drop one level | No penalty |
| Signature events | E10 Pivot | E11 Client churn | E08 RTO mandate, E09 Reorg |
| Coworkers | 5 authored (run 1) | Generated from a name pool | Generated from a name pool |

**Floor depth (R-ARC-02).** Floor *n* multiplies event frequency by 1 + 0.15(*n* − 1), Dana's Doubt HP by 1 + 0.08(*n* − 1), and offer salaries by 1 + 0.04(*n* − 1). Deeper floors are harder to get into and busier to survive, but pay better.

**Pivotly's authored coworkers (run 1)**

| Name | Role | Trait | Mechanical hook |
| --- | --- | --- | --- |
| Minh | Junior, your desk neighbour | Kind; clicks everything | Source of E14; the first desk to go dark in the resizing |
| Priya | Senior engineer | Hears things early | Rapport 60+: mentorship (E23) and the exact layoff date |
| Tom | Product manager | "It's a small one" | Brings new projects (E03); owns the deadlines |
| Kev | Your engineering manager | Means well, reports up | Runs your reviews |
| Dana | HR | The same Dana | Sends the invite and delivers the layoff scene; resized herself, she turns up as HR at your next company |

## 9. Events

Events are the game: about 25 decisions a year at floor 1, split into three tiers so most can be planned for or dreaded rather than just suffered.

**Tiers (R-EVT-01)**

| Tier | Warning | Per 360 days, floor 1 | What it generates |
| --- | --- | --- | --- |
| Scheduled | On the calendar strip up to 60 days ahead | \~10 | Planning |
| Telegraphed | Rumors 10–30 days before | 1–2 chains | Dread and preparation |
| Random | None; incidents scale with Codebase | \~12 | Pressure you caused |

**Burnout auto-resolve (R-EVT-02)**

- From Burnout 75, an event with choices may decide for you. The chance is (Burnout − 70) ÷ 30, reaching certainty at 100.
- It takes the event's authored "exhausted" choice — usually the passive or people-pleasing one, written for the joke.
- Three warning beats come first, as Burnout first crosses 60, 70 and 75: "You read the same line four times."
- The card says the choice was made for you, so it reads as burnout, not as the game cheating.

**Layoff selection (R-EVT-03, P-03).** When a resizing fires, each employee's chance is weighted 80% by salary rank and 20% by chance. Manager Opinion is not an input. The counterplay is preparation — savings, Rapport, a live application — not performance.

**Event schema (R-EVT-04).** Content is data, one file per event, editable without code changes.

```yaml
id: E12_incident_prod
tier: random                 # scheduled | telegraphed | random
archetypes: [any]
levels: [junior, mid, senior]
trigger:
  p_daily: "0.002 + 0.0006 * codebase"
  cooldown_days: 20
telegraph: null              # telegraphed: { rumors: [...], lead_days: [10, 30] }
pause: true
focus: { location: war_room }
choices:
  - id: fix_it
    label: "Fix it yourself"
    effects: { mo: +10, burnout: +15, codebase: -5, flags: [owns_service] }
  - id: escalate
    label: "Wake whoever is on call"
    effects: { mo: -3, burnout: +2 }
exhausted_choice: fix_it
ducky:
  joke: "You fixed prod at 2 a.m. Prod now has your phone number."
  cause: "Whoever fixes it once becomes whoever fixes it always."
  tip: tip_escalate
diorama: { flash: red_screens }
```

**v1 event table (R-EVT-05).** Effects are starting values; "exh." marks the exhausted choice.

| ID | Event | Tier | When | Choices → effects | Ducky tip |
| --- | --- | --- | --- | --- | --- |
| E01 | Payday and rent | Scheduled | Monthly | None; the money pulse | — |
| E02 | Performance review | Scheduled | 180 days, Agency 120 | 3-prompt duel → Below, Meets or Exceeds | Keep a brag doc; your manager forgets, documents don't |
| E03 | New project | Scheduled | Every 60 days | Volunteer: MO +6, Burnout +8, next ticket L · Stay on your ticket | Volunteer for work your manager's manager can see |
| E04 | Lease renewal | Scheduled | Every 360 days | Accept +10% · Move down a tier · Negotiate (tip): 30% chance of +5% instead | Landlords negotiate too; ask before you sign |
| E05 | All-hands | Scheduled | Every 90 days | None; carries rumors | Read the slides for what isn't said |
| E06 | On-call week | Scheduled | If the contract has the clause | 7 days: incident chance ×2, Burnout +0.5 a day | On-call lives in the appendix; read it |
| E07 | Resizing | Telegraphed | Archetype pattern; run 1 day 240 | Prep during the chain: update profile, ask Priya, cut spending · then the scene | Layoffs select for cost, not performance; prepare anyway |
| E08 | RTO mandate | Telegraphed | MegaCorp; Startup after funding | Comply: onsite, commute Burnout +0.3 a day · Push back (tip and remote clause): keep remote, MO −15 · Quit | Get remote in writing; verbal flexibility expires |
| E09 | Reorg | Telegraphed | MegaCorp, Startup | New manager, MO halved toward 0 · Book a 1:1 in week one: MO +5 · Wait and see | New manager? Book the 1:1 before they form an opinion |
| E10 | Pivot | Telegraphed | Startup | Codebase +20, ticket reset · Champion it: MO +8, Burnout +5 · Stay quiet | Pivots move headcount; know where your work sits on the new roadmap |
| E11 | Client churn | Telegraphed | Agency | On the bench 20–40 days, MO −0.2 a day · Learn: Skill +5, Rust −20 · Ask for any client: MO +5, Burnout +6 | On the bench, visible beats busy |
| E12 | Prod incident | Random | Chance from Codebase | Fix it: MO +10, Burnout +15, Codebase −5, you own the service · Escalate: MO −3, Burnout +2 · exh. Fix it | Heroics are a staffing bug; escalate first, then help |
| E13 | Phishing test | Random | Any | Click: 3 days of training · Report: MO +2 · Ignore · exh. Click | Urgency is the scammer's favourite feature; check the sender |
| E14 | Coworker clicks a scam | Random | Named coworker | Help clean up: Rapport +15, ticket −20% · Stay out: Rapport −10 | Report fast; the cleanup is cheaper than the shame |
| E15 | Hardcoded secret | Random | Codebase 30+ | Report: MO −2, Codebase −5 · Fix quietly: Codebase −5 · Ignore: incident chance +50% for 60 days · exh. Ignore | A leaked key gets rotated, not just deleted |
| E16 | Stale PR | Random | Any | Ping one named reviewer: 60% merged in 2 days · Post in the channel: 30% · Merge anyway: Codebase +5, MO −5 | Small PRs get reviewed; ask one named person |
| E17 | Credit taken | Random | Coworker demo | Speak up: MO +5, Rapport −15 · Say nothing: MO −3 · Send the brag doc (tip): MO +6 | Write it down the day you ship it |
| E18 | Recruiter DM | Random | Any | Take the call: a posting that skips to interview · Ignore · exh. Ignore | Always take the call; information is free |
| E19 | Coffee machine breaks | Random | Onsite | None; Burnout recovery halved for 3 days | — |
| E20 | Laptop dies | Random | Personal | Pay 1.2 k$ · Limp along: ticket speed −20% for 30 days · exh. Limp along | An emergency fund is boring until it's the only thing that works |
| E21 | Lifestyle offer | Scheduled | After any raise | Upgrade a home tier · Stay | Raise your savings rate before your rent |
| E22 | Ticket reassigned to an AI agent | Random | Any | Review its PR properly: Skill +3, Burnout +4 · Approve it: Codebase +10 · exh. Approve | Reviewing generated code is a skill now; practise it |
| E23 | Mentor offer | Random | Rapport 60+ with a senior | Accept: Skill +0.05 a day, review Evidence +10, Burnout +0.05 a day · Decline | Ask for mentorship specifically: 30 minutes, every two weeks |
| E24 | Overtime ask | Random | Deadline in 3 days or an incident | Stay late: Hours locked at 5 for 5 days, MO +4 · Decline: MO −3 · exh. Stay late | Overtime is a loan; know who's paying it back |
| E25 | Review request | Random | Mid and Senior | Review properly: Rapport +10, ticket speed −10% for 5 days · Rubber-stamp: Codebase +3 | Review the design, not the semicolons |
| E26 | Blame post-mortem | Random | Senior; incident after running Fast | Own it: MO −4, Codebase −10 · Blame the deadline: MO −8 | Blameless post-mortems fix systems; blame fixes nothing |

**Run 1 resizing chain (R-RUN-02).** Five readable signs before the scene: a hiring freeze (about day 150); an "efficiency" all-hands (about 165); your project loses its next quarter on the roadmap (about 190); Minh's desk goes dark in a first round (about 210); Dana's calendar invite with no agenda (about 235).

**Layoff scene (D-22).** About 20 seconds, skippable after the first time. The VS intro plays "DANA vs YOU", then no fight starts. Dana reads the euphemism ("We're reshaping how we're shaped"), the severance figure appears, your badge greys out, and your desk goes dark in the diorama.

## 10. Job hunt

The job hunt is the DoomApply app on your phone: its board is the route map of your career, and every interview behind it is still the Dana duel (D-03, P-02).

**The board (R-JOB-01)**

- 3–5 postings, refreshed every 14 days or after you apply.
- Each posting is a node: company and archetype, required level, salary at this floor, work mode, one or two visible clauses (on-call, "unlimited PTO", remote in writing), and one hidden clause revealed in the contract.
- Applying costs Burnout +3 while employed, +2 while unemployed. A reply arrives in 3–10 days.
- Each application while employed has a 5% chance your manager notices the profile update: MO −10.

**Callback (R-JOB-02)**

```latex
p_{\text{callback}} = 0.35 \times f_{\text{level}} \times (1 - 0.15\,n_{\text{short tenure}}) \times (1 + 0.1\,n_{\text{references}}) \times e_{\text{handbook}}
```

Level fit *f* is 1.0 at your level, 0.5 one level up, 0.8 below your level.

**Interview (R-JOB-03).** The existing duel, fed by the work state (assumption A-01).

| Duel input | Comes from |
| --- | --- |
| Your Composure HP | base × (1 − Burnout ÷ 200) |
| Answer Meter width | base × (1 + Skill ÷ 200) × (1 − Rust ÷ 200) |
| Dana's Doubt HP | base × the floor multiplier (section 8) |
| Extra answer options | Handbook tips (section 11) |

The interview is a scheduled event 3–7 days after the callback, shown on the calendar; time pauses for it and Rust resets to 0. One duel per offer; MegaCorp postings take two.

**Offer (R-JOB-04).** The existing contract modal: Accept, Negotiate once, or Decline. Negotiation succeeds with chance 0.30 + 0.05 × runway months, capped at 0.70, and adds 8% salary — savings are your leverage. Accepting while employed is a voluntary exit.

**Study (R-JOB-05).** A DoomApply action: Burnout +4, Rust −20, Skill +1. Three Studies while unemployed prevent the Résumé Gap Scar.

**Adapter to the existing Phase 1 code (R-JOB-06).** Wrap the duel and the contract modal behind one typed interface, so the shipped code never learns about the new systems:

```text
DuelRequest  { composure, meterWidth, doubtHp, floor, archetype, unlockedOptions[], rounds }
DuelResult   { passed, composureLeft, dreamRealityDelta }
OfferRequest { company, archetype, level, salary, workMode, clauses[], hiddenClause, runwayMonths }
OfferResult  { decision: accept | negotiate | decline, finalSalary, clauses[] }
```

Retired from the Phase 1 build: the day loop, the energy pips, and the separate rent countdown (D-04).

## 11. Scars and the Handbook

Scars make each job in a run harder than the last; the Handbook makes each run a little easier than the last, mostly with more options rather than more power.

**Scars, within a run (R-SCAR-01, P-04).** Three stacks at most of each. A layoff gives no Scar.

| Scar | Gained when | Effect per stack | Counterplay |
| --- | --- | --- | --- |
| Short Tenure | You leave a job before day 180, except by layoff | Callback chance −15% | Removed after 360 days at one job |
| Burnout History | A forced leave (Burnout hits 100) | Burnout floor +15 | One stack removed by 120 days at Burnout 30 or less |
| Bad Reference | Fired, or you quit with MO under −30 | Next job's MO starts at −20 | A reference from a coworker at Rapport 60+ cancels it |
| Résumé Gap | Unemployed more than 60 days | Offers −10% | Three Studies while unemployed prevent it |
| Corner-Cutter | You leave a Senior job with Codebase 80+ | Next job's Codebase starts +15 | Get a later job's Codebase under 40 |

**Handbook, between runs (R-HB-01, D-18).** Every Ducky tip is collected permanently the first time it appears; v1 has 24. Each tip is one of three kinds.

| Kind | What it does | Examples | Cap |
| --- | --- | --- | --- |
| Option | Unlocks a choice in an event or an answer in a duel | Get it in writing (E08 push back), Landlords negotiate too (E04) | None |
| Edge | A small permanent bonus | The five below | 5 tips, about 15% of total power |
| Lore | A joke and a truth, no effect | Read the slides for what isn't said (E05) | None |

| Edge tip | Bonus |
| --- | --- |
| Emergency fund (E20) | Each run starts with one extra month of expenses saved |
| Brag doc (E02) | Review Evidence +10; also unlocks the E17 option |
| Take the call (E18) | One extra posting on the board |
| Overtime is a loan (E24) | Burnout gain at notch 5 is 10% lower |
| Negotiate every offer (contract modal) | Negotiation chance +5% |

**Other unlocks:** The Graduate after run 1; The Self-Taught after the first Studio win or five runs; an ending gallery; Handbook completion shown as a percentage.

## 12. Office diorama in the existing pixel-art style

The office is drawn in the pixel-art style set by the original game docs. "No art budget" means no commissioned art: reuse existing sprites and tiles first, and draw anything new in the same style (D-21, D-25, R-DIO-01).

**Visual language**

- A top-down pixel-art floor plan in a tall column about three screens high; scrolling it reads the company's health.
- The same pixel grid, palette and character proportions as the shipped game. Where this spec and the original art docs differ on a detail, the art docs win.
- Top to bottom: manager's office and meeting rooms, the server rack, desk rows, the pantry, the exit.
- You stand out the way the shipped game already marks the player.

**State as sprite and tile swaps (R-DIO-02)**

| What changes | How it looks |
| --- | --- |
| Time of day | A palette or lighting shift across each tick |
| Overtime | At 18:00 coworkers walk to the exit; your desk-lamp sprite stays lit |
| Burnout | Your sprite's posture frames: upright, slumped, head on the desk |
| Codebase | A server-rack sprite with 10 LED pixels; one turns red per 10 points |
| Headcount | A removed coworker's desk swaps to an empty, unlit desk tile |
| Incident | Every monitor sprite flashes red |
| Remote work | The view swaps to your home room; its furniture follows your home tier, and The Studio has the window, plant and lamp from the video |

**Walking (R-DIO-03).** Coworkers move along fixed waypoint lanes — desk, pantry, meeting room, exit — with no pathfinding, using the game's existing walk cycle. You walk only inside event scenes.

**Pause-and-zoom (R-DIO-04).** When an event fires, the camera steps from 1× to 2× or 3× on the event's focus location and the card slides up into the thumb zone. Zoom stays at whole-number steps with nearest-neighbour filtering so pixels stay crisp. Closing the card zooms back out and the clock resumes.

**Asset list (R-DIO-05).** Each milestone lists the sprites and tiles it needs — size, frames, states — and marks which already exist. Until art exists, use labelled placeholders on the same pixel grid. CC0 pixel packs can fill gaps if they match the palette; check each pack's licence first. The list below is an estimate until it is checked against the existing assets.

| Likely new art | States or frames |
| --- | --- |
| Office floor, wall and room tiles | Day and night palettes |
| Desk with monitor | Normal, red, empty and unlit |
| Desk lamp | On, off |
| Server rack | 10 LED pixels, set in code |
| Coworkers: 5 at Pivotly, palette swaps elsewhere | Idle, walk |
| Your sprite | Upright, slumped, head on the desk |
| Home room | Shared room, One-bed, The Studio, Penthouse |

## 13. Realization plan

Build the simulation first and headless, prove it with bots, then put the cheapest possible UI on it and playtest before drawing a single desk. The riskiest question — is a Junior with one slider fun? — gets answered at M2, before any art or content spend.

**Architecture**

- **Sim core.** A pure, deterministic step function — `step(state, inputs, seed) → (state, events)` — with no engine calls. Write it in the same language as your existing build so there is one implementation, never a port.
- **Content as data.** Events, archetypes, tips and every constant live in data files, reloaded without a rebuild. Tuning becomes editing numbers.
- **Presentation.** Reads state, draws the HUD and diorama, sends inputs (slider, choices, speed). It knows no rules.
- **Adapter.** The existing duel and contract modal sit behind R-JOB-06.
- **Run log.** Every tick summary and every choice. It feeds telemetry, exact bug replays (seed plus inputs), and the ending video's captions.

Why this shape: tuning to a 5–10% win rate needs thousands of runs, so the sim must run without the engine. Save, resume and "no time while closed" all reduce to serializing one state object.

**Balancing harness (R-BAL)**

| Bot | Plays | Target |
| --- | --- | --- |
| Planner | Keeps Burnout 30–60, saves 6 months, routes Agency then MegaCorp, chases remote | Wins 5–10% (R-BAL-01) |
| Coaster | Hours notch 1–2, never applies | No wins; median loss before day 1,800 (R-BAL-02) |
| Grinder | Hours notch 5 always | Mostly Burnout endings; under 2% wins |
| Lifestyle | Upgrades the home tier at every offer | Mostly Plan B endings |
| Random | Random choices and slider | Under 1% wins |

Run 10,000 seeds per bot after every tuning change. Also hold: median run 1,100–1,400 days; each hard-loss ending at least 10% of losses; Planner reaches Mid inside job 1 in 60% or more of run-1 seeds (D-23).

**Milestones**

| # | Build | Exit criterion |
| --- | --- | --- |
| M1 | Sim core, constants, 10 events, the five bots | 10,000 seeds run in minutes; Planner within 5 points of its band |
| M2 | Grey-box UI: phone shell, calendar strip, four numbers, Hours slider, event cards, speed, save and resume; no diorama | Three outside players finish job 1 and can say why they were laid off |
| M3 | Run 1 end to end: Pivotly and its coworkers, the resizing chain, review duel, layoff scene, the board, the adapter | Run 1 playable from day 0 to the board |
| M4 | All systems: 3 archetypes, floor depth, Mid and Senior controls, home tiers, Scars, Studio hold, every ending | A full run playable; Planner wins 5–10% |
| M5 | Pixel-art office diorama, pause-and-zoom, the ending video | Playtesters mention the empty desk or the lamp unprompted |
| M6 | Handbook, events to about 40, a Ducky writing pass, tuning | The playtest gates below pass |

Requirement IDs (R-…) are stable, so each milestone splits cleanly into task folders.

**Playtest gates**

| Ask the player | Pass | If it fails |
| --- | --- | --- |
| Could you have avoided the layoff? | "No, but I could have been readier" | Make the five signs louder |
| What did you do with the Hours slider? | Moved it at least twice a job, with a reason | Junior is passive: raise event density or let events push the slider |
| What were you trying to get? | Names The Studio or one of its conditions | The checklist isn't visible enough |
| Where did you stop playing? | At natural breaks: payday, a review, a job change | Add a soft stop point after big events |

**Telemetry (R-TEL-01):** win rate by background, run length, ending mix, Hours changes per job, share of events auto-resolved, DoomApply use while employed, and quit points.

## 14. Traceability

Each design objective maps to the requirements that carry it, a test that proves it, and a metric that watches it after launch; the harness and content-lint tests belong in CI so a tuning change can't silently break an objective.

| Objective | Requirements | Test | Metric |
| --- | --- | --- | --- |
| O1 Performance doesn't protect you | R-EVT-03, R-RUN-02 | Sim: MO has no effect on layoff selection; run 1 shows five signs before day 240 | Playtest gate 1 pass rate |
| O2 Standing still is never safe | R-ECO, R-WIN-01 | Coaster bot: no wins, median loss before day 1,800 | Coaster loss day |
| O3 Junior eye level, not a manager sim | R-CTL-01, R-CTL-02, R-CTL-03 | UI audit: the Junior screen has exactly one continuous control | Hours changes per job, target 2+ |
| O4 Hard but winnable | R-BAL-01 | Planner wins 5–10% over 10,000 seeds | Live win rate by background |
| O5 The Codebase is the core | R-CB-02, R-CTL-03 | Sim: incidents a year at Codebase 80 are at least 3× those at 20 | Incidents per run |
| O6 Success in tech is the win | R-WIN-01 to R-WIN-08 | Unit tests: the win fires only with all five conditions held 90 days | Mix of winning routes by archetype chain |
| O7 Every failure teaches | R-HB-01, R-EVT-05 | Content lint: every event has a tip or an explicit none | Handbook completion per player |
| O8 Fits mobile sessions | R-CLK, R-TEL-01 | Kill the app mid-run; state restores identically | Session length, target 5–12 min |
| O9 No commissioned art, one pixel style | R-DIO-01 | Asset audit: every new sprite matches the shipped pixel grid and palette; nothing commissioned | Art spend, target 0 |

## 15. Assumptions, risks and open questions

Two answers unblock M1: your engine and language, and the names of Phase 1's duel stats (Q-01, Q-02). Everything else can be tuned later.

**Assumptions**

| ID | Assumption | If wrong |
| --- | --- | --- |
| A-01 | The existing duel can take Composure, Answer Meter width and Doubt HP as inputs | Map the real stat names inside the adapter |
| A-02 | The sim core can be written in the existing build's language and run headless | Build the harness as a separate console target of the same code |
| A-03 | Every number is a starting value | The harness sets the real ones |
| A-04 | 30-day months, 360-day years | Change freely; nothing depends on it |
| A-05 | Money is in in-game thousands of dollars | Any currency label works |

**Risks**

| Risk | Level | Mitigation |
| --- | --- | --- |
| A Junior with one slider still feels passive | High | The M2 gate; about 25 events a year; events that push the slider |
| The Studio routing puzzle is opaque | Medium | Checklist always visible; Ducky hints at a route after the first loss |
| Scars plus rising costs become a death spiral | Medium | Counterplay for every Scar, a 3-stack cap, harness checks |
| New pixel sprites outrun what you can draw | Medium | Reuse existing tiles first; an asset list per milestone; labelled placeholders on the same grid |
| Burnout auto-resolve feels unfair | Medium | Three warnings first; the card says the choice was made for you |
| Layoffs and burnout are real, and the satire stings | Low–medium | The joke is never on the player; Ducky's tip is always genuine |
| Review duel content cost | Low | A 12-prompt pool in v1 |

**Open questions for you**

| ID | Question | My default |
| --- | --- | --- |
| Q-01 | What engine and language is the existing build in? | Godot engine |
| Q-02 | What are Phase 1's duel stats called, and which can be fed in? | The A-01 mapping |
| Q-03 | Startup, Agency and MegaCorp as the three archetypes (P-07)? | Yes |
| Q-04 | Five conditions held 90 days for The Studio (P-05)? | Yes, tuned by the harness |
| Q-05 | Run 1 background fixed to The Intern (P-06)? | Yes |
| Q-06 | Does a broken Studio hold reset to zero or keep half? | Reset to zero |
| Q-07 | Layoff selection by salary, not performance (P-03)? | Yes |

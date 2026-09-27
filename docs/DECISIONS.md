# Decision log

One line per decision. To change your mind, add a new row that supersedes the old one, and never rewrite history. The GDD is updated to match each decision; this file records *what* was decided, *when* and *why*.

| ID | Decision | Why | Date |
|---|---|---|---|
| D1 | **Portrait only** (`display/window/handheld/orientation = 1`) | Developer's call. Overrides the landscape recommendation in the first GDD draft. | 2026-09-26 |
| D2 | **270x480 base** (portrait mirror of 480x270), stretch `viewport` + aspect `expand` + scale `integer`, plus the `Device` scale guard | Same pixel density as the art reference, same art cost and same text capacity (about 40 chars x 40 lines) as the landscape plan. Every verified scaling result carries over with width and height swapped. | 2026-09-26 |
| D3 | Knowledge questions use the one-tap **Answer Meter** | Default. Stats decide the zone and 75% of the score, the thumb about 25%. Mashing returns LATER as the take-home "CRUNCH!" mini-game. | 2026-09-26 |
| D4 | CV lying: **3 lines x Honest / Polished / Lie**, lie probe (Come clean / Bluff), background check only for degree lies | Default | 2026-09-26 |
| D5 | One **Plan B** ending when rent runs out, a grace day if an invite is waiting, one-tap Retry | Default | 2026-09-26 |
| D6 | Customization = **background + name dice** only; cosmetics LATER | Default | 2026-09-26 |
| D7 | **One-tap Negotiate**, the first SHOULD after Research | Default | 2026-09-26 |
| D8 | Interview tuning **(a)**: Doubt HP 118 / 128 / 132; revisit after Playtest #1 | Default | 2026-09-26 |
| P1 | **iPhone first**, built and deployed from the developer's MacBook; Android LATER | The developer has an iPhone and a MacBook, and no Android phone. | 2026-09-26 |
| C1 | 12 parody names renamed (e.g. SynergAI -> Hierarchai, HireBot 3000 -> Parsinator 3000); content ids unchanged | A web check found live businesses with the same names in the same fields. Run a real trademark search before any public release. | 2026-09-26 |
| P2 | **PC only for now:** all work happens on the Windows PC; the MacBook and iPhone steps (Step 2's device checks, every on-iPhone Done-when) wait until the developer sets them up | Developer's call: the Mac and iPhone will be set up later. | 2026-09-27 |
| W1 | **Claude commits and pushes.** After each verified increment Claude commits on a per-step branch (`step-NN-<slug>`, each branched from the previous step's branch) and pushes without asking. The developer reviews and merges on GitHub, in step order, with merge commits (not squash). | The developer is away while Claude builds; one branch per step keeps each review small. Supersedes "the developer commits". | 2026-09-27 |
| W2 | **Dependency gate:** a step may start when every earlier step is either done or has only developer-owned criteria left (device, You-do, manual review). Those steps stay `in_progress`/`verifying`, never `done`, until the developer confirms. | Lets PC work continue without the iPhone; device risk is re-checked before Playtest #1. | 2026-09-27 |
| W3 | **You-do tasks queue up.** Claude never does them. Where a You-do produces something the game needs to run (e.g. `hp_bar`, `stat_bar`), Claude builds a plain placeholder and the proper version stays the developer's exercise. | Keeps the learning tasks while the game stays playable. | 2026-09-27 |
| W4 | **Design huddles while the developer is away:** Claude takes the documented recommended default, logs it here as "agent default, please review", and lists it in the step summary. Scope (MUST/SHOULD/LATER), tone and tip accuracy are never decided without the developer. | Avoids blocking on questions that already have a recommended answer. | 2026-09-27 |
| W5 | **Autonomous run:** Step 2 (the PC part: the device-check screen) through Step 6 (v0.1-greybox), with a summary after each step. Stop early on a blocker, the 2x rule, or a decision only the developer can make. Step 7 (playtest) needs people. | Developer's go-ahead: "go with the recommendations and start". | 2026-09-27 |
| W6 | **No quizzes:** "explain X" checks are recorded from the developer's own statement; Claude doesn't ask for the explanations. | Developer's request. | 2026-09-27 |

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

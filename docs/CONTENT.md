# Software Engineer Simulator - Content Pack (MVP)

Companion to `docs/GDD.md`. Every player-facing string for the MVP, with the stable ids the GDD's data model uses (GDD section 5.0). Each section names the JSON file it becomes.

Status: v1.2, 2026-10-07 (v1.1: 2026-09-29; v1.0: 2026-09-26). v1.2 adds section 16, the career run's draft strings (Run Spec v1, DECISIONS W8), and Run Spec v1 notes in sections 1.1, 3, 14 and 15. v1.1 follows the developer's review of the v0.1 grey-box: the CV screen and lying are gone (DECISIONS D9), the choice questions are in plain language for non-tech players (C3), the Hired card is clearer (C4), and the copy the review queue listed is approved, with its 4 wording fixes (C2). Everything here is still a first draft for playtesting. You (the developer) own the jokes and sign off every career tip before release. 2026-10-07: Negotiate was removed (DECISIONS D-27), so its strings went too (sections 8.2, 10.1, 11 and 13.1 say which; they left the JSON in the code cleanup of 2026-10-08). The career run's strings (Run Spec v1) are section 16: drafts, not in the JSON yet.

---

## 0. Conventions

- **ASCII only** in player-facing strings: no curly quotes, accents, emoji or special dashes. The pixel font may not have them, and `tests/test_content_lint.gd` rejects them.
- **Ids are snake_case and stable.** Don't rename an id once code refers to it; change the text instead.
- **Placeholders:** `{player_name}`, `{company}`, `{job_title}`, `{salary}`, `{work_mode}`, `{commute_min}`, `{office_days}`, `{hours}`, `{last_company}`, `{knockout}`, `{insider}`, `{days}`, `{n}`, `{day}`, `{topic_1}`, `{topic_2}`, `{r}` (rejections), `{g}` (ghosted), `{i}` (interviews), `{total}` (prompts in this interview). Text in `[SQUARE_BRACKETS]` is deliberately left unfilled: that's the joke.
- **Text budgets** (GDD 2.7, enforced by the lint test, which also word-wraps every string at the 40-column portrait text width and checks the line cap):

| Field | Max chars (lines at 40 columns) |
|---|---|
| Dialogue, reaction, bark | 120 (up to 4 lines) |
| Question prompt | 100 (3) |
| Answer button | 40 (1; exactly the button width, so nothing goes in front of the text) |
| Knowledge spoken answer (green / yellow / red) | 80 (3) |
| Posting joke, company card joke, background one-liner, CV line | 60 (2) |
| Tip on screen (`short`) | 120 (4) |
| Email body | 240 (7) |
| Player name | 10 (1) |

- **MVP amounts:** 9 companies (6 flagged `mvp`), 20 posting templates (+1 SHOULD), 18 CV lines, 13 choice questions (+ the Research opener), 22 knowledge questions, 30 tips, 10 rejection lines.
- **Refreshable jokes:** topical 2026 AI-hype lines live in `news.json` and `events.json` so they can be updated without code changes.

---

## 1. World naming sheet -> `data/content/naming.json`

### 1.1 Names

| Key | Name | Tagline / note |
|---|---|---|
| `city` | Byteburg | the city everything happens in |
| `app_video` | ClikClok | short-video app. "Your future, 15 seconds at a time." |
| `influencer` | @RemoteRemy (Remy) | "Just learn to code, bro." |
| `app_jobs` | DoomApply | the phone job app; the hub screen is your phone. "Swipe right on your future." |
| `site_mega` | MegaBoard | site tab 1 (SHOULD). "10 million jobs. Some of them real." |
| `site_brag` | HumbleBrag | site tab 2 and the Network action (SHOULD). "Thrilled to announce: everything." |
| `site_launch` | LaunchPadd | site tab 3, startups (SHOULD). "Equity instead of money since forever." |
| `app_reviews` | Cubicle Whispers | the Research lookup. "Anonymous reviews. Your manager knows it was you." |
| `app_study` | BigOhNo | the Study action. "Invert a binary tree. You will never do this at work." |
| `app_ai` | Guessomatic | the AI assistant everyone pretends not to use |
| `ats_robot` | Parsinator 3000 | the applicant-tracking robot |
| `mascot` | Ducky | a rubber debugging duck that gives the real tips |
| `interviewer` | Dana | one interviewer, three tier outfits |
| `uni_intern` | Byteburg State University | the Intern's real school |
| `uni_graduate` | Metro City University | the Graduate's real school |

Removed 2026-09-29 with the CV screen and lying (D9): Buzzwordsmith, the CV app, and Very Famous University, the school in every degree lie.

Before any public release, run a trademark and app-store search on every name above and on every company in section 4.

**Run Spec v1 (2026-10-07):** the career run adds names (section 16.1): Hierarchai's four coworkers, a coworker name pool, the four home tiers and two phone apps, Home and the Handbook (the Run Spec's placeholder companies Pivotly, Outsourcery and Monolith are replaced by Phase 1's Hierarchai, Scope & Creep Digital and OmniGlobal Dynamics: MC-06, D-34). The same trademark check applies to any of them that ships.

### 1.2 Keywords and topics

Keywords (CV and posting tags): `python` Python, `javascript` JavaScript, `java` Java, `sql` SQL, `git` Git, `cloud` Cloud, `testing` Testing, `apis` APIs, `mobile` Mobile, `data` Data, `agile` Agile, `ai` AI.

Knowledge topics (labels for the Self-Taught's gap list): `algorithms` Algorithms, `data_structures` Data structures, `databases` Databases, `web` Web and HTTP, `tools` Git and testing, `concurrency` Concurrency, `system_design` System design, `security` Security, `behavioral` Behavioral. Gap topics are rolled from the the 7 technical topics other than `tools`.

### 1.3 Banned real brands (lint list)
Case-insensitive, whole-word match over all player-facing JSON strings. Exceptions go in an explicit `lint_allow` list with a reason.

google, alphabet, microsoft, macrohard, apple, amazon, amazoom, meta, facebook, faceplant, instagram, whatsapp, tiktok, youtube, netflix, uber, lyft, airbnb, linkedin, linkedout, indeed, indeedn't, glassdoor, glassdoorknob, leetcode, hackerrank, github, gitlab, stackoverflow, openai, chatgpt, anthropic, claude, gemini, copilot, nvidia, tesla, twitter, reddit, discord, slack, zoom, salesforce, oracle, ibm, intel, samsung, spotify, stanford, stanfurd, harvard, mit, oxford, cambridge, berkeley, caltech, princeton, yale, ledgerly, kubernetes, docker, aws, azure, redis, bytedance, douyin, snapchat, pinterest, patreon, tinder, ziprecruiter, careerbuilder, wellfound, angellist, teamblind, taleo, icims, hirevue, jobvite, smartrecruiters, jobscan, zety, canva, neetcode, algoexpert, codesignal, codewars, duolingo, udemy, coursera, codecademy, freecodecamp, udacity, xai, deepseek, midjourney, replit, doordash, grubhub, deliveroo, instacart, postmates, adp, paychex, quickbooks, accenture, deloitte, hewlett, xerox, pagerduty, jira, bitcoin, dogecoin, coinbase, cmu, cornell, synergai, quantumleaf, nimbus, hirebot, jobdeck, glassceiling, resumeforge, promptpal, bytebistro, algogrind.

(Why "LinkedOut" is banned: it is the name of a real inclusion program for people excluded from work, so mocking it would punch down. "Macrohard" is a real company name since 2025.)

---

## 2. Intro cutscene -> `data/content/cutscene.json`

6 panels, 40 s total, 2022 to 2026. Background-neutral (it plays before the background pick). Tap = finish/advance a caption; hold the Skip pill (bottom-right) 0.5 s = skip all (Android Back too, LATER). Panels are portrait (270x480 on screen). Build it as text slides first; art last. Visual notes are for the artist and are not shown.

| id | Time | Visual (not shown) | Captions (shown in order) | Audio |
|---|---|---|---|---|
| `intro_p1` | 6 s | Side-view cutaway of a small bedroom at night: warm desk lamp, chemistry textbook, a 17-year-old under a blanket lit by phone glow. Night-palette dithered clouds in the window (the reference's cloud style). | "2022. You are 17." / "You are supposed to be asleep." | clock tick, phone buzz x2 |
| `intro_p2` | 7 s | The phone fills nearly the whole panel: a thin bezel and the kid's thumb at the edges, bedroom blurred in the margins. ClikClok UI: "@RemoteRemy - A DAY IN THE LIFE OF A SOFTWARE ENGINEER". Inside: a sunlit studio (the reference's bright sky and fluffy clouds through a big window). Remy wakes; clock 10:47. Then his laptop grid: six sleepy faces, "STANDUP 00:12:00". | Remy: "Woke up at 10:47. No alarm." / "Commute: 3 steps." / "Standup: 12 minutes. Pants: optional." | swipe whoosh, lo-fi beat drops in |
| `intro_p3` | 7 s | Pan sideways across the one-room studio (panel up to 480 px wide, 270 visible); labels pop: BEDROOM, OFFICE, GYM (one kettlebell), KITCHEN (one espresso machine). Then a balcony at sunset, pixel coins raining, "SALARY: $$$$$$" with a sticker "CENSORED FOR ENGAGEMENT". Comments scroll up: "HOW DO I START", "is math needed??", "bro lives in 2030". | Remy: "One room. Bedroom, office, gym. That's called efficiency." / "Six figures to think. Mostly about lunch." / "Just learn to code, bro. Link in bio." | pop x4, cash register, crowd "ooooh" |
| `intro_p4` | 6 s | Close-up: your eyes become pixel sparkles. You close the chemistry book. A search bar types "how to become software engineer fast easy remote". | "That night, you made a decision." | 8-bit "aaah", key clicks |
| `intro_p5` | 7 s | Calendar pages fly 2022 -> 2026 while seasons change outside the same window. Books and coffee cups pile up; a screen says "Hello, World!" and you fist-pump; a bug counter goes 99 -> 127. Keep it ambiguous: it could be classes, internships or tutorials. | "Four years of learning." / "Some of it on purpose." | upbeat chiptune, page flips |
| `intro_p6` | 7 s | Same room, desaturated, rain. You are 21. A sports-style ticker crawls: "RECORD PROFITS, 12,000 LAYOFFS 'TO FOCUS ON AI' * ENTRY-LEVEL ROLE: 5+ YEARS REQUIRED * 4,000 APPLICANTS FOR 1 JUNIOR ROLE". The phone buzzes: Remy, same studio, now full of moving boxes, ring light flickering. Smash to black; title slams in. | "2026." / Remy: "So... I got laid off. Anyway! My course is 70% off." / (title) "SOFTWARE ENGINEER SIMULATOR" / "How did you spend those four years?" | beat slows like a dying cassette, record scratch, 1 s silence, title sting |

---

## 3. Backgrounds -> `data/content/backgrounds.json` (numbers live in `BackgroundData`)

**Run Spec v1 status:** run 1's background is always The Intern (P-06), so run 1 never shows Background select; The Graduate unlocks after run 1 and The Self-Taught after the first Studio win or five runs (GDD 5.21). The card's energy and rent-runway lines (`ui_energy_per_day`, `ui_rent_runway`) retire with the day loop (D-04), and what replaces them is Settled (MC-04, D-30): starting savings in months of expenses. The perk and flaw lines describe hunt mechanics (referrals, knockouts, Tailor & Apply), so they need new text now that MC-03 is settled (D-32): in the career run a background changes only the duel's inputs, starting savings and the commute. The lines the duel uses stay (`vs_nickname`, `dana_opener`), and so does `plan_b_line`. The header that ends the intro is Settled (MC-11, D-34).

### 3.1 Text

**`intern`** - THE INTERN - EASY
- `selector`: "INTERN"
- `one_liner`: "Three internships, 214 connections, one mentor who texts."
- `perk`: "WARM INTROS: 2 referrals. A referral gets a human to read your CV and skips knockout filters."
- `flaw`: "BIG-TECH AURA: startups think you'll leave in 6 months. Your algorithms are rusty."
- `vs_nickname`: "THE CONNECTED"
- `dana_opener`: "Three internships. Why didn't they keep you? ...Budget freeze. Right. Same."
- `commute_line`: "Coffee shop Wi-Fi. 20 minutes away."
- `plan_b_line`: "Your old internship mentor liked your first video. Then unfollowed."
- Hoodie color: teal.

**`graduate`** - THE GRADUATE - MEDIUM
- `selector`: "GRADUATE"
- `one_liner`: "One diploma, one student loan, zero callbacks."
- `perk`: "DIPLOMA: passes 'degree required' filters. TEXTBOOK ANSWER: wider zone on your first knowledge question."
- `flaw`: "ENTRY-LEVEL PARADOX: '1+ years' filters reject you unless you Tailor & Apply."
- `vs_nickname`: "THE THEORIST"
- `dana_opener`: "A fresh grad. The ATS wants 3 years. I want to hear what you built."
- `commute_line`: "Campus library, alumni pass. 45 minutes."
- `plan_b_line`: "Your diploma now holds up the ring light."
- Hoodie color: maroon.

**`self_taught`** - THE SELF-TAUGHT - HARD
- `selector`: "SELF-TAUGHT"
- `one_liner`: "437 hours of tutorials, 6 languages, 2 bus transfers."
- `perk`: "BREADTH: 6 skills on your CV. SCRAPPY BUILDER: startups love shipped projects."
- `flaw`: "THE LONG WAY: 2-bus commute, no degree, knowledge gaps, no team stories yet."
- `gaps_line`: "Gaps: {topic_1}, {topic_2}"
- `vs_nickname`: "THE SELF-MADE"
- `dana_opener`: "Our ATS hates 'no degree'. I don't. Show me what you shipped."
- `commute_line`: "Home Wi-Fi: one bar. Library: two buses away."
- `commute_strip` (SHOULD): "Bus 1 of 2. -4 energy."
- `plan_b_line`: "Your course is called 'Self-Taught, Self-Employed'. It sells."
- Hoodie color: mustard.

Background select header: "How did you spend those four years?" (`ui_background_header`). Button: "CHOOSE" (`ui_choose`). Both live in section 10.1. `selector` is the short name on the S03 selector button (80 px wide, 13 characters), above the difficulty; added 2026-09-27 with the text of the GDD S03 mockup and ARCHITECTURE 11.3.

### 3.2 Name dice -> `data/content/names.json`
Default: **Alex**. Dice pool (20, gender-neutral, none shared with Dana, Remy or Jordan, the teammate in eq_credit_theft):
Alex, Sam, Morgan, Taylor, Riley, Casey, Jamie, Avery, Quinn, Rowan, Kai, Sky, Drew, Robin, Jesse, Parker, Reese, Emerson, Charlie, Finley.

---

## 4. Companies -> `data/content/companies.json`
Fields: `id, name, tier, mvp, tagline, card_joke (<=60), insider (<=40; the insider "Why us?" answer button), dana_line (<=120), review (<=60), red_flags (<=40 each), art (not shown)`. Numbers come from the tier (`TierData`).

### Big corp

**`co_omniglobal`** - OmniGlobal Dynamics - `big` - mvp: true
- tagline: "Synergizing Tomorrow, Yesterday."
- card_joke: "Enterprise software, consulting, and printers."
- insider: "You run payroll for 2M businesses."
- dana_line: "Sorry. Reorg. As of two minutes ago I'm Partner III. Continue."
- review: "2/5 - Great benefits. 6 managers in 11 months."
- red_flags: "Return to office: 5 days", "A reorg every quarter"
- art: glass atrium, badge gates, LED wall where the stock ticker goes up and a small HEADCOUNT counter goes down, ping-pong table "RESERVED FOR Q3 OFFSITE".

**`co_nimbus`** - Murkcloud - `big` - mvp: true
- tagline: "Your Data. Somewhere."
- card_joke: "Cloud and AI. Mostly AI. Humans sometimes."
- insider: "Your cloud runs half of Byteburg."
- dana_line: "Our AI screened you first. It rated you 6/10. It rates everything 6/10."
- review: "3/5 - Interviewed, onboarded and laid off by the AI."
- red_flags: "First interview is with an AI"
- art: server racks fading into parallax fog, cold blue light, floor decal "AI-FIRST. HUMANS-SOMETIMES.", an Employee of the Month frame showing a server.

**`co_adverse`** - Engagement Farms Inc. - `big` - mvp: false
- tagline: "Connecting People to Advertisers."
- card_joke: "Parent company of ClikClok. Yes, that ClikClok."
- insider: "You own ClikClok. I'm on it daily."
- dana_line: "Every time someone here says 'family', a desk disappears. Watch."
- review: "4/5 - Great free food. Ate it alone after the restructure."
- red_flags: "'We're a family'", "Return to office: 5 days"
- art: candy-colored open office, neon "WE'RE A FAMILY" sign, nap pod "BOOKED UNTIL 2027", engagement graphs on every wall.

### Mid-size

**`co_beigeware`** - Beigeware Financial - `mid` - mvp: true
- tagline: "Boring on Purpose."
- card_joke: "Payroll and insurance software since 1998."
- insider: "You've been stable for 28 years."
- dana_line: "Days since last incident: 0. Days since last reorg: 2,000. We like it that way."
- review: "4/5 - Nothing exciting ever happens. I'm so happy."
- red_flags: "Legacy code from 1998"
- art: beige cubicles, one flickering light, a fax machine taped "DO NOT UNPLUG - PROD", a sad ficus, a sign "DAYS SINCE LAST INCIDENT: 0".

**`co_bytebistro`** - Lukewarm Express - `mid` - mvp: true
- tagline: "Your Food. Eventually."
- card_joke: "Food delivery. The fries are in the lake again."
- insider: "You deliver a million meals a week."
- dana_line: "Sorry, that alert was the fries. They're on the highway. Again."
- review: "3/5 - Free lunch every day. It arrives at 4 PM."
- red_flags: "'Fast-paced' (no documentation)"
- art: converted warehouse, wall-sized live map of delivery scooters (some in the lake), neon burger sign, a "SURGE PRICING" gong.

**`co_pixelpivot`** - Scope & Creep Digital - `mid` - mvp: false
- tagline: "We'll Build Anything. Anything."
- card_joke: "An agency. Your next client is a mattress store."
- insider: "You shipped 14 client apps last year."
- dana_line: "This interview is billed to a regional mattress chain. Please be concise."
- review: "3/5 - Built 14 apps in a year. I dream in invoices."
- red_flags: "'Wear many hats'", "Client-facing (clients yell)"
- art: exposed-brick loft, a wall of parody client logos (mattress store, dentist, lettuce startup), a Gantt chart ending in a hand-drawn skull.

### Startup

**`co_synergai`** - Hierarchai - `startup` - mvp: true
- tagline: "Agents All the Way Down."
- card_joke: "An AI agent that manages your AI agents."
- insider: "Your agents manage 10,000 agents."
- dana_line: "Quick update: we're AI for pets now. Same questions though."
- review: "5/5 (1 review, written by the founder)"
- red_flags: "Equity instead of salary", "Pivots every week"
- art: co-working warehouse, neon "HUSTLE" sign, beanbags, kombucha tap, a hockey-stick graph with no axes.

**`co_quantumleaf`** - Entangled Greens - `startup` - mvp: true
- tagline: "Disrupting Lettuce."
- card_joke: "Blockchain, quantum, and lettuce. Mostly lettuce."
- insider: "You grow lettuce with sensors. Neat."
- dana_line: "Part of your salary is LettuceCoin. Its value is: lettuce."
- review: "4/5 - Great culture. Paid partly in lettuce."
- red_flags: "Paid partly in tokens"
- art: greenhouse office, hydroponic lettuce under purple grow-lights, a padlocked box labelled "QUANTUM" with one blinking LED.

**`co_stealth`** - Stealth Mode Inc. - `startup` - mvp: false
- tagline: "We Can't Tell You."
- card_joke: "Industry: [REDACTED]. Office: a basement."
- insider: "Honestly? The mystery."
- dana_line: "Please sign this NDA about the NDA. Great. Hello."
- review: "?/5 - [Removed at the employer's request]"
- red_flags: "You can't know what you're applying for"
- hired_extra: "You may now know what we do. ...It's a to-do app."
- art: basement, blacked-out windows, a whiteboard under a bedsheet, one humming server rack, a shredder with a "BUSY" light.

---

## 5. Job postings -> `data/content/postings.json`
Templates are tier-bound. `company: any` = paired with a random company of that tier when the card is generated. Fields: `id, tier, company, title (<=40), tags (3), degree, min_years, ghost (roll | always), joke (<=60), salary_text (<=40)`. Knockout counts match GDD section 7: Big has a degree knockout on 5 of 7 and a years knockout on 4 of 7; Mid has a years knockout on 3 of 7; startups have none.

### Big corp (7)

| id | title | tags | degree | min_years | ghost | joke | salary_text |
|---|---|---|---|---|---|---|---|
| `job_big_junior_swe` | Junior Software Engineer I | java, testing, agile | yes | 5 | roll | Entry level. 5+ years required. PhD a plus. | Competitive |
| `job_big_cloud_associate` | Associate Cloud Engineer | cloud, python, data | yes | 0 | roll | Must know our internal tools. Not sold outside. | $98k-$190k (you get $98k) |
| `job_big_future_talent` | Developer, Future Opportunities | java, python, cloud | yes | 0 | always | Evergreen role. Building our talent pipeline. | Competitive |
| `job_big_new_grad_sre` | New Grad Reliability Engineer | python, cloud, testing | yes | 1 | roll | On-call from day 2. The pager is named Gerald. | $105k + 1 energy drink/week |
| `job_big_frontend` | Frontend Engineer, Engagement | javascript, testing, data | no | 3 | roll | Make infinite scroll more infinite. | $100k-$120k |
| `job_big_ai_engineer` | AI Engineer (Junior) | ai, python, data | yes | 3 | roll | 3+ years with a model released 8 months ago. | $110k-$130k |
| `job_big_data_analyst` | Data Analyst II (Level 0.5) | sql, data, agile | no | 0 | roll | Build dashboards nobody opens. At scale. | $95k |

### Mid-size (7)

| id | title | tags | degree | min_years | ghost | joke | salary_text |
|---|---|---|---|---|---|---|---|
| `job_mid_backend` | Backend Developer | java, sql, apis | no | 1 | roll | Read code from someone who left in 2009. | $78k-$88k |
| `job_mid_qa` | QA Automation Engineer | testing, python, sql | no | 0 | roll | Find bugs. Not too many. Morale. | $70k-$80k |
| `job_mid_mobile` | Junior Mobile Developer | mobile, apis, git | no | 0 | roll | Deliver cold fries in 45 minutes. In an app. | $72k-$85k + late lunch |
| `job_mid_data_eng` | Data Analyst to Data Engineer | sql, python, data | no | 2 | roll | Title upgrade. Salary upgrade sold separately. | $68k |
| `job_mid_fullstack` | Full-Stack Developer (Full-Full) | javascript, sql, cloud | no | 0 | roll | Frontend, backend, DevOps and the office plants. | $65k-$75k |
| `job_mid_web_rescue` | Web Dev, Client Rescue Squad | javascript, git, testing | no | 1 | roll | Fix sites the last agency built. Also us. | $62k-$70k |
| `job_mid_platform` | Junior Platform Engineer | cloud, git, agile | no | 0 | roll | CI takes 45 minutes. Your job: make it 44. | $75k-$85k |

### Startup (6)

| id | company | title | tags | joke | salary_text |
|---|---|---|---|---|---|
| `job_st_founding` | any | Founding Engineer #1 (of 1) | python, ai, apis | Build the AI that builds the AI. By Friday. | $55k + 0.0001% equity |
| `job_st_fullstack_ninja` | any | Full-Stack Ninja Rockstar | javascript, mobile, cloud | Must thrive in chaos. Mostly chaos. | $58k + snacks |
| `job_st_ai_generalist` | any | AI Generalist (Everything Engineer) | ai, python, data | Ownership mindset: you own everything. Bugs too. | $60k + equity (vibes) |
| `job_st_mobile_barista` | any | Mobile Dev (Also Barista) | mobile, javascript, git | Snacks unlimited. Salary limited. | $52k + all the oat milk |
| `job_st_growth` | any | Growth Engineer | javascript, data, apis | Make the hockey-stick graph real. By Q3. | $56k + 0.0002% equity |
| `job_st_stealth_swe` | co_stealth | Software Engineer (Under NDA) | apis, sql, cloud | 5 years of [REDACTED]. Sign NDA to see pay. | Competitive (NDA) |

Startup templates: degree no, min_years 0, ghost roll. `job_st_stealth_swe` is only generated when `co_stealth` is enabled.

### The Unicorn (SHOULD, once per run via `evt_unicorn`)

| id | tier | company | title | tags | ghost | joke | salary_text |
|---|---|---|---|---|---|---|---|
| `job_unicorn_remote` | mid | any | Junior Dev, Fully Remote, 4-Day Week | (the player's 3 best honest tags, so all 3 show green) | always | Fully remote. $180k. Junior. 9,000 applicants. | $180k |

Research reveal: "Posted 2,555 days ago. Reposted every week since 2019." It is the influencer's dream, and it never replies.

### Card and research strings

| id | Text |
|---|---|
| `card_applicants` | "{n} applicants" |
| `card_posted` | "Posted {days} days ago" |
| `card_posted_one` | "Posted 1 day ago" |
| `card_posted_today` | "Posted today" |
| `card_reposted` | "Reposted" |
| `card_knockout` | "Knockout: {knockout}" |
| `knock_degree` | "Degree required" |
| `knock_years` | "{n}+ years experience" |
| `research_ghost` | "Posted {days} days ago. Reposted {n} times. Hmm." |
| `research_clean` | "Posted {days} days ago. Seems real. Probably." |
| `research_salary` | "Real salary band: {salary}" |
| `research_flags` | "Red flags:" |
| `research_none` | "No red flags found. Suspicious in itself." |
| `hirebot_scan` | "Parsinator 3000 is reading your CV..." |
| `hirebot_found` | "Keywords found: {n}/3" |
| `stamp_sent` | "SENT" |

`card_posted_one` and `card_posted_today` are grammatical variants of `card_posted` for 1 and 0 days (startups can post 0 days ago), added 2026-09-27 for Step 6 and approved by the developer on 2026-09-29 (DECISIONS C2).

---

## 6. CV lines -> `data/content/cv_lines.json`
Fields: `id, background, line (edu | exp | proj), variant (honest | polished), text (<=60), tags, degree (edu only: shows a degree), passes_years (exp only)`. Both variants are true: Polished is an honest reframing of the same facts.

Since 2026-09-29 (DECISIONS D9) there is no Lie variant and no CV screen. Quick Apply sends the Honest lines; Tailor & Apply sends the Polished ones for that one application (GDD 5.4). The lint checks exactly 6 lines per background, no lie-only fields (`degree_claim`, `probe`, `probe_at`), and that a Polished Education line never changes the degree. The line texts aren't shown in the MVP; their tags and gates decide the odds and the knockouts.

### The Intern (honest tags: python, sql, testing, agile, git)

| id | text | tags | gates |
|---|---|---|---|
| `cv_intern_edu_honest` | B.Sc. Computer Science, Byteburg State (GPA 3.3) | python | degree |
| `cv_intern_edu_polished` | B.Sc. CS + Data minor (two electives count) | python, data | degree |
| `cv_intern_exp_honest` | 3 internships: fixed 14 bugs, coverage 41% to 58% | sql, testing, agile | passes_years |
| `cv_intern_exp_polished` | SWE Intern x3: built 3 internal APIs, on-call once | sql, testing, agile, apis | passes_years |
| `cv_intern_proj_honest` | Standup-reminder bot, used by 30 coworkers | git | |
| `cv_intern_proj_polished` | Team bot on the cloud: 30 daily users, 0 outages | git, cloud | |

### The Graduate (honest tags: java, python, sql, git)

| id | text | tags | gates |
|---|---|---|---|
| `cv_graduate_edu_honest` | B.Sc. Information Tech, Metro City University | java | degree |
| `cv_graduate_edu_polished` | B.Sc. IT; courses: Databases, ML, Cloud | java, data | degree |
| `cv_graduate_exp_honest` | Teaching Assistant, Intro to Programming (2 terms) | python | |
| `cv_graduate_exp_polished` | Capstone team of 4 + TA for 120 students | python, agile | passes_years |
| `cv_graduate_proj_honest` | Capstone: room-booking app (my part: backend + DB) | sql, git | |
| `cv_graduate_proj_polished` | Built the REST API + database for a team app | sql, git, apis | |

### The Self-Taught (honest tags: javascript, apis, python, sql, git, mobile)

| id | text | tags | gates |
|---|---|---|---|
| `cv_self_taught_edu_honest` | High school diploma + 400 hrs of online courses | (none) | |
| `cv_self_taught_edu_polished` | Self-directed CS curriculum (11 certificates) | data | |
| `cv_self_taught_exp_honest` | Freelance: sites for a bakery, a tattoo shop, my uncle | javascript, apis | |
| `cv_self_taught_exp_polished` | Freelance dev, 3 clients, 2 yrs (+ a bakery chatbot) | javascript, apis, ai | passes_years |
| `cv_self_taught_proj_honest` | 3 small apps deployed: budget, recipes, bus times | python, sql, git, mobile | |
| `cv_self_taught_proj_polished` | Shipped 3 apps, live, with READMEs and tests | python, sql, git, mobile, cloud | |

---

## 7. Choice (ethics) questions -> `data/content/questions_choice.json`
Format per entry: header `id | teamwork | tiers | tip`, the prompt, then one line per answer: `+` good, `~` neutral, `-` bad, `*` background-exclusive answer (replaces the neutral button for that background). Each answer line is `kind | text (<=40) | Dana's reaction (<=120)`. Buttons are shuffled at runtime. Effects are in GDD 5.8.3.

Since 2026-09-29 (DECISIONS C3) every prompt, answer and reaction is in plain language, so a player who has never worked in tech can see which answer is right: no deploy, rollback, postmortem, config, pull request, rotate, anonymize or audit logs. The right answer stays jokingly obvious and the wrong one is the joke. Ids, kinds, tiers, tips and `opener_only` are unchanged.

```
eq_why_us | teamwork: no | tiers: all | tip: tip_research_company
Q: So. Why do you want to work here?
+ insider | {insider} | ...You actually read about us. That's rarer than you'd think.
~ neutral | Honestly? Rent. | Fair. Relatable. Not an answer, but fair.
- bad | What do you do again? | We have a website. It has an About page. It's right there.
```
(`eq_why_us` is only used as the opener after Research. `{insider}` is the company's insider line from section 4. It can repeat across interviews.)

```
eq_friday_deploy | teamwork: no | tiers: all | tip: tip_small_changes
Q: Friday, 4:55 PM. Your app update is done, but nobody has tested it yet. What do you do?
+ good | Test it, then release it on Monday. | Correct. Weekends are for sleeping, not for fixing Friday's surprises.
~ neutral | Ask the team chat what to do. | Safe-ish. The team chat says 'Looks good!' to everything. It said it to a blank page once.
- bad | Release it now. Turn off my phone. | Bold. That's exactly how our last three weekends got cancelled.
```

```
eq_credit_theft | teamwork: yes | tiers: all | tip: tip_give_credit
Q: Your teammate Jordan fixed the big bug. In the meeting, your manager thanks YOU.
+ good | Say it was Jordan's fix, not mine. | Correct. Steal credit once and your whole team starts keeping receipts.
~ neutral | Say nothing, thank Jordan later. | Half credit. Jordan noticed. Jordan remembers.
- bad | 'Thanks, it was really hard.' | Jordan is in this meeting. Jordan is looking at you.
* intern | good | At my internship we shared credit. | You mention the internship a lot. Correct answer, though.
```

```
eq_outage_blame | teamwork: yes | tiers: all | tip: tip_blameless
Q: Your update broke the site's Pay button for 10 minutes. Tomorrow the team reviews what went wrong.
+ good | Own it, explain it, prevent it. | Perfect. That meeting is for fixing the process, not the person. The process is in trouble.
~ neutral | Say it was 'a settings issue'. | True. And who changed the settings? (You. It was you.)
- bad | Blame the intern. | We don't have an intern. We have you.
```

```
eq_ai_takehome | teamwork: no | tiers: all | tip: tip_ai_tools
Q: Honest question: did you use an AI assistant on our at-home coding test?
+ good | Yes, and I can explain every line. | Great. We allow tools. We don't allow mysteries.
~ neutral | A little. Mostly for vibes. | 'Vibes' won't help when I ask what line 12 does. Close, though.
- bad | Never. What's an AI? | The screen you're sharing shows Guessomatic, the AI app. Open. Right now.
```

```
eq_leaked_password | teamwork: no | tiers: all | tip: tip_secrets
Q: Someone posted the password to all our customer data in the company-wide group chat.
+ good | Tell security so they change it. | Exactly. Once a password leaks, it isn't a password anymore. It's trivia.
~ neutral | Delete the message and move on. | Deleting it doesn't change it. Half the company already saw it. Some took screenshots.
- bad | Screenshot it. Might be handy. | Please stay seated. Legal is walking over.
```

```
eq_celebrity_orders | teamwork: no | tiers: all | tip: tip_privacy
Q: A coworker dares you to look up a celebrity customer's order history.
+ good | No. No business reason, no access. | Correct. Also, every look-up is recorded. Every single one.
~ neutral | Only if we hide the name first. | Nice try. Hiding the name doesn't make it your business.
- bad | Sure, in incognito mode. | Private mode hides it from your browser history. Not from our security team.
```

```
eq_meeting_overload | teamwork: no | tiers: big, mid | tip: tip_focus_time
Q: Six hours of meetings today. Your deadline is tomorrow.
+ good | Skip the optional ones, ask for notes. | Healthy boundaries! Rare here, but healthy.
~ neutral | Attend all, camera off, work quietly. | Relatable. Our nod-detection AI flagged you anyway.
- bad | Book a meeting about fewer meetings. | Accepted. It's recurring now. Weekly.
```

```
eq_impossible_deadline | teamwork: yes | tiers: all | tip: tip_scope
Q: Your boss wants a 3-month project done by Friday. It's Wednesday.
+ good | Offer a smaller version and flag risks. | A smaller plan and the risks, in writing. Someone's been burned before.
~ neutral | Say yes and hope. | Hope is not a plan. We know. We tried it last quarter.
- bad | Put up a 'Coming Soon' sign. | ...That's literally our five-year plan.
* graduate | good | My course says: do less, warn early. | Textbook. Literally. But right.
```

```
eq_harsh_review | teamwork: yes | tiers: all | tip: tip_take_feedback
Q: A senior coworker checks your work and leaves one comment: 'this is garbage'.
+ good | Ask what to fix; discuss tone privately. | Mature. And yes, raise it. 'Garbage' isn't feedback.
~ neutral | Fix it silently and seethe. | Fixed code, unfixed feelings. Half marks.
- bad | Reply: 'I know you are, but what am I?' | A playground classic. Not a career move.
* self_taught | neutral | So far, only an AI app reviews my work. | Honest. Help out on free, public coding projects: real humans review your work there.
```

```
eq_weakness | teamwork: no | tiers: all | tip: tip_star_stories
Q: What's your greatest weakness?
+ good | I overdo details, so I set time limits. | A real answer! I'm writing that down in pen.
~ neutral | I'm a perfectionist who works too hard. | That's the 3,000th time I've heard that. Second today.
- bad | Garlic. And sunlight. | ...Okay. We do have a night shift.
```

```
eq_grind_culture | teamwork: no | tiers: startup | tip: tip_rest
Q: We work 80-hour weeks here. Grind culture. You in?
+ good | Committed, but at a sustainable pace. | Most people just say yes. You didn't. That's... reassuring, actually.
~ neutral | Is the pay 80 hours' worth too? | Great question. Next question.
- bad | I'll sleep under my desk. | Love the energy. Our insurance does not.
```

```
eq_rto | teamwork: no | tiers: big | tip: tip_total_comp
Q: Five days in the office, starting Monday. Thoughts?
+ good | I'd ask why, then plan around it. | A mature answer. I'm almost suspicious.
~ neutral | Is it negotiable? | Everything is negotiable. Except this.
- bad | Swipe in, grab a free coffee, go home. | Ah, 'coffee badging'. It's so common it has a name. Our door scanners keep score.
```

```
eq_any_questions | teamwork: no | tiers: all | tip: tip_ask_questions
Q: Do you have any questions for us?
+ good | What does success look like in 90 days? | Oh, a good question. Let me actually think.
~ neutral | How soon can I take vacation? | Day 91. After probation. Noted.
- bad | No, I'm good. | Not having questions is also an answer.
```

Pool sizes per tier (no repeats within a run, 2 per interview): Big 12, Mid 11, Startup 11. Teamwork-tagged: 4 of 13.

---

## 8. Dana, the VS announcer and the Answer Meter -> `data/content/barks.json`

### 8.1 Dana: titles and greetings

| id | Text |
|---|---|
| `dana_title_startup` | Head of People & Vibes & Snacks |
| `dana_title_mid` | Recruiter (also Office Manager) |
| `dana_title_big` | Senior Talent Acquisition Partner II |
| `bark_dana_greet_startup` | Hi! Grab a beanbag. The founder's on a podcast, so it's you and me. |
| `bark_dana_greet_mid` | Welcome! Coffee? It's bad. Let's begin. |
| `bark_dana_greet_big` | Welcome to {company}. You have 45 minutes. I have 11 more of these today. |
| `bark_dana_greet_again` | Didn't I interview you at {last_company}? ...Yeah. Laid off. Rehired. Hi. |
| `bark_dana_tired` | You look like you took two buses. Water? ...Okay, let's start. |

Background-specific openers are in section 3 (`dana_opener`); company one-liners in section 4 (`dana_line`, SHOULD). Order in an interview: greeting (or `greet_again`), then the background opener on the first interview of a run, then the company line.

### 8.2 Dana: reactions and outcomes

| id | Text |
|---|---|
| `bark_dana_great_1` | That's a good answer. I've heard maybe three today. |
| `bark_dana_great_2` | Crisp. I'm writing 'strong' in pen. |
| `bark_dana_great_3` | Nice. You'd be surprised how rare that is. |
| `bark_dana_ok_1` | Mm-hm. That'll do. |
| `bark_dana_ok_2` | Logged as 'meets expectations (adjacent)'. |
| `bark_dana_ok_3` | Okay. Some 'um's, but okay. |
| `bark_dana_bad_1` | I'll write 'did not demonstrate'. Neutrally. Very neutrally. |
| `bark_dana_bad_2` | Hm. Confident. Not correct, but confident. |
| `bark_dana_bad_3` | Let's... move on. |
| `bark_dana_pivot` | Quick update: we pivoted. Keep going. |
| `bark_dana_ko` | That's a yes from me. Don't tell the committee I said that. |
| `bark_dana_committee` | It's close. The Hiring Committee decides. It's three people and a spreadsheet. |
| `bark_dana_committee_win` | The spreadsheet likes you. Congratulations. |
| `bark_dana_committee_lose` | The spreadsheet said no. I argued. The spreadsheet won. |
| `bark_dana_reject` | Off the record, here's the feedback nobody gives you: |
| `bark_dana_other_candidates` | We've decided to move forward with other candidates. |
| `bark_dana_composure_zero` | Let's stop here. Get some rest. Seriously. Apply again. |
| `bark_dana_decline` | No worries! (Our ATS will remember this.) |

Dana's four lie-probe lines (the probe intro, Come clean, a won bluff, BUSTED) were removed with lying on 2026-09-29 (DECISIONS D9). Her two negotiation lines, `bark_dana_nego_win` and `bark_dana_nego_lose`, were removed with Negotiate (2026-10-07, D-27) and left `barks.json` in the code cleanup of 2026-10-08.

### 8.3 VS screen and announcer

| id | Text |
|---|---|
| `vs_title` | {player_name} VS DANA |
| `vs_banner_startup` | ROUND 1: VIBE CHECK |
| `vs_banner_mid` | ROUND 1: CULTURE FIT |
| `vs_banner_big` | ROUND 1 OF 7 |
| `vs_start` | INTERVIEW! |
| `vs_ko` | K.O.! |
| `vs_offer` | OFFER! |
| `vs_committee` | TIME OVER! THE COMMITTEE DECIDES... |
| `vs_reject` | ...WE'LL KEEP YOUR CV ON FILE. |
| `vs_perfect` | PERFECT! (Reply in 3-5 business weeks) |
| `vs_warmup` | WARM-UP - DOESN'T COUNT |
| `vs_pivot` | PIVOT! |
| `vs_dana_stat_1` | Candidates today: 11 |
| `vs_dana_stat_2` | Coffee: 4th cup |
| `vs_dana_stat_3` | Patience: [###--] |
| `vs_dana_move_1` | Special move: The Five-Year Plan |
| `vs_dana_move_2` | Special move: The Salary Expectation Trap |
| `vs_dana_move_3` | Special move: The Awkward Silence |
| `vs_versus` | VS |

Since 2026-09-29 (DECISIONS D12) Dana's VS plate shows one joke stat and one special move, taking turns by how often you've met her this run: the first interview shows `vs_dana_stat_1` and `vs_dana_move_1`, the second the `_2` pair, the third the `_3` pair, then it starts over (GDD S07). The one-line `vs_dana_move_1..3` replace the old three-move line. The held last frame shows `ui_tap_to_continue` (section 10.1).

Banners at Press Start 2P 16 fit 15 characters a line, up to 3 lines (GDD 2.7). The portrait VS screen shows the two names on separate plates, so `vs_title` appears only where one line fits; there, use size 8.

### 8.4 Answer Meter labels

| id | Text |
|---|---|
| `meter_left` | Rambling |
| `meter_near` | Vague |
| `meter_zone` | NAILED IT |
| `meter_right` | Overthinking |
| `meter_hint` | Tap anywhere! |
| `meter_perfect` | PERFECT |
| `meter_good` | GOOD |
| `meter_close` | CLOSE |
| `meter_miss` | ...uhh |
| `ducky_real_answer` | Real answer: |

---

## 9. Knowledge questions -> `data/content/questions_knowledge.json`
Header: `id | topic | kind (tech | behavioral) | difficulty (1-3) | weak_for (background id or none) | tiers | tip`. Then `Q` (<=100), the three spoken answers `green` / `yellow` / `red` (<=80 each; your character says one depending on Q, GDD 5.8.4) and `ducky` (<=120, shown after a red answer and in the Notebook).

Totals: 22 questions (18 tech, 4 behavioral). Difficulty 1: 8, 2: 10, 3: 4. weak_for: intern 5, graduate 6, self_taught 7, none 4. Eligible per tier: Big 21, Mid 22, Startup 19.

```
kq_binary_search | algorithms | tech | 1 | intern | all | tip_think_aloud
Q: Binary search on a sorted array of n items. What's the time complexity?
green: O(log n). Each step halves the range.
yellow: Log-something? It halves stuff... O(log n), I think.
red: O(n). It checks every item, just faster.
ducky: O(log n). Each comparison halves what's left to search.
```

```
kq_nested_loops | algorithms | tech | 1 | self_taught | all | tip_think_aloud
Q: A loop over n items inside another loop over n items. Complexity?
green: O(n squared): n times n steps.
yellow: Quadratic-ish? n times n... O(n^2)?
red: O(2n). Two loops, so two n.
ducky: O(n^2). Nested loops multiply; loops one after another add.
```

```
kq_hash_map | data_structures | tech | 1 | self_taught | all | tip_fundamentals
Q: What's the average time to look up a key in a hash map?
green: O(1) on average; O(n) worst case with lots of collisions.
yellow: Fast? Constant... unless collisions. Probably O(1).
red: O(log n), because hash maps keep their keys sorted.
ducky: O(1) on average. Hash maps aren't sorted; heavy collisions can make it O(n).
```

```
kq_two_sum | algorithms | tech | 3 | intern | big, mid | tip_think_aloud
Q: Does any pair in an array add up to a target? What's the fast approach?
green: One pass with a hash set: check if target minus x was seen.
yellow: Maybe a set? Store what I've seen, then... check it?
red: Two nested loops. Brute force is honest work.
ducky: One pass plus a hash set is O(n). Nested loops work too, but they're O(n^2).
```

```
kq_recursion_base | algorithms | tech | 1 | intern | all | tip_think_aloud
Q: A recursive function has no base case. What happens?
green: It never stops calling itself: stack overflow.
yellow: It loops forever? Something overflows. The stack?
red: It returns zero. The compiler adds a base case.
ducky: It recurses until the call stack overflows. Write the base case first.
```

```
kq_left_join | databases | tech | 2 | self_taught | all | tip_fundamentals
Q: Users LEFT JOIN Orders. What do you get back?
green: Every user, plus their orders; no orders means NULLs.
yellow: All the users? And some orders? With blanks, maybe.
red: Only the users who have orders.
ducky: All left rows are kept; missing right-side values are NULL. INNER JOIN drops them.
```

```
kq_index_tradeoff | databases | tech | 2 | graduate | all | tip_fundamentals
Q: What's the main trade-off of adding a database index?
green: Faster reads, but more storage and slower writes.
yellow: Faster queries... and it costs something. Space?
red: No trade-off. Index every column.
ducky: Indexes speed up lookups but use storage and slow down inserts and updates.
```

```
kq_http_403 | web | tech | 2 | graduate | all | tip_think_aloud
Q: You're logged in, but the admin page refuses you. Best HTTP status code?
green: 403 Forbidden: we know who you are; you're not allowed.
yellow: Four-oh-something. 403? Or 401. Probably 403.
red: 500. The server is clearly upset with me.
ducky: 403: logged in, not allowed. 401: not logged in. Some sites send 404 to hide that a page exists.
```

```
kq_idempotent | web | tech | 2 | self_taught | all | tip_fundamentals
Q: Name an idempotent HTTP method: sending it 5 times has the same effect as once.
green: PUT. Same request, same final state.
yellow: Not POST... GET-ish? PUT, I think.
red: POST. It posts the same thing every time.
ducky: PUT (also GET and DELETE). POST usually creates something new on each call.
```

```
kq_rebase_merge | tools | tech | 2 | graduate | all | tip_think_aloud
Q: Git: what's the difference between merge and rebase?
green: Merge adds a merge commit; rebase replays my commits on top.
yellow: Rebase is... cleaner? It moves the commits somewhere.
red: Rebase deletes the other branch. Merge is the free version.
ducky: Rebase rewrites your commits onto a new base. Never rebase commits others already pulled.
```

```
kq_testing_pyramid | tools | tech | 1 | graduate | all | tip_fundamentals
Q: In the testing pyramid, which tests should you have the most of?
green: Unit tests: fast and cheap. Fewest end-to-end tests.
yellow: The small ones? Unit tests. Mostly.
red: End-to-end UI tests. Click everything, every time.
ducky: Many unit tests, fewer integration tests, fewest slow end-to-end tests.
```

```
kq_race_condition | concurrency | tech | 2 | self_taught | all | tip_think_aloud
Q: Two threads each add 1 to a counter 1,000 times. The result is 1,734. Why?
green: A race: read-modify-write isn't atomic. Use a lock.
yellow: The threads fight? Something about locks, maybe.
red: Integer overflow. The CPU got tired.
ducky: Unsynchronized updates overwrite each other. Use a lock or an atomic counter.
```

```
kq_deadlock | concurrency | tech | 3 | intern | big, mid | tip_think_aloud
Q: Thread A holds lock 1 and wants lock 2. Thread B holds 2 and wants 1. What is this?
green: A deadlock. Fix it by always taking locks in the same order.
yellow: They're stuck? A... deadlock. Yes. Deadlock.
red: A memory leak. Restart and pray.
ducky: A deadlock. A consistent lock order, or timeouts, prevents it.
```

```
kq_cache_first_fix | system_design | tech | 3 | graduate | all | tip_think_aloud
Q: The same rarely-changing data is read 10,000 times a second. The DB is struggling. First fix?
green: Put a cache with an expiry time in front of the database.
yellow: Cache it? In memory, somewhere? Yes. Cache.
red: Rewrite the app in a trendier language.
ducky: Cache hot, rarely-changing reads with a time-to-live. Measure first, then optimize.
```

```
kq_load_balancer | system_design | tech | 1 | none | all | tip_fundamentals
Q: What does a load balancer do?
green: Spreads requests across servers and skips unhealthy ones.
yellow: Balances... load. Across the servers. Evenly?
red: Decides who gets laid off.
ducky: It distributes traffic across servers and routes around the unhealthy ones.
```

```
kq_url_shortener | system_design | tech | 3 | self_taught | big, mid | tip_clarify_first
Q: Design a URL shortener. What happens when someone opens a short link?
green: Look up the code in a fast key-value store, then redirect.
yellow: Find the long URL... and send them there? A redirect?
red: Generate a brand-new short link every time.
ducky: A cached key-value lookup, then an HTTP 301 or 302 redirect. Ask about scale first!
```

```
kq_sql_injection | security | tech | 2 | none | all | tip_fundamentals
Q: What's the best defense against SQL injection?
green: Parameterized queries. Never glue user input into SQL.
yellow: Sanitize... stuff? Escape the quotes, I guess.
red: Check the input in the browser. Done.
ducky: Parameterized queries (prepared statements). Browser-side checks are easy to bypass.
```

```
kq_password_storage | security | tech | 2 | intern | all | tip_fundamentals
Q: How should an app store user passwords?
green: A salted hash with a slow algorithm made for passwords.
yellow: Encrypted? Hashed? Hashed. With salt, I think.
red: Base64. It looks secure.
ducky: Slow, salted password hashing. If a site can email you your password, it's stored wrong.
```

```
kq_star_conflict | behavioral | behavioral | 1 | self_taught | all | tip_star_stories
Q: Tell me about a time you disagreed with a teammate.
green: We tested both ideas, the data picked one, and I learned why.
yellow: Um, once? We disagreed. Then we... agreed?
red: I don't disagree. I'm always right.
ducky: Use STAR: Situation, Task, Action, Result. No team yet? Use open source or clients.
```

```
kq_failure_story | behavioral | behavioral | 2 | graduate | all | tip_star_stories
Q: Tell me about a project that failed.
green: It shipped late. I learned to cut scope early. Here's how.
yellow: Everything worked out in the end, honestly. Mostly.
red: Nothing I build fails. Some of it just never runs.
ducky: Pick a real failure, own your part, and show what you changed afterwards.
```

```
kq_learn_fast | behavioral | behavioral | 1 | none | startup, mid | tip_fundamentals
Q: How do you learn a new technology quickly?
green: Build a tiny project, read the docs, ask for a review.
yellow: Videos? Lots of videos. At 2x speed.
red: I ask Guessomatic and paste whatever it says.
ducky: A small project, the official docs, and feedback. Explain it back to check you get it.
```

```
kq_estimate | behavioral | behavioral | 2 | none | all | tip_scope
Q: Your task will take twice as long as planned. What do you do?
green: Tell my lead early, with options to cut scope or move dates.
yellow: Tell my lead? Soon-ish? Maybe cut... something?
red: Say it's 90% done. For three weeks.
ducky: Flag slips early and bring options. Surprises are worse than bad news.
```

On screen, `ducky` lines are prefixed with `ducky_real_answer` ("Real answer:").

---

## 10. UI strings and Ducky coach lines -> `data/content/barks.json` (flat ids `ui_*`, `coach_*`)

### 10.1 UI strings

| id | Text |
|---|---|
| `ui_logo_1` | SOFTWARE |
| `ui_logo_2` | ENGINEER |
| `ui_logo_3` | SIMULATOR |
| `ui_tap_to_start` | Tap to start |
| `ui_tap_to_continue` | Tap to continue |
| `ui_continue` | Continue |
| `ui_new_game` | New game |
| `ui_replay_intro` | Replay intro |
| `ui_skip_hold` | Hold to skip |
| `ui_background_header` | How did you spend those four years? |
| `ui_choose` | CHOOSE |
| `ui_day` | Day {day} |
| `ui_energy` | Energy |
| `ui_rent_due` | Rent due in {days} days |
| `ui_rent_due_one` | Rent due TOMORROW |
| `ui_rent_due_today` | Rent due today |
| `ui_radar` | Recruiter Radar |
| `ui_apply` | APPLY |
| `ui_skip` | SKIP |
| `ui_tailor` | TAILOR & APPLY |
| `ui_research` | RESEARCH |
| `ui_use_referral` | Use referral ({n} left) |
| `ui_back` | Back |
| `ui_sleep` | Sleep |
| `ui_tab_jobs` | Jobs |
| `ui_tab_mail` | Mail |
| `ui_tab_study` | Study |
| `ui_tab_network` (SHOULD) | Coffee |
| `ui_invite_waiting` | Invite waiting |
| `ui_sleep_confirm` | You still have {n} energy. Sleep anyway? |
| `ui_night_summary` | Applied {n} - Rejected {r} - Ghosted {g} |
| `ui_morning` | Morning, day {day}. |
| `ui_go_now` | GO NOW |
| `ui_later` | Later |
| `ui_flip_all` | Flip all |
| `ui_rejections` | {n} rejections |
| `ui_ghost_footer` | {n} applications: no reply. Probably ever. |
| `ui_ghost_footer_one` | 1 application: no reply. Probably ever. |
| `ui_start_day` | Start day |
| `ui_accept` | ACCEPT |
| `ui_decline` | Decline |
| `ui_decline_confirm` | Decline this offer? Rent keeps ticking. |
| `ui_decline_confirm_grace` | Decline this offer? Rent is due today, so this ends the run. |
| `ui_ready` | Ready? Tap to continue. |
| `ui_quit_confirm` | Quit the game? |
| `ui_quit` | Quit |
| `ui_pause_resume` | Resume |
| `ui_pause_title` | Quit to title |
| `ui_retry` | Retry |
| `ui_new_run` | New run |
| `ui_title` | Title |
| `ui_odds_1` | Long shot |
| `ui_odds_2` | Unlikely |
| `ui_odds_3` | Possible |
| `ui_odds_4` | Decent |
| `ui_odds_5` | Good |
| `ui_tired` | TIRED: needle is faster |
| `ui_study_title` | BigOhNo: Knowledge +5 (2 energy) |
| `ui_study_joke_1` | Invert a binary tree. You will never do this at work. |
| `ui_study_joke_2` | Day 400 of your streak. The streak is the job now. |
| `ui_study_joke_3` | Solved: Two Sum. Unsolved: rent. |
| `ui_grace_day` | Your landlord gave you one more day. ONE. |
| `ui_rent_warning` | Rent is due soon. Ramen budget activated. |
| `ui_composure` | COMPOSURE |
| `ui_doubt` | DOUBT |
| `ui_round` | ROUND {n}/{total} |
| `ui_back_to_hunt` | Back to the hunt |
| `ui_stat_knw` | KNOWLEDGE |
| `ui_stat_exp` | EXPERIENCE |
| `ui_stat_net` | NETWORK |
| `ui_energy_per_day` | Energy/day |
| `ui_rent_runway` | Rent runway: {days} days |
| `ui_name` | NAME |
| `ui_radar_short` | Radar |
| `ui_odds_quick` | Quick apply |
| `ui_odds_tailored` | Tailored |
| `ui_deck_empty` | {n} new cards per morning. |
| `ui_invite_line` | Interview with {company}: today or tomorrow |

The hub's bottom dock (GDD 4.2 S04) uses `ui_tab_*` plus `ui_sleep`; dock labels are at most 6 characters. `ui_quit_confirm` appears on Android (LATER) and desktop only: iOS apps never quit themselves (GDD 4.4); `ui_quit` is its confirm button (added 2026-09-27 with no source text). `ui_logo_1`-`ui_logo_3` are the title logo's three lines (GDD S01). Added 2026-09-27 for the Step 4 interview, with text from the GDD mockups: `ui_composure`, `ui_doubt` and `ui_round` are the S08 bars band ("ROUND 2/5"; `{total}` is the number of prompts), `ui_back_to_hunt` and `bark_dana_other_candidates` are S09 (and GDD 5.8.6), `ui_stat_*` are the S03 stat bar labels (also on the S07 VS plate), and `vs_versus` is the S07 "VS" (ARCHITECTURE 11.5). Added 2026-09-27 for the Step 5 Background select, with text from the GDD S03 mockup: `ui_energy_per_day` (the card's energy pips row), `ui_rent_runway` and `ui_name` (the name row). Added 2026-09-27 for the Step 5 hub (DoomApply, part 1), with text from the GDD: `ui_radar_short` is the S04 HUD's "Radar [###---]" (the long `ui_radar` doesn't fit the HUD row), `ui_odds_quick` the card front's "Quick apply [##---] Unlikely" (S04 mockup), `ui_odds_tailored` the card back's tailored odds label (GDD 5.6 "Tailored"), and `ui_deck_empty` the empty-deck line (S04 "6 new cards per morning"; `{n}` is `board_new_per_day`). Added 2026-09-27 for the Step 5 hub (part 2), with text from the GDD: `ui_invite_line` is the invite card's line (S06 "Interview with {company}: today or tomorrow"). Removed 2026-09-29 with the CV screen (D9): `ui_done` (its DONE button) and `ui_yes` / `ui_no` (its `{yes_no}` chips), along with the `{yes_no}` placeholder. Added 2026-09-27 for the Step 6 offer, with no source text: `ui_decline_confirm_grace` replaces `ui_decline_confirm` on the grace day, when Decline ends the run (GDD 5.10), because "Rent keeps ticking" would be false there. Added 2026-09-27 for the Step 6 Hired card, with no source text: `ui_tap_to_continue` is the hint under beat 1 (GDD S11 "Tap anywhere to continue"); since 2026-09-29 the VS intro's held last frame shows it too (GDD S07, D12). Added 2026-09-27 for the Step 6 endings, a grammatical variant of `ui_rent_due`: `ui_rent_due_today` replaces "Rent due in 0 days" in the HUD and the night summary on the grace day and the Plan B morning. Added 2026-09-27 for Step 6, a grammatical variant of `ui_ghost_footer`: `ui_ghost_footer_one` replaces "1 applications: no reply" in Mail's footer.

**Approved (DECISIONS C2, 2026-09-29):** the developer approved all the copy the review queue listed ("go with it"): every line above that was added with no source text, the grammatical variants and the labels copied from the GDD mockups. The CV screen's labels (the CV dock tab, the degree and "1+ yrs" chips, Lie risk, Honest / Polished / Lie, and the row labels), and the Come clean and Bluff buttons, were removed with it (D9).

**Removed 2026-10-07 (DECISIONS D-27):** `ui_negotiate`, because Negotiate was removed. It left `barks.json` in the code cleanup of 2026-10-08.

A primary button shows its label in capitals (`UiText.primary()` upper-cases it, as the GDD 4.2 mockups do: `[ CONTINUE ]`, `[ NEW RUN ]`), and a Back-style button puts "< " in front (`UiText.back()`). Write the text here in its normal case. (Agent default, please review.)

### 10.2 Ducky coach lines (first run, GDD 4.3)

| id | Text |
|---|---|
| `coach_apply` | Swipe right or tap APPLY to send your CV. Costs 1 energy. |
| `coach_flip` | Tap a card to flip it. Tailor & Apply sends a better CV. |
| `coach_sleep` | Out of energy? Tap the moon to sleep. Replies come in the morning. |
| `coach_invite` | An interview! Research the company first: it unlocks a secret answer. |
| `coach_invite_no_research` | An interview! Rest up: tired thumbs are slow thumbs. |
| `coach_meter` | Tap anywhere when the needle is in NAILED IT. A wider zone means you know this. |
| `coach_first_reject` | Rejections happen to everyone. Each one leaves a tip in your Notebook. |
| `coach_radar` | The Recruiter Radar fills with relevant applications. Full means a human reads one. |

A tap on a hunt coach note closes it for the rest of the run (GDD 4.3, DECISIONS D11); doing the action still closes it too. The "x" in the note's corner that shows this is a plain placeholder, not a content string, until the art pass. Mail's invite mark is closed as one mark (id `coach_invite`) whichever line it shows: `coach_invite_no_research` until Research ships (SHOULD), then `coach_invite`. `coach_meter` (the interview) can't be tapped closed. `coach_first_reject` and `coach_radar` aren't shown yet. The CV screen's coach line was removed with it (D9).

---

## 11. Career tips -> `data/content/tips.json`
Fields: `id, short (<=120, on screen), more (Notebook extra), triggers`. GDD 8.3 maps moments to tips. The developer signs off every tip before release.

| id | short | more | triggers |
|---|---|---|---|
| `tip_ats_knockouts` | ATS software rarely auto-rejects on keywords. Knockout questions (degree, years, location) do. | Answer knockout questions truthfully and apply where you meet them, or get a referral so a human reads your CV. | knockout rejection |
| `tip_keywords_honest` | Use the posting's real terms for skills you actually have. Recruiters search for them. | Don't paste the whole posting into your CV; mirror the terms that honestly describe your work. | none in the MVP (was the CV screen) |
| `tip_quantify_impact` | Use numbers: 'raised test coverage from 41% to 58%' beats 'worked on testing'. | Action verb + what you did + a measurable result. Put your strongest line first. | night after a Tailor & Apply |
| `tip_projects_count` | Projects, TA work and freelance count as experience. Describe them honestly and concretely. | Say what you built, for whom, and what happened. 'Capstone team of 4, shipped' is honest and strong. | night after a Tailor & Apply, when the honest CV fails 1+ years |
| `tip_tailor_over_spray` | A tailored application to a job you really fit is much more likely to get a reply than a one-click one. | Tailor your summary and top bullets to each posting you really match. | 8 Quick Applies without an invite |
| `tip_referrals` | A referral gets a human to read your CV. Ask people who actually know your work. | Make it easy for them: send a two-line blurb and the job link. | first referral |
| `tip_informational_chats` | Network with curiosity: ask engineers for 15 minutes of advice, not for a job. | Referrals often follow real conversations. It works best before you need it. | Network (SHOULD) |
| `tip_ghost_jobs` | Postings open for months or reposted constantly may not be hiring. Prefer fresh ones. | Check the company's own careers page and the posting date before investing effort. | Research reveals a ghost job |
| `tip_research_company` | Research the company before interviews: news, product, reviews. It improves every answer. | It also helps you judge them: layoffs, funding and reviews tell you what you're walking into. | committee loss, rejection without research, `eq_why_us` |
| `tip_rejection_numbers` | In a tight market, many rejections are normal. Track applications and keep going. | A simple spreadsheet (date, role, contact, stage) shows what's working. It's volume plus targeting. | first rejection, every 10th |
| `tip_rest` | Rest before interviews. Tired answers go worse. Schedule the search like a job. | A job search is a marathon. Plan breaks on purpose. | Tired, `eq_grind_culture` |
| `tip_think_aloud` | In technical interviews, think out loud. Interviewers grade your reasoning, not just the answer. | If you're stuck, say what you'd try first and why. | red knowledge answer |
| `tip_clarify_first` | Ask clarifying questions before designing: users, scale, constraints. | Jumping straight to a solution is a common junior mistake. Interviewers like the questions. | `kq_url_shortener` |
| `tip_star_stories` | Prepare 5 stories: conflict, failure, teamwork, a win, learning fast. Tell each as situation, task, action, result. | End each one with what you learned. The same stories answer many questions. | red behavioral answer, `eq_weakness` |
| `tip_teamwork_without_job` | No team yet? Public coding projects, team coding events and freelance clients give you feedback and team stories. | Feedback on your code from strangers is a fast way to learn how teams work. | none in the MVP (`eq_harsh_review` uses `tip_take_feedback`; the Self-Taught's own answer there carries this lesson) |
| `tip_take_feedback` | Rude feedback can still hold a real fix. Ask what to change, then raise the tone privately and calmly. | Separate the message from the delivery. Fix the work first, then talk about the tone one-on-one. | `eq_harsh_review` |
| `tip_ask_questions` | Always ask a question at the end: what success looks like in 90 days, how the team works, real hours. | It shows interest, and the answers tell you whether you want the job. | `eq_any_questions` |
| `tip_fundamentals` | Frameworks change fast. Fundamentals transfer: data structures, databases, networking, testing. | Learn one stack well, but keep the basics sharp. They show up in every interview. | first Study, several knowledge Qs |
| `tip_ai_tools` | Use AI tools where allowed, but understand and test every line. You'll be asked to explain it. | Say what you used and how you checked it. | `eq_ai_takehome` |
| `tip_secrets` | A leaked password is no longer secret. Report it so it gets changed; deleting the message isn't enough. | Never paste passwords into chats, emails or code. | `eq_leaked_password` |
| `tip_small_changes` | Release small, tested updates early in the week, so problems get fixed before the weekend. | Small updates are easier to check and easier to undo. | `eq_friday_deploy` |
| `tip_give_credit` | Credit teammates publicly. It builds trust, and people remember who shares. | It also makes your own wins more believable. | `eq_credit_theft` |
| `tip_blameless` | Good teams review mistakes without blame: what happened, how it was fixed, and what stops a repeat. | Owning your part calmly is a strength, not a confession. | `eq_outage_blame` |
| `tip_privacy` | Customer data is off-limits without a business reason. Access is logged. | Snooping is a fast way to lose a job and to hurt real people. | `eq_celebrity_orders` |
| `tip_focus_time` | Protect focus time: decline meetings you aren't needed in and ask for notes. | Say what you're working on and when you'll be free. | `eq_meeting_overload` |
| `tip_scope` | When a deadline is impossible, offer a smaller first version and write down the risks. | Flag slips early. Surprises are worse than bad news. | `eq_impossible_deadline`, `kq_estimate` |
| `tip_total_comp` | Compare total pay: salary, bonus, equity, benefits and commute. 3 hours a day on a bus is a pay cut. | Ask about office days, on-call and real working hours too. Tight deadline? Asking for a few more days is normal. | offer with a commute, `eq_rto` |
| `tip_equity_lottery` | Treat startup equity like a lottery ticket. Ask the percentage and the vesting schedule. | A 1-year cliff means you get nothing if you leave or are laid off before 12 months. Also ask the strike price and how long you'd have to buy vested options after leaving. | startup offer |
| `tip_fine_print` | Read non-compete, IP and probation clauses. Enforceability varies by country and state. Unsure? Ask a lawyer. | Ask HR what a clause covers and get the answer in writing before you sign. Whether it's enforceable is a question for an employment lawyer or legal aid. | fine print opened |
| `tip_written_offer` | Don't stop other applications until you have a signed, written offer. | Check that it lists the start date, pay and work mode. | Hired card |

Changed 2026-09-29: the tips for the plain-language choice questions (`tip_small_changes`, `tip_blameless`, `tip_secrets`, `tip_teamwork_without_job`, `tip_star_stories`, `tip_ask_questions`) lost their jargon (DECISIONS C3); tip accuracy is still yours to sign off. The two lying tips ("I don't know" beats a bluff; don't lie on a CV) were removed with lying (D9). `tip_keywords_honest` has no trigger in the MVP (it was the CV screen's), and `tip_quantify_impact` and `tip_projects_count` now come the night after a Tailor & Apply (GDD 8.3). Changed again in the review fix pass (DECISIONS A49, A50; please check their accuracy): `tip_star_stories` names the 5 topics before the structure; `tip_small_changes` lost the "how weekends die" hyperbole (GDD 1.3: the joke belongs to Dana's reaction); `tip_teamwork_without_job` says "team coding events", because most coding contests are solo; and `tip_take_feedback` is new: `eq_harsh_review`'s bad answer used to show `tip_teamwork_without_job`, which didn't match the cause (GDD 8.1 rule 4), so that tip has no trigger in the MVP now. Removed 2026-10-07: `tip_negotiate`, because Negotiate was removed (DECISIONS D-27); it left `tips.json` in the code cleanup of 2026-10-08.

---

## 12. Emails and notifications -> `data/content/emails.json`

### 12.1 Invites (morning inbox; valid today and tomorrow)

| id | subject | body |
|---|---|---|
| `mail_invite_startup` | yo | yo {player_name} loved ur profile. can u do a video call today or tmrw?? - {company} (founder is busy, this is Dana) |
| `mail_invite_mid` | Interview: {job_title} | Hi {player_name}! We'd love to chat. One conversation with Dana from People, today or tomorrow. A real human. We know. Rare. |
| `mail_invite_big` | Next steps: Stage 1 of 7 | Congratulations! You've reached Stage 1 of 7 for {job_title}. Please attend an in-person interview today or tomorrow. Parking is not validated. |
| `mail_invite_radar` | A human actually read it! | Hi {player_name}, a recruiter at {company} read your CV. On purpose. Interview today or tomorrow? |
| `mail_invite_guarantee` | Saw your profile! | Hi {player_name}! {company} saw your application. Fast. Suspiciously fast. Interview today or tomorrow? |
| `mail_invite_grace` | Landlord | Your landlord gave you one more day. ONE. Make this interview count. |
| `mail_invite_expired` | Update | The role was filled internally. It always was. |

### 12.2 Knockout auto-rejection (next morning, any tier)

| id | subject | body |
|---|---|---|
| `mail_knockout` | Update on your application | Hi {player_name}, after careful consideration (0.4 seconds, at 3:07 AM), we won't be moving forward. Knockout: {knockout}. - Parsinator 3000 |

### 12.3 Rejections (one short line each in the "Flip all" stack)

| id | Line |
|---|---|
| `mail_reject_01` | After careful consideration, we've decided to move forward with other candidates. |
| `mail_reject_02` | Dear [FIRST_NAME], we regret to inform you about [JOB_TITLE]. Warmly, [RECRUITER]. |
| `mail_reject_03` | You're overqualified for this entry-level role and underqualified for its salary. |
| `mail_reject_04` | The role went to an internal candidate. It always was. We had to post it anyway. |
| `mail_reject_05` | We loved you! We chose someone equally lovable with 7 more years of experience. |
| `mail_reject_06` | Our AI screener made a decision. It declined to explain. It declined us too. |
| `mail_reject_07` | Due to shifting priorities, this role no longer exists. Neither does the team. |
| `mail_reject_08` | We'll keep your CV on file. The file is very large. It is also a shredder. |
| `mail_reject_09` | Thanks for applying! This is an automated message. So was the decision. |
| `mail_reject_10` | Great news: you made the top 3,000! Bad news: we're hiring one. |

### 12.4 Ghosting and notifications

| id | Text |
|---|---|
| `notif_ghosted` | Ghosted: {company} - {job_title} ({days} days, no reply) |
| `notif_profile_view` | HumbleBrag: a recruiter viewed your profile! See who with Premium Gold+. (It was a bot.) |
| `notif_typing` | The recruiter is typing... |
| `notif_typing_stop` | The recruiter stopped typing. |

The OFFER RESCINDED mail was removed with the background check (D9).

---

## 13. Offer letter, perks and fine print -> `data/content/emails.json` (flat ids `offer_*`, `perk_*`, `fp_*`)

### 13.1 Offer modal template

```
OFFER OF EMPLOYMENT - {company}
Dear {player_name},
We are thrilled (legally required wording) to offer you the role of {job_title}.
Salary:     {salary}/year
Work mode:  {work_mode}
Commute:    {commute_line}
Perks:      {perk_1}.
            {perk_2}.
Fine print: {fine_print}
Please decide before you sleep.
[ Decline ]  [          ACCEPT          ]
```

One field per line after a 12-character label column; values wrap at 28 columns, fine print up to 4 lines (GDD 4.2 S10). The template's `[ Negotiate ]` row was removed on 2026-10-07 with Negotiate (DECISIONS D-27).

The template's first line is `offer_title`; the salary value (without its "Salary:" label) is `offer_salary`, where `{salary}` is the whole-dollar amount with its "$" and thousands commas ("$71,000"). The Hired card reuses `offer_salary`. The other template lines got ids when Step 6 built the paper (2026-09-27): `offer_dear`, `offer_role`, the field labels `offer_label_*` and `offer_deadline`, copied from the template above. Two were new, and the developer approved them on 2026-09-29 (DECISIONS C2): `offer_label_equity` and `offer_equity`, the startup's joke equity (GDD 5.9.2 and 7: "$50-70k + 0.0001% equity") shown as its own field under the salary. `{hours}` is the weekly commute (`office_days` x 2 x `commute_min` / 60) with one decimal ("12.7").

| id | Text |
|---|---|
| `offer_title` | OFFER OF EMPLOYMENT - {company} |
| `offer_dear` | Dear {player_name}, |
| `offer_role` | We are thrilled (legally required wording) to offer you the role of {job_title}. |
| `offer_label_salary` | Salary: |
| `offer_salary` | {salary}/year |
| `offer_label_equity` | Equity: |
| `offer_equity` | 0.0001% |
| `offer_label_mode` | Work mode: |
| `offer_mode_startup` | Fully remote |
| `offer_mode_mid` | Hybrid: 2 office days a week |
| `offer_mode_big` | Office: 4 days a week |
| `offer_label_commute` | Commute: |
| `offer_commute_remote` | 0 minutes. The influencer was right about one thing. |
| `offer_commute_office` | {office_days} days x {commute_min} min each way = {hours} h a week |
| `offer_label_perks` | Perks: |
| `offer_label_fine_print` | Fine print: |
| `offer_deadline` | Please decide before you sleep. |

`offer_equity_doubled` and `offer_signon` were Negotiate's success lines; they were removed with Negotiate (2026-10-07, DECISIONS D-27) and left `emails.json` in the code cleanup of 2026-10-08.

### 13.2 Perks (2 shown per offer)

| id | tier | Text |
|---|---|---|
| `perk_pingpong` | startup | Ping-pong table |
| `perk_kombucha` | startup | Kombucha on tap |
| `perk_unlimited_pto` | startup | Unlimited PTO* (*average taken: 4 days) |
| `perk_pizza` | mid | Pizza Friday (Fridays subject to change) |
| `perk_banana` | mid | Free snacks (1 banana a week) |
| `perk_pto20` | mid | 20 days PTO |
| `perk_insurance` | big | Great insurance |
| `perk_rsu` | big | Stock units (1-year cliff) |
| `perk_pto15` | big | 15 days PTO |

### 13.3 Fine print (1 shown; 3 behind the magnifier, SHOULD)

| id | tiers | Text |
|---|---|---|
| `fp_probation` | mid, big | Probation: you may be let go for any reason, including 'Q3'. |
| `fp_rto` | big | Hybrid policy: work from home on any day that is not a weekday. |
| `fp_unlimited_pto` | startup | Unlimited PTO*. *Subject to approval, deadlines, and vibes. |
| `fp_non_compete` | big | Non-compete: for 24 months you won't work in, near, or think about software. |
| `fp_equity` | startup | Equity: 0.0001%, 4-year vest, 1-year cliff. Worth one sandwich at target valuation. |
| `fp_ip_clause` | big, startup | All ideas you have during employment, including dreams, belong to the Company. |
| `fp_on_call` | mid, startup | You will join the on-call rotation. The rotation is you. |
| `fp_perks` | mid | Pizza parties are provided in lieu of raises. |
| `fp_laptop` | big | Your laptop ships in 6-8 weeks. Please be productive meanwhile. |
| `fp_salary_review` | startup, mid, big | Salary is reviewed annually. Reviewing is not increasing. |
| `fp_runway` | startup | Your role is secure for the full runway (7 months, give or take a Tuesday). |
| `fp_family` | startup, big | The Company reserves the right to call itself 'a family'. |

The fine print never repeats a perk on the same paper: an `fp_<x>` is left out when `perk_<x>` was one of the 2 perks dealt (`RunState.fine_print_pool`, 2026-09-29). Today the only such pair is `perk_unlimited_pto` / `fp_unlimited_pto`, so a startup never lists "Unlimited PTO*" twice. A joke pairing on a different id, such as `perk_pizza` with `fp_perks`, is still allowed.

---

## 14. Endings -> `data/content/endings.json`

| id | Text |
|---|---|
| `end_hired_title` | HIRED! |
| `end_hired_startup` | Founding Engineer energy. Runway: 7 months. Chair: bring your own. |
| `end_hired_mid` | There's a sweater on your chair. The fax machine blinks at you. It knows. |
| `end_hired_big` | Your badge is printing. Your laptop ships in 6-8 weeks. Your first reorg is being planned. |
| `end_dream_header` | YOUR JOB vs REMY'S VIDEO |
| `end_dream_row_salary` | Salary (Remy: $150k) |
| `end_dream_row_remote` | Days at home (Remy: 5 of 5) |
| `end_dream_row_commute` | Commute (Remy: 3 steps) |
| `end_dream_row_flags` | Red flags (Remy: none) |
| `end_dream_row_rent` | Rent days to spare |
| `end_dream_grade_1` | All reality, no dream |
| `end_dream_grade_2` | Doable |
| `end_dream_grade_3` | Pretty good |
| `end_dream_grade_4` | Suspiciously close to the video |
| `end_dream_footer` | 100 is the life in Remy's video. Nobody gets 100. Not even Remy. |
| `end_tbc` | TO BE CONTINUED - Phase 2: The Working Life |
| `end_plan_b_title` | PLAN B |
| `end_plan_b` | Rent's due. You became a ClikClok career coach. Your course 'How I Almost Got Into Tech' has 40,000 students. |
| `end_plan_b_final` | Somewhere, a 17-year-old is watching your video. At night. Under a blanket. |
| `end_decline` | You declined. Bold. The market respects confidence. The market does not care. |
| `end_stats` | Days: {day} - Applications: {n} - Interviews: {i} - Rejections: {r} |
| `end_remy_dm` (SHOULD) | @RemoteRemy liked your post 'I got a job!' New DM: 'Guest spot in my course? Pay: exposure.' |

Background lines for Plan B are in section 3 (`plan_b_line`). The Stealth Mode Hired card adds its `hired_extra` from section 4.

Changed 2026-09-29 (DECISIONS C4): the Dream vs Reality header, row labels, lowest grade and footer. The four rows from Remy's video now name his number (the rent row has none: the video never mentions rent), each row shows its points out of the row's maximum ("18.9/40", DECISIONS A48), and the footer explains the 100 (the old one, "The video scored 100. The video was sponsored.", was neither clear nor funny to the developer). The rescinded-offer ending line was removed with the background check (D9).

**Run Spec v1 status:** the Plan B card stays as the career run's runway loss (D-19); `end_plan_b`'s "Rent's due." is Settled (MC-20, D-34): reword at M3, and `end_stats` counts the hunt (the career run's stats line is a draft in 16.5). The Hired card is no longer an ending (D-24): `end_hired_*`, the Dream rows and `end_tbc` follow MC-08 and MC-09 (settled, D-34): the HIRED! stamp stays as a short beat, the Dream rows are rebased, and `end_tbc` goes. The four new endings are drafts in 16.5.

---

## 15. Events, news and myths (SHOULD) -> `data/content/events.json`, `news.json`

**Run Spec v1 status:** the career run's events (16.3, GDD 5.19) replace these morning cards (RC-16); what happens to them in Phase 1 is settled (MC-01, D-33): they are parked. The Unicorn (`evt_unicorn`) has no place on the career run's board (MC-07, D-34). The news ticker (15.2) stays.

### 15.1 Morning event cards (one per morning, 50% chance, never on day 1)

| id | Text | Effect |
|---|---|---|
| `evt_layoff_news` | Layoffs: Round 14. Everyone you know is applying today. | invite odds x0.8 today |
| `evt_hiring_spree` | Hierarchai raised $40M to pivot. Startups are hiring! | startup invite odds x1.3 today |
| `evt_recruiter_spam` | Recruiter: 'Senior Principal COBOL Architect. 3-month contract. Relocate to the Moon.' | none |
| `evt_remy_course` | @RemoteRemy: 'Hired in 30 days or your money back!*' (*money back not available) | none; Ducky: "Reality: fundamentals, projects and consistency. No 30-day shortcut." |
| `evt_mom_call` | Mom asks if you've tried 'just applying online'. Emotional support: +1 energy. | +1 pip today |
| `evt_streak_lost` | BigOhNo: you lost your 400-day streak. Pity discount: Study costs 1 today. | Study costs 1 today |
| `evt_unicorn` | A posting appears: Junior, fully remote, $180k. 9,000 applicants in an hour. | adds `job_unicorn_remote` (once per run) |

### 15.2 News ticker (title screen, intro panel 6)

| id | Headline |
|---|---|
| `news_01` | OmniGlobal posts record profits, announces 'strategic headcount rightsizing' |
| `news_02` | Murkcloud AI now writes 40% of Murkcloud code, says Murkcloud AI |
| `news_03` | Engagement Farms Inc. orders 5-day office return, sells office buildings same week |
| `news_04` | Study: 1 in 3 job postings 'may not technically be jobs' |
| `news_05` | Hierarchai raises $40M to pivot |
| `news_06` | Entry-level role now requires 5 years with a 2-year-old tool |

---

## 16. The career run (Run Spec v1): draft strings

Every string in this section is a **draft** for the career run, written during the Run Spec v1 merge (2026-10-07). Their tone and the 23 event tips were signed off on 2026-10-08 (D-37; later edits come back to you), and they go into the JSON as each milestone builds them (M1's 10 events and 8 tips already are). M6 is the Ducky writing pass, with the plain-language rule for non-tech players (C3; Settled, MC-17, D-34), so jargon here ("prod", "PR", "post-mortem") is kept only until then.

- **Conventions** (section 0): ASCII only, American spelling (A57), snake_case ids with a prefix, and the GDD 2.7 budgets: a card or dialogue line 120 characters, a choice or answer button 40, a tip `short` 120, a dock label 6.
- **New placeholders**, which join section 0's list when these strings go into the JSON: `{jobs}`, `{layoffs}`, `{money}`, `{months}`, `{level}`, `{coworker}`, `{choice}`, `{home}`, `{what}` (the next thing on the calendar strip, M2). Money shows as `{money}`; MC-10 settled that the contract shows the yearly figure (D-34).
- **Banned words:** the brand list (1.3) bans some everyday words too ("indeed", "slack", "zoom", "meta", "intel", "apple", "discord", "copilot", "alphabet", "azure", "nimbus", "oracle"). These drafts avoid them; so must any rewrite.
- **Where they go** (planned, ARCHITECTURE 19.3): names in `naming.json` and a new `coworkers.json`; the work state's UI in `barks.json` (`ui_*`); the events in a new `work_events.json` (`evt_eNN_*`, A54); the tips in `tips.json`; the endings in `endings.json`; Dana's new lines in `barks.json`.

### 16.1 Names

| Key | Name | Note |
|---|---|---|
| `co_synergai` | Hierarchai | run 1's Startup (MC-06, D-34: the Run Spec's placeholder was Pivotly). Already in `companies.json` |
| `co_pixelpivot` | Scope & Creep Digital | the Agency's lead company (MC-06; the placeholder was Outsourcery). Already in `companies.json` |
| `co_omniglobal` | OmniGlobal Dynamics | the MegaCorp's lead company (MC-06; the placeholder was Monolith). Already in `companies.json` |
| `app_home` | Home | the home-tier app. "Your rent, with nicer photos." |
| `app_handbook` | The Handbook | Ducky's collected tips, kept between runs (GDD 5.21) |
| `ui_archetype_startup` / `_agency` / `_megacorp` | Startup / Agency / MegaCorp | the ids are set (MC-05, A68, D-34) |
| `ui_level_junior` / `_mid` / `_senior` | Junior / Mid / Senior | |
| `ui_home_shared` / `_one_bed` / `_studio` / `_penthouse` | Shared room / One-bed / The Studio / Penthouse | the home tiers (GDD 5.15) |
| `scar_short_tenure` / `scar_burnout_history` / `scar_bad_reference` / `scar_resume_gap` / `scar_corner_cutter` | Short Tenure / Burnout History / Bad Reference / Resume Gap / Corner-Cutter | the Scars (GDD 5.21); "Resume" without the accent (A57) |

**Hierarchai's coworkers** (`coworkers.json`; a new `cw_` prefix that joins GDD 5.0's list when the file exists):

| id | Name | Role | Card line |
|---|---|---|---|
| `cw_minh` | Minh | Junior, your desk neighbor | Kind. Clicks everything. |
| `cw_priya` | Priya | Senior engineer | Hears things early. |
| `cw_tom` | Tom | product manager | "It's a small one." |
| `cw_kev` | Kev | your engineering manager | Means well. Reports up. |

Dana is the same Dana (sections 8 and 16.6). **The coworker name pool** for an Agency or a MegaCorp (`coworker_pool`), sharing no name with the dice pool (3.2), Dana, Remy, Jordan or Hierarchai's four: Ari, Bo, Cam, Eli, Fran, Gale, Hana, Ira, Jo, Lee, Nico, Noor, Oli, Pat, Ren, Sasha.

### 16.2 The work state (the phone shell, M2)

| id | Text | Where |
|---|---|---|
| `ui_runway` | {months} mo | the Runway chip (red under 2) |
| `ui_burnout` | BURNOUT | the HUD |
| `ui_ticket` | TICKET | the HUD, under the calendar strip |
| `ui_codebase` | CODEBASE | the HUD's server rack |
| `ui_studio_chip` | Studio {n}/5 | the HUD chip (R-WIN-07) |
| `ui_studio_s1` | Senior engineer | ClikClok's checklist (GDD 3.4) |
| `ui_studio_s2` | Fully remote | |
| `ui_studio_s3` | Living in The Studio | |
| `ui_studio_s4` | Burnout 30 or less | |
| `ui_studio_s5` | 6 months saved at Studio rent | |
| `ui_filming` | Filming... | ClikClok's 90-day hold bar |
| `ui_hours` | Hours | the slider's label |
| `ui_hours_1` | Quiet quitting | the notch labels (GDD 5.17), shown one at a time over the notches |
| `ui_hours_2` | Nine-to-five-ish | |
| `ui_hours_3` | Reasonable | |
| `ui_hours_4` | Just this sprint | |
| `ui_hours_5` | Hustle culture | |
| `ui_speed_pause` / `ui_speed_1` / `ui_speed_2` / `ui_speed_4` | Pause / 1x / 2x / 4x | the speed control |
| `ui_cal_payday` / `ui_cal_rent` / `ui_cal_review` / `ui_cal_interview` / `ui_cal_deadline` / `ui_cal_lease` | Payday / Rent / Review / Interview / Deadline / Lease | the calendar strip |
| `ui_tab_home` / `ui_tab_video` / `ui_tab_ducky` | Home / Video / Ducky | dock labels (6 characters): the Home app, ClikClok, the Handbook; DoomApply keeps `ui_tab_jobs` |
| `ui_pick_feature` / `ui_pick_bugfix` / `ui_pick_paydown` | Feature / Bugfix / Pay-down | a Mid's ticket pick (GDD 5.17) |
| `ui_pick_paydown_note` | Nobody notices. | the Run Spec's line on the pay-down card |
| `ui_push_back` | Push back the deadline | a Mid's once-per-cycle action |
| `ui_quality_clean` / `ui_quality_balanced` / `ui_quality_fast` | Clean / Balanced / Fast | a Senior's quality bar |
| `ui_home_move` | Move here: {money} | the Home app (one month of the new rent) |
| `ui_home_here` | You live here. | |
| `ui_callback` | Callback | the posting's 5-dot odds band (GDD 5.20) |
| `ui_applied` | Applied. Reply in 3-10 days. Maybe. | after Apply on the board |
| `ui_last_floor` | This is your last floor. There's no job 6. | the board during job 5 (a spec gap's proposal) |
| `ui_run_ends_confirm` | Leaving job 5 ends your career. Are you sure? | RC-33's confirm |
| `ui_promoted` | Promoted to {level}! Same desk. Bigger title. | after a review |
| `ui_pip` | Performance plan: 60 days. Your manager has concerns, in writing. | two Below in a row |
| `ui_forced_leave` | Burnout hit 100. Forced leave: your body filed the ticket nobody else would. | the forced leave (GDD 5.21) |
| `ui_burnout_warn_60` | You read the same line four times. | the first warning beat (the Run Spec's line) |
| `ui_burnout_warn_70` | You said yes to a meeting about meetings. You don't remember saying it. | the second |
| `ui_burnout_warn_75` | Running on empty. From now on, a tired you may pick some choices for you. | the third: auto-resolve starts here (R-EVT-02) |
| `ui_auto_resolved` | Too tired to choose. Burnout picked: {choice} | an auto-resolved card says so (R-EVT-02) |

The burnout lines follow GDD 1.3: the workload and the employer are the joke, never the person's health.

### 16.3 Event cards (`work_events.json`)

One entry per event, keyed `evt_eNN_<name>` (A54). Its texts sit inline in the entry, like a question's answers (ARCHITECTURE 6.3, 19.3), so an id below that extends an event id (a choice such as `evt_e12_fix_it`, a result such as `evt_e02_below`, a rumor, a sign) names a field of that entry, not an entry of its own. Each choice's effects are in GDD 5.19 and stay out of the text. "exh." is the exhausted choice: the Run Spec's where it gave one, otherwise **proposed** (a spec gap for M1 and M6). Ducky's joke and cause come with M6's writing pass, except E12's, which the Run Spec wrote; the tip ids are in 16.4.

| id | Card text | Choices (label: text) | exh. |
|---|---|---|---|
| `evt_e01_payday` | Payday! {money} in. (On day 1 of each month: "Rent day. {money} out.", `evt_e01_rent`.) | none: the money pulse | - |
| `evt_e02_review` | Review day. Your manager has a form, a template and 15 minutes. | the 3-prompt review duel; results `evt_e02_below` "Rating: Below. Your manager is 'concerned'. In writing.", `evt_e02_meets` "Rating: Meets. Raise: 1%. Inflation sends its regards.", `evt_e02_exceeds` "Rating: Exceeds. Raise: 3%. Your manager calls it 'a strong signal'." | - |
| `evt_e03_new_project` | Tom: "Got a new project. It's a small one." It is not a small one. | `volunteer`: Volunteer; `stay`: Stay on your ticket | Volunteer (proposed) |
| `evt_e04_lease_renewal` | Lease renewal. Your landlord loves you. Your rent loves you 10% more. | `accept`: Accept the +10%; `move_down`: Move down a tier | Accept the +10% (proposed) |
| `evt_e05_all_hands` | All-hands. 42 slides. The word "exciting" appears 19 times. | none: it carries rumors | - |
| `evt_e06_on_call` | On-call week. Your phone is a pager now. It knows where you sleep. | none: 7 days of effects | - |
| `evt_e07_resizing` | (the chain's signs, below, then the layoff scene, 16.6) | prep, on a card during the chain: `update_profile`: Update your profile; `ask_priya`: Ask Priya what she's heard; `cut_spending`: Cut spending | to set at M3 (proposed: no prep is taken; too tired to prepare) |
| `evt_e08_rto_mandate` | Memo: "We're excited to bring everyone back together." Monday. Five days a week. | `comply`: Comply: back to the office; `push_back`: Push back: it's in my contract (the tip and a remote clause); `quit`: Quit | Comply (proposed) |
| `evt_e09_reorg` | Reorg. You have a new manager with a new vision. Neither has met you. | `book_1on1`: Book a 1:1 in week one; `wait`: Wait and see | Wait and see (proposed) |
| `evt_e10_pivot` | Pivot! The company is AI for pets now. Your project is "legacy". | `champion`: Champion it; `stay_quiet`: Stay quiet | Stay quiet (proposed) |
| `evt_e11_client_churn` | The client left. You're on the bench. The bench is a chair by the printer. | `learn`: Learn something new; `any_client`: Ask for any client | Ask for any client (proposed) |
| `evt_e12_incident_prod` | 2 a.m. Prod is down. The alerts are loud. Whoever is on call is very quiet. | `fix_it`: Fix it yourself; `escalate`: Wake whoever is on call | Fix it yourself (the Run Spec's) |
| `evt_e13_phishing_test` | Email: "URGENT: your payroll is on hold. Click here to fix it." The sender looks almost right. | `click`: Click the link; `report`: Report it; `ignore`: Ignore it | Click the link (the Run Spec's) |
| `evt_e14_coworker_scam` | {coworker} clicked a "free pizza" link. Their laptop is now mining something. | `help`: Help clean up; `stay_out`: Stay out of it | Help clean up (proposed) |
| `evt_e15_hardcoded_secret` | You found a password in the code. In plain text. From 2019. It still works. | `report`: Report it; `fix_quietly`: Fix it quietly; `ignore`: Ignore it | Ignore it (the Run Spec's) |
| `evt_e16_stale_pr` | Your change has waited 9 days for a review. Someone reacted with a cobweb. | `ping_one`: Ping one named reviewer; `post_channel`: Post in the team channel; `merge_anyway`: Merge it anyway | Merge it anyway (proposed) |
| `evt_e17_credit_taken` | Demo day. {coworker} presents your feature. "I" comes up 14 times. "We", once. | `speak_up`: Speak up; `say_nothing`: Say nothing; `brag_doc`: Send the brag doc (the tip) | Say nothing (proposed) |
| `evt_e18_recruiter_dm` | A recruiter DMs: "Exciting role, perfect fit, can we talk?" They spelled your name right. | `take_call`: Take the call; `ignore`: Ignore it | Ignore it (the Run Spec's) |
| `evt_e19_coffee_machine` | The coffee machine is broken. A sign says "Ticket filed." Morale: also broken. | none: 3 days of effects | - |
| `evt_e20_laptop_dies` | Your laptop dies. Its last words: a spinning wheel. | `pay`: Buy a new one ({money}); `limp`: Limp along | Limp along (the Run Spec's) |
| `evt_e21_lifestyle_offer` | A raise! A listing appears: "{home}. You deserve this." Your rent agrees. | `upgrade`: Move to {home}; `stay`: Stay where you are | Stay where you are (proposed) |
| `evt_e22_ai_agent` | Your ticket went to an AI agent. It finished in 4 minutes. It also deleted a test. | `review`: Review its work properly; `approve`: Approve it | Approve it (the Run Spec's) |
| `evt_e23_mentor_offer` | {coworker}: "Want to meet every other Thursday? Bring questions." | `accept`: Accept; `decline`: Decline | Decline (proposed) |
| `evt_e24_overtime_ask` | Your manager: "Can you stay late this week? Just this sprint." It is never just this sprint. | `stay_late`: Stay late; `decline`: Decline | Stay late (the Run Spec's) |
| `evt_e25_review_request` | {coworker} asks you to review 2,000 lines of code. "Should be quick!" | `review`: Review it properly; `rubber_stamp`: Rubber-stamp it | Rubber-stamp it (proposed) |
| `evt_e26_blame_postmortem` | Incident review. Slide 3 says "Root cause:" and then a pause long enough for your name. | `own_it`: Own it; `blame_deadline`: Blame the deadline | Own it (proposed) |

**Built in M1 (STEP-14).** The ten events of DECISIONS A62 (E01, E02, E04, E07, E08, E12, E18, E20, E21, E24) are in `data/content/work_events.json` with these draft texts, unchanged except that E02's results say `{n}` for the raise so tuning can never make a card lie; the signs of run 1's chain and E08's rumor are inline in their entries. Their eight tips are in `tips.json` as drafts for your sign-off (`more` is empty until M6's writing pass). The exhausted choices are the "proposed" ones (A66); E07's prep takes none (`"none"`). `coworkers.json` holds Hierarchai's four and the name pool.

**E12's Ducky block** (the Run Spec's): `evt_e12_joke` "You fixed prod at 2 a.m. Prod now has your phone number."; `evt_e12_cause` "Whoever fixes it once becomes whoever fixes it always."; tip `tip_escalate`.

**Rumors** (telegraphed events; shown on the calendar strip 10-30 days ahead):

| id | Text |
|---|---|
| `evt_e08_rumor` | Rumor: leadership toured an empty floor and "felt sad". |
| `evt_e09_rumor` | Rumor: a consultant is "mapping the org". With a red pen. |
| `evt_e10_rumor` | Rumor: the founder's new podcast episode is called "Burn the Boats". |
| `evt_e11_rumor` | Rumor: the client's new CTO "has a nephew who codes". |

**Run 1's resizing chain** (R-RUN-02, GDD 5.19):

| id | About day | Text |
|---|---|---|
| `evt_e07_sign_1` | 150 | All-staff email: "We're pausing hiring to stay nimble." The careers page says "Coming soon". |
| `evt_e07_sign_2` | 165 | All-hands: "This year is about efficiency." The snacks are the first to go. |
| `evt_e07_sign_3` | 190 | The new roadmap is out. Your project is in a box called "Later". Later has no date. |
| `evt_e07_sign_4` | 210 | Minh's desk is empty. The plant is gone. The badge reader beeps red at no one. |
| `evt_e07_sign_5` | 235 | Calendar invite from Dana: "15 min sync". No agenda. The room is called "Opportunity". |

### 16.4 Event tips (`tips.json`)

The Run Spec's own tip texts, made ASCII and American ("favorite", "practice"). The `more` line (the Handbook's extra) comes with M6's writing pass. Tip accuracy is yours to sign off (W4, GDD 8.1). Where each fires and its kind: GDD 8.6.

| id | short | Event |
|---|---|---|
| `tip_brag_doc` | Keep a brag doc; your manager forgets, documents don't. | E02 (Edge) |
| `tip_visible_work` | Volunteer for work your manager's manager can see. | E03 |
| `tip_read_slides` | Read the slides for what isn't said. | E05 |
| `tip_on_call_appendix` | On-call lives in the appendix; read it. | E06 |
| `tip_layoffs_cost` | Layoffs select for cost, not performance; prepare anyway. | E07 |
| `tip_remote_in_writing` | Get remote in writing; verbal flexibility expires. | E08 (Option) |
| `tip_new_manager` | New manager? Book the 1:1 before they form an opinion. | E09 |
| `tip_pivot_roadmap` | Pivots move headcount; know where your work sits on the new roadmap. | E10 |
| `tip_bench_visible` | On the bench, visible beats busy. | E11 |
| `tip_escalate` | Heroics are a staffing bug; escalate first, then help. | E12 |
| `tip_check_sender` | Urgency is the scammer's favorite feature; check the sender. | E13 |
| `tip_report_fast` | Report fast; the cleanup is cheaper than the shame. | E14 |
| `tip_rotate_key` | A leaked key gets rotated, not just deleted. | not used: E15 reuses `tip_secrets` (MC-17, D-34) |
| `tip_small_prs` | Small PRs get reviewed; ask one named person. | E16 |
| `tip_write_it_down` | Write it down the day you ship it. | E17 |
| `tip_take_the_call` | Always take the call; information is free. | E18 (Edge) |
| `tip_emergency_fund` | An emergency fund is boring until it's the only thing that works. | E20 (Edge) |
| `tip_savings_rate` | Raise your savings rate before your rent. | E21 |
| `tip_review_ai_code` | Reviewing generated code is a skill now; practice it. | E22 |
| `tip_ask_mentorship` | Ask for mentorship specifically: 30 minutes, every two weeks. | E23 |
| `tip_overtime_loan` | Overtime is a loan; know who's paying it back. | E24 (Edge) |
| `tip_review_design` | Review the design, not the semicolons. | E25 |
| `tip_blameless_postmortem` | Blameless post-mortems fix systems; blame fixes nothing. | not used: E26 reuses `tip_blameless` (MC-17, D-34) |

23 tips. E01, E04 and E19 have none (D-28 took E04's "Landlords negotiate too; ask before you sign").

### 16.5 Endings (`endings.json`)

| id | Text |
|---|---|
| `end_studio_title` | THE STUDIO |
| `end_studio` | You woke at 10:47. It took {jobs} jobs. |
| `end_studio_one` | You woke at 10:47. It took one job. |
| `end_studio_caption` | 10:47 - woke up. {jobs} jobs. {layoffs} layoffs. 1 Studio. |
| `end_burnout_title` | BURNOUT |
| `end_burnout` | You took the leave. You didn't come back. |
| `end_career_change_title` | CAREER CHANGE |
| `end_career_change` | You teach a bootcamp now. You show them the video. |
| `end_legacy_title` | LEGACY SYSTEM |
| `end_legacy` | Six years. Same service. You are the legacy system. |
| `end_career_stats` | Days: {day} - Jobs: {jobs} - Layoffs: {layoffs} - Level: {level} |

- The four card lines are the Run Spec's (GDD 3.3); `end_studio_caption` is the win video's caption (GDD 3.4). `end_studio_one` is a grammatical variant, like `ui_ghost_footer_one`; the caption's one-job and one-layoff variants come with the JSON.
- Plan B keeps `end_plan_b_title`, `end_plan_b` (its "Rent's due." is Settled, MC-20, D-34: reword at M3), the background's `plan_b_line` and `end_plan_b_final`.
- Every ending card also shows the career-long Dream vs Reality score, whose formula and rows are Settled (MC-09, D-34): the 5 rows, rebased and scored per job.

### 16.6 The layoff scene and Dana's new lines (`barks.json`)

| id | Text |
|---|---|
| `vs_layoff_title` | DANA VS YOU |
| `bark_dana_layoff` | We're reshaping how we're shaped. |
| `bark_dana_layoff_2` | Your badge stops at 5 PM. Mine stops at 6. I asked for a head start. |
| `ui_severance` | Severance: {money} |
| `ui_access_revoked` | ACCESS REVOKED |
| `bark_dana_greet_after_layoff` | Yes, I laid you off at {last_company}. Then they laid me off. Hi. Shall we? |
| `vs_banner_big_2` | ROUND 2 OF 7 |

- `vs_layoff_title` and `bark_dana_layoff` are the Run Spec's (D-22). Dana stays as written (GDD 1.3, RC-23): the joke is the script she has to read and the process behind it, never her.
- `bark_dana_greet_after_layoff` is for the first interview after run 1's layoff, which Dana delivered rather than interviewed you for, so `bark_dana_greet_again` ("Didn't I interview you at...") doesn't fit there (proposed).
- `vs_banner_big_2` is the banner of a MegaCorp posting's second duel (GDD 5.20).
- The intro's handover to day 0 is Settled (MC-11, D-34). The last caption, as a draft: `intro_p6_handover` "Four years later, you have a job. Remy says the next part is easy."

### 16.7 Phase 1's strings in the career run

- **Kept:** the duel's (sections 7-9), the offer's (13; `offer_deadline`, "Please decide before you sleep.", is Settled, MC-20, D-34: reword at M3), the Plan B card's (14) and `coach_meter` (10.2).
- **Retired with the hunt** when the career run is built (MC-01, D-33: the career run is what `v0.5-mvp` ships): the hunt's UI lines in 10.1 (energy, rent, the Radar, the deck, Mail), its coach lines in 10.2, the emails (12) and the morning events (15.1).
- **Following MC-08 and MC-09 (settled, D-34):** `end_hired_*` (the stamp stays as a beat), the Dream rows (rebased) and `end_tbc` (dropped).
- **Removed** (D-27; they left the JSON in the code cleanup of 2026-10-08): `tip_negotiate`, `bark_dana_nego_win`, `bark_dana_nego_lose`, `ui_negotiate`, `offer_equity_doubled`, `offer_signon`.

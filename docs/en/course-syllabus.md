# 8-Week Course Syllabus — Learning iOS App Design through the "Living Record" App

> English translation. Korean original: `8주-강의계획서.md`.

> Project-based learning (PBL) · Main text: the project report (`프로젝트-보고서.md`) · Supplements: `concept.md` · `spike-findings.md` · `v1~v4-slices.md` · the user guide (`사용설명서.md`)
> Written 2026-06-05

---

## Course Overview

| Item | Details |
|---|---|
| **Audience** | Students with basic Swift syntax (variables, functions, optionals, closures) |
| **Prerequisites** | Swift fundamentals. SwiftUI/SwiftData are covered in this course |
| **Dev environment** | macOS + Xcode (iOS 26+ SDK), **one physical device recommended** (voice, widgets, and notifications require a real device) |
| **Time allocation** | **3 hours per week** (① theory & decisions 1h → ② code reading 1h → ③ hands-on / live coding 1h) + assignments |
| **Teaching style** | No mere copy-typing ✗ — first ask *"why was it decided that way"* and track change through commit diffs |

### Learning Outcomes (what you can do after completing the course)
1. Grow a working app step by step through **vertical slices**.
2. Validate uncertain technology with a **spike** before designing.
3. Use AI (on-device LLM, embeddings) **only as much as you can trust it**, and shore up what you can't trust with **deterministic rules**.
4. Enforce **privacy and data ownership** in code.
5. Know how to *narrow scope or roll back* when stuck (failure handling).

### Grading Weights
| Item | Weight | Description |
|---|---|---|
| Weekly hands-on / assignments | 30% | Weekly milestone submission (code + short reflection) |
| Spike reproduction report | 15% | Reproducing the embedding & intention-detection spikes + interpretation |
| Judgment analysis essay | 15% | Analysis of one design decision ("what would I do?") |
| Privacy audit | 10% | Tracing every path by which a sealed item could leave the device |
| Final project | 30% | Your own slice / extension + presentation |

> **Rubric (common):** Does the slice *work* · verification habits · recording the rationale for judgments · privacy boundaries · failure handling.

---

## The 8 Weeks at a Glance

| Week | Theme | Report phase/unit | Key keywords | Milestone |
|---|---|---|---|---|
| 1 | Orientation · methodology · conception & validation | 0 (0-1, 0-2) | Vertical slice, spike | Environment setup + run one spike |
| 2 | v1 foundation: capture → store → list · energy · seal | 1-1~1-3 | SwiftUI, SwiftData, vDSP | S0~S2 working |
| 3 | v1 data: Obsidian mirror · classification & consolidation ⭐ | 1-4, 1-5 | Embedding, FM assignment, curation | S3~S4 + spike reproduction submission |
| 4 | v1 digest & cloud · on-device validation | 1-6~1-9 | Two-stage distillation, privacy | **Midpoint check**: complete v1 |
| 5 | v2 sustain loop (5 signals · decision loop) | 2-0~2-4 | Deterministic gate, feedback loop | S8~S11 + essay submission |
| 6 | v3 reachability · v4 search · extras | 3·4·5 | App Intent, widgets, hybrid search | 2 of trigger/search/backup |
| 7 | Living Record · LLM wiki | 6·7 | push, resurfacing, knowledge base | Resurfacing or one wiki |
| 8 | Learning from failures & reviews · synthesis presentation | 8 | Reversal, embedding limits, audit | **Final presentation** + privacy audit |

---

# Weekly Detail

## Week 1 — Orientation · Development Methodology · Conception & Validation

**Learning objectives**
- Understand *what* you learn from this project (not the code, but the flow of judgment).
- Know the discipline of vertical slices, spike-first, and "implement → validate → commit".
- Run a spike yourself and experience "turning uncertainty into fact".

**Lecture flow**
1. *Theory (1h):* The app vision ("what to sustain") · the 7 methodology principles · why docs matter as much as code.
2. *Code reading (1h):* Tour the repository structure — `docs/` first, then the source map. Open one commit (`04ad787`).
3. *Hands-on (1h):* Xcode and device setup. Run `spike/embed_spike3.swift` or `intention_spike2.swift` with `swift` and reproduce the output.

**Hands-on / assignment**
- Environment setup proof (screenshot of an empty project that builds).
- One spike's run result + 3 sentences on "how this result might affect the design".

**Reading:** the project report (`프로젝트-보고서.md`) §0~§2, `concept.md` (read through), `spike-findings.md` ①②③⑥.

**Checkpoint:** Write a "one-line definition of a vertical slice" in your own words.

---

## Week 2 — v1 Foundation: Capture → Store → List · Energy · Seal

**Learning objectives**
- Build a minimal flow that *stores and shows on screen* with SwiftData `@Model`/`@Query`.
- Know why we drive the most important flow (capture) all the way through first.
- Understand the privacy decision of keeping only the prosody score and discarding the audio.

**Lecture flow**
1. *Theory:* SwiftData basics (models, contexts, queries, migrations) · SwiftUI state (`@State`/`@Environment`).
2. *Code reading:* `Models.swift` → `CaptureView.swift` → `CaptureListView.swift`. Commits `f6af896` · `c12f7db`.
3. *Live coding:* Text capture → store → list from scratch (recording may be narrowed to a later step).

**Hands-on / assignment (Milestone 1)**
- Implement S0~S2 yourself: text (minimum), and voice capture if possible + energy/seal fields.
- 3-sentence reflection: "why I built capture first / where I got stuck / how I narrowed scope to solve it".

**Reading:** report units 1-1~1-3, `v1-slices.md` S0~S2.

**Checkpoint:** One sentence on *what problem* sealing (sealed) solves.

---

## Week 3 — v1 Data: Obsidian Mirror · Classification & Consolidation (theme) ⭐ The Hardest Week

**Learning objectives**
- Export the app data **one-way** into a user-owned format (Markdown).
- Hit the *limits of embeddings and the FM* firsthand when grouping similar captures into a theme.
- Internalize the core design: "automation is best-effort, curation is human".

**Lecture flow**
1. *Theory:* security-scoped bookmark (access outside the sandbox) · embeddings and cosine similarity · **centering** · FM guide generation (`@Generable`).
2. *Code reading:* `VaultStore` · `ObsidianMirroring` → `Embedding` · `ThemeAssigning` · `Consolidation` · `Curation`. Commits `508fa6c` · `e0d5ba6` · `b951fdc`.
3. *Hands-on:* Run the spikes `embed_spike3` · `binary_spike` to reproduce *why threshold clustering failed and we moved to FM assignment*.

**Hands-on / assignment (Milestone 2 + spike report submission)**
- S3 mirror + S4 theme grouping (OK even if incomplete) + one curation type (rename or merge).
- **Spike reproduction report (15% of grade):** Reproduce the embedding/intention-detection spike results + interpret "why that conclusion".

**Reading:** report units 1-4 · 1-5, `spike-findings.md` ⑤⑥, `v1-slices.md` S3 · S4.

**Checkpoint:** Why "over-splitting is safer than over-merging".

---

## Week 4 — v1 Digest & Cloud · On-Device Validation (Midpoint Check)

**Learning objectives**
- Understand day/week/period digests and **two-stage distillation** (originals local, only the distilled layer to the cloud).
- See the cloud consent model (turn on once, sealed exception, transfer log) in code.
- Feel that *simulator ≠ physical device*, and see the UX break and get fixed several times.

**Lecture flow**
1. *Theory:* The altitude ladder of reflection (day → week → period) · privacy boundaries · cloud = upgrade (not a dependency).
2. *Code reading:* `DailyDigest` · `WeeklyReview` · `Distillation` · `DeepSynthesizer` · `CloudConsent`. Commits `bbbcdc5` · `8176371` · `3df87d6`. Compare the UX-struggle commits (`ca7e901` → `db3e13f`).
3. *Hands-on:* Generate a daily digest + (optional) read the cloud toggle flow. Voice capture on a real device + a CER measurement tool.

**Hands-on / assignment (Midpoint check: complete v1)**
- Minimal working *daily digest* among S5~S7 + demo one flow of your own app on a physical device.
- Short presentation (3 min): "the hardest decision in my v1".

**Reading:** report units 1-6~1-9, `spike-findings.md` ②-real (92.8%).

**Checkpoint:** What is the distilled layer? *Where* is it guaranteed that sealed items don't go to the cloud?

---

## Week 5 — v2: Sustain Loop (5 Signals · Decision Loop)

**Learning objectives**
- Complete the signals by adding **action, cooling, and connection** to repetition, energy, and evolution.
- Understand the design that closes the *decision → practice → feedback* loop.
- Analyze the judgment of choosing a **Korean-ending gate instead of an FM Bool** (the peak of this course).

**Lecture flow**
1. *Theory:* Momentum (early vs. late in the window) · evolving/looping · cooling (pruning) · "make the deterministic things deterministic".
2. *Code reading:* `WeeklyReview` (candidates · cooling · followUps · Precedent) · `IntentionDetecting` · `Resurfacer is Week 7`. Commits `f111058` · `321f36a` · `c4a77ca` · `58134ba`.
3. *Hands-on:* Reproduce the A (FM) · B (gate) · C comparison with `intention_spike2` → why the gate wins.

**Hands-on / assignment (Milestone 3 + essay submission)**
- Implement one of S8 (intention detection + commitment) or S9 (cooling).
- **Judgment analysis essay (15% of grade):** "Ending gate instead of FM" or one free-choice decision — what, why, and what I would do.

**Reading:** report Phase 2 (2-0~2-4), `spike-findings.md` ⑦, `v2-slices.md`.

**Checkpoint:** *How* did we measure the FM's "yes bias"?

---

## Week 6 — v3 Reachability · v4 Search · Extra Features

**Learning objectives**
- Build the system integration (App Intent, widgets, notifications) that captures without opening the app.
- Understand full-text + semantic **hybrid search** and its *honest labeling* ("estimated").
- Add portability and expressiveness with encrypted backup, templates, and visualization.

**Lecture flow**
1. *Theory:* App Intents / `openAppWhenRun` / AppShortcut · WidgetKit interactive widgets · UNCalendar notifications · CryptoKit (HKDF + AES-GCM) · Swift Charts.
2. *Code reading:* `CaptureIntents` · `Reminders` · `CaptureWidget*` · `Search` · `Backup` · `Templates` · `InsightsView`. Commits `feeb00f` · `2eb2465` · `6230017` · `b791ce8` · `eebc466`.
3. *Hands-on:* Trigger a capture via the Action button / Siri (physical device) **or** implement search **or** a backup round-trip (`backup_spike`).

**Hands-on / assignment (Milestone 4)**
- Implement and demo **2** of trigger / search / backup.

**Reading:** report Phases 3 · 4 · 5, `v3-slices.md` · `v4-slices.md`.

**Checkpoint:** Why does semantic search run only on return, not on every keystroke? Why derive the key with HKDF?

---

## Week 7 — Living Record (Resurfacing) · LLM Wiki

**Learning objectives**
- Understand the design that turns the app from pull (you go and look) into **push (the past walks up to you)**.
- Structure the vault into a **knowledge base (wiki)** that an LLM can navigate and read.
- See the design that keeps expensive work (cloud summarization) behind *explicit actions* only.

**Lecture flow**
1. *Theory:* "How the past helps the present" (resurfacing · precedent · throughline) · avoiding the rumination trap · wiki hub + MOC · opt-in summary.
2. *Code reading:* `Resurfacer` · `Throughline` · `Reminders` (resurfacing push) · `WeeklyReview` (Precedent) · `WikiBuilder` · `WikiSummary`. Commits `aabe3b7` · `dbd806f` · `2a0ffce` · `4e1c9e2` · `0204f06` · `1472fa4`.
3. *Hands-on:* Implement resurfacing (Resurfacer) **or** generate a wiki hub (`WikiBuilder`) — check the graph view in the vault.

**Hands-on / assignment (Milestone 5)**
- Implement and demo resurfacing (one of echo / resurfacing / precedent / throughline) **or** wiki A.

**Reading:** report Phases 6 · 7, the user guide (`사용설명서.md`) (usage flow of the finished app).

**Checkpoint:** How was *dynamic content* carried in a repeating notification (7 days of non-repeating scheduling)?

---

## Week 8 — Learning from Failures & Reviews · Synthesis Presentation

**Learning objectives**
- Learn that *knowing how to roll back* is also skill, through the two-way Obsidian reversal case.
- Know the judgment to *change approach* when you repeatedly hit a technology's limit (embeddings).
- Audit the privacy invariants to the very end.

**Lecture flow**
1. *Theory:* The *root cause* and safeguards of the two-way duplicate-creation incident · the embedding limit (3 times) · final code review (sealed cloud leak).
2. *Code reading (diff comparison):* `b0d28e6` (introducing two-way) ↔ `f9fe264` (reversal) · `4ee6710`/`f0b5001` (related-theme tuning → removal) · `6b0df7f` (review · leak fix).
3. *Presentation:* Final project presentations.

**Hands-on / assignment (Final)**
- **Privacy audit (10% of grade):** Trace "every path by which a sealed item could leave the device" in the code, as a table (hint: cloud vs. vault iCloud sync).
- **Final project (30% of grade):** Your own slice / extension + presentation (you may pick one of the D options below).

**Reading:** report Phase 8, notes / commit messages (reversal rationale).

**Checkpoint:** Why was guidance alone of "re-export everything first" not enough?

---

## Project Milestones (Submission Schedule)

| Week | Deliverable |
|---|---|
| 2 | M1: S0~S2 working + reflection |
| 3 | M2: S3~S4 + **spike reproduction report** |
| 4 | Midpoint check: demo one v1 flow on a physical device |
| 5 | M3: S8 or S9 + **judgment analysis essay** |
| 6 | M4: 2 of trigger/search/backup |
| 7 | M5: resurfacing or one wiki |
| 8 | Final: **privacy audit + project presentation** |

### Final Project Options (pick 1, report §6-D)
- **Deterministic related themes** based on "appearing together on the same day" (instead of embeddings).
- **Threshold tuning** of signals with real data (cooling · commitment · momentum).
- **iCloud sync** or an **MLX fallback engine**.
- Your own new **vertical slice** (design doc → spike → implementation → validation).

---

## Operational Tips (for Instructors)

- Share **one physical device** across sections, or make the voice/widget/notification units demo-centered (state the simulator's limits explicitly).
- **Read commit diffs together** every week — "what was added" is the best teaching material.
- Ask **"why" first** rather than copy-typing: turn each unit's review question into a discussion prompt.
- Guide students to **narrow scope** when stuck (e.g., "text capture only first, not voice").
- Treat the failure cases (Week 8) not as *something embarrassing* but as the *most valuable teaching material*.

---

## Length Adjustment Guide

- **Short (4-week) compression:** W1 (methodology + conception) → W2 (v1 S0~S4) → W3 (v1 digest & cloud + v2 core) → W4 (resurfacing/wiki + learning from failure & presentation).
- **Long (16-week) expansion:** Two weeks per phase (separating theory/code-reading ↔ hands-on implementation), one week per slice for v2 through the wiki.

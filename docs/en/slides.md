---
marp: true
theme: default
paginate: true
header: "Living Record — iOS App Design, 8 Weeks"
---

<!-- This file is a Marp deck. Convert to PDF/PPT with the VS Code Marp extension or `marp slides.md`.
     `---` separates slides. Speaker notes go in <!-- comments -->. 5-7 slides per week. -->

# iOS App Design,
# **Taught Through Living Record**

8-week project course · Slide overview

<!-- Companion materials: syllabus, workbook, model-answer set, grading rubric. The weekly "read the commit diff together" is the core text. -->

---

## What This Course Teaches

- Not the *quantity* of code, but the **quality of judgment**
- Five competencies: **A** slicing · **B** verification · **C** evidence · **D** privacy · **E** failure handling
- Discipline: **implement → verify by running → commit**

> "Read the code, but first ask **why it was decided that way**."

---

# Week 1
## Methodology · Conception and Verification

---

## Learning Goals (Week 1)
- State this app's *single question* → **“what to sustain”**
- Explain **vertical slice** · **spike-first**
- Run one spike yourself

---

## Key Concepts (Week 1)
- **Vertical slice**: the smallest unit that runs one flow end to end, UI to storage
- **Spike**: a *throwaway experiment* before the real build to remove uncertainty
- A **record of good judgment** (docs/) comes before good code

---

## Code/Doc Walk (Week 1)
- `docs/concept.md` — decided vs. open
- `spike-findings.md` ①②③⑥ — Korean on-device verification results
- Open commit `04ad787` (S0 scaffolding)

<!-- Demo: run `swift spike/intention_spike2.swift` in the terminal -->

---

## Discussion Prompts (Week 1)
- "In one word, how does your note app differ from this one?"
- "What separates a spike from a prototype?"

**Assignment:** Set up the environment + 3 sentences on one spike run

---

# Week 2
## v1 Foundation — Capture → Store → List

---

## Learning Goals (Week 2)
- The minimal flow that *saves and shows on screen* via SwiftData
- Drive the most important flow (capture) through first
- The privacy decision to discard audio and keep only a score

---

## Key Concepts (Week 2)
- `@Model` (model) · `@Query` (auto-fetch) · `ModelContext`
- Zero friction: **no classification UI** on the capture screen
- Energy = a relative value "vs. usual"; **audio is discarded immediately**

---

## Code Walk (Week 2)
- `Models.swift:Capture` — read the fields
- `CaptureView.swift:saveText()` → insert · save · enqueue
- `CaptureListView` — `@Query` auto-refresh
- Commits `f6af896` · `c12f7db`

---

## Demo · Discussion (Week 2)
- Demo: capture text → appears in the list instantly
- Prompt: "Why throw audio away? Wouldn't keeping it be better?"

**Milestone 1:** S0-S2 working + 3-sentence retrospective

---

# Week 3 ⭐
## v1 Data — Mirror · Classification · Consolidation

---

## Learning Goals (Week 3)
- A **one-way** markdown mirror (data ownership)
- Hit the **limits** of embeddings and the FM firsthand
- "Automation is best-effort; the digest is done **by people**"

---

## Key Concepts (Week 3)
- security-scoped bookmark (access outside the sandbox)
- Embeddings + **centering** (anisotropy correction)
- Threshold clustering *fails* → FM **Bool judgment** ("same topic?")

---

## Code Walk (Week 3)
- `ObsidianMirroring:markdown` — frontmatter
- `Embedding` · `ThemeAssigning(SameTopic)` · `Consolidation` · `Curation`
- Reproduce spikes `binary_spike` / `embed_spike3`
- Commits `508fa6c` · `e0d5ba6` · `b951fdc`

---

## Why You Can't Trust Embeddings (Week 3 — key slide)
- Pairs that should merge **0.209** < pairs that shouldn't **0.353**
- → *similarity ranking is inverted* → no single threshold works
- ∴ drop embedding clustering → FM assignment → still unstable on-device
- **Conclusion: best-effort + curation**

---

## Discussion (Week 3)
- "Why is over-splitting safer than over-merging?"

**Milestone 2 + spike reproduction report (15%)**

---

# Week 4
## v1 Digest · Cloud · Real Device

---

## Learning Goals (Week 4)
- Daily/weekly/period digests + **two-stage distillation**
- Consent model (one-time opt-in · sealed exception · transfer log)
- *Simulator ≠ real device*

---

## Key Concepts (Week 4)
- **Two-stage distillation**: raw text stays local → only the distilled layer goes to cloud
- Cloud = an **upgrade** (not a dependency)
- Sealing is blocked at `Distillation`'s `!sealed`

---

## Code Walk (Week 4)
- `DailyDigest` · `WeeklyReview` · `Distillation` · `DeepSynthesizer` · `CloudConsent`
- Compare UX struggle: `ca7e901`→`db3e13f` (4 commits to auto-expand the input field)
- Commits `bbbcdc5` · `8176371` · `3df87d6`

---

## Demo · Discussion (Week 4)
- Demo: real-device voice capture (STT 92.8%)
- Prompt: "The most private place is the one that most needs the cloud — how do you solve that?"

**Mid-check:** 3-minute real-device demo of one v1 flow

---

# Week 5
## v2 Sustain Loop — Deterministic Gate

---

## Learning Goals (Week 5)
- Five signals (repetition · energy · evolving + acting · cooling · linking)
- Decision → action → **feedback** loop
- The judgment to choose an **ending gate** over the FM

---

## Key Slide (Week 5)
Spike ⑦:
| Strategy | Accuracy |
|---|---|
| FM Bool alone | **1~6/10** (wobbly) |
| Ending gate | **10/10** |
**→ The decision is a deterministic gate; the FM only assists with labels**

---

## Code Walk (Week 5)
- `IntentionDetecting:markers` (겠/해야/하자/봐야지… — commitment endings)
- `WeeklyReview` (candidates · cooling · followUps · Precedent)
- Spike `intention_spike2` (A/B/C comparison)
- Commits `321f36a` · `c4a77ca` · `58134ba`

---

## Discussion (Week 5)
- "How did you *measure* the FM's 'yes bias'?"
- "If the ending gate also catches '좋겠다' (would be nice) — is it still better?"

**Milestone 3 + judgment-analysis essay (15%)**

---

# Week 6
## v3 Reachability · v4 Search · Extras

---

## Learning Goals (Week 6)
- Capture in one action from outside the app (App Intent · widget · notification)
- **Hybrid search** + an honest label ("estimated")
- Encrypted backup · templates · visualization

---

## Key Concepts (Week 6)
- `openAppWhenRun` → execution runs in the *app process*
- Search: full-text (primary) + semantic (secondary · threshold 0.30)
- Backup: **HKDF** (key derivation) + **AES-GCM**

---

## Code Walk · Demo (Week 6)
- `CaptureIntents` · `CaptureWidget*` · `Reminders` · `Search` · `Backup`
- Demo: capture via Action Button/Siri (real device), `backup_spike` (wrong password fails)
- Commits `feeb00f` · `6230017` · `b791ce8` · `eebc466`

**Milestone 4:** 2 of trigger / search / backup

---

# Week 7
## Living Record · LLM Wiki

---

## Learning Goals (Week 7)
- **pull → push** (the past comes to you)
- Turn the vault into an **LLM knowledge base (wiki)**
- Expensive work (cloud summarization) only via *explicit action*

---

## Key Concepts (Week 7)
- Resurfacing: echo · resurfacing · precedent · throughline
- Resurfacing = "today, N years ago" / "the forgotten" (14+ days · sealed excluded)
- Wiki: theme hubs + `index.md` MOC

---

## Code Walk (Week 7)
- `Resurfacer` · `Throughline` · `WikiBuilder` · `WikiSummary`
- Demo: Obsidian graph view (hubs + captures)
- Commits `aabe3b7` · `2a0ffce` · `4e1c9e2` · `0204f06`

**Milestone 5:** one of resurfacing or the wiki

---

## Discussion (Week 7)
- "Why exclude sealed and recent (14 days) from resurfacing?" → **the rumination trap**
- "How did you load *dynamic* content into repeating notifications?" → schedule 7 days ahead · refresh

---

# Week 8
## Learning from Failure and Audit · Presentation

---

## Learning Goals (Week 8)
- *Knowing how to roll back* is also a skill
- The lesson of hitting embedding limits **three times**
- Audit privacy **all the way through**

---

## Two-Way Obsidian — Adopted, Then Reverted (key)
- Adopted `b0d28e6` → **duplicate-creation incident** → reverted `f9fe264`
- Root cause: existing files had **no `id:`**, so all were treated as "new captures" → wholesale duplication
- Lesson: deletion and automation must be **explicit · guarded · dry-run**

---

## Embedding Limits — Confirmed 3 Times
- Theme clustering (S4) → linking (S10) → wiki related-themes (7-3)
- Each time the *ranking was too coarse* to trust → **abandon / deterministic alternative**

> When one signal repeatedly proves untrustworthy, *change the approach.*

---

## Code Walk · Finals (Week 8)
- diff: `git show b0d28e6` ↔ `f9fe264` (the vanished file: `ObsidianSync.swift`)
- Final sweep: fix sealed-content cloud leak (`6b0df7f`)

**Finals:** privacy audit (10%) + project presentation (30%)

---

## Closing

> The real lesson of this app is not code but **judgment** —
> what to automate and what to leave to people,
> what to trust and what to verify,
> when to push and when to roll back.

**That record of judgment lives in docs/ and the commit messages.**

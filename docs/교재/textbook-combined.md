---
title: "Learning iOS App Design with Living Record"
subtitle: "From concept to 67 commits — a project textbook that follows the flow of judgment"
author: "Living Record Project"
date: "2026"
lang: en
toc: true
toc-depth: 2
numbersections: false
documentclass: report
---

# Preface

This book bundles the full journey of one iOS app — **"Living Record (생동하는 기록)"** — from *concept → validation → 67 commits*, organized so you can **study it one step at a time**.

On the surface it is a voice-memo app. But what this book teaches is not code; it is **the flow of judgment** — what to automate vs. leave to the person, what to trust vs. verify, when to push vs. roll back.

## Who is this for
- **Students** learning SwiftUI/SwiftData who want to build *design thinking*.
- **Instructors** running a project-based (PBL) course (includes 8-week plan, rubric, question bank).
- **Self-learners** following a real app's decisions and failures.

> Prerequisite: basic Swift (variables, functions, optionals, closures). SwiftUI/SwiftData are taught in the text.

## Structure (4 Parts)
- **Part I · Main Text (Study Report)** — the whole journey in 9 phases / 25 study units. *The spine of the book.*
- **Part II · Design Source Material** — the concept (decision log), technical validation (spikes), per-phase plans, finished-app user guide. *The primary sources for "why."*
- **Part III · Course Operation (instructor)** — syllabus, grading rubric, instructor answer key.
- **Part IV · Student Materials** — workbook, question bank, portfolio template.

> The **slide deck (Marp)** does not fit a linear book; it lives separately at `en/slides.md` — convert with `marp` or the VS Code Marp extension.

## Reading paths
| Goal | Path |
|---|---|
| **Self-study** | Read Part I (report) phases 0→8, cross-reading the source material in Part II |
| **8-week course (student)** | Fill the Part IV workbook weekly; consult Part I |
| **8-week course (instructor)** | Part III syllabus → weekly Part I units + slides; assess with rubric + question bank |
| **Just the app** | Part II *user guide* |

**How to study:** for each unit, ① read the *why* (decision) first → ② read the related code file line by line → ③ check the commit diff for *what was added* → ④ answer the review questions yourself.

## Making a student edition (instructor)
This combined master edition includes **answers, model answers, and the rubric**. Build a student-facing edition with:
```bash
docs/교재/build.sh en --student     # excludes instructor materials + strips the question-bank answer appendix
```

## See also
- **Source code** — `LivingRecord/` (42 Swift files + widget), `spike/` (24 validation scripts).
- **Commit history** — `git log --reverse --oneline` (S0 scaffolding → final review).
- **Korean originals** — the `docs/` folder.

---

> Read the code, but ask **why it was decided that way** first. That answer is the main text of this book.


\newpage



\newpage

# Part I · Main Text — Study Report

# Project Report — Building the "Living Record" App

> English translation. Korean original: `프로젝트-보고서.md`.

> Student learning project · Written 2026-06-05 · Platform iOS 26+ (Swift/SwiftUI/SwiftData)
> This document lays out the entire journey of one app going from *concept → validation → 67 commits*, organized so you can **study it one piece at a time**.
> Companion design docs: `concept.md` (decision discussions) · `spike-findings.md` (technical validation) · `v1~v4-slices.md` (work plans) · `사용설명서.md` (user manual for the finished app)

---

## 0. What You Learn From This Project

On the surface it looks like a "voice memo app," but the real goal of the lesson is **the flow of thinking by which a single app gets built**.

**Learning objectives**
1. How to slice features into **vertical slices** and grow a *working app* one step at a time.
2. The habit of **validating uncertain technology with spikes (experiments) before writing the real code**.
3. The judgment to use AI (on-device LLMs and embeddings) **only as far as you can trust it**, and to backstop the parts you can't with **deterministic rules**.
4. How to bake **privacy and data ownership** into the design from the very start.
5. **Learning from failure** — the features that got rolled back, the approaches abandoned, the bugs fixed: these are the most valuable teaching material in this project.

**Core value (the question the app tries to answer):** *"What am I going to sustain?"* — an app that gathers scattered thoughts and shows you the *evidence* so that a person can decide what to carry forward and what to let go.

---

## 1. Development Methodology (the principles running through every stage)

The working discipline this project followed. **The same loop repeats at every stage.**

| Principle | Meaning | Where it shows up |
|---|---|---|
| **Vertical slice** | Work in the smallest unit that cuts through one flow from UI to storage | S0~S15; each commit is one *working* piece |
| **Spike first** | Validate uncertain technology with a small experiment before the real implementation | 24 items in `spike/`, `spike-findings.md` |
| **Implement → verify by running → commit** | Not just that it builds, but that it *actually runs*, then commit | Every feat commit |
| **The human decides** | AI goes as far as presenting evidence; the judgment is the user's | sustain/hold/drop, curation |
| **Make the deterministic things deterministic** | Where AI can't be trusted, use rules | Intention-ending gate, date window |
| **Privacy first** | Local by default; the cloud is opt-in and limited to the distilled layer; sealing | Two-stage distillation, sealed folder |
| **Record decisions in docs** | Capture the discussion and rationale for why things were decided that way | concept/spike/slices docs |

> **Learning point:** A *record of good judgment* comes before good code. That's why this app's docs folder matters as much as the code.

---

## 2. Tech Stack (the technologies being studied)

| Area | Technology | Learning keywords |
|---|---|---|
| UI | SwiftUI | declarative views, `@State`/`@Environment`, `NavigationStack`, `TabView` |
| Storage | SwiftData | `@Model`, `@Query`, `ModelContext`, lightweight migration |
| Speech→text | SpeechTranscriber | on-device STT, asset management |
| Local LLM | Foundation Models | `LanguageModelSession`, `@Generable` guided generation, guardrails |
| Embeddings | NLContextualEmbedding | sentence vectors, cosine similarity, **centering (anisotropy correction)** |
| Audio | Accelerate/vDSP | arousal score from RMS·dBFS |
| Cloud | Claude API (URLSession) | opt-in, two-stage distillation, transmission log |
| System integration | App Intents·WidgetKit·UserNotifications | Action Button·Siri·widgets·local notifications |
| Visualization | Swift Charts | Bar/Line/Point marks |
| Encryption | CryptoKit | HKDF key derivation + AES-GCM |
| Concurrency | Swift Concurrency | `async/await`, `@MainActor`, Sendable |

---

## 3. Learning Path (curriculum)

Study the **9 phases and roughly 25 study units** below in order. Each unit follows the format
**[Goal] · [Key concepts] · [Related files] · [Commit] · [Takeaways] · [Review questions]**.

> How to study: ① Read the *why* (goal and decisions) of the unit → ② open the related files and go line by line → ③ look at the commit diff to see *what was added* → ④ answer the review questions on your own.

---

## Phase 0 — Concept and Validation (0 lines of code)

### Unit 0-1. What and Why We're Building (concept)
- **Goal:** Split a vague idea into *decided matters* and *open questions*.
- **Key concepts:** defining the differentiator ("what to sustain"), the privacy hybrid, two-stage distillation, classification = theme (emergent + consolidated).
- **Read:** all of `concept.md`.
- **Takeaway:** *Lock decisions through discussion* before code. When they change, update the doc.
- **Review questions:** What is the single thing that makes this app different from "voice memo + AI summary"? What problem does sealing (봉인) solve?

### Unit 0-2. Spikes — Validate the Hard Parts First
- **Goal:** Measure "Is Apple's on-device AI actually usable *in Korean*?" before the real implementation.
- **Key concepts:** spike (throwaway experiment), hypothesis → measurement → verdict.
- **Read:** `spike-findings.md` ①~⑧, the `spike/` folder (24 items).
- **Key findings:**
  - ① Embeddings: Korean is OK, **but centering preprocessing is mandatory** (without it, everything clusters together).
  - ② STT: the new **SpeechTranscriber** is confirmed (legacy dropped). Real-voice character accuracy 92.8%.
  - ③ FM guardrails: even harmless teacher/child sentences get falsely blocked → a fallback is needed.
  - ⑥ Automatic theme classification: on-device FM is unstable (over-merging ↔ over-splitting) → **best-effort + curation**.
- **Takeaway:** *When uncertain, run a small experiment to get the facts in hand, then design.* A spike is throwaway code, so write it fast.
- **Review questions:** Why was centering needed? How did we *measure* that FM can't be trusted?

---

## Phase 1 — v1: Digital Collection & Archive (S0~S7)

> "Speak and it's saved → it's grouped into themes → a review gets generated." The heart of the app.

### Unit 1-1. S0 Scaffolding — The Ground to Stand On
- **Goal:** SwiftData models + component interfaces + a 4-tab shell. Make it *run* even if the screens are empty.
- **Files:** `Models.swift`, `Interfaces.swift`, `ContentView.swift`, `LivingRecordApp.swift`.
- **Commit:** `04ad787`.
- **Takeaway:** Abstracting boundaries **as protocols** (Transcriber/Embedder…) makes it easy to swap implementations later.
- **Review questions:** What's the difference between `@Model` and a plain class? Why put the interfaces in first?

### Unit 1-2. S1 Capture → Save → List ⭐
- **Goal:** Record → STT → save Capture → show in the list. Text fallback.
- **Key concepts:** fire-and-forget background transcription, automatic `@Query` refresh.
- **Files:** `CaptureView.swift`, `CaptureListView.swift`, `Transcribing.swift`, `AudioRecorder.swift`.
- **Commit:** `f6af896`.
- **Takeaway:** Cut through the most important flow (capture) *first*. Zero friction (no classification UI).
- **Review questions:** Why was UI feedback during recording needed (several UX commits after `f6af896`)?

### Unit 1-3. S2 Energy + Sealing
- **Goal:** Extract an acoustic arousal score, then **immediately discard the audio** (compromise C) + a sealed mode.
- **Key concepts:** vDSP RMS → dBFS → 0~1, privacy (the most sensitive thing, audio, is never accumulated).
- **Files:** `ProsodyAnalyzing.swift`, `Models.swift` (energy/sealed).
- **Commit:** `c12f7db`.
- **Review questions:** Why keep only the score and throw the audio away? Energy is interpreted not as an absolute value but as what?

### Unit 1-4. S3 Obsidian Mirror
- **Goal:** Mirror captures into the vault as markdown, **one-way** (sealed ones go to a separate folder).
- **Key concepts:** security-scoped bookmark (access to folders outside the sandbox), frontmatter + wikilinks.
- **Files:** `VaultStore.swift`, `ObsidianMirroring.swift`.
- **Commits:** `508fa6c`, `31894b1` (sealed separation), `dbc7295` (theme `[[links]]` and re-mirroring).
- **Takeaway:** Give data *ownership* to the user (standard markdown). One-way is safer (→ later proven by the two-way experiment).
- **Review questions:** Why start one-way instead of two-way?

### Unit 1-5. S4 Classification & Consolidation (themes) — *the hardest unit*
- **Goal:** Group similar captures into a Theme + curation (rename, move, merge).
- **Key concepts:** emergent tagging vs. embedding clustering vs. **FM semantic assignment**, label drift.
- **Files:** `Consolidation.swift`, `ThemeAssigning.swift`, `ThemeNaming.swift`, `Embedding.swift`, `Curation.swift`, `ThemeListView.swift`.
- **Commits:** `e0d5ba6`, `b951fdc`, `db468f6`.
- **Takeaway (important):** In spike ⑥, *embedding threshold clustering failed → FM assignment → still unstable on-device* → **conclusion: automation is best-effort, the tidying is done by a human.** Give up on perfect automation in favor of a *correctable design*.
- **Review questions:** Why can't embedding-similarity rankings be trusted? Why is "over-splitting safer than over-merging"?

### Unit 1-6. S5 Daily Digest (local)
- **Goal:** Render the day as an insight-centered narrative (no list dumping) + one question for tomorrow.
- **Files:** `DailyDigest.swift`.
- **Commit:** `db468f6`.
- **Review questions:** What value does connecting the "recent flow" to today provide?

### Unit 1-7. S6 Weekly Review + Cloud ⭐ core value
- **Goal:** Sustain candidates (recurrence · energy · evolving/looping) + a decision [sustain/hold/drop] + **deep cloud synthesis (opt-in)**.
- **Key concepts:** **two-stage distillation** (originals stay local, only the distilled layer goes to the cloud), the consent model (turn on once + sealed exceptions + transmission log).
- **Files:** `WeeklyReview.swift`, `WeeklyReviewView.swift`, `Distillation.swift`, `DeepSynthesizer.swift`, `CloudConsent.swift`.
- **Commits:** `bbbcdc5` (S6a), `8176371` (S6b).
- **Takeaway:** The app is useful *even if you never turn the cloud on once* (cloud = upgrade, not dependency). Enforce the privacy boundary in code.
- **Review questions:** What is the distilled layer? Where is it guaranteed that sealed captures never go to the cloud?

### Unit 1-8. S7 Period Digest (basic form)
- **Goal:** Recurring themes over an arbitrary span + a decision log.
- **Files:** `PeriodReview.swift`, `PeriodReviewView.swift`.
- **Commit:** `3df87d6`.

### Unit 1-9. Real-Device Validation & UX Polish (the most realistic lesson)
- **Goal:** Verify on a *real device with real speech* rather than the simulator, and make the UX feel right in the hand.
- **Files:** `STTAccuracyView.swift`, `FillerCleaner.swift`, `CaptureView.swift`, `ContentView.swift` (tab swipe).
- **Commits:** `0175472`·`55189b5` (CER measurement), `b29db09` (filler words), `16599b5`~`5382b10` (tab swipe), `ca7e901`~`db3e13f` (the struggle to auto-expand the input box).
- **Takeaway:** Fixing the single "auto-expanding input box" took four commits (`ca7e901` → `db3e13f`). *Even a small bit of UX breaks and gets fixed several times on a real device.* A passing build ≠ working.
- **Review questions:** On what basis was 92.8% accuracy judged "good enough"? Why does STT not work in the simulator?

---

## Phase 2 — v2: Completing the Sustain Loop (S8~S11)

> Equipped with 5 signals (recurrence · energy · evolving + **execution · connection · cooling**), close the *decision → practice → feedback* loop. Plan: `v2-slices.md`.

### Unit 2-0. Signal Refinement — Momentum & Energy Trend
- **Goal:** A *recent flow* (rising/cooling) and energy trend instead of a flat average.
- **Commit:** `f111058`. **File:** `WeeklyReview.swift`.
- **Takeaway:** How to extract *a more meaningful signal* from the same data (splitting the window into first and second halves).

### Unit 2-1. S8 Execution Tracking ⭐ — *the triumph of the deterministic gate*
- **Goal:** Detect "I'm going to ~" intentions inside a capture and turn them into a Commitment, then track survival (alive/quiet) afterward.
- **Key concepts:** **FM Bool verdict vs. Korean intention-ending gate.**
- **Files:** `IntentionDetecting.swift`, `Models.swift` (Commitment), `Consolidation.swift`, `WeeklyReview.swift`.
- **Commit:** `321f36a`. **Spike:** ⑦ (`intention_spike*.swift`).
- **Takeaway (core):** In spike ⑦, **FM alone scored 1~6/10 (wildly variable), the intention-ending gate scored 10/10.** → *The verdict comes from deterministic rules; FM only assists with label extraction.* A textbook case of deciding "how far to trust AI" by measurement.
- **Review questions:** What is FM's "yes bias"? Why doesn't the gate get shaken by the environment?

### Unit 2-2. S9 Active Cooling
- **Goal:** Surface a theme that once ran hot and has since cooled, to ask "revive it / let it go?"
- **Files:** `WeeklyReview.swift` (coolingThemes/revive), `WeeklyReviewView.swift`.
- **Commit:** `c4a77ca`.
- **Takeaway:** Sustaining = carrying forward **+ pruning**. *Surface the things that went quiet, too, in a balanced way* (to avoid the rumination trap).

### Unit 2-3. S10 Deeper Connection (→ later withdrawn)
- **Goal:** Close theme pairs + "tie them into one throughline."
- **Commits:** `bc46e2a` (introduced), `f58ab7b`.
- **Takeaway (foreshadowing):** Embedding-based theme connection is rough *here too, and in the wiki too*, and eventually can't be trusted (→ Units 7-3, 8-2).

### Unit 2-4. S11 Making Feedback Visible ⭐ — the loop closes
- **Goal:** The review opens with "the present state of past decisions" (did what you sustained carry on / is what you dropped coming back).
- **Files:** `WeeklyReview.swift` (followUps), `WeeklyReviewView.swift`.
- **Commit:** `58134ba`.
- **Review questions:** Which unit *extended* this one-week feedback into a long-term "precedent"? (→ 6-4)

---

## Phase 3 — v3: Capture Reachability (S12~S14)

> Capture in one action without opening the app. Plan: `v3-slices.md`.

### Unit 3-1. S12 App Intent Capture ⭐ (0 new targets)
- **Goal:** Make "start capture" a system action → Action Button · Siri · AirPods all at once.
- **Key concepts:** `AppIntent`/`openAppWhenRun`/`AppShortcutsProvider`, communicating with SwiftUI via a singleton signal.
- **Files:** `CaptureIntents.swift`, `ContentView.swift`, `CaptureView.swift`.
- **Commit:** `feeb00f`.
- **Takeaway:** The biggest reach at the *lowest cost* (without a new target). Because of `openAppWhenRun`, execution happens in the app process, so the singleton works.

### Unit 3-2. S13 Evening Review Reminder
- **Goal:** A local notification at a daily set time → into capture.
- **Key concepts:** `UNCalendarNotificationTrigger`, permissions, the delegate, **putting dynamic content on a repeating notification** (schedule and refresh 7 days' worth — later combined with resurfacing, 6-3).
- **Files:** `Reminders.swift`.
- **Commit:** `2eb2465`.

### Unit 3-3. S14 Widget (new target — user does this in Xcode)
- **Goal:** One-tap capture from the home screen / lock screen / Control Center.
- **Key concepts:** Widget Extension target, interactive widget `Button(intent:)`, target-membership sharing.
- **Files:** `CaptureWidget*.swift`.
- **Commit:** `6230017`.
- **Takeaway:** A new target is added *by a person in Xcode* (code alone can't do it). The intent is shared by two targets.

---

## Phase 4 — v4: Search (hybrid)

### Unit 4-1. S15 Full-Text + Semantic Search
- **Goal:** Exact containment (full-text) + "similar records" (semantic). Put to use the embeddings that had only been stored since v1.
- **Files:** `Search.swift`, `CaptureListView.swift`.
- **Commit:** `b791ce8`. **Spike:** ⑧ (`search_spike.swift`).
- **Takeaway:** In spike ⑧, semantic-ranking top-1 was 3/6 (rough) → **hybrid** (full-text = primary and trusted, semantic = secondary, estimated, threshold-gated). *Put untrustworthy signals in a supporting role and label them honestly ("estimated").*
- **Review questions:** Why does semantic search run only when you press Return (not on every keystroke)?

---

## Phase 5 — Extra Features (portability · expressiveness)

### Unit 5-1. Encrypted Backup & Restore
- **Goal:** Export/restore (merge) all data as a password-locked file.
- **Key concepts:** CryptoKit **HKDF key derivation + AES-GCM**, Codable DTO serialization, `FileDocument`.
- **Files:** `Backup.swift`. **Commit:** `eebc466`. **Spike:** `backup_spike.swift` (round-trip and wrong-password-failure verification).
- **Review questions:** Why derive a key with HKDF instead of using the password directly as the key? Why include sealed items in the backup?

### Unit 5-2. A Seam for Local LLM Fallback (LocalSynth) — refactoring
- **Goal:** Gather the scattered FM calls into one place to set up an "FM → fallback → nil" seam.
- **Files:** `LocalSynth.swift` (+ unifying 6 call sites). **Commit:** `62b194d`.
- **Takeaway:** Before a new feature (MLX), first make the seam to swap in via a *zero-dependency refactoring*.

### Unit 5-3. Custom Digest Templates
- **Goal:** Set the digest's tone and focus via presets + free-form writing.
- **Files:** `Templates.swift`, `TemplatesView.swift`, `Models.swift` (CustomTemplate). **Commit:** `136ccab`.
- **Takeaway:** Keep the default frame per type and *only append style instructions*, a design that doesn't break the structure.

### Unit 5-4. Visualization Flow Tab + Menu Cleanup
- **Goal:** With Swift Charts, daily captures · energy · theme distribution + settings organized into categories.
- **Files:** `InsightsView.swift`, `SettingsView.swift` (category separation). **Commit:** `ca4d192`.

---

## Phase 6 — "Living Record": the Past Coming Into the Present (the past coming forward)

> *"How can earlier records help the present and future me?"* — turning the app from pull (you go and look) into **push (the past walks up to you)**. The part where it earns its name.

### Unit 6-1. An Echo at the Moment of Capture
- **Goal:** On save, quietly surface "a similar thought from before" (reusing semantic search, sealed excluded).
- **Files:** `CaptureView.swift`. **Commit:** `aabe3b7`.

### Unit 6-2. Resurfacing (Flow tab)
- **Goal:** Once a day a past capture comes up ("on this day N years ago" / "something you'd forgotten for a while").
- **Key concepts:** the choice to *fix it per day* (daySeed), avoiding the rumination trap (14+ days, sealed excluded).
- **Files:** `Resurfacer.swift`, `InsightsView.swift`. **Commit:** `aabe3b7`.

### Unit 6-3. Resurfacing in the Reminder (real push)
- **Goal:** The evening notification carries that day's resurfaced item.
- **Key concepts:** working around repeating-notification limits (schedule 7 days of non-repeating notifications, refresh in the foreground), resolving a ModelContext concurrency warning with `@MainActor`.
- **Files:** `Reminders.swift`, `ContentView.swift`. **Commit:** `dbd806f`.

### Unit 6-4. Helping Decisions With Precedent
- **Goal:** At the decision moment, show that theme's past decisions and outcomes ("30 days ago 'hold' (the 3rd time) → 4 more times after that").
- **Files:** `WeeklyReview.swift` (Precedent). **Commit:** `2a0ffce`.
- **Takeaway:** Extend S11 (one week) into the *whole history of a theme*.

### Unit 6-5. The Long-Breath Throughline
- **Goal:** A theme that runs across multiple periods (30+ days, 3+ weeks) = "the thing you've cared about consistently."
- **Files:** `Throughline.swift`, `InsightsView.swift`. **Commit:** `4e1c9e2`.

---

## Phase 7 — LLM Wiki (the vault as a knowledge base)

> Turn scattered notes into a wiki an LLM can navigate and read. Discussion decision: a general structure + cloud opt-in summaries. **One-way** (see 8-1 below).

### Unit 7-1. Slice A — Structure (hub + index)
- **Goal:** A hub per theme (`Themes/<theme>.md`: meta + decisions + records) + an `index.md` MOC + strengthened frontmatter (id reintroduced).
- **Files:** `WikiBuilder.swift`, `ObsidianMirroring.swift`, update hooks (`Consolidation`/`Curation`). **Commit:** `0204f06`.
- **Key concepts:** idempotent overwrite, `safeName` for filenames and links, automatic update hooks.

### Unit 7-2. Slice B — Cloud "At a Glance"
- **Goal:** A summary at the top of each hub via Claude (distilled, sealed excluded, transmission log, manual refresh only).
- **Files:** `WikiSummary.swift`, `Models.swift` (Theme.summary). **Commit:** `1472fa4`.
- **Takeaway:** Expensive work (N cloud calls) happens *only via an explicit action*. The structure is free and automatic; the summary is opt-in.

### Unit 7-3. Removing the Wiki's "Related Themes" — *an honest retreat*
- **Goal:** Embedding-similarity links kept being wrong → even threshold tuning (0.15 → 0.30) couldn't catch it, so it was **removed**.
- **Commits:** `4ee6710` (tuning), `f0b5001` (removal).
- **Takeaway:** *Better to show nothing than to show something wrong.* When tweaking numbers isn't the answer, change the approach or drop it. (Alternative: a deterministic "appeared together on the same day" signal — not adopted.)

---

## Phase 8 — Learning From Failure & Review (the highlight of this project)

### Unit 8-1. Two-Way Obsidian — Introduced and Then Withdrawn
- **What happened:** Two-way sync (import, delete, auto-sync) was introduced (`b0d28e6`) → a **duplication incident** → withdrawn (`f9fe264`).
- **Root cause:** The existing mirrored `.md` files had no `id:`, so the import turned *all of them into new captures*, **duplicating the whole library.**
- **Takeaways (important):**
  1. **Deletion and auto-sync are dangerous.** Explicit, with safeguards and a dry-run, is the baseline.
  2. Don't turn id-less or ambiguous files into "new" ones → use a separate inbox and hash matching.
  3. *Knowing how to roll back* is also a skill. Withdraw cleanly (down to leftover comments).
- **Read:** compare the diff of commit `b0d28e6` (introduced) ↔ `f9fe264` (withdrawn).
- **Review questions:** Why wasn't a "re-export everything first" notice enough on its own?

### Unit 8-2. The Limits of Embeddings — a Lesson Confirmed Three Times
- **What happened:** Theme clustering (S4) → theme connection (S10) → wiki related themes (7-3): **all three times the embedding ranking was too rough** to trust.
- **Takeaway:** When you hit a technology's limit *repeatedly*, abandon that signal itself or move to a deterministic alternative. "Embeddings = a cure-all" is false.

### Unit 8-3. Full Review — Code Review and Privacy
- **What happened:** A late-stage code review found a **leak where the period digest was sending sealed theme names to the cloud**, fixed it + removed dead code + got to 0 warnings.
- **Files:** `PeriodReview.swift` (`!sealed` filter), `Interfaces.swift` (stub removal). **Commit:** `6b0df7f`.
- **Takeaway:** *Verify privacy invariants all the way to the end.* Make "does every path to the cloud drop sealed items?" a checklist.
- **Review questions:** The daily/weekly local digests *include* sealed items — why was that left as is? (the difference between cloud and local)

---

## 4. Data Model (the whole picture)

```
Capture(포착) ──N:1── Theme(주제) ──1:N── Decision(결정)
   │ text, createdAt, energy?, sealed,        │ name, state, summary?(wiki)
   │ embedding(512d)?, sortIndex               └ Commitment(다짐): themeID snapshot
   └ if sealed, excluded from cloud and gallery

Digest(정리: daily/weekly/period)   Transmission(cloud transmission log)   CustomTemplate(user template)
```
> SwiftData **lightweight migration**: adding fields/models is automatic (Commitment · CustomTemplate · summary · mirrored, etc., all came in that way).

---

## 5. The Spike Collection (the evidence behind validation-first)

The core ones among the 24 in `spike/`. **When studying, run the spikes yourself with `swift <file>`.**

| Spike | What it validated | Conclusion |
|---|---|---|
| `embed_spike3` | Korean embeddings + centering | centering mandatory |
| `stt_new` | the new SpeechTranscriber | adopted (legacy dropped) |
| `fm_spike2` | FM guardrails | harmless sentences falsely blocked |
| `binary_spike`/`fm_guided` | FM theme assignment | macOS OK, device unstable |
| `intention_spike2` | intention detection A/B/C | ending gate 10/10 |
| `search_spike` | semantic search quality | rough → hybrid |
| `backup_spike` | encryption round-trip | correct password matches / wrong fails |
| `obsidian_parse_spike` | (for two-way) parser | 4/4 — but the feature was withdrawn |

---

## 6. Student Assignments (suggested)

**A. Build along (required)** — Implement S0~S4 yourself. From capture → save → list → grouping into themes.

**B. Reproduce the spikes** — Run `embed_spike3` and `intention_spike2`, reproduce the results, and write one paragraph on *why that conclusion*.

**C. Judgment analysis (essay)** — Pick one of the following and address "what was decided, why, how, and what would I do?":
- Why the ending gate was chosen over an FM Bool (Unit 2-1)
- The withdrawal of two-way Obsidian (Unit 8-1)
- The removal of embedding-based related themes (Unit 7-3)

**D. Extension (choose one)** — Safely retry an unimplemented/withdrawn item:
- A deterministic "appeared together on the same day" related-themes signal
- Threshold tuning (cooling · commitment · momentum) against real data
- iCloud sync or the actual MLX fallback

**E. Privacy audit** — Trace "every path by which a sealed item could leave the device" through the code and tabulate it. (Hint: cloud vs. vault iCloud sync.)

---

## 7. Evaluation Rubric (example)

| Item | Evaluation point |
|---|---|
| Vertical slice | Is each stage a *working* minimal unit? |
| Validation habit | Were uncertain parts confirmed via spike/execution? |
| Rationale for judgment | Was the "why" left in docs / commit messages? |
| Privacy | Were sensitive-data boundaries enforced in code? |
| Failure handling | When stuck, can you *narrow scope or roll back*? |

---

## 8. Appendix

### 8-1. Companion Reading
- `concept.md` — design discussion and decisions (read first)
- `spike-findings.md` — technical validation results (①~⑧)
- `v1-slices.md`·`v2-slices.md`·`v3-slices.md`·`v4-slices.md` — stage-by-stage plans
- `사용설명서.md` — user manual for the finished app

### 8-2. Source File Map (42 + 3 widget)
- **Input:** CaptureView, AudioRecorder, Transcribing, ProsodyAnalyzing, FillerCleaner, IntentionDetecting, CaptureIntents
- **Storage/models:** Models, VaultStore, Backup, DateFilter
- **Classification/consolidation:** Consolidation, ThemeAssigning, ThemeNaming, Embedding, Curation, Search
- **Digest/signals:** DailyDigest, WeeklyReview(+View), PeriodReview(+View), Distillation, DeepSynthesizer, CloudConsent, LocalSynth, Resurfacer, Throughline, Templates(+View)
- **Wiki:** ObsidianMirroring, WikiBuilder, WikiSummary
- **Screens:** ContentView, CaptureListView, ThemeListView, DigestView, InsightsView, SettingsView, STTAccuracyView
- **System:** Reminders, LivingRecordApp, Interfaces, CaptureWidget*

### 8-3. Glossary
- **Vertical slice**: the smallest unit of work that cuts through one flow from UI to storage.
- **Spike**: experimental code written quickly and thrown away to remove uncertainty.
- **Sealed (봉인)**: a capture that never leaves the device (excluded from cloud and gallery, kept in a separate folder).
- **Two-stage distillation**: original → (local abstraction) → distilled layer → (opt-in) cloud.
- **Centering**: correcting the phenomenon where embeddings cluster to one side (anisotropy) by subtracting the mean.
- **Best-effort + curation**: automation is the starting point; the tidying is done by a human.
- **Deterministic gate**: judging with rules (e.g., Korean grammatical endings) instead of AI — not shaken by the environment.

### 8-4. All 67 Commits
Check with `git log --reverse --oneline`. From S0 (`04ad787`) → full review (`6b0df7f`).

---

> **Closing:** The real lesson of this app is not the code but the *judgment* — what to automate and what to leave to a person, what to trust and what to verify, when to push and when to roll back. The record of that judgment lives in docs/ and the commit messages. Read the code, but first ask **why it was decided that way**.


\newpage



\newpage

# Part II · Design Source Material

# Thought Capture & Digest App — Concept (Discussion Record)

> English translation. Korean original: `concept.md`.

> Written: 2026-06-04 · Updated: 2026-06-04 · Status: **v1 implementation complete (S0~S7, committed to git)** — slices in docs/v1-slices.md
> App name: **Living Record** (생동하는 기록)
> This document records what was *decided* and what remains *open* from design discussions. When a decision changes, update it.

---

## 0. One-Line Definition

> **An app that collects the thoughts you pour out in speech, stored locally, where AI analyzes, classifies, and digests them into "processed writing" (daily/weekly/period templates), ultimately helping you with "what am I going to sustain."**

## 1. Core Loop

```
capture (speech) → store (text, local) → AI analysis/classification → process (templates: daily/weekly/period) → reflect/decide (what to sustain?)
                                                                                ↘ the decision feeds back into the next reflection
```

## 2. Differentiator / Moat

- The one thing that sets it apart from the common "voice memo + AI summary": **it helps you with "what am I going to sustain going forward."**
- The real moat: because it's **voice**, it can read the *grain (energy) of your voice* — something a text journaling app cannot do.
- The machine **does not pass judgment.** It presents evidence → **the person decides** → that decision becomes data that makes the next round smarter.

---

## 3. Decided Items ✅

### 3-1. Privacy: Hybrid
- **Capture and storage are local**, **only processing optionally goes to the cloud**.
- Principle: **the app must be useful even if you never turn the cloud on once** (the cloud is an upgrade, not a dependency).
  - Local handles: capture (STT) + storage + classification/tagging/consolidation + **light daily digest**
  - Cloud handles: **deep synthesis** for weekly/period (trends, recurrence, connections, sustain suggestions)

### 3-2. Two-Stage Distillation (the original is sealed locally)
```
[local] verbatim original ──local LLM──▶ distilled layer (themes, summary, keywords)
                                            └─(only when turned on)──▶ [cloud] deep synthesis
```
- **The raw speech (the original) never leaves the device.** What goes to the cloud is only the *distilled layer* that local has abstracted.

### 3-3. Cloud Consent Model: "Turn on once / seal exceptions / after-the-fact review" (not asked every time)
1. **Set once** — a "deep synthesis: allow cloud" switch (default OFF; turning it on is a conscious, one-time act).
2. **Seal (exception)** — if something is *truly private* when you capture it, **seal** it right there. A sealed capture/theme never goes to the cloud even if the global switch is on. (Absorbed into the capture trigger — see 3-4 below.)
3. **Transmission log** — you can always see "when and what went out to the cloud" (after-the-fact audit instead of pre-emptive blocking).

### 3-4. Capture — Zero-Friction
- **Principle: capture = one action, zero decisions.** Speak and you're done. Classification, tagging, and digesting are all done later by AI.
  - Capture screen = record button + text field + that's it. **No classification UI.**
- **Primary device: phone (on the move) is #1** → mobile-first. **Platform: iOS first** (Android later).
- **Trigger (v1): one tap on a home/lock-screen widget**. Action button / long-press on AirPods are a *later upgrade*.
  - ~~Always listening~~ rejected — privacy + capture is an *intentional* act.
  - **Seal = absorbed into the trigger**: tap = normal / long-press = seal (both one gesture). Sealing is also possible after the fact from the log.
- **Right after speaking**: store immediately (fire-and-forget). STT, prosody, and audio disposal happen in the **background**. Confirmation is a quiet signal (vibration, etc.).
- **Text fallback**: voice first, but text is always available (for meetings, public places).

### 3-5. Classification Scheme — emergent + consolidation
- **Here, classification = not "putting into folders" but "grouping by Theme"** = the foundation of the recurrence signal.
- Fixed framework ✗ (can't predict thought categories in advance + kills discovery + adds capture friction). Pure emergent also ✗ (label drift breaks the recurrence count).
- **Answer: AI freely assigns themes → merge similar ones by embedding similarity into stable Themes.** Growing from below + self-merging. **Locally.**
- **A single axis (theme).** The grain of type/emotion is carried by the signals (looping/evolving/energy).
- **User curation included in v1**: rename, merge, split, and pin themes. (AI consolidation is imperfect + recurrence accuracy hinges on theme boundaries.) Corrections are also feedback data.

### 3-6. Signals That Detect "What to Sustain" (5 total)
1. **Recurrence** — *evolving recurrence* (the thought grows the more you speak it = alive) vs. *looping recurrence* (repeating the same words = stuck/worried). **This distinction is the app's intelligence.**
2. **Energy** — the excitement/engagement read from the grain of the voice (the moat).
3. **Execution tracking** — did a "I'll do it" survive later?
4. **Connection** — the moment distant thoughts converge into one strand (inspiration).
5. **Cooling** — a theme that was hot and then cooled. It must also notice *what to fold* (sustaining = continuing + pruning).

### 3-7. v1 Signal Scope
- **v1: recurrence (evolving/looping) + energy** only. (Works right away even with little data.)
- Next step: execution tracking · connection · cooling (these only become meaningful once data accumulates).

### 3-8. Energy Source: Compromise C (only a score at the moment of capture, audio discarded)
```
spoke → [moment of capture, local]
         ├─ extract text via STT ──────────▶ store
         ├─ extract prosody summary values (1~2 energy scores) ─▶ store
         └─ discard original audio immediately ✗
```
- Voice-based energy (the moat) is **secured**, the most sensitive thing — the audio — is **not accumulated** (privacy preserved), with no storage burden.
- Language-based signals (positive/negative direction) are layered on from the text → **voice (arousal) + language (direction)**.

### 3-9. Templates — The Altitude Ladder
The three templates are not "the same summary in 3 sizes" but **altitudes with different purposes**. The lower feeds the higher (daily → weekly → period).

- **📅 Daily** — *close out today, seed for tomorrow* (local, lightweight). Per-theme records + "thoughts that appeared for the first time / appeared again" + an energy snapshot + 1 question that carries into tomorrow. Not decision-making.
- **📆 Weekly** — *pattern discovery + first decision request* (the first real synthesis, cloud optional). Recurrence (evolving/looping) + energy badges + **a "sustain candidate" view + decision prompts [sustain][hold][fold]** ← where the human decision loop switches on.
- **🗓️ Period** — *long-breath direction and sustaining* (built on accumulated decisions). The strands that endured + the flow of decisions. v1 is a *light form* (recurrence over long spans + a decision log); it gets richer once execution tracking and cooling are added.
- **Format = both narrative writing and action elements.** "Processed *writing*" (a reflection the AI wrote in sentences) + sustain-candidate cards and decision buttons. Not just a dashboard but *writing that gets read*.

### 3-10. v1 Template Scope
- **Daily + weekly fully in v1** (daily = habit, weekly = core value = insight + decision).
- **Period is a basic form in v1** (recurrence over long spans + a decision log), getting richer in follow-ups.

### 3-11. Local Stack — All-in on iOS 26+ Apple On-Device
- **Foundation: iOS 26+.** Nearly 100% Apple on-device → zero bundled models, the best privacy story, minimal maintenance and dependencies. (Accepting non-support for older devices.)
- **Components (#1 choice / replacement alternative)**:

  | Need | #1 (Apple) | Alternative (if quality falls short) |
  |------|-------------|-------------------|
  | STT | **SpeechTranscriber** (✅ verified, dropped legacy SFSpeechRecognizer) | WhisperKit (CoreML Whisper) |
  | Local LLM (tagging, daily digest) | **Foundation Models** ~3B | MLX + small open model |
  | prosody | **Accelerate/vDSP** directly | — |
  | embeddings (theme consolidation) | **NLContextualEmbedding** | multilingual sentence-transformer (CoreML) |

- **STT decision**: start with Apple SpeechTranscriber, with **room to swap to WhisperKit** depending on Korean quality.
- **The local LLM can be small**: since deep synthesis was offloaded to the cloud, local only does light work → the sweet spot for small models.
- **prosody = interpretable acoustic features** (volume, pitch variation, speech rate → arousal score). **Not a black-box emotion AI.** Arousal (excitement) only; direction (positive/negative) is handled by language. As a **relative value against my own baseline**, a soft signal.
- **Cross-cutting principle — boundary abstraction** (like feedback-app's storage.ts): wrap with `Transcriber` / `LocalSynthesizer` / `ProsodyAnalyzer` / `Embedder` interfaces so each component is swappable.
- ⚠️ **Early-implementation spike required**: directly verify the **Korean on-device quality** of the Apple APIs, then finalize #1 / alternative. (Results in `docs/spike-findings.md`.)
- ✅ **Embeddings verified**: NLContextualEmbedding is OK for Korean, but **centering (anisotropy correction) preprocessing is mandatory**. No sentence-transformer bundle needed.
- ✅ **STT verification complete**: SpeechTranscriber on-device for Korean. **Real-device real-voice character accuracy ~92.8%** → finalized for v1, WhisperKit unnecessary. (Minor errors at the level of filler '음→응'.)
- 🛑 **Foundation Models guardrail risk**: some harmless teacher/child sentences are falsely blocked. **The local LLM must be doubled up as "Apple FM + MLX open-model fallback"** (to avoid guardrails). Design a graceful fallback on block. (MLX fallback PoC ✅ — spike-findings ④.)

### 3-12. Cloud Provider · Storage (finalized)
- **Deep-synthesis cloud = Claude (Anthropic)**: excellent Korean synthesis/reasoning + API does not train by default. Abstracted behind a `DeepSynthesizer` interface (swappable). **Only the distilled layer, only when opted in**, is transmitted.
- **Local primary storage = SwiftData**: Capture/Theme/Digest/Decision + embeddings (512d blob).
- **Sync = single-device first** (v1). iCloud is opt-in, a follow-up.
- **Backup = user-driven encrypted export** (file).
- **Obsidian dual storage (user requirement)**: **mirror captures and digests simultaneously as markdown into an Obsidian vault** → user-owned, portable, leveraging the graph. Same philosophy as the vibe-code notes.
  - Format: frontmatter (date, energy, seal, etc.) + body. **Theme = `[[wikilink]]`** → visualizes thought-threads in the Obsidian graph.
  - Direction (proposal): **one-way (app → Obsidian)** for v1. Two-way (reflecting back) makes conflict handling complex → follow-up.
  - Seal handling (changed): **sealed captures are mirrored separately into an Obsidian '봉인' folder** (normal ones go to Captures/). They are **still excluded from cloud deep synthesis** (filtered in Distillation). However, if the vault is iCloud-synced, sealed items leave the device too → a user choice, made explicit.
  - ⚠️ Privacy: if the vault is iCloud-synced, plaintext records leave the device → a user choice, but make it explicit.

---

## 4. Data Model Strawman (draft)

```
Capture   : original (text), timestamp, energy score (prosody), emotion direction?, sealed?, theme candidate tags[]
Theme     : a consolidated strand (emergent + merged). Captures gather into it. State (active/looping/cooling/decided).
            User curation (rename, merge, split, pin) possible.
Digest    : template (daily/weekly/period), span, narrative writing + action elements, generation location (local/cloud), source Captures[]
Decision  : sustain/hold/fold on a Theme + reason + timestamp  (→ feeds back into the next reflection)
```
- Future extensions (execution/connection/cooling) just leave room and aren't built now (YAGNI).
- v1 starts with a vertical slice cutting through the single strand of **Capture → consolidation (Theme) → Digest (daily/weekly)**.

### Output Example — the "sustain candidate" view inside a weekly/period digest
```
🌱 "Leave class reflections in writing"   evolving↑ energy high      [sustain][hold][fold]
🔁 "Stress from dealing with parents"     looping energy high (negative) → needs 'release'  [sustain][hold][fold]
❄️ "YouTube channel idea"                 cooling for 3 weeks (once hot)  [revive][fold]   ← cooling is post-v1
```

---

## 5. Open Items 🔜

- **Obsidian mirror details** — finalize one-way / seal-exclusion (adopt the proposal?), folder structure, file-naming rules, iOS vault access (security-scoped bookmark).
- **Template selection UX** — beyond the 3 built-in for v1, are custom templates a follow-up?
- **Measure STT WER on real human voice** (actual usage recordings, not synthetic).
- **App name.**

## 6. Pitfalls to Watch For (raised in discussion)

- ⚠️ Rumination trap: high recurrence + energy could be *anxiety* → evolving/looping distinction + emotion direction too.
- ⚠️ Self-fulfilling loop: if the app keeps surfacing X, you end up speaking X more → also surface the strands that have gone quiet, in a balanced way.
- ⚠️ The place where the cloud is needed most (deep synthesis) is the most private place → split it via two-stage distillation.
- ⚠️ Label drift (naming the same theme differently) → prevent it via consolidation (embedding merge) + user curation.

---

## 7. Candidates for the Next Discussion
1. **Storage/sync/backup** strategy (single-device first? export?)
2. **Cloud provider** selection (model for deep synthesis, retention policy)
3. **Early-implementation spike**: verify Apple on-device Korean quality (STT, embeddings, LLM)
4. (Implementation phase) Break v1 into vertical slices → **done: `docs/v1-slices.md`** (S0~S7). Starting point S0 scaffolding → S1 capture.


\newpage

# Spike Findings — Korean On-Device Quality Validation

> English translation. Korean original: `spike-findings.md`.

> Environment: macOS 26.6, Xcode 26.5, Swift 6.3.2 (CLI run directly on Mac)
> Goal: Empirically test whether the first-choice Apple on-device tier of the concept.md §3-11 local stack is usable *in Korean*.
> Spike code: `spike/` (embed_spike*.swift, etc.)

## ① Embedding (theme consolidation) — ✅ Pass (conditional)

- `NLEmbedding.wordEmbedding(for: .korean)` → **nil (no Korean word embedding in the OS).**
- `NLContextualEmbedding(language: .korean)` → **loads successfully.** Assets already installed (no download needed), 512-dim.
- Raw cosine on mean-pooled vectors is 0.61~0.78, so **everything clusters together (anisotropy)** → separation between same/different themes is only 0.103, with rankings tangled.
- Applying **centering (subtract the overall centroid, then renormalize)** raises separation to **0.380** → clusters become distinct.

**Verdict:** Theme consolidation **is feasible** with Apple's on-device Korean embedding. **However, centering (anisotropy correction) preprocessing is essential.**
→ No need to **bundle** a multilingual sentence-transformer in v1. Adopt Apple native.

**Implementation notes:**
- Sentence vector = mean pooling of token vectors → **subtract centroid + L2 normalize**, then cosine.
- The centroid is more stable the more it is estimated from a sufficient background corpus (accumulated captures). Early on the sample is small, so keep thresholds conservative.
- Theme-merge thresholds need tuning against real data.

## ② STT (Korean transcription) — 🟡 Partial (architecture OK, quality unmeasured)

- `SFSpeechRecognizer(locale: ko-KR)` creates OK. **Permission granted** in the CLI (raw=3).
- ⭐ **`supportsOnDeviceRecognition == true`** — **confirmed on-device support** for Korean (core to the local-first design).
- However, `recognitionTask` **never emits a result callback** in a headless CLI (both aiff and wav, 55s wait, no error either).
  - Suspected cause: incomplete on-device model provisioning + `requiresOnDeviceRecognition=true` going unresponsive, or a need for an app run loop / bundle context.
- Test assets: `spike/cap.aiff`, `cap.wav` (synthesized with say -v Yuna, 7.5s).

### ②-new New SpeechTranscriber/SpeechAnalyzer — ✅ Pass (works even in CLI)
- `SpeechTranscriber`/`SpeechAnalyzer`/`AssetInventory` symbols exist. ko-KR **supported=true, installed=true**, asset auto-install OK.
- `analyzer.analyzeSequence(from: AVAudioFile)` + `transcriber.results` successfully transcribed the file (even in a headless CLI).
- Result: words **100% correct** (the only difference being one comma), character accuracy (CER) **97.7%** (cap.wav, TTS synthesized).
- **Verdict:** **Definitively adopt** the new SpeechTranscriber for Korean on-device STT. Drop the legacy SFSpeechRecognizer.
- ⚠️ Caveat: Based on TTS synthesized speech. Real human speech is harder → measured on a real device (below).

### ②-real Real-device, real-speech measurement — ✅ SpeechTranscriber confirmed
- Using the in-app measurement tool (STTAccuracyView), 6 sentences of natural speech on a real device → **average character accuracy 92.8%** (CER, excluding whitespace).
- Example error: the filler '음'→'응' (minor; fillers are close to noise). Capture is editable and gist-focused, so 92.8% is sufficient.
- **Verdict: SpeechTranscriber confirmed for v1. WhisperKit not needed** (consider the §3-11 alternative only if higher accuracy is required).

## ③ Foundation Models (Korean tagging/summarization) — 🟡 Works but guardrail risk (important)

- `SystemLanguageModel.default.availability == .available`. **Works** in the CLI.
- Korean tagging/summarization **quality is good** (most neutral, student-, and children-related sentences produce plausible tags + summaries).
- 🛑 **However, guardrail false positives**: some harmless teacher sentences are blocked with `guardrailViolation("May contain unsafe content")`.
  - Blocked: "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있는 걸 보고, 이 방식을 계속 밀고 가야겠다…" ("Watching the children's eyes come alive as they presented in class today, I think I should keep pushing this approach…")
  - Passed: "우리 반 아이들이 글쓰기를 어려워해서…" ("The kids in my class struggle with writing…"), "학생들과 텃밭을…" ("A garden with my students…"), and neutral sentences.
  - → It's not the word "아이들" (children) itself, but **a specific combination of expressions misread out of context**. Unpredictable and erratic.
- **Verdict / design impact (important):** In a private reflection app for teachers, **intermittent silent refusal of harmless captures = a trust-collapse risk.**
  - Foundation Models **must not be relied on alone.** The §3-11 **MLX open-model alternative is needed for guardrail avoidance (not for quality).**
  - Or: on a block, **graceful fallback** (retry with an alternative model / manual user tagging / placeholder). Apple's guardrail cannot be turned off by the user.
  - Cloud deep synthesis also has guardrails, but a two-stage distillation (transmitting an abstraction) may reduce false positives.

## ④ MLX open-model fallback PoC — ✅ Pass

- The machine had **no** ollama/llama.cpp/mlx_lm → installed via `pip install mlx-lm` (0.31.3), using Qwen2.5-1.5B-Instruct-4bit.
- It processed **the very sentence FM had blocked** ("…아이들이 발표할 때 눈빛이 살아있는…") normally:
  tags=academics·presentation, summary=reasonable. No guardrail.
- Performance: on-device ~100 tok/s, **peak 1.0GB**. 1.5B is "usable" for Korean tagging (the academics tag is imprecise).
- **Verdict:** When the FM guardrail blocks, an **MLX open-model fallback is feasible** (fully on-device). Consider a 3B-class model if more quality is desired.
- The actual app will bundle mlx-swift (Swift). (The PoC used python mlx-lm for a quick check.)

## ⑤ Embedding consolidation (clustering) PoC — ✅ Pass

- Centered Korean embeddings + online greedy clustering (threshold-based).
- **Threshold range −0.10 ~ 0.0 → exactly 3 pure clusters** (class/food/exercise). Too low and they mix (over-merging); too high and they over-split.
- **Verdict:** The consolidation algorithm is valid. Default threshold ~0.0, with **conservative (pure) clustering** to avoid over-merging → handle over-splitting via a "merge" curation step.
- Key point: Consolidation is possible **with embeddings alone** (no LLM needed). The LLM is only for *naming* themes.
- spike: `cluster_spike.swift`.

## ⑥ Theme assignment: embedding threshold ❌ → FM semantic assignment ✅ (important pivot)

- **The embedding threshold fundamentally fails**: a pair that should merge (class1·2 = 0.209) < a pair that should not merge (hiking·food = 0.353).
  The similarity ordering is inverted, so **no single threshold can satisfy both**. Mean-pooled NLContextualEmbedding is too coarse to distinguish diverse Korean themes.
- **Assigning via FM structured output (guided generation) → 6/6 correct**: a clean list of theme names + `@Generable` forcing a number (or -1).
  hiking→new theme, pasta→food, parent-teacher conference·sports day→class — all correct.
- spike: `online_spike` (reproduces the threshold failure), `fm_guided_spike` (6/6, macOS).

### ⑥-b Device validation: on-device FM classification is unstable → confirmed as best-effort + curation
- **index selection** (-1 if none): when there is one theme, the on-device FM **skews everything to idx=0** (a bias toward preferring a valid number) → over-merging (everything in one theme).
- Replaced with a **Bool "same field?"**: this time on the device it **over-splits** ("rethinking after class ends" doesn't attach to "class" but becomes a new theme). Device behavior **differs** from the macOS spike (5/6).
- **Conclusion (important):** On-device FM auto-clustering of short Korean swings between over-merging↔over-splitting and **varies by environment, so it cannot be made 100% via prompting**. Cannot be tuned without device access.
- **Final design (Option A):** Auto-classification is **conservative best-effort** (Bool judgment; over-splitting is safer than over-merging — it can be tidied by merging) + **strong curation** (rename·merge·move/extract captures). Auto is the starting point; the user tidies up in 2 taps.
- Room for future improvement: embedding top-K candidate reduction, batch "tidy-up suggestions" (FM proposes merges → user approves), real-device prompt tuning.

## ⑦ (v2 S8) Automatic intention detection: FM ❌ → deterministic ending-marker gate ✅

- Compared three strategies on the same 10 sentences (5 intention / 5 observation·emotion):
  - **A (FM `@Generable` Bool only)**: fluctuates per run — once 6/10, the next run 1/10. It over-detects observations as intentions, then sometimes drops obvious intentions ("해봐야겠다" = "I should try this") to false — **unstable in both directions** (akin to the yes-skew in ⑥-b).
  - **B (deterministic Korean intention ending-marker gate only)**: **10/10.** Markers = substrings such as `겠`(will/intend) / `해야`(must) / `하자`(let's) / `해보자`(let's try) / `볼까`(shall I) / `봐야지`(I'll have to) / `야지`(I'll) / `려고`(intending to) / `을래·를래`(I want to) / `시작하`(start) / `다짐`(resolve), etc.
  - **C (gate AND FM)**: 6/10 — FM drags down the perfect gate.
- **Verdict:** **Intention judgment/detection uses the deterministic ending-marker gate**; FM is best-effort *for intention-phrase (label) extraction only* (fall back to capture text on failure/empty). Zero guardrail, latency, or bundle cost. Reaffirms the v1 ⑥-b lesson ("do deterministically what can be done deterministically; FM is auxiliary").
- ⚠️ Caveat: Based on 10 hand-picked sentences. The ending-marker gate can rarely over-fire ("좋겠다" = a wish) — allow it conservatively (the user can ignore it; safer than FM chaos). Refine the marker set against real data.
- spike: `intention_spike.swift` (FM alone), `intention_spike2.swift` (A/B/C comparison).

## ⑧ (v4 search) Semantic search quality: coarse → 'auxiliary' in a hybrid

- Centered-cosine ranking of 6 questions over a corpus of 12 (6 themes): **top-1 3/6, top-3 5/6**.
- Good matches: "사람들과의 관계" ("relationships with people")→relationships (0.47), "꾸준히 글 쓰기" ("writing consistently")→writing (0.35). Misses: "건강을 위해 운동하기" ("exercising for health")→writing (top), "돈 관리" ("money management")→class (top). Same limitation as ⑥ (inverted similarity ordering).
- **Verdict:** Semantic search cannot be trusted as a precise ranking → **hybrid confirmed**: full-text (exact contains) = primary·trusted, semantic = "similar records (estimated)" auxiliary. To cut noise, use a similarity threshold (~0.30) + only a small top set, labeled "estimated."
- spike: `search_spike.swift`.

## Overall conclusions
- Embedding ✅ (centering essential) · STT ✅ (new SpeechTranscriber, 97.7% on clean speech) · FM 🟡 (works but needs a guardrail fallback) · MLX fallback ✅ (no guardrail).
- **Local stack validation complete**: STT = SpeechTranscriber confirmed, embedding = NLContextualEmbedding + centering, local LLM = "Apple FM + MLX fallback" redundancy.
- Remaining validation: real human-speech WER (real-use recordings), fallback model size (1.5B vs 3B) tuning.


\newpage

# Living Record — v1 Vertical Slice Plan

> English translation. Korean original: `v1-slices.md`.

> Written: 2026-06-04 · Basis: `concept.md` (decisions), `spike-findings.md` (verification)
> Platform: iOS 26+ (Swift/SwiftUI, SwiftData). Spikes verified as a macOS CLI → ported to the app implementation.

## Workflow (same as feedback-app)
- **Vertical slice**: drive one flow end-to-end from UI to storage. Each slice = **implement → verify by actually running → commit**.
- Move on only **after the previous slice actually runs**. If stuck, narrow the scope further.
- Slice tag in commit messages: `feat(S1): capture→store→list`.
- Components are **abstracted behind interfaces** (Transcriber/LocalSynthesizer/ProsodyAnalyzer/Embedder/DeepSynthesizer/ObsidianMirror).

## Slices

### S0 · Scaffolding
- **Goal**: A floor to stand on. Xcode iOS 26+ project, SwiftData models (Capture/Theme/Digest/Decision), 6 interfaces (empty implementations), app shell and tabs.
- **Verification**: Builds and runs, blank screen appears. Model migration OK.
- **Depends on**: None.

### S1 · Capture → Store → List  ⭐ Core (zero friction)
- **Goal**: "Speak and it's saved and shows up in the list." Record button → SpeechTranscriber transcription → store Capture (text) in SwiftData → display in list. Text fallback.
- **Includes**: Capture screen (record + text field, **no classification UI**), background transcription (fire-and-forget), list.
- **Verification**: Korean speech → text stored and displayed. Persists even if the app is killed. (First WER measurement on real human voice.)
- **Depends on**: S0. **Spike reuse**: `stt_new.swift` (SpeechTranscriber).

### S2 · Energy + Seal
- **Goal**: At the moment of capture, extract a prosody energy score (vDSP) + **discard the audio** (compromise C). Sealed (press-and-hold) capture.
- **Includes**: ProsodyAnalyzer implementation (volume · pitch variation · speech rate → arousal), energy and seal fields on Capture, energy display in the list.
- **Verification**: Score difference between excited speech vs. flat speech. No audio file left behind. Seal indicator.
- **Depends on**: S1.

### S3 · Obsidian Mirror
- **Goal**: **One-way mirror** captures into an Obsidian vault as markdown. frontmatter + body. **Sealed entries excluded.**
- **Includes**: ObsidianMirror implementation, vault folder selection (security-scoped bookmark), filename and folder conventions.
- **Verification**: On capture, a .md file is created and opens in Obsidian. Sealed entries are not mirrored.
- **Depends on**: S1 (+S2 seal).

### S4 · Classification & Consolidation (Theme)
- **Goal**: Group Captures into Themes via emergent tagging + embedding consolidation. Curation (rename · merge · split).
- **Includes**: LocalSynthesizer (Foundation Models + **MLX fallback**: when blocked by guardrails), Embedder (NLContextualEmbedding **+ centering**), similarity-based merging and thresholds, Theme screen, Obsidian themes = `[[wikilinks]]`.
- **Verification**: Similar captures gather into one Theme. Sentences blocked by FM are still tagged via the fallback. Merge/split work.
- **Depends on**: S1. **Spike reuse**: `embed_spike3.swift` (centering), `fm_spike2.swift` + `mlx` (fallback).

### S5 · Daily Digest (local)
- **Goal**: A day's captures as a light retrospective (local). Theme-based groupings + first-time/recurring thoughts + energy snapshot + one question for tomorrow. Also recorded to Obsidian.
- **Verification**: Generate, display, and mirror a daily Digest for one day's worth.
- **Depends on**: S4.

### S6 · Weekly Digest + Sustain Candidates + Decisions  ⭐ Core value
- **Goal**: Repetition (evolving/looping) + energy → a "sustain candidates" view + decision prompts [sustain/hold/fold]. Save decisions and feedback. **Opt-in cloud deep synthesis** (two-stage distillation → Claude) + consent model (toggle + seal exception + transmission log).
- **Verification**: Show candidates and badges for one week's worth, save decisions. When the cloud toggle is on, only the distilled layer is transmitted and logged. With it OFF, it still works locally.
- **Depends on**: S4, S5. **Spike reuse**: distillation & consolidation.

### S7 · Period Digest (basic)
- **Goal**: Repetition over an arbitrary range + decision log. (Execution tracking · connection · cooling are post-v1.)
- **Verification**: Generate a one-month period digest.
- **Depends on**: S6.

## v1 Boundary Recap
- **v1**: capture · energy · seal · Obsidian mirror · classification & consolidation · curation · daily · weekly (+ decisions, cloud opt-in) · period (basic).
- **post-v1**: execution tracking · connection · cooling signals, two-way Obsidian, iCloud sync, custom templates, Action Button/AirPods trigger, Android.

## Starting Point
- Begin with **S0 (scaffolding) → S1 (capture core)**. When S1 runs on real Korean speech, the app's heart is beating.

## Status (2026-06-04) — ✅ All of v1 implemented and committed
- S0–S7 all complete. On-device: voice capture · consolidation · daily/weekly/period digests · sustain candidates · decisions · cloud opt-in all working.
- S4 auto-classification is best-effort (on-device FM limits) + complemented by curation (move/merge/reorder) — spike-findings ⑥-b.
- Remaining polish (open): WER measurement on real-device real voice, Obsidian theme `[[links]]` (re-mirror), simulator STT assets fragile (real devices fine), MLX fallback bundle (for guardrail cases), advancing the evolving/looping · connection signals.


\newpage

# Living Record — v2 Vertical Slice Plan (Completing the Sustain Loop)

> English translation. Korean original: `v2-slices.md`.

> Written: 2026-06-04 · Basis: `concept.md` (§1 core loop, §3-6 the five signals), `사용설명서.md` (v1 status)
> Platform: iOS 26+ · Workflow: same as v1 (implement → verify by running on a real device → commit, slice tag `feat(S8): …`)

## 0. The Goal of v2 — Reconnecting the Broken Arrow

In concept §1's core loop, the link v1 failed to close:

```
capture → theme → [signal] → decision → ❳execution❲ → "so how did it turn out" in the next retrospective  ← v2 fills this
              └ v1: repetition · energy · evolution        ↑___________feedback___________↓
                v2: + execution tracking · cooling · connection
```

**v1 signals (3): repetition · energy · evolving/looping.** (+ momentum · energy trend added in the most recent enhancement.)
**v2 signals (3): execution tracking · cooling · connection** → completing concept §3-6's five signals + closing the decision→action→feedback loop.

## 1. Firm Decisions (premises of this v2 plan)

- **Execution tracking = "automatic intention detection."** This app cannot observe real behavior → defined as "did the *intention* in the words survive afterward" (concept §3-6.3 verbatim). Capture friction stays at zero (the user marks nothing; the local AI detects it).
- **Scope = sequential S8→S9→S10→S11.** Move on when the previous one runs on a real device.
- **All signals are local.** Intention detection · cooling · connection computation are all on-device (FM/embeddings/NLTagger). The cloud is used only for weekly/period deep synthesis as before (distilled layer, opt-in, seal excluded).
- **Prevent the self-fulfilling loop (concept §6).** So as not to only amplify what's loud, surface quieted threads and cooling in balance.
- **The data model had placeholders → now we fill them.** v1's `Decision` stays as is; a new `Commitment` is introduced for execution tracking (additive → lightweight SwiftData migration).

---

## 2. Slices

### S8 · Execution Tracking (survival of intention) ⭐ Heart of the loop
- **Goal**: Locally detect intentions and commitments within a capture, leave them as a **Commitment**, then track **whether it survived / fizzled out** and surface that in the retrospective.
- **Includes**:
  - `IntentionDetector` interface + FM implementation: `@Generable { hasIntention: Bool, phrase: String }` — "Does this memo contain an intention/plan/commitment to do something going forward? If so, extract the core intention phrase." On guardrail/failure, fall back (detect nothing, conservative).
  - At the end of consolidation (`Consolidator.consolidate`), detect intention → if present, create `Commitment(text: phrase, sourceCapture, theme, createdAt)`.
  - **Survival decision (deterministic)**: if there is a new capture in the same theme after the commitment is created, `surviving`; if there is zero activity for a set period (e.g., 10 days), `faded`. (Semantic re-mention is a follow-up — for now an activity-based, conservative signal.)
  - A **"This Week's Commitments"** section in the weekly retrospective: intentions that survived / intentions that went quiet. Reflected in the Obsidian mirror too.
- **Data**: a new `@Model Commitment` (id, text, createdAt, statusRaw, lastActivityAt, sourceCapture?, theme?). Registered in `modelContainer`.
- **Verification**: utterances like "next week I should try ~" → a commitment is created. A follow-up capture in the same theme → surviving. Neglected → faded. Memos with no intention create no commitment (low over-detection).
- **Depends on**: all of v1. **Spike recommended**: a short check of Korean intention-detection precision (FM @Generable).

### S9 · Activating Cooling (pruning signal)
- **Goal**: Actively surface themes that were hot and then cooled, and ask whether to **revive or let go**. (Sustaining = continuing + pruning.)
- **Includes**:
  - Cooling decision: previously active (e.g., schedule threshold ↑ over the prior 2 weeks) but strongly negative momentum in the recent window → `Theme.state = .cooling`. (Reuse and extend the existing momentum computation.)
  - A **❄️ "cooling threads"** section in the weekly retrospective (separate from sustain candidates): `[Revive][Fold]`. concept §4 example verbatim.
    - `[Revive]` → return state (active) + (optional) suggest a question to continue tomorrow. `[Fold]` → `Decision(.drop)`.
  - Balanced surfacing: gently bring up 1–2 "once-cherished themes that have been quiet for a while" (prevents the self-fulfilling loop).
- **Data**: uses the existing `ThemeState.cooling` (no model change).
- **Verification**: a once-frequent, now-stopped theme shows up as ❄️. Revive/fold work and are reflected in the next retrospective.
- **Depends on**: S8 (shared feedback expression) · v1 momentum.

### S10 · Deepening Connection (inspiration signal)
- **Goal**: Capture the moment when far-apart thoughts converge into one thread, as an **actionable suggestion**.
- **Includes**:
  - Enhance `relatedPairs`: strength tiers (high/medium) + emphasize **"newly close" connections** (first proximity this week).
  - From a connection card, **"bundle into one thread"** (= merge themes) in one tap.
  - Inject connection insight into the weekly/period narrative ("A and B, once far apart, met this week").
- **Data**: no model change (embedding-based computation).
- **Verification**: related theme pairs are shown with strength, bundling works, reflected in the narrative.
- **Depends on**: v1 relatedPairs.

### S11 · Making the Feedback Loop Visible ⭐ The loop closes
- **Goal**: The retrospective starts with "how did things go since the last decision," so that decisions visibly make the next ones smarter.
- **Includes**:
  - A **"Since the last retrospective"** summary at the very top of the weekly retrospective: the current status of recent decisions.
    - X that you sustained → N times this week (alive ✓ / quiet). Y that you folded → did it come back up? (revival alert). The survival tally of commitments (S8).
  - Feed decision/commitment history into the narrative input to generate insights like "of last week's commitments, … carried on while … fizzled out."
  - Period digests also accumulate decision/execution flow (extending the existing decision log).
- **Data**: read-only queries of existing `Decision` · new `Commitment`.
- **Verification**: decision → one week later, a tracking summary at the top of the retrospective. If something folded comes back up, it's surfaced.
- **Depends on**: S8 · S9 · S10.

---

## 3. v2 Boundary

- **v2**: execution tracking (survival of intention) · activating cooling · deepening connection · making feedback visible → concept's five signals complete, loop closed.
- **Still post-v2**: widget/Action Button/AirPods triggers · notification nudges (reachability), search · semantic exploration, iCloud sync · encrypted backup · MLX fallback bundle · two-way Obsidian, custom templates, visualization.

## 4. Data Model Changes (summary)

```
+ Commitment(commitment/intention) : text, createdAt, status(open/surviving/faded), lastActivityAt,
                           sourceCapture?, theme?   ← new in S8 (additive migration)
  Theme.state            : active/looping/cooling/decided  ← cooling actively used in S9
  Decision, Capture, Theme, Digest, Transmission  ← unchanged (read-only)
```

## 5. Starting Point
- Begin with **S8 (execution tracking)**. When intention detection works reasonably on a real device, the heart of the loop is beating.
- If stuck, narrow the scope (e.g., "intention detection + commitment creation only first; survival decision next").

## Status (2026-06-04) — ✅ All of v2 implemented and committed
- **S8 Execution tracking**: deterministic gate on intention endings (spike ⑦, 10/10) + FM label. Commitment model, survival decision (surviving/faded), weekly 'This Week's Commitments'.
- **S9 Cooling**: coolingThemes (prior 2 weeks ≥3 · recent window ≤1 · quiet for 4+ days), 'cooling threads [Revive][Fold]'. revive = sustain record + return to active.
- **S10 Connection**: Connection (high/medium tier · new connections), 'bundle into one thread' in one tap, narrative injection.
- **S11 Feedback**: followUps (current state of past decisions), weekly top 'Since the last retrospective', extended period decision log.
- **→ concept §3-6's five signals complete + decision→action→feedback closed loop done.** End-to-end on real data is recommended to confirm on a real device (room for threshold tuning).


\newpage

# Living Record — v3 Vertical Slice Plan (Capture Reachability)

> English translation. Korean original: `v3-slices.md`.

> Written: 2026-06-04 · Basis: `concept.md` §3-4 (capture = one action · trigger), `사용설명서.md`
> Platform: iOS 26+ · Workflow: implement → verify on a real device → commit (`feat(S12): …`)

## 0. Goal — Capture in One Action, Outside the App

v1+v2 capture **only if you open the app**. v3 actually realizes concept §3-4's "trigger = one action, zero decisions."
- **Firm decision (concept §3-4):** widget/trigger one tap → capture. Seal = absorbed into the trigger (tap = normal / press-and-hold = sealed). Always-listening is rejected (a deliberate act).
- **This decision:** on trigger, **the app opens to the capture screen and starts recording automatically** (the instant it opens). The mic requires the app to be active → entering the foreground is unavoidable, but the user action is a single one.

## 1. Slices

### S12 · App Intent Capture ⭐ (the biggest reach, zero new targets)
- **Goal**: Expose "start capture" as a system action → **Action Button · Siri · AirPods ("Hey Siri, capture")** all at once. The app opens to the capture tab and starts recording automatically.
- **Includes**:
  - `AppLaunchState` (@Observable singleton): `startCapture`/`startSealed` signals. Injected into the app environment.
  - `StartCaptureIntent` / `StartSealedCaptureIntent` (`openAppWhenRun=true`) → set the signal.
  - `AppShortcutsProvider`: "capture" · "sealed capture" phrases (exposed to Siri/Shortcuts/Action Button).
  - ContentView: on signal, switch to the capture tab (0). CaptureView: after consuming the signal, automatically start `toggleRecord()` (duplicate guard).
- **Verification**: "capture" appears in the Shortcuts app; running it makes the app start recording. Assign to the Action Button → pressing it records. (Real device.)
- **Depends on**: v1 capture. **No new Xcode target needed.**

### S13 · Evening Retrospective Reminder
- **Goal**: A gentle local notification, "Today in one line?" Tapping it goes to capture (or the daily digest).
- **Includes**: notification permission request, toggle + time in settings, `UNUserNotificationCenter` daily schedule, deep link on tap (reuses AppLaunchState).
- **Verification**: notification at the set time, tap → capture screen. (Real device.)
- **Depends on**: S12 (shares the deep-link signal).

### S14 · Home/Lock Screen Widget
- **Goal**: Widget one tap → capture screen (auto-record). Sealed variant.
- **Includes**: **a new Widget Extension target** (added by the user in Xcode) + an **App Group** (SwiftData sharing isn't needed for v1, but will be needed later if the widget shows recent state) + the widget button runs an App Intent/deep link.
- **Verification**: tap the home screen widget → record. (Real device.)
- **Depends on**: S12. ⚠️ **Adding a new target is a user task** (as with app creation).

## 2. v3 Boundary
- **v3**: triggers (App Intent/Action Button/Siri/AirPods) · reminder · widget.
- **post-v3**: search · semantic exploration, iCloud sync · encrypted backup · MLX fallback bundle · two-way Obsidian, custom templates, visualization, Android.

## 3. Starting Point
- Begin with **S12 (App Intent)**. With no new target, the Action Button · Siri · AirPods all open it in one action.

## Status
- **S12 ✅ Done (2026-06-04)**: App Intent capture. AppLaunchState singleton + Start(Sealed)CaptureIntent (openAppWhenRun) + LivingRecordShortcuts. ContentView tab switch + CaptureView auto-record (guard). Build · metadata extraction · launch confirmed. Action Button/Siri real behavior on a real device.
- **S13 ✅ Done (2026-06-04)**: Evening retrospective reminder. ReminderStore (toggle + time default 21:00, permission, UNCalendar daily repeat) + NotificationDelegate (foreground banner + tap → openCapture) + AppLaunchState.openCapture (navigation only). Settings 'Reminder' section. Build · launch OK. Permission · firing · tap on a real device.
- **S14 ✅ Done (2026-06-04)**: Capture widget. CaptureWidgetExtension target (user-added) + CaptureWidget (home systemSmall 🎙️/🔒, lock screen accessoryCircular · Rectangular, Button(intent:)) + CaptureWidgetControl (Control Center). Static launcher (no App Group needed), openAppWhenRun → app process → AppLaunchState auto-record. CaptureIntents.swift shared with the widget target. Build · .appex embed · launch OK. Widget add · tap real behavior on a real device.
- **→ v3 "capture reachability" complete (S12–S14). Action Button · Siri · AirPods · reminder · widget all capture in one action.**


\newpage

# Living Record — v4 Slice Plan (Search · Semantic Exploration)

> English translation. Korean original: `v4-slices.md`.

> Written: 2026-06-04 · Basis: `spike-findings.md` ⑧, user decision (hybrid)
> Platform: iOS 26+ · Workflow: implement → verify on a real device → commit

## 0. Goal — Refind Accumulated Captures + Use Embeddings That Were Only Stored

v1~v3 had no search. The more captures pile up, the more essential it becomes. At last we use the **512d embeddings** that had only been stored, unused, since v1.

## 1. Firm Decisions (basis: spike ⑧)

- Semantic-search ranking is **coarse** (top-1 3/6, top-3 5/6). Cannot be trusted as precise.
- **Hybrid**: **full-text (exact contains) = primary, trusted** + **semantic ('similar records') = secondary, estimated** (threshold ~0.30, top 6, 'estimated' label).
- Location: **the search bar in the Records tab** (`.searchable`). Not expanded to 5 tabs.
- Performance: full-text is live; semantic embeds **only when search runs (on return)** (not embedding on every keystroke).

## 2. Slices

### S15 · Hybrid Search ✅ Done (2026-06-04)
- **Includes**: `SemanticSearch.similar()` (embed the query → centered cosine → threshold · top). CaptureListView `.searchable`: empty query = existing list, query = 「exact contains」 + 「similar records (estimated)」 sections. Semantic search on onSubmit; reset when the query is cleared. Empty-result state view.
- **Verification**: build · install · launch OK. Semantic quality · threshold confirmed via spike ⑧. The feel on real data is for a real device.
- **Depends on**: v1 embeddings (already stored).

## 3. v4 Boundary
- **v4**: hybrid search.
- **post-v4**: iCloud sync · encrypted backup · MLX fallback bundle · two-way Obsidian · custom templates · visualization. + Reserved: v2 threshold tuning.

## Status
- **S15 ✅ Done.** (Semantic threshold 0.30 · top 6 leave room for tuning on real data — included in reserved work.)


\newpage

# Living Record (생동하는 기록) — User Guide

> English translation. Korean original: `사용설명서.md`.

> Updated: 2026-06-05 · Scope: current build (v1 archive → v2 sustain loop → v3 capture reachability → v4 search → wiki · resurfacing · backup) · Platform: iOS 26+ (iPhone)
> Basis: actual source (`LivingRecord/`), design (`concept.md`), validation (`spike-findings.md`), plans (`v1~v4-slices.md`)

---

## 0. What is this app?

When you **capture (포착) a thought as if letting it flow by** — spoken or written — the app **stores it locally**, **groups similar thoughts into themes**, and creates **something to look back on (a digest, 정리)** by day, week, or arbitrary period. Its ultimate purpose is to answer a single question:

> **"What will I sustain?"**

This is not a grading or evaluation app. Judgment belongs to the person. The app merely **gathers and shows evidence (repetition, energy, flow)**; you decide what to sustain, hold, or close.

### Three unshakable principles
1. **Capture has zero friction.** It never asks for category, title, or tags. You speak or write, and you're done.
2. **Local first.** The original text, voice, and energy never leave the device. The cloud is *optional*, and even when something does go out, it is not the original but a *summary (the distilled layer, 증류층)*.
3. **Decisions belong to the person.** AI handles classification, summarization, and surfacing signals. Whether to "sustain or close" is up to you.

---

## 1. Getting started

### 1-1. First launch
When you open the app, you land directly on the **Capture (포착) tab**. You can record right away by speaking or typing, with no setup. That said, two things are worth doing in advance.

### 1-2. Connect an Obsidian vault (optional, recommended)
Connect this if you **also want to keep captures and digests as Markdown files** in parallel.
- **Gear icon (⚙️) at the top right of the Capture tab → Settings → Obsidian vault → "Select vault folder"**
- Once you pick a folder, every capture from then on is mirrored as `.md` under that folder.
  - Regular captures → `Captures/`
  - Sealed captures → `봉인/`
  - Digests (daily/weekly/period) → `Digests/`
- ⚠️ **Caution:** If the vault folder syncs via iCloud/Dropbox, **sealed captures will also leave the device.** To preserve the meaning of sealing (never leaving the device), keep the vault as a local folder.

### 1-3. Cloud deep synthesis (optional, off by default)
Turn this on only when you want weekly/period digests synthesized more deeply by Claude.
- **Settings → Cloud deep synthesis → toggle ON + enter Claude API key → "Save key"**
- The key is stored in the device **Keychain** (it is never left in code or on a server).
- Even when on, **the original text does not go out.** Only the locally produced *per-theme summary (distilled layer)* is transmitted, and **sealed captures are excluded entirely**. You can review what has gone out under **Transmission log** in Settings, by date, type, and character count.
- When off (the default), all digests are produced **entirely by local AI (Apple Foundation Models)**.

---

## 2. Screen layout — 5 tabs

There are 5 tabs along the bottom. **Swipe left or right on an empty area** to move to the adjacent tab (left → next, right → previous).

| Tab | Icon | What it does |
|---|---|---|
| **Capture (포착)** | 🎙️ | Leave a thought by speaking or writing (the entrance) · ⚙️ Settings at top right |
| **Records (기록)** | ☰ | View all captures newest-first + search (full-text · semantic) |
| **Themes (주제)** | ✚ | View by automatically grouped theme + curation |
| **Digest (정리)** | 📄 | Create daily/weekly/period retrospectives (the exit) |
| **Flow (흐름)** | 📊 | See daily captures, energy trends, and theme distribution at a glance |

**Settings** is reached via the ⚙️ at the top right of the Capture tab, organized by category: **Storage & Sync** (Obsidian vault · backup), **Digest & Processing** (digest templates · cloud deep synthesis), **Notifications** (evening retrospective), and **Tools** (dictation accuracy).

---

### 2-1. Capture tab — where you leave a thought

From top to bottom: **seal toggle → record button → direct-entry field**.

**① By voice (default)**
- **Tap the microphone button in the center to start recording.** "Listening · tap to save" appears, a ring pulses to your voice level, and elapsed time is shown.
- **Tap again to stop and save.** Dictation (STT) runs automatically and the result is saved as text. Light fillers (standalone tokens like "um/uh/yeah") are cleaned up conservatively.
- During recording, the app extracts **acoustic energy (arousal)** and then **immediately discards the raw audio.** (Only the voice score remains; the audio file does not.)

**② By writing (fallback)**
- Write in the "Or type directly" field below and **Save**. The field grows downward as text gets longer (up to 6 lines, then scrolls internally). Close it with **Done** above the keyboard.

**③ Sealing (🔒)**
- Tap the **Seal (봉인)** chip above to enter the purple sealed mode. A capture saved in this state **never leaves the device** (Obsidian uses a separate `봉인/` folder, and it is excluded from cloud synthesis).
- For very private thoughts. It is distinguished from regular captures by a lock icon on the same screen.

**Right after saving**, quietly in the background: embedding generation → theme assignment/creation → (if a vault exists) Markdown mirroring. You don't need to wait. When you save, an **echo (메아리) of "a similar thought from before"** briefly surfaces, connecting you to your past self (excluding sealed captures).

**④ With one action from outside the app** — Trigger via the Action Button, Siri, AirPods ("Hey Siri, capture to Living Record"), Home/Lock Screen widget, or Control Center, and the app opens to the Capture screen and **records automatically** (including a sealed variant). The evening retrospective notification can do this too (see Other features below).

> The gear (⚙️) is at the top right of this tab (to enter Settings).

---

### 2-2. Records tab — all captures, newest-first

- View all captures in reverse chronological order. Each row: body text + date/time + (if present) energy bar + theme chip + (if sealed) 🔒.
- **Date-range chips** (top): narrow to Today · 1 week · 1 month · All · Custom range.
- **Search** (top search bar): **exact match** (full-text, instant) + **similar records (estimated)** (semantic search, on return) — finds by meaning even when no words overlap.
- **Long-press a row** for a context menu:
  - **Move to another theme** — choose from the list of other themes, or **extract into a new theme**.
  - **Delete record** — removes the capture and its Obsidian `.md`. If it was the theme's last record, the now-empty theme is cleaned up too.

---

### 2-3. Themes tab — automatically grouped thoughts

Similar captures are automatically grouped into a **Theme (주제)**. Theme grouping is the **on-device AI's best-effort** (not perfect — see §5 below). That is why **curation (큐레이션, hand-tuning)** is essential.

- List: theme name + capture count. Tap to see that theme's captures (in manual sort order).
- **Long-press a theme**: **Rename**, **Merge into another theme**.
- In theme detail, the **⋯ menu at the top right**: Rename / Merge. **Long-press an individual record** to move or extract it to another theme.
- When you rename, move, or merge, Obsidian's `[[theme]]` wikilinks are automatically rewritten as well.

> The design tolerates misclassification. **If it's wrong, just move it by hand** — that is the normal flow.

---

### 2-4. Digest tab — looking back (the app's exit and core value)

From the **"Create digest" (✚) menu** at the top right, pick one of three:

**① Daily digest (today)** — local only
- Gathers today's captures by theme into an **insight-driven narrative** (a flow, not a list) of 4–6 sentences.
- Connects to the **continuing flow (🔁 repetition)** from the prior 7 days to point out what carries over and what is new.
- Ends with one **question to carry into tomorrow**.

**② Weekly retrospective** — core value ⭐ (the heart of the app)
Opens as a sheet and, top to bottom, follows the **"sustain loop"** order — look back → what to carry forward → what to let go → commitment → connection → writing:

1. **Since the last retrospective** *(looking back — the head that closes the loop)*
   - The *now* of decisions you made last time. Did what you chose to **sustain** carry on (N times ✓ this week) / go quiet, did what you **closed** come back up (↑). A decision lights the next one. *(Visible only after one cycle has passed.)*
2. **Sustain candidates (지속 후보)** — themes that returned **2 or more times** this week (7 days). Each candidate gets signal badges:
   - **↑ rising / ↓ cooling** — activity rate of the recent half (3 days) vs. the earlier half (4 days). *Momentum (모멘텀).*
   - **🌱 evolving / 🔁 looping** — whether the thinking moved on (embedding-centroid distance between first and second half).
   - **Energy %, heat ↑/↓** — average energy and its trend.
   - Sorted by **sustain-value score** (repetition center + added weight for momentum, energy, and evolution).
   - Each candidate has **[Sustain] [Hold] [Close]** → saved and reflected in the next retrospective (item 1).
   - **Precedent (선례, 🕘)** — if you've decided on this theme before, it shows that track record, e.g. "'Hold' decision 30 days ago (3rd time) → then 4 more times after." *Before you press now*, the past lends a hand.
3. **❄️ Cooling throughlines** *(pruning)* — themes you once handled often (≥3 times in the prior 2 weeks) that have gone quiet recently (≤1 time, 4+ days). **[Revive]** (pick it back up) / **[Close]** (let it go). *Sustaining = carrying forward + pruning.*
4. **This week's commitments (다짐)** *(execution tracking)* — intentions like "I'll do ~" or "I should try ~" automatically detected within captures and gathered here. If the same theme continues, **carrying on ✓**; if quiet for 10+ days, **gone quiet**. (Auto-detected — for reference.)
5. **Connected themes (연결)** *(inspiration)* — pairs of themes close to each other. **New connection** (first grown close this week) · **strong/medium** badges + **[Bind into one throughline]** in one tap (merges the smaller into the larger).
6. **Weekly narrative** — generate the retrospective text with "Generate weekly digest." It weaves the signals above (looking back · rising/cooling · commitments · new connections) into insight. With cloud ON, ☁️ deep synthesis (only the distilled layer is transmitted); with cloud OFF, local.

**③ Period digest** — arbitrary span
- Synthesizes the recurring themes of the last N days (or all) plus a cumulative log of **"decisions made and what followed"** (carried on / came back up / settled). Summarizes the larger flow. Same cloud opt-in.

Generated digests accumulate in a list (narrow with the **date-range chips** at top), and if a vault exists they are also saved to `Digests/`.

---

### 2-5. Flow tab — at a glance + resurfacing

- **Resurfacing (되새김)** *(the past checking in)* — even when you do nothing, once a day one capture from 14+ days ago comes up. **"N years/months ago today"** or **"something you'd forgotten for a while."** (To avoid rumination traps, sealed captures are excluded and there is no noisy recency bias.)
- **Long-running throughlines (줄기)** *(throughline)* — themes that didn't just flare up once but **returned again and again across multiple periods** (30+ days · 3+ distinct weeks). "What I've consistently cared about."
- **Charts** — summary (captures · themes · average energy · sealed) + daily capture count (14 days) + energy trend + theme distribution (Top 8). *(Swift Charts)*

---

## 2-9. Other key features

- **Evening retrospective reminder** — at a time you set each day, a notification **carrying that day's resurfacing** (or "today in one line" if none). Tap to go to Flow/Capture. *Stays entirely on the device.* (Settings → Notifications)
- **LLM wiki (위키)** — turns the vault into a knowledge base an LLM can navigate and read. Each theme gets a **hub (허브) note** (`Themes/<theme>.md`: metadata + decisions + record list + cloud "at a glance") + an **`index.md`** (throughlines + all themes). It updates automatically on new captures and curation, and use **"Rebuild wiki"** for existing data. The AI "at a glance" is cloud opt-in (distilled, sealed excluded). One-way (app → vault). (Settings → Obsidian vault)
- **Encrypted backup/restore** — export/restore all data as a single password-locked file (includes sealed captures; merges with the same password). (Settings → Backup & Restore)
- **Digest templates (템플릿)** — choose or create the tone and focus of digest writing (warm insight / concise / question-driven / action-oriented + free-form). (Settings → Digest templates)

---

## 3. Core concepts summary

| Concept | Meaning | How it's used |
|---|---|---|
| **Capture (포착)** | A fragment of thought (voice→text or direct entry) | Created in the Capture tab |
| **Sealed (봉인)** | A capture that never leaves the device | The 🔒 toggle at capture time |
| **Energy** | Arousal while speaking (volume-based, 0–100%) — *not sentiment analysis* | Automatic, read "relative to your usual" |
| **Theme (주제)** | A grouping of similar captures | Automatic + hand curation |
| **Momentum (모멘텀)** | Recent trend (rising/steady/cooling) | Weekly-retrospective badge |
| **Evolving/looping (진화/맴돎)** | Did the thinking develop / stay put | Weekly-retrospective badge |
| **Sustain candidate (지속 후보)** | A frequently returning theme | Decided in the weekly retrospective |
| **Decision** | Sustain/hold/close | Reflected in retrospective text and period digest |
| **Commitment (다짐)** | An auto-detected intention within a capture | Survival-tracked in "this week's commitments" |
| **Cooling (식어가는 줄기)** | A theme once hot, now quiet | Pruned via revive/close |
| **Connection (연결)** | Two close themes (inspiration) | "Bind into one throughline" |

> **Sustain loop:** capture → theme → signals (repetition · energy · evolution · **execution · cooling · connection**) → decision → execution tracking → feedback into "since the last retrospective." This loop is what supports the app's core value, "what will I sustain?"

---

## 4. Privacy — what lives where

```
[Voice] ──record──▶ extract energy score only ──▶ audio discarded at once (no file kept)
                                          │
[Text/transcribed words] ──▶ SwiftData (on-device local) ──▶ (optional) Obsidian vault .md
                                          │
                       ┌──────────────────┴───────────────────┐
                  Default (cloud OFF)                  Cloud ON (optional)
                  All digests = local AI               Weekly/period only = Claude
                                                        but original text X → only the 'distilled
                                                          layer' (per-theme summary) is sent
                                                        Sealed captures = always excluded
                                                        Transmission record = logged in Settings
```

- **Two-stage distillation (2단계 증류):** The original stays local only. To the cloud goes only a *summary* produced by local AI. Abstracted, with no quoting of the original.
- **Consent model:** "turn on once + sealed exception + transmission log." It doesn't ask every time, but sealed captures are always left out, and everything that goes out is visible.
- Secret keys live in the **Keychain**, with no hardcoding in code.

---

## 5. Limits & caveats to know (honestly)

- **Real-device-only feature:** dictation (SpeechTranscriber) has **fragile speech assets in the simulator.** Test voice capture on a real iPhone. (Real-device, real-voice transcription accuracy measured at ≈ 92.8%.)
- **Automatic theme classification is best-effort:** on-device AI (Foundation Models) may, depending on conditions, **lump everything into one theme or split it excessively.** That's why the design is "automatic + curation." **If it's off, moving it by hand in the Themes tab is the normal flow.**
- **FM guardrails:** even harmless sentences can occasionally be falsely blocked by the local AI (when summarization/naming fails, it falls back to count and leading characters). The MLX open-model fallback is validated but not yet bundled in the v1 app.
- **Signals need data to accumulate:** evolving/looping needs 3+ embeddings, the energy trend needs 4+ energy captures, momentum and sustain candidates need 2+ within 7 days, **cooling** needs quiet after 3+ in the prior 2 weeks, **commitment survival** takes 10 days, and **feedback ("since the last retrospective")** only becomes meaningful after one cycle has passed since the decision. Early on, it's normal to see few badges.
- **Intention detection is an ending-gate (deterministic):** it catches Korean intention endings like "~하겠다/해야지/해보자" so it isn't swayed by conditions (the FM Boolean verdict was unstable, so it was dropped). Rarely it can over-fire ("좋겠다" = a wish), and commitment *labels* are extracted by FM, so quality can be uneven. Signal **thresholds will be tuned with real-usage data** (currently conservative defaults).
- **iCloud vault = sealed-leak risk:** see the caution in §1-2.
- **Single device:** v1 has no cross-device sync (iCloud sync is a follow-up). Backup is manual.

---

## 6. Data model (at a glance)

- **Capture** — one capture: text, creation time, energy?, sealed flag, tag candidates, embedding (512d)?, theme?, sort value.
- **Theme** — a theme: name, state (active/looping/cooling/decided), captures, wiki "at a glance" summary?.
- **Digest** — a digest: type (daily/weekly/period), span, narrative text, cloud-generated flag.
- **Decision** — a decision: theme, verdict (sustain/hold/close), time.
- **Commitment** — a commitment (intention): intention phrase, time, state (in progress/carrying on/quiet), theme-ID snapshot.
- **CustomTemplate** — a user digest template: name, style instructions.
- **Transmission** — a cloud transmission log: type, character count, time.

> The model is left open so extension tables for grading/comments and the like can be attached later.

---

## 7. Tech stack (for reference)

SwiftUI + SwiftData / all-in on Apple on-device AI:
- STT = **SpeechTranscriber** (Korean on-device)
- Local LLM = **Foundation Models** (+MLX fallback planned)
- Embeddings = **NLContextualEmbedding** (Korean, *centering preprocessing required*)
- prosody = **vDSP** acoustic features (arousal)
- Local text generation = **LocalSynth** (FM → MLX fallback slot) · deep synthesis (opt-in) = **Claude (Sonnet)** = `CloudSynthesizer`
- Core components are **abstracted behind interfaces** (Transcriber/ProsodyAnalyzer/Embedder/ObsidianMirror/IntentionDetector) → replaceable.
- Search & signals = **NLContextualEmbedding** (centered) cosine + deterministic signals (ending gate · date windows). *Automatic theme-to-theme linking was not adopted, as embeddings can't be trusted for it.*


\newpage



\newpage

# Part III · Course Operation (instructor)

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


\newpage

# Detailed Grading Rubric — "Living Record" Project Course

> English translation. Korean original: `채점-루브릭.md`.

> Companion materials: `8주-강의계획서.md` (assessment weights) · `학생-워크북.md` (assignments) · `프로젝트-보고서.md` (competency definitions)
> Written 2026-06-05

---

## 0. Grading Philosophy

This course evaluates not the *quantity of code* but the **quality of judgment**. Accordingly, the five core competencies underlie every rubric.

| Competency | Core Question |
|---|---|
| **A. Vertical Slice** | Is the submission a *working minimal unit*? |
| **B. Verification Habit** | Did you confirm uncertain parts through a spike or by running them? |
| **C. Rationale** | Did you record "why you decided that way" in docs, commits, or prose? |
| **D. Privacy** | Did you enforce the boundary of sensitive data (sealed/original text) in code? |
| **E. Failure-handling** | When stuck, do you know how to *narrow scope or roll back*? |

**Performance Scale (common)**

| Level | Point Band | In a Word |
|---|---|---|
| **4 Exemplary** | 90–100 | Goes beyond the standard, identifying the *why and trade-offs* independently |
| **3 Proficient** | 75–89 | Faithfully meets the standard, with rationale |
| **2 Developing** | 60–74 | Works, but rationale and verification are shallow |
| **1 Insufficient** | <60 | Incomplete or copied, no rationale |

> Score for each deliverable = sum of (per-item level score × weight), converted to a 100-point scale.

---

## 1. Common Competency Rubric (the baseline applied to all deliverables)

| Competency | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **A Slice** | One flow is *complete* from UI to storage, with a clean boundary that allows extension to the next step | One flow works | Only part works / breaks off | Does not work |
| **B Verification** | *Measures* via a spike or by running, and changes the design based on the result | Runs to confirm and reports | Confirms the build only | Unverified |
| **C Rationale** | Explains *why* by comparing alternatives and trade-offs | States the "why" in one paragraph | Describes the result only | No rationale |
| **D Privacy** | Inspects and blocks every path through which sealed/original text could leak | Aware of sealing and excludes it | Partial awareness | Leaves leaks unaddressed |
| **E Failure-handling** | Narrows or rolls back the blockage and records the *lesson* | Narrows scope to resolve | Resolves with help | Gives up / leaves it |

---

## 2. Weekly Practicals / Milestones — **30%**

Weekly submission (code + retrospective). 5 milestones (weeks 2, 3, 5, 6, 7) + a mid-point check (week 4).
**Per-item weights**: functionality 35 · slice appropriateness 20 · verification & retrospective 20 · code quality 15 · deadline & polish 10.

| Item | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **Functionality (A)** | The intended flow runs smoothly on a real device / in execution | Works (minor defects) | Only part works | Does not work |
| **Slice Appropriateness (A)** | Scope is *exactly one flow*, with a clear opening for the next extension | Appropriate | Too broad or too narrow | Attempted all at once and left unfinished |
| **Verification & Retrospective (B, E)** | Execution results + a concrete "what blocked me · narrowed to resolve" retrospective | Execution confirmed + retrospective | Retrospective is perfunctory | None |
| **Code Quality (C)** | Names/structure reveal intent, no needless duplication | Readable | Function-only | Messy |
| **Deadline & Polish** | On time + extra refinement | On time | Late submission | Not submitted |

> **Partial-credit principle:** Completing something by *narrowing scope*, such as "text capture first," is not a deduction but **bonus credit for the E competency**.

---

## 3. Spike-Reproduction Report — **15%** (submitted week 3)

Subject: the embedding (centering) or intent-detection (A/B/C) spike.
**Per-item weights**: reproduction accuracy 30 · result organization 25 · interpretation (why) 30 · design implications 15.

| Item | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **Reproduction Accuracy (B)** | Runs the spike and reproduces results accurately, even noting environment differences | Reproduction succeeds | Partial reproduction | Could not run it |
| **Result Organization** | Input/expected/actual/match table + key figures highlighted | Organized in a table | Listed as text | Fragmentary |
| **Interpretation (C)** | Explains "why this conclusion" (e.g., threshold failure ∴ FM assignment) causally | States the reason for the conclusion | Restates the result | No interpretation |
| **Design Implications** | Connects through to "so how does the app design change" | One implication | Vague | None |

**The grain of an exemplary full-mark answer**: "The pair that should merge (0.209) < the pair that should not merge (0.353) → a single threshold cannot satisfy both ∴ abandon embedding clustering, switch to FM semantic assignment. However, on-device baselines are unstable → best-effort + curation."

---

## 4. Design-Decision Essay — **15%** (submitted week 5)

Topic: "Suffix gate instead of FM Bool," or one free-choice decision (bidirectional withdrawal, related-topic removal, etc.).
**Per-item weights**: understanding the decision 20 · rationale & measurement 30 · trade-offs 25 · "if it were me" originality 15 · writing 10.

| Item | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **Understanding the Decision (C)** | Accurate on what, when, and from which alternatives it was chosen | Decision content accurate | Approximate | Misunderstood |
| **Rationale & Measurement (B, C)** | Presents rationale with *measurements/spikes* (e.g., 10/10 vs. 1–6/10) | Has rationale | Impression-based | None |
| **Trade-offs** | Balances what was lost and gained (e.g., giving up automation ↔ stability) | One trade-off axis | One side only | None |
| **"If It Were Me"** | A reasonable alternative + its risks too | Proposes an alternative | Merely agrees | None |
| **Writing** | Structured, concise, cites rationale | Readable | Rambling | Weak |

---

## 5. Privacy Audit — **10%** (submitted week 8)

Assignment: trace "every path by which sealed data could leave the device" in a table.
**Per-item weights**: path coverage 40 · accuracy 30 · pinpointing the block location 20 · recommendations 10.

| Item | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **Path Coverage (D)** | Cloud, Captures mirror, iCloud vault (Digests/), backups, wiki — all without omission | Covers the main paths | Some omissions | Only 1–2 |
| **Accuracy (D)** | Judges each path's sealed-exclusion status with *code evidence* | Mostly accurate | Some guesswork mixed in | Wrong |
| **Block Location** | Pinpoints *where* it is caught, such as `!sealed` in `Distillation` | Mentions the location | Vague | None |
| **Recommendations** | Presents the remaining risk (iCloud vault) and a hardening plan | Recognizes the risk | Perfunctory | None |

> **Full-mark cue:** Daily/weekly *local* organization includes sealed-derived signals but never reaches the cloud — distinguishing the difference between *cloud vs. local/vault sync* earns an Exemplary on D.

---

## 6. Final Project + Presentation — **30%**

Split into deliverable 70% + presentation 30%.

### 6-1. Deliverable (21% of the total)
**Per-item weights**: design process 25 · verification 25 · polish 25 · privacy 15 · originality 10.

| Item | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **Design Process (C, A)** | The *flow* of design doc → spike → slice → verification is visible | The stages are present | Code only | Improvised |
| **Verification (B)** | Measures and reports via a real device / spike | Execution confirmed | Build only | Unverified |
| **Polish (A)** | One flow is complete and stable | Works | Partial | Unfinished |
| **Privacy (D)** | New features also respect the sealed/original-text boundary | Aware | Partial | Ignored |
| **Originality/Difficulty** | A deep challenge, such as a *safe* retry of a withdrawn item | A meaningful extension | Basic following-along | Insufficient |

### 6-2. Presentation (9% of the total)
**Per-item weights**: explaining problem & decision 35 · demo 30 · sharing failure & lessons 20 · Q&A 15.

| Item | 4 Exemplary | 3 Proficient | 2 Developing | 1 Insufficient |
|---|---|---|---|---|
| **Problem & Decision (C)** | "What was decided and why, this way" is the focus | Explains the decision | Lists features | Unclear |
| **Demo (A)** | Actually demonstrates the core flow live | Demonstrates | Screens only | None |
| **Failure & Lessons (E)** | Honestly shares what blocked, what was rolled back, what was learned | Shares difficulties | Perfunctory | Only glosses over |
| **Q&A** | Answers trade-off questions with rationale | Answers adequately | Thin | Cannot answer |

---

## 7. Score Conversion · Final Grade

```
Total (100) = Weekly 30 + Spike 15 + Essay 15 + Audit 10 + Final 30
Each deliverable = Σ(item level score × item weight) → converted to 0–100
```

| Grade | Total | Description |
|---|---|---|
| A | 90+ | Identifies judgment, verification, and privacy *independently* |
| B | 80–89 | Performs faithfully with rationale |
| C | 70–79 | Works but rationale and verification are shallow |
| D | 60–69 | Mostly incomplete or copied |
| F | <60 | Falls short on essentials |

---

## 8. Grading Operations Notes (for instructors)

- **Partial credit & resubmission:** "Completing by narrowing scope" is not a deduction but **bonus credit for the E competency**. Milestones allow one resubmission (capped at Proficient).
- **Anti-plagiarism / anti-copying:** Pose the *why* question on the spot in the presentation or Q&A — failing to give a rationale means C or below.
- **Fairness:** When voice/widget/notification could not be done due to lack of a real device, assess via a substitute demo or logic explanation (relaxing the weight of functionality).
- **Feedback:** Prioritize a *one-line comment per competency A–E* over the score — what to fix in the next milestone.
- **Weight adjustment:** Depending on the section's level, the final weight (30) and weekly weight (30) may be adjusted within ±10.

---

## Appendix · Per-Item Self-Checklist (for student distribution)

Check ✓ for yourself before submitting:
- [ ] (A) Does my submission have *one flow* that works?
- [ ] (B) Did I confirm it via *execution/spike*, not just the build?
- [ ] (C) Did I write even one paragraph on "why I decided this way"?
- [ ] (D) Did I inspect the paths through which sealed/original text could leak?
- [ ] (E) Did I record in the retrospective what blocked me and how I *narrowed/rolled back* to resolve it?


\newpage

# Instructor Answer Key (Teacher's Edition)

> English translation. Korean original: `강사용-모범답안집.md`.

> ⚠️ **INSTRUCTOR ONLY** — do not distribute to students. Companions: `학생-워크북.md` (problems) · `채점-루브릭.md` (assessment) · `프로젝트-보고서.md` (commentary).
> Each week: **Blank answers + why / Code exploration model answers (file:symbol) / Model review answers / Hands-on grading points & common mistakes / Discussion facilitation notes.**
> Written 2026-06-05

---

## How to Use

- Blank answers are **concepts**, not words. If a student uses a different word but *the meaning is correct*, accept it.
- Use the "why" boxes (💡) as discussion prompts. Ask the students *before* giving them the answer.
- Code exploration answers specify `file.swift:symbol` — guide students to find it themselves.

---

# Week 1 · Methodology, Conception & Validation

### Blank answers
1. **sustain (지속)** · 2. **vertical slice (수직 슬라이스)** · 3. **spike (스파이크)** · 4. **(run) validate → commit** · 5. **user (person)**
💡 *Why:* "sustain (지속)" is this app's differentiator — the single word that sets it apart from ordinary voice memos. #4 imprints "a successful build ≠ working behavior."

### Code exploration model answers
- Decision examples: privacy hybrid / two-stage distillation / classification = theme (emergent + consolidation) / sealing = trigger absorption — any 2.
- Open-question examples (concept §5): template-selection UX / real-speech WER / app name (at the time) / Obsidian bidirectional — any 2.

### Spike model interpretation
- `intention_spike2`: "FM swings 1~6/10 across runs, the verb-ending gate is 10/10" → the core message is *a deterministic rule doesn't waver with the environment*.

### Model review answers
1. **Differentiator:** "It helps you decide what to *sustain (지속)* going forward — gathering evidence so the person decides." (Summarizing/searching is not the goal.)
2. **Sealing:** "It keeps your most private thoughts *off the device* — excluded from cloud synthesis and the gallery, in a separate folder." It solves privacy as *a single action at the moment of capture*.

### Discussion facilitation notes
- Prompt: "In one word, what's the difference between your note-taking app and this one?" → draw out 'sustain (지속)'.
- Common misconception: "spike = prototype." Stress the difference — a *throwaway* experiment, done fast, discarded once you have the facts.

---

# Week 2 · v1 Foundation (Capture · Energy · Sealing)

### Blank answers
1. **@Model, @Query** · 2. **capture (포착)** · 3. **none (없다)** · 4. **usual (평소)** · 5. **audio (오디오)**
💡 *Why:* #3 "no classification UI" = zero friction. Zero decisions at the moment of capture. #4 energy is a value *relative to "my usual"* (not absolute arousal).

### Code exploration model answers
- `Capture` fields (`Models.swift:Capture`): `id, text, createdAt, energy?, sealed, tagCandidates, embedding?, theme?, sortIndex` (+ vestigial `mirrored`). Five is enough.
- Text storage: `CaptureView.swift:saveText()` → internally `save(_:energy:sealed:)` → `context.insert` + `context.save()` + `Consolidator.enqueue`.

### Model review answers
- **Why capture was built first:** "It's the heart of the app and the most important flow. Once this actually runs, everything else (themes, digest) can be stacked on top of it. The starting point of the vertical slice."

### Hands-on — grading points / common mistakes
- ✅ Does `@Query` *auto-refresh* (does it appear in the list immediately after saving)?
- Common mistakes: missing `context.save()` / unspecified `@Query` sort / creating only the sealed field without wiring up the UI toggle.
- Bonus (E): a student who narrowed scope to "text first, audio later."

### Discussion facilitation notes
- Prompt: "Why discard the audio? Wouldn't keeping it be better?" → draw out the privacy (most sensitive) + storage trade-off.

---

# Week 3 · v1 Data (Obsidian Mirror · Classification & Consolidation) ⭐

### Blank answers
Goal line: **user** · 1. **security-scoped** · 2. **centering (중심화)** · 3. **similarity (유사도)** · 4. **structured (Bool judgment)** · 5. **best-effort**
💡 *Why:* This week's core = accepting that *perfect automatic classification is impossible*. "Automation is the starting point; the person does the digesting."

### Code exploration model answers
- frontmatter keys (`ObsidianMirroring.swift:markdown`): `id, type, created, source` (+ conditional `energy`, `theme`). After the body, a `주제: [[...]]` (theme) link.
- `ThemeAssigning.swift`: `@Generable struct SameTopic { let same: Bool }` — *a per-theme "same field?" Bool instead of an index (number)*. (The on-device FM skews indices toward 0.)

### Spike report — full-marks criteria
- Table (input/expected/actual/match) + **causal interpretation**: "The pair that should merge (class1·2 = 0.209) < the pair that must not merge (hiking·food = 0.353) → the similarity ranking is inverted, so *no single threshold* can satisfy both ∴ abandon embedding clustering → FM semantic assignment. But it's unstable on-device → best-effort + curation."
- Grading: if the causal link (∴) is present, C is excellent. Merely restating the result is average.

### Model review answers
- **Why over-splitting is safer than over-merging:** "What's split too finely is easily undone with a *merge* curation, but what's wrongly merged is hard to *split* again and pollutes the repetition count (signal). So automation errs on the conservative side of splitting."

### Discussion facilitation notes
- Prompt: "Embeddings are supposed to find similar things well — why can't we trust them?" → show with the spike numbers that *the ranking is inverted* (not absolute distance).
- Misconception: "If the FM scores 5/6 on macOS, it'll work on-device too" → spike ⑥-b: *on-device behavior differs*. Imprint "the environment difference."

---

# Week 4 · v1 Digest & Cloud · Real Device

### Blank answers
1. **local, distillation** · 2. **enabled, sealing, log** · 3. **upgrade** · 4. **92.8** · 5. **Distillation (the distill step)**

### Code exploration model answers
- The filter that excludes sealed items (`Distillation.swift:distill`): `let caps = all.filter { !$0.sealed && $0.createdAt >= start && $0.createdAt < end }`.
- Transmission log model: `Transmission`(kind, charCount, date) — `Models.swift`.

### Model review answers
- **Distilled layer:** "Not the verbatim original, but a *summary abstracted by theme* by the local LLM. Only this goes to the cloud."
- **Where sealing is guaranteed:** "The `!$0.sealed` filter in `Distillation.distill` — blocked at the source when building the input that goes to the cloud. (In the final review, the same filter was added to `PeriodReview` to plug a leak.)"

### Hands-on — grading points
- A real-device demo is required (be aware simulator STT is fragile). If a student can't, substitute with a logic explanation (rubric §8 fairness).
- Bonus: a student who confirmed "the digest still works with local only, even with the cloud toggle OFF" (internalizing the cloud = upgrade principle).

### Discussion facilitation notes
- Prompt: "The place where the cloud is most needed (deep synthesis) is the most private place — how do you solve that?" → draw out two-stage distillation (concept §6 trap).

---

# Week 5 · v2 Sustain Loop (Deterministic Gate)

### Blank answers
1. **first half, second half** · 2. **pruning (가지치기)** · 3. **1~6, 10** · 4. **(deterministic) verb-ending, (intention-tool) label** · 5. **(past) decision**
💡 *Why:* This week's peak = "Decide how far to trust the AI *by measurement*." The FM assists with labels; the verdict is by rule.

### Code exploration model answers
- Intention verb-ending markers (`IntentionDetecting.swift:markers`): any 3 of `겠` (will), `해야` (must), `하자` (let's), `해보자` (let's try), `볼까` (shall I look), `할까` (shall I), `봐야지` (I should look), `야지` (I shall), `려고` (intending to), `을래/를래` (I'll), `시작하` (start), `기로 했` (decided to), `다짐` (commitment), `마음먹` (made up my mind).
- `hasIntention` return: **Bool**. **Works without the FM** (pure string substring check) — which is why it doesn't waver with the environment. (The FM is used only for the label in `extractPhrase`, falling back to the leading text of the entry on failure.)

### Essay — full-marks criteria (gist)
- Cites measured values ("FM 1~6/10 vs gate 10/10"), the trade-off ("the gate occasionally over-fires on '좋겠다' (I wish — a wish) ↔ the FM is unstable in both directions — the latter is more harmful"), and "if it were me" (e.g., a two-stage gate + weak FM confirmation, and its risks too).

### Model review answers
- **Measuring the yes-skew:** "Run the FM repeatedly on the same 10 sentences (5 intention / 5 observation), and quantify as accuracy the *instability* of over-detecting observation sentences as intention and dropping clear intentions to false (1~6/10). The verb-ending gate is a consistent 10/10 on the same input."

### Discussion facilitation notes
- Prompt: "What if the verb-ending gate also catches '좋겠다' (I wish — a wish)? Is it still better than the FM?" → *over-firing can be ignored by the user; it's safer than FM confusion*.
- Connection: foreshadow that S11 (one-week feedback) is extended into Week 6's 'precedent' (long-term).

---

# Week 6 · v3 Reachability · v4 Search · Extras

### Blank answers
1. **openAppWhenRun** · 2. **target (membership)** · 3. **full-text, semantic** · 4. **return** · 5. **HKDF, AES-GCM**

### Code exploration model answers
- Semantic search (`Search.swift:SemanticSearch.similar`): threshold **0.30**, top **6**.
- Two-stage backup (`Backup.swift:encrypt`): ① passphrase → derive a key via **HKDF-SHA256** (+ random salt) → ② **AES-GCM** seal → JSON envelope.

### Model review answers
- **Why derive with HKDF:** "A passphrase is *weak and of arbitrary length*. HKDF derives a fixed-length, strong key, and a random salt makes the same passphrase yield a different key every time → defends against dictionary attacks and reuse."
- (On semantic search only at return) "Embedding on every keystroke is wasteful and slow. Full-text search is live; semantic runs only at *search execution*."

### Hands-on — grading points
- Trigger: on a real device, from the Action Button/Siri all the way to *the app opening and recording starting*. Be aware the simulator can't do this.
- Backup: did the student confirm *wrong passphrase → decryption failure* with `backup_spike` (the security core)?

### Discussion facilitation notes
- Prompt: "How does a widget button start recording inside the app?" → because of `openAppWhenRun`, `perform` runs *in the app process* → it communicates via a singleton signal.

---

# Week 7 · Living Record · LLM Wiki

### Blank answers
1. **comes walking (걸어옴)** · 2. **14, sealed** · 3. **period (week)** · 4. **<theme>, index** · 5. **cloud (Claude)**
💡 *Why:* The meaning of the app name "Living Record (생동하는 기록)" = the record *comes to you alive* (push). This week earns that name.

### Code exploration model answers
- Resurfacing top priority (`Resurfacer.swift:daily`): **"N years/months ago today"** — old captures from the same *month and day*. If none, "something you'd forgotten for a while" (fixed per day via daySeed).
- Wiki-safing function: `WikiBuilder.safeName(_:)` — replaces `/ : [ ] # ^ | * ? " < >` and the like with spaces (preventing broken filenames/links).

### Model review answers
- **Dynamic content in repeating notifications:** "Because a repeating notification's content is *fixed*, schedule the next 7 days each *non-repeating* with *that day's resurfacing* content, and refill them to keep them current every time the app launches (`scenePhase active`)."

### Hands-on — grading points
- Wiki: in Obsidian's graph view, the shape of a *hub node with captures hanging off it*; is `[[theme]]` not a broken link?
- Resurfacing: did the student confirm in code that 14+ days old and sealed are excluded (preventing the rumination trap)?

### Discussion facilitation notes
- Prompt: "Why exclude sealed and recent (14 days) from resurfacing?" → the *rumination trap* (reviving only noisy recent worries is harmful) + sealed privacy.

---

# Week 8 · Learning from Failure & Review

### Blank answers
1. **duplication (중복)** · 2. **id** · 3. **safeguard (안전장치)** · 4. **three (3)** · 5. **period (기간)**
💡 *Why:* This week's message = *knowing how to roll back is also skill*. Failure isn't shameful — it's the most valuable teaching material.

### Code exploration model answers
- The file that was added in `git show b0d28e6 --stat` (introducing bidirectional) and disappeared in `f9fe264` (the retraction): **`ObsidianSync.swift`** (pull/reexportAll). Plus frontmatter `id:` added→removed, and `VaultStore`'s listMarkdown/subdirExists/bidirectional added→removed.

### Privacy audit — model table
| Path | Sealed excluded? | Where |
|---|---|---|
| Cloud deep synthesis (weekly) | ✅ | `!$0.sealed` in `Distillation.distill` |
| Cloud deep synthesis (period) | ✅ | `!$0.sealed` in `PeriodReview.build` (final fix) |
| Obsidian Captures/ mirror | ✅ | Sealed are separated into the `봉인/` folder (`ObsidianMirroring.mirror`) |
| Wiki hub/index | ✅ | `!$0.sealed` filter |
| **Daily/weekly *local* digest md** | ❌ (by design) | Contains sealed-derived signals — *does not go to the cloud*. Leaves the device when the vault syncs to iCloud (user-accepted) |
| Backup file | Included (encrypted) | User-owned, passphrase-protected |
💡 Full-marks tell: distinguishing the difference between **cloud vs. local/vault sync** makes D excellent.

### Model review answers
- **Why "re-export everything first" guidance alone was insufficient:** "Guidance is *easy to skip*, and auto-sync can fire before it. Existing mirror files have no `id:`, so the import turns them all into *new captures*, duplicating the entire library wholesale. → The safeguard must be *code, not guidance* (don't turn id-less files into new ones, dry-run, explicit only)."

### Discussion facilitation notes
- Prompt: "How would you fix this feature *without rolling it back*?" → draw out a separate inbox folder, hash matching, and dry-run, but conclude with *rolling back was the right call this time*.
- Closing message: "We hit the limits of embeddings *three times* (theme clustering, linking, wiki relevance) — when one signal can't be trusted repeatedly, *abandon it or use a deterministic alternative*."

---

# Appendix A · Collected Common Misconceptions (all weeks)

| Misconception | Correction |
|---|---|
| "spike = prototype" | A throwaway experiment. Get the facts and discard. |
| "if it builds, it's done" | Build ≠ behavior. Validate by running, on a real device. |
| "the AI will classify it well" | The on-device FM is unstable across environments → best-effort + curation. |
| "embeddings find similar things, so they'll link too" | *The ranking is inverted* → theme linking is untrustworthy (confirmed 3 times). |
| "the app is useless without the cloud" | Cloud = upgrade. Fully functional even OFF. |
| "sealing just means excluding the cloud" | Check the vault iCloud sync path too. |
| "bidirectional is better, isn't it" | Risk of deletion, automation, duplication. One-way is safer. |

---

# Appendix B · Quick Discrimination Criteria for Grading

- **Sign of C-excellent (evidence):** the answer has a *measured value* or a *∴ (therefore)* causal link.
- **Sign of B-deficient (validation):** only "it built" with no mention of running/spike.
- **Sign of E-bonus (failure handling):** "solved it by narrowing scope / rolling back" appears in the retrospective.
- **Sign of D-excellent (privacy):** distinguishes "cloud vs. local/vault."
- **Suspected copying:** can't explain *why* in presentation Q&A → confirm with an on-the-spot question.

---

# Appendix C · Lecture Prep Checklist (Instructor)
- [ ] Secure at least one real device (for voice/widget/notification demos).
- [ ] Open each week's *commit hash to read* in advance and prepare the diff (specified in this document and the plan).
- [ ] Run the two spikes (`intention_spike2`, `embed_spike3`) ahead of time and check the output.
- [ ] Be ready to put Week 8's bidirectional diff (`b0d28e6` ↔ `f9fe264`) on screen.


\newpage



\newpage

# Part IV · Student Materials

# Student Workbook — Learning iOS App Design with the "Living Record" App

> English translation. Korean original: `학생-워크북.md`.

> This workbook is material you study by **filling in and building yourself**. Companion materials: `프로젝트-보고서.md` (commentary) · `8주-강의계획서.md` (schedule).
> Keep these open alongside it: `concept.md` · `spike-findings.md` · `v1~v4-slices.md` · `사용설명서.md`

---

## How to Use This Workbook

- **Blanks `______`** are key terms/decisions. *Fill them in yourself first*, then check against the 〈Answer key〉 at the back.
- **`[ ]`** are items you do hands-on and check off.
- **✍ Answer:** Write in your own words on the blank line below (keep it short).
- **Rule:** No copy-and-paste ✗ → at every step, ask *"why this way?"* first.

Learner name: ______________  ·  Start date: ____________

---

# Week 1 · Methodology, Conception, and Validation

### ✅ Goals for This Week
- [ ] Can state the *single question* this app aims to answer.
- [ ] Can explain vertical slice and spike-first.
- [ ] Ran 1 spike yourself.

### 📖 Concept fill-in
1. The app's core question: "What will I ______ (do/continue)?"
2. The smallest unit of work that cuts through one flow from UI to storage = **______ ______**.
3. Code that experiments small to validate an uncertain technology before the main implementation = **______**.
4. The three-beat work discipline: implement → ______ → ______.
5. The AI goes as far as presenting evidence; the final judgment is made by the ______.

### 🔍 Code exploration
- Read through `docs/concept.md` and copy out 2 each of the **"decided items"** and the **"open items."**
  - Decided: ① ____________ ② ____________
  - Open: ① ____________ ② ____________

### 🧪 Run a spike
- [ ] In the terminal, run `cd spike && swift intention_spike2.swift` (or `embed_spike3.swift`).
- The 1 most striking number in the output and what it means: ____________

### ❓ Review questions
1. What is the single thing that makes this app different from a "voice memo + AI summary"?
   ✍ ______________________________________________
2. What problem does sealing (sealed) solve?
   ✍ ______________________________________________

### ✍ Reflection for This Week (3 sentences)
______________________________________________

---

# Week 2 · v1 Foundation: Capture → Store → List · Energy · Seal

### ✅ Goals
- [ ] Build the minimal flow that gets stored via SwiftData and appears on screen.
- [ ] Understand the decision to discard the audio and keep only the score.

### 📖 Concept fill-in
1. In SwiftData, the model declaration is `@______`, and automatic querying/refreshing is `@______`.
2. Cut through the most important flow — ______ — first.
3. The capture screen ______ (has / does not have) classification UI — the zero-friction principle.
4. Energy is interpreted not as an absolute value but as a relative value "compared to ______."
5. After recording, the most sensitive ______ original is discarded immediately.

### 🔍 Code exploration (`Models.swift`, `CaptureView.swift`)
- Write 5 fields of `Capture`: ______, ______, ______, ______, ______
- What is the name of the text-saving function? `____________`

### 🛠 Hands-on (Milestone 1)
- [ ] Create a new SwiftData model `Capture` (text, createdAt).
- [ ] Input field + "Save" button → `context.insert` → `try? context.save()`.
- [ ] Display the list with `@Query` (newest first).
- [ ] (Challenge) Seal toggle + `sealed` field.
- 1 thing you got stuck on + how you narrowed scope to solve it: ____________

### ❓ Review
- State "why capture was built first" in one sentence. ✍ ______________________

### ✍ Reflection
______________________________________________

---

# Week 3 · v1 Data: Obsidian Mirror · Classification & Integration ⭐The Hardest Week

### ✅ Goals
- [ ] Export data to markdown **one-way**.
- [ ] Hit the limits of embeddings and the FM firsthand.
- [ ] Internalize "automation is best-effort, digesting is by the ______."

### 📖 Concept fill-in
1. To access a folder outside the sandbox, a ______-______ bookmark is needed.
2. Correcting the phenomenon where embeddings cluster to one side (anisotropy) by subtracting the mean = **______**.
3. Why embedding-threshold clustering failed: the pairs that should be merged had a lower ______ than the pairs that should not be merged (the similarity ranking was off).
4. So assignment moved to the FM **______ output** (@Generable) — yet it was still unstable on-device.
5. Final design: automatic classification is ______-______, digesting is user curation.

### 🔍 Code exploration
- The 3 frontmatter keys produced by `markdown(_:)` in `ObsidianMirroring.swift`: ______, ______, ______
- The `@Generable` struct name and its field in `ThemeAssigning.swift`: ______ / ______

### 🧪 Spike Reproduction Report (submit · 15% of grade)
- [ ] Run `binary_spike.swift` or `online_spike`.
- Organize in a table: input / expected / actual / match.
- One paragraph on "why this conclusion (threshold failure → FM assignment)": ____________

### 🛠 Hands-on (Milestone 2)
- [ ] S3: Write 1 capture to a file as `.md` (frontmatter + body).
- [ ] S4: Group 2 similar captures into the same Theme (incomplete is OK).
- [ ] 1 kind of curation: rename *or* merge.

### ❓ Review
- Why is "over-splitting safer than over-merging"? ✍ ______________________

### ✍ Reflection
______________________________________________

---

# Week 4 · v1 Digesting & Cloud · On-Device Validation (Mid-Check)

### ✅ Goals
- [ ] Understand daily/weekly/period digesting and two-stage distillation.
- [ ] Feel that the simulator ≠ a real device.

### 📖 Concept fill-in
1. Two-stage distillation: keep the original text ______, and send only the ______ layer to the cloud.
2. The 3 elements of the cloud-consent model: one ______ + ______ exception + transmission ______.
3. The cloud is not a dependency but an ______ — the app must be useful even without it on.
4. The character accuracy of real speech on a real device ≈ ______ %.
5. Sealed captures are filtered out of cloud synthesis at ______ (file name).

### 🔍 Code exploration (`Distillation.swift`, `WeeklyReview.swift`)
- The one line of filter code that filters out sealed items in distillation: `____________`
- The name of the log model kept during cloud transmission: `____________`

### 🛠 Mid-Check (On-Device Demo)
- [ ] Create 1 daily digest.
- [ ] Demo one flow on a real device: voice capture → store → list (3-minute presentation).
- "The hardest decision in my v1": ____________

### ❓ Review
- What is the distillation layer? *Where* is it guaranteed that sealed items don't go to the cloud?
  ✍ ______________________________________________

### ✍ Reflection
______________________________________________

---

# Week 5 · v2 Continuation Loop (The Peak of the Deterministic Gate)

### ✅ Goals
- [ ] Know the 5 signals (repetition · energy · evolving + execution · cooling · connection).
- [ ] Understand the decide → act → feedback loop.
- [ ] Analyze the judgment to choose the ending-marker gate over the FM.

### 📖 Concept fill-in
1. Momentum splits the window into ______ and ______ and compares activity rates.
2. Cooling = the opposite side of continuation, i.e. ______ (carrying on + pruning).
3. Spike ⑦ result: FM Bool = ____/10 (fluctuating), ending-marker gate = ____/10.
4. So **the verdict is the ______ gate, and the FM is the ______ extraction aid**.
5. S11 feedback makes reflection start with "the present of the ______."

### 🔍 Code exploration (`IntentionDetecting.swift`)
- Write 3 intention ending-markers: ______, ______, ______
- What does `hasIntention` return? Does it work without the FM? ✍ ____________

### 🧪 Judgment Analysis Essay (submit · 15% of grade)
- Topic (choose 1): "ending-marker gate instead of FM" / 1 free decision.
- Frame: ① what you decided ② why (rationale · measurement) ③ trade-offs ④ what I would do.

### 🛠 Hands-on (Milestone 3)
- [ ] Choose 1: S8 (intention detection → commitment creation) *or* S9 (cooling throughline + resurfacing/folding).

### ❓ Review
- *How did you measure* the FM's "yes bias"? ✍ ______________________

### ✍ Reflection
______________________________________________

---

# Week 6 · v3 Reachability · v4 Search · Extras

### ✅ Goals
- [ ] Build system integration that captures without opening the app.
- [ ] Understand hybrid search and honest labeling ("estimated").

### 📖 Concept fill-in
1. The property that makes an App Intent launch the app = `______`.
2. For a button in a widget to run an intent, that type must also be included in the widget ______.
3. Search: exact containment = ______ search (primary · trusted), similar meaning = ______ search (secondary · estimated).
4. Semantic search is expensive, so it runs not on every keystroke but only when ______ is pressed.
5. Encryption: rather than using the passphrase directly as a key, derive it via ______, then encrypt with ______-______.

### 🔍 Code exploration (`Search.swift`, `Backup.swift`)
- The semantic search threshold and the top-N count: ______ / ______
- The 2 stages of the backup encryption function: ______ → ______

### 🛠 Hands-on (Milestone 4)
- Implement and demo **2** of: trigger / search / backup.
  - [ ] Choice 1: ____________
  - [ ] Choice 2: ____________

### ❓ Review
- Why *derive* the key with HKDF (instead of using it directly)? ✍ ____________

### ✍ Reflection
______________________________________________

---

# Week 7 · Living Record (Resurfacing) · LLM Wiki

### ✅ Goals
- [ ] Understand the pull → push shift (the past comes walking to you).
- [ ] Structure the vault as an LLM knowledge base (wiki).

### 📖 Concept fill-in
1. Change the app from "going to look (pull)" to "the past ______ (push)."
2. To prevent the rumination trap, resurfacing picks from older than ______ days + excluding the previous · ______.
3. A throughline = a theme that has been returned to again and again across multiple ______.
4. The wiki hub = `Themes/______.md` per theme, the entrance = `______.md`.
5. The hub's "at-a-glance" summary is filled only by the ______ (opt-in).

### 🔍 Code exploration (`Resurfacer.swift`, `WikiBuilder.swift`)
- What is the top-priority selection criterion for resurfacing? ✍ ____________
- The function that sanitizes wiki hub file names/links: `____________`

### 🛠 Hands-on (Milestone 5)
- [ ] Resurfacing (1 of echo / resurfacing / precedent / throughline) *or* wiki hub generation.
- (If wiki) What appeared in the vault graph view: ____________

### ❓ Review
- How did you load *dynamic content* into a repeating notification? ✍ ____________

### ✍ Reflection
______________________________________________

---

# Week 8 · Learning from Failures and Checks · Synthesis

### ✅ Goals
- [ ] Know that being able to roll back is also a skill.
- [ ] Audit the privacy invariant to the very end.

### 📖 Concept fill-in
1. The bidirectional-Obsidian thinking = ______ creation (cloning the entire library).
2. The root cause: the existing files had no ______, so everything was imported as a "new capture."
3. Lesson: deletion and auto-sync are risky → explicit · ______ · dry-run by default.
4. Met the embedding limit ______ times (theme clustering · connection · wiki related-themes) and eventually gave up / found an alternative.
5. In the final review, fixed a leak where ______ digesting was sending sealed theme names to the cloud.

### 🔍 Code exploration (diff comparison)
- Compare `git show b0d28e6 --stat` with `git show f9fe264 --stat`.
- The file that was added on introduction and disappeared on withdrawal: `____________`

### 🛠 Final (Submit)
- **Privacy audit (10% of grade):** A table of "every path by which a sealed item could leave the device."
  | Path | Is the seal excluded? | Where |
  |---|---|---|
  | Cloud deep synthesis | | |
  | Obsidian Captures/ mirror | | |
  | Digests/ on vault iCloud sync | | |
- **Final project (30% of grade):** Your own slice/extension + presentation.

### ❓ Review
- Why was guidance of "re-export everything first" alone not enough?
  ✍ ______________________________________________

### ✍ Final Reflection (one page)
One moment in this project where you learned *judgment over code*:
______________________________________________

---

# Appendix A · Self-Check Fill-in Answer Key & Hints

> Check *after you fill them in yourself*. What matters is not the answer but *why it is so*.

**Week 1:** 1 continue (지속) · 2 vertical slice · 3 spike · 4 (run-)validate, commit · 5 user
**Week 2:** 1 @Model, @Query · 2 capture · 3 does not have · 4 the usual (평소) · 5 audio
**Week 3:** by the user · 1 security-scoped · 2 centering · 3 similarity · 4 structured (Bool/index) · 5 best-effort
**Week 4:** 1 local, distillation · 2 turn on, seal, log · 3 upgrade · 4 92.8 · 5 Distillation (distillation)
**Week 5:** 1 first half, second half · 2 pruning · 3 1–6, 10 · 4 (deterministic) ending-marker, (intention-phrase) label · 5 (last) decision
**Week 6:** 1 openAppWhenRun · 2 target (membership) · 3 full-text, semantic · 4 return (key) · 5 HKDF, AES-GCM
**Week 7:** 1 comes walking · 2 14, sealed · 3 period (week) · 4 <theme>, index · 5 cloud (Claude)
**Week 8:** 1 duplicate · 2 id · 3 safeguard · 4 three (3) · 5 period

---

# Appendix B · Common Sticking Points & Remedies

| Symptom | Remedy |
|---|---|
| Speech recognition doesn't work in the simulator | Normal — STT assets are fragile in the simulator. Use a **real device**. |
| Builds fine but behaves strangely | A passing build ≠ working behavior. *Run it and verify yourself* before committing. |
| Themes get grouped oddly | Normal — automation is best-effort. Fix it with **curation**. |
| One feature keeps breaking | Retry by **narrowing scope further** (e.g. text only first, not voice). |
| Too much at once | Cut down to a single vertical slice (one flow only). |

---

# Appendix C · Quick Glossary
vertical slice · spike · seal · two-stage distillation · centering · best-effort + curation · deterministic gate · pull→push.
(For meanings, see `프로젝트-보고서.md` §8-3 glossary)


\newpage

# Quiz & Exam Question Bank — "Living Record" Project Course

> English translation. Korean original: `문제은행.md`.

> Companions: `course-syllabus.md` · `project-report.md` · `grading-rubric.md` · `instructor-answer-key.md`
> **Answers & explanations are at the very end in 〈Appendix: Answers & Explanations〉 (instructor only)** — remove that section before distributing to students.
> Written 2026-06-05

---

## How to Use

- **Question ID** examples: `W3-MC2` (Week 3, multiple choice #2), `X-ES1` (cross-cutting essay #1). Pick by ID to assemble an exam.
- **Type:** MC (multiple choice) · TF (true/false) · FB (fill-in-the-blank) · SA (short answer) · CODE (code reading) · ES (essay / design judgment).
- **Difficulty:** ★ (recall) · ★★ (comprehension & application) · ★★★ (analysis & judgment).
- **Competency tags:** A Slice · B Verification · C Rationale · D Privacy · E Failure-handling (linked to the grading rubric).

---

# Part 1 · Questions by Week

## Week 1 — Methodology · Conception · Verification

**W1-MC1 ★ [C]** What is the "single question" this app sets out to answer?
① How can I take notes faster ② What to sustain ③ How can I summarize well ④ Which font is best

**W1-MC2 ★★ [B]** Which best describes the purpose of a spike?
① To pre-build a reusable module ② To pick a design mockup ③ To validate an uncertain technology with a *throwaway experiment* ④ To finalize the production UI

**W1-TF1 ★ [B]** (True/False) "If the build succeeds, the feature is done."

**W1-SA1 ★ [A]** What do we call the smallest unit of work that runs all the way through a single flow from UI to storage?

**W1-SA2 ★★ [B]** State the biggest difference between a spike and a prototype in one sentence.

**W1-FB1 ★ [C]** The three-beat work rhythm: implement → ______ → commit.

---

## Week 2 — Capture · Energy · Sealing

**W2-MC1 ★ [A]** In SwiftData, which property pair is used for model declaration and automatic querying?
① `@State`/`@Binding` ② `@Model`/`@Query` ③ `@Observable`/`@Environment` ④ `@Entity`/`@Fetch`

**W2-MC2 ★★ [D]** What is the main reason for *discarding the raw audio immediately* after recording and keeping only the energy score?
① Battery savings ② Protecting privacy by not accumulating the most sensitive data ③ Improving STT accuracy ④ Cloud upload speed

**W2-TF1 ★ [A]** (True/False) The capture screen has a classification UI for choosing a theme.

**W2-SA1 ★★ [C]** The energy (arousal) score is interpreted not as an absolute value, but as a value relative to what?

**W2-CODE1 ★★ [A]** Fill in the blanks for the following flow. When saving text in `CaptureView`: `context.insert(c)` → `try? context.______()` → `Consolidator.______(c, ...)`.

---

## Week 3 — Obsidian Mirror · Classification · Consolidation ⭐

**W3-MC1 ★★ [B]** Why is "centering" needed for Korean embeddings?
① To increase speed ② To correct the anisotropy where vectors cluster to one side ③ To exclude sealed items ④ To convert Hangul encoding

**W3-MC2 ★★★ [B,C]** Which most accurately states why embedding-threshold clustering *fundamentally* failed?
① The embedding dimension was too small ② The similarity of pairs that should merge was lower than that of pairs that must not merge, so *the ranking was inverted* ③ It did not support Korean ④ The computation was too slow

**W3-TF1 ★★ [E]** (True/False) For automatic classification, "over-merging" is safer than "over-splitting."

**W3-SA1 ★★ [C]** State the final design principle for automatic classification in a short phrase (e.g., "○○○○ + curation").

**W3-CODE1 ★★★ [C]** `ThemeAssigning.swift` asks "same field?" using `@Generable struct SameTopic { let same: Bool }` instead of a theme *index (number)*. State in one sentence why the number-based approach was abandoned.

---

## Week 4 — Digest · Cloud · Real Device

**W4-MC1 ★★ [D]** What is the core idea of "two-stage distillation"?
① It compresses the data twice ② The original stays local and *only the distilled layer (summary)* is sent to the cloud ③ It summarizes twice in the cloud ④ It encrypts the seal in two stages

**W4-MC2 ★★ [D]** Fill in the blank: "The cloud is not a dependency but a ______."
① necessity ② backup ③ upgrade ④ risk

**W4-TF1 ★ [B]** (True/False) Voice dictation works just as well in the simulator as on a real device.

**W4-SA1 ★★ [D]** At *which step in the code* is it guaranteed that sealed captures do not go to the cloud?

**W4-FB1 ★ [B]** Real-device, real-voice character accuracy (by CER) ≈ ______%.

---

## Week 5 — Sustain Loop · Deterministic Gate

**W5-MC1 ★ [A]** Which is NOT one of the new signals added in v2?
① Action (commitment / 다짐) ② Cooling ③ Connection ④ Font

**W5-MC2 ★★★ [B,C]** Which is the correct conclusion of intention detection from spike ⑦?
① The FM Bool was the most stable ② The ending-marker gate (10/10) was more stable than the FM (1~6/10) → the judgment is the gate, and the FM only assists with labels ③ Neither is usable ④ The embedding was the most accurate

**W5-CODE1 ★★ [B]** `IntentionDetecting`'s `hasIntention` works even without the FM. Why?

**W5-SA1 ★★ [C]** Momentum (rising / cooling) is computed by splitting the window into what and what for comparison?

**W5-ES1 ★★★ [C]** (Essay, 5 sentences) Explain the decision to "choose the Korean ending-marker gate over the FM Bool," citing *evidence (measured values) and trade-offs*.

---

## Week 6 — Reachability · Search · Add-ons

**W6-MC1 ★★ [A]** Which property makes an App Intent bring the app to the foreground when triggered?
① `runsInBackground` ② `openAppWhenRun` ③ `launchOnTrigger` ④ `foregroundOnly`

**W6-MC2 ★★ [C]** In hybrid search, which side is the *primary / trusted* one?
① Semantic search ② Full-text (exact-match) search ③ Voice search ④ Tag search

**W6-MC3 ★★ [D]** Which is NOT an appropriate reason for deriving the key via HKDF rather than using the passphrase *directly* as the key?
① A fixed-length, strong key ② A random salt makes the same passphrase yield a different key each time ③ Defense against dictionary attacks ④ Reducing file size

**W6-SA1 ★★ [A]** Because of its cost, semantic search runs not on every keystroke but when?

**W6-CODE1 ★★★ [A]** Explain how the widget's button starts recording *inside the app*, from the perspective of `openAppWhenRun`.

---

## Week 7 — Living Record · LLM Wiki

**W7-MC1 ★ [A]** Express this stage's design shift as a one-word pair.
① push→pull ② pull→push ③ local→cloud ④ text→voice

**W7-MC2 ★★★ [D,C]** What is the *main reason* resurfacing selects candidates that are 14+ days old and excludes sealed items?
① Storage space ② Preventing the rumination trap + privacy ③ Speed ④ Cloud cost

**W7-SA1 ★★ [A]** Define "throughline" in one sentence.

**W7-MC3 ★★ [D]** How is the wiki hub's "at-a-glance" summary populated?
① Always automatically, locally ② Only via cloud (Claude) opt-in and explicit refresh ③ The user types it manually ④ It is never populated

**W7-CODE1 ★★★ [A]** A repeating notification has fixed content — so how was a *different* resurfacing item delivered each day?

---

## Week 8 — Learning from Failures & Reviews

**W8-MC1 ★★★ [E,D]** What is the *root cause* of the "duplicate creation" incident in bidirectional Obsidian?
① A network error ② The existing mirror files had no `id:`, so the import treated them all as "new captures" and duplicated them ③ Lost passphrase ④ Embedding failure

**W8-TF1 ★★ [E]** (True/False) The *guidance note* alone ("re-export everything first") was sufficient to prevent the duplication incident.

**W8-SA1 ★★ [B]** *How many times* did this project repeatedly confirm that embedding-based theme linking cannot be trusted? (Bonus for naming the three points.)

**W8-CODE1 ★★ [E]** What *key file* was added in `git show b0d28e6` (bidirectional introduction) and removed in `f9fe264` (rollback)?

**W8-ES1 ★★★ [D]** (Essay) Name three or more "paths by which a sealed item could leave the device," and for each state whether the seal is excluded and where.

---

# Part 2 · Cross-cutting Essays

**X-ES1 ★★★ [C,E]** Pick one decision that was *reversed/abandoned* in this project (bidirectional Obsidian, removal of embedding-based related themes, the FM Bool, etc.) and analyze it in a one-page write-up using the frame "what · why · trade-off · what I would do."

**X-ES2 ★★★ [B]** Explain, with examples, how the "spike-first" discipline changed *three or more* design decisions in this app (embedding · STT · intention detection · search, etc.).

**X-ES3 ★★★ [D]** Explain this app's privacy model (local-first · two-stage distillation · sealing · transmission log), and present one *remaining* risk together with a hardening proposal.

**X-ES4 ★★ [A]** Write two advantages of working in "vertical slices," and one problem that arises when a single flow is scoped *too broadly*.

**X-SA1 ★★ [C]** What did this app use to decide "how far to trust the AI"? (One word/phrase.)

---

# Part 3 · Advanced Code Reading

**C-CODE1 ★★★ [D]** Below is part of the distillation code. Explain the *privacy invariant* this one line guarantees.
```swift
let caps = all.filter { !$0.sealed && $0.createdAt >= start && $0.createdAt < end }
```

**C-CODE2 ★★ [B]** Explain, in terms of a property of the code, why the following intention ending-marker gate is said to be "unshaken by the environment."
```swift
static let markers = ["겠", "해야", "하자", "봐야지", "려고", "시작하", "다짐", ...]
func hasIntention(_ text: String) -> Bool { Self.markers.contains { text.contains($0) } }
```

**C-CODE3 ★★★ [A]** In the following resurfacing selection logic, explain what the "top priority" is, and what `daySeed` does.
```swift
// anniversaries: 같은 월·일의 옛 포착
if let pick = anniversaries.min(by: { $0.createdAt < $1.createdAt }) { return ... }
let daySeed = Int(today.timeIntervalSince1970 / 86_400)
let idx = ((daySeed % pool.count) + pool.count) % pool.count
```

---

# Part 4 · Exam Blueprint Examples

### Midterm (W1~W4, 100 points, 50 min)
- MC/TF 10 questions × 4 pts = 40 (`W1-MC1·MC2`, `W2-MC1·MC2·TF1`, `W3-MC1·MC2·TF1`, `W4-MC1·TF1`)
- SA 4 questions × 6 pts = 24 (`W1-SA1`, `W2-SA1`, `W3-SA1`, `W4-SA1`)
- CODE 2 questions × 8 pts = 16 (`W2-CODE1`, `W3-CODE1`)
- ES 1 question × 20 pts = 20 (`X-ES4` or `X-ES2`)

### Final (entire course, 100 points, 80 min)
- MC/TF 12 questions × 3 pts = 36 (1~2 from each week, evenly)
- SA 4 questions × 6 pts = 24 (`W5-SA1`, `W6-SA1`, `W7-SA1`, `W8-SA1`)
- CODE 2 questions × 10 pts = 20 (`C-CODE1`, `W7-CODE1`)
- ES 1 question × 20 pts = 20 (`X-ES1` or `X-ES3`)

> **Balance tip:** Ensure every exam includes at least one question from each competency A~E. Center the ES on *rationale (C) · privacy (D) · failure-handling (E)*.

---

# Appendix · Answers & Explanations [INSTRUCTOR ONLY — remove before distributing to students]

### Week 1
- **W1-MC1** ② — "sustaining" is the differentiator.
- **W1-MC2** ③ — a spike is a *throwaway* experiment (gain the facts only, then discard).
- **W1-TF1** False — build ≠ working. Real-run / real-device verification is required.
- **W1-SA1** vertical slice (수직 슬라이스).
- **W1-SA2** e.g. "A spike is a *throwaway* experiment that removes uncertainty only and is then discarded; a prototype is a draft you can develop and keep."
- **W1-FB1** (run-)validate.

### Week 2
- **W2-MC1** ② — `@Model`/`@Query`.
- **W2-MC2** ② — not accumulating the most sensitive audio protects privacy (+ saves storage).
- **W2-TF1** False — there is no classification UI (zero friction).
- **W2-SA1** relative to "(my) usual."
- **W2-CODE1** `save` / `enqueue`.

### Week 3
- **W3-MC1** ② — anisotropy correction.
- **W3-MC2** ② — the similarity *ranking* is inverted (e.g., 0.209 < 0.353) → no single threshold works.
- **W3-TF1** False — *over-splitting* is safer than over-merging (easy to undo by merging).
- **W3-SA1** best-effort.
- **W3-CODE1** e.g. "When the on-device FM had only one theme, it *skewed* all indices to 0 → over-merging; the Bool judgment avoids this."

### Week 4
- **W4-MC1** ② · **W4-MC2** ③ · **W4-TF1** False (simulator STT is weak) · **W4-FB1** 92.8.
- **W4-SA1** The `!$0.sealed` filter at the `Distillation` step (+ also added to `PeriodReview`).

### Week 5
- **W5-MC1** ④ · **W5-MC2** ②.
- **W5-CODE1** "A marker substring check (pure string) — there is no FM call, so it is deterministic and unshaken by the environment. The FM is used only for labeling (extractPhrase), with a fallback on failure."
- **W5-SA1** the first half (earlier half) / the second half (recent half).
- **W5-ES1** Rubric: stronger if it includes measured values (10/10 vs 1~6/10), the trade-off (over-firing on '좋겠다' / "I wish" ↔ FM instability), and a "what I would do."

### Week 6
- **W6-MC1** ② · **W6-MC2** ② · **W6-MC3** ④ (unrelated to file size).
- **W6-SA1** only when search is executed (on return).
- **W6-CODE1** "Because of `openAppWhenRun`, the intent's perform runs *in the app process* → setting a singleton (AppLaunchState) signal lets SwiftUI observe it and start recording."

### Week 7
- **W7-MC1** ② · **W7-MC2** ② · **W7-MC3** ②.
- **W7-SA1** "A theme that keeps coming back across multiple periods (different weeks) = something you cared about consistently."
- **W7-CODE1** "Schedule the next 7 days each *non-repeating* with *that day's resurfacing* content, and refill them to keep them current every time the app becomes active."

### Week 8
- **W8-MC1** ② · **W8-TF1** False (guidance is easy to skip and auto-sync fires first → the safeguard must be *code*).
- **W8-SA1** 3 times — theme clustering (S4) · linking (S10) · wiki related themes (7-3).
- **W8-CODE1** `ObsidianSync.swift`.
- **W8-ES1** Rubric: cloud (✅ Distillation/PeriodReview) · Captures mirror (sealed are separated into `봉인/`) · wiki (✅) · *the local digest md does include sealed items but does not go to the cloud* · vault iCloud sync risk — excellent on D when it distinguishes cloud vs local/vault.

### Cross-cutting & Advanced Code
- **X-SA1** "by measurement (the spike)" — trust only as far as proven; where it can't be trusted, use a deterministic rule.
- **C-CODE1** "When building the cloud input, sealed captures are excluded at the source → a seal never goes to the cloud."
- **C-CODE2** "A pure substring check with no FM call → the same input always yields the same result (deterministic). Unlike the FM, which fluctuates across device/OS/run, it is consistent."
- **C-CODE3** "Top priority = the 'today, N years ago' of the same month and day. `daySeed` (a per-day seed) produces an index that is *fixed for the whole day*, so the candidate doesn't change if you look again the same day."

---

> **Authoring principle (instructor):** Mix ★/★★/★★★ at roughly 7:2:1, and require *rationale and trade-offs* in the essays (ES). The more questions ask **"why"** rather than rote recall, the better they fit the spirit of this course.


\newpage

# Student Portfolio — "Living Record" Project

> English translation. Korean original: `학생-포트폴리오-템플릿.md`.

> **Copy this file and fill it in under your own name** (e.g., `portfolio-honggildong.md`). A form for *gathering evidence* over 8 weeks.
> Assessment linkage: `채점-루브릭.md` (Competencies A–E) · `8주-강의계획서.md` (milestones).
> Writing rule: the **what · why · evidence** triad. An item without a "why" is as good as blank.

---

## 0. Cover Page

| | |
|---|---|
| **Name** | ________________ |
| **Section / Student ID** | ________________ |
| **Period** | 20__ . __ . __ ~ 20__ . __ . __ |
| **Repository (GitHub, etc.)** | ____________________ |
| **Dev environment** | Xcode ____ · physical device ____ |

**One-line introduction:** ____________________________________________

---

## 1. Start — Goals and Expectations (write in Week 1)

- The *one thing you most want to learn* in this course: ____________________
- The competency you're weakest at (among A–E) and why: ____________________
- What you want to build by the end (final project concept): ____________________

> 💡 After the course ends, reread this box in §7 and reflect on *how much has changed*.

---

## 2. Competency Map (the 5 core competencies — what to develop)

| Competency | Meaning | My one-line goal |
|---|---|---|
| **A Slice** | Breaking work into the smallest working units | |
| **B Verification** | Confirming via spikes / execution | |
| **C Rationale** | Leaving behind the "why" | |
| **D Privacy** | Boundaries for sensitive data | |
| **E Failure-handling** | Narrowing the scope or rolling back | |

---

## 3. Weekly Learning Journal (W1–W8)

> Use the same form every week. *Evidence* should be commit hashes, screenshots, or code snippets.

### ▷ Week N — (Theme: ____________)  *copy and fill in all 8*

- **What you did this week (one flow):** ____________________
- **One newly learned concept:** ____________________
- **Where you got stuck → how you narrowed/rolled back to solve it:** ____________________  *(Competency E)*
- **Why you decided that way (one design decision):** ____________________  *(Competency C)*
- **Evidence:**
  - Commit: `________`  (one-line summary: ________)
  - Screenshot / graph: `[paste image link or screenshot here]`
  - 3–5 lines of key code:
    ```swift
    
    ```
- **My answer to one review question:** ____________________
- **One-line reflection for this week:** ____________________

*(W1 methodology · concept / W2 capture · energy · seal / W3 mirror · classification · integration / W4 digest · cloud / W5 persistence loop / W6 reachability · search · extras / W7 resurfacing · wiki / W8 failure · review)*

---

## 4. Collection of Core Deliverables

### 4-1. Milestones (M1–M5)
> Each milestone: *what you built + proof it works + the hardest decision*.

| # | Week | What you built | Proof it works (commit/screenshot) | Hardest decision |
|---|---|---|---|---|
| M1 | 2 | | | |
| M2 | 3 | | | |
| M3 | 5 | | | |
| M4 | 6 | | | |
| M5 | 7 | | | |

### 4-2. Spike-Reproduction Report (Week 3 · 15% of rubric)
- Target spike: ____________  (`spike/________.swift`)
- Execution results table:

| Input | Expected | Actual | Match |
|---|---|---|---|
| | | | |
| | | | |

- **Why this conclusion (causal ∴):** ____________________________________________
- **Impact on the design:** ____________________

### 4-3. Design-Decision Essay (Week 5 · 15% of rubric)
- Decision analyzed: ____________  (e.g., suffix gate instead of FM Bool / bidirectional retraction / removing related themes)
- **Gist (4 lines):** ① What ____ ② Why (rationale · measurement) ____ ③ Trade-offs ____ ④ What I would do ____
- Full text link / attachment: `____________`

### 4-4. Privacy Audit (Week 8 · 10% of rubric)
> Fill in "every path by which a seal could leave the device."

| Path | Excludes sealed content? | Where (code reference) |
|---|---|---|
| Cloud deep synthesis (weekly) | | |
| Cloud deep synthesis (period) | | |
| Obsidian Captures/ mirror | | |
| LLM wiki hub/index | | |
| Daily/weekly local digest md | | |
| When vault syncs via iCloud | | |
| Encrypted backup | | |

- **One remaining risk + mitigation:** ____________________

### 4-5. Final Project (30% of rubric)
- **Title / one-line description:** ____________________
- **Design process (make the flow visible):**
  - Design decision / doc: ____________
  - Spike (verification): ____________
  - Slice (implementation scope): ____________
  - Verification (physical-device / measured results): ____________
- **Evidence:** commit `____` · demo video/screenshot `____`
- **Privacy considerations:** ____________  *(does the new feature also keep the seal/raw-content boundary?)*
- **Core message of the presentation (why you built it this way):** ____________________
- **Where you got stuck / what you rolled back / what you learned:** ____________________  *(Competency E)*

---

## 5. Competency Self-Assessment (A–E · self-grade on 4 levels + evidence)

> 4 Excellent / 3 Strong / 2 Fair / 1 Weak. Include *evidence (which item in this portfolio)*.

| Competency | My level (1–4) | Rationale (portfolio §) |
|---|---|---|
| A Slice | | |
| B Verification | | |
| C Rationale | | |
| D Privacy | | |
| E Failure-handling | | |

- The competency you're most confident in and its decisive evidence: ____________________
- Your weakest competency and how you'll improve it next: ____________________

---

## 6. Code & Deliverables Index (all submissions at a glance)

| Item | Location (file / commit / link) |
|---|---|
| Repository root | |
| Key slice code | |
| Spike code / output | |
| Demo video / screenshot | |
| (If wiki) Obsidian graph screenshot | |

---

## 7. Final Reflection (at the end of the course)

1. **One moment you learned *judgment* rather than code:** ____________________________________________
2. **The decision you're most proud of (and its rationale):** ____________________
3. **What you'd do differently if you started over (and why):** ____________________
4. **Compared with your starting goals in §1 — what changed:** ____________________

> One free-form paragraph of reflection:
> ____________________________________________
> ____________________________________________

---

## 8. (Optional) Feedback

- **Peer feedback (name: ____):** ____________________
- **Instructor feedback:** ____________________

---

## 9. Submission Checklist

- [ ] Cover page and starting goals written
- [ ] 8 weekly journals (each with *evidence*)
- [ ] Milestone table M1–M5
- [ ] Spike report (table + causal reasoning)
- [ ] Design-decision essay
- [ ] Privacy audit table
- [ ] Final project (design → verification → presentation)
- [ ] Competency self-assessment + evidence
- [ ] Final reflection
- [ ] Verify that every *evidence link* actually opens

> **Signs of a strong portfolio (self-check):**
> Each item has a *why (C)* · comes with *proof it works (A)* · shows *verification (B)* · is conscious of *privacy (D)* · and bears traces of *narrowing/rolling back from a blocker (E)*.


\newpage


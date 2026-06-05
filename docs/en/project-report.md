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

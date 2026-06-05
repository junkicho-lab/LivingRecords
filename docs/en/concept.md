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

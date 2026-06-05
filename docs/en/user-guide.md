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

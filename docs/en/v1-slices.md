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

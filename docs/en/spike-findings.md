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

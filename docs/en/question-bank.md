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

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

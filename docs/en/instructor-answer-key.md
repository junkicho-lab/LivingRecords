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
- The file that was added in `git show 184c6a9 --stat` (introducing bidirectional) and disappeared in `59f559c` (the retraction): **`ObsidianSync.swift`** (pull/reexportAll). Plus frontmatter `id:` added→removed, and `VaultStore`'s listMarkdown/subdirExists/bidirectional added→removed.

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
- [ ] Be ready to put Week 8's bidirectional diff (`184c6a9` ↔ `59f559c`) on screen.

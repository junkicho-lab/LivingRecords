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

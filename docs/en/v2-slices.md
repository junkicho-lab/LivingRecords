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

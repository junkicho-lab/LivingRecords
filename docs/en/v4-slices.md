# Living Record — v4 Slice Plan (Search · Semantic Exploration)

> English translation. Korean original: `v4-slices.md`.

> Written: 2026-06-04 · Basis: `spike-findings.md` ⑧, user decision (hybrid)
> Platform: iOS 26+ · Workflow: implement → verify on a real device → commit

## 0. Goal — Refind Accumulated Captures + Use Embeddings That Were Only Stored

v1~v3 had no search. The more captures pile up, the more essential it becomes. At last we use the **512d embeddings** that had only been stored, unused, since v1.

## 1. Firm Decisions (basis: spike ⑧)

- Semantic-search ranking is **coarse** (top-1 3/6, top-3 5/6). Cannot be trusted as precise.
- **Hybrid**: **full-text (exact contains) = primary, trusted** + **semantic ('similar records') = secondary, estimated** (threshold ~0.30, top 6, 'estimated' label).
- Location: **the search bar in the Records tab** (`.searchable`). Not expanded to 5 tabs.
- Performance: full-text is live; semantic embeds **only when search runs (on return)** (not embedding on every keystroke).

## 2. Slices

### S15 · Hybrid Search ✅ Done (2026-06-04)
- **Includes**: `SemanticSearch.similar()` (embed the query → centered cosine → threshold · top). CaptureListView `.searchable`: empty query = existing list, query = 「exact contains」 + 「similar records (estimated)」 sections. Semantic search on onSubmit; reset when the query is cleared. Empty-result state view.
- **Verification**: build · install · launch OK. Semantic quality · threshold confirmed via spike ⑧. The feel on real data is for a real device.
- **Depends on**: v1 embeddings (already stored).

## 3. v4 Boundary
- **v4**: hybrid search.
- **post-v4**: iCloud sync · encrypted backup · MLX fallback bundle · two-way Obsidian · custom templates · visualization. + Reserved: v2 threshold tuning.

## Status
- **S15 ✅ Done.** (Semantic threshold 0.30 · top 6 leave room for tuning on real data — included in reserved work.)

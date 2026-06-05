---
title: "Learning iOS App Design with Living Record"
subtitle: "From concept to 67 commits — a project textbook that follows the flow of judgment"
author: "Living Record Project"
date: "2026"
lang: en
toc: true
toc-depth: 2
numbersections: false
documentclass: report
---

# Preface

This book bundles the full journey of one iOS app — **"Living Record (생동하는 기록)"** — from *concept → validation → 67 commits*, organized so you can **study it one step at a time**.

On the surface it is a voice-memo app. But what this book teaches is not code; it is **the flow of judgment** — what to automate vs. leave to the person, what to trust vs. verify, when to push vs. roll back.

## Who is this for
- **Students** learning SwiftUI/SwiftData who want to build *design thinking*.
- **Instructors** running a project-based (PBL) course (includes 8-week plan, rubric, question bank).
- **Self-learners** following a real app's decisions and failures.

> Prerequisite: basic Swift (variables, functions, optionals, closures). SwiftUI/SwiftData are taught in the text.

## Structure (4 Parts)
- **Part I · Main Text (Study Report)** — the whole journey in 9 phases / 25 study units. *The spine of the book.*
- **Part II · Design Source Material** — the concept (decision log), technical validation (spikes), per-phase plans, finished-app user guide. *The primary sources for "why."*
- **Part III · Course Operation (instructor)** — syllabus, grading rubric, instructor answer key.
- **Part IV · Student Materials** — workbook, question bank, portfolio template.

> The **slide deck (Marp)** does not fit a linear book; it lives separately at `en/slides.md` — convert with `marp` or the VS Code Marp extension.

## Reading paths
| Goal | Path |
|---|---|
| **Self-study** | Read Part I (report) phases 0→8, cross-reading the source material in Part II |
| **8-week course (student)** | Fill the Part IV workbook weekly; consult Part I |
| **8-week course (instructor)** | Part III syllabus → weekly Part I units + slides; assess with rubric + question bank |
| **Just the app** | Part II *user guide* |

**How to study:** for each unit, ① read the *why* (decision) first → ② read the related code file line by line → ③ check the commit diff for *what was added* → ④ answer the review questions yourself.

## Making a student edition (instructor)
This combined master edition includes **answers, model answers, and the rubric**. Build a student-facing edition with:
```bash
docs/교재/build.sh en --student     # excludes instructor materials + strips the question-bank answer appendix
```

## See also
- **Source code** — `LivingRecord/` (42 Swift files + widget), `spike/` (24 validation scripts).
- **Commit history** — `git log --reverse --oneline` (S0 scaffolding → final review).
- **Korean originals** — the `docs/` folder.

---

> Read the code, but ask **why it was decided that way** first. That answer is the main text of this book.

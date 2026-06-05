# Living Record — Teaching Package (English)

English translations of the educational package for the **"Living Record (생동하는 기록)"** iOS app-design course.
Korean originals live in `../` (the `docs/` folder).

| Document | English | Korean original | For |
|---|---|---|---|
| Project Report (study guide) | [`project-report.md`](project-report.md) | `../프로젝트-보고서.md` | everyone |
| 8-Week Course Syllabus | [`course-syllabus.md`](course-syllabus.md) | `../8주-강의계획서.md` | instructor |
| Slide Deck (Marp) | [`slides.md`](slides.md) | `../주차별-슬라이드개요.md` | instructor |
| Instructor Answer Key | [`instructor-answer-key.md`](instructor-answer-key.md) | `../강사용-모범답안집.md` | instructor only |
| Grading Rubric | [`grading-rubric.md`](grading-rubric.md) | `../채점-루브릭.md` | instructor |
| Student Workbook | [`student-workbook.md`](student-workbook.md) | `../학생-워크북.md` | student |
| Quiz / Exam Question Bank | [`question-bank.md`](question-bank.md) | `../문제은행.md` | instructor (answers appendix) |

## Primary source material (Korean, not translated)
- `../concept.md` — design decisions & open questions
- `../spike-findings.md` — on-device Korean AI validation (spikes ①–⑧)
- `../v1-slices.md` … `../v4-slices.md` — per-phase build plans
- `../사용설명서.md` — finished-app user guide

## Notes for English readers
- The app's UI and the captured notes are in **Korean**; feature names appear as *English (Korean)* on first use.
- Some lessons hinge on **Korean grammar** (e.g. intention/volitional endings 겠/해야/하자/봐야지/려고). These are kept in Korean with an English gloss, because the lesson *is* "a deterministic rule on Korean endings beat the on-device LLM."
- Code identifiers, file names, and commit hashes are left as-is so they match the repository.
- Render slides with the VS Code **Marp** extension or `marp slides.md` (→ PDF/PPTX).

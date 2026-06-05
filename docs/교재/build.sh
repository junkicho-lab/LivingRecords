#!/usr/bin/env bash
# 단일 통합 교재 조립기 — Markdown 합본(+ Pandoc PDF, 있으면).
#   build.sh [ko|en] [--student]
#     ko(기본): 한국어 마스터판   en: 영문 마스터판
#     --student: 강사용 자료(루브릭·모범답안) 제외 + 문제은행 정답 절 제거
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DOCS="$(dirname "$HERE")"            # .../docs
LANG_SEL="${1:-ko}"
STUDENT=""
case " $* " in *" --student "*) STUDENT=1 ;; esac

# part divider 를 합본에 써넣는다
part() { printf '\n\n\\newpage\n\n# %s\n\n' "$1" >> "$OUT"; }
chap() { # 파일을 page-break와 함께 덧붙임
  [ -f "$1" ] || { echo "  (없음: $1)"; return; }
  cat "$1" >> "$OUT"; printf '\n\n\\newpage\n\n' >> "$OUT"
}
# 문제은행: 학생 모드면 정답 부록 잘라내기
qbank() {
  local f="$1" marker="$2"
  if [ -n "$STUDENT" ]; then
    awk -v m="$marker" 'index($0,m)==1{exit} {print}' "$f" >> "$OUT"
  else cat "$f" >> "$OUT"; fi
  printf '\n\n\\newpage\n\n' >> "$OUT"
}

if [ "$LANG_SEL" = "en" ]; then
  D="$DOCS/en"; FRONT="$HERE/preface-en.md"
  OUT="$HERE/textbook-combined$([ -n "$STUDENT" ] && echo -student).md"
  : > "$OUT"; cat "$FRONT" >> "$OUT"; printf '\n\n\\newpage\n\n' >> "$OUT"
  part "Part I · Main Text — Study Report";        chap "$D/project-report.md"
  part "Part II · Design Source Material"
    chap "$D/concept.md"; chap "$D/spike-findings.md"
    chap "$D/v1-slices.md"; chap "$D/v2-slices.md"; chap "$D/v3-slices.md"; chap "$D/v4-slices.md"
    chap "$D/user-guide.md"
  if [ -z "$STUDENT" ]; then
    part "Part III · Course Operation (instructor)"
      chap "$D/course-syllabus.md"; chap "$D/grading-rubric.md"; chap "$D/instructor-answer-key.md"
  else
    part "Part III · Course Operation";  chap "$D/course-syllabus.md"
  fi
  part "Part IV · Student Materials"
    chap "$D/student-workbook.md"
    qbank "$D/question-bank.md" "# Appendix · Answers"
    chap "$D/student-portfolio-template.md"
else
  D="$DOCS"; FRONT="$HERE/머리말.md"
  OUT="$HERE/교재-통합본$([ -n "$STUDENT" ] && echo -학생판).md"
  : > "$OUT"; cat "$FRONT" >> "$OUT"; printf '\n\n\\newpage\n\n' >> "$OUT"
  part "제1부 · 본문 — 학습 보고서";       chap "$D/프로젝트-보고서.md"
  part "제2부 · 설계 원자료"
    chap "$D/concept.md"; chap "$D/spike-findings.md"
    chap "$D/v1-slices.md"; chap "$D/v2-slices.md"; chap "$D/v3-slices.md"; chap "$D/v4-slices.md"
    chap "$D/사용설명서.md"
  if [ -z "$STUDENT" ]; then
    part "제3부 · 강의 운영(강사용)"
      chap "$D/8주-강의계획서.md"; chap "$D/채점-루브릭.md"; chap "$D/강사용-모범답안집.md"
  else
    part "제3부 · 강의 운영";  chap "$D/8주-강의계획서.md"
  fi
  part "제4부 · 학생 자료"
    chap "$D/학생-워크북.md"
    qbank "$D/문제은행.md" "# 부록 · 정답·해설"
    chap "$D/학생-포트폴리오-템플릿.md"
fi

echo "합본 생성: $OUT  ($(wc -l < "$OUT") 줄)"
BASE="${OUT%.md}"

if ! command -v pandoc >/dev/null 2>&1; then
  echo "pandoc 없음 → 합본 .md 만 생성. (브라우저/에디터로 바로 읽기 가능)"
  echo "  변환하려면: brew install pandoc"
  exit 0
fi

if command -v xelatex >/dev/null 2>&1; then
  # 최상: LaTeX PDF (CJK 폰트)
  FONT="${BOOK_FONT:-Apple SD Gothic Neo}"
  echo "PDF 생성(pandoc+xelatex, 폰트=$FONT)…"
  if pandoc "$OUT" -o "$BASE.pdf" --toc --pdf-engine=xelatex \
       -V mainfont="$FONT" -V CJKmainfont="$FONT" -V geometry:margin=1in -V linkcolor=blue \
       2>/tmp/pandoc-book.err; then
    echo "PDF: $BASE.pdf"
  else echo "PDF 실패. 로그: /tmp/pandoc-book.err"; fi
else
  # 폴백: LaTeX 없이 — HTML(브라우저서 ⌘P→PDF) + DOCX. 한글 폰트는 시스템이 처리.
  echo "xelatex 없음 → HTML/DOCX로 폴백(브라우저 인쇄로 PDF 가능)."
  if pandoc "$OUT" -o "$BASE.html" --toc --standalone --embed-resources 2>/tmp/pandoc-book.err; then
    echo "HTML: $BASE.html   ← 브라우저로 열고 ⌘P → 'PDF로 저장'"
  else echo "HTML 실패. 로그: /tmp/pandoc-book.err"; fi
  pandoc "$OUT" -o "$BASE.docx" --toc 2>/dev/null && echo "DOCX: $BASE.docx" || true
  echo "진짜 PDF 엔진이 필요하면: brew install --cask mactex-no-gui  (xelatex)"
fi

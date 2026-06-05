# 통합 교재 (`docs/교재/`)

전체 교육 자료를 **한 권의 책**으로 묶는 곳. 합본 `.md`는 빌드 스크립트로 *조립*되며(원본 문서에서 자동 생성), HTML/DOCX/PDF로 변환할 수 있다.

## 결과물

| 파일 | 내용 |
|---|---|
| `교재-통합본.md` | **한국어 마스터판**(머리말 + 4부 전체). 바로 읽거나 변환. |
| `textbook-combined.md` | **English master edition** (preface + all parts). |
| `머리말.md` / `preface-en.md` | 책 앞부분(제목·머리말·읽는 길) — 합본의 첫 장. |
| `build.sh` | 조립기(+ HTML/DOCX/PDF 변환). |

> `*.html`·`*.docx`·`*.pdf`와 학생판 합본은 *빌드 산출물*이라 git에서 제외(.gitignore). 필요할 때 `build.sh`로 만든다.

## 빌드

```bash
docs/교재/build.sh                 # 한국어 마스터판(.md) + 변환
docs/교재/build.sh en              # 영문 마스터판
docs/교재/build.sh ko --student    # 학생판(루브릭·모범답안 제외 + 문제은행 정답 절 삭제)
docs/교재/build.sh en --student    # English student edition
```

**변환 우선순위(자동):**
1. `xelatex` 있으면 → **PDF**(한글 폰트). 설치: `brew install --cask mactex-no-gui`.
2. 없으면 → **HTML**(self-contained) + **DOCX**. HTML을 브라우저로 열고 **⌘P → "PDF로 저장"** 하면 한글 그대로 PDF가 된다(LaTeX 불필요, 가장 쉬움).
3. pandoc도 없으면 → `.md`만(에디터/마크다운 뷰어로 읽기).

설치: `brew install pandoc`. 폰트 변경: `BOOK_FONT='Noto Sans CJK KR' docs/교재/build.sh`.

## 구성 (4부)
1. **본문** — 프로젝트 학습 보고서(척추)
2. **설계 원자료** — concept · spike-findings · v1~v4-slices · 사용설명서
3. **강의 운영(강사)** — 8주 강의계획서 · 채점 루브릭 · 강사용 모범답안집
4. **학생 자료** — 워크북 · 문제은행 · 포트폴리오 템플릿

> **슬라이드(Marp)** 는 선형 책에 안 맞아 별도: `../주차별-슬라이드개요.md`(영문 `../en/slides.md`).

## 주의
- 합본 `.md`는 *생성물*이다. 원본 문서를 고치면 `build.sh`로 다시 만들어야 최신이 된다.
- 마스터판에는 **정답·모범답안**이 들어 있으니, 학생 배부는 `--student`로.

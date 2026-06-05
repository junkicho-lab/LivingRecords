# 생동하는 기록 (Living Record)

![iOS 26+](https://img.shields.io/badge/iOS-26%2B-000000?logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-SwiftUI%20%C2%B7%20SwiftData-FA7343?logo=swift&logoColor=white)
[![Code: MIT](https://img.shields.io/badge/code-MIT-blue)](LICENSE)
[![Docs: CC BY 4.0](https://img.shields.io/badge/docs-CC%20BY%204.0-lightgrey)](LICENSE-docs.md)
[![Docs: KO + EN](https://img.shields.io/badge/docs-KO%20%2B%20EN-success)](docs/en/)
[![Course: 8-week PBL](https://img.shields.io/badge/course-8--week%20PBL-orange)](docs/8주-강의계획서.md)

> 말로 쏟아낸 생각을 로컬에 모아두면, AI가 분석·분류·정리해 일/주/기간 회고로 만들고,
> 결국 **"나는 무엇을 지속할 것인가"** 를 돕는 iOS 앱.
>
> *동시에*, 이 저장소는 **한 앱이 구상→검증→83개 커밋으로 완성되는 과정**을 그대로 담은 **학습 프로젝트**다.
> *English: see [`docs/en/`](docs/en/).*

---

## 이 저장소는 두 가지다

| | 무엇 | 어디 |
|---|---|---|
| 🍎 **앱** | iOS 26+ SwiftUI/SwiftData 앱 + 위젯 | [`LivingRecord/`](LivingRecord/) · [`spike/`](spike/) |
| 📚 **교재** | 그 앱의 *설계 사고*를 가르치는 한·영 교육 패키지 | [`docs/`](docs/) · [`docs/en/`](docs/en/) · [`docs/교재/`](docs/교재/) |

---

## 빠른 시작

### 앱 실행
1. Xcode(iOS 26+ SDK)로 `LivingRecord/LivingRecord.xcodeproj` 열기
2. **실기기** 선택 → ⌘R *(음성·위젯·알림은 시뮬레이터에서 제약 — 실기기 권장)*
3. 스파이크(검증 실험) 돌리기: `swift spike/intention_spike2.swift`

### 교재 읽기 / 강의
- **자습·전체 해설** → [`docs/프로젝트-보고서.md`](docs/프로젝트-보고서.md) (9페이즈·25단위)
- **한 권으로 묶인 책** → [`docs/교재/교재-통합본.md`](docs/교재/) (빌드: `docs/교재/build.sh`)
- **앱 사용법만** → [`docs/사용설명서.md`](docs/사용설명서.md)

---

## 핵심 가치 (앱이 답하려는 질문)

> **"무엇을 지속할 것인가?"** — 흩어진 생각을 모아, 무엇을 *이어가고* 무엇을 *놓을지* 사람이 결정하도록 **증거**(반복·에너지·진화·냉각·연결·실행)를 보여준다. AI는 판결하지 않는다.

**흔들리지 않는 원칙**
- **로컬 우선** — 원문·음성·에너지는 기기를 떠나지 않는다. 클라우드는 *옵트인*이고 나갈 때도 *증류층(요약)* 만.
- **봉인(sealed)** — 가장 사적인 포착은 기기 밖으로 안 나간다(클라우드 제외, 별도 폴더).
- **포착은 마찰 0** — 말하거나 쓰면 끝. 분류·제목을 묻지 않는다.
- **결정은 사람이** — AI는 증거 제시까지.

---

## 무엇이 들어 있나 (기능 요약)

포착(음성/텍스트·에너지·봉인) · 자동 주제 묶기 + 큐레이션 · 일/주/기간 정리 ·
**지속 루프**(반복·에너지·진화·냉각·연결·실행 추적·선례·피드백) · 검색(전문+의미) ·
**되살아남**(포착 순간 메아리·되새김·저녁 알림 push) · 긴 호흡의 줄기 ·
시각화(흐름 탭) · App Intent/위젯/Siri 트리거 · Obsidian 단방향 미러 + **LLM 위키** ·
암호화 백업 · 커스텀 템플릿. (자세히 → [`docs/사용설명서.md`](docs/사용설명서.md))

---

## 학습 패키지 (한국어)

| 문서 | 대상 | 용도 |
|---|---|---|
| [`프로젝트-보고서.md`](docs/프로젝트-보고서.md) | 공통 | 전 과정 해설(25단위) |
| [`8주-강의계획서.md`](docs/8주-강의계획서.md) | 강사 | 주차별 운영·평가 |
| [`주차별-슬라이드개요.md`](docs/주차별-슬라이드개요.md) | 강사 | 발표(Marp) |
| [`강사용-모범답안집.md`](docs/강사용-모범답안집.md) | 강사 | 모범답안·지도 노트 |
| [`채점-루브릭.md`](docs/채점-루브릭.md) | 강사 | 5역량 × 4수준 평가 |
| [`학생-워크북.md`](docs/학생-워크북.md) | 학생 | 빈칸·실습·복습 |
| [`문제은행.md`](docs/문제은행.md) | 강사 | 퀴즈·시험(정답 포함) |
| [`학생-포트폴리오-템플릿.md`](docs/학생-포트폴리오-템플릿.md) | 학생 | 8주 증거 수집 |

**설계 원자료(1차 사료):**
[`concept.md`](docs/concept.md)(결정 토론) · [`spike-findings.md`](docs/spike-findings.md)(기술 검증 ①~⑧) ·
[`v1-slices.md`](docs/v1-slices.md)~[`v4-slices.md`](docs/v4-slices.md)(단계 계획) · [`사용설명서.md`](docs/사용설명서.md)

> **English** — 전 문서 영문판이 [`docs/en/`](docs/en/)에 있다([`docs/en/README.md`](docs/en/README.md) 색인).
> **통합본** — [`docs/교재/`](docs/교재/)에서 `build.sh`로 한 권 PDF/HTML 빌드(학생판 `--student`).

---

## 학습자를 위한 안내 (왜 이 저장소가 교재인가)

겉은 음성 메모 앱이지만, 배우는 것은 코드가 아니라 **판단의 흐름**이다 — 무엇을 자동화하고 무엇을 사람에게 남길지, 무엇을 믿고 무엇을 검증할지, 언제 밀고 언제 되돌릴지.

**공부법:** 각 단위에서 ① *왜*(결정)를 먼저 → ② 관련 코드 한 줄씩 → ③ **커밋 diff**로 *무엇이 추가됐나* → ④ 복습 질문에 스스로 답.

이 저장소의 **가장 값진 교재는 실패다** — 되돌린 양방향 Obsidian(중복 사고), 세 번 확인한 임베딩 한계, 막바지에 막은 봉인 누수. `git log --reverse --oneline`로 S0(스캐폴딩)부터 따라가 보라.

---

## 저장소 구조

```
living-record/
├─ LivingRecord/           # iOS 앱 (Swift 42개 + 위젯) · Xcode 프로젝트
├─ spike/                  # 검증 실험 24개 (swift <파일>.swift 로 실행)
├─ docs/                   # 설계 문서 + 한국어 교육 패키지
│   ├─ en/                 # 전 문서 영문판 (+ README 색인)
│   └─ 교재/               # 단일 통합 교재 빌드(build.sh) + 합본
└─ README.md               # (이 파일) 전체 안내 허브
```

## 기술 스택

SwiftUI · SwiftData · SpeechTranscriber(STT) · Foundation Models(로컬 LLM) ·
NLContextualEmbedding(임베딩+중심화) · vDSP(prosody) · Swift Charts · CryptoKit(백업) ·
App Intents/WidgetKit/UserNotifications · Claude API(옵트인 깊은 종합).

## 라이선스 · 기여

- **코드**(`LivingRecord/`·`spike/`·빌드 스크립트) → **MIT** ([`LICENSE`](LICENSE))
- **문서·교재**(`docs/`) → **CC BY 4.0** ([`LICENSE-docs.md`](LICENSE-docs.md)) — 출처만 밝히면 수정·번역·상업적 이용 가능
- 기여 환영 — 작업 규율(수직 슬라이스·스파이크 우선·프라이버시 절대 규칙·PR 체크리스트)은 [`CONTRIBUTING.md`](CONTRIBUTING.md)

## 상태 · 비고

- 빌드: ⌘R(실기기 권장). 경고 0 클린 빌드.
- 미완(옵션): iCloud 동기화, MLX 폴백 본체(SPM 패키지 추가 필요), 신호 임계값 튜닝(실데이터).
- 이 코드와 문서는 학습 목적의 예시다. *왜 그렇게 정했는지*가 핵심이니, 코드를 읽되 결정의 근거를 먼저 물어라.

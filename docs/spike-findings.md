# 스파이크 결과 — 한국어 온디바이스 품질 검증

> 환경: macOS 26.6, Xcode 26.5, Swift 6.3.2 (맥에서 CLI 직접 실행)
> 목적: concept.md §3-11 로컬 스택의 Apple 온디바이스 1순위가 *한국어로* 쓸 만한지 실측.
> 스파이크 코드: `spike/` (embed_spike*.swift 등)

## ① 임베딩 (주제 통합) — ✅ 통과 (조건부)

- `NLEmbedding.wordEmbedding(for: .korean)` → **nil (한국어 word 임베딩 OS에 없음).**
- `NLContextualEmbedding(language: .korean)` → **로드 성공.** assets 이미 설치됨(다운로드 불필요), 512차원.
- 평균 풀링한 원본 코사인은 0.61~0.78로 **다 몰림(anisotropy)** → 같은/다른 주제 분리도 0.103, 순위 뒤엉킴.
- **중심화(전체 centroid 빼고 재정규화)** 적용 시 분리도 **0.380** → 군집 명확.

**판정:** Apple 온디바이스 한국어 임베딩으로 주제 통합 **가능. 단 중심화(anisotropy 보정) 전처리 필수.**
→ v1에서 다국어 sentence-transformer **번들 불필요**. Apple 네이티브 채택.

**적용 메모(구현 시):**
- 문장 벡터 = 토큰 벡터 평균 풀링 → **centroid 차감 + L2 정규화** 후 코사인.
- centroid는 충분한 배경 코퍼스(누적 포착)로 추정할수록 안정적. 초기엔 작은 표본이라 임계값 보수적으로.
- 주제 병합 임계값은 실데이터로 튜닝 필요.

## ② STT (한국어 받아쓰기) — 🟡 부분 (아키텍처 OK, 품질 미측정)

- `SFSpeechRecognizer(locale: ko-KR)` 생성 OK. CLI에서 **권한 통과**(raw=3).
- ⭐ **`supportsOnDeviceRecognition == true`** — 한국어 **on-device 지원 확인**(로컬 우선 설계 핵심).
- 그러나 `recognitionTask`가 헤드리스 CLI에서 **결과 콜백을 전혀 안 냄**(aiff·wav 모두, 55s 대기, 에러도 없음).
  - 원인 추정: on-device 모델 프로비저닝 미완 + `requiresOnDeviceRecognition=true` 무응답, 또는 앱 런루프/번들 컨텍스트 필요.
- 테스트 자산: `spike/cap.aiff`, `cap.wav` (say -v Yuna 합성, 7.5s).

### ②-new 신형 SpeechTranscriber/SpeechAnalyzer — ✅ 통과 (CLI에서도 작동)
- `SpeechTranscriber`/`SpeechAnalyzer`/`AssetInventory` 심볼 존재. ko-KR **supported=true, installed=true**, 에셋 자동 설치 OK.
- `analyzer.analyzeSequence(from: AVAudioFile)` + `transcriber.results`로 파일 전사 성공(헤드리스 CLI에서도).
- 결과: 단어 **100% 정확**(차이는 쉼표 1개), 문자 정확도 **97.7%** (cap.wav, TTS 합성).
- **판정:** 신형 SpeechTranscriber로 한국어 on-device STT **확정 채택**. 레거시 SFSpeechRecognizer는 버림.
- ⚠️ 단서: TTS 합성 음성 기준. **실제 사람 음성(잡음·발음·속도) WER은 더 높을 것** → 실사용 녹음으로 추가 측정 권장.

## ③ Foundation Models (한국어 태깅·요약) — 🟡 작동하나 가드레일 리스크 (중요)

- `SystemLanguageModel.default.availability == .available`. CLI에서 **작동**.
- 한국어 태깅·요약 **품질 양호**(중립·학생·아이들 문장 대부분 그럴듯한 태그+요약 생성).
- 🛑 **그러나 가드레일 거짓 양성**: 무해한 교사 문장 일부가 `guardrailViolation("May contain unsafe content")`로 차단.
  - 차단: "오늘 수업에서 아이들이 발표할 때 눈빛이 살아있는 걸 보고, 이 방식을 계속 밀고 가야겠다…"
  - 통과: "우리 반 아이들이 글쓰기를 어려워해서…", "학생들과 텃밭을…", 중립 문장.
  - → "아이들" 자체가 아니라 **특정 표현 조합을 맥락 없이 오해**. 예측 불가·변덕스러움.
- **판정 / 설계 영향(중요):** 교사용 사적 회고 앱에서 **무해한 포착의 간헐적 침묵 거부 = 신뢰 붕괴 리스크.**
  - Foundation Models는 **단독 의존 금지.** §3-11 **MLX 오픈모델 대안이 (품질 아닌) 가드레일 회피용으로 필요**.
  - 또는: 차단 시 **우아한 폴백**(대체 모델 재시도 / 사용자 수동 태깅 / 자리표시). Apple 가드레일은 사용자가 끌 수 없음.
  - 클라우드 깊은 종합도 가드레일 있으나, 2단계 증류(추상화 전송)가 오탐을 줄일 여지.

## ④ MLX 오픈모델 폴백 PoC — ✅ 통과

- 머신에 ollama/llama.cpp/mlx_lm **없었음** → `pip install mlx-lm`(0.31.3)로 설치, Qwen2.5-1.5B-Instruct-4bit 사용.
- **FM이 차단했던 바로 그 문장**("…아이들이 발표할 때 눈빛이 살아있는…")을 정상 처리:
  태그=학문·발표, 요약=합리적. 가드레일 없음.
- 성능: 온디바이스 ~100 tok/s, **peak 1.0GB**. 1.5B는 한국어 태깅 "쓸 만함"(학문 태그는 부정확).
- **판정:** FM 가드레일 차단 시 **MLX 오픈모델 폴백 실현 가능**(완전 온디바이스). 품질 더 원하면 3B급 검토.
- 실제 앱은 mlx-swift(Swift)로 번들. (PoC는 python mlx-lm으로 빠르게 확인)

## ⑤ 임베딩 통합(군집화) PoC — ✅ 통과

- 중심화한 한국어 임베딩 + 온라인 그리디 군집화(임계값 기반).
- **임계값 −0.10 ~ 0.0 구간 → 정확히 3개 순수 클러스터**(수업/음식/운동). 너무 낮으면 섞임(잘못된 병합), 높으면 과분할.
- **판정:** 통합 알고리즘 유효. 기본 임계값 ~0.0, **보수적(순수) 군집화**로 잘못된 병합 회피 → 과분할은 '합치기' 큐레이션으로 해결.
- 핵심: 통합은 **임베딩만으로** 가능(LLM 불필요). LLM은 주제 *이름짓기*에만.
- spike: `cluster_spike.swift`.

## ⑥ 주제 배정: 임베딩 임계값 ❌ → FM 의미 배정 ✅ (중요 전환)

- **임베딩 임계값은 근본적으로 실패**: 합쳐야 할 쌍(수업1·2=0.209) < 합치면 안 될 쌍(등산·음식=0.353).
  유사도 순서가 어긋나 **어떤 단일 임계값으로도 둘 다 만족 불가**. 평균 풀링 NLContextualEmbedding이 다양한 한국어 주제 구분엔 너무 거침.
- **FM 구조화 출력(guided generation)로 배정 → 6/6 정확**: 깨끗한 주제명 목록 + `@Generable`로 번호(또는 -1) 강제.
  등산→새주제, 파스타→음식, 학부모상담·체육대회→수업 모두 정확.
- spike: `online_spike`(임계값 실패 재현), `fm_guided_spike`(6/6, macOS).

### ⑥-b 기기 검증: 온디바이스 FM 분류는 불안정 → best-effort + 큐레이션으로 확정
- **index 선택**(없으면 -1): 기기 FM이 주제 1개일 때 **전부 idx=0으로 쏠림**(유효 번호 선호 편향) → 과병합(전부 한 주제).
- **Bool "같은 분야?"**로 교체: 기기에서 이번엔 **과분할**("수업 끝나고 다시 생각"이 "수업"에 안 붙고 새 주제). macOS 스파이크(5/6)와 기기 동작이 **다름**.
- **결론(중요):** 온디바이스 FM의 짧은 한국어 자동 군집은 과병합↔과분할을 오가고 **환경마다 달라 프롬프트로 100% 불가**. 기기 접근 없이 튜닝 불가.
- **최종 설계(방안 A):** 자동 분류는 **보수적 best-effort**(Bool 판단, 과분할이 과병합보다 안전 — 합치기로 정리 가능) + **강한 큐레이션**(이름변경·합치기·포착 이동/추출). 자동은 출발점, 정리는 사용자가 2탭으로.
- 향후 개선 여지: 임베딩 top-K 후보 축소, 배치 "정리 제안"(FM이 합치기 제안→사용자 승인), 실기기 프롬프트 튜닝.

## 종합 결론
- 임베딩 ✅(중심화 필수) · STT ✅(신형 SpeechTranscriber, 깨끗한 음성 97.7%) · FM 🟡(작동하나 가드레일 폴백 필요) · MLX 폴백 ✅(가드레일 없음).
- **로컬 스택 검증 완료**: STT=SpeechTranscriber 확정, 임베딩=NLContextualEmbedding+중심화, 로컬 LLM="Apple FM + MLX 폴백" 이중화.
- 남은 검증: 실제 사람 음성 WER(실사용 녹음), 폴백 모델 크기(1.5B vs 3B) 튜닝.

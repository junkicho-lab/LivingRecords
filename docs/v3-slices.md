# 생동하는 기록 — v3 수직 슬라이스 계획 (포착 도달성)

> 작성: 2026-06-04 · 근거: `concept.md` §3-4(포착=한 동작·트리거), `사용설명서.md`
> 플랫폼: iOS 26+ · 워크플로: 구현 → 실기기 검증 → 커밋(`feat(S12): …`)

## 0. 목표 — 앱 밖에서 한 동작으로 포착

v1+v2는 **앱을 열어야만** 포착된다. v3는 concept §3-4의 "트리거=한 동작, 결정 0개"를 실제로 만든다.
- **굳은 결정(concept §3-4):** 위젯/트리거 한 탭 → 포착. 봉인=트리거에 흡수(탭=일반 / 꾹=봉인). 항상 듣기는 탈락(의도적 행위).
- **이번 결정:** 트리거 시 **앱이 포착 화면으로 열리며 자동 녹음 시작**(열자마자). 마이크는 앱 활성 필요 → 포그라운드 진입은 불가피하나 사용자 동작은 한 번.

## 1. 슬라이스

### S12 · App Intent 포착 ⭐ (가장 큰 도달, 새 타깃 0)
- **목표**: "포착 시작"을 시스템 액션으로 노출 → **액션 버튼 · Siri · AirPods("Siri야, 포착")** 가 한 번에. 앱이 포착 탭으로 열리며 자동 녹음.
- **포함**:
  - `AppLaunchState`(@Observable 싱글턴): `startCapture`/`startSealed` 신호. 앱 환경에 주입.
  - `StartCaptureIntent` / `StartSealedCaptureIntent`(`openAppWhenRun=true`) → 신호 set.
  - `AppShortcutsProvider`: "포착"·"봉인 포착" 프레이즈(Siri/단축어/액션버튼 노출).
  - ContentView: 신호 시 포착 탭(0)으로. CaptureView: 신호 소비 후 자동 `toggleRecord()` 시작(중복 가드).
- **검증**: 단축어 앱에 "포착" 노출, 실행 시 앱이 녹음 시작. 액션 버튼에 할당→누르면 녹음. (실기기)
- **의존**: v1 포착. **새 Xcode 타깃 불필요**.

### S13 · 저녁 회고 리마인더
- **목표**: "오늘을 한 줄로?" 부드러운 로컬 알림. 탭하면 포착(또는 일일 정리)로.
- **포함**: 알림 권한 요청, 설정에 토글+시각, `UNUserNotificationCenter` 일일 스케줄, 탭 시 딥링크(AppLaunchState 재사용).
- **검증**: 설정 시각에 알림, 탭→포착 화면. (실기기)
- **의존**: S12(딥링크 신호 공유).

### S14 · 홈/잠금화면 위젯
- **목표**: 위젯 한 탭 → 포착 화면(자동 녹음). 봉인 변형.
- **포함**: **Widget Extension 새 타깃**(사용자가 Xcode에서 추가) + **App Group**(SwiftData 공유는 v1엔 불필요하나 향후 위젯에 최근 상태 표시 시 필요) + 위젯 버튼이 App Intent/딥링크 실행.
- **검증**: 홈 화면 위젯 탭→녹음. (실기기)
- **의존**: S12. ⚠️ **새 타깃 추가는 사용자 작업**(앱 생성 때처럼).

## 2. v3 경계
- **v3**: 트리거(App Intent/액션버튼/Siri/AirPods) · 리마인더 · 위젯.
- **post-v3**: 검색·의미 탐색, iCloud 동기화·암호화 백업·MLX 폴백 번들·양방향 Obsidian, 커스텀 템플릿, 시각화, Android.

## 3. 시작점
- **S12(App Intent)** 부터. 새 타깃 없이 액션버튼·Siri·AirPods가 한 번에 열린다.

## 진행 상황
- **S12 ✅완료(2026-06-04)**: App Intent 포착. AppLaunchState 싱글턴 + Start(Sealed)CaptureIntent(openAppWhenRun) + LivingRecordShortcuts. ContentView 탭전환 + CaptureView 자동녹음(가드). 빌드·메타데이터 추출·기동 확인. 액션버튼/Siri 실동작은 실기기.
- **S13 ✅완료(2026-06-04)**: 저녁 회고 리마인더. ReminderStore(토글+시각 기본21:00, 권한, UNCalendar 일일반복) + NotificationDelegate(포그라운드 배너+탭→openCapture) + AppLaunchState.openCapture(이동전용). 설정 '리마인더' 섹션. 빌드·기동 OK. 권한·발화·탭은 실기기.
- (예정) S14 위젯(새 타깃).

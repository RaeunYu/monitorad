# monitorad — 제품 브리프

## 문제

macOS Tahoe(26)는 볼륨·밝기 HUD를 우측 상단의 작은 Liquid Glass 팝오버로 바꿨다. 노트북 화면에서는 견딜 만하지만 대형·고해상도 모니터에서는 시선이 닿지 않아 조작 피드백을 놓치기 쉽다. Sequoia까지의 HUD는 화면 중앙 하단에서 16블록 미터로 상태를 크게 보여줬다.

## 목표

1. Tahoe에서도 Sequoia식 legacy HUD로 볼륨·밝기 변화를 읽을 수 있게 한다. 가능하면 Tahoe HUD는 대체한다.
2. HUD로 표시되는 시스템 지표(볼륨, 밝기 등)를 메뉴바에 상시 표시한다. 사용자는 표시할 지표와 순서를 팝오버에서 정한다.
3. 새 조작 지표를 나중에 간단한 코딩으로 추가할 수 있도록 지표 추상화 계층을 둔다.

## 사용자

- 1차: 작성자 본인 (macOS Tahoe, 대형 모니터·고해상도 환경).
- 2차: Tahoe HUD가 불편한 공개 사용자. GitHub Releases에서 직접 내려받아 설치한다.

## v1 범위

- **메뉴바 인디케이터**: 항목 1개, 최대 3지표, 1개=큰 링·2~3개=작은 링 나란히, 볼륨·밝기 실시간 표시.
- **팝오버**: 지표 선택(최대 3·최소 1), 드래그 순서, HUD 표시 시간(0.5–2.0초, 기본 1.0), HUD 대체 on/off, 로그인 시 시작(기본 off), 종료. 권한이 없을 때만 Accessibility 안내 행 노출.
- **legacy HUD replacement**(볼륨·밝기): 16블록 미터 + 자체 드로잉 글리프, 동작이 일어난 디스플레이에 표시, 설정된 표시 시간만큼 페이드.
- **키 가로채기 + Accessibility 권한**, companion 폴백.
- **키보드 백라이트**: 지표 추상화 경계에만 포함하고 구현은 v1.1로 미룬다.
- ad-hoc 서명 빌드, GitHub Releases 배포. macOS 26+, arm64.

## 비목표 (v1)

- Mac App Store 배포 (키 가로채기·private API와 양립 불가).
- Developer ID 서명·notarization·Homebrew cask 배포 (GitHub Releases ad-hoc 배포로 확정).
- 블루투스 기기 배터리 지표 (v2, 문서만 기록; 메뉴바 표시 전용, HUD 미노출).
- 외장 모니터 밝기 제어 (v2 이후, DDC).
- 메뉴바 스크롤로 값 조절.
- 4개 이상 지표 표시, 2×2 미니 링.
- 영어 UI (문자열은 localization-ready 구조로만 준비).

## 로드맵

- **v0.1**: 스캐폴드 + 지표 추상화 + 메뉴바 인디케이터 + 팝오버 + 단위 테스트/CI.
- **v0.2**: legacy HUD 오버레이 + replacement(키 가로채기) + Accessibility/companion + HUD 표시 시간 설정.
- **v1.1**: 키보드 백라이트 지표 + HUD.
- **v2**: 배터리 지표(블루투스 기기), 외장 모니터 밝기/테스트, 영어 localization.

## 수용 기준 (v0.1)

- [ ] 메뉴바 전용 앱(LSUIElement)으로 실행되고 Dock 아이콘이 없다.
- [ ] 볼륨·밝기 변화가 1개 또는 2~3개 링으로 메뉴바에 반영된다.
- [ ] 팝오버에서 지표 선택·순서·표시 시간(0.5–2.0)·로그인 시작·종료가 동작하고 재실행 후 유지된다.
- [ ] 최대 3개 제한과 최소 1개 규칙이 지켜진다.
- [ ] Core 단위 테스트가 통과하고 GitHub Actions `macos-26` PR 체크가 그린이다.

## 제약

- private API(`DisplayServices`, `CoreBrightness.KeyboardBrightnessClient`)와 미디어 키 가로채기 사용 → App Store 불가, OS 업데이트 취약.
- Tahoe 메뉴바 항목은 ControlCenter가 관리하며 화면 밖으로 밀리는 사례가 보고됨 → 방어 로직 필요.
- Apple HUD 자산은 재배포 불가 → 글리프는 실측 비율로 자체 드로잉.

## 확정된 결정

- 배포: GitHub Releases의 ad-hoc 서명 빌드. Developer ID/공증 미사용 (ADR-0004).
- 키보드 백라이트: v1 추상화 경계에 포함하고 구현은 v1.1.

## 참고

- 실행가능성 조사: `docs/research/tahoe-hud-feasibility.md`
- 결정 기록: `docs/adr/0001`~`0004`
- 도메인 용어: `CONTEXT.md`

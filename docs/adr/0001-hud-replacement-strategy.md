# HUD는 키 가로채기로 대체하고, 권한이 없으면 companion으로 폴백한다

Status: accepted

Tahoe의 HUD는 ControlCenter의 SystemBanner가 그리고 이를 끄는 공식 API나 설정은 없다. 우리는 미디어 키 이벤트를 가로채 시스템 HUD 대신 legacy HUD를 표시하고 값을 직접 바꾸는 replacement 모드를 기본으로 하고, Accessibility 권한이 없거나 지표별 대체가 불가능하면 시스템 HUD를 유지한 채 우리 HUD를 추가하는 companion 모드로 폴백한다. 팝오버의 **HUD 대체 토글**을 끄면(off) replacement를 쓰지 않고 companion 모드로 동작한다. App Store 샌드박스에서는 키 가로채기와 private API가 불가능하므로 배포는 GitHub 직접 다운로드로 한정한다.

## Considered Options

- companion 전용(Hudlum 모델): App Store 배포는 가능하지만 "Tahoe HUD 숨김" 요구를 충족하지 못한다.
- SystemBanner XPC 직접 호출: Apple 전용 entitlement로 차단되어 불가능하다.
- 공식 설정/defaults 조작: 존재하지 않는다.

## Consequences

- macOS 업데이트마다 키코드·private API가 깨질 수 있으므로 지표 어댑터 단위로 격리한다.
- 권한이 없으면 시스템 HUD와 우리 HUD가 동시에 보일 수 있고, 팝오버에 권한 안내를 노출한다.
- HUD 대체 토글이 off면 시스템 HUD는 그대로 두고 우리 HUD만 추가로 표시한다.

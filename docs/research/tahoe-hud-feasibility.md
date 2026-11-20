# Tahoe HUD 대체 실행가능성 조사

조사일: 2026-11-19. macOS 26.3(25D125), arm64, Xcode 26.x에서 로컬 검증한 사실과 인용을 정리한다. 결정은 ADR-0001~0004에 있다.

## 핵심 사실

- **Tahoe HUD 렌더러**: `OSDUIHelper`가 아니라 **ControlCenter의 SystemBanner**가 그린다. `/System/Library/LaunchAgents/com.apple.controlcenter.plist`에 MachService `com.apple.SystemBanner`·`SystemBannerService`가 있고, ControlCenter 바이너리에 `SystemBannerService+OSD.swift`, `SystemBannerWindow`, `HUDLayer`, `showOSD:displayID:imageID:priority:msecUntilFade:value:max:` 문자열이 있다. `SystemBanner.framework`도 존재한다. 구형 `com.apple.OSDUIHelper` 잡은 `state = not running`, 실행 0회.
- **억제 수단 없음**: `defaults read com.apple.controlcenter`에 HUD/OSD 키가 없다. SystemBanner XPC 직접 호출은 Apple 전용 entitlement로 차단된다(연결 거부).
- **유일한 대체 경로**: CGEventTap으로 미디어 키를 소비하고 값을 직접 처리. Accessibility 권한(`AXIsProcessTrusted`) 필요. `NX_SYSDEFINED = 14`, subtype 8은 SDK에 상수가 없어 하드코딩, keyCode는 `(data1 & 0xFFFF0000) >> 16`. keycodes: 볼륨 0/1, 밝기 2/3, 음소거 7, 명암 11/12, 키보드 조명 21/22/23.
- **API 등급**: 볼륨·음소거 = CoreAudio(public) / 내장 밝기 = `IODisplayParameters.BrightnessMilliNits`(private, `AppleARMBacklight`) / 키보드 백라이트 = `CoreBrightness.KeyboardBrightnessClient` read·write(private) / 외장 모니터 밝기 = DDC·`DisplayServices`(private, high risk) / 명암 = Apple Silicon에서 지원 없음.
- **레거시 글리프**: `OSDUIHelper.app/Contents/Resources/`에 Illustrator PDF 6종(Volume, Brightness, kBright, kBrightOff, Mute, Mute_RTL), 170×170pt 단일 path, `#231F20`. Apple 서명/SLA로 재배포·트레이싱 불가 → 실측 비율로 자체 드로잉.
  - 스피커 37×53.8(바디 18.3×27, r≈4.7), 웨이브는 3개의 `(` 아크(sagitta 18.0/16.5/12.1, chord 72.8/53.9/34.6, stroke 3.34)
  - 밝기: 링 r24/r18 + 8개 캡슐 광선(6×24, 45°, Ø112)
  - 키보드: 키캡 형상 + 모든 지표가 공유하는 16블록 미터
- **Sequoia HUD 레이아웃 참고**(volumeHUD, MIT): 200pt 정사각 카드, cornerRadius 16, 16 bars(7.5pt/2pt 간격/20pt inset), 아이콘 80pt SF Symbol 0.7 opacity.
- **메뉴바 제약**: `NSStatusBar.system.thickness == 22` 실측. Tahoe에서 항목이 `(0, -17, 34×22)`로 밀리는 사례가 보고됨 → 추가 후 프레임 검사·재추가 방어. Bartender/Ice가 항목을 재부모화하면 `window.screen == nil`일 때 애니메이션·갱신을 중지.
- **CI·배포**: GitHub Actions에 `macos-26` 러너(Xcode 26.6 기본)가 있고 공개 레포는 무료. unsigned 다운로드는 quarantine되며 macOS 15+에서 우클릭 열기 우회가 제거되어 시스템 설정 ▸ Open Anyway가 필요하다. Homebrew cask는 Developer ID + notarization이 필요하다.

## 인용

- 로컬: `/System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/`, Xcode SDK `IOKit.framework/Headers/hidsystem/ev_keymap.h`·`IOLLEvent.h`, `/System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter`, `/System/Library/LoginPlugins/BezelServices.loginPlugin/Contents/MacOS/BezelServices`.
- 웹: [volumeHUD](https://github.com/dannystewart/volumeHUD), [ClassicHUD.swift](https://github.com/dannystewart/volumeHUD/blob/main/volumeHUD/UI/ClassicHUD.swift), [omlx#1497](https://github.com/jundot/omlx/issues/1497), [macos-26 runner](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md), [Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions), [Homebrew Acceptable Casks](https://docs.brew.sh/Acceptable-Casks), [KeyboardBrightnessClient.h](https://github.com/EthanRDoesMC/KBPulse/blob/master/KBPulse/KeyboardBrightnessClient.h).

## 재현 명령 (로컬)

조사 환경: macOS 26.3(25D125), arm64, Xcode 26.x. 시스템 버전에 따라 경로가 달라질 수 있다.

```bash
# ControlCenter·HUD
launchctl print gui/$(id -u)/com.apple.controlcenter | head -20
launchctl print gui/$(id -u)/com.apple.OSDUIHelper 2>/dev/null | grep -E 'state =|runs ='   # 구형 HUD 잡 상태
plutil -p /System/Library/LaunchAgents/com.apple.controlcenter.plist                      # MachService SystemBanner 확인
strings /System/Library/CoreServices/ControlCenter.app/Contents/MacOS/ControlCenter | grep -E 'SystemBanner|HUDLayer|showOSD'
defaults read com.apple.controlcenter                                                     # HUD/OSD 관련 키 유무

# 레거시 글리프 자산
ls /System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/
sips -s format png /System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/OSD_Brightness.pdf --out /tmp/osd_brightness.png
sips -g pixelWidth -g pixelHeight /tmp/osd_brightness.png
mdls -name kMDItemPageWidth -name kMDItemPageHeight /System/Library/CoreServices/OSDUIHelper.app/Contents/Resources/OSD_Brightness.pdf

# API·키코드
ioreg -r -c AppleARMBacklight -l | grep -i brightness
ioreg -r -c KeyboardBacklight -l | grep -i brightness
strings /System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness | grep -i KeyboardBrightness
SDK=$(xcrun --show-sdk-path)
grep -n 'NX_KEYTYPE_SOUND_UP\|NX_KEYTYPE_BRIGHTNESS_UP\|NX_KEYTYPE_ILLUMINATION' "$SDK/System/Library/Frameworks/IOKit.framework/Headers/hidsystem/ev_keymap.h"
grep -n 'NX_SYSDEFINED\|NX_SUBTYPE_AUX_CONTROL_BUTTONS' "$SDK/System/Library/Frameworks/IOKit.framework/Headers/hidsystem/IOLLEvent.h"

# 메뉴바 높이
swift -e 'import AppKit; print(NSStatusBar.system.thickness)'
```

# 배포는 GitHub Releases의 ad-hoc 서명 빌드로 한다

Status: accepted

이 앱은 키 가로채기와 private API를 쓰므로 App Store 샌드박스와 양립하지 않는다. 배포는 공개 GitHub 저장소의 Releases로 하고, 빌드는 Xcode의 "Sign to Run Locally"(ad-hoc 서명)로 만든다. Apple Silicon에서는 ad-hoc 서명이 없으면 실행되지 않으므로 서명 자체는 필요하지만, Developer ID 인증서와 notarization은 사용하지 않는다. 설치 시 Gatekeeper 경고는 사용자가 시스템 설정에서 직접 허용한다.

## Consequences

- macOS 15+에서는 우클릭 열기 우회가 없어 시스템 설정 ▸ Open Anyway 안내가 README에 필요하다.
- Homebrew cask는 공증을 요구하므로 지원하지 않는다.
- Developer ID 서명·공증으로의 승격은 필요해지면 별도 ADR로 결정한다.

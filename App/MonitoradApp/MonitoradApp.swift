import AppKit
import SwiftUI

/// 메뉴바 전용 앱 진입점.
/// 창이 없는 SwiftUI App 라이프사이클을 쓰고, 실제 앱 동작은 `AppDelegate` → `AppController`가 맡는다.
@main
struct MonitoradApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // 설정 창은 팝오버가 대신하므로 빈 Settings scene만 둔다.
        Settings {
            EmptyView()
        }
    }
}

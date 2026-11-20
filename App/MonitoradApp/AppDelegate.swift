import AppKit

/// 앱 라이프사이클을 받아 `AppController`를 구동한다.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LSUIElement(Info.plist)와 함께 Dock 아이콘을 없애는 이중 설정.
        NSApp.setActivationPolicy(.accessory)
        let controller = AppController()
        self.controller = controller
        controller.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

import ServiceManagement

/// 로그인 시 시작(SMAppService.mainApp) 래퍼.
/// 개발 빌드처럼 등록이 불가능한 환경에서는 오류를 던지고, 팝오버가 사유를 표시한다.
enum LaunchAtLogin {
    /// 현재 등록 상태. SMAppService가 유일한 기준이다.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 등록/해제. 실패하면 오류를 그대로 던진다.
    static func setEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}

import CoreGraphics

/// 디스플레이 밝기를 읽을 대상 선택. 순수 함수라 디스플레이 API 없이 단위 테스트할 수 있다.
///
/// 밝기 제어(private DisplayServices)는 내장 디스플레이에만 유효하다. 메인 디스플레이가 외장
/// 모니터인 환경(lid-open + 외장 메인)에서도 내장 디스플레이가 활성 상태라면 그쪽에서 읽어야
/// 하므로, `CGMainDisplayID()`가 아니라 활성 디스플레이 중 내장 디스플레이를 고른다.
/// 내장 디스플레이가 없으면(clamshell 등) nil을 반환하고 호출자가 unavailable로 처리한다.
public enum BuiltInDisplaySelection {
    /// 활성 디스플레이 목록에서 내장 디스플레이 ID를 고른다.
    /// 활성 목록 순서를 유지하며 처음 만나는 내장 디스플레이를 반환한다.
    /// - Parameters:
    ///   - activeDisplayIDs: 현재 활성 디스플레이 ID 목록(순서 유지).
    ///   - builtInDisplayIDs: 그중 내장 디스플레이 ID 집합.
    /// - Returns: 선택된 내장 디스플레이 ID. 활성 목록에 내장이 없으면 nil.
    public static func preferredDisplayID(
        activeDisplayIDs: [CGDirectDisplayID],
        builtInDisplayIDs: Set<CGDirectDisplayID>
    ) -> CGDirectDisplayID? {
        activeDisplayIDs.first { builtInDisplayIDs.contains($0) }
    }
}

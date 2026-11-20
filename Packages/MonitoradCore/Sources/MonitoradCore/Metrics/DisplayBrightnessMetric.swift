import CoreGraphics
import Darwin
import Foundation

/// 디스플레이 밝기 지표. private framework `DisplayServices`의 `DisplayServicesGetBrightness`로 읽는다.
///
/// private API이므로 로드에 실패하거나 값을 읽을 수 없으면 `.unavailable(reason:)`으로 두고
/// 앱은 계속 동작한다 (브리프: API가 없거나 실패하면 해당 지표를 비활성으로 두고 앱은 계속 동작).
/// 메인 디스플레이가 외장이어도 내장 디스플레이가 활성이면 그 디스플레이에서 읽는다
/// (``BuiltInDisplaySelection``). 내장이 없으면 사유와 함께 비활성으로 둔다.
/// 밝기 변경 알림은 공개 API가 없어 메인 런루프에서 주기적으로 다시 읽는다.
public final class DisplayBrightnessMetric: AdjustableMetric {
    public let id = MetricID.displayBrightness
    public let displayName = "디스플레이 밝기"
    public let symbolName = "sun.max.fill"
    public let tint = MetricColor.brightnessOrange
    public var onChange: ((Double) -> Void)?

    public private(set) var value: Double = 0
    public private(set) var availability: MetricAvailability = .available

    /// private framework 경로. macOS 버전에 따라 바뀔 수 있다.
    private static let frameworkPath = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"

    /// `DisplayServicesGetBrightness(displayID, float *brightness) -> kern_return_t`
    private typealias BrightnessFunction = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

    /// 폴링 주기(초). 밝기 변경 알림이 없기 때문에 주기적으로 읽는다.
    public static let defaultPollInterval: TimeInterval = 0.5

    private let pollInterval: TimeInterval
    private let frameworkHandle: UnsafeMutableRawPointer?
    private let getBrightness: BrightnessFunction?
    private let loadFailureReason: String?
    private var pollTimer: Timer?
    private var observing = false
    private var lastNotifiedValue: Double?
    private var lastNotifiedAvailability: MetricAvailability?

    public init(pollInterval: TimeInterval = DisplayBrightnessMetric.defaultPollInterval) {
        self.pollInterval = pollInterval

        let handle = dlopen(Self.frameworkPath, RTLD_NOW)
        var failureReason: String?
        var function: BrightnessFunction?
        if handle == nil {
            let message = dlerror().map { String(cString: $0) } ?? "알 수 없는 오류"
            failureReason = "DisplayServices를 불러올 수 없습니다(\(message))"
        } else if let symbol = dlsym(handle, "DisplayServicesGetBrightness") {
            function = unsafeBitCast(symbol, to: BrightnessFunction.self)
        } else {
            failureReason = "DisplayServicesGetBrightness 심볼을 찾을 수 없습니다"
        }

        self.frameworkHandle = handle
        self.getBrightness = function
        self.loadFailureReason = failureReason
        self.availability = .available
        self.availability = evaluateAvailability()
    }

    deinit {
        if observing {
            stopObserving()
        }
        if let frameworkHandle {
            dlclose(frameworkHandle)
        }
    }

    public func startObserving() {
        guard !observing else { return }
        observing = true
        refresh()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    public func stopObserving() {
        guard observing else { return }
        observing = false
        pollTimer?.invalidate()
        pollTimer = nil
        lastNotifiedValue = nil
        lastNotifiedAvailability = nil
    }

    // MARK: - 값 읽기

    /// 밝기 읽기 결과. 실패 시 사용 불가 사유를 함께 전달한다.
    private enum BrightnessReading {
        case success(Double)
        case failure(String)
    }

    private func refresh() {
        guard observing else { return }
        switch readBrightnessFromSelectedDisplay() {
        case let .success(brightness):
            value = brightness
            availability = .available
        case let .failure(reason):
            value = 0
            availability = .unavailable(reason: reason)
        }
        notifyIfNeeded()
    }

    private func evaluateAvailability() -> MetricAvailability {
        switch readBrightnessFromSelectedDisplay() {
        case .success:
            return .available
        case let .failure(reason):
            return .unavailable(reason: reason)
        }
    }

    /// 활성 디스플레이 중 내장 디스플레이를 골라 밝기를 읽는다.
    private func readBrightnessFromSelectedDisplay() -> BrightnessReading {
        if let loadFailureReason {
            return .failure(loadFailureReason)
        }
        guard let displayID = Self.selectedBuiltInDisplayID() else {
            return .failure("내장 디스플레이가 없어 밝기를 읽을 수 없습니다")
        }
        guard let brightness = readBrightness(displayID: displayID) else {
            return .failure("디스플레이 밝기 값을 읽을 수 없습니다")
        }
        return .success(brightness)
    }

    private func readBrightness(displayID: CGDirectDisplayID) -> Double? {
        guard let getBrightness else { return nil }
        var raw: Float = 0
        let result = getBrightness(displayID, &raw)
        guard result == 0, raw.isFinite else { return nil }
        return min(max(Double(raw), 0), 1)
    }

    private func notifyIfNeeded() {
        guard lastNotifiedValue != value || lastNotifiedAvailability != availability else { return }
        lastNotifiedValue = value
        lastNotifiedAvailability = availability
        onChange?(value)
    }

    /// 현재 활성 디스플레이 목록에서 밝기를 읽을 내장 디스플레이를 고른다.
    private static func selectedBuiltInDisplayID() -> CGDirectDisplayID? {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else { return nil }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else { return nil }
        let activeDisplayIDs = Array(displays.prefix(Int(displayCount)))
        let builtInDisplayIDs = Set(activeDisplayIDs.filter { CGDisplayIsBuiltin($0) != 0 })
        return BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: activeDisplayIDs,
            builtInDisplayIDs: builtInDisplayIDs
        )
    }
}

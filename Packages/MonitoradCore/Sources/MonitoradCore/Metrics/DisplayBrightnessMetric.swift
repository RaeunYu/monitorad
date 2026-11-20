import CoreGraphics
import Darwin
import Foundation

/// 디스플레이 밝기 지표. private framework `DisplayServices`의 `DisplayServicesGetBrightness`로 읽는다.
///
/// private API이므로 로드에 실패하거나 값을 읽을 수 없으면 `.unavailable(reason:)`으로 두고
/// 앱은 계속 동작한다 (브리프: API가 없거나 실패하면 해당 지표를 비활성으로 두고 앱은 계속 동작).
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

    private func refresh() {
        guard observing else { return }
        if let loadFailureReason {
            value = 0
            availability = .unavailable(reason: loadFailureReason)
        } else if !Self.hasBuiltInDisplay() {
            value = 0
            availability = .unavailable(reason: "내장 디스플레이가 없어 밝기를 읽을 수 없습니다")
        } else if let brightness = readBrightness() {
            value = brightness
            availability = .available
        } else {
            value = 0
            availability = .unavailable(reason: "디스플레이 밝기 값을 읽을 수 없습니다")
        }
        notifyIfNeeded()
    }

    private func evaluateAvailability() -> MetricAvailability {
        if let loadFailureReason {
            return .unavailable(reason: loadFailureReason)
        }
        guard Self.hasBuiltInDisplay() else {
            return .unavailable(reason: "내장 디스플레이가 없어 밝기를 읽을 수 없습니다")
        }
        guard readBrightness() != nil else {
            return .unavailable(reason: "디스플레이 밝기 값을 읽을 수 없습니다")
        }
        return .available
    }

    private func readBrightness() -> Double? {
        guard let getBrightness else { return nil }
        var raw: Float = 0
        let result = getBrightness(CGMainDisplayID(), &raw)
        guard result == 0, raw.isFinite else { return nil }
        return min(max(Double(raw), 0), 1)
    }

    private func notifyIfNeeded() {
        guard lastNotifiedValue != value || lastNotifiedAvailability != availability else { return }
        lastNotifiedValue = value
        lastNotifiedAvailability = availability
        onChange?(value)
    }

    /// `CGDisplayIsBuiltin`으로 내장 디스플레이가 있는지 확인한다.
    private static func hasBuiltInDisplay() -> Bool {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else { return false }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else { return false }
        return displays.prefix(Int(displayCount)).contains { CGDisplayIsBuiltin($0) != 0 }
    }
}

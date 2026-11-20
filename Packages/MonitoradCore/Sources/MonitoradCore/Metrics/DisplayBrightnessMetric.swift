import CoreGraphics
import Foundation

/// 디스플레이 밝기 지표. private framework `DisplayServices`의 `DisplayServicesGetBrightness`로 읽는다.
///
/// 데이터 소스(프로덕션 기본값: ``DisplayServicesBrightnessDataSource``)를 주입해
/// 로드·심볼·read 실패 경로를 단위 테스트할 수 있다.
/// private API이므로 실패하면 `.unavailable(reason:)`으로 두고 앱은 계속 동작한다.
/// 메인 디스플레이가 외장이어도 내장 디스플레이가 활성이면 그 디스플레이에서 읽는다
/// (``BuiltInDisplaySelection``). 내장이 없으면 사유와 함께 비활성으로 둔다.
/// 밝기 변경 알림은 공개 API가 없어 메인 런루프에서 주기적으로 다시 읽는다.
/// 표시 중일 때는 촘촘하게, 표시되지 않을 때는 느리게 읽는다(``PollingCadence``).
public final class DisplayBrightnessMetric: AdjustableMetric, AdjustableMetricCadence {
    public let id = MetricID.displayBrightness
    public let displayName = "디스플레이 밝기"
    public let symbolName = "sun.max.fill"
    public let tint = MetricColor.brightnessOrange
    public var onChange: ((Double) -> Void)?

    public private(set) var value: Double = 0
    public private(set) var availability: MetricAvailability = .available

    /// 현재 폴링 주기(초). 선택 상태에 따라 ``PollingCadence``가 결정한다.
    public private(set) var currentPollInterval: TimeInterval

    private let dataSource: DisplayBrightnessDataSource
    private let cadence: PollingCadence
    private var pollTimer: Timer?
    private var observing = false
    private var lastNotifiedValue: Double?
    private var lastNotifiedAvailability: MetricAvailability?

    public init(
        dataSource: DisplayBrightnessDataSource = DisplayServicesBrightnessDataSource(),
        cadence: PollingCadence = .brightness
    ) {
        self.dataSource = dataSource
        self.cadence = cadence
        self.currentPollInterval = cadence.interval(isSelected: false)
        refresh()
    }

    deinit {
        if observing {
            stopObserving()
        }
    }

    public func startObserving() {
        guard !observing else { return }
        observing = true
        refresh()
        schedulePollTimer()
    }

    public func stopObserving() {
        guard observing else { return }
        observing = false
        pollTimer?.invalidate()
        pollTimer = nil
        lastNotifiedValue = nil
        lastNotifiedAvailability = nil
    }

    // MARK: - AdjustableMetricCadence

    /// 선택 상태가 바뀌면 폴링 주기를 다시 정한다. 관측 중이면 타이머를 재시작한다.
    public func updatePollingSelection(isSelected: Bool) {
        let newInterval = cadence.interval(isSelected: isSelected)
        guard newInterval != currentPollInterval else { return }
        currentPollInterval = newInterval
        if observing {
            schedulePollTimer()
        }
    }

    // MARK: - 값 읽기

    private func schedulePollTimer() {
        pollTimer?.invalidate()
        let timer = Timer(timeInterval: currentPollInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    /// 밝기 읽기 결과. 실패 시 사용 불가 사유를 함께 전달한다.
    private enum BrightnessReading {
        case success(Double)
        case failure(String)
    }

    private func refresh() {
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

    /// 활성 디스플레이 중 내장 디스플레이를 골라 밝기를 읽는다.
    private func readBrightnessFromSelectedDisplay() -> BrightnessReading {
        let displayInfo = dataSource.displayInfo()
        guard let displayID = BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: displayInfo.activeDisplayIDs,
            builtInDisplayIDs: displayInfo.builtInDisplayIDs
        ) else {
            return .failure("내장 디스플레이가 없어 밝기를 읽을 수 없습니다")
        }
        do {
            let brightness = try dataSource.readBrightness(from: displayID)
            return .success(min(max(brightness, 0), 1))
        } catch let error as DisplayBrightnessDataSourceError {
            switch error {
            case let .frameworkUnavailable(reason):
                return .failure(reason)
            case .symbolUnavailable:
                return .failure("DisplayServicesGetBrightness 심볼을 찾을 수 없습니다")
            case .readFailed:
                return .failure("디스플레이 밝기 값을 읽을 수 없습니다")
            }
        } catch {
            return .failure("디스플레이 밝기 값을 읽을 수 없습니다")
        }
    }

    private func notifyIfNeeded() {
        guard lastNotifiedValue != value || lastNotifiedAvailability != availability else { return }
        lastNotifiedValue = value
        lastNotifiedAvailability = availability
        onChange?(value)
    }
}

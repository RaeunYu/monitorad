import Foundation

/// 시스템 출력 볼륨 지표.
///
/// 오디오 클라이언트(프로덕션 기본값: ``CoreAudioOutputClient``)를 주입해 읽기·관측을 위임한다.
/// 기본 출력 장치의 볼륨 스칼라(0...1)를 읽고, 음소거 상태면 0으로 반영한다.
/// 클라이언트가 변경을 알리면(property listener) 다시 읽는다. 모든 접근은 메인 스레드에서 이뤄진다.
public final class SystemVolumeMetric: AdjustableMetric {
    public let id = MetricID.volume
    public let displayName = LocalizedStrings.localized("metric.volume.name", fallback: "볼륨")
    public let symbolName = "speaker.wave.2.fill"
    public let tint = MetricColor.volumeBlue
    public var onChange: ((Double) -> Void)?

    public private(set) var value: Double = 0
    public private(set) var availability: MetricAvailability = .available

    private let audioClient: AudioOutputClient
    private var observing = false
    private var lastNotifiedValue: Double?
    private var lastNotifiedAvailability: MetricAvailability?

    public init(audioClient: AudioOutputClient = CoreAudioOutputClient()) {
        self.audioClient = audioClient
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
        audioClient.startObserving { [weak self] in
            self?.refresh()
        }
        refresh()
    }

    public func stopObserving() {
        guard observing else { return }
        observing = false
        audioClient.stopObserving()
        lastNotifiedValue = nil
        lastNotifiedAvailability = nil
    }

    // MARK: - 값 반영

    private func refresh() {
        switch audioClient.currentState() {
        case .noOutputDevice:
            update(value: 0, availability: .unavailable(reason: LocalizedStrings.localized("metric.volume.noOutputDevice", fallback: "출력 장치를 찾을 수 없습니다")))
        case .unreadableVolume:
            update(value: 0, availability: .unavailable(reason: LocalizedStrings.localized("metric.volume.unreadableVolume", fallback: "이 출력 장치에서 볼륨 값을 읽을 수 없습니다")))
        case let .value(volume, isMuted):
            update(value: isMuted ? 0 : volume, availability: .available)
        }
    }

    private func update(value newValue: Double, availability newAvailability: MetricAvailability) {
        value = min(max(newValue, 0), 1)
        availability = newAvailability
        notifyIfNeeded()
    }

    private func notifyIfNeeded() {
        guard lastNotifiedValue != value || lastNotifiedAvailability != availability else { return }
        lastNotifiedValue = value
        lastNotifiedAvailability = availability
        onChange?(value)
    }
}

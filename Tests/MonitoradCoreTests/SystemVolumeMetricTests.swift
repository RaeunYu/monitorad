import MonitoradCore
import XCTest

/// 테스트용 오디오 클라이언트. 상태와 관측 호출을 주입·기록한다.
final class MockAudioOutputClient: AudioOutputClient {
    var state: AudioOutputState
    private(set) var startObservingsCount = 0
    private(set) var stopObservingCount = 0
    private var changeHandler: (() -> Void)?

    init(state: AudioOutputState) {
        self.state = state
    }

    func currentState() -> AudioOutputState {
        state
    }

    func startObserving(_ handler: @escaping () -> Void) {
        startObservingsCount += 1
        changeHandler = handler
    }

    func stopObserving() {
        stopObservingCount += 1
        changeHandler = nil
    }

    /// 클라이언트가 외부 변경을 관측했다고 가정하고 상태를 바꿔 알린다.
    func emitChange(to newState: AudioOutputState) {
        state = newState
        changeHandler?()
    }
}

/// 볼륨 어댑터의 값·음소거·미지원 경로와 관측 위임.
final class SystemVolumeMetricTests: XCTestCase {
    func testReadsVolumeAndAvailability() {
        let client = MockAudioOutputClient(state: .value(volume: 0.4, isMuted: false))
        let metric = SystemVolumeMetric(audioClient: client)

        XCTAssertEqual(metric.value, 0.4, accuracy: 0.0001)
        XCTAssertEqual(metric.availability, .available)
    }

    func testMutedVolumeIsReportedAsZero() {
        let client = MockAudioOutputClient(state: .value(volume: 0.4, isMuted: true))
        let metric = SystemVolumeMetric(audioClient: client)

        XCTAssertEqual(metric.value, 0, accuracy: 0.0001)
        XCTAssertEqual(metric.availability, .available)
    }

    func testUnavailableWhenNoOutputDevice() {
        let client = MockAudioOutputClient(state: .noOutputDevice)
        let metric = SystemVolumeMetric(audioClient: client)

        XCTAssertEqual(metric.availability.unavailableReason, "출력 장치를 찾을 수 없습니다")
        XCTAssertEqual(metric.value, 0)
    }

    func testUnavailableWhenVolumeCannotBeRead() {
        let client = MockAudioOutputClient(state: .unreadableVolume)
        let metric = SystemVolumeMetric(audioClient: client)

        XCTAssertEqual(metric.availability.unavailableReason, "이 출력 장치에서 볼륨 값을 읽을 수 없습니다")
    }

    func testStartAndStopObservingAreIdempotent() {
        let client = MockAudioOutputClient(state: .value(volume: 0.2, isMuted: false))
        let metric = SystemVolumeMetric(audioClient: client)

        metric.startObserving()
        metric.startObserving()
        XCTAssertEqual(client.startObservingsCount, 1)

        metric.stopObserving()
        metric.stopObserving()
        XCTAssertEqual(client.stopObservingCount, 1)
    }

    func testClientChangeNotifiesMetric() {
        let client = MockAudioOutputClient(state: .value(volume: 0.2, isMuted: false))
        let metric = SystemVolumeMetric(audioClient: client)
        var received: [Double] = []
        metric.onChange = { received.append($0) }

        metric.startObserving()
        client.emitChange(to: .value(volume: 0.7, isMuted: false))

        XCTAssertEqual(metric.value, 0.7, accuracy: 0.0001)
        XCTAssertEqual(received.last ?? 0, 0.7, accuracy: 0.0001)
    }
}

import CoreGraphics
import MonitoradCore
import XCTest

/// 테스트용 밝기 데이터 소스. 디스플레이 정보와 read 결과를 주입한다.
final class MockDisplayBrightnessDataSource: DisplayBrightnessDataSource {
    var displayInfoResult: DisplayInfo
    var readResult: Result<Double, DisplayBrightnessDataSourceError>
    private(set) var requestedDisplayIDs: [CGDirectDisplayID] = []

    init(
        displayInfoResult: DisplayInfo,
        readResult: Result<Double, DisplayBrightnessDataSourceError> = .success(0.5)
    ) {
        self.displayInfoResult = displayInfoResult
        self.readResult = readResult
    }

    func displayInfo() -> DisplayInfo {
        displayInfoResult
    }

    func readBrightness(from displayID: CGDirectDisplayID) throws -> Double {
        requestedDisplayIDs.append(displayID)
        return try readResult.get()
    }
}

/// 밝기 어댑터의 실패 경로·대상 디스플레이 선택·폴링 주기.
final class DisplayBrightnessMetricTests: XCTestCase {
    private let builtInDisplayID: CGDirectDisplayID = 42
    private let externalDisplayID: CGDirectDisplayID = 7

    private func builtInDisplayInfo() -> DisplayInfo {
        DisplayInfo(
            activeDisplayIDs: [externalDisplayID, builtInDisplayID],
            builtInDisplayIDs: [builtInDisplayID]
        )
    }

    func testReadsBrightnessFromBuiltInDisplayWhenExternalIsMain() {
        let source = MockDisplayBrightnessDataSource(
            displayInfoResult: builtInDisplayInfo(),
            readResult: .success(0.42)
        )

        let metric = DisplayBrightnessMetric(dataSource: source)

        XCTAssertEqual(metric.availability, .available)
        XCTAssertEqual(metric.value, 0.42, accuracy: 0.0001)
        XCTAssertEqual(source.requestedDisplayIDs.last, builtInDisplayID)
    }

    func testUnavailableWhenNoBuiltInDisplay() {
        let source = MockDisplayBrightnessDataSource(
            displayInfoResult: DisplayInfo(
                activeDisplayIDs: [externalDisplayID],
                builtInDisplayIDs: []
            ),
            readResult: .success(0.5)
        )

        let metric = DisplayBrightnessMetric(dataSource: source)

        XCTAssertEqual(metric.availability.unavailableReason, "내장 디스플레이가 없어 밝기를 읽을 수 없습니다")
        XCTAssertEqual(metric.value, 0)
        XCTAssertTrue(source.requestedDisplayIDs.isEmpty)
    }

    func testUnavailableWhenFrameworkLoadFails() {
        let source = MockDisplayBrightnessDataSource(
            displayInfoResult: builtInDisplayInfo(),
            readResult: .failure(.frameworkUnavailable(reason: "DisplayServices를 불러올 수 없습니다(테스트)"))
        )

        let metric = DisplayBrightnessMetric(dataSource: source)

        XCTAssertEqual(metric.availability.unavailableReason, "DisplayServices를 불러올 수 없습니다(테스트)")
        XCTAssertEqual(metric.value, 0)
    }

    func testUnavailableWhenSymbolIsMissing() {
        let source = MockDisplayBrightnessDataSource(
            displayInfoResult: builtInDisplayInfo(),
            readResult: .failure(.symbolUnavailable)
        )

        let metric = DisplayBrightnessMetric(dataSource: source)

        XCTAssertEqual(metric.availability.unavailableReason, "DisplayServicesGetBrightness 심볼을 찾을 수 없습니다")
    }

    func testUnavailableWhenReadFails() {
        let source = MockDisplayBrightnessDataSource(
            displayInfoResult: builtInDisplayInfo(),
            readResult: .failure(.readFailed)
        )

        let metric = DisplayBrightnessMetric(dataSource: source)

        XCTAssertEqual(metric.availability.unavailableReason, "디스플레이 밝기 값을 읽을 수 없습니다")
    }

    func testPollingIntervalFollowsSelection() {
        let metric = DisplayBrightnessMetric(
            dataSource: MockDisplayBrightnessDataSource(displayInfoResult: builtInDisplayInfo()),
            cadence: PollingCadence(selectedInterval: 0.1, idleInterval: 0.4)
        )

        XCTAssertEqual(metric.currentPollInterval, 0.4, accuracy: 0.0001)
        metric.updatePollingSelection(isSelected: true)
        XCTAssertEqual(metric.currentPollInterval, 0.1, accuracy: 0.0001)
        metric.updatePollingSelection(isSelected: false)
        XCTAssertEqual(metric.currentPollInterval, 0.4, accuracy: 0.0001)
    }

    func testStartAndStopObservingAreIdempotent() {
        let source = MockDisplayBrightnessDataSource(
            displayInfoResult: builtInDisplayInfo(),
            readResult: .success(0.3)
        )
        let metric = DisplayBrightnessMetric(dataSource: source)
        let readsAfterInit = source.requestedDisplayIDs.count

        metric.startObserving()
        XCTAssertEqual(source.requestedDisplayIDs.count, readsAfterInit + 1)
        metric.startObserving()
        XCTAssertEqual(source.requestedDisplayIDs.count, readsAfterInit + 1)

        metric.stopObserving()
        metric.stopObserving()
        XCTAssertEqual(source.requestedDisplayIDs.count, readsAfterInit + 1)
    }
}

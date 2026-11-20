import CoreAudio
import MonitoradCore
import XCTest

/// 마스터 엘리먼트가 없을 때 채널 1·2로 폴백하는 볼륨/음소거 해석 규칙.
final class AudioVolumeResolutionTests: XCTestCase {
    func testMasterValueWins() {
        let resolved = AudioVolumeResolution.resolvedValue(
            byElement: [kAudioObjectPropertyElementMain: 0.55, 1: 0.11, 2: 0.22]
        )
        XCTAssertEqual(resolved ?? 0, 0.55, accuracy: 0.0001)
    }

    func testFallsBackToChannelOneWhenMasterIsMissing() {
        let resolved = AudioVolumeResolution.resolvedValue(byElement: [1: 0.33, 2: 0.66])
        XCTAssertEqual(resolved ?? 0, 0.33, accuracy: 0.0001)
    }

    func testFallsBackToChannelTwoWhenMasterAndChannelOneAreMissing() {
        let resolved = AudioVolumeResolution.resolvedValue(byElement: [2: 0.66])
        XCTAssertEqual(resolved ?? 0, 0.66, accuracy: 0.0001)
    }

    func testReturnsNilWhenNoElementValueIsAvailable() {
        XCTAssertNil(AudioVolumeResolution.resolvedValue(byElement: [:]))
    }

    func testMuteUsesSameFallbackOrder() {
        XCTAssertTrue(
            AudioVolumeResolution.resolvedMute(
                byElement: [kAudioObjectPropertyElementMain: true, 1: false]
            )
        )
        XCTAssertTrue(AudioVolumeResolution.resolvedMute(byElement: [2: true]))
        XCTAssertFalse(AudioVolumeResolution.resolvedMute(byElement: [:]))
    }
}

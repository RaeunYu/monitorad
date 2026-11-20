import CoreGraphics
import MonitoradCore
import XCTest

/// 가짜 밝기 read 함수. DisplayServices 함수 포인터 자리에 넣는다.
private func fakeBrightnessFunction(
    _ displayID: CGDirectDisplayID,
    _ brightness: UnsafeMutablePointer<Float>
) -> Int32 {
    brightness.pointee = 0.42
    return 0
}

/// 프로덕션 DisplayServices 데이터 소스의 로더/리더 주입과 실패 경로.
final class DisplayServicesBrightnessDataSourceTests: XCTestCase {
    private func dummyHandle() -> UnsafeMutableRawPointer {
        UnsafeMutableRawPointer(bitPattern: 0x1)!
    }

    func testFrameworkLoadFailureMapsToFrameworkUnavailable() {
        let source = DisplayServicesBrightnessDataSource(
            frameworkPath: "/nonexistent",
            frameworkLoader: { _ in nil },
            symbolResolver: { _, _ in nil },
            frameworkErrorDescription: { "테스트 로드 실패" }
        )

        do {
            _ = try source.readBrightness(from: 1)
            XCTFail("로드 실패가 전파되어야 한다")
        } catch let error as DisplayBrightnessDataSourceError {
            guard case let .frameworkUnavailable(reason) = error else {
                return XCTFail("frameworkUnavailable이어야 한다: \(error)")
            }
            XCTAssertTrue(reason.contains("테스트 로드 실패"), "사유: \(reason)")
        } catch {
            XCTFail("예상하지 못한 오류: \(error)")
        }
    }

    func testMissingSymbolMapsToSymbolUnavailable() {
        let source = DisplayServicesBrightnessDataSource(
            frameworkPath: "/dummy",
            frameworkLoader: { _ in self.dummyHandle() },
            symbolResolver: { _, _ in nil }
        )

        do {
            _ = try source.readBrightness(from: 1)
            XCTFail("심볼 없음이 전파되어야 한다")
        } catch let error as DisplayBrightnessDataSourceError {
            XCTAssertEqual(error, .symbolUnavailable)
        } catch {
            XCTFail("예상하지 못한 오류: \(error)")
        }
    }

    func testLoadedFunctionReadsBrightness() throws {
        let functionPointer = unsafeBitCast(
            fakeBrightnessFunction as DisplayBrightnessFunction,
            to: UnsafeMutableRawPointer.self
        )
        let source = DisplayServicesBrightnessDataSource(
            frameworkPath: "/dummy",
            frameworkLoader: { _ in self.dummyHandle() },
            symbolResolver: { _, _ in functionPointer }
        )

        XCTAssertEqual(try source.readBrightness(from: 42), 0.42, accuracy: 0.0001)
    }

    func testLoadedFunctionTreatsFailureResultAsReadFailed() {
        // 0이 아닌 kern_return_t를 돌려주는 함수를 주입해 read 실패 경로를 확인한다.
        let failingFunction: @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32 = { _, _ in 1000 }
        let functionPointer = unsafeBitCast(failingFunction, to: UnsafeMutableRawPointer.self)
        let source = DisplayServicesBrightnessDataSource(
            frameworkPath: "/dummy",
            frameworkLoader: { _ in self.dummyHandle() },
            symbolResolver: { _, _ in functionPointer }
        )

        do {
            _ = try source.readBrightness(from: 42)
            XCTFail("read 실패가 전파되어야 한다")
        } catch let error as DisplayBrightnessDataSourceError {
            XCTAssertEqual(error, .readFailed)
        } catch {
            XCTFail("예상하지 못한 오류: \(error)")
        }
    }
}

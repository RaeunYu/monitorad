import CoreGraphics
import Darwin
import Foundation

/// `DisplayServicesGetBrightness(displayID, float *brightness) -> kern_return_t` 시그니처.
public typealias DisplayBrightnessFunction = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32

/// 밝기 데이터 소스 오류. 사용자에게 보여 줄 사유 문구는 지표가 매핑한다.
public enum DisplayBrightnessDataSourceError: Error, Equatable {
    /// DisplayServices 프레임워크를 불러오지 못했다.
    case frameworkUnavailable(reason: String)
    /// 프레임워크는 열렸지만 `DisplayServicesGetBrightness` 심볼이 없다.
    case symbolUnavailable
    /// 함수 호출이 실패했거나 유효한 값을 받지 못했다.
    case readFailed
}

/// 활성 디스플레이 정보.
public struct DisplayInfo: Equatable {
    /// 현재 활성 디스플레이 ID 목록(순서 유지).
    public let activeDisplayIDs: [CGDirectDisplayID]
    /// 그중 내장 디스플레이 ID 집합.
    public let builtInDisplayIDs: Set<CGDirectDisplayID>

    public init(activeDisplayIDs: [CGDirectDisplayID], builtInDisplayIDs: Set<CGDirectDisplayID>) {
        self.activeDisplayIDs = activeDisplayIDs
        self.builtInDisplayIDs = builtInDisplayIDs
    }
}

/// 밝기 어댑터가 의존하는 데이터 소스 경계. 테스트는 목업을 주입한다.
public protocol DisplayBrightnessDataSource: AnyObject {
    /// 현재 활성 디스플레이 목록과 그중 내장 디스플레이 ID.
    func displayInfo() -> DisplayInfo
    /// 지정한 디스플레이의 밝기(0...1). 실패하면 사유를 던진다.
    func readBrightness(from displayID: CGDirectDisplayID) throws -> Double
}

/// 프로덕션 구현. private framework DisplayServices를 로드해 밝기를 읽는다.
///
/// 프레임워크 로더와 심볼 리졸버를 주입할 수 있어 로드 실패·심볼 없음 경로를 단위 테스트한다.
/// macOS 버전에 따라 프레임워크 경로가 바뀔 수 있다.
public final class DisplayServicesBrightnessDataSource: DisplayBrightnessDataSource {
    public typealias FrameworkLoader = (String) -> UnsafeMutableRawPointer?
    public typealias SymbolResolver = (UnsafeMutableRawPointer, String) -> UnsafeMutableRawPointer?

    public static let defaultFrameworkPath = "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices"
    public static let brightnessSymbolName = "DisplayServicesGetBrightness"

    private let brightnessFunction: DisplayBrightnessFunction?
    private let loadError: DisplayBrightnessDataSourceError?

    /// 프로덕션 기본값: dlopen/dlsym으로 실제 프레임워크를 로드한다.
    public convenience init() {
        self.init(
            frameworkLoader: { path in dlopen(path, RTLD_NOW) },
            symbolResolver: { handle, name in dlsym(handle, name) },
            frameworkErrorDescription: {
                dlerror().map { String(cString: $0) }
                    ?? LocalizedStrings.localized("metric.brightness.unknownError", fallback: "알 수 없는 오류")
            }
        )
    }

    /// 테스트에서 로더·리졸버를 주입하기 위한 이니셜라이저.
    /// 기본 에러 문구는 공개 기본 인자 제약상 한국어 리터럴을 쓰고, 프로덕션 경로는 로컬라이즈된 문구를 넘긴다.
    public init(
        frameworkPath: String = DisplayServicesBrightnessDataSource.defaultFrameworkPath,
        frameworkLoader: @escaping FrameworkLoader,
        symbolResolver: @escaping SymbolResolver,
        frameworkErrorDescription: @escaping () -> String = { "알 수 없는 오류" }
    ) {
        guard let handle = frameworkLoader(frameworkPath) else {
            brightnessFunction = nil
            let format = LocalizedStrings.localized("metric.brightness.frameworkUnavailable", fallback: "DisplayServices를 불러올 수 없습니다(%@)")
            loadError = .frameworkUnavailable(reason: String(format: format, frameworkErrorDescription()))
            return
        }
        guard let symbol = symbolResolver(handle, Self.brightnessSymbolName) else {
            brightnessFunction = nil
            loadError = .symbolUnavailable
            return
        }
        brightnessFunction = unsafeBitCast(symbol, to: DisplayBrightnessFunction.self)
        loadError = nil
    }

    public func displayInfo() -> DisplayInfo {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success, displayCount > 0 else {
            return DisplayInfo(activeDisplayIDs: [], builtInDisplayIDs: [])
        }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        guard CGGetActiveDisplayList(displayCount, &displays, &displayCount) == .success else {
            return DisplayInfo(activeDisplayIDs: [], builtInDisplayIDs: [])
        }
        let activeDisplayIDs = Array(displays.prefix(Int(displayCount)))
        return DisplayInfo(
            activeDisplayIDs: activeDisplayIDs,
            builtInDisplayIDs: Set(activeDisplayIDs.filter { CGDisplayIsBuiltin($0) != 0 })
        )
    }

    public func readBrightness(from displayID: CGDirectDisplayID) throws -> Double {
        if let loadError {
            throw loadError
        }
        guard let brightnessFunction else {
            throw DisplayBrightnessDataSourceError.readFailed
        }
        var raw: Float = 0
        let result = brightnessFunction(displayID, &raw)
        guard result == 0, raw.isFinite else {
            throw DisplayBrightnessDataSourceError.readFailed
        }
        return min(max(Double(raw), 0), 1)
    }
}

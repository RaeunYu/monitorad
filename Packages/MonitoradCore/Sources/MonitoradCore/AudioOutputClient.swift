import CoreAudio
import Foundation

/// 출력 장치 상태 스냅샷.
public enum AudioOutputState: Equatable {
    /// 기본 출력 장치가 없다.
    case noOutputDevice
    /// 장치는 있지만 볼륨 값을 읽을 수 없다(볼륨 속성이 없는 장치 등).
    case unreadableVolume
    /// 볼륨 읽기 성공. `isMuted`면 지표 값은 0으로 표시한다.
    case value(volume: Double, isMuted: Bool)
}

/// 볼륨 어댑터가 의존하는 오디오 클라이언트 경계. 테스트는 목업을 주입한다.
public protocol AudioOutputClient: AnyObject {
    /// 현재 출력 장치 상태.
    func currentState() -> AudioOutputState
    /// 변경 관측 시작. 변경 시 handler를 메인 스레드에서 호출한다. 중복 호출에 안전하다.
    func startObserving(_ handler: @escaping () -> Void)
    /// 변경 관측 중지. 중복 호출에 안전하다.
    func stopObserving()
}

/// 엘리먼트별 읽기 결과에서 표시 값을 고르는 순수 규칙.
///
/// 장치에 따라 볼륨/음소거 속성이 마스터 엘리먼트에만 있거나, 채널 1·2에만 있을 수 있다.
/// 마스터를 우선하고 없으면 채널 1, 2 순으로 폴백한다.
public enum AudioVolumeResolution {
    /// 마스터가 없을 때 순서대로 시도하는 채널 엘리먼트.
    public static let channelElements: [AudioObjectPropertyElement] = [1, 2]

    /// 엘리먼트별 볼륨 값에서 표시할 볼륨을 고른다. 값이 하나도 없으면 nil.
    public static func resolvedValue(
        byElement: [AudioObjectPropertyElement: Double],
        masterElement: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> Double? {
        if let master = byElement[masterElement] {
            return master
        }
        for element in channelElements {
            if let value = byElement[element] {
                return value
            }
        }
        return nil
    }

    /// 엘리먼트별 음소거 값에서 표시할 음소거 여부를 고른다. 값이 하나도 없으면 false.
    public static func resolvedMute(
        byElement: [AudioObjectPropertyElement: Bool],
        masterElement: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
    ) -> Bool {
        if let master = byElement[masterElement] {
            return master
        }
        for element in channelElements {
            if let value = byElement[element] {
                return value
            }
        }
        return false
    }
}

/// 프로덕션 CoreAudio 클라이언트. 기본 출력 장치의 볼륨/음소거를 읽고 property listener로 관측한다.
/// CoreAudio public API만 사용하며, listener block을 main queue로 등록해 메인 스레드에서만 접근한다.
public final class CoreAudioOutputClient: AudioOutputClient {
    /// 등록한 property listener. 해제할 때 같은 주소·블록을 넘겨야 하므로 보관한다.
    private final class Listener {
        let objectID: AudioObjectID
        let address: AudioObjectPropertyAddress
        let block: AudioObjectPropertyListenerBlock

        init(objectID: AudioObjectID, address: AudioObjectPropertyAddress, block: @escaping AudioObjectPropertyListenerBlock) {
            self.objectID = objectID
            self.address = address
            self.block = block
        }
    }

    /// 볼륨/음소거를 읽을 때 시도하는 엘리먼트. 마스터가 없으면 채널 1·2를 시도한다.
    private static let elements: [AudioObjectPropertyElement] = [kAudioObjectPropertyElementMain, 1, 2]

    private var systemListeners: [Listener] = []
    private var deviceListeners: [Listener] = []
    private var deviceID: AudioDeviceID?
    private var observing = false
    private var changeHandler: (() -> Void)?

    public init() {}

    deinit {
        if observing {
            stopObserving()
        }
    }

    // MARK: - AudioOutputClient

    public func currentState() -> AudioOutputState {
        guard let device = defaultOutputDevice() else {
            return .noOutputDevice
        }
        var volumeByElement: [AudioObjectPropertyElement: Double] = [:]
        var muteByElement: [AudioObjectPropertyElement: Bool] = [:]
        for element in Self.elements {
            if let volume = readVolume(device: device, element: element) {
                volumeByElement[element] = volume
            }
            if let mute = readMute(device: device, element: element) {
                muteByElement[element] = mute
            }
        }
        guard let volume = AudioVolumeResolution.resolvedValue(byElement: volumeByElement) else {
            return .unreadableVolume
        }
        return .value(
            volume: min(max(volume, 0), 1),
            isMuted: AudioVolumeResolution.resolvedMute(byElement: muteByElement)
        )
    }

    public func startObserving(_ handler: @escaping () -> Void) {
        guard !observing else { return }
        observing = true
        changeHandler = handler
        addSystemListener()
        refreshDeviceListeners()
    }

    public func stopObserving() {
        guard observing else { return }
        observing = false
        removeAllListeners()
        deviceID = nil
        changeHandler = nil
    }

    // MARK: - 관측

    private func notifyChange() {
        guard observing else { return }
        changeHandler?()
    }

    private func addSystemListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.handleDefaultDeviceChanged()
        }
        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main,
            block
        )
        if status == noErr {
            systemListeners.append(
                Listener(objectID: AudioObjectID(kAudioObjectSystemObject), address: address, block: block)
            )
        }
    }

    private func handleDefaultDeviceChanged() {
        guard observing else { return }
        refreshDeviceListeners()
        notifyChange()
    }

    private func refreshDeviceListeners() {
        removeDeviceListeners()
        guard let device = defaultOutputDevice() else {
            deviceID = nil
            return
        }
        deviceID = device
        addDeviceListeners(device: device)
    }

    private func addDeviceListeners(device: AudioDeviceID) {
        for element in Self.elements {
            addDeviceListener(device: device, selector: kAudioDevicePropertyVolumeScalar, element: element)
            addDeviceListener(device: device, selector: kAudioDevicePropertyMute, element: element)
        }
    }

    private func addDeviceListener(
        device: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        element: AudioObjectPropertyElement
    ) {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(device, &address) else { return }
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.notifyChange()
        }
        let status = AudioObjectAddPropertyListenerBlock(device, &address, DispatchQueue.main, block)
        if status == noErr {
            deviceListeners.append(Listener(objectID: device, address: address, block: block))
        }
    }

    private func removeDeviceListeners() {
        removeAll(deviceListeners)
        deviceListeners.removeAll()
    }

    private func removeAllListeners() {
        removeAll(systemListeners)
        removeAll(deviceListeners)
        systemListeners.removeAll()
        deviceListeners.removeAll()
    }

    private func removeAll(_ listeners: [Listener]) {
        for listener in listeners {
            var address = listener.address
            AudioObjectRemovePropertyListenerBlock(
                listener.objectID,
                &address,
                DispatchQueue.main,
                listener.block
            )
        }
    }

    // MARK: - 값 읽기

    private func defaultOutputDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &device
        )
        guard status == noErr, device != AudioDeviceID(kAudioObjectUnknown) else { return nil }
        return device
    }

    private func readVolume(device: AudioDeviceID, element: AudioObjectPropertyElement) -> Double? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(device, &address) else { return nil }
        var volume = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        guard status == noErr, volume.isFinite else { return nil }
        return Double(volume)
    }

    private func readMute(device: AudioDeviceID, element: AudioObjectPropertyElement) -> Bool? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: element
        )
        guard AudioObjectHasProperty(device, &address) else { return nil }
        var mute = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &mute)
        guard status == noErr else { return nil }
        return mute != 0
    }
}

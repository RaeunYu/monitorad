import CoreAudio
import Foundation

/// 시스템 출력 볼륨 지표. CoreAudio의 public API만 사용한다.
///
/// 기본 출력 장치의 볼륨 스칼라(0...1)를 읽고, 음소거 상태면 0으로 반영한다.
/// property listener로 기본 장치·볼륨·음소거 변경을 관측한다.
/// 모든 접근은 메인 스레드에서 이뤄진다(listener block을 main queue로 등록한다).
public final class SystemVolumeMetric: AdjustableMetric {
    public let id = MetricID.volume
    public let displayName = "볼륨"
    public let symbolName = "speaker.wave.2.fill"
    public let tint = MetricColor.volumeBlue
    public var onChange: ((Double) -> Void)?

    public private(set) var value: Double = 0
    public private(set) var availability: MetricAvailability = .available

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

    private var systemListeners: [Listener] = []
    private var deviceListeners: [Listener] = []
    private var deviceID: AudioDeviceID?
    private var observing = false
    private var lastNotifiedValue: Double?
    private var lastNotifiedAvailability: MetricAvailability?

    /// 볼륨 값을 읽을 때 시도하는 엘리먼트. 마스터가 없으면 채널 1·2를 시도한다.
    private static let volumeElements: [AudioObjectPropertyElement] = [
        kAudioObjectPropertyElementMain,
        1,
        2,
    ]

    public init() {}

    deinit {
        if observing {
            stopObserving()
        }
    }

    public func startObserving() {
        guard !observing else { return }
        observing = true
        addSystemListener()
        refreshDeviceAndValue()
    }

    public func stopObserving() {
        guard observing else { return }
        observing = false
        removeListeners()
        deviceID = nil
        lastNotifiedValue = nil
        lastNotifiedAvailability = nil
    }

    // MARK: - 관측

    private func addSystemListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refreshDeviceAndValue()
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

    private func refreshDeviceAndValue() {
        guard observing else { return }
        removeDeviceListeners()
        guard let device = defaultOutputDevice() else {
            deviceID = nil
            update(value: 0, availability: .unavailable(reason: "출력 장치를 찾을 수 없습니다"))
            return
        }
        deviceID = device
        addDeviceListeners(device: device)
        refreshValue()
    }

    private func addDeviceListeners(device: AudioDeviceID) {
        for element in Self.volumeElements {
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
            self?.refreshValue()
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

    private func removeListeners() {
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

    private func refreshValue() {
        guard observing, let device = deviceID else { return }
        guard let volume = readVolume(device: device) else {
            update(value: 0, availability: .unavailable(reason: "이 출력 장치에서 볼륨 값을 읽을 수 없습니다"))
            return
        }
        let muted = readMute(device: device) ?? false
        update(value: muted ? 0 : volume, availability: .available)
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

    private func readVolume(device: AudioDeviceID) -> Double? {
        for element in Self.volumeElements {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: element
            )
            guard AudioObjectHasProperty(device, &address) else { continue }
            var volume = Float32(0)
            var size = UInt32(MemoryLayout<Float32>.size)
            let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
            if status == noErr, volume.isFinite {
                return Double(volume)
            }
        }
        return nil
    }

    private func readMute(device: AudioDeviceID) -> Bool? {
        for element in Self.volumeElements {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: element
            )
            guard AudioObjectHasProperty(device, &address) else { continue }
            var mute = UInt32(0)
            var size = UInt32(MemoryLayout<UInt32>.size)
            let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &mute)
            if status == noErr {
                return mute != 0
            }
        }
        return nil
    }
}

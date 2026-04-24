import AppKit
import Combine
import CoreAudio

@MainActor
final class AudioController: ObservableObject {
    @Published private(set) var isMuted: Bool = false
    
    nonisolated(unsafe) private var pollingTimer: Timer?
    
    init() {
        refresh()
        startPolling()
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
    
    func toggle() {
        setMuted(!isMuted)
        refresh()
    }
    
    func refresh() {
        isMuted = getInputMuted()
    }
    
    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
    
    // MARK: - CoreAudio
    
    private func getDefaultInputDevice() -> AudioDeviceID? {
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        
        guard status == noErr else {
            print("Failed to get default input device: \(status)")
            return nil
        }
        
        return deviceID
    }
    
    private func getInputMuted() -> Bool {
        guard let deviceID = getDefaultInputDevice() else { return false }
        
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
        
        if status != noErr {
            print("Failed to get mute state: \(status)")
            return false
        }
        
        return muted != 0
    }
    
    private func setMuted(_ mute: Bool) {
        guard let deviceID = getDefaultInputDevice() else { return }
        
        var muted: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &muted)
        
        if status != noErr {
            print("Failed to set mute state: \(status)")
        }
    }
}

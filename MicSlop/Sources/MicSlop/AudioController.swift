import AppKit
import Combine

@MainActor
final class AudioController: ObservableObject {
    @Published private(set) var volume: Int = 0
    
    nonisolated(unsafe) private var pollingTimer: Timer?
    
    init() {
        refresh()
        startPolling()
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
    
    func toggle() {
        if volume > 0 {
            setInputVolume(0)
        } else {
            setInputVolume(50)
        }
        refresh()
    }
    
    func refresh() {
        volume = getInputVolume()
    }
    
    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }
    
    private func getInputVolume() -> Int {
        let script = NSAppleScript(source: "input volume of (get volume settings)")
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error getting volume: \(error)")
            return volume // Return last known state
        }
        
        return Int(result?.int32Value ?? 0)
    }
    
    private func setInputVolume(_ newVolume: Int) {
        let script = NSAppleScript(source: "set volume input volume \(newVolume)")
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        
        if let error = error {
            print("AppleScript error setting volume: \(error)")
        }
    }
}

import SwiftUI
import HotKey
import ServiceManagement
import Combine

@main
struct MicSlopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var audioController: AudioController!
    private var hotKey: HotKey?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        audioController = AudioController()
        
        setupStatusItem()
        setupHotKey()
        setupLaunchAtLogin()
        
        observeMuteChanges()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.autosaveName = "com.micslop.statusitem"
        
        updateStatusItemView()
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    private func updateStatusItemView() {
        let isOnAir = !audioController.isMuted
        let text = isOnAir ? "ON AIR" : "OFF AIR"
        let backgroundColor = isOnAir 
            ? NSColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1.0)
            : NSColor(white: 0.557, alpha: 1.0)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white,
            .backgroundColor: backgroundColor
        ]
        
        statusItem.button?.attributedTitle = NSAttributedString(string: " \(text) ", attributes: attributes)
    }
    
    private func setupHotKey() {
        hotKey = HotKey(key: .l, modifiers: [.command])
        hotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.audioController.toggle()
            }
        }
    }
    
    private func setupLaunchAtLogin() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to register launch at login: \(error)")
        }
    }
    
    private func observeMuteChanges() {
        audioController.$isMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemView()
            }
            .store(in: &cancellables)
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}

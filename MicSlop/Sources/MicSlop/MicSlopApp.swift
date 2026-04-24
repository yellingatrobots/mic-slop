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
        
        observeVolumeChanges()
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
        let isOnAir = audioController.volume > 0
        let view = StatusBarView(isOnAir: isOnAir)
        let hostingView = NSHostingView(rootView: view)
        hostingView.setFrameSize(hostingView.fittingSize)
        
        statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
        
        // Use menu bar height for proper centering
        let menuBarHeight = NSStatusBar.system.thickness
        let viewSize = hostingView.fittingSize
        let yOffset = (menuBarHeight - viewSize.height) / 2
        
        hostingView.frame = NSRect(
            x: 0,
            y: yOffset,
            width: viewSize.width,
            height: viewSize.height
        )
        
        statusItem.button?.addSubview(hostingView)
        statusItem.button?.frame.size.width = viewSize.width
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
    
    private func observeVolumeChanges() {
        audioController.$volume
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

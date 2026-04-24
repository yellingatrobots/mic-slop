# MicSlop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that toggles system input volume between 0 and 50 via Cmd+L hotkey with visual ON AIR / OFF AIR status.

**Architecture:** SwiftUI App with AppDelegate for menu bar integration. AudioController handles volume via NSAppleScript with 60s polling. StatusBarView renders colored label. HotKey package for global shortcuts.

**Tech Stack:** Swift, SwiftUI, SPM, HotKey (sindresorhus), SMAppService, NSAppleScript

---

## File Structure

```
MicSlop/
├── Package.swift              # SPM manifest with HotKey dependency
├── Sources/
│   └── MicSlop/
│       ├── MicSlopApp.swift       # App entry point, AppDelegate setup
│       ├── StatusBarView.swift    # ON AIR / OFF AIR SwiftUI view
│       └── AudioController.swift  # Volume control + polling timer
└── Info.plist                 # LSUIElement=true, other metadata
```

**Responsibilities:**
- `Package.swift` - Declares executable target, HotKey dependency via SPM
- `MicSlopApp.swift` - SwiftUI App conformer, creates AppDelegate, owns NSStatusItem, registers HotKey, sets up launch-at-login
- `StatusBarView.swift` - Pure SwiftUI view: red "ON AIR" or grey "OFF AIR" based on volume
- `AudioController.swift` - ObservableObject wrapping NSAppleScript for volume get/set, Timer for polling

---

### Task 1: Create Package.swift with HotKey Dependency

**Files:**
- Create: `MicSlop/Package.swift`

- [ ] **Step 1: Create MicSlop directory structure**

```bash
mkdir -p MicSlop/Sources/MicSlop
```

- [ ] **Step 2: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicSlop",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "MicSlop",
            dependencies: ["HotKey"]
        )
    ]
)
```

- [ ] **Step 3: Verify package resolves**

Run: `cd MicSlop && swift package resolve`
Expected: Fetches HotKey dependency, no errors

- [ ] **Step 4: Commit**

```bash
git add MicSlop/Package.swift
git commit -m "feat: init SPM package with HotKey dependency"
```

---

### Task 2: Create AudioController with Volume Toggle

**Files:**
- Create: `MicSlop/Sources/MicSlop/AudioController.swift`

- [ ] **Step 1: Create AudioController.swift with volume property and AppleScript helpers**

```swift
import AppKit
import Combine

@MainActor
final class AudioController: ObservableObject {
    @Published private(set) var volume: Int = 0
    
    private var pollingTimer: Timer?
    
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
```

- [ ] **Step 2: Verify it compiles**

Run: `cd MicSlop && swift build 2>&1 | head -20`
Expected: Build proceeds (may fail on missing main entry point, that's expected)

- [ ] **Step 3: Commit**

```bash
git add MicSlop/Sources/MicSlop/AudioController.swift
git commit -m "feat: add AudioController with AppleScript volume control"
```

---

### Task 3: Create StatusBarView

**Files:**
- Create: `MicSlop/Sources/MicSlop/StatusBarView.swift`

- [ ] **Step 1: Create StatusBarView.swift**

```swift
import SwiftUI

struct StatusBarView: View {
    let isOnAir: Bool
    
    var body: some View {
        Text(isOnAir ? "ON AIR" : "OFF AIR")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isOnAir ? Color(red: 1.0, green: 0.231, blue: 0.188) : Color(white: 0.557))
            .cornerRadius(3)
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBarView(isOnAir: true)
        StatusBarView(isOnAir: false)
    }
    .padding()
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd MicSlop && swift build 2>&1 | head -20`
Expected: Build proceeds (still may fail on missing main entry point)

- [ ] **Step 3: Commit**

```bash
git add MicSlop/Sources/MicSlop/StatusBarView.swift
git commit -m "feat: add StatusBarView with ON AIR / OFF AIR display"
```

---

### Task 4: Create MicSlopApp with AppDelegate and Menu Bar Integration

**Files:**
- Create: `MicSlop/Sources/MicSlop/MicSlopApp.swift`

- [ ] **Step 1: Create MicSlopApp.swift with full menu bar setup**

```swift
import SwiftUI
import HotKey
import ServiceManagement

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
        
        updateStatusItemView()
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    private func updateStatusItemView() {
        let isOnAir = audioController.volume > 0
        let hostingView = NSHostingView(rootView: StatusBarView(isOnAir: isOnAir))
        hostingView.frame = NSRect(x: 0, y: 0, width: 60, height: 22)
        statusItem.button?.subviews.forEach { $0.removeFromSuperview() }
        statusItem.button?.addSubview(hostingView)
        statusItem.button?.frame = hostingView.frame
    }
    
    private func setupHotKey() {
        hotKey = HotKey(key: .l, modifiers: [.command])
        hotKey?.keyDownHandler = { [weak self] in
            self?.audioController.toggle()
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

import Combine
```

- [ ] **Step 2: Verify it compiles**

Run: `cd MicSlop && swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add MicSlop/Sources/MicSlop/MicSlopApp.swift
git commit -m "feat: add MicSlopApp with menu bar, hotkey, and launch-at-login"
```

---

### Task 5: Create Info.plist for LSUIElement

**Files:**
- Create: `MicSlop/Info.plist`

- [ ] **Step 1: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.micslop.app</string>
    <key>CFBundleName</key>
    <string>MicSlop</string>
    <key>CFBundleDisplayName</key>
    <string>MicSlop</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 2: Update Package.swift to reference Info.plist**

Update the target in Package.swift to include resources:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicSlop",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "MicSlop",
            dependencies: ["HotKey"],
            resources: [
                .copy("../../Info.plist")
            ]
        )
    ]
)
```

Note: SPM executables don't automatically use Info.plist like Xcode projects. For proper LSUIElement behavior, we'll need to run as an .app bundle. For development, the app will show in dock.

- [ ] **Step 3: Verify build still works**

Run: `cd MicSlop && swift build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add MicSlop/Info.plist MicSlop/Package.swift
git commit -m "feat: add Info.plist with LSUIElement for menu-bar-only mode"
```

---

### Task 6: Test Full App Functionality

**Files:**
- None (manual testing)

- [ ] **Step 1: Build and run the app**

Run: `cd MicSlop && swift run`
Expected: App starts, menu bar shows "ON AIR" or "OFF AIR" based on current input volume

- [ ] **Step 2: Test hotkey toggle**

Press: Cmd+L
Expected: 
- If was "ON AIR" (volume > 0), becomes "OFF AIR" (volume = 0)
- If was "OFF AIR" (volume = 0), becomes "ON AIR" (volume = 50)
- System input volume changes accordingly

- [ ] **Step 3: Test external volume change detection**

Action: Use System Settings > Sound > Input to change volume
Wait: Up to 60 seconds
Expected: Menu bar status updates to reflect actual volume

- [ ] **Step 4: Test quit menu**

Action: Click status bar item, click "Quit"
Expected: App terminates

- [ ] **Step 5: Commit any fixes if needed**

If issues found, fix and commit with appropriate message.

---

### Task 7: Create App Bundle for LSUIElement (Optional for Development)

**Files:**
- Create: `MicSlop/build-app.sh`

This task creates an app bundle so LSUIElement works properly (no dock icon).

- [ ] **Step 1: Create build script**

```bash
#!/bin/bash
set -e

# Build release
swift build -c release

# Create app bundle structure
APP_NAME="MicSlop.app"
rm -rf "$APP_NAME"
mkdir -p "$APP_NAME/Contents/MacOS"
mkdir -p "$APP_NAME/Contents/Resources"

# Copy executable
cp .build/release/MicSlop "$APP_NAME/Contents/MacOS/"

# Copy Info.plist
cp Info.plist "$APP_NAME/Contents/"

echo "Built $APP_NAME"
echo "Run with: open MicSlop.app"
```

- [ ] **Step 2: Make script executable**

Run: `chmod +x MicSlop/build-app.sh`

- [ ] **Step 3: Build app bundle**

Run: `cd MicSlop && ./build-app.sh`
Expected: MicSlop.app created

- [ ] **Step 4: Test app bundle**

Run: `open MicSlop/MicSlop.app`
Expected: App starts, no dock icon, menu bar shows status

- [ ] **Step 5: Commit**

```bash
git add MicSlop/build-app.sh
git commit -m "feat: add build script for app bundle with LSUIElement"
```

---

## Summary

| Task | Component | Purpose |
|------|-----------|---------|
| 1 | Package.swift | SPM setup with HotKey dependency |
| 2 | AudioController | Volume get/set via AppleScript, polling |
| 3 | StatusBarView | ON AIR / OFF AIR visual display |
| 4 | MicSlopApp | App entry, menu bar, hotkey, launch-at-login |
| 5 | Info.plist | LSUIElement for menu-bar-only |
| 6 | Testing | Manual verification of all features |
| 7 | build-app.sh | App bundle creation for proper LSUIElement |

All spec requirements covered:
- Toggle: Cmd+L toggles volume 0 ↔ 50
- Status display: Red "ON AIR" / Grey "OFF AIR"
- External changes: 60s polling via Timer
- Menu: Quit option only
- Launch at login: SMAppService registered by default
- No dock icon: LSUIElement=true in Info.plist (requires app bundle)

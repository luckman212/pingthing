//
//  PingThing
//  AppDelegate.swift
//

import Cocoa
import SwiftyPing
import UserNotifications

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let monitor = PingMenuNetworkMonitor()
    let menu = NSMenu()

    var pingGraphView: PingResponseGraphView?
    var menuItemLabelView: MenuItemLabelView!
    var prefsWindow: PreferencesWindowController?
    var logWindow: LogWindowController?
    var pinger: SwiftyPing?

    var statusItem: NSStatusItem!
    var currentPingTime: NSMenuItem!
    var retryWorkItem: DispatchWorkItem?
    var target: String = ""
    
    var currentDynamicColor: NSColor = NSColor.labelColor
    var currentTheme: String? = nil
    var cachedCptAttributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: NSColor.labelColor,
        .font: NSFont.menuFont(ofSize: NSFont.systemFontSize)
    ]
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
   
    func applicationDidFinishLaunching(_ notification: Notification) {
        self.logWindow = LogWindowController()
        updateThemeColors()
        
        menuItemLabelView = MenuItemLabelView(text: "Initializing…", color: currentDynamicColor)
        menuItemLabelView.frame = NSRect(origin: .zero, size: menuItemLabelView.intrinsicContentSize)
        currentPingTime = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        currentPingTime.isEnabled = false
        currentPingTime.view = menuItemLabelView
        menu.addItem(currentPingTime)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Show Log", action: #selector(showLogWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q"))
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            PTdebugPrint("Delayed block")
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
            PTdebugPrint("Timer fired")
        }
        */
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNetworkChange(_:)),
            name: .networkStatusChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setupPinger(_:)),
            name: .preferencesDidChange,
            object: nil
        )

        DistributedNotificationCenter.default.addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            PTdebugPrint("Detected theme change")
            self.updateThemeColors()
        }
        
        // request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                PTdebugPrint("Error requesting notification permission: \(error)")
            } else {
                PTdebugPrint("Notification permission granted: \(granted)")
            }
        }
        
        // initialize state
        setupPinger()
    }
      
    func createStatusItem() {
        let historySize = UserDefaults.standard.object(forKey: "HistorySize") as? Int ?? defaultHistorySize
        let barWidth = UserDefaults.standard.object(forKey: "BarWidth") as? Int ?? defaultBarWidth
        let absoluteWidth = Double(historySize * barWidth)
        if statusItem != nil {
            if statusItem.length == absoluteWidth { return } // don't recreate if width didn't change
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = NSStatusBar.system.statusItem(withLength: absoluteWidth)

        if let button = statusItem.button {
            button.image = nil
            button.title = ""
            button.toolTip = k_AppName

            let container = NSView(frame: NSRect(x: 0, y: 0, width: absoluteWidth, height: k_graphHeight))
            container.wantsLayer = true
            container.layer?.cornerRadius = k_graphCornerRadius
            container.layer?.masksToBounds = false

            let pgv = PingResponseGraphView(historySize: historySize, barWidth: barWidth)
            pgv.frame = container.bounds
            pgv.autoresizingMask = [.width, .height]
            pgv.wantsLayer = true
            pgv.layer?.cornerRadius = k_graphCornerRadius
            pgv.layer?.masksToBounds = true
            container.addSubview(pgv)
            pingGraphView = pgv
                        
            button.addSubview(container)
            container.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                container.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                container.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                container.topAnchor.constraint(equalTo: button.topAnchor),
                container.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
        }
        statusItem.menu = menu
    }

    @objc func handleNetworkChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let isConnected = userInfo["isConnected"] as? Bool else {
            return
        }
        PTdebugPrint("Received networkStatusChanged notification: isConnected = \(isConnected)")
        if isConnected {
            setupPinger()
        } else {
            stopPinger()
        }
    }
    
    @objc func openPreferences() {
        if prefsWindow == nil {
            prefsWindow = PreferencesWindowController()
        }
        prefsWindow?.showWindow(nil)
        if let window = self.prefsWindow?.window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(self.prefsWindow?.targetField)
        }
    }
  
    @objc func showLogWindow() {
        if logWindow == nil {
          logWindow = LogWindowController()
        }
        if let window = logWindow?.window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }

    func getThemeAndColor(for appearance: NSAppearance) -> (theme: String, color: NSColor) {
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return ("dark", NSColor.white)
        } else {
            return ("light", NSColor.black)
        }
        /*
        self.currentDynamicColor = NSColor(
            name: nil,
            dynamicProvider: { appearance in
                if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                    return NSColor.white
                } else {
                    return NSColor.black
                }
            }
        )
        */
    }

    func updateThemeColors() {
        PTdebugPrint("in updateThemeColors()")
        let appearance = NSApp.effectiveAppearance
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            currentDynamicColor = NSColor.white
            currentTheme = "dark"
        } else {
            currentDynamicColor = NSColor.black
            currentTheme = "light"
        }
        PTdebugPrint("Updated current theme: \(currentTheme ?? "unknown"), currentDynamicColor: \(currentDynamicColor)")
        menuItemLabelView?.updateColor(currentDynamicColor)
    }
    
    func paintCptItem(_ str: String) {
        menuItemLabelView.updateText(str)
        currentPingTime.menu?.update()
    }
    
    func timeoutResponse(with time: Double) {
        pingGraphView?.addPingResponse(time)
        guard let currentPinger = pinger, let ip = currentPinger.destination.ip else { return }
        if target != ip {
            paintCptItem(String(format: "🔴 %@ [%@] (timeout)", target, ip))
        } else {
            paintCptItem(String(format: "🔴 %@ (timeout)", target))
        }
        statusItem.button?.toolTip = "timeout"
    }

    func updatePingResponse(with time: Double) {
        pingGraphView?.addPingResponse(time)
        let curMs: Double = time * 1000
        guard let currentPinger = pinger, let ip = currentPinger.destination.ip else { return }
        if target != ip {
            paintCptItem(String(format: "🟢 %@ [%@] • %.0fms", target, ip, curMs))
        } else {
            paintCptItem(String(format: "🟢 %@ • %.0fms", target, curMs))
        }
        if let avg = pingGraphView?.averagePing {
            let avgMs: Double = avg * 1000
            statusItem.button?.toolTip = String(format: "%.0fms (avg: %.1f)", curMs, avgMs)
        } else {
            statusItem.button?.toolTip = k_AppName
        }
    }
    
    func stopPinger() {
        if let currentPinger = self.pinger {
            currentPinger.stopPinging()
            self.pinger = nil
        }
        paintCptItem("🔴 \(target) (waiting for network)")
        pingGraphView?.pingerActive = false
    }
    
    @objc func setupPinger(_ notification: Notification? = nil) {
        retryWorkItem?.cancel()
        retryWorkItem = nil
        stopPinger() // Stop existing pinger before starting a new one

        target = UserDefaults.standard.object(forKey: "PingTarget") as? String ?? defaultPingTarget
        let interval = UserDefaults.standard.object(forKey: "PingInterval") as? Double ?? defaultPingInterval
        let timeout = UserDefaults.standard.object(forKey: "PingTimeout") as? Double ?? defaultPingTimeout
        let pingConfiguration = PingConfiguration(interval: interval, with: timeout)
        PTdebugPrint("Ping configuration - target: \(target), interval: \(interval), timeout: \(timeout)")

        if !monitor.isActive {
            PTdebugPrint("WARNING: Network not active, retrying in 5 seconds")
            schedulePingerSetupRetry()
            return
        } else {
            PTdebugPrint("Network is active")
        }

        createStatusItem()
        
        do {
            self.pinger = try SwiftyPing(
                host: target,
                configuration: pingConfiguration,
                queue: DispatchQueue.global()
            )
        } catch {
            PTdebugPrint("⚠️ Failed to initialize \(target): \(error)")
            paintCptItem("❌ Error: \(error)")
            schedulePingerSetupRetry()
            return
        }
            
        self.pinger?.observer = { [weak self] response in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = response.error {
                    switch error {
                        case .requestTimeout, .responseTimeout:
                            //PTdebugPrint("⏳ Ping timeout")
                            self.timeoutResponse(with: timeout)
                        case .unknownHostError, .addressLookupError, .hostNotFound:
                            PTdebugPrint("⚠️ Host not found, or DNS lookup failure: \(error)")
                            self.paintCptItem("❌ DNS error (\(error))")
                            self.schedulePingerSetupRetry()
                        default:
                            PTdebugPrint("⚠️ SwiftyPing error: \(error)")
                            self.paintCptItem("❌ Error: \(error)")
                            self.schedulePingerSetupRetry()
                      }
                } else {
                    let duration = response.duration
                    self.updatePingResponse(with: duration)
                }
            }
        }
            
        do {
            try self.pinger?.startPinging()
            pingGraphView?.pingerActive = true
        } catch {
            PTdebugPrint("ERROR: Failed to start pinging: \(error)")
            paintCptItem("❌ \(target) (\(error))")
            schedulePingerSetupRetry()
        }

    }
  
    private func schedulePingerSetupRetry(after delay: TimeInterval = 5.0) {
        retryWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.setupPinger()
        }
        retryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        PTdebugPrint("Shutting down")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .preferencesDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .networkStatusChanged, object: nil)
    }

}

//
//  AppDelegate.swift
//  pingthing LoginHelper
//

import AppKit

@main
class HelperAppDelegate: NSObject, NSApplicationDelegate {
    
    static func main() {
        let hApp = NSApplication.shared
        let hAppDelegate = HelperAppDelegate()
        hApp.delegate = hAppDelegate
        hApp.setActivationPolicy(.accessory)
        hApp.run()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let workspace = NSWorkspace.shared
        let mainAppBundleID = "com.luckman212.pingthing"
        let runningApps = workspace.runningApplications
        let isRunning = runningApps.contains {
            $0.bundleIdentifier == mainAppBundleID
        }
        
        if !isRunning {
            guard let url = workspace.urlForApplication(withBundleIdentifier: mainAppBundleID) else {
                print("Could not locate the main app with bundle ID \(mainAppBundleID)")
                NSApp.terminate(nil)
                return
            }
            
            let configuration = NSWorkspace.OpenConfiguration()
            workspace.openApplication(at: url, configuration: configuration) { app, error in
                if let error = error {
                    print("Failed to launch main app: \(error)")
                }
                NSApp.terminate(nil)
            }
        }
    }
    
}

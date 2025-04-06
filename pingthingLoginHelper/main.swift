//
//  pingthing LaunchAtLoginHelper
//

import AppKit

func main() {
    let workspace = NSWorkspace.shared
    guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
        print("Failed to retrieve bundle identifier")
        exit(1)
    }
    let mainAppBundleId = bundleIdentifier.replacingOccurrences(of: ".LoginHelper", with: "")
    if !NSRunningApplication.runningApplications(withBundleIdentifier: mainAppBundleId).isEmpty {
        exit(0)
    }
    guard let url = workspace.urlForApplication(withBundleIdentifier: mainAppBundleId) else {
        print("Could not locate the main app with bundle ID \(mainAppBundleId)")
        exit(1)
    }
    let configuration = NSWorkspace.OpenConfiguration()
    let group = DispatchGroup()
    group.enter()
    workspace.openApplication(at: url, configuration: configuration) { app, error in
        if let error = error {
            print("Failed to launch main app: \(error)")
        }
        group.leave()
    }
    group.wait()
    exit(0)
}

main()

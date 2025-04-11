//
//  Constants.swift
//

import AppKit

let k_AppName: String = "PingThing"
let k_logwindow_q: String = "\(Bundle.main.bundleIdentifier ?? "com.luckman212.pingthing").debugLogger"

let defaultPingTarget = "8.8.8.8" // or "one.one.one.one"
let defaultPingInterval: Double = 1.0
let defaultPingTimeout: Double = 5.0
let defaultHistorySize: Int = 24
let defaultBarWidth: Int = 2

let k_fastMs: Double = 40
let k_mediumMs: Double = 100
let k_slowMs: Double = 200

let k_graphHeight: CGFloat = 22.0
let k_graphCornerRadius: CGFloat = 3
let k_graphBarAlpha: CGFloat = 0.7      // suggest: 0.5—0.7
let k_graphBorderAlpha: CGFloat = 0.15  // suggest: 0.1—0.2

let k_barsAntiAliasing: Bool = false
let k_CGAntiAliasing: Bool = true

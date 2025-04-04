//
//  NetworkMonitor.swift
//

import Foundation
import Network
import Combine

class PingMenuNetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let monitor_queue = DispatchQueue(label: "NetworkMonitor")

    var isActive: Bool = false
    var isExpensive: Bool = false
    var isConstrained: Bool = false
    var connectionType: NWInterface.InterfaceType = .other

    // track previous state so we only post notifications if changed
    private var previousActive: Bool = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let currentActive = path.status == .satisfied

            if currentActive != self.previousActive {
                self.previousActive = currentActive
                print("DEBUG: Network status changed. isConnected: \(currentActive)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .networkStatusChanged,
                        object: self,
                        userInfo: ["isConnected": currentActive]
                    )
                }
            }

            self.isActive = currentActive
            self.isExpensive = path.isExpensive
            self.isConstrained = path.isConstrained

            // https://developer.apple.com/documentation/network/nwinterface/interfacetype
            let connectionTypes: [NWInterface.InterfaceType] = [.cellular, .wifi, .wiredEthernet]
            self.connectionType = connectionTypes.first(where: path.usesInterfaceType) ?? .other

            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
        monitor.start(queue: monitor_queue)
    }
}

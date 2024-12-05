//
//  NetworkMonitor.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 5/11/24.
//

import Foundation
import Network

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionDescription = ""
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionDescription = self?.getConnectionDescription(path) ?? ""
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionDescription(_ path: NWPath) -> String {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                return "WiFi connected"
            } else if path.usesInterfaceType(.cellular) {
                return "Cellular connected"
            } else {
                return "Connected"
            }
        } else {
            return "No connection"
        }
    }
}

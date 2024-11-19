//
//  ReachabilityManager.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 18/11/24.
//

import Foundation
import Network

class ReachabilityManager: ObservableObject {
    static let shared = ReachabilityManager() // Sprint 3: Singleton instance

    @Published var isConnected: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ReachabilityQueue")

    private init() { // Private initializer for singleton
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}

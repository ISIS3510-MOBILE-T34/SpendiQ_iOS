//
//  PersistenceController.swift
//  SpendiQ
//
//  Created by Juan Salguero on 16/11/24.
//

// PersistenceController.swift

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "CachedModel") // Replace with your data model name
        container.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Error loading Core Data: \(error)")
            }
        }
    }
}

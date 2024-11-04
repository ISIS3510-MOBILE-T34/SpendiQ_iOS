//
//  CachedTransaction+CoreDataProperties.swift
//  SpendiQ
//
//  Created by Juan Salguero on 4/11/24.
//
//

import Foundation
import CoreData


extension CachedTransaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedTransaction> {
        return NSFetchRequest<CachedTransaction>(entityName: "CachedTransaction")
    }

    @NSManaged public var id: String?
    @NSManaged public var accountId: String?
    @NSManaged public var transactionName: String?
    @NSManaged public var amount: Int64
    @NSManaged public var dateTime: Date?
    @NSManaged public var transactionType: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var amountAnomaly: Bool
    @NSManaged public var locationAnomaly: Bool

}

extension CachedTransaction : Identifiable {

}

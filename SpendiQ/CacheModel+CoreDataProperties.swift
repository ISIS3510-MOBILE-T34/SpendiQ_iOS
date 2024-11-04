//
//  CacheModel+CoreDataProperties.swift
//  SpendiQ
//
//  Created by Juan Salguero on 4/11/24.
//
//

import Foundation
import CoreData


extension CacheModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CacheModel> {
        return NSFetchRequest<CacheModel>(entityName: "CacheModel")
    }

    @NSManaged public var accountId: String?
    @NSManaged public var amount: Int64
    @NSManaged public var amountAnomaly: Bool
    @NSManaged public var dateTime: Date?
    @NSManaged public var id: String?
    @NSManaged public var latitude: Double
    @NSManaged public var locationAnomaly: Bool
    @NSManaged public var longitude: Double
    @NSManaged public var transactionName: String?
    @NSManaged public var transactionType: String?

}

extension CacheModel : Identifiable {

}

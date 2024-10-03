//
//  ShopSalesModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct ShopSalesModel: Identifiable, Codable {
    @DocumentID var id: String?
    var placeName: String
    var offerDescription: String
    var recommendationReason: String
    var logoName: String
    var latitude: Double
    var longitude: Double
    var distance: Double?
    
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

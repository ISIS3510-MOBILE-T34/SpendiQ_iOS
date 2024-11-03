//
//  ShopModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation

struct Shop: Identifiable {
    var id: String // Firestore ID
    var city: String // Name of the city
    var name: String // Offer description for the detail view
    var shopImage: String // Image of the shop
    var latitude: Double // Latitude for map
    var longitude: Double // Longitude for map
    var distance: Int // Distance from the user, as an integer
    
}

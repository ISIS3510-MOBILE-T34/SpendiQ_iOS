//
//  Offer.swift
//  SpendiQ
//
//  Created by Fai on 18/10/24.
//

import Foundation

struct Offer: Identifiable {
    var id: String // Firestore ID
    var placeName: String // Shop or place name
    var offerDescription: String // Offer description for the detail view
    var recommendationReason: String // Recommendation based on user history
    var shopImage: String // Image of the shop
    var latitude: Double // Latitude for map
    var longitude: Double // Longitude for map
    var distance: Int // Distance from the user, as an integer
}

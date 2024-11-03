//
//  Offer.swift
//  SpendiQ
//
//  Created by Fai on 18/10/24.
//

import Foundation
import FirebaseFirestore

struct Offer: Identifiable, Equatable {
    @DocumentID var id: String?
    var placeName: String // Shop or place name
    var offerDescription: String // Offer description for the detail view
    var recommendationReason: String // Recommendation based on user history
    var shopImage: String // Image of the shop
    var latitude: Double // Latitude for map
    var longitude: Double // Longitude for map
    var distance: Int // Distance from the user, as an integer
    var shop: String //path to the related shop, which is in a path like this in Firestore (/shops/[id])
}

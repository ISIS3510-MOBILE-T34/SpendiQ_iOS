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
    var shopImage: String // URL of the Image of the shop
    var latitude: Double // Latitude for map
    var longitude: Double // Longitude for map
    var distance: Int // Distance from the user, as an integer
    var shop: String //path to the related shop, which is in a path like this in Firestore (/shops/[id])
    var featured: Bool // Sprint 4 - New feature for CAS: Can highlight one or more offers to show them first in the list and with a special design
    var viewCount: Int32 // Sprint 4 - Alonso - New BQ type 4: Giving info to the shops about how many people were engaged by the offers, specially for the featured ones, where they need to pay an extra.
}

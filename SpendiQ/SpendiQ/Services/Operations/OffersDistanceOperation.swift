//
//  OffersDistanceOperation.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 4/11/24.
//

import Foundation
import CoreLocation

@objc(OffersDistanceOperation)
final class OffersDistanceOperation: Operation {
    private let offers: [Offer]
    private let userLocation: CLLocation
    private(set) var processedOffers: [Offer]?
    
    init(offers: [Offer], userLocation: CLLocation) {
        self.offers = offers
        self.userLocation = userLocation
        super.init()
    }
    
    override func main() {
        // Check if operation was cancelled before starting
        guard !isCancelled else { return }
        
        // Process offers in background
        processedOffers = offers.map { offer in
            // Check for cancellation during processing
            guard !isCancelled else { return offer }
            
            var updatedOffer = offer
            let offerLocation = CLLocation(latitude: offer.latitude, longitude: offer.longitude)
            let distanceInMeters = userLocation.distance(from: offerLocation)
            updatedOffer.distance = Int(distanceInMeters)
            return updatedOffer
        }
        .sorted { ($0.distance) < ($1.distance) }
    }
}

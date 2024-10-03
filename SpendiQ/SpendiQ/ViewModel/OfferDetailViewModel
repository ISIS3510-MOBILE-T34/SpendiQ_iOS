//
//  OfferDetailViewModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation
import MapKit

class OfferDetailViewModel: ObservableObject {
    @Published var region: MKCoordinateRegion
    var offer: OfferModel
    
    init(offer: OfferModel) {
        self.offer = offer
        self.region = MKCoordinateRegion(
            center: offer.locationCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

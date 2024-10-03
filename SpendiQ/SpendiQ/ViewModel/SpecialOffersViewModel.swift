//
//  SpecialOffersViewModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation
import Combine
import CoreLocation

class SpecialOffersViewModel: ObservableObject {
    @Published var offers: [OfferModel] = []
    @Published var userName: String = "User"
    private var dataService = DataService()
    private var locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchUserName()
        fetchOffers()
        observeLocation()
    }
    
    private func fetchUserName() {
        // Replace with actual user fetching logic
        userName = "John"
    }
    
    private func fetchOffers() {
        dataService.fetchOffers { [weak self] fetchedOffers in
            DispatchQueue.main.async {
                self?.offers = fetchedOffers
            }
        }
    }
    
    private func observeLocation() {
        locationManager.$location
            .sink { [weak self] location in
                guard let self = self, let userLocation = location else { return }
                self.calculateDistances(from: userLocation)
            }
            .store(in: &cancellables)
    }
    
    private func calculateDistances(from userLocation: CLLocation) {
        offers = offers.map { offer in
            var updatedOffer = offer
            let offerLocation = CLLocation(latitude: offer.latitude, longitude: offer.longitude)
            let distanceInMeters = userLocation.distance(from: offerLocation)
            updatedOffer.distance = distanceInMeters
            return updatedOffer
        }
        .sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
    }
}

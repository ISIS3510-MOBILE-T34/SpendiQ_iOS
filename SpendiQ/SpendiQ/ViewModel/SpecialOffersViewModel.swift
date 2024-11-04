//
//  SpecialOffersViewModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//
import Foundation
import Combine
import CoreLocation

@MainActor
class SpecialOffersViewModel: ObservableObject {
    @Published var offers: [Offer] = []
    @Published var userName: String = "User"
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var dataService = DataService()
    private var locationManager: LocationManager
    private var cancellables = Set<AnyCancellable>()
    private let processingQueue = DispatchQueue(label: "com.spendiq.offersprocessing", qos: .userInitiated)
    
    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager
        setupBindings()
        Task {
            await fetchInitialData()
        }
    }
    
    private func setupBindings() {
        locationManager.$location
            .debounce(for: .seconds(1), scheduler: processingQueue)
            .compactMap { $0 }
            .sink { [weak self] location in
                Task { [weak self] in
                    await self?.updateOffersWithLocation(location)
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch user name
        fetchUserName()
        
        // Fetch offers
        await fetchOffers()
    }
    
    private func fetchUserName() {
        // Replace with actual user fetching logic
        userName = "John"
    }
    
    func fetchOffers() async {
        isLoading = true
        error = nil
        
        do {
            var fetchedOffers = try await dataService.fetchOffers()
            
            if let currentLocation = locationManager.location {
                fetchedOffers = await dataService.processOffersWithDistance(
                    offers: fetchedOffers,
                    userLocation: currentLocation
                )
            }
            
            offers = fetchedOffers
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func updateOffersWithLocation(_ location: CLLocation) async {
        guard !offers.isEmpty else { return }
        
        let processedOffers = await dataService.processOffersWithDistance(
            offers: offers,
            userLocation: location
        )
        
        offers = processedOffers
    }
    
    // Public method to refresh data
    func refreshData() {
        Task {
            await fetchOffers()
        }
    }
}

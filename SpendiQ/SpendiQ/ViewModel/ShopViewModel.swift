//
//  ShopViewModel.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 26/10/24.
//

import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine

class ShopViewModel: ObservableObject {
    @Published var shops: [Shop] = []
    @Published var isLoading: Bool = true
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var locationManager = LocationManager()

    init() {
        // Observe location updates
        NotificationCenter.default.publisher(for: NSNotification.Name("UserLocationUpdated"))
            .sink { [weak self] notification in
                if let location = notification.userInfo?["location"] as? CLLocation {
                    self?.fetchShops(userLocation: location)
                }
            }
            .store(in: &cancellables)
    }

    func fetchShops(userLocation: CLLocation) {
        db.collection("shops").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching shops: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }

            guard let documents = snapshot?.documents else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
                return
            }

            var fetchedShops: [Shop] = []

            for doc in documents {
                let data = doc.data()
                guard
                    let city = data["city"] as? String,
                    let name = data["name"] as? String,
                    let shopImage = data["shopImage"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double
                else { continue }

                let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distanceInMeters = userLocation.distance(from: shopLocation)

                let shop = Shop(
                    id: doc.documentID,
                    city: city,
                    name: name,
                    shopImage: shopImage,
                    latitude: latitude,
                    longitude: longitude,
                    distance: Int(distanceInMeters)
                )
                fetchedShops.append(shop)
            }

            // Sort shops by distance
            DispatchQueue.main.async {
                self?.shops = fetchedShops.sorted(by: { $0.distance < $1.distance })
                self?.isLoading = false
            }
        }
    }
}

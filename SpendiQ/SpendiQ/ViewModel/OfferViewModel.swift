import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine

class OfferViewModel: ObservableObject {
    @Published var offers: [Offer] = []
    @Published var isLoading: Bool = true
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var locationManager = LocationManager()
    private var userLocation: CLLocation?
    
    @Published var locationAccessDenied: Bool = false
    
    init(mockData: Bool = false) {
        if mockData {
            // Provide some mock data for preview purposes
            self.offers = [
                Offer(id: "1",
                      placeName: "McDonald's Parque 93",
                      offerDescription: "Get 20% off on all meals!",
                      recommendationReason: "You have bought 30 times in the last month",
                      shopImage: "https://pbs.twimg.com/profile_images/1798086490502643712/ntN62oCw_400x400.jpg",
                      latitude: 4.676,
                      longitude: -74.048,
                      distance: 500,
                      shopReference: "shops/25epsfpOrxLY9rfntnRa"),
                Offer(id: "2",
                      placeName: "Starbucks",
                      offerDescription: "Buy 1 get 1 free on all drinks!",
                      recommendationReason: "Great for coffee lovers",
                      shopImage: "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png",
                      latitude: 4.670,
                      longitude: -74.050,
                      distance: 200,
                      shopReference: "shops/25epsfpOrxLY9rfntnRa"),
                Offer(id: "3",
                      placeName: "Nike Store",
                      offerDescription: "Get 20% off on all sportswear!",
                      recommendationReason: "Recommended for athletes",
                      shopImage: "https://thumbs.dreamstime.com/b/conception-de-vecteur-logo-nike-noir-noire-sport-prête-à-imprimer-l-illustration-183282273.jpg",
                      latitude: 4.677,
                      longitude: -74.049,
                      distance: 1000,
                      shopReference: "shops/25epsfpOrxLY9rfntnRa")
            ]
            self.isLoading = false
        } else {
            // Observe location updates
            NotificationCenter.default.publisher(for: NSNotification.Name("UserLocationUpdated"))
                .sink { [weak self] notification in
                    if let location = notification.userInfo?["location"] as? CLLocation {
                        self?.userLocation = location
                        self?.fetchOffers()
                    }
                }
                .store(in: &cancellables)
            
            // Observe location access denied notification
            NotificationCenter.default.publisher(for: NSNotification.Name("LocationAccessDenied"))
                .sink { [weak self] _ in
                    self?.locationAccessDenied = true
                    self?.isLoading = false
                }
                .store(in: &cancellables)
        }
        
    }
    
    func fetchOffers() {
        guard let userLocation = self.userLocation else {
            print("User location not available.")
            self.isLoading = false
            return
        }
        
        db.collection("offers").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
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
            
            var fetchedOffers: [Offer] = []
            
            for doc in documents {
                let data = doc.data()
                guard
                    let placeName = data["placeName"] as? String,
                    let offerDescription = data["offerDescription"] as? String,
                    let recommendationReason = data["recommendationReason"] as? String,
                    let shopImage = data["shopImage"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double,
                    let shopReference = data["shopReference"] as? String
                else { continue }
                
                let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distanceInMeters = userLocation.distance(from: shopLocation)
                
                let offer = Offer(
                    id: doc.documentID,
                    placeName: placeName,
                    offerDescription: offerDescription,
                    recommendationReason: recommendationReason,
                    shopImage: shopImage,
                    latitude: latitude,
                    longitude: longitude,
                    distance: Int(distanceInMeters),
                    shopReference: shopReference
                )
                fetchedOffers.append(offer)
            }
            
            // Sort offers by distance
            DispatchQueue.main.async {
                self?.offers = fetchedOffers.sorted(by: { $0.distance < $1.distance })
                self?.isLoading = false
            }
        }
    }
}
    

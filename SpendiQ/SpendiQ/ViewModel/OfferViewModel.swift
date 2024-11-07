import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine

class OfferViewModel: ObservableObject {
    @Published var offers: [Offer] = []
    @Published var isLoading: Bool = true
    @Published var showNoOffersMessage: Bool = false
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var userLocation: CLLocation?
    
    private var noOffersTimer: Timer?
    private var fetchOffersTimer: Timer?
    private var isFetching: Bool = false
    
    init(locationManager: LocationManager, mockData: Bool = false) {
        if mockData {
             //Mock data
            self.offers = []
            self.isLoading = false
            self.showNoOffersMessage = self.offers.isEmpty
        } else {
             //Observe location updates
            locationManager.$location
                .sink { [weak self] location in
                    guard let self = self else { return }
                    self.userLocation = location
                    self.fetchOffers()
                }
                .store(in: &cancellables)
            
             //Start timer to fetch offers every 10 seconds
            fetchOffersTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                self?.fetchOffers()
            }
        }
    }
    
    func fetchOffers() {
        guard let userLocation = self.userLocation else {
            print("User location not available.")
            DispatchQueue.main.async {
                self.isLoading = false
                self.showNoOffersMessage = true
            }
            return
        }
        
        guard !isFetching else {
            print("Fetch already in progress.")
            return
        }
        
        isFetching = true
        self.isLoading = true
        self.showNoOffersMessage = false
        
        noOffersTimer?.invalidate()
        noOffersTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.offers.isEmpty {
                self.showNoOffersMessage = true
                print("No offers found within 6 seconds.")
            }
        }
        
        print("Fetching offers for location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
        
        db.collection("offers").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            defer { self.isFetching = false }
            
            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showNoOffersMessage = true
                }
                return
            }
            
            guard let documents = snapshot?.documents else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showNoOffersMessage = true
                }
                return
            }
            
            var fetchedOffers: [Offer] = []
            
            for doc in documents {
                let data = doc.data()
                guard
                    let shopName = data["placeName"] as? String,
                    let offerDescription = data["offerDescription"] as? String,
                    let recommendationReason = data["recommendationReason"] as? String,
                    let shopImage = data["shopImage"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double
                else {
                    print("Incomplete offer data for document ID: \(doc.documentID)")
                    continue
                }
                
                let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distanceInMeters = userLocation.distance(from: shopLocation)
                
                print("Offer '\(shopName)' is \(distanceInMeters) meters away from the user.")
                
                if distanceInMeters <= 1000 {
                    let offer = Offer(
                        id: doc.documentID,
                        placeName: shopName,
                        offerDescription: offerDescription,
                        recommendationReason: recommendationReason,
                        shopImage: shopImage,
                        latitude: latitude,
                        longitude: longitude,
                        distance: Int(distanceInMeters),
                        shop: ""
                    )
                    if !self.offers.contains(offer) {
                        fetchedOffers.append(offer)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.offers.append(contentsOf: fetchedOffers)
                self.offers.sort { $0.distance < $1.distance }
                self.isLoading = false
                self.noOffersTimer?.invalidate()
                self.showNoOffersMessage = self.offers.isEmpty
            }
        }
    }
    
    deinit {
        fetchOffersTimer?.invalidate()
        noOffersTimer?.invalidate()
    }
}

// Developed by Alonso Hernandez

import SwiftUI
import FirebaseFirestore
import CoreLocation
import Combine
import CoreData // Sprint 3

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
    public var shouldFetchOnAppear: Bool = true

    private let context = CoreDataManager.shared.context // Sprint 3
    
    init(locationManager: LocationManager, mockData: Bool = false) {
        if mockData {
            print("Using mock data for offers.")
            self.offers = []
            self.isLoading = false
            self.showNoOffersMessage = self.offers.isEmpty
        } else {
            print("Initializing OfferViewModel with live data.")
            locationManager.$location
                .sink { [weak self] location in
                    guard let self = self else { return }
                    self.userLocation = location
                    self.fetchOffers()
                }
                .store(in: &cancellables)
            
            fetchOffersTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
                self?.fetchOffers()
            }
        }
    }
    
    func removeOldOfferImages(newOffers: [Offer]) {
        let newOfferKeys = Set(newOffers.compactMap { $0.id }) // Using compactMap to remove nils
        let currentOfferKeys = Set(offers.compactMap { $0.id })

        let removedOffers = currentOfferKeys.subtracting(newOfferKeys)
        ImageCacheManager.shared.clearCache(forKeys: Array(removedOffers))
    }
    
    func fetchOffers() {
        guard let userLocation = self.userLocation else {
            print("User location not available. Loading cached offers.")
            loadCachedOffers() // Sprint 3: Network falling back to Cache
            return
        }

        guard !isFetching else {
            print("Fetch already in progress. Skipping fetch.")
            return
        }
        
        if !ReachabilityManager.shared.isConnected {
            // If offline, simply load cached offers without fetching from Firebase
            print("Offline: Loading cached offers.")
            loadCachedOffers()
            return
        }
        
        if !shouldFetchOnAppear {
            print("Skipping fetch since the view is returning from the detail view.")
            return
        }

        // Proceed with online fetching
        isFetching = true
        isLoading = true
        showNoOffersMessage = false
        print("Fetching offers from Firebase...")
        db.collection("offers").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            defer { self.isFetching = false }

            if let error = error {
                print("Error fetching offers from Firebase: \(error.localizedDescription)")
                self.loadCachedOffers()
                return
            }

            guard let documents = snapshot?.documents else {
                print("No documents found in Firebase. Loading cached offers.")
                self.loadCachedOffers()
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
                print("Fetched \(fetchedOffers.count) offers from Firebase.")
                self.removeOldOfferImages(newOffers: fetchedOffers) // Sprint 3: Removing old images
                self.offers = fetchedOffers
                self.cacheOffers(fetchedOffers)
                self.isLoading = false
                self.noOffersTimer?.invalidate()
                self.showNoOffersMessage = self.offers.isEmpty
            }
        }
    }

    private func cacheOffers(_ offers: [Offer]) { // Sprint 3: Caching offers to handle the ECS3
        print("Caching \(offers.count) offers to Core Data...")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = OfferEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            
            for offer in offers {
                let offerEntity = OfferEntity(context: context)
                offerEntity.id = offer.id
                offerEntity.placeName = offer.placeName
                offerEntity.offerDescription = offer.offerDescription
                offerEntity.recommendationReason = offer.recommendationReason
                offerEntity.shopImage = offer.shopImage
                offerEntity.latitude = offer.latitude
                offerEntity.longitude = offer.longitude
                offerEntity.distance = Int16(offer.distance)
            }
            
            try context.save()
            print("Successfully cached offers.")
        } catch {
            print("Error caching offers: \(error)")
        }
    }

    func loadCachedOffers() {
        print("Loading cached offers from Core Data...")
        let fetchRequest: NSFetchRequest<OfferEntity> = OfferEntity.fetchRequest()
        
        do {
            let cachedEntities = try context.fetch(fetchRequest)
            let cachedOffers = cachedEntities.map { entity in
                Offer(
                    id: entity.id ?? "",
                    placeName: entity.placeName ?? "",
                    offerDescription: entity.offerDescription ?? "",
                    recommendationReason: entity.recommendationReason ?? "",
                    shopImage: entity.shopImage ?? "",
                    latitude: entity.latitude,
                    longitude: entity.longitude,
                    distance: Int(entity.distance),
                    shop: ""
                )
            }
            
            DispatchQueue.main.async {
                print("Loaded \(cachedOffers.count) cached offers.")
                self.offers = cachedOffers
                self.isLoading = false
                self.showNoOffersMessage = cachedOffers.isEmpty
            }
        } catch {
            print("Error loading cached offers: \(error)")
        }
    }
    
    deinit {
        fetchOffersTimer?.invalidate()
        noOffersTimer?.invalidate()
    }
}

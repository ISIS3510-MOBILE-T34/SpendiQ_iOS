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

            var featuredOffers: [Offer] = []
            var nonFeaturedOffers: [Offer] = []
            
            for doc in documents {
                let data = doc.data()
                guard
                    let shopName = data["placeName"] as? String,
                    let offerDescription = data["offerDescription"] as? String,
                    let recommendationReason = data["recommendationReason"] as? String,
                    let shopImage = data["shopImage"] as? String,
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double,
                    let isFeatured = data["featured"] as? Bool, // Sprint 4: Checking featured attribute
                    let viewCount = data["viewCount"] as? Int32
                
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
                        shop: "",
                        featured: isFeatured,
                        viewCount: viewCount
                    )
                    
                    if isFeatured {
                               featuredOffers.append(offer)
                           } else {
                               nonFeaturedOffers.append(offer)
                           }
                }
            }
            
            // Sprint4: Sorting featured offers alphabetically
            featuredOffers.sort { $0.placeName < $1.placeName }

            // Sprint4: Combining featured and non-featured offers
            let sortedOffers = featuredOffers + nonFeaturedOffers
            
            DispatchQueue.main.async {
                print("Fetched \(sortedOffers.count) offers from Firebase.")
                self.removeOldOfferImages(newOffers: sortedOffers) // Sprint 3: Removing old images
                self.offers = sortedOffers
                self.cacheOffers(sortedOffers)
                self.isLoading = false
                self.noOffersTimer?.invalidate()
                self.showNoOffersMessage = self.offers.isEmpty
            }
        }
    }
    
    // Sprint 4: BQ type 4 - Counting number of visits to the offer to show to third parties.
    func incrementViewCount(for offer: Offer) {
        guard let offerId = offer.id else {
            print("Sprint 4 - Alonso: Error: Offer ID is missing.")
            return
        }
        
        if !ReachabilityManager.shared.isConnected {
            // Offline: Cache the increment locally
            print("Sprint 4 - Alonso: Offline. Caching viewCount increment locally for \(offerId).")
            cacheViewCountIncrement(for: offerId)
            return
        }
        
        // Online: Update Firebase
        db.collection("offers").document(offerId).updateData([
            "viewCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Sprint 4 - Alonso: Error incrementing viewCount for \(offerId): \(error.localizedDescription)")
            } else {
                print("Sprint 4 - Alonso: ViewCount incremented successfully for \(offerId).")
            }
        }
    }
    
    // Sprint 4 - Alonso: Caching Strategy for New BQ Type 4
    private func cacheViewCountIncrement(for offerId: String) {
        let fetchRequest: NSFetchRequest<OfferEntity> = OfferEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", offerId)
        
        do {
            if let offerEntity = try context.fetch(fetchRequest).first {
                offerEntity.viewCount += 1
                try context.save()
                print("Sprint 4 - Alonso: Cached viewCount increment for \(offerId).")
            }
        } catch {
            print("Sprint 4 - Alonso: Error caching viewCount increment: \(error)")
        }
    }

    // Sprint 4 - Alonso: Caching Strategy for New BQ Type 4
    // Incrementing the amount of views for each updated offer which was stored locally
    func syncCachedViewCountIncrements() {
        guard ReachabilityManager.shared.isConnected else { return }

        let fetchRequest: NSFetchRequest<OfferEntity> = OfferEntity.fetchRequest()
        
        do {
            let cachedEntities = try context.fetch(fetchRequest)
            for entity in cachedEntities where entity.viewCount > 0 {
                guard let offerId = entity.id else { continue }
                let increment = Int(entity.viewCount)
                
                db.collection("offers").document(offerId).updateData([
                    "viewCount": FieldValue.increment(Int64(increment))
                ]) { error in
                    if let error = error {
                        print("Sprint 4 - Alonso: Error syncing viewCount for \(offerId): \(error.localizedDescription)")
                    } else {
                        print("Sprint 4 - Alonso: Synced viewCount for \(offerId).")
                        entity.viewCount = 0 // Reset local increment
                    }
                }
            }
            
            try context.save()
        } catch {
            print("Sprint 4 - Alonso: Error syncing cached viewCounts: \(error)")
        }
    }


    private func cacheOffers(_ offers: [Offer]) {
        print("Sprint 4 - Alonso: Caching offers including featured and viewCount attributes...")
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = OfferEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest) // Clear old cache
            
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
                offerEntity.featured = offer.featured // Sprint 4 - Alonso: Cache featured attribute
                offerEntity.viewCount = Int32(offer.viewCount) // Sprint 4 - Alonso: Cache viewCount
            }
            
            try context.save()
            print("Sprint 4 - Alonso: Offers cached successfully.")
        } catch {
            print("Sprint 4 - Alonso: Error caching offers: \(error)")
        }
    }

    func loadCachedOffers() {
        print("Sprint 4 - Alonso: Loading cached offers and ensuring sorting order...")
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
                    shop: "",
                    featured: entity.featured,
                    viewCount: Int32(entity.viewCount)
                )
            }

            // Sprint 4 - Alonso: Sorting cached offers
            let sortedOffers = cachedOffers.sorted { lhs, rhs in
                if lhs.featured && !rhs.featured {
                    return true // Featured offers come first
                } else if !lhs.featured && rhs.featured {
                    return false
                } else if lhs.featured && rhs.featured {
                    return lhs.placeName < rhs.placeName
                } else {
                    return lhs.placeName < rhs.placeName
                }
            }

            DispatchQueue.main.async {
                print("Sprint 4 - Alonso: Cached offers loaded and sorted successfully.")
                self.offers = sortedOffers
                self.isLoading = false
                self.showNoOffersMessage = sortedOffers.isEmpty
            }
        } catch {
            print("Sprint 4 - Alonso: Error loading and sorting cached offers: \(error)")
        }
    }

    
    deinit {
        fetchOffersTimer?.invalidate()
        noOffersTimer?.invalidate()
    }
}

import SwiftUI
import FirebaseFirestore

class OfferViewModel: ObservableObject {
    @Published var offers: [Offer] = []
    @Published var isLoading: Bool = true
    
    init(mockData: Bool = false) {
        if mockData {
            // Provide some mock data for preview purposes
            self.offers = [
                Offer(id: "1",
                      placeName: "McDonald's Parque 93",
                      offerDescription: "Get 20% off on all meals!",
                      recommendationReason: "You have bought 30 times in the last month",
                      shopImage: "https://pbs.twimg.com/profile_images/1798086490502643712/ntN62oCw_400x400.jpg", // Replace with your asset
                      latitude: 4.676,
                      longitude: -74.048,
                      distance: 500), // 500 meters
                    
                Offer(id: "2",
                      placeName: "Starbucks",
                      offerDescription: "Buy 1 get 1 free on all drinks!",
                      recommendationReason: "Great for coffee lovers",
                      shopImage: "https://upload.wikimedia.org/wikipedia/en/thumb/d/d3/Starbucks_Corporation_Logo_2011.svg/1200px-Starbucks_Corporation_Logo_2011.svg.png", // Replace with your asset
                      latitude: 4.670,
                      longitude: -74.050,
                      distance: 200), // 200 meters
                    
                Offer(id: "3",
                      placeName: "Nike Store",
                      offerDescription: "Get 20% off on all sportswear!",
                      recommendationReason: "Recommended for athletes",
                      shopImage: "https://thumbs.dreamstime.com/b/conception-de-vecteur-logo-nike-noir-noire-sport-prête-à-imprimer-l-illustration-183282273.jpg", // Replace with your asset
                      latitude: 4.677,
                      longitude: -74.049,
                      distance: 1000) // 1 km
            ]
            self.isLoading = false
        } else {
            fetchOffersFromFirebase() // Fetch offers when ViewModel is initialized
        }
    }
    
    func fetchOffersFromFirebase() {
        let db = Firestore.firestore()
        db.collection("offers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching offers: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.offers = documents.compactMap { doc in
                let data = doc.data()
                return Offer(
                    id: doc.documentID,
                    placeName: data["placeName"] as? String ?? "",
                    offerDescription: data["offerDescription"] as? String ?? "",
                    recommendationReason: data["recommendationReason"] as? String ?? "",
                    shopImage: data["shopImage"] as? String ?? "",
                    latitude: data["latitude"] as? Double ?? 0.0,
                    longitude: data["longitude"] as? Double ?? 0.0,
                    distance: data["distance"] as? Int ?? 0 // Default to 0 if not found
                )
            }
            print("Offers data loaded: ", self.offers)
            self.isLoading = false
        }
    }
}

//
//  DataService.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class DataService {
    private let db = Firestore.firestore()
    
    func fetchOffers(completion: @escaping ([OfferModel]) -> Void) {
        db.collection("offers").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var offers = [OfferModel]()
            for document in snapshot!.documents {
                do {
                    if let offer = try document.data(as: OfferModel?.self) {
                        offers.append(offer)
                    }
                } catch {
                    print("Error decoding offer: \(error.localizedDescription)")
                }
            }
            completion(offers)
        }
    }
}

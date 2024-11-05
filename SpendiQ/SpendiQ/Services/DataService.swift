//
//  DataService.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreLocation

class DataService {
    private let db = Firestore.firestore()
    private let operationQueue: OperationQueue
    
    init() {
        operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 2
        operationQueue.qualityOfService = .userInitiated
    }
    
    // Async version of fetchOffers
    func fetchOffers() async throws -> [Offer] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("offers").getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                do {
                    let offers = try snapshot?.documents.compactMap { document in
                        try document.data(as: Offer.self)
                    } ?? []
                    continuation.resume(returning: offers)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Async version of processOffersWithDistance
    func processOffersWithDistance(offers: [Offer], userLocation: CLLocation) async -> [Offer] {
        await withCheckedContinuation { continuation in
            let operation = OffersDistanceOperation(offers: offers, userLocation: userLocation)
            
            operation.completionBlock = {
                if let processedOffers = operation.processedOffers {
                    continuation.resume(returning: processedOffers)
                } else {
                    continuation.resume(returning: offers)
                }
            }
            
            operationQueue.addOperation(operation)
        }
    }
    
    // Keep the completion handler versions for backward compatibility if needed
    func fetchOffers(completion: @escaping ([Offer]) -> Void) {
        Task {
            do {
                let offers = try await fetchOffers()
                DispatchQueue.main.async {
                    completion(offers)
                }
            } catch {
                print("Error fetching offers: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    func processOffersWithDistance(offers: [Offer],
                                 userLocation: CLLocation,
                                 completion: @escaping ([Offer]) -> Void) {
        Task {
            let processedOffers = await processOffersWithDistance(offers: offers, userLocation: userLocation)
            DispatchQueue.main.async {
                completion(processedOffers)
            }
        }
    }
}

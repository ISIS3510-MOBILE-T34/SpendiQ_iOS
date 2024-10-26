//
//  FirebaseFacade.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 25/10/24.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

protocol FirebaseFacadeProtocol {
    func createUserDocument(userId: String, data: [String: Any]) -> AnyPublisher<Void, Error>
    func updateUserVerifiedEmail(userId: String, verified: Bool) -> AnyPublisher<Void, Error>
}

class FirebaseFacade: FirebaseFacadeProtocol {
    private let db = Firestore.firestore()
    
    func createUserDocument(userId: String, data: [String: Any]) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                self?.db.collection("users").document(userId).setData(data) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateUserVerifiedEmail(userId: String, verified: Bool) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                self?.db.collection("users").document(userId).updateData([
                    "verifiedEmail": verified
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}

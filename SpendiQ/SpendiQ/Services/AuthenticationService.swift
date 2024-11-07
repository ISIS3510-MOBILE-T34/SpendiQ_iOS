//
//  AuthenticationService.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<Bool, Error>
    func signUp(email: String, password: String, fullName: String, phoneNumber: String, birthDate: String) -> AnyPublisher<Bool, Error>
    func resetPassword(email: String) -> AnyPublisher<Void, Error>
    func verifyResetCode(code: String) -> AnyPublisher<Void, Error>
    func confirmPasswordReset(code: String, newPassword: String) -> AnyPublisher<Void, Error>
    func logout() -> AnyPublisher<Bool, Error>
    func getCurrentUser() -> User?
    func signInWithSavedCredentials(email: String, password: String) -> AnyPublisher<Bool, Error>
}

class AuthenticationService: AuthenticationServiceProtocol {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var currentNonce: String?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d 'de' MMMM 'de' yyyy, h:mm:ss'p.m.' z"
        formatter.timeZone = TimeZone(identifier: "UTC-5")
        return formatter
    }()
    
    private let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/M/yyyy"
        return formatter
    }()
    
    func login(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    print("Firebase login error: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                if let _ = result?.user {
                    promise(.success(true))
                } else {
                    promise(.success(false))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func signInWithSavedCredentials(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return Future { promise in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    print("Firebase saved credentials login error: \(error.localizedDescription)")
                    promise(.failure(error))
                    return
                }
                
                if let user = authResult?.user {
                    print("Successfully logged in with saved credentials for user: \(user.uid)")
                    promise(.success(true))
                } else {
                    promise(.success(false))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String, fullName: String, phoneNumber: String, birthDate: String) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }
                
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    guard let userId = authResult?.user.uid else {
                        promise(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID"])))
                        return
                    }

                    let userData: [String: Any] = [
                        "fullName": fullName,
                        "email": email,
                        "phoneNumber": phoneNumber,
                        "birthDate": birthDate,
                        "registrationDate": self.dateFormatter.string(from: Date()),
                        "verifiedPhoneNumber": false
                    ]

                    let firebaseFacade = FirebaseFacade()
                    firebaseFacade.createUserDocument(userId: userId, data: userData)
                        .sink(receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                promise(.success(true))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        }, receiveValue: { _ in })
                        .store(in: &self.cancellables)
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func resetPassword(email: String) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                Auth.auth().sendPasswordReset(withEmail: email) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func verifyResetCode(code: String) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                Auth.auth().verifyPasswordResetCode(code) { result, error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func confirmPasswordReset(code: String, newPassword: String) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { promise in
                Auth.auth().confirmPasswordReset(withCode: code, newPassword: newPassword) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { promise in
                do {
                    try Auth.auth().signOut()
                    promise(.success(true))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func getCurrentUser() -> User? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }

        var user = User(from: firebaseUser)

        // Fetch additional user data from Firestore
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] (document, error) in
            if let document = document, document.exists, var userData = document.data() {
                // Update the user object with data from Firestore
                userData["id"] = firebaseUser.uid
                userData["email"] = user.email
                userData["fullName"] = user.fullName
                userData["phoneNumber"] = user.phoneNumber

                if let verifiedPhoneNumber = userData["verifiedPhoneNumber"] as? Bool {
                    user.verifiedPhoneNumber = verifiedPhoneNumber
                }

                // You can notify observers here if needed
            } else {
                print("Error fetching user data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        return user
    }
}

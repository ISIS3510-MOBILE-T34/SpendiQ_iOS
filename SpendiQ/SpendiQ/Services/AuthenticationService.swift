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
    func verifyEmailCode(email: String, code: String) -> AnyPublisher<Bool, Error>
}

class AuthenticationService: AuthenticationServiceProtocol {
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
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
        Deferred {
            Future { promise in
                Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(true))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String, fullName: String, phoneNumber: String, birthDate: String) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { [weak self] promise in
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    guard let self = self else { return }
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
                        "verifiedEmail": false
                    ]
                    
                    let firebaseFacade = FirebaseFacade()
                    firebaseFacade.createUserDocument(userId: userId, data: userData)
                        .flatMap { _ -> AnyPublisher<Void, Error> in
                            let emailVerificationService = EmailVerificationService()
                            return emailVerificationService.sendVerificationCode(to: email)
                        }
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
    
    func verifyEmailCode(email: String, code: String) -> AnyPublisher<Bool, Error> {
        let emailVerificationService = EmailVerificationService()
        return emailVerificationService.verifyCode(code, for: email)
            .flatMap { isValid -> AnyPublisher<Bool, Error> in
                if isValid {
                    guard let userId = Auth.auth().currentUser?.uid else {
                        return Fail(error: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])).eraseToAnyPublisher()
                    }
                    let firebaseFacade = FirebaseFacade()
                    return firebaseFacade.updateUserVerifiedEmail(userId: userId, verified: true)
                        .map { _ in true }
                        .eraseToAnyPublisher()
                } else {
                    return Just(false)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
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
        
        // Primero creamos un usuario básico con los datos de Auth
        let user = User(from: firebaseUser)
        
        // También podríamos obtener los datos adicionales de Firestore si los necesitamos
        db.collection("users").document(firebaseUser.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                // Aquí podrías actualizar los datos del usuario con la información de Firestore
                // Por ejemplo, a través de un delegate o callback
            }
        }
        
        return user
    }
}

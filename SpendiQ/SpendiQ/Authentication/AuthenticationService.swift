//
//  AuthenticationService.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//
import Foundation
import Combine
import FirebaseAuth

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<Bool, Error>
    func signUp(email: String, password: String) -> AnyPublisher<Bool, Error>
    func resetPassword(email: String) -> AnyPublisher<Void, Error>
    func verifyResetCode(code: String) -> AnyPublisher<Void, Error>
    func confirmPasswordReset(code: String, newPassword: String) -> AnyPublisher<Void, Error>
}

class AuthenticationService: AuthenticationServiceProtocol {
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
    
    func signUp(email: String, password: String) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { promise in
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(true))
                    }
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
                // El método devuelve (String?, Error?), ambos deben ser manejados
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

//
//  AuthenticationService.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import Foundation
import Combine

protocol AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<Bool, Error>
    func signUp(email: String, password: String) -> AnyPublisher<Bool, Error>
}

class AuthenticationService: AuthenticationServiceProtocol {
    func login(email: String, password: String) -> AnyPublisher<Bool, Error> {
        // TODO: Implement actual login logic with Firebase
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func signUp(email: String, password: String) -> AnyPublisher<Bool, Error> {
        // TODO: Implement actual sign up logic with Firebase
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

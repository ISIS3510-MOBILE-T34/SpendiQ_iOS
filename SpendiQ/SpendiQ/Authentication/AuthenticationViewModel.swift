//
//  AuthenticationViewModel.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import Foundation
import Combine

class AuthenticationViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
    }
    
    func login() {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Login error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] success in
                self?.isAuthenticated = success
            }
            .store(in: &cancellables)
    }
    
    func signUp() {
        authService.signUp(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Sign up error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] success in
                self?.isAuthenticated = success
            }
            .store(in: &cancellables)
    }
}

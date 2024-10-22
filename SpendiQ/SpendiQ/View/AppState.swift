//
//  AppState.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 20/10/24.
//

import SwiftUI
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    private let authService: AuthenticationServiceProtocol
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
        updateAuthState()
    }
    
    func updateAuthState() {
        currentUser = authService.getCurrentUser()
        isAuthenticated = currentUser != nil
    }
}

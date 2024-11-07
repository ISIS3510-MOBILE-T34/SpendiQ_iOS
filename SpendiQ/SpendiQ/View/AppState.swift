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
    @Published var isFirstLogin = true
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
    // Al hacer login exitoso, actualizamos isFirstLogin
    func completeFirstLogin() {
        isFirstLogin = false
    }
    
    // Al hacer logout, no reseteamos isFirstLogin
    func logout() {
        isAuthenticated = false
    }
    // Método para actualizar el estado después del primer login
    func setFirstLoginComplete() {
        isFirstLogin = false
    }
    
    // Método para manejar el login exitoso
    func loginSuccessful(user: User) {
        currentUser = user
        isAuthenticated = true
        setFirstLoginComplete() // Llamamos a este método cuando el login es exitoso
    }
    
    // Método para reiniciar el estado (útil para testing o limpieza completa)
    func reset() {
        currentUser = nil
        isAuthenticated = false
        isFirstLogin = true
    }
}

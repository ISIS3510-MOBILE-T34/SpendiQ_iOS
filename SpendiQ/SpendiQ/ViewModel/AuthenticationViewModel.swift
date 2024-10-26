//
//  AuthenticationViewModel.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//
import Foundation
import Combine
import SwiftUI

class AuthenticationViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var fullName: String = ""
    @Published var phoneNumber: String = ""
    @Published var birthDate: String = ""
    @Published var errorMessage: String?
    @Published var smsCode: String = ""
    @Published var isVerificationSent: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationServiceProtocol
    private let smsService = SMSVerificationService()

    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
    }
    
    func login(appState: AppState) {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { success in
                if success {
                    appState.isAuthenticated = true
                }
            }
            .store(in: &cancellables)
    }
    
    func signUp(appState: AppState) {
        authService.signUp(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
            birthDate: birthDate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            switch completion {
            case .finished:
                self?.sendVerificationCode()
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        } receiveValue: { _ in }
        .store(in: &cancellables)
    }

    func sendVerificationCode() {
        smsService.sendVerificationCode(to: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isVerificationSent = true
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func verifySMSCode(appState: AppState) {
        smsService.verifyCode(smsCode, for: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isValid):
                    if isValid {
                        appState.isAuthenticated = true
                    } else {
                        self?.errorMessage = "Invalid verification code."
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func resetPassword() {
        authService.resetPassword(email: email)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.errorMessage = "Password reset email sent"
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func verifyResetCode(_ code: String) {
        authService.verifyResetCode(code: code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.errorMessage = "Code verified"
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func confirmPasswordReset(code: String, newPassword: String) {
        authService.confirmPasswordReset(code: code, newPassword: newPassword)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.errorMessage = "Password reset successfully"
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func loginWithFaceID(appState: AppState) {
        // Implementa la lógica para iniciar sesión con Face ID
        // Esto podría implicar recuperar credenciales almacenadas de forma segura
        // y luego llamar a la función de login
        // Por ahora, simplemente simularemos un inicio de sesión exitoso
        DispatchQueue.main.async {
            appState.isAuthenticated = true
        }
    }
    
    func logout(appState: AppState) {
        authService.logout()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Logout error: \(error.localizedDescription)")
                }
            } receiveValue: { success in
                if success {
                    appState.isAuthenticated = false
                }
            }
            .store(in: &cancellables)
    }
}

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
    @Published var isLoading = false
    @Published var rememberMe = false 

    var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationServiceProtocol
    private let smsService = SMSVerificationService()
    private let biometricAuth = BiometricAuthenticationFacade()
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
    }
    
    func login(appState: AppState) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                if success {
                    if self.rememberMe {
                        self.saveCredentialsForBiometric()
                    }
                    appState.isAuthenticated = true
                    // Marcamos que ya no es el primer login
                    appState.completeFirstLogin()
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Authentication failed"
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
                        self?.errorMessage = "Code is not valid, try again."
                    }
                case .failure:
                    self?.errorMessage = "Code is not valid, try again."
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
        print("Starting Face ID login process")
        isLoading = true
        errorMessage = nil
        
        // 1. Primero verificar si el dispositivo puede usar Face ID
        guard biometricAuth.canUseBiometrics() else {
            print("Device cannot use Face ID")
            isLoading = false
            errorMessage = "Face ID is not available on this device"
            return
        }
        
        // 2. Intentar autenticar con Face ID
        biometricAuth.authenticateUser()
            .handleEvents(
                receiveSubscription: { _ in
                    print("Starting Face ID authentication")
                },
                receiveOutput: { success in
                    print("Face ID authentication result: \(success)")
                }
            )
            .flatMap { success -> AnyPublisher<(String, String)?, Error> in
                guard success else {
                    print("Face ID authentication failed")
                    return Fail(error: BiometricError.authenticationFailed).eraseToAnyPublisher()
                }
                print("Retrieving saved credentials")
                return self.biometricAuth.retrieveBiometricCredentials()
            }
            .handleEvents(
                receiveOutput: { credentials in
                    print("Retrieved credentials: \(credentials != nil)")
                }
            )
            .flatMap { credentials -> AnyPublisher<Bool, Error> in
                guard let (email, password) = credentials else {
                    print("No credentials found")
                    return Fail(error: BiometricError.noCredentialsStored).eraseToAnyPublisher()
                }
                print("Attempting Firebase login with saved credentials")
                return self.authService.signInWithSavedCredentials(email: email, password: password)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                switch completion {
                case .finished:
                    print("Face ID login process completed")
                case .failure(let error):
                    print("Face ID login error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                self.isLoading = false
                
                if success {
                    print("Successfully logged in with Face ID")
                    appState.isAuthenticated = true
                } else {
                    print("Face ID login failed without error")
                    self.errorMessage = "Authentication failed"
                }
            }
            .store(in: &cancellables)
    }
    
    func saveCredentialsForBiometric() {
        print("Saving credentials for biometric")
        guard !email.isEmpty, !password.isEmpty else {
            print("Cannot save empty credentials")
            return
        }
        
        biometricAuth.saveBiometricCredentials(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("Credentials saved successfully")
                case .failure(let error):
                    print("Failed to save credentials: \(error)")
                }
            } receiveValue: { success in
                print("Save credentials operation completed: \(success)")
            }
            .store(in: &cancellables)
    }
    
    func canUseBiometrics() -> Bool {
        return biometricAuth.canUseBiometrics()
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
                    appState.logout() // Usamos el método del AppState
                }
            }
            .store(in: &cancellables)
    }
    
    // Input validation
    struct ValidationLimits {
        static let maxNameLength = 50
        static let maxPhoneLength = 15
        static let maxEmailLength = 100
        static let maxPasswordLength = 50
        static let minPasswordLength = 6
        static let minAge = 18
        static let maxAge = 120
    }
    
    func validateAge(birthDate: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        guard let age = ageComponents.year else { return false }
        return age >= ValidationLimits.minAge && age <= ValidationLimits.maxAge
    }
    
    func validateInputs(firstName: String, lastName: String) -> String? {
        if firstName.isEmpty || lastName.isEmpty {
            return "Please fill in all name fields"
        }
        if firstName.count > ValidationLimits.maxNameLength || lastName.count > ValidationLimits.maxNameLength {
            return "Names must be less than \(ValidationLimits.maxNameLength) characters"
        }
        if phoneNumber.count > ValidationLimits.maxPhoneLength {
            return "Phone number must be less than \(ValidationLimits.maxPhoneLength) characters"
        }
        if email.count > ValidationLimits.maxEmailLength {
            return "Email must be less than \(ValidationLimits.maxEmailLength) characters"
        }
        if password.count < ValidationLimits.minPasswordLength {
            return "Password must be at least \(ValidationLimits.minPasswordLength) characters"
        }
        if password.count > ValidationLimits.maxPasswordLength {
            return "Password must be less than \(ValidationLimits.maxPasswordLength) characters"
        }
        return nil
    }
}

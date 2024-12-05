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
    @Published var isNetworkAvailable = true
    @Published var retryAttempts = 0
    @Published var isConnected: Bool = true
    private let maxRetryAttempts = 3
    var networkMonitor: NetworkMonitor?

    var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticationServiceProtocol
    private let smsService = SMSVerificationService()
    private let biometricAuth = BiometricAuthenticationFacade()
    
    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
    }
    
    

    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func validateSignUpForm(firstName: String, lastName: String, birthDate: Date) -> String? {
        if !(networkMonitor?.isConnected ?? false) {
            return "Internet connection is required. Please check your connection."
        }
        
        if let basicValidation = validateInputs(firstName: firstName, lastName: lastName) {
            return basicValidation
        }
        
        if !validateAge(birthDate: birthDate) {
            return "You must be between \(ValidationLimits.minAge) and \(ValidationLimits.maxAge) years old"
        }
        
        if !validateEmail(email) {
            return "Please enter a valid email address"
        }
        
        return nil
    }
    
    func initializeNetworkMonitoring() {
        networkMonitor = NetworkMonitor()
        // Observar los cambios en isConnected del NetworkMonitor
        networkMonitor?.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
            }
            .store(in: &cancellables)
    }
    
    private func performLogin(appState: AppState) {
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    self.handleLoginError(error, appState: appState)
                }
            } receiveValue: { [weak self] success in
                guard let self = self else { return }
                self.isLoading = false
                self.retryAttempts = 0
                
                if success {
                    if self.rememberMe {
                        self.saveCredentialsForBiometric()
                    }
                    appState.isAuthenticated = true
                    appState.completeFirstLogin()
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "Authentication failed"
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSignUp(appState: AppState) {
        authService.signUp(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
            birthDate: birthDate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.isLoading = false
            
            switch completion {
            case .finished:
                self.retryAttempts = 0
                self.sendVerificationCode()
            case .failure(let error):
                self.handleSignUpError(error, appState: appState)
            }
        } receiveValue: { _ in }
        .store(in: &cancellables)
    }
    
    private func handleSignUpError(_ error: Error, appState: AppState) {
        if let networkError = error as? URLError {
            switch networkError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                if retryAttempts < maxRetryAttempts {
                    retryAttempts += 1
                    errorMessage = "Connection lost. Retrying... (Attempt \(retryAttempts)/\(maxRetryAttempts))"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.signUp(appState: appState)
                    }
                } else {
                    errorMessage = "Unable to connect after several attempts. Please try again later."
                }
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleLoginError(_ error: Error, appState: AppState) {
        if let networkError = error as? URLError {
            switch networkError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                if retryAttempts < maxRetryAttempts {
                    retryAttempts += 1
                    errorMessage = "Connection lost. Retrying... (Attempt \(retryAttempts)/\(maxRetryAttempts))"
                    
                    // Esperar 2 segundos antes de reintentar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.login(appState: appState)
                    }
                } else {
                    errorMessage = "Unable to connect after several attempts. Please try again later."
                }
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleNoConnection(appState: AppState) {
        isLoading = false
        errorMessage = "No internet connection. Please check your connection and try again."
        
        // Suscribirse a cambios en la conexión
        networkMonitor?.$isConnected
            .dropFirst() // Ignorar el valor inicial
            .filter { $0 } // Solo nos interesa cuando la conexión se restaura
            .first() // Tomar solo el primer evento de reconexión
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.errorMessage = "Connection restored. You can try logging in again."
            }
            .store(in: &cancellables)
    }
    
    func login(appState: AppState) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        // Verificar conexión de red
        guard networkMonitor?.isConnected == true else {
            handleNoConnection(appState: appState)
            return
        }
        
        performLogin(appState: appState)
    }
    
    deinit {
        networkMonitor?.stopMonitoring()
    }
    
    func signUp(appState: AppState) -> Bool {
        guard !isLoading else { return false }
        guard networkMonitor?.isConnected ?? false else {
            errorMessage = "No internet connection. Please check your connection and try again."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        authService.signUp(
            email: email,
            password: password,
            fullName: fullName,
            phoneNumber: phoneNumber,
            birthDate: birthDate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.isLoading = false
            
            switch completion {
            case .finished:
                self.retryAttempts = 0
                self.sendVerificationCode()
            case .failure(let error):
                self.handleSignUpError(error, appState: appState)
            }
        } receiveValue: { _ in }
        .store(in: &cancellables)
        
        return true
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
        
        // Primero verificar si hay credenciales guardadas
        biometricAuth.hasSavedCredentials()
            .flatMap { hasCreds -> AnyPublisher<Bool, Error> in
                if !hasCreds {
                    return Fail(error: BiometricError.noCredentialsStored).eraseToAnyPublisher()
                }
                return self.biometricAuth.authenticateUser()
            }
            .flatMap { _ in
                self.biometricAuth.retrieveBiometricCredentials()
            }
            .flatMap { credentials -> AnyPublisher<Bool, Error> in
                guard let (email, password) = credentials else {
                    return Fail(error: BiometricError.noCredentialsStored).eraseToAnyPublisher()
                }
                return self.authService.signInWithSavedCredentials(email: email, password: password)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
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
                    self.errorMessage = "Face ID authentication failed"
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

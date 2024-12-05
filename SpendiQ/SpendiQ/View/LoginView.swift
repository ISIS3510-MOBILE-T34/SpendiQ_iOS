//
//  LoginView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthenticationViewModel()
    
    // MARK: - State Variables
    @State private var showForgotPassword = false
    @State private var showPrivacy = false
    @State private var showHelp = false
    @State private var canUseBiometrics = false
    @State private var hasSavedCredentials = false
    @State private var showFaceIDError = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var faceIDErrorMessage = "Face ID functionality is currently unavailable. Please log in with your email and password."
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        viewModel.email.count <= AuthenticationViewModel.ValidationLimits.maxEmailLength &&
        viewModel.password.count >= AuthenticationViewModel.ValidationLimits.minPasswordLength &&
        viewModel.password.count <= AuthenticationViewModel.ValidationLimits.maxPasswordLength &&
        viewModel.email.contains("@") &&
        viewModel.email.contains(".")
    }
    
    // MARK: - View Components
    private func formField(title: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false, maxLength: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.custom("SFProText-Regular", size: 18))
            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: text.wrappedValue) { newValue in
                        if newValue.count > maxLength {
                            text.wrappedValue = String(newValue.prefix(maxLength))
                        }
                    }
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                    .onChange(of: text.wrappedValue) { newValue in
                        if newValue.count > maxLength {
                            text.wrappedValue = String(newValue.prefix(maxLength))
                        }
                    }
            }
        }
    }
    
    // MARK: - Validation Helper
    private func validateLoginForm() -> String? {
        if viewModel.email.isEmpty || viewModel.password.isEmpty {
            return "Please fill in all fields"
        }
        if viewModel.email.count > AuthenticationViewModel.ValidationLimits.maxEmailLength {
            return "Email must be less than \(AuthenticationViewModel.ValidationLimits.maxEmailLength) characters"
        }
        if viewModel.password.count < AuthenticationViewModel.ValidationLimits.minPasswordLength {
            return "Password must be at least \(AuthenticationViewModel.ValidationLimits.minPasswordLength) characters"
        }
        if viewModel.password.count > AuthenticationViewModel.ValidationLimits.maxPasswordLength {
            return "Password must be less than \(AuthenticationViewModel.ValidationLimits.maxPasswordLength) characters"
        }
        if !viewModel.email.contains("@") || !viewModel.email.contains(".") {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFFFFF").edgesIgnoringSafeArea(.all)
                
                // Background rhombuses
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        path.move(to: CGPoint(x: -width * 4.7, y: height * 3.6))
                        path.addLine(to: CGPoint(x: width * 0.23, y: height * 0.51))
                        path.addLine(to: CGPoint(x: width * 0.0, y: height * 0.33))
                        path.addLine(to: CGPoint(x: -width * 7.75, y: height * 0.1))
                        path.closeSubpath()
                    }
                    .stroke(Color(hex: "C33BA5"), lineWidth: 5)
                    
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        path.move(to: CGPoint(x: width * 4.9, y: height * 3.5))
                        path.addLine(to: CGPoint(x: width * 1.9, y: height * 0.0))
                        path.addLine(to: CGPoint(x: width * 1.7, y: -height * 0.3))
                        path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.51))
                        path.closeSubpath()
                    }
                    .stroke(Color(hex: "B3CB54"), lineWidth: 5)
                }
                
                VStack(spacing: 20) {
                    // Header section
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(Color(hex: "65558F"))
                                .imageScale(.large)
                        }
                        Spacer()
                    }
                    .padding(.top, 50)
                    
                    Text("SpendiQ")
                        .font(.custom("SFProDisplay-Bold", size: 64))
                        .fontWeight(.bold)
                        .padding(.top, 50)
                        .padding(.bottom, 30)
                    
                    // Form fields
                    formField(title: "Email",
                             text: $viewModel.email,
                             placeholder: "Email...",
                             keyboardType: .emailAddress,
                             maxLength: AuthenticationViewModel.ValidationLimits.maxEmailLength)
                    
                    formField(title: "Password",
                             text: $viewModel.password,
                             placeholder: "Password...",
                             isSecure: true,
                             maxLength: AuthenticationViewModel.ValidationLimits.maxPasswordLength)
                    
                    HStack {
                        Toggle("", isOn: $viewModel.rememberMe)
                            .labelsHidden()
                        Text("Remember me")
                            .font(.custom("SFProText-Regular", size: 14))
                    }
                    
                    // Login button
                    Button(action: {
                        if let validationError = validateLoginForm() {
                            errorMessage = validationError
                            showErrorAlert = true
                            return
                        }
                        viewModel.login(appState: appState)
                    }) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color(hex: "65558F") : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.custom("SFProText-Regular", size: 18))
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 20)
                    

                    // Face ID button
                    if canUseBiometrics && hasSavedCredentials {
                        Button(action: {
                            viewModel.loginWithFaceID(appState: appState)
                        }) {
                            HStack {
                                Image(systemName: "faceid")
                                    .foregroundColor(.white)
                                Text("Log in with Face ID")
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "65558F"))
                            .cornerRadius(10)
                            .font(.custom("SFProText-Regular", size: 18))
                        }
                        .disabled(viewModel.isLoading)
                        .overlay {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }
                    
                    // Forgot password button
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot your ID or password?")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    .padding(.top, 10)
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.custom("SFProText-Regular", size: 14))
                    }
                    
                    Spacer()
                    
                    // Footer
                    HStack {
                        Button(action: {
                            showPrivacy = true
                        }) {
                            Text("Privacy")
                                .font(.custom("SFProText-Regular", size: 14))
                                .foregroundColor(Color(hex: "C33BA5"))
                        }
                        Text("|")
                            .foregroundColor(Color(hex: "65558F"))
                        Button(action: {
                            showHelp = true
                        }) {
                            Text("Help")
                                .font(.custom("SFProText-Regular", size: 14))
                                .foregroundColor(Color(hex: "B3CB54"))
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showPrivacy) {
                PrivacyView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Face ID", isPresented: $showFaceIDError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(faceIDErrorMessage)
            }
            .onAppear {
                viewModel.initializeNetworkMonitoring()
                if !appState.isFirstLogin {
                    checkBiometricAvailability()
                    checkSavedCredentials()
                }
            }
        }
    }
    
    // Agregar esta vista al LoginView, justo después del botón de login
        private var networkStatusView: some View {
            Group {
                if !viewModel.isNetworkAvailable {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                        Text("No internet connection")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(.red)
                    }
                    .padding(.vertical, 8)
                }
                
                if viewModel.errorMessage?.contains("Connection restored") == true {
                    HStack {
                        Image(systemName: "wifi")
                            .foregroundColor(.green)
                        Text(viewModel.errorMessage ?? "")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        

    
    // MARK: - Helper Methods
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        DispatchQueue.main.async {
            let canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            print("Can use biometrics: \(canUseBiometrics)")
            if let error = error {
                print("Biometric error: \(error.localizedDescription)")
            }
            self.canUseBiometrics = canUseBiometrics
            
            // Si podemos usar biométricos, verificamos credenciales guardadas
            if canUseBiometrics {
                self.checkSavedCredentials()
            }
        }
    }
    
    private func checkSavedCredentials() {
        let facade = BiometricAuthenticationFacade()
        facade.hasSavedCredentials()
            .receive(on: DispatchQueue.main)
            .sink { hasCredentials in
                print("Has saved credentials: \(hasCredentials)")
                self.hasSavedCredentials = hasCredentials
            }
            .store(in: &viewModel.cancellables)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
}

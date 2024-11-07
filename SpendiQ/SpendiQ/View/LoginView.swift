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
    @State private var showForgotPassword = false
    @State private var showPrivacy = false
    @State private var showHelp = false
    @State private var canUseBiometrics = false
    @State private var hasSavedCredentials = false
    @State private var showFaceIDError = false
    @State private var faceIDErrorMessage = "Face ID functionality is currently unavailable. Please log in with your email and password."
    
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
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email")
                            .font(.custom("SFProText-Regular", size: 18))
                        TextField("Email...", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Password")
                            .font(.custom("SFProText-Regular", size: 18))
                        SecureField("Password...", text: $viewModel.password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    
                    HStack {
                        Toggle("", isOn: $viewModel.rememberMe)
                            .labelsHidden()
                        Text("Remember me")
                            .font(.custom("SFProText-Regular", size: 14))
                    }
                    
                    Button(action: {
                        viewModel.login(appState: appState)
                    }) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "65558F"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.custom("SFProText-Regular", size: 18))
                    }
                    .padding(.top, 20)
                    
                    Group {
                        if canUseBiometrics && hasSavedCredentials && !appState.isFirstLogin {
                            Button(action: {
                                showFaceIDError = true
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
                            .padding(.top, 10)
                        }
                    }
                    
                    Button(action: {
                        showForgotPassword = true
                    }) {
                        Text("Forgot your ID or password?")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    .padding(.top, 10)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.custom("SFProText-Regular", size: 14))
                    }
                    
                    Spacer()
                    
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
            .alert("Face ID", isPresented: $showFaceIDError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(faceIDErrorMessage)
            }
            .onAppear {
                // Solo verificamos biométricos si no es el primer login
                if !appState.isFirstLogin {
                    checkBiometricAvailability()
                    checkSavedCredentials()
                }
            }
        }
    }
    
    private func checkBiometricAvailability() {
        print("Checking biometric availability")
        let context = LAContext()
        var error: NSError?
        
        DispatchQueue.main.async {
            canUseBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            print("Face ID available: \(canUseBiometrics)")
            if let error = error {
                print("Face ID error: \(error.localizedDescription)")
                canUseBiometrics = false
            }
        }
    }
    
    private func checkSavedCredentials() {
        print("Checking for saved credentials")
        let facade = BiometricAuthenticationFacade()
        facade.hasSavedCredentials()
            .receive(on: DispatchQueue.main)
            .sink { hasCredentials in
                print("Has saved credentials check result: \(hasCredentials)")
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

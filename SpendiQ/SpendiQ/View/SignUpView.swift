//
//  SignUpView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var agreeToTerms = false
    @State private var showTermsAndConditions = false
    
    var body: some View {
        ZStack {
            Color(hex: "FFFFFF").edgesIgnoringSafeArea(.all)
            
            // Background rhombuses
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: -width * 0.7, y: height * 1.6))
                    path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.9))
                    path.addLine(to: CGPoint(x: width * 0.0, y: height * 0.6))
                    path.addLine(to: CGPoint(x: -width * 1.0, y: height * 1.9))
                    path.closeSubpath()
                }
                .stroke(Color(hex: "C33BA5"), lineWidth: 5)
                
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    path.move(to: CGPoint(x: width * 4.0, y: height * 0.7))
                    path.addLine(to: CGPoint(x: width * 1.4, y: height * 0.0))
                    path.addLine(to: CGPoint(x: width * 1.1, y: -height * 0.3))
                    path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.13))
                    path.closeSubpath()
                }
                .stroke(Color(hex: "B3CB54"), lineWidth: 5)
            }
            
            VStack(alignment: .leading, spacing: 25) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    Text("Create Free Account")
                        .font(.custom("SFProDisplay-Bold", size: 32))
                        .fontWeight(.bold)
                }
                .padding(.top, 50)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("First & Last Name")
                        .font(.custom("SFProText-Regular", size: 18))
                    TextField("Enter your name...", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color(hex: "65558F"))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email Address")
                        .font(.custom("SFProText-Regular", size: 18))
                    TextField("you@example.com", text: $viewModel.email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(Color(hex: "65558F"))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Create Password")
                        .font(.custom("SFProText-Regular", size: 18))
                    SecureField("Create a secure password...", text: $viewModel.password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                HStack {
                    Toggle("", isOn: $agreeToTerms)
                        .labelsHidden()
                    Text("I agree with the")
                        .font(.custom("SFProText-Regular", size: 18))
                    Button(action: {
                        showTermsAndConditions = true
                    }) {
                        Text("Terms & Conditions")
                            .foregroundColor(Color(hex: "C33BA5"))
                            .font(.custom("SFProText-Regular", size: 15))
                    }
                }
                
                Button(action: {
                    if agreeToTerms {
                        viewModel.signUp(appState: appState)
                    } else {
                        viewModel.errorMessage = "Please agree to the Terms & Conditions"
                    }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "65558F"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.custom("SFProText-Regular", size: 18))
                }
                .padding(.top, 20)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.custom("SFProText-Regular", size: 14))
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showTermsAndConditions) {
            TermsAndConditionsView()
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AppState())
    }
}

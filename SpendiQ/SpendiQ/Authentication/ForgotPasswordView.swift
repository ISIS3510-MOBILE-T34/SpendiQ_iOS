//
//  ForgotPasswordView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 01/10/24.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var verificationCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isCodeSent = false
    @State private var isCodeVerified = false
    
    var body: some View {
        ZStack {
            Color(hex: "FFFFFF").edgesIgnoringSafeArea(.all)
            
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
                    .padding(.bottom, 10)
                
                Text("Forgot Password")
                    .font(.custom("SFProText-Regular", size: 28))
                    .foregroundColor(Color(hex: "65558F"))
                    .padding(.bottom, 30)
                
                if !isCodeSent {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter your email")
                            .font(.custom("SFProText-Regular", size: 14))
                        TextField("Email...", text: $viewModel.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    
                    Button(action: {
                        viewModel.resetPassword()
                        withAnimation {
                            isCodeSent = true
                        }
                    }) {
                        Text("Send Code")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "65558F"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.custom("SFProText-Regular", size: 18))
                    }
                    .padding(.top, 20)
                } else if !isCodeVerified {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enter verification code")
                            .font(.custom("SFProText-Regular", size: 14))
                        TextField("Verification Code...", text: $verificationCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    
                    Button(action: {
                        viewModel.verifyResetCode(verificationCode)
                        withAnimation {
                            isCodeVerified = true
                        }
                    }) {
                        Text("Verify Code")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "65558F"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.custom("SFProText-Regular", size: 18))
                    }
                    .padding(.top, 20)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("New Password")
                            .font(.custom("SFProText-Regular", size: 14))
                        SecureField("New Password...", text: $newPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(Color(hex: "65558F"))
                        
                        Text("Confirm Password")
                            .font(.custom("SFProText-Regular", size: 14))
                        SecureField("Confirm Password...", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    
                    Button(action: {
                        if newPassword == confirmPassword {
                            viewModel.confirmPasswordReset(code: verificationCode, newPassword: newPassword)
                        } else {
                            viewModel.errorMessage = "Passwords do not match"
                        }
                    }) {
                        Text("Reset Password")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "65558F"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.custom("SFProText-Regular", size: 18))
                    }
                    .padding(.top, 20)
                }
                
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
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}

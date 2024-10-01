//
//  LoginView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    
    var body: some View {
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
                    .padding(.bottom, 30)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Email")
                        .font(.custom("SFProText-Regular", size: 14))
                    TextField("Email...", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(Color(hex: "65558F"))
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Password")
                        .font(.custom("SFProText-Regular", size: 14))
                    SecureField("Password...", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color(hex: "65558F"))
                }
                
                HStack {
                    Toggle("", isOn: $rememberMe)
                        .labelsHidden()
                    Text("Remember me")
                        .font(.custom("SFProText-Regular", size: 14))
                }
                
                Button(action: {
                    // TODO: Implement login action
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
                
                HStack {
                    Spacer()
                    Button(action: {
                        // TODO: Implement forgot password action
                    }) {
                        Text("Forgot your ID or password?")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button(action: {
                        // TODO: Implement privacy action
                    }) {
                        Text("Privacy")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(Color(hex: "C33BA5"))
                    }
                    Text("|")
                        .foregroundColor(Color(hex: "65558F"))
                    Button(action: {
                        // TODO: Implement help action
                    }) {
                        Text("Help")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(Color(hex: "B3CB54"))
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 40)
        }
        .navigationBarHidden(true)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

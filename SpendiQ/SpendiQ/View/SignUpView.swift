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
    @State private var birthDate = Date()
    @State private var showSMSVerificationView = false  // Correct property

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    private let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/M/yyyy"
        return formatter
    }()

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
                    Text("First Name")
                        .font(.custom("SFProText-Regular", size: 18))
                    TextField("Enter your first name...", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color(hex: "65558F"))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Last Name")
                        .font(.custom("SFProText-Regular", size: 18))
                    TextField("Enter your last name...", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(Color(hex: "65558F"))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Phone Number")
                        .font(.custom("SFProText-Regular", size: 18))
                    Text("- Country Code + number")
                        .font(.custom("SFProText-Regular", size: 14))
                    Text("- Example: 573118977713")
                        .font(.custom("SFProText-Regular", size: 14))
                    TextField("Enter your phone number...", text: $viewModel.phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Birth Date")
                        .font(.custom("SFProText-Regular", size: 18))
                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(DefaultDatePickerStyle())
                        .onChange(of: birthDate) { newValue in
                            viewModel.birthDate = birthDateFormatter.string(from: newValue)
                        }
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
                        viewModel.fullName = firstName + " " + lastName
                        viewModel.birthDate = birthDateFormatter.string(from: birthDate)
                        viewModel.signUp(appState: appState)
                        self.showSMSVerificationView = true  // Corrected line
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
        .sheet(isPresented: $showSMSVerificationView) {
            SMSVerificationView()
                .environmentObject(appState)
                .environmentObject(viewModel)
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AppState())
    }
}

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
    
    // MARK: - State Variables
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var agreeToTerms = false
    @State private var showTermsAndConditions = false
    @State private var birthDate = Date()
    @State private var showSMSVerificationView = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    // MARK: - Formatters
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
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !viewModel.phoneNumber.isEmpty &&
        !viewModel.email.isEmpty &&
        !viewModel.password.isEmpty &&
        agreeToTerms &&
        viewModel.validateAge(birthDate: birthDate)
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "65558F"))
                    }
                    Text("Create Free Account")
                        .font(.custom("SFProDisplay-Bold", size: 32))
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.top, 20)
                
                // Form Fields
                Group {
                    formField(title: "First Name",
                             text: $firstName,
                             placeholder: "Enter your first name...",
                             maxLength: AuthenticationViewModel.ValidationLimits.maxNameLength)
                    
                    formField(title: "Last Name",
                             text: $lastName,
                             placeholder: "Enter your last name...",
                             maxLength: AuthenticationViewModel.ValidationLimits.maxNameLength)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Phone Number")
                            .font(.custom("SFProText-Regular", size: 18))
                        Text("Format: Country Code + Number (e.g., 573118977713)")
                            .font(.custom("SFProText-Regular", size: 14))
                            .foregroundColor(.gray)
                        formField(title: "",
                                text: $viewModel.phoneNumber,
                                placeholder: "Enter your phone number...",
                                keyboardType: .phonePad,
                                maxLength: AuthenticationViewModel.ValidationLimits.maxPhoneLength)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Birth Date")
                            .font(.custom("SFProText-Regular", size: 18))
                        DatePicker("", selection: $birthDate,
                                 in: Calendar.current.date(byAdding: .year, value: -120, to: Date())!...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                                 displayedComponents: .date)
                            .datePickerStyle(DefaultDatePickerStyle())
                            .onChange(of: birthDate) { newValue in
                                viewModel.birthDate = birthDateFormatter.string(from: newValue)
                            }
                    }
                    
                    formField(title: "Email Address",
                             text: $viewModel.email,
                             placeholder: "you@example.com",
                             keyboardType: .emailAddress,
                             maxLength: AuthenticationViewModel.ValidationLimits.maxEmailLength)
                    
                    formField(title: "Create Password",
                             text: $viewModel.password,
                             placeholder: "Create a secure password...",
                             isSecure: true,
                             maxLength: AuthenticationViewModel.ValidationLimits.maxPasswordLength)
                }
                
                // Terms and Conditions
                HStack {
                    Toggle("", isOn: $agreeToTerms)
                        .labelsHidden()
                    Text("I agree with the")
                        .font(.custom("SFProText-Regular", size: 18))
                    Button(action: { showTermsAndConditions = true }) {
                        Text("Terms & Conditions")
                            .foregroundColor(Color(hex: "C33BA5"))
                            .font(.custom("SFProText-Regular", size: 15))
                    }
                }
                
                // Sign Up Button
                Button(action: {
                    if let validationError = viewModel.validateInputs(firstName: firstName, lastName: lastName) {
                        errorMessage = validationError
                        showErrorAlert = true
                        return
                    }
                    
                    if !viewModel.validateAge(birthDate: birthDate) {
                        errorMessage = "You must be between \(AuthenticationViewModel.ValidationLimits.minAge) and \(AuthenticationViewModel.ValidationLimits.maxAge) years old"
                        showErrorAlert = true
                        return
                    }
                    
                    viewModel.fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
                    viewModel.birthDate = birthDateFormatter.string(from: birthDate)
                    viewModel.signUp(appState: appState)
                    showSMSVerificationView = true
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color(hex: "65558F") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.custom("SFProText-Regular", size: 18))
                }
                .disabled(!isFormValid)
                .padding(.top, 20)
            }
            .padding(.horizontal, 40)
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
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

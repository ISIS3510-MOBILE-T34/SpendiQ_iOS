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
    @FocusState private var focusedField: Field?
    
    
    // MARK: - State Variables
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var agreeToTerms = false
    @State private var showTermsAndConditions = false
    @State private var birthDate = Date()
    @State private var showSMSVerificationView = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showNetworkAlert = false
    
    // MARK: - Enums
    enum Field: Hashable {
        case firstName
        case lastName
        case phone
        case email
        case password
    }
    
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
        viewModel.validateAge(birthDate: birthDate) &&
        viewModel.validateEmail(viewModel.email)
    }
    
    // MARK: - View Components
    private func formField(title: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default, isSecure: Bool = false, maxLength: Int, field: Field? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.custom("SFProText-Regular", size: 18))
            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: field)
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
                    .focused($focusedField, equals: field)
                    .onChange(of: text.wrappedValue) { newValue in
                        if newValue.count > maxLength {
                            text.wrappedValue = String(newValue.prefix(maxLength))
                        }
                    }
            }
            
            // Agregar botón "Done" solo para el campo de teléfono
            if keyboardType == .phonePad {
                HStack {
                    Spacer()
                    Button("Done") {
                        focusedField = nil // Cierra el teclado
                    }
                    .foregroundColor(Color(hex: "65558F"))
                    .padding(.top, 5)
                }
            }
        }
    }
    
    private var networkStatusView: some View {
        Group {
            if !viewModel.isConnected {
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
                                  maxLength: AuthenticationViewModel.ValidationLimits.maxPhoneLength,
                                  field: .phone)
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
                
                // Network Status View
                networkStatusView
                
                // Sign Up Button
                Button(action: {
                    if let validationError = viewModel.validateSignUpForm(
                        firstName: firstName,
                        lastName: lastName,
                        birthDate: birthDate
                    ) {
                        errorMessage = validationError
                        showErrorAlert = true
                        return
                    }
                    
                    viewModel.fullName = "\(firstName.trimmingCharacters(in: .whitespaces)) \(lastName.trimmingCharacters(in: .whitespaces))"
                    viewModel.birthDate = birthDateFormatter.string(from: birthDate)
                    
                    if viewModel.signUp(appState: appState) {
                        showSMSVerificationView = true
                    }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid && viewModel.isConnected ? Color(hex: "65558F") : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.custom("SFProText-Regular", size: 18))
                }
                .disabled(!isFormValid || !viewModel.isConnected)
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
        .onAppear {
            viewModel.initializeNetworkMonitoring()
        }
        .onChange(of: viewModel.isConnected) { isConnected in
            if isConnected {
                errorMessage = "Connection restored. You can proceed with sign up."
            } else {
                errorMessage = "No internet connection. Please check your connection."
            }
            showErrorAlert = true
        }
    }
}
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AppState())
    }
}

//
//  EditProfileView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 26/10/24.
//
import SwiftUI
import FirebaseFirestore
struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: UserViewModel
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    init(viewModel: UserViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _fullName = State(initialValue: viewModel.user?.fullName ?? "")
        _phoneNumber = State(initialValue: viewModel.user?.phoneNumber ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Full Name")
                        .font(.custom("SFProText-Regular", size: 18))
                    TextField("Enter your name...", text: $fullName)
                        .textFieldStyle(CustomTextFieldStyle())
                        .foregroundColor(Color(hex: "65558F"))
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Phone Number")
                        .font(.custom("SFProText-Regular", size: 18))
                    TextField("Enter your phone number...", text: $phoneNumber)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.phonePad)
                        .foregroundColor(Color(hex: "65558F"))
                }
                .padding(.horizontal)
                
                Button(action: updateProfile) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "65558F"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.custom("SFProText-Regular", size: 18))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(Color(hex: "65558F"))
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(isSuccess ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func updateProfile() {
        guard let user = viewModel.user else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        userRef.updateData([
            "fullName": fullName,
            "phoneNumber": phoneNumber
        ]) { error in
            if let error = error {
                self.alertMessage = "Error updating profile: \(error.localizedDescription)"
                self.isSuccess = false
            } else {
                self.alertMessage = "Profile updated successfully"
                self.isSuccess = true
            }
            self.showAlert = true
        }
    }
}
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(viewModel: UserViewModel(mockData: true))
    }
}

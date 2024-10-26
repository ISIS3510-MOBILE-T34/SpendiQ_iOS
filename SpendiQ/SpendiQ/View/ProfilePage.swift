//
//  ProfilePage.swift
//  SpendiQ
//
//  Created by Juan Salguero and Daniel Clavijo on 27/09/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfilePage: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: UserViewModel = UserViewModel()
    @State private var showDeleteAlert = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                if let user = viewModel.user {
                    HStack(spacing: 16) {
                        // Iniciales del usuario en círculo
                        Circle()
                            .fill(Color(hex: "65558F"))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text(getInitials(from: user.fullName))
                                    .foregroundColor(.white)
                                    .font(.system(size: 24, weight: .medium))
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Secciones
                VStack(spacing: 0) {
                    // GENERAL Section
                    SectionHeader(title: "GENERAL")
                    
                    ProfileRow(
                        icon: "info.circle",
                        iconColor: .blue,
                        text: "Version",
                        value: "1.0.0"
                    )
                    
                    // ACCOUNT Section
                    SectionHeader(title: "ACCOUNT")
                    
                    Button(action: { showEditProfile = true }) {
                         ProfileRow(
                             icon: "person.circle",
                             iconColor: Color(hex: "65558F"),
                             text: "Edit Profile"
                         )
                     }
                    
                    Button(action: { handleSignOut() }) {
                        ProfileRow(
                            icon: "arrow.right.square",
                            iconColor: Color(hex: "65558F"),
                            text: "Sign Out",
                            showDivider: false
                        )
                    }
                    
                    Button(action: { showDeleteAlert = true }) {
                        ProfileRow(
                            icon: "xmark.circle",
                            iconColor: .red,
                            text: "Delete Account",
                            showDivider: false
                        )
                    }
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            
            .padding(.top)
            .navigationBarHidden(true)
            .background(Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all))
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { handleDeleteAccount() }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        return components.compactMap { $0.first }.map(String.init).joined()
    }
    
    private func handleSignOut() {
        do {
            try Auth.auth().signOut()
            appState.isAuthenticated = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    private func handleDeleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        // 1. Primero eliminar datos de Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { error in
            if let error = error {
                print("Error deleting user data: \(error)")
                return
            }
            
            // 2. Luego eliminar la cuenta de autenticación
            user.delete { error in
                if let error = error {
                    print("Error deleting account: \(error)")
                    return
                }
                
                // 3. Actualizar el estado de la app
                DispatchQueue.main.async {
                    appState.isAuthenticated = false
                }
            }
        }
    }
}

// Componentes auxiliares
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(hex: "F5F5F5"))
    }
}

struct ProfileRow: View {
    let icon: String
    var iconColor: Color
    let text: String
    var value: String? = nil
    var showDivider: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                Text(text)
                    .foregroundColor(Color(hex: "333333"))
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .foregroundColor(.gray)
                }
                
                if value == nil {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
            .padding()
            
            if showDivider {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

// Preview
struct ProfilePage_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePage()
            .environmentObject(AppState())
    }
}

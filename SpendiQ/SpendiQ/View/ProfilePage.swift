//
//  ProfilePage.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 26/10/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfilePage: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: UserViewModel
    @Binding var selectedTab: String
    @State private var showDeleteAlert = false
    @State private var showEditProfile = false
    @State private var showTransactionsMap = false

    var body: some View {
        VStack(spacing: 24) {
            // Back Button and Profile Header
            HStack {
                Button(action: {
                    // Navigate back to the previous tab (e.g., "Home")
                    selectedTab = "Home" // Change to your desired tab
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.leading)
                
                Spacer()
            }
            .padding(.top)
            
            if let user = viewModel.user {
                HStack(spacing: 16) {
                    // User's Profile Picture or Initials
                    if user.profilePicture.trimmingCharacters(in: .whitespaces).isEmpty {
                        initialsView(from: user.fullName)
                            .frame(width: 60, height: 60)
                    } else {
                        AsyncImage(url: URL(string: user.profilePicture)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .empty:
                                ProgressView()
                            case .failure:
                                initialsView(from: user.fullName)
                            @unknown default:
                                initialsView(from: user.fullName)
                            }
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    }
                    
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
            
            // Sections
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
                
                NavigationLink(destination: TransactionsMapView()) {
                    ProfileRow(
                        icon: "map",
                        iconColor: Color(hex: "65558F"),
                        text: "My Transactions Map"
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
        .background(Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all))
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { handleDeleteAccount() }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
    }
    
    // Helper function to get initials from full name
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        return components.compactMap { $0.first }.map(String.init).joined()
    }
    
    // View to display initials with colored background
    private func initialsView(from name: String) -> some View {
        let initials = getInitials(from: name)
        return Circle()
            .fill(Color.blue) // Customize color as needed
            .overlay(
                Text(initials)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            )
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
        
        // 1. First, delete data from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { error in
            if let error = error {
                print("Error deleting user data: \(error)")
                return
            }
            
            // 2. Then delete the authentication account
            user.delete { error in
                if let error = error {
                    print("Error deleting account: \(error)")
                    return
                }
                
                // 3. Update the app state
                DispatchQueue.main.async {
                    appState.isAuthenticated = false
                }
            }
        }
    }
}

// Auxiliary Components
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
        // Provide a constant binding for preview purposes
        ProfilePage(selectedTab: .constant("Profile"))
            .environmentObject(AppState())
            .environmentObject(UserViewModel(mockData: true))
    }
}

//
//  UserViewModel.swift
//  SpendiQ
//
//  Created by Alonso Hernandez (Fai) on 18/10/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var isLoading: Bool = true
    
    init(mockData: Bool = false) {
        if mockData {
            // Use mock data for preview or local testing
            self.user = User(
                id: "1",
                name: "Alonso Hernandez",
                email: "alonso@example.com",
                profilePicture: "https://avatars.githubusercontent.com/u/98569502?v=4" // Example URL for the profile picture
            )
            self.isLoading = false
        } else {
            fetchUserFromFirebase()
        }
    }
    
    func fetchUserFromFirebase() {
        guard let currentUser = Auth.auth().currentUser else {
            self.isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user: \(error)")
                    self.isLoading = false
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self.isLoading = false
                    return
                }
                
                self.user = User(
                    id: snapshot?.documentID ?? "",
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? currentUser.email ?? "",
                    profilePicture: data["profilePicture"] as? String ?? ""
                )
                self.isLoading = false
            }
    }
}

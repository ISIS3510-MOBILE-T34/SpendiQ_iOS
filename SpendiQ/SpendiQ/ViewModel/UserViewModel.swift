//
//  UserViewModel.swift
//  SpendiQ
//
//  Created by Alonso Hernandez (Fai) on 18/10/24.
//

import SwiftUI
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var user: User? = nil
    @Published var isLoading: Bool = true
    
    init(mockData: Bool = false) {
        if mockData {
            // Use mock data for preview or local testing
            self.user = User(
                id: "1",
                name: "Alonso Hernandez",
                profilePicture: "https://avatars.githubusercontent.com/u/98569502?v=4" // Example URL for the profile picture
            )
            self.isLoading = false
        } else {
            fetchUserFromFirebase()
        }
    }
    
    func fetchUserFromFirebase() {
        let db = Firestore.firestore()
        db.collection("users").document("user_id") // Replace "user_id" with actual user ID
            .getDocument { snapshot, error in
                if let error = error {
                    print("Error fetching user: \(error)")
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                
                self.user = User(
                    id: snapshot?.documentID ?? "",
                    name: data["name"] as? String ?? "",
                    profilePicture: data["profilePicture"] as? String ?? ""
                )
                self.isLoading = false
            }
    }
}

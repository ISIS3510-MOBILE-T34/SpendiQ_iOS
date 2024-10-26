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
                fullName: "Alonso Hernandez",
                email: "alonso@example.com",
                phoneNumber: "+1234567890",
                birthDate: "01/01/1990",
                registrationDate: Date(),
                verifiedPhoneNumber: false  // Updated field
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
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching user: \(error)")
                    self.isLoading = false
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self.isLoading = false
                    return
                }
                
                let registrationDateString = data["registrationDate"] as? String ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "es_ES")
                dateFormatter.dateFormat = "d 'de' MMMM 'de' yyyy, h:mm:ss'p.m.' z"
                let registrationDate = dateFormatter.date(from: registrationDateString) ?? Date()
                
                self.user = User(
                    id: snapshot?.documentID ?? "",
                    fullName: data["fullName"] as? String ?? "",
                    email: data["email"] as? String ?? currentUser.email ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    birthDate: data["birthDate"] as? String ?? "",
                    registrationDate: registrationDate,
                    verifiedPhoneNumber: data["verifiedPhoneNumber"] as? Bool ?? false  // Updated field
                )
                self.isLoading = false
            }
    }
}

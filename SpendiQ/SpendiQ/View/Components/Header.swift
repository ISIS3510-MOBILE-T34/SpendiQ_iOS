import SwiftUI

struct Header: View {
    @ObservedObject var viewModel: UserViewModel
    @Binding var selectedTab: String

    var body: some View {
        HStack {
            // Simplified date format
            Text(formattedDate())
                .font(.custom("SFProText-Regular", size: 18))
                .fontWeight(.regular)
                .padding(.leading, 16)
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                Button(action: {
                    // Change the selected tab to "Profile"
                    selectedTab = "Profile"
                }) {
                    // Check if profilePicture is not empty
                    if !user.profilePicture.trimmingCharacters(in: .whitespaces).isEmpty,
                       let url = URL(string: user.profilePicture) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure(_), .empty:
                                initialsView(from: user.fullName)
                            @unknown default:
                                initialsView(from: user.fullName)
                            }
                        }
                    } else {
                        // Show initials if no profile picture
                        initialsView(from: user.fullName)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .padding(.trailing, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 55)
        .background(Color.white)
        .shadow(radius: 1)
    }
    
    // Helper function to format date
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    // Helper function to get initials from full name
    func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.prefix(2).joined()
    }
    
    // View to display initials with colored background
    @ViewBuilder
    func initialsView(from name: String) -> some View {
        let initials = getInitials(from: name)
        Circle()
            .fill(Color.blue) // Choose desired background color
            .overlay(
                Text(initials)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            )
    }
}

struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header(viewModel: UserViewModel(mockData: true), selectedTab: .constant("Home"))
    }
}

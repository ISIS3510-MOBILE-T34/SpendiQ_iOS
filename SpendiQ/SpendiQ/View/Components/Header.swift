//
//  Header.swift
//  SpendiQ
//
//  Created by Fai on 18/10/24.
//

import SwiftUI

struct Header: View {
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        HStack {
            // Today's date with adjusted font
            Text(todayDate())
                .font(.custom("SFProText-Regular", size: 18))
                .fontWeight(.regular) // Adjust font weight to be less bold
                .padding(.leading, 16)
            
            Spacer()
            
            // User's profile picture, clickable to navigate to ProfilePage()
            if viewModel.isLoading {
                ProgressView() // Placeholder while loading
            } else if let user = viewModel.user {
                NavigationLink(destination: ProfilePage()) {
                    AsyncImage(url: URL(string: user.profilePicture)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 55)
        .background(Color.white)
        .shadow(radius: 3)
    }
    
    // Helper function to format today's date
    func todayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header(viewModel: UserViewModel(mockData: true)) // Using mock data for preview
    }
}


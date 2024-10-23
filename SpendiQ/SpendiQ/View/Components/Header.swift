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
            Text(todayDate())
                .font(.custom("SFProText-Regular", size: 18))
                .fontWeight(.regular)
                .padding(.leading, 16)
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                NavigationLink(destination: ProfilePage()) {
                    // Círculo simple como placeholder para la futura foto de perfil
                    Circle()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 55)
        .background(Color.white)
        .shadow(radius: 3)
    }
    
    func todayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header(viewModel: UserViewModel(mockData: true))
    }
}

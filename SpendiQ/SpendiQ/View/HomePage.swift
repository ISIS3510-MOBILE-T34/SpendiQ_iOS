//
//  HomePage.swift
//  SpendiQ
//
//  Created by Juan Salguero on 27/09/24.
//

import SwiftUI

struct HomePage: View {
    @State private var currentIndex: Int = 0 // Controla el índice del cuadro actual
    @State private var CurrentBalance: Int = 504277
    var body: some View {
        VStack {
            ScrollView {
                Spacer()
                    .frame(height: 53)
                
                Text("Total Balance")
                    .font(.custom("SF Pro", size: 19))
                    .fontWeight(.regular)
                
                Spacer()
                    .frame(height: 6)
                
                
                Text("$ \(CurrentBalance)")
                    .font(.custom("SF Pro", size: 32))
                    .foregroundColor(.primarySpendiq)
                    .fontWeight(.bold)
                
                GraphBox(currentIndex: $currentIndex)
                    .frame(height: 264)
                    .padding(.bottom,12)
                
                Divider()
                    .frame(width: 361)
                
                Text("Movements")
                    .font(.custom("SF Pro", size: 19))
                    .fontWeight(.regular)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
    }
}

#Preview {
    HomePage()
}

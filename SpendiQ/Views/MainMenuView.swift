//
//  MainMenuView.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import SwiftUI

struct MainMenuView: View {
    @StateObject var viewModel = SpecialOffersViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Header placeholder
                Color.clear.frame(height: 50)
                
                // Main content
                ScrollView {
                    // Other main menu content
                    SpecialOffersAlertView(viewModel: viewModel)
                }
                
                // Footer placeholder
                Color.clear.frame(height: 50)
            }
            .navigationBarTitle("Main Menu", displayMode: .inline)
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}

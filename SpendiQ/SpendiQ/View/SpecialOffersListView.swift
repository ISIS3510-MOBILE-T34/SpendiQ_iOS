//
//  SpecialOffersListView.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import SwiftUI

struct SpecialOffersListView: View {
    @ObservedObject var viewModel: SpecialOffersViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header placeholder
            Color.clear.frame(height: 50)
            
            // Main content
            ScrollView {
                VStack {
                    ForEach(viewModel.offers, id: \.id) { offer in
                        NavigationLink(destination: OfferDetailView(offer: offer)) {
                            OfferBubbleView(offer: offer)
                        }
                    }
                }
                .padding()
            }
            
            // Footer placeholder
            Color.clear.frame(height: 50)
        }
        .navigationBarTitle("Special Offers", displayMode: .inline)
    }
}

struct SpecialOffersListView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SpecialOffersViewModel()
        SpecialOffersListView(viewModel: viewModel)
    }
}

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
        ZStack {
            VStack(spacing: 0) {
                // Header placeholder
                Color.clear.frame(height: 50)
                
                if viewModel.isLoading {
                    // Loading state
                    ProgressView("Loading offers...")
                        .padding()
                } else if let error = viewModel.error {
                    // Error state
                    VStack {
                        Text("Error loading offers")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("Retry") {
                            viewModel.refreshData()
                        }
                        .padding()
                    }
                } else {
                    // Content
                    ScrollView {
                        VStack {
                            ForEach(viewModel.offers) { offer in
                                NavigationLink(destination: OfferDetailView(offer: offer)) {
                                    OfferBubbleView(offer: offer)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.refreshData()
                    }
                }
                
                // Footer placeholder
                Color.clear.frame(height: 50)
            }
        }
        .navigationBarTitle("Special Offers", displayMode: .inline)
    }
}

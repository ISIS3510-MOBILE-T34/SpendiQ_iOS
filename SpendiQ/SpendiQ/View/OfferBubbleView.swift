//
//  OfferBubbleView.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 30/09/24.
//

import SwiftUI

struct OfferBubbleView: View {
    @ObservedObject var viewModel = OfferViewModel(mockData: false)

    var body: some View {
        NavigationView { // Wrap the entire view in NavigationView
            VStack {
                Text("Special Sales in your Area")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)

                Text("Based on the shops where you have purchased before, we think these sales near to your location may interest you. Touch one for more information!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)

                if viewModel.isLoading {
                    ProgressView("Loading offers...")
                        .padding(.top, 50)
                } else {
                    ScrollView {
                        ForEach(viewModel.offers) { offer in
                            OfferCardView(offer: offer)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                }
            }

        }
    }
}

struct OfferBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        OfferBubbleView(viewModel: OfferViewModel(mockData: false))
        }
}


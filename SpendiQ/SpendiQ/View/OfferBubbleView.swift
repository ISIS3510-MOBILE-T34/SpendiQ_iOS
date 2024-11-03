//
//  OfferBubbleView.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 30/09/24.
//

import SwiftUI

struct OfferBubbleView: View {

    @ObservedObject var viewModel: OfferViewModel
    @State private var selectedOffer: Offer?

    var body: some View {
        VStack {
            Text("Special Sales in your Area")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .padding(.bottom, 10)

            Text("Based on the shops where you have purchased before, we think these sales near to your location may interest you. Touch one for more information!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)

            if viewModel.offers.isEmpty && viewModel.showNoOffersMessage {
                // Display "No offers found" message after 6 seconds
                VStack {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    Text("No stores were found near you, please try in another area.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                }
                .padding(.top, 50)
            } else if !viewModel.offers.isEmpty {
                // Display offers immediately when found
                ScrollView {
                    ForEach(viewModel.offers) { offer in
                        Button(action: {
                            selectedOffer = offer
                        }) {
                            OfferCardView(offer: offer)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // No loading indicator or blank screen
                // Optionally, you can show a placeholder or nothing
                EmptyView()
            }
        }
        .background(
            Group {
                if let offer = selectedOffer {
                    NavigationLink(
                        destination: OfferDetailView(offer: offer),
                        isActive: Binding<Bool>(
                            get: { selectedOffer != nil },
                            set: { _ in selectedOffer = nil }
                        ),
                        label: { EmptyView() }
                    )
                }
            }
        )
        .onAppear {
            // Ensure no test notification triggers are present
            // If there's any residual test code, remove or comment it out here
        }
    }
}

struct OfferBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        let locationManager = LocationManager()
        let offerViewModel = OfferViewModel(locationManager: locationManager, mockData: false)
        OfferBubbleView(viewModel: offerViewModel)
    }
}

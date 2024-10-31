//
//  OfferBubbleView.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 30/09/24.
//

import SwiftUI

struct OfferBubbleView: View {

    @ObservedObject var viewModel = OfferViewModel(mockData: false)
    @State private var selectedOffer: Offer?

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
                } else if viewModel.locationAccessDenied {
                    VStack {
                        Image(systemName: "location.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        Text("Location access denied.")
                            .font(.headline)
                            .padding(.top, 10)
                        Text("Please enable location services in Settings to see offers near you.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 5)
                        Button(action: {
                            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(appSettings)
                            }
                        }) {
                            Text("Open Settings")
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                    .padding(.top, 50)
                } else if viewModel.offers.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        Text("No offers could be found near you.")
                            .font(.headline)
                            .padding(.top, 10)
                    }
                    .padding(.top, 50)
                } else {
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
                }
            }
            .background(
                Group {
                    if let offer = selectedOffer ?? viewModel.offers.first {
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
                // Listen for notification to show offers list
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowOffersList"), object: nil, queue: .main) { notification in
                    // Optionally, you can use the shopId from notification to filter offers
                    if let shopId = notification.userInfo?["shopId"] as? String, !shopId.isEmpty {
                        // Filter or highlight the specific offer/shop
                    }
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


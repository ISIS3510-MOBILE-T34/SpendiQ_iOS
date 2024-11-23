// Developed by Alonso Hernandez

import SwiftUI

struct OfferBubbleView: View {
    @ObservedObject var viewModel: OfferViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var selectedOffer: Offer?
    @ObservedObject private var reachability = ReachabilityManager.shared // Sprint 3: Singleton for CoreData Cache

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

            if !reachability.isConnected {
                // Sprint 3: Offline Note
                Text("You are offline and won't see updated Offers for now.")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }

            if viewModel.isLoading {
                ProgressView("Loading offers...")
                    .padding()
            } else if viewModel.offers.isEmpty && viewModel.showNoOffersMessage {
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
            } else {
                // Display offers
                ScrollView {
                    ForEach(viewModel.offers) { offer in
                        Button(action: {
                            print("Button clicked for offer ID: \(offer.id ?? "Unknown")")
                            selectedOffer = offer
                            viewModel.incrementViewCount(for: offer) // Increment viewCount
                        }) {
                            OfferCardView(offer: offer, locationManager: locationManager)
                                .padding(.vertical, 8)
                                .cornerRadius(8)
                                .padding(.bottom, offer.featured ? 8 : 0)
                        }
                    }
                }

                .padding(.horizontal)
            }
        }
        .background(
            Group {
                if let offer = selectedOffer {
                    NavigationLink(
                        destination: OfferDetailView(offer: offer, locationManager: locationManager),
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
            viewModel.shouldFetchOnAppear = false
            if reachability.isConnected {
                print("Online: Fetching offers if needed.")
                viewModel.fetchOffers()
            } else {
                print("Offline: Loading cached offers.") // Sprint 3: Cache
                viewModel.loadCachedOffers()
            }
        }
        .onChange(of: reachability.isConnected) { isConnected in
            print("Connectivity changed. Connected: \(isConnected)")
            if isConnected {
                viewModel.fetchOffers()
                print("Sprint 4 - Alonso: Online. Syncing cached viewCounts...")
                viewModel.syncCachedViewCountIncrements()
            } else {
                viewModel.loadCachedOffers() // Sprint 3: Cache Strategy 1 for ECS3
            }
        }
        .animation(.easeInOut, value: reachability.isConnected)
    }
}

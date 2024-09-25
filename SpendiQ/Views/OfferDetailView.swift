//
//  OfferDetailView.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import SwiftUI
import MapKit

struct OfferDetailView: View {
    @StateObject var viewModel: OfferDetailViewModel
    
    init(offer: OfferModel) {
        _viewModel = StateObject(wrappedValue: OfferDetailViewModel(offer: offer))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header placeholder
            Color.clear.frame(height: 50)
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Special Sales in your Area")
                        .font(.title)
                        .bold()
                    
                    HStack {
                        Image(viewModel.offer.logoName)
                            .resizable()
                            .frame(width: 50, height: 50)
                        Text(viewModel.offer.placeName)
                            .font(.title2)
                            .bold()
                    }
                    
                    Map(coordinateRegion: $viewModel.region, annotationItems: [viewModel.offer]) { place in
                        MapMarker(coordinate: place.locationCoordinate)
                    }
                    .frame(width: 361, height: 411)
                    .cornerRadius(15)
                    
                    VStack(alignment: .leading) {
                        Text("Sales")
                            .font(.headline)
                        Text(viewModel.offer.offerDescription)
                            .font(.body)
                    }
                    .frame(width: 361, height: 411)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    Text("Reason: \(viewModel.offer.recommendationReason)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            // Footer placeholder
            Color.clear.frame(height: 50)
        }
        .navigationBarTitle("Offer Details", displayMode: .inline)
    }
}

struct OfferDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let offer = OfferModel(
            id: "1",
            placeName: "McDonald's Parque 93",
            offerDescription: "Get 20% off on all meals!",
            recommendationReason: "you have bought 30 times in the last month",
            logoName: "mcdonalds",
            latitude: 4.676,
            longitude: -74.048
        )
        OfferDetailView(offer: offer)
    }
}

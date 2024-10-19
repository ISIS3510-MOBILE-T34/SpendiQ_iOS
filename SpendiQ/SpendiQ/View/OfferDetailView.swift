//
//  OfferDetailView.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import SwiftUI
import MapKit

struct OfferDetailView: View {
    var offer: Offer
    
    @State private var region: MKCoordinateRegion

    init(offer: Offer) {
        self.offer = offer
        // Set region dynamically based on offer latitude and longitude
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: offer.latitude, longitude: offer.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Special Sales in your Area")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            HStack {
                // Load image from the internet using AsyncImage
                AsyncImage(url: URL(string: offer.shopImage)) { image in
                    image
                        .resizable()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    ProgressView() // Placeholder while the image loads
                }
                
                Text(offer.placeName)
                    .font(.headline)
                    .padding(.leading, 10)
            }
            .padding(.bottom, 10)
            
            Map(coordinateRegion: $region, interactionModes: [.zoom, .pan], showsUserLocation: false)
                .frame(height: 300)
                .cornerRadius(15)
                .padding(.bottom, 20)
            
            Text("Sales")
                .font(.headline)
                .padding(.bottom, 5)
            
            Text(offer.offerDescription)
                .padding(.bottom, 10)
            
            Text("Recommendation: \(offer.recommendationReason)")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
    }
}

struct OfferDetailView_Previews: PreviewProvider {
    static var previews: some View {
        OfferDetailView(offer: Offer(
            id: "1",
            placeName: "McDonald's Parque 93",
            offerDescription: "Get 20% off on all meals!",
            recommendationReason: "You have bought 30 times in the last month",
            shopImage: "https://pbs.twimg.com/profile_images/1798086490502643712/ntN62oCw_400x400.jpg", // Example URL for McDonald's image
            latitude: 4.676, // Example coordinates for the map
            longitude: -74.048,
            distance: 500
        ))
    }
}

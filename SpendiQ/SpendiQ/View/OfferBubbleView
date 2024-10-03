//
//  OfferBubbleView.swift
//  SpendiQ
//
//  Created by Estudiantes on 25/09/24.
//

import SwiftUI

struct OfferBubbleView: View {
    var offer: OfferModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(offer.placeName)
                    .font(.title3)
                    .bold()
                if let distance = offer.distance {
                    Text("\(Int(distance)) meters away")
                        .font(.subheadline)
                }
                Text(offer.offerDescription)
                    .font(.body)
                Text("Recommended because \(offer.recommendationReason)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(offer.logoName)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .padding()
        .frame(width: 361, height: 180)
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.vertical, 11)
    }
}

struct OfferBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        let offer = OfferModel(
            id: "1",
            placeName: "McDonald's Parque 93",
            offerDescription: "Get 20% off on all meals!",
            recommendationReason: "you have bought 30 times in the last month",
            logoName: "mcdonalds",
            latitude: 0.0,
            longitude: 0.0
        )
        OfferBubbleView(offer: offer)
    }
}

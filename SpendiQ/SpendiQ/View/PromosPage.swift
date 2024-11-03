//
//  PromosPage.swift
//  SpendiQ
//
//  Created by Juan Salguero on 27/09/24.
//

import SwiftUI

struct PromosPage: View {
    @ObservedObject var offerViewModel: OfferViewModel

    init(locationManager: LocationManager) {
        self.offerViewModel = OfferViewModel(locationManager: locationManager, mockData: false)
    }

    var body: some View {
        VStack {
            OfferBubbleView(viewModel: offerViewModel)
                .padding()
        }
    }
}

struct PromosPage_Previews: PreviewProvider {
    static var previews: some View {
        let locationManager = LocationManager()
        PromosPage(locationManager: locationManager)
    }
}

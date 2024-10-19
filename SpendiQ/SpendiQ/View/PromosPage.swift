//
//  PromosPage.swift
//  SpendiQ
//
//  Created by Juan Salguero on 27/09/24.
//

import SwiftUI

struct PromosPage: View {
    var body: some View {
        VStack {
            OfferBubbleView(viewModel: OfferViewModel(mockData: false))
                .padding()
        }
    }
}

#Preview {
    PromosPage()
}


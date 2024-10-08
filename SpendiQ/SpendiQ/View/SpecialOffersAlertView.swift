//
//  SpecialOffersAlertView.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import SwiftUI

struct SpecialOffersAlertView: View {
    @ObservedObject var viewModel: SpecialOffersViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Hey! \(viewModel.userName), you are in a zone where your favorite shops have Special Sales")
                .font(.headline)
                .padding(.bottom, 10)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.offers.prefix(5), id: \.id) { offer in
                        Image(offer.logoName)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding()
        .background(
            NavigationLink(
                destination: SpecialOffersListView(viewModel: viewModel),
                label: {
                    EmptyView()
                }
            )
            .opacity(0) // Makes the NavigationLink invisible
        )
    }
}

struct SpecialOffersAlertView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SpecialOffersViewModel()
        SpecialOffersAlertView(viewModel: viewModel)
    }
}

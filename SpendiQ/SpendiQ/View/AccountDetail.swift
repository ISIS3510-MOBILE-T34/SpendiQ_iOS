import SwiftUI

struct AccountDetailView: View {
    var accountName: String

    var body: some View {
        VStack {
            Text("Account: \(accountName)")
                .font(.largeTitle)
                .padding()

            Spacer()
        }
    }
}

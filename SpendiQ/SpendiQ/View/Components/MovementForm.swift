import SwiftUI
import FirebaseCore
import CoreLocation
import MapKit

struct MovementForm: View {
    @ObservedObject var bankAccountViewModel: BankAccountViewModel
    private let locationManager = LocationManager()

    var body: some View {
        EditTransactionForm(
            locationManager: locationManager,
            bankAccountViewModel: bankAccountViewModel,
            transactionViewModel: TransactionViewModel(),
            transaction: nil
        )
    }
}

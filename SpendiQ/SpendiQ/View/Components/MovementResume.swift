import SwiftUI

struct MovementResume: View {
    var transaction: Transaction
    private let locationManager = LocationManager()
    @ObservedObject var viewModel: TransactionViewModel
    @State private var showEditForm = false

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.yellow)
                Text(selectEmoji(for: transaction.transactionType))
                    .font(.largeTitle)
            }
            .padding(.leading, 16)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(transaction.transactionName)
                        .fontWeight(.regular)
                    
                    // Mostrar íconos de anomalía si corresponden
                    if transaction.amountAnomaly {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                    }
                    
                    if transaction.locationAnomaly {
                        Image(systemName: "mappin")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                    }
                }
                
                HStack {
                    Text(viewModel.accounts[transaction.accountId] ?? "Loading...")
                        .fontWeight(.light)
                        .font(.system(size: 14))
                    
                    Divider()
                        .frame(height: 14)
                    
                    Text(formatTime(transaction.dateTime.dateValue()))
                        .fontWeight(.light)
                        .font(.system(size: 14))
                }
            }
            
            Spacer()
            
            if transaction.transactionType == "Expense" {
                Text("-$ \(Int(transaction.amount))")
                    .fontWeight(.medium)
                    .font(.system(size: 16))
                    .foregroundStyle(.red)
            } else {
                Text("+$ \(Int(transaction.amount))")
                    .fontWeight(.medium)
                    .font(.system(size: 16))
                    .foregroundStyle(.primarySpendiq)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showEditForm = true
        }
        .sheet(isPresented: $showEditForm) {
            EditTransactionForm(
                locationManager: locationManager,
                bankAccountViewModel: BankAccountViewModel(),
                transactionViewModel: viewModel,
                transaction: transaction
            )
        }
        .onAppear {
            if viewModel.accounts[transaction.accountId] == nil {
                viewModel.getAccountName(accountID: transaction.accountId)
            }
        }
    }

    func selectEmoji(for transactionType: String) -> String {
        switch transactionType {
        case "Expense":
            return "💰"
        case "Income":
            return "🍾"
        case "Transaction":
            return "🔄"
        default:
            return "❓"
        }
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

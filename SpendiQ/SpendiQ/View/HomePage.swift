import SwiftUI
import FirebaseAuth

struct HomePage: View {
    @EnvironmentObject var appState: AppState
    @State private var CurrentBalance: Int = 0
    @State private var totalIncome: Double = 0
    @State private var totalExpenses: Double = 0
    @ObservedObject private var viewModel = TransactionViewModel()
    @ObservedObject private var bankAccountViewModel = BankAccountViewModel()

    var body: some View {
        VStack {
            ScrollView {
                Spacer()
                    .frame(height: 53)
                
                HStack {
                    Text("Total Balance")
                        .font(.custom("SF Pro", size: 19))
                        .fontWeight(.regular)
                        .padding(.leading,86)
                    
                    Image(systemName: "bell.fill")
                        .padding(.leading,50)
                }
                
                Spacer()
                    .frame(height: 6)
                
                Text("$ \(calculateTotalBalance(), specifier: "%.2f")")
                    .font(.custom("SF Pro", size: 32))
                    .foregroundColor(.primarySpendiq)
                    .fontWeight(.bold)
                
                GraphBox()
                    .frame(height: 264)
                    .padding(.bottom,12)
                
                Divider()
                    .frame(width: 361)
                
                // Sprint 3 - Alonso: Add OverviewView
                OverviewView(
                    totalIncome: totalIncome,
                    totalExpenses: totalExpenses,
                    monthName: DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1]
                )
                .padding(.bottom, 12)
                
                HStack {
                    Text("Movements")
                        .font(.custom("SF Pro", size: 19))
                        .fontWeight(.regular)
                        .padding(.leading)
                    
                    Spacer()
                }
                
                ForEach(viewModel.transactionsByDay.keys.sorted().reversed(), id: \.self) { day in
                    DayResume(viewModel: viewModel, day: day)
                        .padding(.bottom, 0)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onAppear {
                viewModel.getTransactionsForAllAccounts()
                bankAccountViewModel.getBankAccounts()

                // Sprint 3 - Alonso: Fetch income and expenses for the current month using TransactionViewModel
                viewModel.calculateMonthlyIncomeAndExpenses { income, expenses in
                    totalIncome = income
                    totalExpenses = expenses
                }
            }
        }
    }
    
    func calculateTotalBalance() -> Double {
        return bankAccountViewModel.accounts.reduce(0.0) { $0 + $1.amount }
    }
}

import SwiftUI
import FirebaseAuth

struct HomePage: View {
    @EnvironmentObject var appState: AppState
    @State private var CurrentBalance: Int = 0
    @State private var totalIncome: Double = 0
    @State private var totalExpenses: Double = 0
    @ObservedObject var transactionViewModel: TransactionViewModel
    @ObservedObject private var bankAccountViewModel = BankAccountViewModel()
    @ObservedObject var balanceViewModel = BalanceViewModel() // Agregado
    @State private var selectedAccountID: String = ""

    var body: some View {
        VStack {
            // Selector de cuentas
            Picker("Seleccione una cuenta", selection: $selectedAccountID) {
                Text("Todas las cuentas").tag("")
                ForEach(bankAccountViewModel.accounts, id: \.id) { account in
                    Text(account.name).tag(account.id ?? "")
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedAccountID) { newValue in
                transactionViewModel.getTransactionsForAllAccounts(accountID: selectedAccountID)
            }
            ScrollView {
                Spacer()
                    .frame(height: 53)
                
                HStack {
                    Text("Total Balance")
                        .font(.custom("SF Pro", size: 19))
                        .fontWeight(.regular)
                        .padding(.leading, 86)
                    
                    Image(systemName: "bell.fill")
                        .padding(.leading, 50)
                }
                
                Spacer()
                    .frame(height: 6)
                
                Text("$ \(calculateTotalBalance(), specifier: "%.2f")")
                    .font(.custom("SF Pro", size: 32))
                    .foregroundColor(.primarySpendiq)
                    .fontWeight(.bold)
                
                // Enlace de navegación al tocar el gráfico
                NavigationLink(destination: DetailedGraphView(balanceViewModel: balanceViewModel)) {
                    GraphBox(balanceViewModel: balanceViewModel) // Pasamos balanceViewModel
                        .frame(height: 264)
                        .padding(.bottom, 12)
                }
                
                Divider()
                    .frame(width: 361)
                
                NavigationLink(destination: ThreeMonthOverviewView(viewModel: transactionViewModel)) {
                    OverviewView(
                        totalIncome: totalIncome,
                        totalExpenses: totalExpenses,
                        monthName: DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1], viewModel: transactionViewModel
                    )
                    .padding(.bottom, 12)
                }
                
                HStack {
                    Text("Movements")
                        .font(.custom("SF Pro", size: 19))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.leading)
                    
                    Spacer()
                }
                
                ForEach(transactionViewModel.transactionsByDay.keys.sorted().reversed(), id: \.self) { day in
                    DayResume(viewModel: transactionViewModel, day: day)
                        .padding(.bottom, 0)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onAppear {
                transactionViewModel.getTransactionsForAllAccounts(accountID: selectedAccountID)
                
                // Fetch income and expenses for the current month
                transactionViewModel.calculateMonthlyIncomeAndExpenses { income, expenses in
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

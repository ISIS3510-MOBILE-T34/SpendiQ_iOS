// HomePage.swift

import SwiftUI

struct HomePage: View {
    @State private var currentIndex: Int = 0
    @State private var CurrentBalance: Int = 0
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
                
                GraphBox(currentIndex: $currentIndex)
                    .frame(height: 264)
                    .padding(.bottom,12)
                
                Divider()
                    .frame(width: 361)
                
                Text("Movements")
                    .font(.custom("SF Pro", size: 19))
                    .fontWeight(.regular)
                
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
            }
            .onReceive(viewModel.objectWillChange) { _ in
                // Update the view when the viewModel changes
            }
            .onReceive(bankAccountViewModel.objectWillChange) { _ in
                // Update the balance when the bankAccountViewModel changes
            }
        }
    }
    
    func calculateTotalBalance() -> Double {
        return bankAccountViewModel.accounts.reduce(0.0) { $0 + $1.amount }
    }
}

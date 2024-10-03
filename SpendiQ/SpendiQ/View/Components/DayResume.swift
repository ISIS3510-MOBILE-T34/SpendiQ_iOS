// DayResume.swift

import SwiftUI

struct DayResume: View {
    @ObservedObject var viewModel: TransactionViewModel
    var day: String

    var totalExpenses: Int {
        viewModel.transactionsByDay[day]?.filter { $0.transactionType == "Expense" }.reduce(0) { $0 + Int($1.amount) } ?? 0
    }

    var totalIncomes: Int {
        viewModel.transactionsByDay[day]?.filter { $0.transactionType == "Income" }.reduce(0) { $0 + Int($1.amount) } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DayResumeTitle(Expenses: totalExpenses, Incomes: totalIncomes, Day: day)

            VStack(spacing: 12) {
                if let movements = viewModel.transactionsByDay[day] {
                    ForEach(movements, id: \.id) { transaction in
                        MovementResume(
                            transaction: transaction,
                            viewModel: viewModel
                        )
                        .frame(width: 380)
                        .padding(.bottom,0)
                    }
                }
            }
        }
        .padding()
    }
}

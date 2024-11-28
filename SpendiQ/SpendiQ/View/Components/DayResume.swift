// DayResume.swift

import SwiftUI

struct DayResume: View {
    @ObservedObject var viewModel: TransactionViewModel
    var day: String

    // Actualiza los cálculos para usar solo las transacciones filtradas
    var totalExpenses: Float {
        viewModel.transactionsByDay[day]?.filter { $0.transactionType == "Expense" }.reduce(0) { $0 + $1.amount } ?? 0
    }

    var totalIncomes: Float {
        viewModel.transactionsByDay[day]?.filter { $0.transactionType == "Income" }.reduce(0) { $0 + $1.amount } ?? 0
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

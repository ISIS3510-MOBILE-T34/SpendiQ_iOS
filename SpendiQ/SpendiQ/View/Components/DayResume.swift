import SwiftUI

struct DayResume: View {
    @ObservedObject var viewModel: TransactionViewModel  // Observamos el ViewModel para recibir los datos actualizados
    var day: String  // Día que estamos resumiendo

    // Función para calcular el total de gastos (Expenses)
    var totalExpenses: Int {
        viewModel.transactionsByDay[day]?.filter { $0.transactionType == "Expense" }.reduce(0) { $0 + Int($1.amount) } ?? 0
    }
    
    // Función para calcular el total de ingresos (Incomes)
    var totalIncomes: Int {
        viewModel.transactionsByDay[day]?.filter { $0.transactionType == "Income" }.reduce(0) { $0 + Int($1.amount) } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // DayResumeTitle con actualización dinámica de Expenses e Incomes
            DayResumeTitle(Expenses: totalExpenses, Incomes: totalIncomes, Day: day)
            
            // Lista de movimientos como VStack
            VStack(spacing: 12) {
                if let movements = viewModel.transactionsByDay[day] {
                    ForEach(movements, id: \.id) { transaction in
                        MovementResume(
                            transaction: transaction,
                            viewModel: viewModel  // Pasamos el ViewModel para obtener más datos
                        )
                        .frame(width: 361)
                        
                        Divider()
                            .frame(width: 361)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    DayResume(viewModel: TransactionViewModel(), day: "2024-09-13")
}

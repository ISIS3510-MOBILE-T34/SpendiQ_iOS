import SwiftUI

struct DayResume: View {
    @State private var Movements: [MovementResumeData] = [
        MovementResumeData(MovementName: "Juan Valdez cafe", AccountName: "Bancolombia", MovementTime: "13:53 PM", MovementAmount: 9800, MovementEmoji: "☕️"),
        MovementResumeData(MovementName: "Escuela de gastronomía", AccountName: "Bancolombia", MovementTime: "08:00 AM", MovementAmount: 10000, MovementEmoji: "🍳"),
        MovementResumeData(MovementName: "Escuela de gastronomía", AccountName: "Bancolombia", MovementTime: "08:00 AM", MovementAmount: 10000, MovementEmoji: "🍳"),
        MovementResumeData(MovementName: "Escuela de gastronomía", AccountName: "Bancolombia", MovementTime: "08:00 AM", MovementAmount: 10000, MovementEmoji: "🍳"),
        MovementResumeData(MovementName: "Escuela de gastronomía", AccountName: "Bancolombia", MovementTime: "08:00 AM", MovementAmount: 10000, MovementEmoji: "🍳")
    ]
    
    // Función para calcular el total de gastos (Expenses)
    var totalExpenses: Int {
        Movements.reduce(0) { $0 + $1.MovementAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // DayResumeTitle con actualización dinámica de Expenses
            DayResumeTitle(Expenses: totalExpenses, Incomes: 0, Day: "Sep 13, 2024")
            
            // Lista de movimientos como VStack
            VStack(spacing: 12) {
                ForEach(Movements) { movement in
                    MovementResume(
                        MovementName: movement.MovementName,
                        AccountName: movement.AccountName,
                        MovementTime: movement.MovementTime,
                        MovementAmount: movement.MovementAmount,
                        MovementEmoji: movement.MovementEmoji
                    )
                    .frame(width: 361)
                    
                    Divider()
                        .frame(width:361)
                }
            }
        }
        .padding()
    }
}

#Preview {
    DayResume()
}

// Modelo de datos para los movimientos
struct MovementResumeData: Identifiable {
    var id = UUID()
    var MovementName: String
    var AccountName: String
    var MovementTime: String
    var MovementAmount: Int
    var MovementEmoji: String
}

import SwiftUI

struct MovementResume: View {
    var transaction: Transaction  // Obtenemos un objeto Transaction desde el ViewModel
    @ObservedObject var viewModel: TransactionViewModel  // Referencia al ViewModel para datos adicionales

    var body: some View {
        HStack (spacing: 4 ){
            ZStack{
                Circle()
                    .frame(width:48, height:48)
                    .foregroundStyle(.yellow)
                Text(selectEmoji(for: transaction.transactionType))  // Basado en el tipo de transacción
                    .font(.largeTitle)
            }
            .padding(.leading,16)
            
            VStack (alignment:.leading, spacing: 4){
                Text(transaction.transactionName)
                    .fontWeight(.regular)
                
                HStack{
                    Text(viewModel.accounts[transaction.fromAccountID] ?? "Loading...")  // Usamos el diccionario actualizado en el ViewModel
                        .fontWeight(.light)
                        .font(.system(size:14))
                    
                    Divider()
                        .frame(height:14)
                    
                    Text(formatTime(transaction.dateTime))  // Formatear la hora de la transacción
                        .fontWeight(.light)
                        .font(.system(size:14))
                }
                
            }
            .frame(alignment:.leading)

            Spacer()
            
            if transaction.transactionType == "Expense" {
                Text("$ \(Int(transaction.amount))")  // Mostrar la cantidad como gasto
                    .fontWeight(.medium)
                    .font(.system(size:16))
                    .padding(.trailing, 16)
                    .foregroundStyle(.red)
            } else {
                Text("$ \(Int(transaction.amount))")  // Mostrar la cantidad como ingreso/transacción
                    .fontWeight(.medium)
                    .font(.system(size:16))
                    .padding(.trailing, 16)
                    .foregroundStyle(.primarySpendiq)
            }
        }
        .onAppear {
            // Asegurarnos de que se cargue el nombre de la cuenta si no está ya en el diccionario
            if viewModel.accounts[transaction.fromAccountID] == nil {
                viewModel.getAccountName(fromAccountID: transaction.fromAccountID)
            }
        }
    }

    // Función para seleccionar el emoji en función del tipo de transacción
    func selectEmoji(for transactionType: String) -> String {
        switch transactionType {
        case "Expense":
            return "💰"
        case "Income":
            return "🍾"
        case "Transaction":
            return "3"
        default:
            return "4"  // Emoji por defecto si no coincide con ningún tipo
        }
    }

    // Función para formatear la hora
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    MovementResume(transaction: Transaction(transactionName: "Juan Valdez cafe", amount: 10000, fromAccountID: "Bancolombia", toAccountID: nil, transactionType: "expense", dateTime: Date()), viewModel: TransactionViewModel())
}

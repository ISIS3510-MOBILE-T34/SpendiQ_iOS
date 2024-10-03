import SwiftUI

struct HomePage: View {
    @State private var currentIndex: Int = 0  // Controla el índice del cuadro actual
    @State private var CurrentBalance: Int = 504277
    @StateObject private var viewModel = TransactionViewModel()  // Se crea una instancia del ViewModel

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
                        .foregroundStyle(.black)
                    
                    Image(systemName: "bell.fill")
                        .padding(.leading,50)
                }
                
                Spacer()
                    .frame(height: 6)
                
                Text("$ \(CurrentBalance)")
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
                
                // Muestra los resúmenes de días usando los datos reales
                ForEach(viewModel.transactionsByDay.keys.sorted().reversed(), id: \.self) { day in
                    DayResume(viewModel: viewModel, day: day)
                        .padding(.bottom, 5)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onAppear {
                // Llama a la función para obtener las transacciones de todas las cuentas al cargar la página
                viewModel.getTransactionsForAllAccounts()
            }
        }
    }
}

#Preview {
    HomePage()
}

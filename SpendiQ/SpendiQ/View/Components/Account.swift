import SwiftUI

struct Account: View {
    @Environment(\.dismiss) var dismiss
    @State private var accountName: String = "" // Campo de nombre de cuenta
    @State private var initialBalance: Double? = 0 // Campo de saldo inicial (Double)
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("New Account")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)

            Form {
                // Campo de nombre de cuenta
                Section(header: Text("Account Name")) {
                    TextField("Enter account name", text: $accountName)
                        .frame(height: 32)
                }

                // Campo de saldo inicial
                Section(header: Text("Initial Balance")) {
                    TextField("Enter initial balance", value: $initialBalance, format: .number)
                        .keyboardType(.decimalPad)
                        .onChange(of: initialBalance) { newValue in
                            if let newValue = newValue, newValue < 0 {
                                initialBalance = 0 // Validar si el saldo es negativo
                            }
                        }
                }
            }
            .background(Color.clear)

            // Botones
            HStack {
                Button(action: {
                    // Acción de aceptar (podrías conectar esto con el backend o lógica de negocio)
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    Account()
}

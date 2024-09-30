import SwiftUI

struct Movement: View {
    @State private var showSheet = true
    
    var body: some View {
        Button("") {
            showSheet.toggle()
        }
        .sheet(isPresented: $showSheet) {
            EditTransactionForm() // Aquí llamamos al formulario que contiene los campos editables
                .presentationDetents([.large]) // Controla las alturas del modal
                .presentationDragIndicator(.visible) // Barra de "drag"
        }
    }
}

struct EditTransactionForm: View {
    @Environment(\.dismiss) var dismiss // Para cerrar la hoja modal
    @State private var transactionType: String = "Expense" // Estado para el tipo de transacción
    @State private var transactionName: String = "TDA DE CAFE JUAN VAL"
    @State private var amount: String = "$ 9.800,00"
    @State private var account: String = "Bancolombia"
    @State private var selectedEmoji: String = "☕️" // Estado para el emoji seleccionado
    @FocusState private var isEmojiFieldFocused: Bool // Estado para controlar el foco del campo de emojis
    @State private var selectedTime: Date = Date() // Estado para la hora seleccionada
    @State private var isTimePickerVisible: Bool = false // Controla la visibilidad del Time Picker

    let transactionTypes = ["Expense", "Income", "Transaction"]

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Transaction")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)

            // Picker para seleccionar el tipo de transacción
            Picker("Select Type", selection: $transactionType) {
                ForEach(transactionTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)

            // Imagen del icono
            VStack {
                ZStack(alignment: .center) {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.primarySpendiq)
                    Text(selectedEmoji)
                        .font(.system(size: 58))
                }

                // Botón para cambiar el ícono y enfocar el campo de emojis
                Button("Change icon") {
                    isEmojiFieldFocused = true // Enfoca el campo de emojis
                }
                .foregroundColor(.blue)
            }

            // Formulario con campos editables
            Form {
                Section(header: Text("Transaction name")) {
                    TextField("Transaction name", text: $transactionName)
                        .frame(height: 32)
                }

                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Account")) {
                    TextField("Account", text: $account)
                }

                // Selector de hora: muestra solo la hora si no está seleccionado
                Section(header: Text("Time")) {
                    ZStack {
                        // Time Picker visible cuando el usuario toca la hora
                        if isTimePickerVisible {
                            DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .onTapGesture {
                                    // Permite que el DatePicker siga abierto mientras interactúan con él
                                }
                        } else {
                            Text(selectedTime, style: .time)
                                .onTapGesture {
                                    isTimePickerVisible = true // Muestra el Time Picker
                                }
                        }
                    }
                    // Superposición para detectar toques fuera del Time Picker
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isTimePickerVisible {
                                    isTimePickerVisible = false // Oculta el Time Picker si se toca fuera de él
                                }
                            }
                    )
                }

            }
            .background(Color.clear) // Fondo claro para evitar el gris predeterminado

            // Botones
            HStack {
                Button(action: {
                    // Acción de aceptar
                }) {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    dismiss() // Cierra la hoja modal cuando se presiona el botón Cancel
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
        .onTapGesture {
            // Detecta si se toca fuera del Time Picker y lo oculta
            if isTimePickerVisible {
                isTimePickerVisible = false
            }
        }
    }
}

extension Character {
    // Propiedad para determinar si el carácter es un emoji
    var isEmoji: Bool {
        return unicodeScalars.first?.properties.isEmojiPresentation ?? false
    }
}

#Preview {
    Movement()
}

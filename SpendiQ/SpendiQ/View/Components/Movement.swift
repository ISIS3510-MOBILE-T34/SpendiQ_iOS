import SwiftUI

struct Movement: View {
    @State private var showSheet = true
    
    var body: some View {
        EditTransactionForm()
    }
}

struct EditTransactionForm: View {
    @Environment(\.dismiss) var dismiss
    @State private var transactionType: String = "Expense"
    @State private var transactionName: String = ""
    @State private var amount: Double? = nil // Cambiamos `amount` a Double
    @State private var account: String = ""
    @State private var targetAccount: String = "" // Campo para transacciones
    @State private var selectedEmoji: String = ""
    @FocusState private var isEmojiFieldFocused: Bool
    @State private var selectedDate: Date = Date()
    @State private var isDatePickerVisible: Bool = false // Control para el DatePicker
    @State private var selectedTime: Date = Date()
    @State private var isTimePickerVisible: Bool = false // Control para el TimePicker
    
    let transactionTypes = ["Expense", "Income", "Transaction"]
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Transaction")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Picker("Select Type", selection: $transactionType) {
                ForEach(transactionTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            
            VStack {
                ZStack(alignment: .center) {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.primarySpendiq)
                    Text(selectedEmoji.isEmpty ? "🙂" : selectedEmoji)
                        .font(.system(size: 58))
                }
                
                Button("Change icon") {
                    isEmojiFieldFocused = true
                }
                .foregroundColor(.blue)
            }
            
            Form {
                Section(header: Text("Transaction name")) {
                    TextField("Transaction name", text: $transactionName)
                        .frame(height: 32)
                }
                
                // Actualizamos el campo amount para manejar Double
                Section(header: Text("Amount")) {
                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { newValue in
                            if let newValue = newValue, newValue < 0 {
                                amount = nil
                            }
                        }
                }
                
                Section(header: Text("Account")) {
                    TextField("Account", text: $account)
                }
                
                if transactionType == "Transaction" {
                    Section(header: Text("Target Account")) {
                        TextField("Target Account", text: $targetAccount)
                    }
                }
                
                Section(header: Text("Date")) {
                    ZStack {
                        if isDatePickerVisible {
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(WheelDatePickerStyle())
                        } else {
                            Text(selectedDate, style: .date)
                                .onTapGesture {
                                    isDatePickerVisible = true
                                }
                        }
                    }
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isDatePickerVisible {
                                    isDatePickerVisible = false
                                }
                            }
                    )
                }
                
                // Selector de hora con comportamiento desplegable
                Section(header: Text("Time")) {
                    ZStack {
                        if isTimePickerVisible {
                            DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                        } else {
                            Text(selectedTime, style: .time)
                                .onTapGesture {
                                    isTimePickerVisible = true
                                }
                        }
                    }
                    .background(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isTimePickerVisible {
                                    isTimePickerVisible = false
                                }
                            }
                    )
                }
            }
            .background(Color.clear)
            
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
        .onTapGesture {
            if isDatePickerVisible {
                isDatePickerVisible = false
            }
            if isTimePickerVisible {
                isTimePickerVisible = false
            }
        }
    }
}

#Preview {
    Movement()
}

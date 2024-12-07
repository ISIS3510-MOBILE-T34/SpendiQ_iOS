// DetailedGraphView.swift

import SwiftUI
import Charts

struct DetailedGraphView: View {
    @ObservedObject var balanceViewModel: BalanceViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel // Pasamos el transactionViewModel para acceder a los nombres de las cuentas
    @State private var selectedTimeFrame: String = UserDefaults.standard.string(forKey: "DetailedGraphTimeFrame") ?? "1 Month"
    
    let timeFrames = ["1 Day", "1 Week", "1 Month", "3 Months", "6 Months", "1 Year", "Max"]
    
    var body: some View {
        VStack {
            Text("Balance details")
                .font(.custom("SF Pro", size: 19))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding()
            
            Picker("Time range", selection: $selectedTimeFrame) {
                ForEach(timeFrames, id: \.self) { frame in
                    Text(frame).tag(frame)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selectedTimeFrame) { newValue in
                UserDefaults.standard.set(newValue, forKey: "DetailedGraphTimeFrame")
                balanceViewModel.fetchBalanceData(timeFrame: selectedTimeFrame)
            }
            .padding()
            
            Chart {
                ForEach(balanceViewModel.balanceData, id: \.date) { dataPoint in
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(Color.blue.opacity(0.2))
                    
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDate(for: selectedTimeFrame, date: date))
                                .font(.custom("SF Pro", size: 19))
                                .fontWeight(.regular)
                                .foregroundColor(.black)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .frame(height: 300)
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Ahora InsightsView recibe también el transactionViewModel
            InsightsView(balanceViewModel: balanceViewModel, transactionViewModel: transactionViewModel)
            
            Spacer()
        }
        .onAppear {
            balanceViewModel.fetchBalanceData(timeFrame: selectedTimeFrame)
        }
    }
    
    private func formatDate(for timeFrame: String, date: Date) -> String {
        let formatter = DateFormatter()
        switch timeFrame {
        case "1 Day":
            formatter.dateFormat = "HH:mm"
        case "1 Week", "1 Month", "3 Months", "6 Months":
            formatter.dateFormat = "dd MMM"
        case "1 Year", "Max":
            formatter.dateFormat = "MMM yyyy"
        default:
            formatter.dateFormat = "dd MMM yyyy"
        }
        return formatter.string(from: date)
    }
}

struct InsightsView: View {
    @ObservedObject var balanceViewModel: BalanceViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel // Se inyecta para acceder a los nombres de las cuentas
    
    // Ahora sólo una columna para que todas tengan el mismo tamaño
    let columns = [GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insights")
                .font(.custom("SF Pro", size: 19))
                .fontWeight(.bold)
                .foregroundColor(.black)

            LazyVGrid(columns: columns, spacing: 16) {
                cardView(title: "Total change in Balance", value: "$\(String(format: "%.2f", calculateTotalChange()))")
                cardView(title: "Average Daily Balance", value: "$\(String(format: "%.2f", calculateAverageBalance()))")
                
                let maxAccountID = calculateAccountWithMaxExpense()
                // Obtener el nombre desde transactionViewModel.accounts
                let maxAccountName = (maxAccountID == "No expenses") ? maxAccountID : (transactionViewModel.accounts[maxAccountID] ?? "Unknown Account")
                cardView(title: "Account with highest expense", value: maxAccountName)
                
                cardView(title: "Average Daily Expense", value: "$\(String(format: "%.2f", calculateAverageDailyExpense()))")
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    private func cardView(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.custom("SF Pro", size: 19))
                .fontWeight(.bold) // en negrilla
                .foregroundColor(.black)
            Text(value)
                .font(.custom("SF Pro", size: 19))
                .fontWeight(.regular)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    private func calculateTotalChange() -> Double {
        guard let first = balanceViewModel.balanceData.first?.balance,
              let last = balanceViewModel.balanceData.last?.balance else {
            return 0.0
        }
        return last - first
    }

    private func calculateAverageBalance() -> Double {
        let totalBalance = balanceViewModel.balanceData.reduce(0.0) { $0 + $1.balance }
        return balanceViewModel.balanceData.isEmpty ? 0.0 : totalBalance / Double(balanceViewModel.balanceData.count)
    }
    
    private func calculateAccountWithMaxExpense() -> String {
        var expenseByAccount: [String: Double] = [:]
        
        for transaction in balanceViewModel.currentTransactions {
            if transaction.transactionType == "Expense" {
                let accountID = transaction.accountID ?? "Unknown"
                expenseByAccount[accountID, default: 0.0] += Double(transaction.amount)
            }
        }
        
        let maxAccount = expenseByAccount.max(by: { $0.value < $1.value })?.key ?? "No expenses"
        return maxAccount
    }
    
    private func calculateAverageDailyExpense() -> Double {
        let expenses = balanceViewModel.currentTransactions.filter { $0.transactionType == "Expense" }
        let totalExpenses = expenses.reduce(0.0) { $0 + Double($1.amount) }
        
        guard !expenses.isEmpty else {
            return 0.0
        }
        
        let dates = expenses.compactMap { $0.dateTime }
        guard let minDate = dates.min(), let maxDate = dates.max() else {
            return 0.0
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: minDate), to: calendar.startOfDay(for: maxDate)).day ?? 0
        let numberOfDays = max(1, days + 1)
        
        return totalExpenses / Double(numberOfDays)
    }
}

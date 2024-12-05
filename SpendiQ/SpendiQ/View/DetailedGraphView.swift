import SwiftUI
import Charts

struct DetailedGraphView: View {
    @ObservedObject var balanceViewModel: BalanceViewModel
    @State private var selectedTimeFrame: String = UserDefaults.standard.string(forKey: "DetailedGraphTimeFrame") ?? "1 Month"
    
    let timeFrames = ["1 Day", "1 Week", "1 Month", "3 Months", "6 Months", "1 Year", "Max"]
    
    var body: some View {
        VStack {
            Text("Balance details")
                .font(.title)
                .padding()
            
            // Selector de marco de tiempo
            Picker("Time range", selection: $selectedTimeFrame) {
                ForEach(timeFrames, id: \.self) { frame in
                    Text(frame).tag(frame)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedTimeFrame) { newValue in
                UserDefaults.standard.set(newValue, forKey: "DetailedGraphTimeFrame")
                balanceViewModel.fetchBalanceData(timeFrame: selectedTimeFrame)
            }
    
            // Gráfico detallado
            Chart {
                ForEach(balanceViewModel.balanceData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Balance", dataPoint.balance)
                    )
                    .foregroundStyle(Color.blue.opacity(0.5))
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
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .padding()
    
            // Insights adicionales
            InsightsView(balanceViewModel: balanceViewModel)
    
            Spacer()
        }
        .onAppear {
            balanceViewModel.fetchBalanceData(timeFrame: selectedTimeFrame)
        }
    }
    
    private func formatDate(for timeFrame: String, date: Date) -> String {
        let formatter = DateFormatter()
        switch timeFrame {
        case "1 Día":
            formatter.dateFormat = "HH:mm"
        case "1 Week", "1 Month", "3 Months", "6 Months":
            formatter.dateFormat = "dd MMM"
        case "1 year", "Max":
            formatter.dateFormat = "MMM yyyy"
        default:
            formatter.dateFormat = "dd MMM yyyy"
        }
        return formatter.string(from: date)
    }
}

struct InsightsView: View {
    @ObservedObject var balanceViewModel: BalanceViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insights")
                .font(.headline)
                .padding(.bottom, 5)

            Text("Total change in Balance: $\(calculateTotalChange(), specifier: "%.2f")")
            Text("Avarage Daily Balance: $\(calculateAverageBalance(), specifier: "%.2f")")
            // Agrega más insights según sea necesario
        }
        .padding()
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
        return totalBalance / Double(balanceViewModel.balanceData.count)
    }
}

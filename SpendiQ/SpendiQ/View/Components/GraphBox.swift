import SwiftUI
import Charts

struct GraphBox: View {
    @State private var selectedTimeFrame: String = "1 Day"
    @ObservedObject var balanceViewModel = BalanceViewModel()
    
    let timeFrames = ["1 Day", "Max"]
    
    var body: some View {
        VStack {
            // Chart View
            chartView()
                .frame(height: 200)
                .padding(.horizontal)
            
            // Time Frame Picker
            HStack(spacing: 20) {
                ForEach(timeFrames, id: \.self) { frame in
                    Button(action: {
                        withAnimation {
                            selectedTimeFrame = frame
                            balanceViewModel.fetchBalanceData(timeFrame: selectedTimeFrame)
                        }
                    }) {
                        Text(frame)
                            .fontWeight(selectedTimeFrame == frame ? .bold : .regular)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(selectedTimeFrame == frame ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(20)
                            .foregroundColor(selectedTimeFrame == frame ? .blue : .gray)
                            .font(.system(size: 14))
                    }
                }
            }
            .frame(height: 48)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(14)
            .padding(.horizontal)
        }
        .onAppear {
            balanceViewModel.fetchBalanceData(timeFrame: selectedTimeFrame)
        }
    }
    
    @ViewBuilder
    func chartView() -> some View {
        if balanceViewModel.balanceData.isEmpty {
            Text("No data available")
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
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
            .padding(.bottom, 30)
        }
    }
    
    // Function to format dates based on time frame
    private func formatDate(for timeFrame: String, date: Date) -> String {
        let formatter = DateFormatter()
        switch timeFrame {
        case "1 Day":
            formatter.dateFormat = "HH:mm"
        case "Max":
            formatter.dateFormat = "MMM dd, yyyy"
        default:
            formatter.dateFormat = "MMM dd"
        }
        return formatter.string(from: date)
    }
}

// Created by Alonso Hernandez
// New View Sprint 4

import SwiftUI

struct ThreeMonthOverviewView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var results: [(String, Double, Double)] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(results, id: \.0) { monthName, income, expenses in
                            VStack(alignment: .leading) {
                                Text("Overview of \(monthName)")
                                    .font(.headline)
                                    .padding(.bottom, 5)

                                HStack(spacing: 0) {
                                    VStack {
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(.green)
                                        Text("$\(income, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.green.opacity(0.1))

                                    VStack {
                                        Image(systemName: "arrow.down")
                                            .foregroundColor(.red)
                                        Text("$\(expenses, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.red.opacity(0.1))
                                }
                                .frame(height: 100)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Last Three Months")
                        .font(.title2)
                        .bold()
                        .padding(.bottom, 10) // Add space below the title
                }
            }
        }
        .onAppear {
            fetchData()
        }
        .padding(.top, 40)
        .padding(.bottom, 10)
    }

    private func fetchData() {
        isLoading = true
        viewModel.calculateLastThreeMonthsIncomeAndExpenses { data in
            DispatchQueue.main.async {
                results = data
                isLoading = false
            }
        }
    }
}

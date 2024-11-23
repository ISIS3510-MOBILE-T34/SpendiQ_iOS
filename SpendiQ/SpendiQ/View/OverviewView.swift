//
//  OverviewView.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 20/11/24.
//  Sprint 3: BQ

import Foundation
import SwiftUI

struct OverviewView: View {
    var totalIncome: Double
    var totalExpenses: Double
    var monthName: String
    @ObservedObject var viewModel: TransactionViewModel

    var body: some View {
        NavigationLink(destination: ThreeMonthOverviewView(viewModel: viewModel)) {
            VStack(alignment: .center) {
                Text("Overview of \(monthName)")
                    .font(.headline)
                    .padding(.bottom, 5)
                    .foregroundColor(.black)
                
                Text("Click here to see your comparison in the last three months")
                    .font(.subheadline)
                    .padding(.bottom, 5)
                    .foregroundColor(.black)
                
                HStack(spacing: 0) {
                    // Income section
                    VStack {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.green)
                        Text("$\(totalIncome, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green.opacity(0.1))

                    // Expense section
                    VStack {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.red)
                        Text("$\(totalExpenses, specifier: "%.2f")")
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

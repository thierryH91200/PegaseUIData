//
//  RecetteDepenseBar3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct RecetteDepenseView: View {
    
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = RecetteDepenseBarViewModel()

    let transactions: [EntityTransaction]

    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    @Binding var minDate: Date
    @Binding var maxDate: Date

    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    
    private var firstDate: Date {
        transactions.first?.dateOperation ?? Date()
    }

    private var lastDate: Date {
        transactions.last?.dateOperation ?? Date()
    }

    private var durationDays: Double {
        lastDate.timeIntervalSince(firstDate) / 86400
    }


    var body: some View {
        
        VStack {
            Text(String(localized:"RecetteDepenseBar3"))
                .font(.headline)
                .padding()
            
            HStack {
                DGBarChart4Representable(entries: viewModel.dataEntriesDepense, title: "Dépenses")
                    .frame(width: 600, height: 400)
                    .padding()
                
                DGBarChart4Representable(entries: viewModel.dataEntriesRecette, title: "Recettes")
                    .frame(width: 600, height: 400)
                    .padding()
            }
            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    RangeSlider(
                        minValue: .constant(0),
                        maxValue: .constant(durationDays),
                        lowerValue: $lowerValue,
                        upperValue: $upperValue,
                        referenceDate: minDate, transactionCount: 5
                    )
                    .frame(height: 30)
                    
                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
        }
        .onAppear {
            updatePieData()
        }

    }
    private func updatePieData() {
        
//        let listTransactions = $viewModel.listTransactions
//        firstDate = viewModel.firstDate
//        lastDate = viewModel.lastDate
//        guard let currentAccount = CurrentAccountManager.shared.getAccount() else { return }
//
//        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }

    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}



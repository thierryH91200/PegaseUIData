//
//  ModePaiementPie3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct ModePaiementView: View {

    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = ModePaymentPieViewModel()

    let transactions: [EntityTransaction]

    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    @Binding var minDate: Date
    @Binding var maxDate: Date

    private var firstDate: Date {
        transactions.first?.dateOperation ?? Date()
    }

    private var lastDate: Date {
        transactions.last?.dateOperation ?? Date()
    }

    private var durationDays: Double {
        lastDate.timeIntervalSince(firstDate) / 86400
    }

    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var chartViewRef: PieChartView?
    @State private var updateWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ModePaiement Pie")
                .font(.headline)
                .padding()
            
            HStack {
                SinglePieChartView(entries: viewModel.dataEntriesDepense, title: "Dépenses")
                    .frame(width: 600, height: 400)
                    .padding()
                
                SinglePieChartView(entries: viewModel.dataEntriesRecette, title: "Recettes")
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
            let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
            let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
            let currentAccount = CurrentAccountManager.shared.getAccount()!
            viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
        }
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

}

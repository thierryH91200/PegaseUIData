//
//  CategorieBar23.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct RubricColor : Hashable {
    var name: String
    var color  : NSColor
    
    init(name:String, color : NSColor) {
        self.name = name
        self.color = color
    }
}

struct CategorieBar2View2: View {
        
    @StateObject private var viewModel = CategorieBar2ViewModel()

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
    
    @State private var chartView: BarChartView?
    @State private var updateWorkItem: DispatchWorkItem?
    
    @State private var lower: Double = 2
    @State private var upper: Double = 10

    var body: some View {
        VStack {
            Text("CategorieBar2View2")
                .font(.headline)
                .padding()
            
            DGBarChart2Representable(entries: viewModel.dataEntries,
                           labels: viewModel.labels,
                           chartViewRef: $chartView)
                .frame(width: 600, height: 400)
                .padding()
            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(
                        lowerValue: $lower,
                        upperValue: $upper,
                        totalRange: lower...upper,
                        valueLabel: { value in
                            let today = Date()
                            let date = Calendar.current.date(byAdding: .day, value: Int(value), to: today)!
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            return formatter.string(from: date)
                        },
                        thumbSize: 24,
                        trackHeight: 6
                    )
                    .frame(height: 30)
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
            .padding()

            Spacer()
        }
        .onAppear {
            let listTransactions = ListTransactionsManager.shared.getAllData()
            minDate = listTransactions.first!.dateOperation
            maxDate = listTransactions.last!.dateOperation
            viewModel.updateChartData(startDate: minDate, endDate: maxDate)
            chartView = BarChartView()
            if let chartView = chartView {
                CategorieBar2ViewModel.shared.configure(with: chartView)
            }

        }
        .onChange(of: selectedStart) { _, newValue in
            updateChartDebounced()
        }
        .onChange(of: selectedEnd) { _, newValue in
            updateChartDebounced()
        }
    }
    
    func updateChartDebounced() {
        updateWorkItem?.cancel()
        let workItem = DispatchWorkItem { self.updateChart() }
        updateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func updateChart() {
//        let listTransactions = viewModel.listTransactions
//        firstDate = viewModel.firstDate
//        lastDate = viewModel.lastDate
//        guard let currentAccount = CurrentAccountManager.shared.getAccount() else { return }
//
//        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: firstDate, endDate: lastDate)
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

}

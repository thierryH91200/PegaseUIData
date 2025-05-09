//
//  Untitled 3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct TreasuryCurve: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @State var lineDataEntries: [ChartDataEntry] = []
    @StateObject private var viewModel = TresuryLineViewModel()
    
    @State private var minDate = Date()
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    private let oneDay = 3600.0 * 24.0 // one day

    @State private var chartView : LineChartView?

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Cash flow curve")
                    .font(.headline)
                    .padding()
                
                DGLineChartRepresentable(viewModel: viewModel, entries: viewModel.dataEntries)
                    .frame(width: geometry.size.width, height: 400)
                    .padding()
                    .onAppear {
                        viewModel.updateAccount()
                    }

                GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        RangeSlider(minValue: minDate.timeIntervalSince(minDate) / (oneDay),
                                    maxValue: maxDate.timeIntervalSince(minDate) / (oneDay),
                                    lowerValue: $selectedStart,
                                    upperValue: $selectedEnd)
                        .frame(height: 30)
                    }
                    .padding(.top, 4)
                    .padding(.horizontal)
                }
                .onAppear {
                    
                    ListTransactionsManager.shared.configure(with: modelContext)
                    let listTransactions = ListTransactionsManager.shared.getAllDatas()
                    minDate = listTransactions.first!.dateOperation
                    maxDate = listTransactions.last!.dateOperation

                    chartView = LineChartView()
                    if let chartView = chartView {
                        TresuryLineViewModel.shared.configure(with: chartView)
                    }
                    updateChart()

                }
                .onChange(of: selectedStart) { _, newStart in
                    viewModel.selectedStart = newStart
                    updateChart()
                }
                .onChange(of: selectedEnd) { _, newEnd in
                    viewModel.selectedEnd = newEnd
                    updateChart()
                }
            }
        }
    }
    
    private func updateChart() {
//        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
//        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
//        guard let currentAccount = CurrentAccountManager.shared.getAccount() else { return }
        
        ListTransactionsManager.shared.configure(with: modelContext)
        InitAccountManager.shared.configure(with: modelContext)

//        viewModel.initGraph(chartView: chartView!)
//        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
//        viewModel.setData(chartView: chartView!)
    }

    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

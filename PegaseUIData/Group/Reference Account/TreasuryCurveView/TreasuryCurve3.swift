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
    
    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Courbe de trésorerie")
                    .font(.headline)
                    .padding()
                
                DGLineChartView(entries: viewModel.dataEntries)
                    .frame(width: geometry.size.width, height: 400)
                    .padding()
                GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        RangeSlider(minValue: 0,
                                    maxValue: maxDate.timeIntervalSince(minDate) / (60 * 60 * 24),
                                    lowerValue: $selectedStart,
                                    upperValue: $selectedEnd)
                        .frame(height: 30)
                    }
                    .padding(.top, 4)
                    .padding(.horizontal)

                    
                }
                .onAppear {
                    updateChart()
                }
                .onChange(of: selectedStart) { _, _ in updateChart() }
                .onChange(of: selectedEnd) { _, _ in updateChart() }
            }
        }
    }
    
    private func updateChart() {
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
        guard let currentAccount = CurrentAccountManager.shared.getAccount() else { return }

        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }

    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

}

//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct RecetteDepensePie: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = RecetteDepensePieViewModel()

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30

    @State private var updateWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized:"Recette Dépense Pie"))
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

                    RangeSlider(minValue: 0,
                                maxValue: maxDate.timeIntervalSince(minDate) / (60 * 60 * 24),
                                lowerValue: $selectedStart,
                                upperValue: $selectedEnd)
                        .frame(height: 30)

                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
        }
        .onAppear {
            updateChart()
        }
        .onChange(of: selectedStart) { _, _ in updateChartDebounced() }
        .onChange(of: selectedEnd)   { _, _ in updateChartDebounced() }
    }

    func updateChartDebounced() {
        updateWorkItem?.cancel()
        let workItem = DispatchWorkItem { self.updateChart() }
        updateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func updateChart() {
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
        let currentAccount = CurrentAccountManager.shared.getAccount()!
        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }

    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

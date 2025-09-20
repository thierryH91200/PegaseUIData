////
////  ModePaiementPie3.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
//
//
//  ModePaiementPie3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct ModePaiementView: View {

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
    
    private var totalDays: Int {
        max(0, Calendar.current.dateComponents([.day], from: minDate, to: maxDate).day ?? 0)
    }
    
    
    private var totalDaysRange: ClosedRange<Double> {
        let cal = Calendar.current
        let start = cal.startOfDay(for: minDate)
        let end = cal.startOfDay(for: maxDate)
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 0
        return 0...Double(max(0, days))
    }


    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
//    @State private var chartViewRef: PieChartView?
    @State private var updateWorkItem: DispatchWorkItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ModePaiement Pie")
                .font(.headline)
                .padding()
            
            HStack {
                if viewModel.dataEntriesDepense.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.2))
                        Text("No expenses over the period")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 600, height: 400)
                    .padding()
                } else {
                    SinglePieChartView(entries: viewModel.dataEntriesDepense, title: "Expenses")
                        .frame(width: 600, height: 400)
                        .padding()
                }

                if viewModel.dataEntriesRecette.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.2))
                        Text("No receipts for the period")
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 600, height: 400)
                    .padding()
                } else {
                    SinglePieChartView(entries: viewModel.dataEntriesRecette, title: "Receipts")
                        .frame(width: 600, height: 400)
                        .padding()
                }
            }
            
            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: lowerValue)) to \(formattedDate(from: upperValue))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(
                        lowerValue: $selectedStart,
                        upperValue: $selectedEnd,
                        totalRange: totalDaysRange,
                        valueLabel: { value in
                            let cal = Calendar.current
                            let base = cal.startOfDay(for: minDate)
                            let date = cal.date(byAdding: .day, value: Int(value), to: base) ?? base
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            return formatter.string(from: date)
                        },
                        thumbSize: 24,
                        trackHeight: 6
                    )
                        .frame(height: 30)

                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }

        }
        .onAppear {
            upperValue = Double(totalDays)
            refreshData()
        }
        .onChange(of: lowerValue) { _, _ in
            if lowerValue > upperValue { upperValue = lowerValue }
            refreshData()
        }
        .onChange(of: upperValue) { _, _ in
            if upperValue < lowerValue { lowerValue = upperValue }
            refreshData()
        }
        .onChange(of: minDate) { _, _ in
            // Recompute totalDays implicitly via computed property and clamp values
            lowerValue = max(0, min(lowerValue, Double(totalDays)))
            upperValue = max(lowerValue, min(upperValue, Double(totalDays)))
            refreshData()
        }
        .onChange(of: maxDate) { _, _ in
            lowerValue = max(0, min(lowerValue, Double(totalDays)))
            upperValue = max(lowerValue, min(upperValue, Double(totalDays)))
            refreshData()
        }
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(dayOffset), to: minDate)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func refreshData() {
        let start = Calendar.current.date(byAdding: .day, value: Int(lowerValue), to: minDate)!
        let rawEnd = Calendar.current.date(byAdding: .day, value: Int(upperValue), to: minDate)!
        let end = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: rawEnd) ?? rawEnd
        guard let currentAccount = CurrentAccountManager.shared.getAccount() else { return }
        print("[Pie] refreshData start:", start, "end:", end)
        viewModel.updateChartData( startDate: start, endDate: end)
    }

}


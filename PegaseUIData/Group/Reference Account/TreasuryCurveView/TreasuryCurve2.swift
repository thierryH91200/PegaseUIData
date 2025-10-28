//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//
//

import SwiftUI
import SwiftData
import DGCharts
import Combine

struct TreasuryCurve: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var currentAccountManager: CurrentAccountManager
    @EnvironmentObject private var colorManager: ColorManager
    @EnvironmentObject private var transactionManager: TransactionSelectionManager
    @StateObject private var viewModel = TresuryLineViewModel()
    @ObservedObject private var transactionsManager = ListTransactionsManager.shared
    
    @Binding var transactions: [EntityTransaction]
    @Binding var dashboard: DashboardState
    @Binding var minDate: Date
    @Binding var maxDate: Date
    
    @State private var filteredTransactions: [EntityTransaction] = []
    
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var isDraggingSlider: Bool = false
    @State private var lastAppliedStart: Double = .nan
    @State private var lastAppliedEnd: Double = .nan
    @State private var isApplyingFilter: Bool = false
    
    @State private var hasAppliedInitial: Bool = false
    @State private var applyCooldownUntil: Date = .distantPast
    
    @State private var lower: Double = 2
    @State private var upper: Double = 10
    
    @State private var selectedTransactionID: EntityTransaction.ID? = nil
    
    @State private var pendingStart: Double = 0
    @State private var pendingEnd: Double = 0
    
    @AppStorage("enableSoundFeedback") private var enableSoundFeedback: Bool = true
    
    private var durationDays: Double {
        maxDate.timeIntervalSince(minDate) / 86400
    }
    
    private var totalAmount: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var totalDaysRange: ClosedRange<Double> {
        let cal = Calendar.current
        let start = cal.startOfDay(for: minDate)
        let end = cal.startOfDay(for: maxDate)
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 0
        let upper = max(1, days)
        return 0...Double(upper)
    }
    
    private let formatterPrice: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = .current
        f.numberStyle = .currency
        return f
    }()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header
                chartView(width: geometry.size.width)
                filterBox
            }
            .onAppear {
                refreshData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .sliderValueChanged)) { _ in
                DispatchQueue.main.async { applyFromCurrentSelection() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionsSelectionChanged)) { _ in
                DispatchQueue.main.async {
                    self.filteredTransactions = ListTransactionsManager.shared.listTransactions
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        Text(String(localized:"Treasury curve", table: "Charts"))
            .font(.headline)
            .padding()
    }
    
    private func chartView(width: CGFloat) -> some View {
        DGLineChartRepresentable(viewModel: viewModel, entries: viewModel.dataEntries)
            .frame(width: width, height: 400)
            .padding()
    }
    
    private var filterBox: some View {
        GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
            VStack(alignment: .leading, spacing: 8) {
                selectedPeriodLabel
                periodSlider
                periodSummary
                if hasAppliedInitial {
//                    TransactionList()
                    TransactionLocal()
                }
            }
            .padding(.top, 4)
            .padding(.horizontal)
        }
    }

    private var selectedPeriodLabel: some View {
        let startText = dateFromOffset(isDraggingSlider ? pendingStart : selectedStart)
        let endText = dateFromOffset(isDraggingSlider ? pendingEnd : selectedEnd)
        return Text("Selected period : \(startText) → \(endText)")
            .font(.callout)
            .foregroundColor(.secondary)
    }
    
    private var periodSlider: some View {
        RangeSlider(
            lowerValue: $pendingStart,
            upperValue: $pendingEnd,
            totalRange: totalDaysRange,
            valueLabel: { value in dateLabel(for: value) },
            thumbSize: 24,
            trackHeight: 6
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if !isDraggingSlider { isDraggingSlider = true } }
                .onEnded { _ in
                    isDraggingSlider = false
                    selectedStart = pendingStart
                    selectedEnd = pendingEnd
                    applyFromCurrentSelection()
                }
        )
        .frame(height: 50)
        .onAppear { initializeSliderBounds() }
    }
    
    private var periodSummary: some View {
        Text("\(selectedDays()) days — \(filteredTransactions.count) transaction\(filteredTransactions.count > 1 ? "s" : "") — Total: \(formattedAmount(totalAmount))")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.top, 4)
            .transaction { $0.animation = nil }
    }
    
    private func initializeSliderBounds() {
        dashboard.isVisible = true
        let newStart = 0.0
        let newEnd = max(1, totalDaysRange.upperBound)
        selectedStart = newStart
        selectedEnd = (newEnd <= newStart) ? (newStart + 1) : newEnd
        pendingStart = selectedStart
        pendingEnd = selectedEnd
    }

    // MARK: - Helpers

    private var baseStartOfDay: Date { Calendar.current.startOfDay(for: minDate) }

    private func dateLabel(for value: Double) -> String {
        let cal = Calendar.current
        let base = cal.startOfDay(for: minDate)
        let date = cal.date(byAdding: .day, value: Int(value), to: base) ?? base
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func endOfDay(for date: Date) -> Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? date
    }

    private func applyFromCurrentSelection() {
        if Date() < applyCooldownUntil { return }
        if isDraggingSlider || isApplyingFilter { return }
        let rawStart = selectedStart.rounded()
        let rawEnd = selectedEnd.rounded()
        let safeUpperBound = max(totalDaysRange.upperBound, 1)
        let startDay = max(0, min(rawStart, safeUpperBound - 1))
        let endDay = max(startDay + 1, min(rawEnd, safeUpperBound))
        applyNormalizedRange(startDay: Int(startDay), endDay: Int(endDay))
    }

    private func applyNormalizedRange(startDay: Int, endDay: Int) {
        if isApplyingFilter { return }
        isApplyingFilter = true
        defer { isApplyingFilter = false }
        if Int(lastAppliedStart) == startDay && Int(lastAppliedEnd) == endDay { return }
        lastAppliedStart = Double(startDay)
        lastAppliedEnd = Double(endDay)
        
        let base = baseStartOfDay
        guard let startDateBase = Calendar.current.date(byAdding: .day, value: startDay, to: base),
              let endDateBase = Calendar.current.date(byAdding: .day, value: endDay, to: base) else { return }
        
        let startDate = Calendar.current.startOfDay(for: startDateBase)
        let endDate = endOfDay(for: endDateBase)
        
        let newFiltered = transactions.filter { $0.datePointage >= startDate && $0.datePointage <= endDate }
        
        let oldIDs = filteredTransactions.map { $0.id }
        let newIDs = newFiltered.map { $0.id }
        let dataChanged = (oldIDs != newIDs)
        
        let rangeChanged = (
            viewModel.lowerValue != Double(startDay) ||
            viewModel.upperValue != Double(endDay) ||
            viewModel.selectedStart != Double(startDay) ||
            viewModel.selectedEnd != Double(endDay)
        )
        
        if !dataChanged && !rangeChanged { return }
        
        selectedStart = Double(startDay)
        selectedEnd = Double(endDay)
        
        DispatchQueue.main.async {
            if rangeChanged {
                viewModel.lowerValue = Double(startDay)
                viewModel.upperValue = Double(endDay)
                viewModel.selectedStart = Double(startDay)
                viewModel.selectedEnd = Double(endDay)
                viewModel.updateChartData()
            }
            
            DispatchQueue.main.async {
                if dataChanged {
                    filteredTransactions = []   //newFiltered
                    NotificationCenter.default.post(name: .treasuryListNeedsRefresh, object: nil)
                }
                
                hasAppliedInitial = true
                applyCooldownUntil = Date().addingTimeInterval(0.3)
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .treasuryChartNeedsRefresh, object: nil)
                }
            }
        }
    }

    private func refreshData() {
        
        transactions = ListTransactionsManager.shared.getAllData()
        guard let first = transactions.first?.datePointage,
              let last = transactions.last?.datePointage else {
            return
        }

        minDate = Calendar.current.startOfDay(for: first)
        maxDate = endOfDay(for: last)

        selectedStart = 0
        selectedEnd = max(1, durationDays)
        lastAppliedStart = selectedStart.rounded()
        lastAppliedEnd = selectedEnd.rounded()

        viewModel.listTransactions = transactions

        DispatchQueue.main.async {
            applyFromCurrentSelection()
        }
    }

    private func selectedDays() -> Int {
        Int(selectedEnd - selectedStart + 1)
    }

    private func dateFromOffset(_ offset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(offset.rounded()), to: baseStartOfDay) ?? baseStartOfDay
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
}


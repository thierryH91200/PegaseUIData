//
//  Untitled 3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import AppKit
import Combine


struct TreasuryCurve: View {
    
    @Binding var dashboard: DashboardState

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @EnvironmentObject private var colorManager          : ColorManager

    
    @StateObject private var viewModel = TresuryLineViewModel()
    @ObservedObject private var transactionsManager = ListTransactionsManager.shared

    @Binding var allTransactions: [EntityTransaction]
    @State private var filteredTransactions: [EntityTransaction] = []

    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()
    
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
    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()


    var body: some View {
//        let isSelected = selectedTransactions.contains(transaction.id)
//        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(transaction)

        GeometryReader { geometry in
            
            VStack {
                Text("Treasury curve")
                    .font(.headline)
                    .padding()

                DGLineChartRepresentable(viewModel: viewModel,
                                         entries: viewModel.dataEntries)
                    .frame(width: geometry.size.width, height: 400)
                    .padding()

                GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected period : \(dateFromOffset(isDraggingSlider ? pendingStart : selectedStart)) → \(dateFromOffset(isDraggingSlider ? pendingEnd : selectedEnd))")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        RangeSlider(
                            lowerValue: $pendingStart,
                            upperValue: $pendingEnd,
                            totalRange: totalDaysRange,
                            valueLabel: { value in
                                let cal = Calendar.current
                                let base = cal.startOfDay(for: minDate)
                                let date = cal.date(byAdding: .day, value: Int(value), to: base) ?? base
                                let formatter = DateFormatter()
                                formatter.dateStyle = .short
                                let date1 = formatter.string(from: date)
                                return date1
                            },
                            thumbSize: 24,
                            trackHeight: 6
                    )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isDraggingSlider { isDraggingSlider = true }
                                }
                                .onEnded { _ in
                                    isDraggingSlider = false
                                    selectedStart = pendingStart
                                    selectedEnd = pendingEnd
                                    applyFromCurrentSelection()
                                }
                        )
                        .frame(height: 50)
                        .onAppear {
                            dashboard.isVisible = true

                            // Initialize slider bounds based on available data
                            let newStart = 0.0
                            let newEnd = max(1, totalDaysRange.upperBound)
                            selectedStart = newStart
                            selectedEnd = (newEnd <= newStart) ? (newStart + 1) : newEnd
                            pendingStart = selectedStart
                            pendingEnd = selectedEnd
                        }
                        
                        Text("\(selectedDays()) days — \(filteredTransactions.count) transaction\(filteredTransactions.count > 1 ? "s" : "") — Total: \(formattedAmount(totalAmount))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                            .transaction { $0.animation = nil }
                        if hasAppliedInitial {
                            List(filteredTransactions, id: \.id) { tx in
                                let isSelected = (tx.id == selectedTransactionID)
                                let textColor = isSelected ? Color.white : colorManager.colorForTransaction(tx)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(tx.datePointage, style: .date)
                                            .frame(minWidth: 110, alignment: .leading)

                                        Text(tx.dateOperation, style: .date)
                                            .frame(minWidth: 110, alignment: .leading)

                                        Text(tx.statusString)
                                            .frame(minWidth: 120, alignment: .leading)

                                        Text(tx.paymentModeString)
                                            .frame(minWidth: 140, alignment: .leading)

                                        Text(tx.bankStatementString)
                                            .frame(minWidth: 160, alignment: .leading)
                                    }
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(tx.sousOperations.first?.libelle ?? "—")
                                            .frame(minWidth: 220, alignment: .leading)
                                        
                                        Text(tx.sousOperations.first?.category?.rubric?.name ?? "—")
                                            .frame(minWidth: 120, alignment: .leading)
                                        
                                        Text(tx.sousOperations.first?.category?.name ?? "—")
                                            .frame(minWidth: 140, alignment: .leading)

                                        let amountString = formatterPrice.string(from: NSNumber(value: tx.amount)) ?? "—"
                                        Text(amountString)
                                            .frame(minWidth: 160, alignment: .leading)
                                    }
                                }
                                .foregroundColor(textColor)
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedTransactionID == tx.id {
                                        selectedTransactionID = nil   // toggle off
                                    } else {
                                        selectedTransactionID = tx.id // select
                                    }
                                }
                            }
                            .transaction { $0.animation = nil }
                            .frame(height: 600)
                        }
                        
                    }
                    .padding(.top, 4)
                    .padding(.horizontal)
                }
            }
            .onAppear {
                refreshData(for: currentAccountManager.getAccount())
            }
            .onReceive(NotificationCenter.default.publisher(for: .sliderValueChanged)) { _ in
                // Applique le filtre correspondant à la position actuelle du slider
                DispatchQueue.main.async {
                    applyFromCurrentSelection()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionsSelectionChanged)) { _ in
                DispatchQueue.main.async {
                    self.filteredTransactions = ListTransactionsManager.shared.listTransactions
                }
            }
        }
    }

    // MARK: - Helpers

    private var baseStartOfDay: Date {
        Calendar.current.startOfDay(for: minDate)
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

        // Avoid redundant work
        if Int(lastAppliedStart) == startDay && Int(lastAppliedEnd) == endDay { return }

        lastAppliedStart = Double(startDay)
        lastAppliedEnd = Double(endDay)

        let base = baseStartOfDay
        guard let startDateBase = Calendar.current.date(byAdding: .day, value: startDay, to: base),
              let endDateBase = Calendar.current.date(byAdding: .day, value: endDay, to: base) else { return }

        let startDate = Calendar.current.startOfDay(for: startDateBase)
        let endDate = endOfDay(for: endDateBase)

        let newFiltered = allTransactions.filter { $0.datePointage >= startDate && $0.datePointage <= endDate }

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

        // Immediate: normalize selection only
        var immediateTx = SwiftUI.Transaction()
        immediateTx.disablesAnimations = true
        withTransaction(immediateTx) {
            selectedStart = Double(startDay)
            selectedEnd = Double(endDay)
        }

        // Tick 1: update chart only (coalesced, no animation)
        DispatchQueue.main.async {
            var tx = SwiftUI.Transaction()
            tx.disablesAnimations = true
            withTransaction(tx) {
                if rangeChanged {
                    viewModel.lowerValue = Double(startDay)
                    viewModel.upperValue = Double(endDay)
                    viewModel.selectedStart = Double(startDay)
                    viewModel.selectedEnd = Double(endDay)
                    viewModel.updateChartData()
                }
            }
            
            // Tick 2: update list only (no animation)
            DispatchQueue.main.async {
                var listTx = SwiftUI.Transaction()
                listTx.disablesAnimations = true
                withTransaction(listTx) {
                    if dataChanged {
                        filteredTransactions = newFiltered
                        NotificationCenter.default.post(name: .treasuryListNeedsRefresh, object: nil)
                    }
                }
                hasAppliedInitial = true
                applyCooldownUntil = Date().addingTimeInterval(0.3)
                
                // Tick 3: notify observers after everything is stable
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .treasuryChartNeedsRefresh, object: nil)
                }
            }
        }
    }



    private func refreshData(for account: EntityAccount?) {
        guard let account = account else {
            allTransactions = []
            filteredTransactions = []
            return
        }

        allTransactions = ListTransactionsManager.shared
            .getAllData()
            .filter { $0.account == account }
            .sorted { $0.datePointage < $1.datePointage }

        guard let first = allTransactions.first?.datePointage,
              let last = allTransactions.last?.datePointage else {
            return
        }

        minDate = Calendar.current.startOfDay(for: first)
        maxDate = endOfDay(for: last)

        selectedStart = 0
        selectedEnd = max(1, durationDays)
        lastAppliedStart = selectedStart.rounded()
        lastAppliedEnd = selectedEnd.rounded()

        viewModel.listTransactions = allTransactions

        DispatchQueue.main.async {
            applyFromCurrentSelection()
        }
        // Initial apply is deferred to parent onAppear to avoid visible movement at startup
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


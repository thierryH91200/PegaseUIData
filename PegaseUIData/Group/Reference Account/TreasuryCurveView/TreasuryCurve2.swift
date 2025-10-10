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
    @EnvironmentObject private var currentAccountManager: CurrentAccountManager
    @EnvironmentObject private var colorManager: ColorManager
    @EnvironmentObject private var transactionManager: TransactionSelectionManager

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
            .onAppear { refreshData(for: currentAccountManager.getAccount()) }
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
        Text("Treasury curve")
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

                    transactionsList
                        .transaction { $0.animation = nil }
                        .frame(height: 600)
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
    
    private var headerList: some View {
        VStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 4) {
                    Text("Date of pointing :")
                        .frame(minWidth: 110, alignment: .leading)
                    Text("Date operation")
                        .frame(minWidth: 110, alignment: .leading)
                    Text("Status")
                        .frame(minWidth: 120, alignment: .leading)
                    Text("Mode")
                        .frame(minWidth: 140, alignment: .leading)
                    Text("Statement")
                        .frame(minWidth: 160, alignment: .leading)
                }
                HStack(alignment: .top, spacing: 4) {
                    Text("Comment")
                        .frame(minWidth: 220, alignment: .leading)
                    Text("Rubric")
                        .frame(minWidth: 120, alignment: .leading)
                    Text("Category")
                        .frame(minWidth: 140, alignment: .leading)
                    Text("Amount")
                        .frame(minWidth: 160, alignment: .leading)
                }
            }
            .foregroundColor(.black)
            .bold()
        }
    }

    private var transactionsList: some View {
        List {
            Section(header: headerList) {
                ForEach(filteredTransactions, id: \.id) { tx in
                    TransactionRow(tx: tx,
                                   isSelected: tx.id == selectedTransactionID,
                                   formatterPrice: formatterPrice,
                                   colorManager: colorManager)
                    .contentShape(Rectangle())
                    .onTapGesture { handleTap(on: tx) }
                    .background {
                        if tx.id == selectedTransactionID {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.accentColor.opacity(0.18),
                                    Color.accentColor.opacity(0.10)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Rectangle().fill(Color.white)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func handleTap(on tx: EntityTransaction) {
        if selectedTransactionID == tx.id {
            selectedTransactionID = nil
        } else {
            selectedTransactionID = tx.id
        }
        transactionManager.selectedTransactions = ListTransactionsManager.shared.listTransactions
        if let id = selectedTransactionID, let selected = filteredTransactions.first(where: { $0.id == id }) {
            transactionManager.selectedTransactions = [selected]
            NotificationCenter.default.post(name: .transactionSelectionChanged, object: selected)
        }
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

        var immediateTx = SwiftUI.Transaction()
        immediateTx.disablesAnimations = true
        withTransaction(immediateTx) {
            selectedStart = Double(startDay)
            selectedEnd = Double(endDay)
        }

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

// MARK: - Extracted Row

private struct TransactionRow: View {
    let tx: EntityTransaction
    let isSelected: Bool
    let formatterPrice: NumberFormatter
    let colorManager: ColorManager

    var body: some View {
        let textColor = isSelected ? Color.white : colorManager.colorForTransaction(tx)
        
        VStack(alignment: .leading, spacing: 6) {
            topRow
            bottomRow
        }
        .foregroundColor(textColor)
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isSelected {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentColor.opacity(0.18),
                        Color.accentColor.opacity(0.10)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Rectangle().fill(Color.white)
            }
        }
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: isSelected ? 2 : 0)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.2) : .clear, radius: isSelected ? 4 : 0, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var topRow: some View {
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
    }

    private var bottomRow: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(tx.sousOperations.first?.libelle ?? "—")
                .frame(minWidth: 220, alignment: .leading)
            Text(tx.sousOperations.first?.category?.rubric?.name ?? "—")
                .frame(minWidth: 120, alignment: .leading)
            Text(tx.sousOperations.first?.category?.name ?? "—")
                .frame(minWidth: 140, alignment: .leading)
            let amountString = formatterPrice.string(from: NSNumber(value: tx.amount)) ?? "—"
            Text(amountString)
                .bold()
                .frame(minWidth: 160, alignment: .leading)
        }
    }
}


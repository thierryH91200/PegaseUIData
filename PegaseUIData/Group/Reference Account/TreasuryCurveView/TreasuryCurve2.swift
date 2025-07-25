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


struct TreasuryCurve: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var currentAccountManager: CurrentAccountManager
    @StateObject private var viewModel = TresuryLineViewModel()

    @Binding var allTransactions: [EntityTransaction]
    @State private var filteredTransactions: [EntityTransaction] = []

    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()

//    @State private var rotationAngle: Double = 0
    @AppStorage("enableSoundFeedback") private var enableSoundFeedback: Bool = true

    private var durationDays: Double {
        maxDate.timeIntervalSince(minDate) / 86400
    }

    private var totalAmount: Double {
        filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Treasury curve")
                    .font(.headline)
                    .padding()

                DGLineChartRepresentable(viewModel: viewModel,
                                         entries: viewModel.dataEntries)

                    .frame(width: geometry.size.width, height: 400)
                    .padding()
                    .onAppear {
                        refreshData(for: currentAccountManager.currentAccount)
                    }
                    .onChange(of: currentAccountManager.currentAccount) { _, newAccount in
                        refreshData(for: newAccount)
                    }

                GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected period : \(dateFromOffset(lowerValue)) → \(dateFromOffset(upperValue))")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        RangeSlider(
                            minValue: .constant(0),
                            maxValue: .constant(durationDays),
                            lowerValue: $lowerValue,
                            upperValue: $upperValue,
                            referenceDate: minDate,
                            transactionCount: filteredTransactions.count
                        )
                        .frame(height: 50)
                        .onChange(of: lowerValue) { _, _ in applyFilter() }
                        .onChange(of: upperValue) { _, _ in applyFilter() }

                        Text("\(selectedDays()) days — \(filteredTransactions.count) transaction\(filteredTransactions.count > 1 ? "s" : "") — Total: \(formattedAmount(totalAmount))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)

                        List(filteredTransactions, id: \.uuid) { transaction in
                            Text(transaction.sousOperations.first?.libelle ?? "N/A")
                        }
                        .frame(height: 150)
                    }
                    .padding(.top, 4)
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Helpers

    private func refreshData(for account: EntityAccount?) {
        guard let account = account else {
            allTransactions = []
            filteredTransactions = []
            return
        }

        DataContext.shared.context = modelContext
        allTransactions = ListTransactionsManager.shared
            .getAllData()
            .filter { $0.account == account }
            .sorted { $0.dateOperation < $1.dateOperation }

        guard let first = allTransactions.first?.dateOperation,
              let last = allTransactions.last?.dateOperation else {
            return
        }

        minDate = first
        maxDate = last
        lowerValue = 0
        upperValue = durationDays

        viewModel.listTransactions = allTransactions
        viewModel.lowerValue = lowerValue
        viewModel.upperValue = upperValue
        viewModel.updateChartData()

        applyFilter()
    }

    private func applyFilter() {
        let startDate = Calendar.current.date(byAdding: .day, value: Int(lowerValue), to: minDate) ?? minDate
        let endDate = Calendar.current.date(byAdding: .day, value: Int(upperValue), to: minDate) ?? maxDate

        filteredTransactions = allTransactions.filter {
            $0.dateOperation >= startDate && $0.dateOperation <= endDate
        }

        viewModel.lowerValue = lowerValue
        viewModel.upperValue = upperValue
        viewModel.updateChartData()
    }

    private func selectedDays() -> Int {
        Int(upperValue - lowerValue + 1)
    }

    private func dateFromOffset(_ offset: Double) -> String {
        let date = Calendar.current.date(byAdding: .day, value: Int(offset), to: minDate) ?? minDate
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


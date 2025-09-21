////
////  RecetteDepensePie2.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine

struct RecetteDepensePieView: View {
    @Binding var isVisible: Bool
    
    @State private var transactions: [EntityTransaction] = []
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()

    private let oneDay = 3600.0 * 24.0 // one day

    var body: some View {
        RecetteDepensePie(
            transactions: transactions,
            lowerValue: $lowerValue,
            upperValue: $upperValue,
            minDate: $minDate,
            maxDate: $maxDate
        )
        .task {
            await performFalseTask()
        }
        .onAppear {
            Task {
                await loadTransactions()
                minDate = transactions.first?.dateOperation ?? Date()
                lowerValue = 0
                maxDate = transactions.last?.dateOperation ?? Date()
                upperValue = maxDate.timeIntervalSince(minDate) / oneDay
            }
        }
    }

    private func performFalseTask() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isVisible = false
    }
    private func loadTransactions() async {
        transactions = ListTransactionsManager.shared.getAllData()
    }

}

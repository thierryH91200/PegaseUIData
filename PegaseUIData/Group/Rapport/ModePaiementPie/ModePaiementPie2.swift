////
////  ModePaiementPie2.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
//
import SwiftUI
import SwiftData
import DGCharts
import Combine


struct ModePaiementPieView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isVisible: Bool

    @State private var transactions: [EntityTransaction] = []
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 180
    @State private var minDate: Date = Calendar.current.date(byAdding: .day, value: -180, to: Date())!
    @State private var maxDate: Date = Date()

    var body: some View {
        ModePaiementView(
            transactions: transactions,
            lowerValue: $lowerValue,
            upperValue: $upperValue,
            minDate: $minDate,
            maxDate: $maxDate
        )
        .task {
            await loadTransactions()
        }
    }

    private func loadTransactions() async {
        
        transactions = ListTransactionsManager.shared.getAllData()
        printTag("[Pie] Transactions chargées: \(transactions.count)")
    }
}

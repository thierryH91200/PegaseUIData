//
//  RecetteDepenseBar2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct RecetteDepenseBarView: View {
    
    @Binding var isVisible: Bool
    
    @State private var transactions: [EntityTransaction] = []
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 180
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()

    var body: some View {
        RecetteDepenseView(
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
                    maxDate = transactions.last?.dateOperation ?? Date()
                }
            }
    }

    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
    private func loadTransactions() async {
        transactions = ListTransactionsManager.shared.getAllData()
        printTag("[Recette Pie] Transactions chargées: \(transactions.count)")
    }


}

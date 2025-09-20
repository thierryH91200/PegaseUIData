//
//  CatBar2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct CategorieBar1View: View {
    
    @Binding var isVisible: Bool
    @Binding var executed: Double
    @Binding var planned: Double
    @Binding var engaged: Double

    @State private var transactions: [EntityTransaction] = []
    @State private var allTransactions: [EntityTransaction] = []
    
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()

    
    var body: some View {
        
        SummaryView(
            planned: planned,
            engaged: engaged,
            executed: executed
        )

        CategorieBar1View1(transactions: transactions,
                           lowerValue: $lowerValue,
                           upperValue: $upperValue,
                           minDate: $minDate,
                           maxDate: $maxDate)
            .task {
                await performFalseTask()
            }
            .onAppear {
                transactions = ListTransactionsManager.shared.getAllData()
                allTransactions = transactions
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}

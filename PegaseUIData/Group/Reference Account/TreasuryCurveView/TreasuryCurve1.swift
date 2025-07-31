//
//  Untitled 2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct TreasuryCurveView: View {
    
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
        VStack(spacing: 0) {

            SummaryView(
                planned: planned,
                engaged: engaged,
                executed: executed
            )
            
            TreasuryCurve(allTransactions: $allTransactions)
                .task {
                    await performFalseTask()
                }
        }
        .onAppear {
            transactions = ListTransactionsManager.shared.getAllData().sorted(by: { $0.dateOperation < $1.dateOperation })

            // init des valeurs
            if let first = transactions.first?.dateOperation, let last = transactions.last?.dateOperation {
                let days = last.timeIntervalSince(first) / 86400
                lowerValue = 0
                upperValue = days
            }
        }

    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}

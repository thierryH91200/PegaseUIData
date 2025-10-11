////
////  Untitled 2.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
//
//import SwiftUI
//import SwiftData
//import DGCharts
//
//
//struct TreasuryCurveView: View {
//    
//    @Binding var dashboard: DashboardState
//    @State private var transactions: [EntityTransaction] = []
//    @State private var minDate: Date = Date()
//    @State private var maxDate: Date = Date()
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            TreasuryCurve(transactions: $transactions,
//                          dashboard: $dashboard,
//                          minDate: $minDate,
//                          maxDate: $maxDate)
//            .task {
//                await performFalseTask()
//            }
//        }
//        .onAppear {
//            Task { @MainActor in
//                await loadTransactions()
//            }
//        }
//    }
//    
//    private func performFalseTask() async {
//        // Exécuter une tâche asynchrone (par exemple, un délai)
//        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
//        dashboard.isVisible = true
//    }
//    
//    @MainActor
//    private func loadTransactions() async {
//        transactions = ListTransactionsManager.shared.getAllData()
//        minDate = transactions.first?.datePointage ?? Date()
//        maxDate = transactions.last?.datePointage ?? Date()
//    }
//}

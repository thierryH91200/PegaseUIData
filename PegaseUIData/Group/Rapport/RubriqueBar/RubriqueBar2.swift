//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct RubriqueBarView: View {
    @Binding var isVisible: Bool
    
    @State private var transactions: [EntityTransaction] = []
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()
    
    var body: some View {
        RubriqueBar(
            transactions: transactions,
            minDate: $minDate,
            maxDate: $maxDate
        )
        .task {
            await performFalseTask()
        }
        .onAppear {
            Task {
                await loadTransactions()
                transactions.sort { $0.dateOperation < $1.dateOperation }
                minDate = transactions.first?.dateOperation ?? Date()
                maxDate = transactions.last?.dateOperation ?? Date()
            }
        }
    }
    
    private func performFalseTask() async {
        // Exécute une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
    private func loadTransactions() async {
        transactions = ListTransactionsManager.shared.getAllData()
    }
    
}

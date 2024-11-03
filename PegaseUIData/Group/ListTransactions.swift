//
//  ListTransactions.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI

struct ListTransactions: View {

    @Binding var isVisible: Bool

    var body: some View {
        VStack {
            Text("ListTransactions")
                .font(.headline)
                .padding()
                .task {
                    await performTrueTask()
                }
            OutlineViewWrapper()
                .frame(minWidth: 200, minHeight: 300)
        }
    }
    private func performTrueTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = true
    }

}

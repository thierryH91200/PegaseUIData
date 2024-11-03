//
//  RubriqueBarView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI

struct RubriqueBarView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        Text("RubriqueBarView")
            .font(.title)
            .padding()
            .task {
                await performFalseTask()
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }

}

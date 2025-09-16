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
    
    var body: some View {
////        RecetteDepenseView()
//            .task {
//                await performFalseTask()
//            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }

}

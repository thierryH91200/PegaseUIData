//
//  RecetteDepensePie2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct RecetteDepensePieView: View {
    @Binding var isVisible: Bool

    var body: some View {
//        RecetteDepensePie()
//            .task {
//                await performFalseTask()
//            }
    }

    private func performFalseTask() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isVisible = false
    }
}

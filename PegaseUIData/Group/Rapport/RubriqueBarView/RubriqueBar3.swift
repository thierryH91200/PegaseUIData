//
//  Untitled 3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct RubriqueBar: View {
    
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = RubriqueBarViewModel()

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    
    @State private var chartViewRef: BarChartView?

    let currentAccount: EntityAccount? = nil

    var body: some View {
        VStack {
            Text("Rubrique Bar")
                .font(.headline)
                .padding()
            
            DGBarChartView(entries: viewModel.dataEntries,
                           labels: viewModel.labels,
                           chartViewRef: $chartViewRef)
                .frame(width: 600, height: 400)
                .padding()
            Spacer()
        }
        .onAppear {
            updatePieData()
        }

    }
    private func updatePieData() {
        
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
        let currentAccount = CurrentAccountManager.shared.getAccount()!
        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }


}

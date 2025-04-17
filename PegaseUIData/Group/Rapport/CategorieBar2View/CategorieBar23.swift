//
//  CategorieBar23.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


struct RubricColor : Hashable {
    var name: String
    var color  : NSColor
    
    init(name:String, color : NSColor) {
        self.name = name
        self.color = color
    }
}


struct CategorieBar2View2: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel = CategorieBar2ViewModel()

    @State private var minDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    @State private var maxDate = Date()

    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30
    @State private var chartViewRef: BarChartView?
    @State private var updateWorkItem: DispatchWorkItem?

    var body: some View {
        VStack {
            Text("CategorieBar2View2")
                .font(.headline)
                .padding()
            
            DGBarChartView(entries: viewModel.dataEntries,
                           labels: viewModel.labels,
                           chartViewRef: $chartViewRef)
                .frame(width: 600, height: 400)
                .padding()
            RangeSlider(minValue: 0,
                        maxValue: maxDate.timeIntervalSince(minDate) / (60 * 60 * 24),
                        lowerValue: $selectedStart,
                        upperValue: $selectedEnd)
                .frame(height: 30)

            Spacer()
        }
        .onAppear {
            let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
            let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
            let currentAccount = CurrentAccountManager.shared.getAccount()!
            viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
        }
        
        .onChange(of: selectedStart) { _, newValue in
            updateChartDebounced()
        }
        
        .onChange(of: selectedEnd) { _, newValue in
            updateChartDebounced()
        }
    }
    
    func updateChartDebounced() {
        updateWorkItem?.cancel()
        let workItem = DispatchWorkItem { self.updateChart() }
        updateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    private func updateChart() {
        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
        let currentAccount = CurrentAccountManager.shared.getAccount()!
        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
    }
}

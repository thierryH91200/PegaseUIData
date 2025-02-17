//
//  RecetteDepensePieView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import DGCharts

struct RecetteDepensePieView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        RecetteDepensePie()
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

struct DGPieChartView: NSViewRepresentable {
    let entries: [PieChartDataEntry]

    func makeNSView(context: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = PieChartDataSet(entries: entries, label: "Répartition des Dépenses")
        dataSet.colors = ChartColorTemplates.vordiplom() + ChartColorTemplates.joyful()
        dataSet.valueTextColor = NSUIColor.black
        dataSet.entryLabelColor = NSUIColor.black
        dataSet.sliceSpace = 2.0
        
        let data = PieChartData(dataSet: dataSet)
        chartView.data = data
        
        chartView.usePercentValuesEnabled = true
        chartView.drawHoleEnabled = false
        chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5)
        
        return chartView
    }

    func updateNSView(_ nsView: PieChartView, context: Context) {
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
}

struct RecetteDepensePie: View {
    var pieDataEntries: [PieChartDataEntry] = [
        PieChartDataEntry(value: 40, label: "Logement"),
        PieChartDataEntry(value: 25, label: "Transport"),
        PieChartDataEntry(value: 20, label: "Nourriture"),
        PieChartDataEntry(value: 15, label: "Autres")
    ]

    var body: some View {
        VStack {
            Text("RecetteDepensePie")
                .font(.headline)
                .padding()
            DGPieChartView(entries: pieDataEntries)
                .frame(width: 600, height: 400)
                .padding()
            Spacer()
        }
    }
}

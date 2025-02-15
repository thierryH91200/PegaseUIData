//
//  RubriqueBarView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import DGCharts

struct RubriqueBarView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        RubriqueBar()
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

struct DGBarChart5View5: NSViewRepresentable {
    
    let entries: [BarChartDataEntry]
    
    func makeNSView(context: Context) -> BarChartView {
        let chartView = BarChartView()
        chartView.noDataText = "Aucune donnée disponible"
        
        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()
        
        let data = BarChartData(dataSet: dataSet)
        chartView.data = data
        
        // Personnalisation du graphique
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.animate(yAxisDuration: 1.5)
        
        return chartView
    }
    
    func updateNSView(_ nsView: BarChartView, context: Context) {
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
}

struct RubriqueBar: View {
    var dataEntries: [BarChartDataEntry] = [
        BarChartDataEntry(x: 1.0, y: -500.0),
        BarChartDataEntry(x: 2.0, y: 900.0),
        BarChartDataEntry(x: 3.0, y: 300.0),
        BarChartDataEntry(x: 4.0, y: 1000.0),
        BarChartDataEntry(x: 5.0, y: -450.0)
    ]
    
    var body: some View {
        VStack {
            Text("ModePaiementView")
                .font(.headline)
                .padding()
            DGBarChart2View2(entries: dataEntries)
                .frame(width: 600, height: 400)
                .padding()
            Spacer()
        }
    }
}

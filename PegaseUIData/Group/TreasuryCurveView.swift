//
//  TreasuryCurveView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 30/10/2024.
//

import SwiftUI
import DGCharts



struct TreasuryCurveView: View {
    
    @Binding var isVisible: Bool

    var body: some View {
        TreasuryCurve()
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

struct DGLineChartView: NSViewRepresentable {
    let entries: [ChartDataEntry]

    func makeNSView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = LineChartDataSet(entries: entries, label: "Évolution Mensuelle")
        dataSet.colors = [NSUIColor.systemBlue]
        dataSet.circleColors = [NSUIColor.systemRed]
        dataSet.circleRadius = 5
        dataSet.lineWidth = 2
        dataSet.drawValuesEnabled = true
        
        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
        
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        
        return chartView
    }

    func updateNSView(_ nsView: LineChartView, context: Context) {
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
}

struct TreasuryCurve: View {
    var lineDataEntries: [ChartDataEntry] = [
        ChartDataEntry(x: 1.0, y: 200.0),
        ChartDataEntry(x: 2.0, y: 450.0),
        ChartDataEntry(x: 3.0, y: 300.0),
        ChartDataEntry(x: 4.0, y: 700.0),
        ChartDataEntry(x: 5.0, y: 600.0)
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Sales Line Chart")
                    .font(.headline)
                    .padding()
                DGLineChartView(entries: lineDataEntries)
                    .frame(width: geometry.size.width, height: 400)
                    .padding()
                Spacer()
            }
        }
    }
}

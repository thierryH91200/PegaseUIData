//
//  Untitled 4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts

struct DGLineChartView: NSViewRepresentable {
    let entries: [ChartDataEntry]
//    @Binding var chartViewRef: LineChartView?

    @State private var selectedType: String = "Tous"
    
    @State var chartView = LineChartView()

    private let transactionTypes = ["Tous", "Achat", "Salaire", "Virement"]

    func makeNSView(context: Context) -> LineChartView {

        chartView.noDataText = String(localized:"No chart data available.")
        let safeEntries = entries.isEmpty ? [ChartDataEntry(x: 0, y: 1), ChartDataEntry(x: 1, y: 2)] : entries
        
        let dataSet = LineChartDataSet(entries: safeEntries, label: "Évolution Mensuelle")
        
        dataSet.colors = [NSUIColor.systemBlue]
        dataSet.circleColors = [NSUIColor.systemRed]
        dataSet.circleRadius = 5
        dataSet.lineWidth = 2
        dataSet.drawValuesEnabled = true
        
        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
        
        chartView.xAxis.axisMinimum = 0
        chartView.xAxis.axisMaximum = 200  // éviter plage nulle
        
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.granularity = 1
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
        
        if let minX = entries.map(\.x).min(),
           let maxX = entries.map(\.x).max(),
           minX != maxX {
            chartView.xAxis.axisMinimum = minX
            chartView.xAxis.axisMaximum = maxX
        } else {
            chartView.xAxis.axisMinimum = 0
            chartView.xAxis.axisMaximum = 200
        }
        return chartView
    }

    func updateNSView(_ nsView: LineChartView, context: Context) {

        let dataSet = LineChartDataSet(entries: entries, label: "Évolution Mensuelle")
        let data = LineChartData(dataSet: dataSet)
        nsView.data = data

        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }

    func setDataSet (values : [ChartDataEntry], label: String, color : NSColor) -> LineChartDataSet
    {
        var dataSet =  LineChartDataSet()
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .currency
        pFormatter.maximumFractionDigits = 2
        
        dataSet = LineChartDataSet(entries: values, label: label)
        dataSet.axisDependency = .left
        dataSet.mode = .stepped
        dataSet.valueTextColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        dataSet.lineWidth = 1.5
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = true
        dataSet.valueFormatter = DefaultValueFormatter(formatter: pFormatter  )
        
        dataSet.drawFilledEnabled = false //true
        dataSet.fillAlpha = 0.26
        dataSet.fillColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        dataSet.highlightColor = #colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1)
        dataSet.highlightLineWidth = 4.0
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.formSize = 15.0
        dataSet.colors = [color]
        return dataSet
    }
}

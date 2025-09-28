//
//  Untitled 4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct DGBarChart5Representable: NSViewRepresentable {
    
    let entries: [BarChartDataEntry]
    let title: String
    let labels: [String]
    
    let chartView = BarChartView()

    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }


    func makeNSView(context: Context) -> BarChartView {
        
        chartView.delegate = context.coordinator
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()
        
        let data = BarChartData(dataSet: dataSet)
        chartView.data = data
        
        // Personnalisation du graphique
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelCount = labels.count
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.animate(yAxisDuration: 1.5)
        
        return chartView
    }
    
    func updateNSView(_ nsView: BarChartView, context: Context) {
        nsView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        nsView.xAxis.labelCount = labels.count
        nsView.xAxis.granularity = 1
        nsView.xAxis.drawGridLinesEnabled = false
        
        if let data = nsView.data, let set = data.dataSets.first as? BarChartDataSet {
            set.replaceEntries(entries)
            data.notifyDataChanged()
            nsView.notifyDataSetChanged()
        } else {
            let dataSet = BarChartDataSet(entries: entries, label: "Recette Depense Bar")
            dataSet.colors = ChartColorTemplates.colorful()
            nsView.data = BarChartData(dataSet: dataSet)
            nsView.notifyDataSetChanged()
        }
    }
    
    final class Coordinator: NSObject, ChartViewDelegate {
        var parent: DGBarChart5Representable
        var isUpdating = false
        
        init(parent: DGBarChart5Representable) {
            self.parent = parent
        }
        
        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            
            let index = Int(highlight.x)
            let entryX = entry.x
            let dataSetIndex = Int(highlight.dataSetIndex)
            
            printTag("index: \(index), entryX: \(entryX), dataSetIndex: \(dataSetIndex) ")

        }
        
        public func chartValueNothingSelected(_ chartView: ChartViewBase)
        {
        }

    }

}


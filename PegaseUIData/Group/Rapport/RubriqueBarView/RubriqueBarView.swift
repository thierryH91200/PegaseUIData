//
//  RubriqueBarView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import SwiftData
import DGCharts




//struct DGBarChart5View5: NSViewRepresentable {
//    
//    let entries: [BarChartDataEntry]
//    
//    func makeNSView(context: Context) -> BarChartView {
//        let chartView = BarChartView()
//        chartView.noDataText = String(localized:"No chart data available.")
//        
//        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
//        dataSet.colors = ChartColorTemplates.colorful()
//        
//        let data = BarChartData(dataSet: dataSet)
//        chartView.data = data
//        
//        // Personnalisation du graphique
//        chartView.xAxis.labelPosition = .bottom
//        chartView.xAxis.granularity = 1
//        chartView.animate(yAxisDuration: 1.5)
//        
//        return chartView
//    }
//    
//    func updateNSView(_ nsView: BarChartView, context: Context) {
//        nsView.data?.notifyDataChanged()
//        nsView.notifyDataSetChanged()
//    }
//}


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


//struct DGPieChart1View1: NSViewRepresentable {
//    let entries: [PieChartDataEntry]
//
//    func makeNSView(context: Context) -> PieChartView {
//        let chartView = PieChartView()
//        chartView.noDataText = String(localized:"No chart data available.")
//        
//        let dataSet = PieChartDataSet(entries: entries, label: "Répartition des Rubriques")
//        dataSet.colors = ChartColorTemplates.vordiplom() + ChartColorTemplates.joyful()
//        dataSet.valueTextColor = .black
//        dataSet.entryLabelColor = .black
//        dataSet.sliceSpace = 2.0
//        
//        let data = PieChartData(dataSet: dataSet)
//        chartView.data = data
//        
//        chartView.usePercentValuesEnabled = true
//        chartView.drawHoleEnabled = false
//        chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5)
//        
//        return chartView
//    }
//
//    func updateNSView(_ nsView: PieChartView, context: Context) {
//        nsView.data?.notifyDataChanged()
//        nsView.notifyDataSetChanged()
//    }
//}

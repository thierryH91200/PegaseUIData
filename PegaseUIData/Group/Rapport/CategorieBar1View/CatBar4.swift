//
//  CatBar4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts

struct DGBarChartView: NSViewRepresentable {
    
    @Environment(\.modelContext) var modelContext

    let entries: [BarChartDataEntry]
    let labels: [String]
    @Binding var chartViewRef: BarChartView?
    
    @State var chartView = BarChartView()
    
    @State var resultArray = [DataGraph]()
    @State var label  = [String]()

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func makeNSView(context: Context) -> BarChartView {

        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()

        let data = BarChartData(dataSet: dataSet)
        chartView.data = data

        // Personnalisation du graphique
        initChart()
        chartView.animate(yAxisDuration: 1.5)
        
        self.chartViewRef = chartView
        return chartView
    }

    func updateNSView(_ nsView: BarChartView, context: Context) {
        // Crée un nouveau DataSet avec les nouvelles entrées
        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()
        dataSet.drawValuesEnabled = true
 
        let data = BarChartData(dataSet: dataSet)
//        data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
        data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
        data.setValueTextColor(NSColor.black)
        
        let formatter = CurrencyValueFormatter1()
        data.setValueFormatter(formatter)
        data.setValueFont(.systemFont(ofSize: 10))
        data.setValueTextColor(.black)
 
        nsView.data = data
        nsView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
    
    func initChart() {
        
        chartView.xAxis.valueFormatter = CurrencyValueFormatter()
        
        // MARK: General
//        chartView.delegate = self
        
        chartView.drawBarShadowEnabled      = false

        chartView.drawValueAboveBarEnabled  = true
        chartView.maxVisibleCount           = 60
        chartView.drawGridBackgroundEnabled = true
        chartView.drawBordersEnabled        = true
        chartView.gridBackgroundColor       = .windowBackgroundColor
        chartView.fitBars                   = true

        chartView.pinchZoomEnabled          = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.dragEnabled               = false
        chartView.noDataText = String(localized:"No chart data available.")
        
        // MARK: Axis
        setUpAxis()
        
        // MARK: Legend
        initializeLegend(chartView.legend)
        chartView.legend.enabled = false
        
        // MARK: Description
        let bounds                           = chartView.bounds
        let point    = CGPoint( x: bounds.width / 2, y: bounds.height * 0.25)
        chartView.chartDescription.enabled  = true
        chartView.chartDescription.text     = "Rubric"
        chartView.chartDescription.position = point
        chartView.chartDescription.font     = NSFont(name: "HelveticaNeue-Light", size: CGFloat(24.0))!
    }
    
    func initializeLegend(_ legend: Legend) {
        
        legend.horizontalAlignment           = .left
        legend.verticalAlignment             = .top
        legend.orientation                   = .vertical
        legend.drawInside                    = true
        legend.form                          = .square
        legend.formSize                      = 9.0
        legend.font                          = NSFont.systemFont(ofSize: CGFloat(11.0))
        legend.xEntrySpace                   = 4.0
    }
    
    func setUpAxis() {
        // MARK: xAxis
        let xAxis                      = chartView.xAxis
        xAxis.labelPosition            = .bottom
        xAxis.labelFont                = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        xAxis.drawGridLinesEnabled     = true
        xAxis.granularity              = 1
        xAxis.enabled                  = true
        xAxis.labelTextColor           = .labelColor
        xAxis.labelCount               = 10
        xAxis.valueFormatter           = CurrencyValueFormatter()

        // MARK: leftAxis
        let leftAxis                   = chartView.leftAxis
        leftAxis.labelFont             = NSFont(name: "HelveticaNeue-Light", size: CGFloat(10.0))!
        leftAxis.labelCount            = 12
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.granularityEnabled    = true
        leftAxis.granularity           = 1
        leftAxis.valueFormatter        = CurrencyValueFormatter()
        leftAxis.labelTextColor        = .labelColor

        // MARK: rightAxis
        chartView.rightAxis.enabled    = false
    }
    
}

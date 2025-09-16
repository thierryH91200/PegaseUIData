//
//  CategorieBar24.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct DGBarChart2Representable: NSViewRepresentable {
    
    let entries: [BarChartDataEntry]
    let labels: [String]
    @Binding var chartViewRef: BarChartView?
    
    @Environment(\.modelContext) var modelContext
    
    @State var chartView = BarChartView()
    @State var resultArray = [DataGraph]()
    @State var label  = [String]()
    
    @State var numericIDs  = [String]()
    var arrayUniqueRubriques   = [RubricColor]()

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    let formatterDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM/yyyy", options: 0, locale: Locale.current)
        return fmt
    }()
    
    func makeNSView(context: Context) -> BarChartView {
        chartView.noDataText = String(localized:"No chart data available.")
        
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
    
    private func initChart() {
        
        // MARK: General
        chartView.borderColor = .controlBackgroundColor
        chartView.gridBackgroundColor = .gridColor
        chartView.drawBarShadowEnabled      = false
        chartView.drawValueAboveBarEnabled  = false
        chartView.maxVisibleCount           = 60
        chartView.drawGridBackgroundEnabled = true
        //        chartView.backgroundColor = .windowBackgroundColor
        chartView.gridBackgroundColor = .windowBackgroundColor
        
        chartView.fitBars                   = true
        chartView.drawBordersEnabled = true
        
        chartView.pinchZoomEnabled          = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.dragEnabled               = false
        chartView.noDataText = String(localized:"No chart data available.")
        
        // MARK: xAxis
        let xAxis                      = chartView.xAxis
        xAxis.centerAxisLabelsEnabled = true
        xAxis.granularity              = 1.0
        xAxis.gridLineWidth = 2.0
        xAxis.labelCount = 20
        xAxis.labelFont                = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        xAxis.labelPosition            = .bottom
        xAxis.labelTextColor           = .labelColor
        
        // MARK: leftAxis
        let leftAxis                   = chartView.leftAxis
        leftAxis.labelFont             = NSFont(name: "HelveticaNeue-Light", size: CGFloat(10.0))!
        leftAxis.labelTextColor        = .labelColor
        
        leftAxis.labelCount            = 10
        leftAxis.granularityEnabled    = true
        leftAxis.granularity           = 1
        leftAxis.valueFormatter        = CurrencyValueFormatter()
        
        // MARK: rightAxis
        chartView.rightAxis.enabled    = false
        
        // MARK: legend
        initializeLegend(chartView.legend)
        
        // MARK: description
        chartView.chartDescription.enabled  = false
        
    }
    
    func initializeLegend(_ legend: Legend) {
        legend.horizontalAlignment           = .left
        legend.verticalAlignment             = .bottom
        legend.orientation                   = .vertical
        legend.drawInside                    = false
        legend.form                          = .square
        legend.formSize                      = 9.0
        legend.font                          = NSFont.systemFont(ofSize: CGFloat(11.0))
        legend.xEntrySpace                   = 4.0
        legend.textColor = NSColor.labelColor
        legend.enabled = true
        
    }
    
//    private func setDataCount()
//    {
//        guard resultArray.isEmpty == false else {
//            chartView.data = nil
//            chartView.data?.notifyDataChanged()
//            chartView.notifyDataSetChanged()
//            return }
//
//        let groupSpace = 0.2
//        let barSpace = 0.0
//        let barWidth = Double(0.8 / Double(arrayUniqueRubriques.count))
//
//        // MARK: BarChartDataEntry
//        var entries = [BarChartDataEntry]()
//
//        // MARK: ChartDataSet
//        let dataSets = (0 ..< arrayUniqueRubriques.count).map { (i) -> BarChartDataSet in
//
//            let dataRubrique = resultArray.filter({ $0.name == arrayUniqueRubriques[i].name  })
//            entries.removeAll()
//            for i in 0 ..< dataRubrique.count {
//                entries.append(BarChartDataEntry(x: Double(i), y: abs(dataRubrique[i].value)))
//            }
//
//            let dataSet = BarChartDataSet(entries: entries, label: dataRubrique[0].name)
//            dataSet.colors = [dataRubrique[0].color]
//            dataSet.drawValuesEnabled = false
//            return dataSet
//        }
//
//        let allKeyIDs = Set<String>(resultArray.map { $0.section })
//        self.numericIDs = allKeyIDs.sorted(by: { $0 < $1 })
//        var labelDate = [String]()
//
//        for numericID in self.numericIDs {
//            let numericSection = Int(numericID)
//            var components = DateComponents()
//            components.year = numericSection! / 100
//            components.month = numericSection! % 100
//            let date = Calendar.current.date(from: components)
//            let dateString = formatterDate.string(from: date!)
//            labelDate.append(dateString)
//        }
//
//        // MARK: BarChartData
//        let data = BarChartData(dataSets: dataSets)
//
//        data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//        data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
//        data.setValueTextColor(NSColor.black)
//
//        data.barWidth = barWidth
//        data.groupBars( fromX: Double(0), groupSpace: groupSpace, barSpace: barSpace)
//
//        let groupCount = allKeyIDs.count + 1
//        let startYear = 0
//        let endYear = startYear + groupCount
//
//        self.chartView.xAxis.axisMinimum = Double(startYear)
//        self.chartView.xAxis.axisMaximum = Double(endYear)
//        self.chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labelDate)
//
//        self.chartView.data = data
//
//    }
}

////
////  CatBar4.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 16/04/2025.
////

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct DGBarChart7Representable: NSViewRepresentable {
    
    @ObservedObject var viewModel: CategorieBar1ViewModel
    let entries: [BarChartDataEntry]
    
    let hourSeconds = 3600.0 * 24.0 // one day
    let chartView = BarChartView()

    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, ChartViewDelegate {
        var parent: DGBarChart7Representable
        var isUpdating = false

        init(parent: DGBarChart7Representable) {
            self.parent = parent
        }

        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            let index = Int(highlight.x)
            let entryX = entry.x
            let dataSetIndex = Int(highlight.dataSetIndex)
            
            printTag("index: \(index), entryX: \(entryX), dataSetIndex: \(dataSetIndex) ")
//            let firstDate = parent.lowerValue
            
            if parent.entries.indices.contains(index) {
                print("Selected \(parent.entries[index])")
            } else {
                print("Selected index out of range: \(index)")
            }
        }
        
        public func chartValueNothingSelected(_ chartView: ChartViewBase)
        {
        }
    }


    func makeNSView(context: Context) -> BarChartView {
        
        chartView.delegate = context.coordinator
        initChart(on: chartView)

        chartView.chartDescription.enabled = false
        initializeLegend(chartView.legend)
        chartView.legend.enabled = true

        return chartView
    }

    func updateNSView(_ nsView: BarChartView, context: Context) {
        DispatchQueue.main.async {
            let newData = self.viewModel.resultArray
            self.setData(on: nsView, with: newData)
        }
    }
    
    func setData(on chartView: BarChartView, with data: [DataGraph]) {
        // If there's no data, clear the chart and return
        guard !data.isEmpty else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return
        }

        // Build entries and colors
        var entries: [BarChartDataEntry] = []
        var colors: [NSColor] = []
        var labels: [String] = []

        for (i, item) in data.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
            labels.append(item.name)
            colors.append(item.color)
        }

        // Configure xAxis labels
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelCount = labels.count

        // Create or update dataset
        if chartView.data == nil {
            let dataSet = BarChartDataSet(entries: entries, label: "Rubric")
            dataSet.colors = colors
            dataSet.drawValuesEnabled = true
            dataSet.barBorderWidth = 0.1
            dataSet.valueFormatter = DefaultValueFormatter(formatter: viewModel.formatterPrice)

            let barData = BarChartData(dataSets: [dataSet])
            barData.setValueFormatter(DefaultValueFormatter(formatter: viewModel.formatterPrice))
            barData.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
            barData.setValueTextColor(NSColor.labelColor)

            chartView.data = barData
        } else {
            if let set1 = chartView.data?.dataSets.first as? BarChartDataSet {
                set1.colors = colors
                set1.replaceEntries(entries)
            }
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
        }
    }
    
    func initChart(on chartView: BarChartView) {
        
        chartView.xAxis.valueFormatter = CurrencyValueFormatter()
        
        // MARK: General
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
        setUpAxis(chartView: chartView)
        
        // MARK: Legend
//        initializeLegend(chartView.legend)
//        chartView.legend.enabled = false
        
        // MARK: Description
        let bounds                           = chartView.bounds
        let point    = CGPoint( x: bounds.width / 2, y: bounds.height * 0.25)
        chartView.chartDescription.enabled  = true
        chartView.chartDescription.text     = "Rubric"
        chartView.chartDescription.position = point
        chartView.chartDescription.font     = NSFont(name: "HelveticaNeue-Light", size: CGFloat(24.0))!
    }
    
    func initializeLegend(_ legend: Legend) {
        
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        legend.textColor = NSColor.labelColor

        
//        legend.horizontalAlignment           = .left
//        legend.verticalAlignment             = .top
//        legend.orientation                   = .vertical
//        legend.drawInside                    = true
//        legend.form                          = .square
//        legend.formSize                      = 9.0
//        legend.font                          = NSFont.systemFont(ofSize: CGFloat(11.0))
//        legend.xEntrySpace                   = 4.0
    }
    
    func setUpAxis(chartView: BarChartView) {
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

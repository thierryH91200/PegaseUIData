//////
//////  CatBar4.swift
//////  PegaseUIData
//////
//////  Created by Thierry hentic on 16/04/2025.
//////
//
//import SwiftUI
//import SwiftData
//import DGCharts
//
//
//extension Notification.Name {
//    static let BarChart7NeedsRefresh = Notification.Name("BarChart7NeedsRefresh")
//}
//
//final class NumberFormatterAxisValueFormatter: AxisValueFormatter {
//    private let formatter: NumberFormatter
//    init(formatter: NumberFormatter) { self.formatter = formatter }
//    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
//        return formatter.string(from: NSNumber(value: value)) ?? ""
//    }
//}
//
//struct DGBarChart7Representable: NSViewRepresentable {
//    
//    let entries: [BarChartDataEntry]
//    let title: String
//    let labels: [String]
//    let data : BarChartData?
//    
//    @Binding var lowerValue: Double
//    @Binding var upperValue: Double
//    
//    // Called when a bar is tapped. Provides the selected index and its associated DataGraph.
//    var onSelectBar: ((Int, DataGraph) -> Void)? = nil
//    // Called when selection is cleared (no bar selected). Use to clear displayed transactions.
//    var onClearSelection: (() -> Void)? = nil
//    
//    let items: [DataGraph]
//    
//    let formatterPrice: NumberFormatter = {
//        let _formatter = NumberFormatter()
//        _formatter.locale = Locale.current
//        _formatter.numberStyle = .currency
//        return _formatter
//    }()
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//    
//    func makeNSView(context: Context) -> BarChartView {
//        
//        let chartView = BarChartView()
//
//        chartView.delegate = context.coordinator
//        context.coordinator.chartView = chartView
//        
//        configure(chartView) // voir ci-dessous
//        if let chartData = makeChartData() {
//            chartView.data = chartData
//        } else {
//            chartView.data = nil
//        }
//
//        return chartView
//    }
//    
//    func updateNSView(_ chartView: BarChartView, context: Context) {
//        context.coordinator.parent = self
//
//        // Keep axis config in sync
//        let xAxis = chartView.xAxis
//        xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
//
//        let chartData = makeChartData()
//        chartView.data = chartData
//        chartView.fitBars = true
//        DispatchQueue.main.async {
//            chartData?.notifyDataChanged()
//            chartView.notifyDataSetChanged()
//        }
//    }
//    
//    private func makeChartData() -> BarChartData? {
//        if let provided = data {
//            return provided
//        }
//        guard !entries.isEmpty else { return nil }
//        let dataSet = BarChartDataSet(entries: entries, label: title)
//        dataSet.colors = ChartColorTemplates.colorful()
//        return BarChartData(dataSet: dataSet)
//    }
//
//    func setData(on chartView: BarChartView, with data: [DataGraph]) {
//        // If there's no data, clear the chart and return
//        guard !data.isEmpty else {
//            chartView.data = nil
//            chartView.notifyDataSetChanged()
//            return
//        }
//
//        // Build entries and colors
//        var entries: [BarChartDataEntry] = []
//        var colors: [NSColor] = []
//        var labels: [String] = []
//
//        for (i, item) in data.enumerated() {
//            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
//            labels.append(item.name)
//            colors.append(item.color)
//        }
//
//        // Configure xAxis labels
//        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
//        chartView.xAxis.labelCount = max(1, labels.count)
//        chartView.leftAxis.valueFormatter = NumberFormatterAxisValueFormatter(formatter: formatterPrice)
//
//        // Create or update dataset
//        if chartView.data == nil {
//            let dataSet = BarChartDataSet(entries: entries, label: "Rubric")
//            dataSet.colors = colors
//            dataSet.drawValuesEnabled = true
//            dataSet.barBorderWidth = 0.1
//            dataSet.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//
//            let data = BarChartData(dataSets: [dataSet])
//            data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//            let valueFont = NSFont(name: "HelveticaNeue-Light", size: 11) ?? NSFont.systemFont(ofSize: 11, weight: .light)
//            data.setValueFont(valueFont)
//            data.setValueTextColor(NSColor.labelColor)
//
//            chartView.data = data
//        } else {
//            if let set1 = chartView.data?.dataSets.first as? BarChartDataSet {
//                set1.colors = colors
//                set1.replaceEntries(entries)
//                set1.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//            }
//            chartView.data?.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//            chartView.data?.notifyDataChanged()
//            chartView.notifyDataSetChanged()
//        }
//    }
//
//    @MainActor
//    final class Coordinator: NSObject, ChartViewDelegate {
//        var parent: DGBarChart7Representable
//        weak var chartView: BarChartView?
//
//        init(parent: DGBarChart7Representable) {
//            self.parent = parent
//            super.init()
//        }
//
//        deinit {
//            NotificationCenter.default.removeObserver(self)
//        }
//
//        func chartValueSelected(_ chartView: ChartViewBase,
//                                entry: ChartDataEntry,
//                                highlight: Highlight) {
//            let index = Int(round(highlight.x))
//            if parent.items.indices.contains(index) {
//                let item = parent.items[index]
//                parent.onSelectBar?(index, item)
//            }
//        }
//
//        func chartValueNothingSelected(_ chartView: ChartViewBase) {
////            parent.onClearSelection?()
//            guard !ListTransactionsManager.shared.listTransactions.isEmpty else { return }
//            ListTransactionsManager.shared.listTransactions = []
//        }
//    }
//
//    func configure(_ chartView: BarChartView) {
//        
//        // MARK: General
//        chartView.drawBarShadowEnabled      = false
//        chartView.autoScaleMinMaxEnabled = true
//        chartView.drawValueAboveBarEnabled  = true
//        chartView.maxVisibleCount           = 60
//        chartView.drawGridBackgroundEnabled = true
//        chartView.drawBordersEnabled        = true
//        chartView.gridBackgroundColor       = .windowBackgroundColor
//        chartView.fitBars                   = true
//        chartView.highlightPerTapEnabled   = true
//        chartView.highlightFullBarEnabled  = true
//
////        chartView.highlightPerTapEnabled   = true
////        chartView.highlightFullBarEnabled  = true
//
//        chartView.pinchZoomEnabled          = false
//        chartView.doubleTapToZoomEnabled    = false
//        chartView.dragEnabled               = false
//        chartView.noDataText = String(localized:"No chart data available.")
//        
//        // MARK: Axis
//        setUpAxis(chartView: chartView)
//        
//        // MARK: Legend
//        initializeLegend(chartView.legend)
//        
//        // MARK: Description
//        chartView.chartDescription.enabled = false
//    }
//    
//    func initializeLegend(_ legend: Legend) {
//        
//        legend.horizontalAlignment = .left
//        legend.verticalAlignment = .top
//        legend.orientation = .vertical
//        let font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0)) ?? NSFont.systemFont(ofSize: 14, weight: .light)
//        legend.font = font
//        legend.textColor = NSColor.labelColor
//    }
//    
//    func setUpAxis(chartView: BarChartView) {
//        // MARK: xAxis
//        let xAxis = chartView.xAxis
//        xAxis.labelPosition            = .bottom
//        xAxis.labelFont                = NSFont.systemFont(ofSize: 14, weight: .light)
//        xAxis.drawGridLinesEnabled     = true
//        xAxis.granularity              = 1
//        xAxis.enabled                  = true
//        xAxis.labelTextColor           = .labelColor
//        
//        // MARK: leftAxis
//        let leftAxis                   = chartView.leftAxis
//        leftAxis.labelFont = NSFont(name: "HelveticaNeue-Light", size: 10) ?? NSFont.systemFont(ofSize: 10, weight: .light)
//        leftAxis.labelCount            = 12
//        leftAxis.drawGridLinesEnabled  = true
//        leftAxis.granularityEnabled    = true
//        leftAxis.granularity           = 1
//        leftAxis.valueFormatter        = CurrencyValueFormatter()
//        leftAxis.labelTextColor        = .labelColor
//
//        // MARK: rightAxis
//        chartView.rightAxis.enabled    = false
//    }
//    
//}

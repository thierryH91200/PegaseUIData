////
////  RecetteDepenseBar4.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 17/04/2025.
////
import SwiftUI
import SwiftData
import DGCharts
import Combine
import SwiftDate



struct DGBarChart4Representable: NSViewRepresentable {
    
    let entries: [BarChartDataEntry]
    let title: String
    let labels: [String]
    let data : BarChartData?
    
    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    
    @State var chartView : BarChartView = BarChartView()

    
    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    let formatterDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MM yy", options: 0, locale: Locale.current)
        return fmt
    }()

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, ChartViewDelegate {
        var parent: DGBarChart4Representable
        var isUpdating = false

        init(parent: DGBarChart4Representable) {
            self.parent = parent
        }

        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            
            var startDate = Date()
            var endDate = Date()
            
            let index = Int(highlight.x)
            let entryX = entry.x
            let dataSetIndex = Int(highlight.dataSetIndex)
            
            printTag("index: \(index), entryX: \(entryX), dataSetIndex: \(dataSetIndex) ")
            let lowerValue = parent.lowerValue
            
            let transactions = ListTransactionsManager.shared.getAllData()
            let minDate = transactions.first?.dateOperation ?? Date()
//            let maxDate = transactions.last?.dateOperation ?? Date()
            


            if let date = Calendar.current.date(byAdding: .day, value: Int(lowerValue), to: minDate) {
                print(date) // ✅ Date obtenue
                
                startDate = date.startOfMonth()
                endDate = date.endOfMonth()
            }
            
            let transactions1 = ListTransactionsManager.shared.getAllData(from: startDate, to:endDate)
            
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
        chartView.noDataText = String(localized:"No chart data available.")
        
        initChart()
        let dataSet = BarChartDataSet(entries: entries, label: "Categorie Bar1")
        dataSet.colors = ChartColorTemplates.colorful()
        
        let data = BarChartData(dataSet: dataSet)
        chartView.data = data

        return chartView
    }
    
    func updateNSView(_ chartView: BarChartView, context: Context) {
        context.coordinator.parent = self

        // Keep axis config in sync
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)
        chartView.xAxis.labelCount = labels.count
        chartView.xAxis.granularity = 1
        chartView.xAxis.drawGridLinesEnabled = false

        if entries.isEmpty {
            chartView.data = nil
            chartView.fitBars = true

            DispatchQueue.main.async {
                chartView.notifyDataSetChanged()
            }
            return
        }

        chartView.data = data
        chartView.fitBars = true
        DispatchQueue.main.async {
            data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
        }
    }
        
    private func initChart() {
            
        // MARK: General
        chartView.drawBarShadowEnabled      = false
        chartView.drawValueAboveBarEnabled  = true
        chartView.maxVisibleCount           = 60
        chartView.drawBordersEnabled        = true
        chartView.drawGridBackgroundEnabled = true
        chartView.gridBackgroundColor       = .windowBackgroundColor
        chartView.fitBars                   = true
        
        chartView.pinchZoomEnabled          = false
        chartView.doubleTapToZoomEnabled    = false
        chartView.dragEnabled               = false
        chartView.noDataText = "No chart Data Available"
        
        //             MARK: xAxis
        let xAxis            = chartView.xAxis
        xAxis.centerAxisLabelsEnabled = true
        xAxis.drawGridLinesEnabled    = true
        xAxis.granularity = 1.0
        xAxis.gridLineWidth = 2.0
        xAxis.labelCount = 20
        xAxis.labelFont      = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .labelColor
        
//        xAxis.axisMinimum = -0.25
//        xAxis.axisMaximum = Double(labels.count) + 0.25
        xAxis.axisMinimum = 0
        xAxis.axisMaximum = Double(labels.count)

        
        //             MARK: leftAxis
        let leftAxis                   = chartView.leftAxis
        leftAxis.labelFont             = NSFont(name: "HelveticaNeue-Light", size: CGFloat(10.0))!
        leftAxis.labelCount            = 6
        leftAxis.drawGridLinesEnabled  = true
        leftAxis.granularityEnabled    = true
        leftAxis.granularity           = 1
        leftAxis.valueFormatter        = CurrencyValueFormatter()
        leftAxis.labelTextColor        = .labelColor
        
        // MARK: rightAxis
        chartView.rightAxis.enabled    = false
        
        //             MARK: legend
        let legend = chartView.legend
        legend.horizontalAlignment = .right
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.drawInside                    = true
        legend.xOffset = 10.0
        legend.yEntrySpace = 0.0
        legend.font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!
        legend.textColor = .labelColor
        
        //        MARK: description
        chartView.chartDescription.enabled  = false
    }
    
    
}

extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: 0), to: self.startOfMonth())!
    }
}



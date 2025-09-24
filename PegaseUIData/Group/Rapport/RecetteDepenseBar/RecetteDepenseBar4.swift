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
        
        chartView = BarChartView()
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

        // Do not fetch or mutate any SwiftUI-observed state here.
        // Only reflect the current inputs (entries/labels) into the chart view.
        if entries.isEmpty {
            chartView.data = nil
            DispatchQueue.main.async {
                chartView.notifyDataSetChanged()
            }
            return
        }

//        if let data = chartView.data, data.dataSetCount > 0,
//           let existing = data.dataSets.first as? BarChartDataSet {
//            existing.replaceEntries(entries)
//            existing.label = title
//            existing.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//            DispatchQueue.main.async {
//                data.notifyDataChanged()
//                chartView.notifyDataSetChanged()
//            }
//        } else {
//            let dataSet = BarChartDataSet(entries: entries, label: title)
//            dataSet.colors = ChartColorTemplates.colorful()
//            dataSet.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//
//            let data = BarChartData(dataSet: dataSet)
//            data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//            data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(8.0))!)
//            data.setValueTextColor(.black)

            chartView.data = data
            DispatchQueue.main.async {
                chartView.notifyDataSetChanged()
            }
//        }
    }
    
//    private func computeChartData(startDate: Date, endDate: Date) -> (expense: [DataGraph], income: [DataGraph]) {
//        let listTransactions = ListTransactionsManager.shared.getAllData(from: startDate, to: endDate)
//
//        var dataArray = [DataGraph]()
//        for listTransaction in listTransactions {
//            let value = listTransaction.amount
//            let id   = listTransaction.sectionIdentifier!
//            let data  = DataGraph(name: id, value: value)
//            dataArray.append(data)
//        }
//
//        var resultArrayExpense = [DataGraph]()
//        var resultArrayIncome  = [DataGraph]()
//
//        let allKeys = Set<String>(dataArray.map { $0.name })
//        for key in allKeys {
//            var data = dataArray.filter({ $0.name == key && $0.value < 0 })
//            var sum = data.map({ $0.value }).reduce(0, +)
//            resultArrayExpense.append(DataGraph(name: key, value: sum))
//
//            data = dataArray.filter({ $0.name == key && $0.value >= 0 })
//            sum = data.map({ $0.value }).reduce(0, +)
//            resultArrayIncome.append(DataGraph(name: key, value: sum))
//        }
//
//        resultArrayExpense = resultArrayExpense.sorted(by: { $0.name < $1.name })
//        resultArrayIncome = resultArrayIncome.sorted(by: { $0.name < $1.name })
//        return (expense: resultArrayExpense, income: resultArrayIncome)
//    }
//
//    private func applyData(expense resultArrayExpense: [DataGraph], income resultArrayIncome: [DataGraph], to chartView: BarChartView) {
//        // If there's no data, clear the chart and return
//        guard !resultArrayExpense.isEmpty && !resultArrayIncome.isEmpty else {
//            chartView.data = nil
//            DispatchQueue.main.async {
//                chartView.notifyDataSetChanged()
//            }
//            return
//        }
//
//        let groupSpace = 0.2
//        let barSpace = 0.00
//        let barWidth = 0.4
//
//        // Build entries and dynamic labels from section identifiers
//        var entriesExpense = [BarChartDataEntry]()
//        var entriesIncome = [BarChartDataEntry]()
//
//        var xLabels: [String] = []
//        var components = DateComponents()
//        var dateString = ""
//
//        for i in 0 ..< resultArrayExpense.count {
//            entriesExpense.append(BarChartDataEntry(x: Double(i), y: abs(resultArrayExpense[i].value)))
//            entriesIncome.append(BarChartDataEntry(x: Double(i), y: resultArrayIncome[i].value))
//
//            let numericSection = Int(resultArrayExpense[i].name)
//            components.year = numericSection! / 100
//            components.month = numericSection! % 100
//
//            if let date = Calendar.current.date(from: components) {
//                dateString = formatterDate.string(from: date)
//            }
//            xLabels.append(dateString)
//        }
//
//        // Create or update data sets
//        var dataSet1: BarChartDataSet
//        var dataSet2: BarChartDataSet
//
//        if chartView.data == nil || chartView.data?.dataSetCount != 2 {
//            var label = String(localized: "Expense")
//            dataSet1 = BarChartDataSet(entries: entriesExpense, label: label)
//            dataSet1.colors = [#colorLiteral(red: 1, green: 0.1474981606, blue: 0, alpha: 1)]
//            dataSet1.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//
//            label = String(localized: "Income")
//            dataSet2 = BarChartDataSet(entries: entriesIncome, label: label)
//            dataSet2.colors = [#colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)]
//            dataSet2.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//        } else {
//            dataSet1 = (chartView.data!.dataSets[0] as! BarChartDataSet)
//            dataSet1.replaceEntries(entriesExpense)
//
//            dataSet2 = (chartView.data!.dataSets[1] as! BarChartDataSet)
//            dataSet2.replaceEntries(entriesIncome)
//        }
//
//        // Build BarChartData
//        let data = BarChartData(dataSets: [dataSet1, dataSet2])
//        data.barWidth = barWidth
//        data.groupBars(fromX: Double(0), groupSpace: groupSpace, barSpace: barSpace)
//        data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//        data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(8.0))!)
//        data.setValueTextColor(.black)
//
//        let groupCount = resultArrayExpense.count + 1
//        let startYear = 0
//        let endYear = startYear + groupCount
//
//        chartView.xAxis.axisMinimum = Double(startYear)
//        chartView.xAxis.axisMaximum = Double(endYear)
//        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xLabels)
//
//        chartView.data = data
//        DispatchQueue.main.async {
//            data.notifyDataChanged()
//            chartView.notifyDataSetChanged()
//        }
//    }
    
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

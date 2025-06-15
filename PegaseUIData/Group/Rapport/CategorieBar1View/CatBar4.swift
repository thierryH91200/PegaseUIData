//
//  CatBar4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts

struct DGBarChart1Representable: NSViewRepresentable {
    
    @ObservedObject var viewModel: CategorieBar1ViewModel
    let entries: [BarChartDataEntry]
    
//    let labels: [String]
//    @Binding var chartViewRef: BarChartView?
    
    @State var listTransactions : [EntityTransaction] = []
    @State var firstDate: TimeInterval = 0.0
    @State var lastDate: TimeInterval = 0.0
    
    let hourSeconds = 3600.0 * 24.0 // one day

    func makeNSView(context: Context) -> BarChartView {

        let chartView = BarChartView()
        initChart(on: chartView)
        return chartView
    }

    func updateNSView(_ nsView: BarChartView, context: Context) {
        DispatchQueue.main.async {
            self.updateAccount()
            let oldGraph = self.viewModel.resultArray
            self.updateChartData(for: nsView)
            if oldGraph != self.viewModel.resultArray {
                self.setData(on: nsView, with: self.viewModel.resultArray)
            }
        }
    }
    
    func setData(on chartView: BarChartView, with data: [DataGraph]) {
//        guard resultArray.isEmpty == false else {
//            chartView.data = nil
//            chartView.data?.notifyDataChanged()
//            chartView.notifyDataSetChanged()
//            return }
//
//        // MARK: BarChartDataEntry
//        var entries = [BarChartDataEntry]()
//        var colors = [NSColor]()
//        label.removeAll()
//        colors.removeAll()
//
//        for i in 0 ..< resultArray.count {
//            entries.append(BarChartDataEntry(x: Double(i), y: resultArray[i].value))
//            label.append(resultArray[i].name)
//            colors.append(resultArray[i].color)
//        }
//
//        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: label)
//
//        if chartView.data == nil {
//            // MARK: BarChartDataSet
//            let label = Localizations.Graph.Rubrique
//            var dataSet = BarChartDataSet()
//
////            let block: (Int) -> BarChartDataEntry = { (i) -> BarChartDataEntry in
////                return BarChartDataEntry(x: Double(i), y: Double(self.resultArray[i].value))
////            }
////
////            let yVals1 = (0 ..< 1).map(block)
////            let yVals2 = (0 ..< 1).map(block)
////            let yVals3 = (0 ..< 1).map(block)
////            let yVals4 = (0 ..< 1).map(block)
//
//                //            for i in 0..<entries.count {
//            dataSet = BarChartDataSet(entries: entries, label: label)
//
//            dataSet.colors = colors
//            dataSet.drawValuesEnabled = true
//            dataSet.barBorderWidth = 0.1
//            dataSet.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//                //            }
//
//            chartView.xAxis.labelCount  = entries.count
//
//            // MARK: BarChartData
//            let data = BarChartData(dataSets: [dataSet])
//
//            data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//            data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
//            data.setValueTextColor(NSColor.black)
//            chartView.data = data
//            
//        } else {
//            // MARK: BarChartDataSet
//            let set1 = chartView.data!.dataSets[0] as! BarChartDataSet
//            set1.colors = colors
//            set1.replaceEntries( entries )
//
//            // MARK: BarChartData
//            chartView.data?.notifyDataChanged()
//            chartView.notifyDataSetChanged()
//        }
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
    
    func updateAccount () {
        // Charger toutes les transactions d'abord
        let allTransactions = ListTransactionsManager.shared.getAllData()

        guard !allTransactions.isEmpty else {
            DispatchQueue.main.async {
                self.listTransactions = []
            }
            return
        }

        let firstOpDate = Calendar.current.startOfDay(for: allTransactions.first!.dateOperation)
        let lastOpDate = Calendar.current.startOfDay(for: allTransactions.last!.dateOperation)

        self.firstDate = firstOpDate.timeIntervalSince1970
        self.lastDate = lastOpDate.timeIntervalSince1970

        // Appliquer la plage sélectionnée
        let startDate = Calendar.current.date(byAdding: .day, value: Int(self.viewModel.selectedStart), to: firstOpDate)!
        let endDate = Calendar.current.date(byAdding: .day, value: Int(self.viewModel.selectedEnd), to: firstOpDate)!

        let filteredTransactions = allTransactions.filter {
            $0.dateOperation >= startDate && $0.dateOperation <= endDate
        }

        DispatchQueue.main.async {
            self.listTransactions = filteredTransactions
        }
    }
    
    private func updateChartData( for nsView: BarChartView)
    {
//           
//            let context = mainObjectContext
//            
//            (startDate, endDate) = (sliderViewController?.calcStartEndDate())!
//            
//            let p1 = NSPredicate(format: "account == %@", currentAccount!)
//            let p2 = NSPredicate(format: "dateOperation >= %@", startDate as CVarArg )
//            let p3 = NSPredicate(format: "dateOperation <= %@", endDate as CVarArg )
//            let predicate = NSCompoundPredicate(type: .and, subpredicates: [p1, p2, p3])
//            
//            let fetchRequest = NSFetchRequest<EntityTransactions>(entityName: "EntityTransactions")
//            fetchRequest.predicate = predicate
//            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateOperation", ascending: true)]
//            
//            do {
//                listTransactions = try context!.fetch(fetchRequest)
//            } catch {
//                printTag("Error fetching data from CoreData")
//            }
//            
//            // grouped and sum
//            var dataArray = [DataGraph]()
//            
//            var name = ""
//            var value = 0.0
//            var color = NSColor.blue
//            
//            for listTransaction in listTransactions {
//                let sousOperations = listTransaction.sousOperations?.allObjects  as! [EntitySousOperations]
//                for sousOperation in sousOperations {
//                    name  = (sousOperation.category?.rubric!.name)!
//                    value = sousOperation.amount
//                    color = sousOperation.category?.rubric?.color as! NSColor
//                }
//                dataArray.append( DataGraph(name: name, value: value, color: color))
//            }
//            
//            resultArray.removeAll()
//            let allKeys = Set<String>(dataArray.map { $0.name })
//            for key in allKeys {
//                let data = dataArray.filter({ $0.name == key })
//                let sum = data.map({ $0.value }).reduce(0, +)
//                resultArray.append(DataGraph(name: key, value: sum, color: data[0].color))
//            }
//            resultArray = resultArray.sorted(by: { $0.name < $1.name })
    }
}

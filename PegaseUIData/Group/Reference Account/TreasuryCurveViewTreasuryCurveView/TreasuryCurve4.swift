//
//  TreasuryCurve4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 06/05/2025.
//

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

struct DGLineChartRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: TresuryLineViewModel
    let entries: [ChartDataEntry]

    @State private var selectedType: String = "Tous"
    
    @State var listTransactions : [EntityTransaction] = []
    @State var firstDate: TimeInterval = 0.0
    @State var lastDate: TimeInterval = 0.0
    
    let hourSeconds = 3600.0 * 24.0 // one day

    func makeNSView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        initGraph(on: chartView)
        return chartView
    }

    func updateNSView(_ nsView: LineChartView, context: Context) {
        DispatchQueue.main.async {
            self.updateAccount()
            let oldGraph = self.viewModel.dataGraph
            self.updateChartData(for: nsView)
            if oldGraph != self.viewModel.dataGraph {
                self.setData(on: nsView, with: self.viewModel.dataGraph)
            }
        }
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

    func addLimit( on nsView: LineChartView, index: Double, x: Double) {
        
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yy"
        
        let date2 = Date(timeIntervalSince1970: x )
        if calendar.day(date2) == 1 {
            let dateStr = dateFormatter.string(from: date2)
            let llXAxis = ChartLimitLine(limit: index, label: dateStr)
            llXAxis.lineColor = .linkColor
            llXAxis.valueTextColor = NSColor.controlAccentColor
            llXAxis.valueFont = NSFont.systemFont(ofSize: CGFloat(12.0))
            llXAxis.labelPosition = .rightBottom
            
            let xAxis = nsView.xAxis
            xAxis.addLimitLine(llXAxis)
        }
    }
        
    func setData(on nsView: LineChartView, with data: [DataTresorerie]) {
        guard !data.isEmpty else {
            nsView.data = nil
            nsView.data?.notifyDataChanged()
            nsView.notifyDataSetChanged()
            return
        }

        let filteredData = data.filter {
            $0.x >= viewModel.selectedStart && $0.x <= viewModel.selectedEnd
        }

        if let minX = filteredData.map(\.x).min(),
           let maxX = filteredData.map(\.x).max() {
            nsView.xAxis.axisMinimum = minX
            nsView.xAxis.axisMaximum = maxX
        }
        
        nsView.xAxis.removeAllLimitLines()
        
        var values0 = [ChartDataEntry]()
        var values1 = [ChartDataEntry]()
        var values2 = [ChartDataEntry]()

        for entry in filteredData {
            values0.append(ChartDataEntry(x: entry.x, y: entry.soldeRealise))
            values1.append(ChartDataEntry(x: entry.x, y: entry.soldeEngage))
            values2.append(ChartDataEntry(x: entry.x, y: entry.soldePrevu))
            addLimit(on: nsView, index: entry.x, x: (entry.x * hourSeconds) + firstDate)
        }

        nsView.xAxis.labelCount = 300
        nsView.xAxis.valueFormatter = DateValueFormatter(miniTime: firstDate, interval: hourSeconds)

        // MARK: Marker
//        let marker = RectMarker(
//            color: #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1),
//            font: NSFont.systemFont(ofSize: 12.0),
//            insets: NSEdgeInsets(top: 8.0, left: 8.0, bottom: 20.0, right: 8.0)
//        )
//        marker.minimumSize = CGSize(width: 80.0, height: 40.0)
//        marker.chartView = nsView
//        nsView.marker = marker
//        marker.miniTime = firstDate
//        marker.interval = hourSeconds

        // MARK: Datasets
        
        let label = [String(localized:"Planned"),
                     String(localized:"In progress"),
                     String(localized:"Executed")   ]
        let set1 = setDataSet(values: values0, label: label[0], color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1))
        let set2 = setDataSet(values: values1, label: label[1], color: #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1))
        let set3 = setDataSet(values: values2, label: label[2], color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1))

        let dataSet = LineChartData(dataSets: [set1, set2, set3])
        dataSet.setValueTextColor(.black)
        dataSet.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(9.0))!)

        nsView.data = dataSet
    }
    
    func setDataSet (values : [ChartDataEntry], label: String, color : NSColor) -> LineChartDataSet
    {
        var dataSet =  LineChartDataSet()
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .currency
        pFormatter.maximumFractionDigits = 2
        
        dataSet = LineChartDataSet(entries: values, label: label)
        dataSet.axisDependency = .left
        dataSet.mode = .stepped
        dataSet.valueTextColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        dataSet.lineWidth = 2.0
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = true
        dataSet.valueFormatter = DefaultValueFormatter(formatter: pFormatter  )
        
        dataSet.drawFilledEnabled = false //true
        dataSet.fillAlpha = 0.26
        dataSet.fillColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        dataSet.highlightColor = #colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1)
        dataSet.highlightLineWidth = 4.0
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.formSize = 15.0
        dataSet.colors = [color]
        return dataSet
    }
    
    func initGraph(on nsView: LineChartView) {
        
        // MARK: General
        nsView.dragEnabled = false
        nsView.setScaleEnabled(true)
        nsView.pinchZoomEnabled = false
        nsView.drawGridBackgroundEnabled = false
        nsView.highlightPerDragEnabled = true
        nsView.noDataText = String(localized:"No chart data available.")
        
        nsView.scaleYEnabled = false
        nsView.scaleXEnabled = false
        
        // MARK: xAxis
        let xAxis                             = nsView.xAxis
        xAxis.labelPosition                   = .bottom
        xAxis.labelFont                       = NSFont(name : "HelveticaNeue-Light", size : CGFloat(10.0))!
        xAxis.drawAxisLineEnabled             = true
        xAxis.drawGridLinesEnabled            = true
        xAxis.drawLimitLinesBehindDataEnabled = true
        xAxis.avoidFirstLastClippingEnabled   = false
        xAxis.granularity                     = 1.0
        xAxis.spaceMin                        = xAxis.granularity / 5
        xAxis.spaceMax                        = xAxis.granularity / 5
        xAxis.labelRotationAngle              = -45.0
        xAxis.labelTextColor                  = .labelColor
                
        // MARK: leftAxis
        let leftAxis                  = nsView.leftAxis
        leftAxis.labelPosition        = .outsideChart
        leftAxis.labelFont            = NSFont(name : "HelveticaNeue-Light", size : CGFloat(12.0))!
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled   = true
        leftAxis.yOffset              = -9.0
        leftAxis.labelTextColor       = .labelColor
        
        // MARK: rightAxis
        nsView.rightAxis.enabled = false
        
        // MARK: legend
        let legend                 = nsView.legend
        legend.enabled             = true
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        // MARK: description
        nsView.chartDescription.enabled = false
    }
    
    func updateChartData(for nsView: LineChartView) {
        
        let transactions = viewModel.listTransactions
        
        guard !transactions.isEmpty else { return }

//        var dataGraph : [DataTresorerie] = []
        var dataTresorerie = DataTresorerie()
        var dataGraph : [DataTresorerie] = []

        let initAccount = InitAccountManager.shared.getAllData()
        var soldeRealise = initAccount?.realise ?? 0
        var soldePrevu   = initAccount?.prevu ?? 0
        var soldeEngage  = initAccount?.engage ?? 0

        var prevu  = 0.0
        var engage = 0.0

        let calendar = Calendar.current
        
        // Normalize firstDate to midnight using Calendar
        firstDate = calendar.startOfDay(for: transactions.first!.datePointage).timeIntervalSince1970
        let minValue = Double(firstDate / hourSeconds)
        let maxValue = Double(calendar.startOfDay(for: transactions.last!.datePointage).timeIntervalSince1970 / hourSeconds)
//        let minIndex = 0
        let maxIndex = Int((maxValue - minValue))
        
        let grouped = Dictionary(grouping: transactions, by: { calendar.startOfDay(for: $0.datePointage) })

        let selectedStartOffset = Int(viewModel.selectedStart)
        let selectedEndOffset = min(Int(viewModel.selectedEnd), maxIndex)

        for offset in selectedStartOffset...selectedEndOffset {
            let dayDate = Date(timeIntervalSince1970: firstDate + Double(offset) * hourSeconds)
            let dayTransactions = grouped[dayDate] ?? []

            for tx in dayTransactions {
                switch tx.status?.type {
                case .planned:
                    prevu += tx.amount
                case .inProgress:
                    engage += tx.amount
                case .executed:
                    soldeRealise += tx.amount
                case .none:
                    let _ = 0.0
                }
            }

            soldePrevu  += soldeRealise + engage + prevu
            soldeEngage += soldeRealise + engage
            
            prevu  = 0.0
            engage = 0.0

            printTag("n°\(offset)    \(soldePrevu)  \(soldeEngage)  \(soldeRealise)", flag: true)
            
            dataTresorerie = DataTresorerie(
                x            : Double(offset),
                soldeRealise : soldeRealise,
                soldeEngage  : soldeEngage,
                soldePrevu   : soldePrevu
            )
            dataGraph.append(dataTresorerie)
        }
        if dataGraph.count != viewModel.dataGraph.count {
            viewModel.dataGraph = dataGraph
        } else {
            var isDifferent = false
            for (a, b) in zip(dataGraph, viewModel.dataGraph) {
                if a != b {
                    isDifferent = true
                    break
                }
            }
            if isDifferent {
                viewModel.dataGraph = dataGraph
            }
        }
    }
    
//    func calcStartEndDate() -> (Date, Date) {
        
//        let calendar = Calendar.current
//
//        var date2 = Date(timeIntervalSince1970: ((mySlider.start * self.oneDay) + self.firstDate))
//        self.startDate = calendar.startOfDay(for: date2)
//
//        date2 = Date(timeIntervalSince1970: ((mySlider.end * self.oneDay) + self.firstDate))
//        self.endDate = calendar.endOfDay(date: date2 )
//        return (startDate, endDate)
//    }

}

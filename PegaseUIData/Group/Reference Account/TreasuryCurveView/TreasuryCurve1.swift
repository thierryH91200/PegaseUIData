//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts


class TresuryLineViewModel: ObservableObject {
    @Published var resultArray: [DataGraph] = []
    @Published var dataGraph: [DataTresorerie] = []
    @Published var dataEntries: [ChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    
    @Published var listTransactions : [EntityTransactions] = []
    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    
    @Published var selectedCategories: Set<String> = []
    
    let hourSeconds = 3600.0 * 24.0 // one day
    var firstDate: TimeInterval = 0.0
    var lastDate: TimeInterval = 0.0

    var chartView : LineChartView?
    var rangeSlider : RangeSlider?
    
    static let shared = TresuryLineViewModel()

    var totalValue: Double {
        resultArray.map { $0.value }.reduce(0, +)
    }
    
    var labels: [String] {
        resultArray.map { $0.name }
    }
    
    func configure(with chartView: LineChartView)
    {
        self.chartView = chartView
    }

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    func updateAccount () {
        // Filter transactions for the last month
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        listTransactions = ListTransactionsManager.shared.getAllDatas(from: startDate, to: endDate)
        if listTransactions.isEmpty == false {
            firstDate = (listTransactions.first?.dateOperation.timeIntervalSince1970)!
            lastDate = (listTransactions.last?.dateOperation.timeIntervalSince1970)!
            rangeSlider?.minValue = firstDate
            rangeSlider?.maxValue = lastDate
        }
    }
    
    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {
        
        let firstDate: TimeInterval = 0.0
        
        ListTransactionsManager.shared.configure(with: modelContext)
        listTransactions = ListTransactionsManager.shared.getAllDatas(from: startDate, to: endDate)
        
        guard listTransactions.isEmpty == false else { return }
        
        self.dataGraph.removeAll()
        
        var dataTresorerie = DataTresorerie()
        var index = 0
        var indexDate = 0.0
        var sameDate = true
        
        InitAccountManager.shared.configure(with: modelContext)
        let initAccount = InitAccountManager.shared.getAllDatas()
        
        var soldeRealise = initAccount?.realise ?? 0.0
        var soldePrevu   = initAccount?.prevu ?? 0.0
        var soldeEngage  = initAccount?.engage ?? 0.0
        
        var prevu  = 0.0
        var engage = 0.0
        
        let minValue = 0
        let maxValue = 30
        
        for indexSlider in minValue..<maxValue + 1 {
            
            sameDate = true
            while sameDate == true {
                
                indexDate = ( (listTransactions[index ].datePointage.timeIntervalSince1970) - firstDate ) / hourSeconds
                
                // même jour mais le statut peut être différent ??
                if Int(indexDate) == indexSlider {
                    
                    let propertyEnum = listTransactions[index].status?.type
                    switch propertyEnum
                    {
                    case 0:
                        prevu += listTransactions[index].amount
                    case 1:
                        engage += listTransactions[index].amount
                    case 2:
                        soldeRealise += listTransactions[index].amount
                    case .none:
                        _ = 1
                    case .some(_):
                        _ = 1
                    }
                    
                    index += 1
                    if index == listTransactions.count {
                        sameDate = false
                    }
                } else {
                    sameDate = false
                }
            }
            soldePrevu = soldeRealise + engage + prevu
            soldeEngage = soldeRealise + engage
            
            let entries = listTransactions.enumerated().map { index, item in
                ChartDataEntry(x: Double(index), y: item.amount)
            }
            
            self.dataEntries = entries
            
            self.dataEntries = entries.filter { $0.x.isFinite && $0.y.isFinite && $0.y != 0 }
            
            dataTresorerie.x = Double(indexSlider)
            dataTresorerie.soldeRealise = soldeRealise
            dataTresorerie.soldeEngage = soldeEngage
            dataTresorerie.soldePrevu = soldePrevu
            dataGraph.append(dataTresorerie)
        }
    }
    
    func addLimit( index: Double, x: Double) {
        
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
            
            let xAxis = chartView?.xAxis
            xAxis?.addLimitLine(llXAxis)
        }
    }
    
    func setData(chartView: LineChartView)
    {
        var listTransactions : [EntityTransactions] = []
        guard listTransactions.isEmpty == false || dataGraph.isEmpty == false  || listTransactions.count == 1 else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return }
        
        chartView.xAxis.axisMinimum = 0.0
        chartView.xAxis.axisMaximum = 200.0
        
        chartView.xAxis.removeAllLimitLines()
        
        // MARK: ChartDataEntry
        var values0 = [ChartDataEntry]()
        var values1 = [ChartDataEntry]()
        var values2 = [ChartDataEntry]()
        
        let from = 0
        let to = 30
        
        for i in from..<to {
            values0.append(ChartDataEntry(x: dataGraph[i].x, y: dataGraph[i].soldeRealise))
            values1.append(ChartDataEntry(x: dataGraph[i].x, y: dataGraph[i].soldeEngage))
            values2.append(ChartDataEntry(x: dataGraph[i].x, y: dataGraph[i].soldePrevu))
            
            addLimit(index: dataGraph[i].x, x: (dataGraph[i].x * hourSeconds) + firstDate)
        }
        
        if values0.isEmpty == true {
            chartView.data = nil
            //            sliderViewHorizontalController?.mySlider.isEnabled = false
            return
        }
        
        //        sliderViewHorizontalController?.mySlider.isEnabled = true
        chartView.xAxis.labelCount = 300
        chartView.xAxis.valueFormatter = DateValueFormatter(miniTime: firstDate, interval: hourSeconds)
        
        // MARK: Marker
        //        let  marker = RectMarker( color: .gray,
        //                                  font: NSFont.systemFont(ofSize: 12.0),
        //                                  insets: NSEdgeInsets(top: 8.0, left: 8.0, bottom: 20.0, right: 8.0))
        //
        //        marker.minimumSize = CGSize( width: 80.0, height: 40.0)
        //        marker.chartView = chartView
        //        chartView.marker = marker
        //        marker.miniTime = firstDate
        //        marker.interval = hourSeconds
        
        // MARK: LineChartDataSet
        
        /// Pointe
        var label = "Realise"
        let set1 = setDataSet(values: values0, label: label, color: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1) )
        
        /// Engage
        label = "Engaged"
        let set2 = setDataSet(values: values1, label: label, color: #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1) )
        
        /// Planned
        label = "Planifie"
        let set3 = setDataSet(values: values2, label: label, color: #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1) )
        
        var dataSets = [LineChartDataSet]()
        dataSets.append(set1)
        dataSets.append(set2)
        dataSets.append(set3)
        
        // MARK: LineChartData
        let data = LineChartData(dataSets: dataSets)
        //        let data: LineChartData = [set1, set2, set3]
        data.setValueTextColor ( .black )
        data.setValueFont ( NSFont(name: "HelveticaNeue-Light", size: CGFloat(9.0))!)
        
        chartView.data = data
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
        dataSet.lineWidth = 1.5
        
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
    
    func initGraph(chartView: LineChartView) {
        
        // MARK: General
//        chartView.delegate = self
        
        chartView.dragEnabled = false
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = false
        chartView.drawGridBackgroundEnabled = false
        chartView.highlightPerDragEnabled = true
        chartView.noDataText = String(localized:"No chart data available.")
        
        chartView.scaleYEnabled = false
        chartView.scaleXEnabled = false
        
        // MARK: xAxis
        let xAxis                             = chartView.xAxis
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
        
        //        xAxis.nameAxis = "Date (s)"
        //        xAxis.nameAxisEnabled = true
        
        // MARK: leftAxis
        let leftAxis                  = chartView.leftAxis
        leftAxis.labelPosition        = .outsideChart
        leftAxis.labelFont            = NSFont(name : "HelveticaNeue-Light", size : CGFloat(12.0))!
        leftAxis.drawGridLinesEnabled = true
        leftAxis.granularityEnabled   = true
        leftAxis.yOffset              = -9.0
        leftAxis.labelTextColor       = .labelColor
        
        //        leftAxis.nameAxis = "Amount"
        //        leftAxis.nameAxisEnabled = true
        
        // MARK: rightAxis
        chartView.rightAxis.enabled = false
        
        // MARK: legend
        let legend                 = chartView.legend
        legend.enabled             = true
        legend.form                = .square
        legend.drawInside          = false
        legend.orientation         = .horizontal
        legend.verticalAlignment   = .bottom
        legend.horizontalAlignment = .left
        
        // MARK: description
        chartView.chartDescription.enabled = false
    }
}

struct DataTresorerie {
    var x: Double = 0.0
    var soldeRealise: Double = 0.0
    var soldeEngage: Double = 0.0
    var soldePrevu: Double = 0.0
    
    init(x: Double, soldeRealise: Double, soldeEngage: Double, soldePrevu: Double)
    {
        self.x  = x
        self.soldeRealise = soldeRealise
        self.soldeEngage = soldeEngage
        self.soldePrevu = soldePrevu
    }
    init() {
        self.x  = 0
        self.soldeRealise = 0
        self.soldeEngage = 0
        self.soldePrevu = 0
    }
}


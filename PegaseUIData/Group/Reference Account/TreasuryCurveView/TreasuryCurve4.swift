//
//  Untitled 4.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts

struct DGLineChartView: NSViewRepresentable {
    let entries: [ChartDataEntry]
//    @Binding var chartViewRef: LineChartView?

    @State private var selectedType: String = "Tous"
    
    @State var chartView = LineChartView()
    @StateObject private var viewModel = TresuryLineViewModel()
    
//    func makeCoordinator() -> Coordinator {
//      Coordinator(parent: self)
//    }


    func makeNSView(context: Context) -> LineChartView {
        initGraph()
//        chartView.delegate = context.coordinator
        return chartView
    }


//    func makeNSView(context: Context) -> LineChartView {
//
//        chartView.noDataText = String(localized:"No chart data available.")
//        let safeEntries = entries.isEmpty ? [ChartDataEntry(x: 0, y: 1), ChartDataEntry(x: 1, y: 2)] : entries
//        
//        let dataSet = LineChartDataSet(entries: safeEntries, label: "Évolution Mensuelle")
//        
//        dataSet.colors = [NSUIColor.systemBlue]
//        dataSet.circleColors = [NSUIColor.systemRed]
//        dataSet.circleRadius = 1
//        dataSet.drawCirclesEnabled = false
//        dataSet.lineWidth = 1.5
//        dataSet.drawValuesEnabled = true
//        
//        let data = LineChartData(dataSet: dataSet)
//        chartView.data = data
//        
//        chartView.xAxis.axisMinimum = 0
//        chartView.xAxis.axisMaximum = 200  // éviter plage nulle
//        
//        chartView.xAxis.labelPosition = .bottom
//        chartView.xAxis.granularity = 1
//        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
//        
//        if let minX = entries.map(\.x).min(),
//           let maxX = entries.map(\.x).max(),
//           minX != maxX {
//            chartView.xAxis.axisMinimum = minX
//            chartView.xAxis.axisMaximum = maxX
//        } else {
//            chartView.xAxis.axisMinimum = 0
//            chartView.xAxis.axisMaximum = 200
//        }
//        return chartView
//    }

    func updateNSView(_ nsView: LineChartView, context: Context) {
        
        
//        let data = nsView.
//        let dataset = LineChartDataSet(entries: data)
//        
//        dataset.drawCirclesEnabled = false
//        dataset.drawValuesEnabled = false
//        dataset.drawFilledEnabled = true
//        dataset.label = label
//        dataset.setColor(chartColor)
//        dataset.fillColor = chartColor.withAlphaComponent(0.2)
//        
//        nsView.data = LineChartData(dataSet: dataset)

        let dataSet = LineChartDataSet(entries: entries, label: "Realisé")
        dataSet.axisDependency = .left
        dataSet.mode = .stepped
        dataSet.valueTextColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        dataSet.lineWidth = 1.5
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = true
//        dataSet.valueFormatter = DefaultValueFormatter(formatter: pFormatter  )
        
        dataSet.drawFilledEnabled = false //true
        dataSet.fillAlpha = 0.26
        dataSet.fillColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        dataSet.highlightColor = #colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1)
        dataSet.highlightLineWidth = 4.0
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.formSize = 15.0
        dataSet.colors = [.black]

        let data = LineChartData(dataSet: dataSet)
        nsView.data = data

        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }

//    private func updateChart() {
//        let start = Calendar.current.date(byAdding: .day, value: Int(selectedStart), to: minDate)!
//        let end = Calendar.current.date(byAdding: .day, value: Int(selectedEnd), to: minDate)!
//        guard let currentAccount = CurrentAccountManager.shared.getAccount() else { return }
//
//        viewModel.initGraph(chartView: chartView!)
//        viewModel.updateChartData(modelContext: modelContext, currentAccount: currentAccount, startDate: start, endDate: end)
//        viewModel.setData(chartView: chartView!)
//    }

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
    
    func initGraph() {
        
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
    
    func updateChartData() {
        
//            self.dataGraph.removeAll()
//            guard listTransactions.isEmpty == false else { return }
//            
//            var dataTresorerie = DataTresorerie()
//            var index = 0
//            var indexDate = 0.0
//            var sameDate = true
//            
//            let initAccount = InitAccount.shared.getAllDatas()
//            
//            var soldeRealise = initAccount.realise
//            var soldePrevu   = initAccount.prevu
//            var soldeEngage  = initAccount.engage
//            
//            var prevu  = 0.0
//            var engage = 0.0
//            
//            let minValue = Int((sliderViewHorizontalController?.mySlider.minValue)!)
//            let maxValue = Int((sliderViewHorizontalController?.mySlider.maxValue)!)
//            
//            for indexSlider in minValue..<maxValue + 1 {
//                
//                sameDate = true
//                while sameDate == true {
//                    
//                    indexDate = ( (listTransactions[index ].datePointage?.timeIntervalSince1970)! - firstDate ) / hourSeconds
//                    
//                    // même jour mais le statut peut être différent ??
//                    if Int(indexDate) == indexSlider {
//                        
//                        let propertyEnum = Statut.TypeOfStatut(rawValue: listTransactions[index].statut)!
//                        switch propertyEnum
//                        {
//                        case .planifie:
//                            prevu += listTransactions[index].amount
//                        case .engage:
//                            engage += listTransactions[index].amount
//                        case .realise:
//                            soldeRealise += listTransactions[index].amount
//                        }
//                        index += 1
//                        if index == listTransactions.count {
//                            sameDate = false
//                        }
//                    } else {
//                        sameDate = false
//                    }
//                }
//                soldePrevu = soldeRealise + engage + prevu
//                soldeEngage = soldeRealise + engage
//                
//                dataTresorerie.x = Double(indexSlider)
//                dataTresorerie.soldeRealise = soldeRealise
//                dataTresorerie.soldeEngage = soldeEngage
//                dataTresorerie.soldePrevu = soldePrevu
//                dataGraph.append(dataTresorerie)
//            }
        }

}


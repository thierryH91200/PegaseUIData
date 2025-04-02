//
//  RubriquePieView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import DGCharts
import AppKit

struct RubriquePieView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        RubriquePie()
            .task {
                await performFalseTask()
            }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
}

struct DGPieChart1View1: NSViewRepresentable {
    let entries: [PieChartDataEntry]

    func makeNSView(context: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = PieChartDataSet(entries: entries, label: "Répartition des Rubriques")
        dataSet.colors = ChartColorTemplates.vordiplom() + ChartColorTemplates.joyful()
        dataSet.valueTextColor = NSUIColor.black
        dataSet.entryLabelColor = NSUIColor.black
        dataSet.sliceSpace = 2.0
        
        let data = PieChartData(dataSet: dataSet)
        chartView.data = data
        
        chartView.usePercentValuesEnabled = true
        chartView.drawHoleEnabled = false
        chartView.animate(xAxisDuration: 1.5, yAxisDuration: 1.5)
        
        return chartView
    }

    func updateNSView(_ nsView: PieChartView, context: Context) {
        nsView.data?.notifyDataChanged()
        nsView.notifyDataSetChanged()
    }
}

struct RubriquePie: View {
    @StateObject private var graphPie = GraphPie.shared
    @State private var pieDataEntries: [PieChartDataEntry] = []


    var body: some View {
        VStack {
            Text("RecetteDepensePie")
                .font(.headline)
                .padding()
            DGPieChart1View1(entries: pieDataEntries)
                .frame(width: 600, height: 400)
                .padding()

            Spacer()
        }
        .onAppear {
            updatePieData()
        }

    }
    private func updatePieData() {
        
        graphPie.initChart()
        graphPie.updateChartData(quakes: nil)  // Met à jour les données à partir de GraphPie
        
        pieDataEntries = graphPie.dataRubricPie.map { data in
            PieChartDataEntry(value: data.value, label: data.name)
        }
    }
}

final class GraphPie: ObservableObject {  // Ajout d'ObservableObject

    static let shared = GraphPie()

    var dataRubricPie = [DataGraph]()
    var groupedBonds = [String: [DataGraph]]()
    var pieChartView: PieChartView!
    var splitTransactions : [EntitySousOperations] = []
    var entityTransactions : [EntityTransactions] = []

    func initChart() {
        
        pieChartView = PieChartView()
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        
        let attribut: [ NSAttributedString.Key: Any] =
        [  .font: NSFont(name: "HelveticaNeue-Light", size: 8.0)!,
           .foregroundColor: NSColor.gray,
           .paragraphStyle: paragraphStyle]
        
        let centerText = NSMutableAttributedString(string: "Operation")
        centerText.setAttributes(attribut, range: NSRange(location: 0, length: centerText.length))
        
        self.pieChartView.centerAttributedText = centerText
        self.pieChartView.highlightPerTapEnabled = true
        self.pieChartView.drawSlicesUnderHoleEnabled = false
        self.pieChartView.holeRadiusPercent = 0.58
        self.pieChartView.transparentCircleRadiusPercent = 0.61
        self.pieChartView.drawCenterTextEnabled = true
        self.pieChartView.usePercentValuesEnabled = true
        self.pieChartView.drawEntryLabelsEnabled = false
        
        initializeLegend(self.pieChartView.legend)
        
        self.pieChartView.chartDescription  .enabled = false
        self.pieChartView.noDataText = "No_chart_Data_Available"
        self.pieChartView.holeColor = .windowBackgroundColor
    }
    
    // MARK: Legend
    func initializeLegend(_ legend: Legend) {
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        
        legend.xEntrySpace = 7
        legend.yEntrySpace = 0
        legend.yOffset = 0
        
        legend.font = NSFont(name: "HelveticaNeue-Light", size: 8.0)!
        legend.textColor = NSColor.labelColor
    }
    
    // MARK: update Chart Data
    func updateChartData(quakes : EntityTransactions? ) {
        
        guard splitTransactions.isEmpty == false else {
            entityTransactions = ListTransactionsManager.shared.getAllDatas()
//            resetListTransactions()
            return
        }
        
        self.dataRubricPie.removeAll()
        
        var nameRubric = ""
        var value = 0.0
        var color = NSColor.red
        for sousOperation in splitTransactions {
            
            value = sousOperation.amount
            nameRubric = (sousOperation.category?.rubric!.name)!
            color = (sousOperation.category?.rubric!.color)!
            self.dataRubricPie.append(DataGraph(name: nameRubric, value: value, color: color))
        }
        self.groupedBonds = Dictionary(grouping: self.dataRubricPie) { (DataRubriquePie) -> String in
            return DataRubriquePie.name }
    }
    
    func setDataCount()
    {
        guard dataRubricPie.isEmpty == false else {
            pieChartView.data = nil
            pieChartView.data?.notifyDataChanged()
            pieChartView.notifyDataSetChanged()
            return }
        
//        self.addView.isHidden = groupedBonds.isEmpty == false ? true : false
        
        // MARK: PieChartDataEntry
        var entries = [PieChartDataEntry]()
        var colors : [NSColor] = []
        
        for (key, values) in groupedBonds {
            
            var amount = 0.0
            for value in values {
                amount += value.value
            }
            
            let color = values[0].color
            entries.append(PieChartDataEntry(value: abs(amount), label: key))
            colors.append( color )
        }
        
        // MARK: PieChartDataSet
        let dataSet = PieChartDataSet(entries: entries, label: "Rubriques")
        dataSet.sliceSpace = 2.0
        
        dataSet.colors = colors
        dataSet.yValuePosition = .outsideSlice
        
        // MARK: PieChartData
        let data = PieChartData(dataSet: dataSet)
        
        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = " %"
        
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(8.0))!)
        data.setValueTextColor( .labelColor)
        self.pieChartView.data = data
        self.pieChartView.highlightValues(nil)
    }
    
}

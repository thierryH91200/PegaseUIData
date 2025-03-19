//
//  RecetteDepensePieView.swift
//  PegaseUI
//
//  Created by Thierry hentic on 31/10/2024.
//

import SwiftUI
import DGCharts
import SwiftData

struct RecetteDepensePieView: View {
    
    @Binding var isVisible: Bool
    
    var body: some View {
        RecetteDepensePie()
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

struct DGPieChartView: NSViewRepresentable {
    let entries: [PieChartDataEntry]
    
    var resultArrayD = [DataGraph]()
    var resultArrayR = [DataGraph]()


    func makeNSView(context: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.noDataText = String(localized:"No chart data available.")
        
        let dataSet = PieChartDataSet(entries: entries, label: "Répartition des Dépenses")
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

struct RecetteDepensePie: View {
    var pieDataEntries: [PieChartDataEntry] = [
        PieChartDataEntry(value: 40, label: "Logement"),
        PieChartDataEntry(value: 25, label: "Transport"),
        PieChartDataEntry(value: 20, label: "Nourriture"),
        PieChartDataEntry(value: 15, label: "Autres")
    ]
    
    var chartView: PieChartView!
    var chartView2: PieChartView!
    var listeOperations = [EntityTransactions]()



    var body: some View {
        VStack {
            Text("RecetteDepensePie")
                .font(.headline)
                .padding()
            DGPieChartView(entries: pieDataEntries)
                .frame(width: 600, height: 400)
                .padding()
                .onAppear() {
                    self.chartView.spin(duration: 1, fromAngle: 0, toAngle: 360.0)
                    self.chartView2.spin(duration: 1, fromAngle: 0, toAngle: 360.0)
                    initChart()

                }
            Spacer()
        }
    }
    func initChart() {
        
        // MARK: - Chart View Income
//        chartView.delegate = self
        
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .center
        
        let attribut: [ NSAttributedString.Key: Any] =
        [ .font            : NSFont(name  : "HelveticaNeue-Light", size : 15.0)!,
          .foregroundColor : NSColor.textColor,
          .paragraphStyle  : paragraphStyle]
        
        // MARK: - Chart View Expense
        var centerText = NSMutableAttributedString(string: "Recette")
        centerText.setAttributes(attribut, range: NSRange(location: 0, length: centerText.length))
        chartView.centerAttributedText = centerText
        
        chartView.chartDescription.enabled = false
        chartView.noDataText = "No chart Data available."
        chartView.holeColor = .windowBackgroundColor
        
        // MARK: legend
        let legend = chartView.legend
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .top
        legend.orientation = .vertical
        legend.font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        legend.textColor = .labelColor
        
        // MARK: - Chart View Expenses
//        chartView2.delegate = self
        
        centerText = NSMutableAttributedString(string: "Dépenses")
        centerText.setAttributes(attribut, range: NSRange(location: 0, length: centerText.length))
        
        chartView2.centerAttributedText = centerText
        chartView2.chartDescription.enabled = false
        chartView2.noDataText = "No chart Data available."
        chartView2.holeColor = .windowBackgroundColor
        
        // MARK: legend
        let legend2 = chartView2.legend
        legend2.horizontalAlignment = .left
        legend2.verticalAlignment = .top
        legend2.orientation = .vertical
        legend2.font = NSFont(name: "HelveticaNeue-Light", size: CGFloat(14.0))!
        legend2.textColor = .labelColor
    }
    
    func updateChartData(context : ModelContext)
    {
        var dataArrayExpense = [DataGraph]()
        var dataArrayIncome = [DataGraph]()
        
        var listTransactions = [EntityTransactions]()

        let account = CurrentAccountManager.shared.getAccount()!
        
        
        
        //        (startDate, endDate) = (sliderViewController?.calcStartEndDate())!
        let currentAccountID = account.uuid
        let p1 = #Predicate<EntityTransactions>{ $0.account.uuid == currentAccountID }
//        let p2 = Predicate(format: "dateOperation >= %@", startDate as CVarArg )
//        let p3 = NSPredicate(format: "dateOperation <= %@", endDate as CVarArg )
        let predicate = p1
        
        let ascending = true
        let sort = [
            SortDescriptor(\EntityTransactions.datePointage, order: ascending ? .forward : .reverse),
            SortDescriptor(\EntityTransactions.dateOperation, order: ascending ? .forward : .reverse) ]

        let fetchDescriptor = FetchDescriptor<EntityTransactions>(
            predicate: predicate,
            sortBy: sort )
        
        
        do {
            listTransactions = try context.fetch(fetchDescriptor)
            
        } catch {
            print("Error fetching data from CoreData")
        }
        
//        for listTransaction in listTransactions {
//            
//            let sousOperations = listTransaction.sousOperations  as! [EntitySousOperations]
//            for sousOperation in sousOperations {
//                
//                value = sousOperation.amount
//                rubrique = (sousOperation.category?.rubric!.name)!
//                color = sousOperation.category?.rubric?.color as! NSColor
//                
//                if value < 0 {
//                    dataArrayD.append( DataGraph( name: rubrique, value: value, color: color))
//                    
//                } else {
//                    dataArrayR.append( DataGraph(section: section, name: rubrique, value: value, color: color))
//                }
//        }
//        
//            self.resultArrayD.removeAll()
//            let allKeys = Set<String>(dataArrayD.map { $0.name })
//            for key in allKeys {
//                let data = dataArrayD.filter({ $0.name == key })
//                let sum = data.map({ $0.value }).reduce(0, +)
//                self.resultArrayD.append(DataGraph(name: key, value: sum, color: data[0].color))
//            }
//            self.resultArrayD = self.resultArrayD.sorted(by: { $0.name < $1.name })
//            
//            resultArrayR.removeAll()
//            let allKeysR = Set<String>(dataArrayR.map { $0.name })
//            for key in allKeysR {
//                let data = dataArrayR.filter({ $0.name == key })
//                let sum = data.map({ $0.value }).reduce(0, +)
//                self.resultArrayR.append(DataGraph(name: key, value: sum, color: data[0].color))
//            }
//            resultArrayR = resultArrayR.sorted(by: { $0.name < $1.name })
    }
    
    // MARK: setDataExpenses
    func setDataExpenses()
    {
//        if NSApplication.shared.isCharts == true {
//            
//            guard resultArrayExpense.isEmpty == false  else {
//                chartView.data = nil
//                chartView.data?.notifyDataChanged()
//                chartView.notifyDataSetChanged()
//                return }
//            
//            // MARK: PieChartDataEntry
//            var colors : [NSColor] = []
//            var entries = [PieChartDataEntry]()
//            for result in resultArrayExpense {
//                entries.append(PieChartDataEntry(value: abs(result.value), label: result.name))
//                colors.append(result.color)
//            }
//            
//            // MARK: PieChartDataSet
//            let dataSet = PieChartDataSet(entries: entries, label: "Expenses")
//            dataSet.sliceSpace = 2.0
//            dataSet.colors = colors
//            dataSet.valueLinePart1OffsetPercentage = 0.8
//            dataSet.valueLinePart1Length = 0.4
//            dataSet.valueLinePart2Length = 1.0
//            dataSet.xValuePosition = .outsideSlice
//            dataSet.yValuePosition = .outsideSlice
//            dataSet.valueLineColor = .labelColor
//            dataSet.entryLabelColor = .labelColor
//            
//            // MARK: PieChartData
//            let data = PieChartData(dataSet: dataSet)
//            
//            data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//            data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
//            data.setValueTextColor(NSColor.labelColor)
//            chartView2.data = data
//        }
    }
        
        // MARK: setDataIncomes
    private func setDataIncomes()
    {
//        if NSApplication.shared.isCharts == true {
//            
//            guard resultArrayIncome.isEmpty == false else {
//                chartView2.data = nil
//                chartView2.data?.notifyDataChanged()
//                chartView2.notifyDataSetChanged()
//                return }
//            
//            // MARK: PieChartDataEntry
//            var colors : [NSColor] = []
//            var entries : [PieChartDataEntry] = []
//            for result in self.resultArrayIncome {
//                entries.append(PieChartDataEntry(value: abs(result.value), label: result.name))
//                colors.append(result.color)
//            }
//            
//            // MARK: PieChartDataSet
//            let dataSet = PieChartDataSet(entries: entries, label: "Incomes")
//            dataSet.sliceSpace = 2.0
//            dataSet.colors = colors
//            dataSet.valueLinePart1OffsetPercentage = 0.8
//            dataSet.valueLinePart1Length = 0.2
//            dataSet.valueLinePart2Length = 1.0
//            dataSet.xValuePosition = .outsideSlice
//            dataSet.yValuePosition = .outsideSlice
//            dataSet.valueLineColor = .labelColor
//            dataSet.entryLabelColor = .labelColor
//            
//            // MARK: PieChartData
//            let data = PieChartData(dataSet: dataSet)
//            
//            data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
//            data.setValueFont(NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0))!)
//            data.setValueTextColor(NSColor.labelColor)
//            chartView.data = data
//        }
    }

    
}

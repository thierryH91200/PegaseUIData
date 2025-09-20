//
//  Rubrique.swift
//  PegaseUIData
//
//  Created by thierryH24 on 20/09/2025.
//

//
//  Untitled 2.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


struct RubriquePieView: View {
    
    @Binding var isVisible: Bool
    
    @State private var transactions: [EntityTransaction] = []
    @State private var lowerValue: Double = 0
    @State private var upperValue: Double = 0
    @State private var minDate: Date = Date()
    @State private var maxDate: Date = Date()
    
    private let oneDay = 3600.0 * 24.0 // one day

    var body: some View {
        RubriquePie(
            transactions: transactions,
            lowerValue: $lowerValue,
            upperValue: $upperValue,
            minDate: $minDate,
            maxDate: $maxDate
        )
        .task {
            await performFalseTask()
        }
        .onAppear {
            Task {
                await loadTransactions()
                minDate = transactions.first?.dateOperation ?? Date()
                lowerValue = 0
                maxDate = transactions.last?.dateOperation ?? Date()
                upperValue = maxDate.timeIntervalSince(minDate) / oneDay
            }
        }
    }
    
    private func performFalseTask() async {
        // Exécuter une tâche asynchrone (par exemple, un délai)
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde de délai
        isVisible = false
    }
    private func loadTransactions() async {
        transactions = ListTransactionsManager.shared.getAllData()
        printTag("[Rubrique Pie] Transactions chargées: \(transactions.count)")
    }

}


//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import Combine
import DGCharts

class RubriquePieViewModel: ObservableObject {
    @Published var depenseArray: [DataGraph] = []
    @Published var recetteArray: [DataGraph] = []
    
    @Published var dataEntriesDepense: [PieChartDataEntry] = []
    @Published var dataEntriesRecette: [PieChartDataEntry] = []

    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []
    
    var listTransactions: [EntityTransaction] = []
    
    var totalValueD: Double {
        depenseArray.map { $0.value }.reduce(0, +)
    }

    var labels: [String] {
        depenseArray.map { $0.name }
    }

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func updateChartData(  startDate: Date, endDate: Date) {
        
        listTransactions = ListTransactionsManager.shared.getAllData(from:startDate, to:endDate)
        printTag("[Rubrique Pie] Transactions chargées: \(listTransactions.count)")
        
        var dataArrayExpense = [DataGraph]()
        var dataArrayIncome  = [DataGraph]()

        var rubrique = ""
        var value = 0.0
        var color = NSColor.blue
        let section = ""
        
        for listeOperation in listTransactions {
            
            let sousOperations = listeOperation.sousOperations
            for sousOperation in sousOperations {
                
                value = sousOperation.amount
                rubrique = (sousOperation.category?.rubric!.name)!
                color = (sousOperation.category?.rubric!.color)!
                
                if value < 0 {
                    dataArrayExpense.append( DataGraph( name: rubrique, value: value, color: color))
                    
                } else {
                    dataArrayIncome.append( DataGraph(section: section, name: rubrique, value: value, color: color))
                }
            }
        }
        
        self.depenseArray.removeAll()
        let allKeys = Set<String>(dataArrayExpense.map { $0.name })
        for key in allKeys {
            let data = dataArrayExpense.filter({ $0.name == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            self.depenseArray.append(DataGraph(name: key, value: sum, color: data[0].color))
        }
        self.depenseArray = self.depenseArray.sorted(by: { $0.name < $1.name })
        
        recetteArray.removeAll()
        let allKeysR = Set<String>(dataArrayIncome.map { $0.name })
        for key in allKeysR {
            let data = dataArrayIncome.filter({ $0.name == key })
            let sum = data.map({ $0.value }).reduce(0, +)
            self.recetteArray.append(DataGraph(name: key, value: sum, color: data[0].color))
        }
        recetteArray = recetteArray.sorted(by: { $0.name < $1.name })
        
        self.depenseArray = summarizeData(from: dataArrayExpense, maxCategories: 6)
        self.recetteArray = summarizeData(from: dataArrayIncome, maxCategories: 6)
        
        self.dataEntriesDepense = pieChartEntries(from: depenseArray)
        self.dataEntriesRecette = pieChartEntries(from: recetteArray)
    }
    
    private func summarizeData(from array: [DataGraph], maxCategories: Int = 6) -> [DataGraph] {
        let grouped = Dictionary(grouping: array, by: { $0.name })
        
        let summarized = grouped.map { (key, values) in
            let total = values.map { $0.value }.reduce(0, +)
            return DataGraph(name: key, value: total, color: values.first?.color ?? .gray)
        }

        // Trier du plus grand au plus petit
        let sorted = summarized.sorted { abs($0.value) > abs($1.value) }

        if sorted.count <= maxCategories {
            return sorted
        }

        let main = sorted.prefix(maxCategories)
        let other = sorted.dropFirst(maxCategories)

        let totalOthers = other.map { $0.value }.reduce(0, +)
        let othersData = DataGraph(name: "Autres", value: totalOthers, color: .gray)

        return Array(main) + [othersData]
    }
    
    private func pieChartEntries(from array: [DataGraph]) -> [PieChartDataEntry] {
        array.map {
            PieChartDataEntry(value: abs($0.value), label: $0.name, data: $0)
        }
    }
}

//
//  Untitled 3.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine

struct RubriquePie: View {

    @StateObject private var viewModel = RubriquePieViewModel()
    
    let transactions: [EntityTransaction]

    @Binding var lowerValue: Double
    @Binding var upperValue: Double
    @Binding var minDate: Date
    @Binding var maxDate: Date

    private var firstDate: Date {
        transactions.first?.dateOperation ?? Date()
    }

    private var lastDate: Date {
        transactions.last?.dateOperation ?? Date()
    }

    private var durationDays: Double {
        lastDate.timeIntervalSince(firstDate) / 86400
    }
    
    private var totalDaysRange: ClosedRange<Double> {
        let cal = Calendar.current
        let start = cal.startOfDay(for: minDate)
        let end = cal.startOfDay(for: maxDate)
        let days = cal.dateComponents([.day], from: start, to: end).day ?? 0
        return 0...Double(max(0, days))
    }
    
    @State private var selectedStart: Double = 0
    @State private var selectedEnd: Double = 30

    @State private var updateWorkItem: DispatchWorkItem?
    
    @State private var lower: Double = 2
    @State private var upper: Double = 10

    var body: some View {
        VStack {
            Text(String(localized:"Rubrique pie"))
                .font(.headline)
                .padding()
            
            HStack {
                SinglePieChartView(entries: viewModel.dataEntriesDepense, title: "Dépenses")
                    .frame(width: 600, height: 400)
                    .padding()

                SinglePieChartView(entries: viewModel.dataEntriesRecette, title: String(localized:"Recettes"))
                    .frame(width: 600, height: 400)
                    .padding()
            }
            GroupBox(label: Label("Filter by period", systemImage: "calendar")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From \(formattedDate(from: selectedStart)) to \(formattedDate(from: selectedEnd))")
                        .font(.callout)
                        .foregroundColor(.secondary)

                    RangeSlider(
                        lowerValue: $selectedStart,
                        upperValue: $selectedEnd,
                        totalRange: totalDaysRange,
                        valueLabel: { value in
                            let cal = Calendar.current
                            let base = cal.startOfDay(for: minDate)
                            let date = cal.date(byAdding: .day, value: Int(value), to: base) ?? base
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            return formatter.string(from: date)
                        },
                        thumbSize: 24,
                        trackHeight: 6
                    )
                        .frame(height: 30)

                    Spacer()
                }
                .padding(.top, 4)
                .padding(.horizontal)
            }
        }
        .onAppear {
            // Initialize slider bounds based on available data
            selectedStart = 0
            selectedEnd = totalDaysRange.upperBound
            updatePieData()
        }
        .onChange(of: minDate) { _, _ in
            selectedStart = 0
            updatePieData()
        }
        .onChange(of: maxDate) { _, _ in
            selectedEnd = totalDaysRange.upperBound
            updatePieData()
        }
        .onChange(of: selectedStart) { _, _ in
            updatePieData()
        }
        .onChange(of: selectedEnd) { _, _ in
            updatePieData()
        }
    }
    
    private func updatePieData() {
        // Ensure prerequisites are valid
        guard selectedStart <= selectedEnd else { return }
        guard minDate <= maxDate else { return }

        let calendar = Calendar.current
        let startOfMin = calendar.startOfDay(for: minDate)

        guard let start = calendar.date(byAdding: .day, value: Int(selectedStart), to: startOfMin),
              let endRaw = calendar.date(byAdding: .day, value: Int(selectedEnd), to: startOfMin) else {
            return
        }

        // Clamp to maxDate then extend to end-of-day for inclusive range
        let endClamped = min(endRaw, maxDate)
        let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: endClamped)) ?? endClamped

        viewModel.updateChartData( startDate: start, endDate: endOfDay)
    }
    
    func formattedDate(from dayOffset: Double) -> String {
        let cal = Calendar.current
        let base = cal.startOfDay(for: minDate)
        let date = cal.date(byAdding: .day, value: Int(dayOffset), to: base) ?? base
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

}


//
//  SinglePieChartView.swift
//  PegaseUIData
//
//  Created by thierryH24 on 29/07/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine

struct SinglePieChartView: NSViewRepresentable {
    let entries: [PieChartDataEntry]
    let title: String

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func makeNSView(context: Context) -> PieChartView {
        let chartView = PieChartView()
        chartView.noDataText = String(localized: "No chart data available.")
        chartView.usePercentValuesEnabled = true
        chartView.drawHoleEnabled = true
        chartView.holeRadiusPercent = 0.4
        chartView.transparentCircleRadiusPercent = 0.45

        let centerText = NSMutableAttributedString(string: title)
        centerText.setAttributes([
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ], range: NSRange(location: 0, length: centerText.length))
        chartView.centerAttributedText = centerText

        chartView.chartDescription.enabled = false
        chartView.legend.enabled = true
        chartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)

        return chartView
    }

    func updateNSView(_ nsView: PieChartView, context: Context) {
        let dataSet = PieChartDataSet(entries: entries, label: "")
        dataSet.colors = ChartColorTemplates.material() + ChartColorTemplates.pastel()
        dataSet.drawValuesEnabled = true
        dataSet.valueTextColor = .black
        dataSet.entryLabelColor = .black
        dataSet.sliceSpace = 2.0

        let data = PieChartData(dataSet: dataSet)
        let formatter = PieValueFormatter(currencyCode: "EUR")
        data.setValueFormatter(formatter)
        data.setValueFont(.systemFont(ofSize: 11))

        nsView.data = data
        nsView.notifyDataSetChanged()
    }
}


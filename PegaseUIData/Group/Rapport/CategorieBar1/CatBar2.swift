////
////  CatBar3.swift
////  PegaseUIData
////
////  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine
import UniformTypeIdentifiers

class CategorieBar1ViewModel: ObservableObject {
    
    @Published var listTransactions : [EntityTransaction] = []
    @Published var isBarSelectionActive: Bool = false
    @Published var isMonthSelectionActive: Bool = false
    
    @Published var resultArray: [DataGraph] = []
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    
    @Published var selectedCategories: Set<String> = []
    
    @Published var firstDate: TimeInterval = 0.0
    @Published var lastDate: TimeInterval = 0.0
    
    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    private var fullFilteredCache: [EntityTransaction] = []
    
    var chartView : BarChartView?
    // X-axis labels and section ordering for selection mapping
    @Published var monthLabels: [String] = []
    var sectionOrder: [String] = []
    // Persist unique rubrics for grouped bar rendering
    private var uniqueRubrics: [RubricColor] = []

    static let shared = CategorieBar1ViewModel()
    
    var totalValue: Double {
        resultArray.map { $0.value }.reduce(0, +)
    }

    var labels: [String] {
        resultArray.map { $0.name }
    }
    
    let formatterDate: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMM/yyyy", options: 0, locale: Locale.current)
        return fmt
    }()

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()
    
    func configure(with chartView: BarChartView)
    {
        self.chartView = chartView
    }

    func updateAccount(minDate: Date) {
        let transactions = ListTransactionsManager.shared.getAllData()

        DispatchQueue.main.async {
            self.listTransactions = transactions
            if let first = transactions.first?.dateOperation.timeIntervalSince1970,
               let last = transactions.last?.dateOperation.timeIntervalSince1970 {
                self.firstDate = first
                self.lastDate = last
            }
        }
    }

    private func setDataCount()
    {
        // Ensure we have a chart view and data
        guard let chartView = self.chartView else { return }
        let dataPoints = self.resultArray
        let rubrics = self.uniqueRubrics

        // No data: clear chart
        guard !dataPoints.isEmpty else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return
        }

        // Need at least one rubric to build grouped bars
        guard !rubrics.isEmpty else {
            chartView.data = nil
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            return
        }

        // Collect and sort section keys (e.g., YYYYMM strings)
        let allSectionIDs = Array(Set(dataPoints.map { $0.section }))
        let sortedSectionIDs = allSectionIDs.sorted(by: { $0 < $1 })

        // Build human-readable month labels from section IDs
        var monthLabels: [String] = []
        for section in sortedSectionIDs {
            if let numeric = Int(section) {
                var comp = DateComponents()
                comp.year = numeric / 100
                comp.month = numeric % 100
                if let date = Calendar.current.date(from: comp) {
                    monthLabels.append(formatterDate.string(from: date))
                } else {
                    monthLabels.append(section)
                }
            } else {
                monthLabels.append(section)
            }
        }
        // Persist labels and order for selection mapping
        self.sectionOrder = sortedSectionIDs
        self.monthLabels = monthLabels

        // Build one dataset per rubric, aligned on the same X indexes (months)
        let dataSets: [BarChartDataSet] = rubrics.map { rubric in
            var entries: [BarChartDataEntry] = []
            for (idx, monthKey) in sortedSectionIDs.enumerated() {
                let value = dataPoints.first(where: { $0.section == monthKey && $0.name == rubric.name })?.value ?? 0
                entries.append(BarChartDataEntry(x: Double(idx), y: value))
            }
            let set = BarChartDataSet(entries: entries, label: rubric.name)
            set.colors = [rubric.color]
            set.drawValuesEnabled = true
            set.valueFormatter = DefaultValueFormatter(formatter: formatterPrice)
//            set.valueFormatter = CurrencyValueFormatter1()
//            set.valueFormatter = DefaultValueFormatter(formatter : formatter)


            return set
        }

        // Configure grouped bars
        let groupSpace = 0.2
        let barSpace = 0.0
        let barWidth = Double(0.8 / Double(rubrics.count))

        let data = BarChartData(dataSets: dataSets)
        data.setValueFormatter(DefaultValueFormatter(formatter: formatterPrice))
        if let valueFont = NSFont(name: "HelveticaNeue-Light", size: CGFloat(11.0)) {
            data.setValueFont(valueFont)
        }
        data.setValueTextColor(NSColor.labelColor)
        data.barWidth = barWidth
        data.groupBars(fromX: 0.0, groupSpace: groupSpace, barSpace: barSpace)

        // X axis range and labels
        let groupCount = sortedSectionIDs.count + 1
        let startIndex = 0
        let endIndex = startIndex + groupCount
        chartView.xAxis.axisMinimum = Double(startIndex)
        chartView.xAxis.axisMaximum = Double(endIndex)
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: monthLabels)

        // Apply data to chart
        chartView.data = data
        chartView.fitBars = true
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }

    func updateChartData( startDate: Date, endDate: Date) {
        // Configure the transaction manager with context if needed
        
        var arrayUniqueRubriques   = [RubricColor]()

        // Fetch transactions in the requested range
        self.listTransactions = ListTransactionsManager.shared.getAllData(from: startDate, to: endDate)

        guard !listTransactions.isEmpty else {
            self.resultArray = []
            self.dataEntries = []
            return
        }

        // Build flat data from sousOperations
        // Récupere le nom de toutes les rubriques
        // Récupere les datas pour la période choisie
        var setUniqueRubrique     = Set<RubricColor>()
        var dataRubrique = [DataGraph]()
        
        for listTransaction in listTransactions {
            
            let id = listTransaction.sectionIdentifier!
            
            let sousOperations = listTransaction.sousOperations
            for sousOperation in sousOperations {
                
                let amount    = sousOperation.amount
                
                let nameRubric = sousOperation.category?.rubric?.name
                let color    = sousOperation.category?.rubric?.color
                let rubricColor = RubricColor(name : nameRubric!, color: color ?? .black)
                
                setUniqueRubrique.insert(rubricColor)
                
                let data = DataGraph(section: id, name: nameRubric!, value: amount, color: color ?? .black)
                dataRubrique.append( data)
            }
        }
        arrayUniqueRubriques = setUniqueRubrique.sorted { $0.name > $1.name }
        
        // sum per rubric for each period (section)
        var perSectionResults: [DataGraph] = []
        let allSectionKeys = Set<String>(dataRubrique.map { $0.section })
        let selectedRubricNames: Set<String>? = selectedCategories.isEmpty ? nil : Set(selectedCategories)

        for sectionKey in allSectionKeys {
            for rubric in arrayUniqueRubriques {
                // Apply rubric filter if any
                if let filter = selectedRubricNames, !filter.contains(rubric.name) { continue }
                let matches = dataRubrique.filter { $0.section == sectionKey && $0.name == rubric.name }
                let sum = matches.map({ $0.value }).reduce(0, +)
                perSectionResults.append(DataGraph(section: sectionKey, name: rubric.name, value: sum, color: rubric.color))
            }
        }

        // Sort consistently: by section (ascending), then rubric name (ascending)
        perSectionResults.sort { (a, b) -> Bool in
            if a.section == b.section { return a.name < b.name }
            return a.section < b.section
        }

        // Persist results and rubrics for setDataCount()
        self.resultArray = perSectionResults
        if let filter = selectedRubricNames {
            self.uniqueRubrics = arrayUniqueRubriques.filter { filter.contains($0.name) }
        } else {
            self.uniqueRubrics = arrayUniqueRubriques
        }

        // Ask the chart to refresh on the main thread
        DispatchQueue.main.async {
            self.setDataCount()
        }
    }
    
    func handleBarSelection(rubricName: String) {
        if fullFilteredCache.isEmpty {
            fullFilteredCache = listTransactions
        }
        let filtered = fullFilteredCache.filter { tx in
            tx.sousOperations.contains { $0.category?.rubric?.name == rubricName }
        }
        var didChange = false
        if ListTransactionsManager.shared.listTransactions != filtered {
            ListTransactionsManager.shared.listTransactions = filtered
            didChange = true
        }
        if self.listTransactions != filtered {
            self.listTransactions = filtered
            didChange = true
        }
        if didChange {
            NotificationCenter.default.post(name: .transactionsSelectionChanged, object: nil)
        }
        self.isBarSelectionActive = true
    }

    func clearBarSelection() {
        let restored = self.fullFilteredCache
        self.fullFilteredCache.removeAll()
        var didChange = false
        if ListTransactionsManager.shared.listTransactions != restored {
            ListTransactionsManager.shared.listTransactions = restored
            didChange = true
        }
        if self.listTransactions != restored {
            self.listTransactions = restored
            didChange = true
        }
        if didChange {
            NotificationCenter.default.post(name: .transactionsSelectionChanged, object: nil)
        }
        self.isBarSelectionActive = false
    }
}


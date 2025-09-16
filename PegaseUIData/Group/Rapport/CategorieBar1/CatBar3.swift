//
//  CatBar.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


class CategorieBar1ViewModel: ObservableObject {
    
    @Published var listTransactions : [EntityTransaction] = []
    
    @Published var resultArray: [DataGraph] = []
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    
    @Published var selectedCategories: Set<String> = []
    
    @Published var firstDate: TimeInterval = 0.0
    @Published var lastDate: TimeInterval = 0.0
    
    @Published var selectedStart: Double = 0
    @Published var selectedEnd: Double = 30
    
    @State var chartView : BarChartView?
    var rangeSlider : RangeSlider?

    static let shared = CategorieBar1ViewModel()
    
    var totalValue: Double {
        resultArray.map { $0.value }.reduce(0, +)
    }

    var labels: [String] {
        resultArray.map { $0.name }
    }

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


//    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {
//        
//        ListTransactionsManager.shared.configure(with: modelContext)
//        listTransactions = ListTransactionsManager.shared.getAllData(from: startDate, to: endDate)
//
//        guard listTransactions.isEmpty == false else { return }
//
//        
////        guard let currentAccount else { return }
////        self.currencyCode = currentAccount.currencyCode
////
////        let sort = [SortDescriptor(\EntityTransactions.dateOperation, order: .reverse)]
////        let lhs = currentAccount.uuid
////
////        let descriptor = FetchDescriptor<EntityTransactions>(
////            predicate: #Predicate { transaction in
////                transaction.account.uuid == lhs &&
////                transaction.dateOperation >= startDate &&
////                transaction.dateOperation <= endDate
////            },
////            sortBy: sort
////        )
////
////        var listTransactions: [EntityTransactions] = []
////        do {
////            listTransactions = try modelContext.fetch(descriptor)
////        } catch {
////            printTag("Erreur lors de la récupération des transactions :", error)
////            return
////        }
//
//        var dataArray: [DataGraph] = []
//
//        for transaction in listTransactions {
//            let sousOperations = transaction.sousOperations
//
//            for sousOperation in sousOperations {
//                if let rubric = sousOperation.category?.rubric {
//                    let name = rubric.name
//                    let value = sousOperation.amount
//                    let color = rubric.color
//                    dataArray.append(DataGraph(name: name, value: value, color: color))
//                }
//            }
//        }
//
//        let allKeys = Set(dataArray.map { $0.name })
//        var results: [DataGraph] = []
//        for key in allKeys {
//            let data = dataArray.filter { $0.name == key }
//            let sum = data.map { $0.value }.reduce(0, +)
//            if let color = data.first?.color {
//                results.append(DataGraph(name: key, value: sum, color: color))
//            }
//        }
//
//        var filteredResults = results
//        if !selectedCategories.isEmpty {
//            filteredResults = results.filter { selectedCategories.contains($0.name) }
//        }
//        self.resultArray = filteredResults.sorted { $0.name < $1.name }
//
//        var entries: [BarChartDataEntry] = []
//        for (i, item) in self.resultArray.enumerated() {
//            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
//        }
//        self.dataEntries = entries
//    }
}

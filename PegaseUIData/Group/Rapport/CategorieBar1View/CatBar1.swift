//
//  CatBar.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts

class CategorieBar1ViewModel: ObservableObject {
    @Published var resultArray: [DataGraph] = []
    @Published var dataEntries: [BarChartDataEntry] = []
    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"
    @Published var selectedCategories: Set<String> = []
    
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

    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {
        
        guard let currentAccount else { return }
        self.currencyCode = currentAccount.currencyCode

        let sort = [SortDescriptor(\EntityTransactions.dateOperation, order: .reverse)]
        let lhs = currentAccount.uuid

        let descriptor = FetchDescriptor<EntityTransactions>(
            predicate: #Predicate { transaction in
                transaction.account.uuid == lhs &&
                transaction.dateOperation >= startDate &&
                transaction.dateOperation <= endDate
            },
            sortBy: sort
        )

        var listTransactions: [EntityTransactions] = []
        do {
            listTransactions = try modelContext.fetch(descriptor)
        } catch {
            print("Erreur lors de la récupération des transactions :", error)
            return
        }

        var dataArray: [DataGraph] = []

        for transaction in listTransactions {
            let sousOperations = transaction.sousOperations

            for sousOperation in sousOperations {
                if let rubric = sousOperation.category?.rubric {
                    let name = rubric.name
                    let value = sousOperation.amount
                    let color = rubric.color
                    dataArray.append(DataGraph(name: name, value: value, color: color))
                }
            }
        }

        let allKeys = Set(dataArray.map { $0.name })
        var results: [DataGraph] = []
        for key in allKeys {
            let data = dataArray.filter { $0.name == key }
            let sum = data.map { $0.value }.reduce(0, +)
            if let color = data.first?.color {
                results.append(DataGraph(name: key, value: sum, color: color))
            }
        }

        var filteredResults = results
        if !selectedCategories.isEmpty {
            filteredResults = results.filter { selectedCategories.contains($0.name) }
        }
        self.resultArray = filteredResults.sorted { $0.name < $1.name }

        var entries: [BarChartDataEntry] = []
        for (i, item) in self.resultArray.enumerated() {
            entries.append(BarChartDataEntry(x: Double(i), y: item.value))
        }
        self.dataEntries = entries
    }
}

//
//  RecetteDepensePie1.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 17/04/2025.
//

import SwiftUI
import SwiftData
import DGCharts
import Combine


class RecetteDepensePieViewModel: ObservableObject {
    @Published var recetteArray: [DataGraph] = []
    @Published var depenseArray: [DataGraph] = []
    
    @Published var dataEntriesDepense: [PieChartDataEntry] = []
    @Published var dataEntriesRecette: [PieChartDataEntry] = []

    @Published var currencyCode: String = Locale.current.currency?.identifier ?? "EUR"

    let formatterPrice: NumberFormatter = {
        let _formatter = NumberFormatter()
        _formatter.locale = Locale.current
        _formatter.numberStyle = .currency
        return _formatter
    }()

    func updateChartData(modelContext: ModelContext, currentAccount: EntityAccount?, startDate: Date, endDate: Date) {
        guard let currentAccount else { return }
        self.currencyCode = currentAccount.currencyCode

        let sort = [SortDescriptor(\EntityTransaction.dateOperation, order: .reverse)]
        let lhs = currentAccount.uuid

        let descriptor = FetchDescriptor<EntityTransaction>(
            predicate: #Predicate { transaction in
                transaction.account.uuid == lhs &&
                transaction.dateOperation >= startDate &&
                transaction.dateOperation <= endDate
            },
            sortBy: sort
        )

        var listTransactions: [EntityTransaction] = []
        do {
            listTransactions = try modelContext.fetch(descriptor)
        } catch {
            printTag("Error fetching data from CoreData", flag: true)
        }
        
        var dataArrayExpense = [DataGraph]()
        var dataArrayIncome = [DataGraph]()

        for listTransaction in listTransactions {
            guard let name = listTransaction.paymentMode?.name,
                  let color = listTransaction.paymentMode?.color else { continue }

            let data = DataGraph(name: name, value: listTransaction.amount, color: color)

            if data.value < 0 {
                dataArrayExpense.append(data)
            } else {
                dataArrayIncome.append(data)
            }
        }

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
